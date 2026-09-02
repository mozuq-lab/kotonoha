"""AI プロバイダ SDK との境界。SDK 例外はここで *型だけ* 拾い、SafeError に変える（ADR-003）。

モックはこの境界の外側（HTTP、respx）にのみ置く。SDK 内蔵のリトライは 0 にする
（再試行と締切は service が一元管理する。計画 D4）。想定外の例外もここで型名だけ拾う（D5）。
"""

from __future__ import annotations

from typing import Protocol

import anthropic
import httpx
import openai
from anthropic.types import TextBlock
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


class OpenAIProvider:
    name: ProviderName = "openai"

    def __init__(self, api_key: SecretStr, *, model: str, timeout_seconds: float) -> None:
        self._model = model
        self._client = openai.AsyncOpenAI(
            api_key=api_key.get_secret_value(), max_retries=0, timeout=timeout_seconds
        )

    async def complete(self, prompt: Prompt) -> str:
        code: ErrorCode | None = None
        cause: type[BaseException] | None = None
        retryable = False
        text = ""
        try:
            completion = await self._client.chat.completions.create(
                model=self._model,
                messages=[
                    {"role": "system", "content": prompt.system},
                    {"role": "user", "content": prompt.user},
                ],
                max_tokens=prompt.max_tokens,
                temperature=prompt.temperature,
            )
            content = completion.choices[0].message.content if completion.choices else None
            text = content.strip() if content else ""
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
        except _EmptyCompletionError as exc:
            code, cause = ErrorCode.AI_API_ERROR, type(exc)
        except Exception as exc:
            code, cause = ErrorCode.INTERNAL_ERROR, type(exc)
        if code is not None:
            raise SafeError(code, cause=cause, retryable=retryable)
        return text

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
    return OpenAIProvider(key, model=config.OPENAI_MODEL, timeout_seconds=config.AI_API_TIMEOUT)
