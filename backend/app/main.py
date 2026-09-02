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

from app.ai.providers import Provider, build_provider
from app.ai.service import ConversionService
from app.auth import API_KEY_HEADER_NAME, build_require_api_key
from app.config import API_PREFIX, RuntimeConfig, load_config
from app.errors import (
    HTTP_STATUS,
    USER_MESSAGE,
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


def configured_worker_count(environ: Mapping[str, str], argv: Sequence[str]) -> int:
    """uvicorn / gunicorn 系が使う指定（WEB_CONCURRENCY・--workers N・--workers=N・
    -w N）の最大値。
    """
    counts = [1]
    web = environ.get("WEB_CONCURRENCY", "")
    if web.isdigit():
        counts.append(int(web))
    for index, arg in enumerate(argv):
        if arg in ("--workers", "-w") and index + 1 < len(argv) and argv[index + 1].isdigit():
            counts.append(int(argv[index + 1]))
        elif arg.startswith("--workers=") and arg.removeprefix("--workers=").isdigit():
            counts.append(int(arg.removeprefix("--workers=")))
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
        provider = provider_factory(cfg)  # 資源は lifespan で生成する（ADR-004）
        service = ConversionService(
            provider, max_retries=cfg.AI_MAX_RETRIES, deadline_seconds=cfg.AI_CALL_DEADLINE_SECONDS
        )
        app.state.conversion_service = service
        log_event(ProviderConfigured(provider=service.provider_name))
        try:
            yield
        finally:
            if provider is not None:
                await provider.aclose()

    app = FastAPI(
        title=cfg.PROJECT_NAME,
        version=cfg.VERSION,
        description="文字盤コミュニケーション支援アプリ バックエンドAPI",
        docs_url="/docs" if cfg.docs_enabled else None,
        redoc_url="/redoc" if cfg.docs_enabled else None,
        openapi_url="/openapi.json" if cfg.docs_enabled else None,
        lifespan=lifespan,
    )
    app.add_middleware(
        CORSMiddleware,
        allow_origins=list(cfg.cors_origins()),
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    app.add_exception_handler(SafeError, _safe_error_handler)
    app.add_exception_handler(RequestValidationError, _validation_handler)
    app.add_exception_handler(Exception, _unexpected_handler)

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
    detail = [
        {
            "type": err.get("type", "unknown"),
            "loc": list(err.get("loc", ())),
            "msg": err.get("msg", ""),
        }
        for err in exc.errors()  # input / ctx / url は載せない
    ]
    return JSONResponse(
        status_code=422,
        content={
            "error": USER_MESSAGE[ErrorCode.VALIDATION_ERROR],
            "detail": detail,
            "error_code": ErrorCode.VALIDATION_ERROR.value,
        },
    )


async def _unexpected_handler(request: Request, exc: Exception) -> JSONResponse:
    """routes が拾えなかった層（ミドルウェア等）の最後の受け皿。型名だけ記録する。"""
    log_event(
        RequestFailed(
            route=request.url.path,
            error_code=ErrorCode.INTERNAL_ERROR.value,
            cause_type=type(exc).__name__,
        ),
        level="ERROR",
    )
    return JSONResponse(status_code=500, content=_error_body(ErrorCode.INTERNAL_ERROR))
