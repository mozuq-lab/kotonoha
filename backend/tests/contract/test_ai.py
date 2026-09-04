"""POST /api/v1/ai/convert と /regenerate の外部契約。"""

from __future__ import annotations

import asyncio

import httpx
import pytest
import respx
from fastapi.testclient import TestClient

from tests.contract.conftest import ANTHROPIC_MESSAGES_URL, anthropic_success

CONVERT = "/api/v1/ai/convert"
REGENERATE = "/api/v1/ai/regenerate"
ERROR_SHAPE_KEYS = {"success", "data", "error"}


def _post_convert(client: TestClient, headers: dict[str, str], **body: object) -> httpx.Response:
    payload: dict[str, object] = {"input_text": "水 ぬるく", "politeness_level": "normal"}
    payload.update(body)
    return client.post(CONVERT, json=payload, headers=headers)


def test_convert_returns_flat_body(
    client: TestClient, headers: dict[str, str], provider_http: respx.MockRouter
) -> None:
    response = _post_convert(client, headers, input_text="  水 ぬるく  ", politeness_level="polite")
    assert response.status_code == 200
    body = response.json()
    assert set(body) == {
        "converted_text",
        "original_text",
        "politeness_level",
        "processing_time_ms",
    }
    assert body["converted_text"] == "お水をぬるめでお願いします"
    assert body["original_text"] == "水 ぬるく"  # 前後の空白は落として返す
    assert body["politeness_level"] == "polite"
    assert isinstance(body["processing_time_ms"], int) and body["processing_time_ms"] >= 0
    for name in ("x-ratelimit-limit", "x-ratelimit-remaining", "x-ratelimit-reset"):
        assert name not in response.headers


def test_regenerate_returns_flat_body(
    client: TestClient, headers: dict[str, str], provider_http: respx.MockRouter
) -> None:
    response = client.post(
        REGENERATE,
        json={
            "input_text": "水 ぬるく",
            "politeness_level": "normal",
            "previous_result": "お水をください",
        },
        headers=headers,
    )
    assert response.status_code == 200
    assert set(response.json()) == {
        "converted_text",
        "original_text",
        "politeness_level",
        "processing_time_ms",
    }


@pytest.mark.parametrize(
    "body",
    [
        {"input_text": "あ"},
        {"input_text": "あ" * 501},
        {"input_text": "   "},
        {"input_text": ""},
        {"politeness_level": "very_polite"},
        {"input_text": None},
        {"politeness_level": None},
    ],
)
def test_convert_validation_error_shape(
    client: TestClient, headers: dict[str, str], body: dict[str, object]
) -> None:
    payload: dict[str, object] = {"input_text": "水 ぬるく", "politeness_level": "normal"}
    payload.update(body)
    payload = {k: v for k, v in payload.items() if v is not None}
    response = client.post(CONVERT, json=payload, headers=headers)
    assert response.status_code == 422
    data = response.json()
    assert data["error_code"] == "VALIDATION_ERROR"
    assert isinstance(data["error"], str)
    assert isinstance(data["detail"], list) and data["detail"]
    assert {"type", "loc", "msg"} <= set(data["detail"][0])


@pytest.mark.parametrize("previous_result", ["", "   ", "あ" * 1001])
def test_regenerate_previous_result_validation(
    client: TestClient, headers: dict[str, str], previous_result: str
) -> None:
    response = client.post(
        REGENERATE,
        json={
            "input_text": "水 ぬるく",
            "politeness_level": "normal",
            "previous_result": previous_result,
        },
        headers=headers,
    )
    assert response.status_code == 422
    assert response.json()["error_code"] == "VALIDATION_ERROR"


def test_invalid_json_is_validation_error(client: TestClient, headers: dict[str, str]) -> None:
    response = client.post(
        CONVERT, content=b"{not json", headers={**headers, "Content-Type": "application/json"}
    )
    assert response.status_code == 422
    assert response.json()["error_code"] == "VALIDATION_ERROR"


def _assert_error_shape(response: httpx.Response, status: int, code: str) -> dict[str, object]:
    assert response.status_code == status
    data = response.json()
    assert set(data) == ERROR_SHAPE_KEYS
    assert data["success"] is False and data["data"] is None
    error = data["error"]
    assert error["code"] == code
    assert error["status_code"] == status
    assert isinstance(error["message"], str) and error["message"]
    return error


def test_provider_timeout_is_504(
    client: TestClient, headers: dict[str, str], provider_http: respx.MockRouter
) -> None:
    provider_http.post(ANTHROPIC_MESSAGES_URL).mock(side_effect=httpx.ReadTimeout("read timed out"))
    _assert_error_shape(_post_convert(client, headers), 504, "AI_API_TIMEOUT")


def test_provider_rate_limit_is_429(
    client: TestClient, headers: dict[str, str], provider_http: respx.MockRouter
) -> None:
    provider_http.post(ANTHROPIC_MESSAGES_URL).mock(
        return_value=httpx.Response(
            429,
            json={
                "type": "error",
                "error": {"type": "rate_limit_error", "message": "CANARY-PROVIDER-429"},
            },
        )
    )
    response = _post_convert(client, headers)
    _assert_error_shape(response, 429, "AI_RATE_LIMIT")
    assert "CANARY-PROVIDER-429" not in response.text


def test_provider_server_error_is_500(
    client: TestClient, headers: dict[str, str], provider_http: respx.MockRouter
) -> None:
    provider_http.post(ANTHROPIC_MESSAGES_URL).mock(
        return_value=httpx.Response(
            500,
            json={
                "type": "error",
                "error": {"type": "api_error", "message": "CANARY-PROVIDER-500"},
            },
        )
    )
    response = _post_convert(client, headers)
    _assert_error_shape(response, 500, "AI_API_ERROR")
    assert "CANARY-PROVIDER-500" not in response.text


def test_provider_empty_content_is_500(
    client: TestClient, headers: dict[str, str], provider_http: respx.MockRouter
) -> None:
    body = {**anthropic_success("x").json(), "content": []}
    provider_http.post(ANTHROPIC_MESSAGES_URL).mock(return_value=httpx.Response(200, json=body))
    _assert_error_shape(_post_convert(client, headers), 500, "AI_API_ERROR")


def test_deadline_exceeded_is_504(
    client: TestClient, headers: dict[str, str], provider_http: respx.MockRouter
) -> None:
    async def slow(request: httpx.Request) -> httpx.Response:
        await asyncio.sleep(8)  # AI_CALL_DEADLINE_SECONDS=4 より長い
        return anthropic_success("遅い")

    provider_http.post(ANTHROPIC_MESSAGES_URL).mock(side_effect=slow)
    _assert_error_shape(_post_convert(client, headers), 504, "AI_API_TIMEOUT")
