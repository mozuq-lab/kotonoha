"""AI プロバイダ SDK との境界。SDK 例外はここで *型だけ* 拾い、SafeError に変える（ADR-003）。

モックはこの境界の外側（HTTP、respx）にのみ置く。SDK 内蔵のリトライは 0 にする
（再試行と締切は service が一元管理する。計画 D4）。想定外の例外もここで型名だけ拾う（D5）。
"""

from __future__ import annotations

from collections.abc import Awaitable, Callable
from typing import Protocol

import anthropic
import httpx
import openai
from anthropic.types import TextBlock
from openai.types.chat import (
    ChatCompletion,
    ChatCompletionMessageParam,
    ChatCompletionSystemMessageParam,
    ChatCompletionUserMessageParam,
)
from pydantic import SecretStr

from app.ai.prompts import Prompt
from app.config import ProviderName, RuntimeConfig
from app.errors import ErrorCode, SafeError


class _EmptyCompletionError(Exception):
    """SDK 応答にテキストが無かった内部シグナル（外部へは出さない）。

    診断用に cause_type を残すため、SafeError を直接 raise せず一度この例外を経由する。
    """


class Provider(Protocol):
    @property
    def name(self) -> ProviderName: ...

    async def complete(self, prompt: Prompt) -> str: ...

    async def aclose(self) -> None: ...


class AnthropicProvider:
    name: ProviderName = "anthropic"

    def __init__(self, api_key: SecretStr, *, model: str, timeout_seconds: float) -> None:
        self._model = model
        self._client = anthropic.AsyncAnthropic(
            api_key=api_key.get_secret_value(),
            max_retries=0,
            timeout=timeout_seconds,
            # anthropic 0.39.0 は http_client 未指定時、内部で
            # `httpx.AsyncClient(..., proxies=None, ...)` を組み立てるが、
            # httpx 0.28 は `proxies` 引数を廃止済みで TypeError になる
            # （このリポジトリの requirements.txt 固定版で実測）。
            # 明示的に http_client を渡すとその経路を通らず回避できる。
            http_client=httpx.AsyncClient(follow_redirects=True),
        )

    async def complete(self, prompt: Prompt) -> str:
        code: ErrorCode | None = None
        cause: type[BaseException] | None = None
        retryable = False
        text = ""
        try:
            message = await self._client.messages.create(
                model=self._model,
                max_tokens=prompt.max_tokens,
                temperature=prompt.temperature,
                system=prompt.system,
                messages=[{"role": "user", "content": prompt.user}],
            )
            text = _first_text(message)
            if not text:
                raise _EmptyCompletionError
        except anthropic.APITimeoutError as exc:  # APIConnectionError の子なので先に見る
            code, cause = ErrorCode.AI_API_TIMEOUT, type(exc)
        except anthropic.RateLimitError as exc:
            code, cause, retryable = ErrorCode.AI_RATE_LIMIT, type(exc), True
        except anthropic.APIConnectionError as exc:
            code, cause, retryable = ErrorCode.AI_API_ERROR, type(exc), True
        except anthropic.APIStatusError as exc:
            code, cause = ErrorCode.AI_API_ERROR, type(exc)
        except _EmptyCompletionError as exc:
            code, cause = ErrorCode.AI_API_ERROR, type(exc)
        except Exception as exc:  # SDK 内部の想定外。メッセージは持ち出さない
            code, cause = ErrorCode.INTERNAL_ERROR, type(exc)
        if code is not None:
            raise SafeError(code, cause=cause, retryable=retryable)  # except の外
        return text

    async def aclose(self) -> None:
        await self._client.close()


def _first_text(message: anthropic.types.Message) -> str:
    for block in message.content:
        if isinstance(block, TextBlock) and block.text.strip():
            return block.text.strip()
    return ""


class _TruncatedCompletionError(Exception):
    """出力が上限で切れた内部シグナル。途中までの文は言っていないことになり得るので見せない。"""


