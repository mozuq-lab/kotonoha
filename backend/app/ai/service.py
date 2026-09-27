"""変換サービス。再試行と締切をここで一元管理する。"""

from __future__ import annotations

import asyncio

from app.ai.prompts import PolitenessLevel, Prompt, conversion_prompt, regeneration_prompt
from app.ai.providers import Provider
from app.errors import ErrorCode, SafeError

# 答えそのものの言葉。AI に渡すと「いいえ」が「ううん、いいよ」（かまわない、とも取れる）になり、
# 意味が逆になりうる（2026-09-27 実測）。丁寧さを付ける余地も小さいので、送らずにそのまま返す。
# 利用者は発話で訂正できない（守る約束 ③）
_ANSWER_WORDS: frozenset[str] = frozenset({"はい", "いいえ", "うん", "ううん"})


def _answer_word(input_text: str) -> str | None:
    """入力が答えの言葉だけなら、句点を付けて返す。それ以外は None。"""
    word = input_text.strip().rstrip("。．.！!")
    return f"{word}。" if word in _ANSWER_WORDS else None


class ConversionService:
    def __init__(
        self,
        provider: Provider | None,
        *,
        max_retries: int,
        deadline_seconds: float,
        backoff_seconds: float = 0.5,
    ) -> None:
        self._provider = provider
        self._max_retries = max_retries
        self._deadline = deadline_seconds
        self._backoff = backoff_seconds

    @property
    def provider_name(self) -> str:
        return self._provider.name if self._provider is not None else "none"

    async def convert(self, input_text: str, level: PolitenessLevel) -> str:
        if (answer := _answer_word(input_text)) is not None:
            return answer
        return await self._run(conversion_prompt(input_text, level))

    async def regenerate(
        self, input_text: str, level: PolitenessLevel, previous_result: str
    ) -> str:
        if (answer := _answer_word(input_text)) is not None:
            return answer
        return await self._run(regeneration_prompt(input_text, level, previous_result))

    async def _run(self, prompt: Prompt) -> str:
        provider = self._provider
        if provider is None:
            raise SafeError(ErrorCode.AI_PROVIDER_ERROR)
        timed_out = False
        text = ""
        try:
            text = await asyncio.wait_for(
                self._with_retries(provider, prompt), timeout=self._deadline
            )
        except TimeoutError:
            timed_out = True
        if timed_out:
            raise SafeError(ErrorCode.AI_API_TIMEOUT, cause=TimeoutError)  # except の外
        return text

    async def _with_retries(self, provider: Provider, prompt: Prompt) -> str:
        attempts = 1 + self._max_retries
        last: SafeError | None = None
        for attempt in range(attempts):
            try:
                return await provider.complete(prompt)
            except SafeError as exc:
                if not exc.retryable:
                    raise
                last = exc
            if attempt < attempts - 1:
                await asyncio.sleep(self._backoff * (2**attempt))
        assert last is not None
        raise last
