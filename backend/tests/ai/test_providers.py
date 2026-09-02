"""SDK 境界。B-1 失敗注入（落ちる／遅い／不正応答）と B-3-5（例外連鎖に秘密を残さない）。"""

from __future__ import annotations

from collections.abc import Iterator

import httpx
import pytest
import respx
from pydantic import SecretStr

from app.ai.prompts import PolitenessLevel, conversion_prompt
from app.ai.providers import AnthropicProvider, OpenAIProvider, build_provider
from app.errors import ErrorCode, SafeError
from tests.conftest import make_config

ANTHROPIC_URL = "https://api.anthropic.com/v1/messages"
OPENAI_URL = "https://api.openai.com/v1/chat/completions"
SYMBOL_KEY = "sk-k%40@#=/+!?"
PROMPT = conversion_prompt("水 ぬるく", PolitenessLevel.NORMAL)


def anthropic_body(text: str) -> dict[str, object]:
    return {
        "id": "msg_1",
        "type": "message",
        "role": "assistant",
        "model": "m",
        "content": [{"type": "text", "text": text}],
        "stop_reason": "end_turn",
        "stop_sequence": None,
        "usage": {"input_tokens": 1, "output_tokens": 1},
    }


def openai_body(text: str | None) -> dict[str, object]:
    return {
        "id": "c1",
        "object": "chat.completion",
        "created": 1,
        "model": "m",
        "choices": [
            {"index": 0, "message": {"role": "assistant", "content": text}, "finish_reason": "stop"}
        ],
        "usage": {"prompt_tokens": 1, "completion_tokens": 1, "total_tokens": 2},
    }


@pytest.fixture
def http() -> Iterator[respx.MockRouter]:
    with respx.mock(assert_all_mocked=True, assert_all_called=False) as router:
        yield router


async def test_anthropic_sends_symbol_key_verbatim_and_returns_text(http: respx.MockRouter) -> None:
    route = http.post(ANTHROPIC_URL).mock(
        return_value=httpx.Response(200, json=anthropic_body("  お水をください  "))
    )
    provider = AnthropicProvider(SecretStr(SYMBOL_KEY), model="m", timeout_seconds=1.0)
    try:
        assert await provider.complete(PROMPT) == "お水をください"
    finally:
        await provider.aclose()
    assert route.calls[0].request.headers["x-api-key"] == SYMBOL_KEY
    assert route.calls.call_count == 1  # SDK 内蔵リトライは 0


async def test_openai_sends_symbol_key_verbatim(http: respx.MockRouter) -> None:
    route = http.post(OPENAI_URL).mock(
        return_value=httpx.Response(200, json=openai_body("お水をください"))
    )
    provider = OpenAIProvider(SecretStr(SYMBOL_KEY), model="m", timeout_seconds=1.0)
    try:
        assert await provider.complete(PROMPT) == "お水をください"
    finally:
        await provider.aclose()
    assert route.calls[0].request.headers["authorization"] == f"Bearer {SYMBOL_KEY}"


@pytest.mark.parametrize(
    ("mock_kwargs", "code", "retryable"),
    [
        ({"side_effect": httpx.ReadTimeout("t")}, ErrorCode.AI_API_TIMEOUT, False),
        ({"side_effect": httpx.ConnectError("c")}, ErrorCode.AI_API_ERROR, True),
        (
            {
                "return_value": httpx.Response(
                    429,
                    json={
                        "type": "error",
                        "error": {"type": "rate_limit_error", "message": "CANARY-429"},
                    },
                )
            },
            ErrorCode.AI_RATE_LIMIT,
            True,
        ),
        (
            {
                "return_value": httpx.Response(
                    500,
                    json={"type": "error", "error": {"type": "api_error", "message": "CANARY-500"}},
                )
            },
            ErrorCode.AI_API_ERROR,
            False,
        ),
        (
            {
                "return_value": httpx.Response(
                    401,
                    json={
                        "type": "error",
                        "error": {"type": "authentication_error", "message": "CANARY-401"},
                    },
                )
            },
            ErrorCode.AI_API_ERROR,
            False,
        ),
        (
            {"return_value": httpx.Response(200, json={**anthropic_body("x"), "content": []})},
            ErrorCode.AI_API_ERROR,
            False,
        ),
        (
            {"return_value": httpx.Response(200, content=b"not json")},
            ErrorCode.INTERNAL_ERROR,
            False,
        ),
    ],
)
async def test_anthropic_failures_become_safe_errors(
    http: respx.MockRouter, mock_kwargs: dict[str, object], code: ErrorCode, retryable: bool
) -> None:
    http.post(ANTHROPIC_URL).mock(**mock_kwargs)
    provider = AnthropicProvider(SecretStr("sk"), model="m", timeout_seconds=1.0)
    try:
        with pytest.raises(SafeError) as info:
            await provider.complete(PROMPT)
    finally:
        await provider.aclose()
    err = info.value
    assert err.code is code and err.retryable is retryable
    assert err.__context__ is None and err.__cause__ is None
    assert "CANARY" not in repr(err) and "CANARY" not in (err.cause_type or "")
    assert err.cause_type  # 型名は残す（診断用）


@pytest.mark.parametrize(
    ("response", "code"),
    [
        (
            httpx.Response(429, json={"error": {"message": "CANARY", "type": "x"}}),
            ErrorCode.AI_RATE_LIMIT,
        ),
        (httpx.Response(200, json=openai_body(None)), ErrorCode.AI_API_ERROR),
        (httpx.Response(200, json=openai_body("   ")), ErrorCode.AI_API_ERROR),
    ],
)
async def test_openai_failures_become_safe_errors(
    http: respx.MockRouter, response: httpx.Response, code: ErrorCode
) -> None:
    http.post(OPENAI_URL).mock(return_value=response)
    provider = OpenAIProvider(SecretStr("sk"), model="m", timeout_seconds=1.0)
    try:
        with pytest.raises(SafeError) as info:
            await provider.complete(PROMPT)
    finally:
        await provider.aclose()
    assert info.value.code is code and info.value.__context__ is None


def test_build_provider_follows_default_provider_and_key_presence() -> None:
    assert (
        build_provider(make_config(ANTHROPIC_API_KEY="", DEFAULT_AI_PROVIDER="anthropic")) is None
    )
    assert build_provider(make_config(DEFAULT_AI_PROVIDER="anthropic")).name == "anthropic"
    assert (
        build_provider(make_config(DEFAULT_AI_PROVIDER="openai", OPENAI_API_KEY="sk-o")).name
        == "openai"
    )
    assert build_provider(make_config(DEFAULT_AI_PROVIDER="openai", OPENAI_API_KEY="")) is None
