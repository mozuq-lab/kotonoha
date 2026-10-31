"""X-API-Key 認証。非ASCII入力への401応答と全キー走査。"""

from __future__ import annotations

import pytest
import respx
from fastapi.testclient import TestClient

from tests.contract.conftest import fresh_ip

CONVERT = "/api/v1/ai/convert"
BODY = {"input_text": "水 ぬるく", "politeness_level": "normal"}


def test_missing_key_is_401_with_www_authenticate(client: TestClient) -> None:
    response = client.post(CONVERT, json=BODY, headers={"X-Forwarded-For": fresh_ip()})
    assert response.status_code == 401
    assert response.headers["www-authenticate"] == "X-API-Key"
    assert isinstance(response.json()["detail"], str)


def test_wrong_key_is_401(client: TestClient) -> None:
    response = client.post(
        CONVERT, json=BODY, headers={"X-API-Key": "contract-key-Z", "X-Forwarded-For": fresh_ip()}
    )
    assert response.status_code == 401


@pytest.mark.parametrize("key", ["contract-key-A", "contract-key-B"])
def test_every_configured_key_is_accepted(
    client: TestClient, provider_http: respx.MockRouter, key: str
) -> None:
    response = client.post(
        CONVERT, json=BODY, headers={"X-API-Key": key, "X-Forwarded-For": fresh_ip()}
    )
    assert response.status_code == 200


def test_non_ascii_key_is_401_not_500(client: TestClient) -> None:
    # httpx の headers= はstr値をASCIIで送信時エンコードするため、非ASCII文字を
    # str のまま渡すとテストクライアント側で UnicodeEncodeError になり、
    # サーバーへ届く前に落ちてしまう（意図した検証にならない）。
    # bytes を直接渡すとエンコードをスキップしてそのままワイヤに乗るため、
    # 実際の「非ASCIIバイト列を含むヘッダー」を送る攻撃/誤入力を再現できる。
    response = client.post(
        CONVERT,
        json=BODY,
        headers={"X-API-Key": "ｋｅｙ".encode("utf-8"), "X-Forwarded-For": fresh_ip()},
    )
    assert response.status_code == 401


def test_unauthenticated_burst_never_reaches_rate_limit(client: TestClient) -> None:
    """認証は制限より前。不正キーの連打は 401 のままで 429 に変わらない（プロバイダにも届かない）。"""
    ip = fresh_ip()
    for _ in range(3):
        response = client.post(
            CONVERT, json=BODY, headers={"X-API-Key": "bad", "X-Forwarded-For": ip}
        )
        assert response.status_code == 401
