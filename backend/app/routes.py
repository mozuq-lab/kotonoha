"""公開ルート3本。想定外の例外は型名だけ拾って SafeError にする。"""

from __future__ import annotations

from collections.abc import Awaitable, Callable, Coroutine
from contextlib import aclosing
from datetime import datetime, timezone
from time import perf_counter
from typing import Any, Literal

from fastapi import APIRouter, Depends, Request, Response, Security
from fastapi.routing import APIRoute
from starlette.requests import ClientDisconnect
from starlette.types import Message, Receive

from app.ai.service import ConversionService
from app.auth import API_KEY_HEADER_NAME, api_key_header, require_api_key
from app.errors import ErrorCode, SafeError
from app.logging import ConversionCompleted, log_event
from app.ratelimit import RateLimiter
from app.schemas import (
    REQUEST_BODY_MAX_BYTES,
    ConversionRequest,
    ConversionResponse,
    HealthResponse,
    RegenerateRequest,
)

Route = Literal["convert", "regenerate"]
RouteHandler = Callable[[Request], Coroutine[Any, Any, Response]]


async def _read_body_within(request: Request, limit: int) -> bytes:
    """``limit`` バイトまで読む。Content-Length の申告と実際に読んだ量の両方で見る。"""
    declared = request.headers.get("content-length")
    if declared is not None and declared.isascii() and declared.isdigit() and int(declared) > limit:
        raise SafeError(ErrorCode.PAYLOAD_TOO_LARGE)  # 1 バイトも読まずに断る
    chunks: list[bytes] = []
    size = 0
    async with aclosing(request.stream()) as stream:  # chunked（申告なし）もここで数える
        async for chunk in stream:
            size += len(chunk)
            if size > limit:
                raise SafeError(ErrorCode.PAYLOAD_TOO_LARGE)
            chunks.append(chunk)
    return b"".join(chunks)


def _replay(body: bytes, receive: Receive) -> Receive:
    """読み終えた本文を 1 回だけ渡し、その後は元の receive（切断の通知など）へつなぐ。"""
    replayed = False

    async def replay() -> Message:
        nonlocal replayed
        if replayed:
            return await receive()
        replayed = True
        return {"type": "http.request", "body": body, "more_body": False}

    return replay


def guarded_route_class(api_keys: tuple[bytes, ...]) -> type[APIRoute]:
    """API キーと本文の大きさを、本文を読む前に確かめるルート（2026-10-08 の監査の指摘 1）。

    FastAPI は依存を解決する前に本文を全部読み JSON として解析するので、依存では間に合わない。
    ハンドラの手前で確かめ、断るときは ``SafeError`` を投げて既存の例外ハンドラに応答を作らせる
    （401 の形も CORS ヘッダも、ほかのエラーと同じ経路を通る）。順序は 認証 → 本文 → レート制限。
    """

    class GuardedRoute(APIRoute):
        def get_route_handler(self) -> RouteHandler:
            handler = super().get_route_handler()

            async def guarded(request: Request) -> Response:
                require_api_key(request.headers.get(API_KEY_HEADER_NAME), api_keys)
                body: bytes | None = None
                try:
                    body = await _read_body_within(request, REQUEST_BODY_MAX_BYTES)
                except ClientDisconnect:  # 送信の途中で切れた（通信の瞬断）。相手はもう居ない
                    pass
                if body is None:
                    return Response(status_code=400)  # FastAPI が読んでいたときと同じ 400
                return await handler(Request(request.scope, _replay(body, request.receive)))

            return guarded

    return GuardedRoute


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


def build_router(*, version: str, api_keys: tuple[bytes, ...], limiter: RateLimiter) -> APIRouter:
    router = APIRouter()
    # 認証が要るルートはこのルータに置く（置き場所で、本文より前の確かめが決まる）
    ai = APIRouter(route_class=guarded_route_class(api_keys))

    @router.get("/health", response_model=HealthResponse, tags=["health"])
    async def health(service: ConversionService = Depends(get_service)) -> HealthResponse:
        return HealthResponse(
            status="ok",
            ai_provider=service.provider_name,
            version=version,
            timestamp=datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        )

    @ai.post(
        "/ai/convert",
        response_model=ConversionResponse,
        tags=["ai"],
        summary="AI変換API",
        dependencies=[Security(api_key_header), Depends(limiter.dependency("convert"))],
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

    @ai.post(
        "/ai/regenerate",
        response_model=ConversionResponse,
        tags=["ai"],
        summary="AI再変換API",
        dependencies=[Security(api_key_header), Depends(limiter.dependency("regenerate"))],
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

    router.include_router(ai)
    return router
