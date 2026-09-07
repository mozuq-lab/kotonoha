"""公開ルート3本。想定外の例外は型名だけ拾って SafeError にする。"""

from __future__ import annotations

from collections.abc import Awaitable
from datetime import datetime, timezone
from time import perf_counter
from typing import Literal

from fastapi import APIRouter, Depends, Request

from app.ai.service import ConversionService
from app.auth import ApiKeyDependency
from app.errors import ErrorCode, SafeError
from app.logging import ConversionCompleted, log_event
from app.ratelimit import RateLimiter
from app.schemas import ConversionRequest, ConversionResponse, HealthResponse, RegenerateRequest

Route = Literal["convert", "regenerate"]


def get_service(request: Request) -> ConversionService:
    service: ConversionService = request.app.state.conversion_service
    return service


async def _guarded(route: Route, service: ConversionService, call: Awaitable[str]) -> str:
    """成功・失敗を1行のログにし、例外は SafeError だけを上へ通す。"""
    started = perf_counter()
    text = ""
    failure: SafeError | None = None
    unexpected: type[BaseException] | None = None
    try:
        text = await call
    except SafeError as exc:
        failure = exc
    except Exception as exc:
        unexpected = type(exc)
    latency_ms = int((perf_counter() - started) * 1000)
    if unexpected is not None:
        failure = SafeError(ErrorCode.INTERNAL_ERROR, cause=unexpected)
    if failure is not None:
        log_event(
            ConversionCompleted(
                route=route,
                provider=service.provider_name,
                outcome="error",
                latency_ms=latency_ms,
                error_code=failure.code.value,
                cause_type=failure.cause_type,
            ),
            level="ERROR",
        )
        raise failure  # except の外
    log_event(
        ConversionCompleted(
            route=route, provider=service.provider_name, outcome="success", latency_ms=latency_ms
        )
    )
    return text


def build_router(
    *, version: str, require_api_key: ApiKeyDependency, limiter: RateLimiter
) -> APIRouter:
    router = APIRouter()

    @router.get("/health", response_model=HealthResponse, tags=["health"])
    async def health(service: ConversionService = Depends(get_service)) -> HealthResponse:
        return HealthResponse(
            status="ok",
            ai_provider=service.provider_name,
            version=version,
            timestamp=datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        )

    @router.post(
        "/ai/convert",
        response_model=ConversionResponse,
        tags=["ai"],
        summary="AI変換API",
        dependencies=[Depends(require_api_key), Depends(limiter.dependency("convert"))],
    )
    async def convert(
        body: ConversionRequest, service: ConversionService = Depends(get_service)
    ) -> ConversionResponse:
        started = perf_counter()
        text = await _guarded(
            "convert", service, service.convert(body.input_text, body.politeness_level)
        )
        return ConversionResponse(
            converted_text=text,
            original_text=body.input_text,
            politeness_level=body.politeness_level,
            processing_time_ms=int((perf_counter() - started) * 1000),
        )

    @router.post(
        "/ai/regenerate",
        response_model=ConversionResponse,
        tags=["ai"],
        summary="AI再変換API",
        dependencies=[Depends(require_api_key), Depends(limiter.dependency("regenerate"))],
    )
    async def regenerate(
        body: RegenerateRequest, service: ConversionService = Depends(get_service)
    ) -> ConversionResponse:
        started = perf_counter()
        text = await _guarded(
            "regenerate",
            service,
            service.regenerate(body.input_text, body.politeness_level, body.previous_result),
        )
        return ConversionResponse(
            converted_text=text,
            original_text=body.input_text,
            politeness_level=body.politeness_level,
            processing_time_ms=int((perf_counter() - started) * 1000),
        )

    return router
