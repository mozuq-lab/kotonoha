"""Application Factory（ADR-004）。import しただけでは何も作らない。

起動: ``uvicorn app.main:create_app --factory``
"""

from __future__ import annotations

import os
import sys
from collections.abc import AsyncIterator, Callable, Mapping, Sequence
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from starlette.types import ASGIApp, Receive, Scope, Send

from app.ai.providers import Provider, build_provider
from app.ai.service import ConversionService
from app.auth import API_KEY_HEADER_NAME, build_require_api_key
from app.config import API_PREFIX, RuntimeConfig, load_config
from app.errors import (
    HTTP_STATUS,
    USER_MESSAGE,
    VALIDATION_MESSAGE,
    ConfigError,
    ErrorCode,
    RateLimitExceeded,
    SafeError,
)
from app.logging import (
    AuthenticationSkipped,
    ProviderConfigured,
    RequestFailed,
    configure_logging,
    log_event,
)
from app.ratelimit import RateLimiter
from app.routes import build_router

ProviderFactory = Callable[[RuntimeConfig], Provider | None]


class ExceptionBoundaryMiddleware:
    """想定外例外の最後の受け皿（純 ASGI ミドルウェア）。

    Starlette の ``ServerErrorMiddleware`` は応答を作った後に必ず例外を再送出するため、
    ハンドラ（``add_exception_handler(Exception, ...)``）だけでは uvicorn が例外の文字列
    表現込みの traceback を stderr へ出してしまう。その手前で受け止める。ここを通る例外は
    型名しか残らない。

    ``add_middleware`` は後から足したものが外側になるため、CORS より前に登録して
    CORS の内側・router の外側（``ExceptionMiddleware`` の外側）に置く。
    """

    def __init__(self, app: ASGIApp) -> None:
        self.app = app

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return
        cause: type[BaseException] | None = None
        try:
            await self.app(scope, receive, send)
        except Exception as exc:  # 第三者ライブラリ／他ミドルウェアの自由文を外へ出さない
            cause = type(exc)
        else:
            return
        assert cause is not None  # else 節で return 済みなのでここは except 経由のみ
        log_event(
            RequestFailed(
                route=scope["path"],
                error_code=ErrorCode.INTERNAL_ERROR.value,
                cause_type=cause.__name__,
            ),
            level="ERROR",
        )
        response = JSONResponse(status_code=500, content=_error_body(ErrorCode.INTERNAL_ERROR))
        try:
            await response(scope, receive, send)
        except Exception:  # noqa: S110 -- 応答が既に始まっていた場合の送信失敗。ログは上で出ている
            pass


def _parse_worker_count(raw: str) -> int | None:
    """uvicorn 自身の ``int()`` と同じ解析（符号・前後空白を許す）。0 以下は 1 に丸める。"""
    try:
        value = int(raw)
    except ValueError:
        return None
    return max(1, value)


def configured_worker_count(environ: Mapping[str, str], argv: Sequence[str]) -> int:
    """uvicorn / gunicorn 系が使う指定（WEB_CONCURRENCY・--workers N・--workers=N・
    -w N）の最大値。
    """
    counts = [1]
    parsed = _parse_worker_count(environ.get("WEB_CONCURRENCY", ""))
    if parsed is not None:
        counts.append(parsed)
    for index, arg in enumerate(argv):
        if arg in ("--workers", "-w") and index + 1 < len(argv):
            parsed = _parse_worker_count(argv[index + 1])
        elif arg.startswith("--workers="):
            parsed = _parse_worker_count(arg.removeprefix("--workers="))
        else:
            continue
        if parsed is not None:
            counts.append(parsed)
    return max(counts)


