"""SDK 境界の失敗注入（落ちる／遅い／不正応答）と、例外連鎖に秘密を残さないことの検証。"""

from __future__ import annotations

import json
from collections.abc import Iterator

import httpx
import pytest
import respx
from pydantic import SecretStr

from app.ai.prompts import PolitenessLevel, conversion_prompt
from app.ai.providers import AnthropicProvider, OpenAIProvider, WorkersAIProvider, build_provider
from app.errors import ErrorCode, SafeError
from tests.conftest import make_config

ANTHROPIC_URL = "https://api.anthropic.com/v1/messages"
OPENAI_URL = "https://api.openai.com/v1/chat/completions"
CF_ACCOUNT = "0123456789abcdef0123456789abcdef"
WORKERS_AI_URL = (
    f"https://api.cloudflare.com/client/v4/accounts/{CF_ACCOUNT}/ai/v1/chat/completions"
)
GEMMA = "@cf/google/gemma-4-26b-a4b-it"
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


def openai_body(text: str | None, finish: str = "stop") -> dict[str, object]:
    return {
        "id": "c1",
        "object": "chat.completion",
        "created": 1,
        "model": "m",
        "choices": [
            {"index": 0, "message": {"role": "assistant", "content": text}, "finish_reason": finish}
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


async def test_openai_request_fits_reasoning_models(http: respx.MockRouter) -> None:
    # gpt-6-luna の実測（2026-09-26）: max_tokens は 400、推論ありで temperature≠1 も 400。
    # 推論を切れば temperature（再生成で言い回しを変えるのに使う）を受け付ける。
    route = http.post(OPENAI_URL).mock(
        return_value=httpx.Response(200, json=openai_body("お水をください"))
    )
    provider = OpenAIProvider(SecretStr("sk"), model="m", timeout_seconds=1.0)
    try:
        await provider.complete(PROMPT)
    finally:
        await provider.aclose()
    sent = json.loads(route.calls[0].request.content)
    assert "max_tokens" not in sent
    assert sent["max_completion_tokens"] == PROMPT.max_tokens
    assert sent["reasoning_effort"] == "none"
    assert sent["temperature"] == PROMPT.temperature


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
        # 上限で切れた文は、言っていないことになり得る（守る約束 ③）。見せずに失敗にする
        (httpx.Response(200, json=openai_body("お水を", "length")), ErrorCode.AI_API_ERROR),
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
    assert info.value.cause_type  # 型名は残す（診断用）。Anthropic 側と揃える


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


def workers_ai(gateway_id: str = "") -> WorkersAIProvider:
    return WorkersAIProvider(
        SecretStr(SYMBOL_KEY),
        account_id=CF_ACCOUNT,
        model=GEMMA,
        gateway_id=gateway_id,
        timeout_seconds=1.0,
    )


async def test_workers_ai_turns_off_thinking_and_routes_through_the_gateway(
    http: respx.MockRouter,
) -> None:
    # Gemma 4 は推論を切らないと上限まで考えて本文が空になる（2026-09-26 実測）
    route = http.post(WORKERS_AI_URL).mock(
        return_value=httpx.Response(200, json=openai_body("お水をください"))
    )
    provider = workers_ai(gateway_id="kotonoha-prod")
    try:
        assert await provider.complete(PROMPT) == "お水をください"
    finally:
        await provider.aclose()
    request = route.calls[0].request
    assert request.headers["authorization"] == f"Bearer {SYMBOL_KEY}"
    assert request.headers["cf-aig-gateway-id"] == "kotonoha-prod"
    sent = json.loads(request.content)
    assert sent["model"] == GEMMA
    assert sent["max_tokens"] == PROMPT.max_tokens
    assert sent["temperature"] == PROMPT.temperature
    assert sent["chat_template_kwargs"] == {"enable_thinking": False}
    assert route.calls.call_count == 1  # SDK 内蔵リトライは 0


async def test_workers_ai_without_gateway_sends_no_gateway_header(
    http: respx.MockRouter,
) -> None:
    route = http.post(WORKERS_AI_URL).mock(
        return_value=httpx.Response(200, json=openai_body("お水をください"))
    )
    provider = workers_ai()
    try:
        await provider.complete(PROMPT)
    finally:
        await provider.aclose()
    assert "cf-aig-gateway-id" not in route.calls[0].request.headers


@pytest.mark.parametrize(
    ("response", "code"),
    [
        (
            httpx.Response(429, json={"errors": [{"message": "CANARY"}]}),
            ErrorCode.AI_RATE_LIMIT,
        ),
        (httpx.Response(200, json=openai_body("")), ErrorCode.AI_API_ERROR),
        (httpx.Response(200, json=openai_body("お水を", "length")), ErrorCode.AI_API_ERROR),
    ],
)
async def test_workers_ai_failures_become_safe_errors(
    http: respx.MockRouter, response: httpx.Response, code: ErrorCode
) -> None:
    http.post(WORKERS_AI_URL).mock(return_value=response)
    provider = workers_ai()
    try:
        with pytest.raises(SafeError) as info:
            await provider.complete(PROMPT)
    finally:
        await provider.aclose()
    assert info.value.code is code and info.value.__context__ is None
    assert "CANARY" not in repr(info.value)
    assert info.value.cause_type


def test_build_provider_builds_workers_ai_only_with_token_and_account() -> None:
    ok = make_config(DEFAULT_AI_PROVIDER="workers_ai", CF_API_TOKEN="t", CF_ACCOUNT_ID=CF_ACCOUNT)
    assert build_provider(ok).name == "workers_ai"
    assert (
        build_provider(make_config(DEFAULT_AI_PROVIDER="workers_ai", CF_ACCOUNT_ID=CF_ACCOUNT))
        is None
    )
