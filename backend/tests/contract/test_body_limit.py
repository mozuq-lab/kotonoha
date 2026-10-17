"""本文を読む前に断る（2026-10-08 の監査の指摘 1）。

FastAPI は依存（API キー・レート制限）を解決する前に本文を全部読み、JSON として解析する。
キー無しの誰でも大きな本文で単一 worker のメモリとイベントループを占有できたので、
API キーと本文の大きさは本文を読む前に確かめる。読んだかどうかは ASGI の receive が
呼ばれた回数（アプリの最も外側）で見る。
"""

from __future__ import annotations

import json
from collections.abc import Awaitable, Callable, MutableMapping
from typing import Any

import pytest
import respx
from fastapi import FastAPI
from fastapi.testclient import TestClient

from tests.contract.conftest import fresh_ip

CONVERT = "/api/v1/ai/convert"
REGENERATE = "/api/v1/ai/regenerate"
ROUTES = [CONVERT, REGENERATE]
BODY_LIMIT = (
    64 * 1024
)  # 契約値（バイト）。正当な最大の本文（下の test_largest_legitimate_body…）の 3 倍超
ERROR_SHAPE_KEYS = {"success", "data", "error"}
ORIGIN = "http://localhost:3000"

Message = MutableMapping[str, Any]


def _malformed_json(size: int) -> bytes:
    """末尾の 1 文字だけ壊れた JSON。解析器が最後まで読まないと json_invalid にならない。"""
    return b"[" + b"0," * (size // 2) + b"x]"


async def _asgi_post(
    app: FastAPI,
    path: str,
    headers: list[tuple[bytes, bytes]],
    receive: Callable[[], Awaitable[Message]],
) -> tuple[int, int]:
    """ASGI で直接呼ぶ。(状態コード, 応答を始める前に receive が呼ばれた回数) を返す。"""
    calls = 0
    calls_before_response: int | None = None
    status = 0

    async def counting_receive() -> Message:
        nonlocal calls
        calls += 1
        return await receive()

    async def send(message: Message) -> None:
        nonlocal calls_before_response, status
        if message["type"] == "http.response.start" and calls_before_response is None:
            calls_before_response = calls
            status = message["status"]

    scope: dict[str, Any] = {
        "type": "http",
        "asgi": {"version": "3.0"},
        "http_version": "1.1",
        "method": "POST",
        "scheme": "http",
        "path": path,
        "raw_path": path.encode(),
        "root_path": "",
        "query_string": b"",
        "headers": [(b"host", b"testserver"), (b"x-forwarded-for", fresh_ip().encode()), *headers],
        "client": ("127.0.0.1", 50000),
        "server": ("testserver", 80),
    }
    await app(scope, counting_receive, send)
    assert calls_before_response is not None
    return status, calls_before_response


def _endless_chunks(chunk_size: int, give_up_after: int) -> Callable[[], Awaitable[Message]]:
    """Content-Length 無しで chunk を送り続ける送信元。修正前に無限に読まないよう、give_up_after 回で終える。"""
    sent = 0

    async def receive() -> Message:
        nonlocal sent
        sent += 1
        return {
            "type": "http.request",
            "body": b"0" * chunk_size,
            "more_body": sent < give_up_after,
        }

    return receive


async def _one_small_body() -> Message:
    return {"type": "http.request", "body": b"{}", "more_body": False}


@pytest.mark.parametrize("route", ROUTES)
def test_unauthenticated_large_body_is_401_not_parsed(client: TestClient, route: str) -> None:
    """末尾だけ壊した 8 MiB。最後まで解析していれば 422（解析位置が末尾）になる。"""
    response = client.post(
        route,
        content=_malformed_json(8 * 1024 * 1024),
        headers={"Content-Type": "application/json", "X-Forwarded-For": fresh_ip()},
    )
    assert response.status_code == 401
    assert response.headers["www-authenticate"] == "X-API-Key"
    assert response.json() == {"detail": "Invalid or missing API key."}


@pytest.mark.parametrize("route", ROUTES)
async def test_unauthenticated_request_body_is_never_received(app: FastAPI, route: str) -> None:
    status, received = await _asgi_post(
        app,
        route,
        [(b"content-type", b"application/json"), (b"content-length", b"2"), (b"x-api-key", b"bad")],
        _one_small_body,
    )
    assert (status, received) == (401, 0)


@pytest.mark.parametrize("route", ROUTES)
async def test_declared_oversized_body_is_413_without_receiving(app: FastAPI, route: str) -> None:
    status, received = await _asgi_post(
        app,
        route,
        [
            (b"content-type", b"application/json"),
            (b"content-length", str(BODY_LIMIT + 1).encode()),
            (b"x-api-key", b"contract-key-A"),
        ],
        _one_small_body,
    )
    assert (status, received) == (413, 0)


@pytest.mark.parametrize("route", ROUTES)
async def test_undeclared_oversized_body_stops_reading_at_the_limit(
    app: FastAPI, route: str
) -> None:
    """Content-Length の無い本文（chunked）。上限を超えた時点で読むのをやめる。"""
    chunk = 16 * 1024
    status, received = await _asgi_post(
        app,
        route,
        [(b"content-type", b"application/json"), (b"x-api-key", b"contract-key-A")],
        _endless_chunks(chunk, give_up_after=64),  # 1 MiB で終える
    )
    assert status == 413
    assert received <= BODY_LIMIT // chunk + 1


@pytest.mark.parametrize("route", ROUTES)
def test_authenticated_oversized_body_is_413(
    client: TestClient, headers: dict[str, str], route: str
) -> None:
    response = client.post(
        route,
        content=_malformed_json(BODY_LIMIT),
        headers={**headers, "Content-Type": "application/json", "Origin": ORIGIN},
    )
    assert response.status_code == 413
    body = response.json()
    assert set(body) == ERROR_SHAPE_KEYS
    assert body["success"] is False and body["data"] is None
    assert body["error"]["code"] == "PAYLOAD_TOO_LARGE"
    assert body["error"]["status_code"] == 413
    assert isinstance(body["error"]["message"], str) and body["error"]["message"]
    assert response.headers["access-control-allow-origin"] == ORIGIN


def test_chunked_oversized_body_is_413(client: TestClient, headers: dict[str, str]) -> None:
    def chunks() -> Any:
        for _ in range(8):
            yield b"0" * (16 * 1024)

    response = client.post(
        CONVERT, content=chunks(), headers={**headers, "Content-Type": "application/json"}
    )
    assert response.request.headers.get("transfer-encoding") == "chunked"
    assert "content-length" not in response.request.headers
    assert response.status_code == 413


def test_body_of_exactly_the_limit_is_read(client: TestClient, headers: dict[str, str]) -> None:
    """上限ちょうどは断らない（読んで解析し、壊れているので 422）。"""
    body = b"[" + b"0" * (BODY_LIMIT - 3) + b"x]"
    assert len(body) == BODY_LIMIT
    response = client.post(
        CONVERT, content=body, headers={**headers, "Content-Type": "application/json"}
    )
    assert response.status_code == 422


def test_largest_legitimate_body_is_accepted(
    client: TestClient, headers: dict[str, str], provider_http: respx.MockRouter
) -> None:
    """スキーマの最大長いっぱいを、1 文字 12 バイトの最悪の符号化（サロゲート対の \\u エスケープ）で送る。"""
    body = json.dumps(
        {
            "input_text": "😀" * 500,
            "politeness_level": "polite",
            "previous_result": "😀" * 1000,
        },
        ensure_ascii=True,
    ).encode()
    assert len(body) * 3 < BODY_LIMIT
    response = client.post(
        REGENERATE, content=body, headers={**headers, "Content-Type": "application/json"}
    )
    assert response.status_code == 200


def test_401_carries_cors_headers(client: TestClient) -> None:
    """Flutter Web は CORS ヘッダの無い応答の状態コードを読めない。"""
    response = client.post(
        CONVERT,
        content=_malformed_json(1024 * 1024),
        headers={
            "Content-Type": "application/json",
            "Origin": ORIGIN,
            "X-Forwarded-For": fresh_ip(),
        },
    )
    assert response.status_code == 401
    assert response.headers["access-control-allow-origin"] == ORIGIN
    assert response.headers["access-control-allow-credentials"] == "true"