def create_app(
    config: RuntimeConfig | None = None,
    *,
    provider_factory: ProviderFactory = build_provider,
    environ: Mapping[str, str] | None = None,
    argv: Sequence[str] | None = None,
) -> FastAPI:
    # 起動ガード（ADR-002）。同一コンテナ内の worker 数までしか見えない
    if (
        configured_worker_count(
            os.environ if environ is None else environ, sys.argv if argv is None else argv
        )
        > 1
    ):
        raise SafeError(ErrorCode.STARTUP_MULTIPLE_WORKERS)

    cfg = load_config() if config is None else config
    configure_logging(cfg.LOG_LEVEL)

    api_keys = cfg.api_keys()
    if not api_keys:
        if (
            not cfg.auth_optional
        ):  # load_config の本番ゲートで落ちるが、config を直接渡された場合の守り
            raise ConfigError((("API_KEYS", "missing"),))
        log_event(AuthenticationSkipped(environment=cfg.ENVIRONMENT), level="WARNING")

    @asynccontextmanager
    async def lifespan(app: FastAPI) -> AsyncIterator[None]:
        init_cause: type[BaseException] | None = None
        provider: Provider | None = None
        try:
            provider = provider_factory(cfg)  # 資源は lifespan で生成する（ADR-004）
        except Exception as exc:  # SDK/サードパーティの自由文を境界の外へ出さない
            init_cause = type(exc)
        if init_cause is not None:
            raise SafeError(ErrorCode.STARTUP_PROVIDER_INIT_FAILED, cause=init_cause)
        service = ConversionService(
            provider, max_retries=cfg.AI_MAX_RETRIES, deadline_seconds=cfg.AI_CALL_DEADLINE_SECONDS
        )
        app.state.conversion_service = service
        log_event(ProviderConfigured(provider=service.provider_name))
        try:
            yield
        finally:
            if provider is not None:
                close_cause: type[BaseException] | None = None
                try:
                    await provider.aclose()
                except Exception as exc:  # 終了時は raise せず型名だけ記録する
                    close_cause = type(exc)
                if close_cause is not None:
                    log_event(
                        RequestFailed(
                            route="lifespan",
                            error_code=ErrorCode.INTERNAL_ERROR.value,
                            cause_type=close_cause.__name__,
                        ),
                        level="ERROR",
                    )

    app = FastAPI(
        title=cfg.PROJECT_NAME,
        version=cfg.VERSION,
        description="文字盤コミュニケーション支援アプリ バックエンドAPI",
        docs_url="/docs" if cfg.docs_enabled else None,
        redoc_url="/redoc" if cfg.docs_enabled else None,
        openapi_url="/openapi.json" if cfg.docs_enabled else None,
        lifespan=lifespan,
    )
    app.add_middleware(ExceptionBoundaryMiddleware)  # CORS の内側・router の外側
    app.add_middleware(
        CORSMiddleware,
        allow_origins=list(cfg.cors_origins()),
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    app.add_exception_handler(SafeError, _safe_error_handler)
    app.add_exception_handler(RequestValidationError, _validation_handler)

    limiter = RateLimiter(
        times=cfg.RATE_LIMIT_TIMES,
        seconds=cfg.RATE_LIMIT_SECONDS,
        trusted_proxy_count=cfg.TRUSTED_PROXY_COUNT,
    )
    app.include_router(
        build_router(
            version=cfg.VERSION, require_api_key=build_require_api_key(api_keys), limiter=limiter
        ),
        prefix=API_PREFIX,
    )
    return app


def _error_body(code: ErrorCode, **extra: int) -> dict[str, object]:
    return {
        "success": False,
        "data": None,
        "error": {
            "code": code.value,
            "message": USER_MESSAGE[code],
            "status_code": HTTP_STATUS[code],
            **extra,
        },
    }


async def _safe_error_handler(request: Request, exc: Exception) -> JSONResponse:
    assert isinstance(exc, SafeError)
    if exc.code is ErrorCode.AUTHENTICATION_ERROR:  # 旧契約: {"detail": …} + WWW-Authenticate
        return JSONResponse(
            status_code=401,
            content={"detail": USER_MESSAGE[exc.code]},
            headers={"WWW-Authenticate": API_KEY_HEADER_NAME},
        )
    if isinstance(exc, RateLimitExceeded):
        return JSONResponse(
            status_code=429,
            content=_error_body(exc.code, retry_after=exc.retry_after_seconds),
            headers={
                "Retry-After": str(exc.retry_after_seconds),
                "X-RateLimit-Limit": str(exc.limit),
                "X-RateLimit-Remaining": "0",
                "X-RateLimit-Reset": str(exc.retry_after_seconds),
            },
        )
    return JSONResponse(status_code=HTTP_STATUS[exc.code], content=_error_body(exc.code))


async def _validation_handler(request: Request, exc: Exception) -> JSONResponse:
    assert isinstance(exc, RequestValidationError)
    detail: list[dict[str, object]] = []
    for err in exc.errors():  # input / ctx / url は読まない
        error_type = err.get("type", "unknown")
        detail.append(
            {
                "type": error_type,
                "loc": list(err.get("loc", ())),
                # pydantic の自由文（err["msg"]）は読まない。type から有限語彙へ写像する（ADR-003）
                "msg": VALIDATION_MESSAGE.get(error_type, VALIDATION_MESSAGE["default"]),
            }
        )
    return JSONResponse(
        status_code=422,
        content={
            "error": USER_MESSAGE[ErrorCode.VALIDATION_ERROR],
            "detail": detail,
            "error_code": ErrorCode.VALIDATION_ERROR.value,
        },
    )
