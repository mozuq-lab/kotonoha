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


@pytest.mark.parametrize(
    ("source", "expected"),
    [
        # IPv6 は /64（1 回線）を 1 つの送信元として数える。アドレスを変えても同じ枠
        ("2001:db8:1:2::1", "2001:db8:1:2::/64"),
        ("2001:db8:1:2:ffff:ffff:ffff:ffff", "2001:db8:1:2::/64"),
        ("2001:DB8:1:2:0:0:0:9", "2001:db8:1:2::/64"),  # 表記の揺れも同じ枠
        ("2001:db8:1:3::1", "2001:db8:1:3::/64"),  # 隣の /64 は別の枠
        # IPv4 と、IPv4 射影の IPv6 は IPv4 のまま
        ("203.0.113.7", "203.0.113.7"),
        ("::ffff:203.0.113.7", "203.0.113.7"),
        # アドレスとして読めない値は、今までどおり文字列のまま使う
        ("spoof", "spoof"),
        ("203.0.113.7:443", "203.0.113.7:443"),
        ("[2001:db8::1]:443", "[2001:db8::1]:443"),
    ],
)
def test_client_identifier_groups_ipv6_by_64(source: str, expected: str) -> None:
    from_xff = client_identifier(
        forwarded_for=source, client_host="10.0.0.1", trusted_proxy_count=1
    )
    from_peer = client_identifier(forwarded_for=None, client_host=source, trusted_proxy_count=0)
    assert (from_xff, from_peer) == (expected, expected)


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


def test_addresses_in_one_ipv6_slash64_share_one_limit() -> None:
    """1 回線（/64）の持ち主がアドレスを変えるだけで枠を増やせないこと。"""
    client = _client(RateLimiter(times=1, seconds=60, trusted_proxy_count=1))
    statuses = [
        client.get("/a", headers={"X-Forwarded-For": ip}).status_code
        for ip in ("2001:db8:a:c::1", "2001:db8:a:c::2", "2001:db8:a:c:1234:5678:9abc:def0")
    ]
    other_network = client.get("/a", headers={"X-Forwarded-For": "2001:db8:a:d::1"})
    assert statuses == [200, 429, 429]
    assert other_network.status_code == 200


def test_ipv4_mapped_ipv6_shares_the_ipv4_limit() -> None:
    client = _client(RateLimiter(times=1, seconds=60, trusted_proxy_count=1))
    first = client.get("/a", headers={"X-Forwarded-For": "198.51.100.9"})
    second = client.get("/a", headers={"X-Forwarded-For": "::ffff:198.51.100.9"})
    assert [first.status_code, second.status_code] == [200, 429]


def test_multiple_xff_header_lines_do_not_bypass_rate_limit() -> None:
    """同名ヘッダーが複数行だと ``.get()`` は先頭の1本しか見ないため、攻撃者が
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


def test_configured_window_still_rejects_after_one_second() -> None:
    """秒数が失われて既定の1秒窓になると、同じ送信元が早く再許可される。"""
    with _client(RateLimiter(times=1, seconds=5, trusted_proxy_count=1)) as client:
        headers = {"X-Forwarded-For": "7.7.7.7"}
        assert client.get("/a", headers=headers).is_success
        time.sleep(1.1)
        response = client.get("/a", headers=headers)
        assert response.is_client_error
        assert 1 < response.json()["retry_after"] <= 5