async def _complete_openai_compatible(call: Callable[[], Awaitable[ChatCompletion]]) -> str:
    """OpenAI 互換の chat completions を 1 回呼ぶ。SDK 例外は型だけ拾って SafeError にする。"""
    code: ErrorCode | None = None
    cause: type[BaseException] | None = None
    retryable = False
    text = ""
    try:
        completion = await call()
        choice = completion.choices[0] if completion.choices else None
        content = choice.message.content if choice else None
        text = content.strip() if content else ""
        if choice is not None and choice.finish_reason == "length":
            raise _TruncatedCompletionError
        if not text:
            raise _EmptyCompletionError
    except openai.APITimeoutError as exc:
        code, cause = ErrorCode.AI_API_TIMEOUT, type(exc)
    except openai.RateLimitError as exc:
        code, cause, retryable = ErrorCode.AI_RATE_LIMIT, type(exc), True
    except openai.APIConnectionError as exc:
        code, cause, retryable = ErrorCode.AI_API_ERROR, type(exc), True
    except openai.APIStatusError as exc:
        code, cause = ErrorCode.AI_API_ERROR, type(exc)
    except (_EmptyCompletionError, _TruncatedCompletionError) as exc:
        code, cause = ErrorCode.AI_API_ERROR, type(exc)
    except Exception as exc:
        code, cause = ErrorCode.INTERNAL_ERROR, type(exc)
    if code is not None:
        raise SafeError(code, cause=cause, retryable=retryable)
    return text


def _messages(prompt: Prompt) -> list[ChatCompletionMessageParam]:
    return [
        ChatCompletionSystemMessageParam(role="system", content=prompt.system),
        ChatCompletionUserMessageParam(role="user", content=prompt.user),
    ]


class OpenAIProvider:
    name: ProviderName = "openai"

    def __init__(self, api_key: SecretStr, *, model: str, timeout_seconds: float) -> None:
        self._model = model
        self._client = openai.AsyncOpenAI(
            api_key=api_key.get_secret_value(), max_retries=0, timeout=timeout_seconds
        )

    async def complete(self, prompt: Prompt) -> str:
        return await _complete_openai_compatible(
            lambda: self._client.chat.completions.create(
                model=self._model,
                messages=_messages(prompt),
                # 推論モデル（gpt-6-luna 等）は max_tokens を拒否し、推論ありでは temperature≠1 も
                # 拒否する。短文の変換に推論は要らないので切り、temperature を効かせる（実測）。
                max_completion_tokens=prompt.max_tokens,
                reasoning_effort="none",
                temperature=prompt.temperature,
            )
        )

    async def aclose(self) -> None:
        await self._client.close()


class WorkersAIProvider:
    """Cloudflare Workers AI の OpenAI 互換 API。gateway_id があれば AI Gateway を通す。"""

    name: ProviderName = "workers_ai"

    def __init__(
        self,
        api_token: SecretStr,
        *,
        account_id: str,
        model: str,
        gateway_id: str,
        timeout_seconds: float,
    ) -> None:
        self._model = model
        self._client = openai.AsyncOpenAI(
            api_key=api_token.get_secret_value(),
            base_url=f"https://api.cloudflare.com/client/v4/accounts/{account_id}/ai/v1",
            default_headers={"cf-aig-gateway-id": gateway_id} if gateway_id else None,
            max_retries=0,
            timeout=timeout_seconds,
        )

    async def complete(self, prompt: Prompt) -> str:
        return await _complete_openai_compatible(
            lambda: self._client.chat.completions.create(
                model=self._model,
                messages=_messages(prompt),
                max_tokens=prompt.max_tokens,
                temperature=prompt.temperature,
                # Gemma 4 などは推論を切らないと上限まで考えて本文が空になる（2026-09-26 実測）
                extra_body={"chat_template_kwargs": {"enable_thinking": False}},
            )
        )

    async def aclose(self) -> None:
        await self._client.close()


def build_provider(config: RuntimeConfig) -> Provider | None:
    """DEFAULT_AI_PROVIDER のキーがあればその client を作る。無ければ None（health は "none"）。"""
    key = config.provider_api_key(config.DEFAULT_AI_PROVIDER)
    if key is None:
        return None
    if config.DEFAULT_AI_PROVIDER == "anthropic":
        return AnthropicProvider(
            key, model=config.ANTHROPIC_MODEL, timeout_seconds=config.AI_API_TIMEOUT
        )
    if config.DEFAULT_AI_PROVIDER == "workers_ai":
        if not config.CF_ACCOUNT_ID:
            return None
        return WorkersAIProvider(
            key,
            account_id=config.CF_ACCOUNT_ID,
            model=config.WORKERS_AI_MODEL,
            gateway_id=config.CF_AI_GATEWAY_ID,
            timeout_seconds=config.AI_API_TIMEOUT,
        )
    return OpenAIProvider(key, model=config.OPENAI_MODEL, timeout_seconds=config.AI_API_TIMEOUT)
