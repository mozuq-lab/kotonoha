"""IP ごとの burst 抑制（ADR-002）。XFF の扱いを含む。"""

from __future__ import annotations

import time

import respx
from fastapi.testclient import TestClient

from tests.contract.conftest import CONTRACT_ENV, fresh_ip

CONVERT = "/api/v1/ai/convert"
REGENERATE = "/api/v1/ai/regenerate"
BODY = {"input_text": "水 ぬるく", "politeness_level": "normal"}
REGEN_BODY = {**BODY, "previous_result": "お水をください"}
WINDOW = int(CONTRACT_ENV["RATE_LIMIT_SECONDS"])


def _headers(ip: str) -> dict[str, str]:
    return {"X-API-Key": "contract-key-A", "X-Forwarded-For": ip}


def test_second_request_in_window_is_429(
    client: TestClient, provider_http: respx.MockRouter
) -> None:
    ip = fresh_ip()
    assert client.post(CONVERT, json=BODY, headers=_headers(ip)).status_code == 200
    response = client.post(CONVERT, json=BODY, headers=_headers(ip))
    assert response.status_code == 429
    data = response.json()
    assert data["success"] is False and data["data"] is None
    error = data["error"]
    assert error["code"] == "RATE_LIMIT_EXCEEDED"
    assert error["status_code"] == 429
    assert (
        error["message"] == "リクエスト数が上限に達しました。しばらく待ってから再試行してください。"
    )
    assert isinstance(error["retry_after"], int) and 1 <= error["retry_after"] <= WINDOW
    assert 1 <= int(response.headers["retry-after"]) <= WINDOW
    assert response.headers["x-ratelimit-limit"] == CONTRACT_ENV["RATE_LIMIT_TIMES"]
    assert response.headers["x-ratelimit-remaining"] == "0"
    assert 1 <= int(response.headers["x-ratelimit-reset"]) <= WINDOW


def test_limit_resets_after_window(client: TestClient, provider_http: respx.MockRouter) -> None:
    ip = fresh_ip()
    assert client.post(CONVERT, json=BODY, headers=_headers(ip)).status_code == 200
    time.sleep(WINDOW + 0.2)
    assert client.post(CONVERT, json=BODY, headers=_headers(ip)).status_code == 200


def test_convert_and_regenerate_have_independent_counters(
    client: TestClient, provider_http: respx.MockRouter
) -> None:
    ip = fresh_ip()
    assert client.post(CONVERT, json=BODY, headers=_headers(ip)).status_code == 200
    assert client.post(REGENERATE, json=REGEN_BODY, headers=_headers(ip)).status_code == 200
    assert client.post(REGENERATE, json=REGEN_BODY, headers=_headers(ip)).status_code == 429


def test_different_sources_are_independent(
    client: TestClient, provider_http: respx.MockRouter
) -> None:
    assert client.post(CONVERT, json=BODY, headers=_headers(fresh_ip())).status_code == 200
    assert client.post(CONVERT, json=BODY, headers=_headers(fresh_ip())).status_code == 200


def test_rightmost_trusted_hop_is_used_not_leftmost(
    client: TestClient, provider_http: respx.MockRouter
) -> None:
    """左端（クライアントが自由に書ける値）を信じない。TRUSTED_PROXY_COUNT=1 なら右端。"""
    trusted = fresh_ip()
    first = client.post(CONVERT, json=BODY, headers=_headers(f"{fresh_ip()}, {trusted}"))
    second = client.post(CONVERT, json=BODY, headers=_headers(f"{fresh_ip()}, {trusted}"))
    assert (first.status_code, second.status_code) == (200, 429)


def test_missing_forwarded_for_falls_back_to_peer_address(
    client: TestClient, provider_http: respx.MockRouter
) -> None:
    """チェーンが段数に満たなければ XFF を採用せず接続元へ（フェイルクローズ）。"""
    no_xff = {"X-API-Key": "contract-key-A"}
    first = client.post(CONVERT, json=BODY, headers=no_xff)
    second = client.post(CONVERT, json=BODY, headers=no_xff)
    assert (first.status_code, second.status_code) == (200, 429)
