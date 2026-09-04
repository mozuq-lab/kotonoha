from __future__ import annotations

import time

import pytest
from fastapi import Depends, FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.testclient import TestClient

from app.errors import RateLimitExceeded
from app.ratelimit import RateLimiter, client_identifier


@pytest.mark.parametrize(
    ("xff", "host", "count", "expected"),
    [
        (None, "9.9.9.9", 0, "9.9.9.9"),
        ("1.1.1.1", "9.9.9.9", 0, "9.9.9.9"),  # 信頼段数 0 なら XFF を見ない
        ("1.1.1.1, 2.2.2.2", "9.9.9.9", 1, "2.2.2.2"),  # 右から1番目
        ("1.1.1.1, 2.2.2.2, 3.3.3.3", "9.9.9.9", 2, "2.2.2.2"),  # 右から2番目
        ("1.1.1.1", "9.9.9.9", 2, "9.9.9.9"),  # チェーンが短い → 接続元（フェイルクローズ）
        ("", "9.9.9.9", 1, "9.9.9.9"),
        (None, None, 1, "unknown"),
        # 過大設定の失敗形（文書化済み。守りはデプロイ側）: 実 proxy 1段なのに
        # trusted_proxy_count=2 だと、proxy が実IPを追記した末尾から2番目＝
        # 攻撃者が詰めた値を識別子として採用してしまう。
        ("spoof, 203.0.113.10", "10.0.0.1", 2, "spoof"),
    ],
)
def test_client_identifier(xff: str | None, host: str | None, count: int, expected: str) -> None:
    assert (
        client_identifier(forwarded_for=xff, client_host=host, trusted_proxy_count=count)
        == expected
    )


def _client(limiter: RateLimiter) -> TestClient:
    app = FastAPI()

    @app.exception_handler(RateLimitExceeded)
    async def handler(_: Request, exc: RateLimitExceeded) -> JSONResponse:
        return JSONResponse(
            status_code=429, content={"retry_after": exc.retry_after_seconds, "limit": exc.limit}
        )

    @app.get("/a", dependencies=[Depends(limiter.dependency("a"))])
    async def a() -> dict[str, bool]:
        return {"ok": True}

    @app.get("/b", dependencies=[Depends(limiter.dependency("b"))])
    async def b() -> dict[str, bool]:
        return {"ok": True}

    return TestClient(app)


def test_second_hit_in_window_is_rejected_with_numbers() -> None:
    client = _client(RateLimiter(times=1, seconds=1, trusted_proxy_count=1))
    headers = {"X-Forwarded-For": "5.5.5.5"}
    assert client.get("/a", headers=headers).status_code == 200
    response = client.get("/a", headers=headers)
    assert response.status_code == 429
    assert response.json() == {"retry_after": 1, "limit": 1}


def test_namespaces_and_sources_are_independent() -> None:
    client = _client(RateLimiter(times=1, seconds=1, trusted_proxy_count=1))
    assert client.get("/a", headers={"X-Forwarded-For": "5.5.5.5"}).status_code == 200
    assert client.get("/b", headers={"X-Forwarded-For": "5.5.5.5"}).status_code == 200
    assert client.get("/a", headers={"X-Forwarded-For": "6.6.6.6"}).status_code == 200


def test_window_resets() -> None:
    client = _client(RateLimiter(times=1, seconds=1, trusted_proxy_count=1))
    headers = {"X-Forwarded-For": "7.7.7.7"}
    assert client.get("/a", headers=headers).status_code == 200
    time.sleep(1.1)
    assert client.get("/a", headers=headers).status_code == 200


def test_times_greater_than_one() -> None:
    client = _client(RateLimiter(times=2, seconds=5, trusted_proxy_count=1))
    headers = {"X-Forwarded-For": "8.8.8.8"}
    assert [client.get("/a", headers=headers).status_code for _ in range(3)] == [200, 200, 429]


def test_multiple_xff_header_lines_do_not_bypass_rate_limit() -> None:
    """C-1: 同名ヘッダーが複数行だと ``.get()`` は先頭の1本しか見ないため、攻撃者が
    先頭行に任意文字列を置くと毎回別バケットになってしまう（RFC 9110 §5.2: 複数行は
    カンマ結合と等価）。"""
    client = _client(RateLimiter(times=1, seconds=60, trusted_proxy_count=1))
    first = client.get(
        "/a", headers=[("x-forwarded-for", "spoof-1"), ("x-forwarded-for", "5.5.5.5")]
    )
    second = client.get(
        "/a", headers=[("x-forwarded-for", "spoof-2"), ("x-forwarded-for", "5.5.5.5")]
    )
    assert [first.status_code, second.status_code] == [200, 429]
