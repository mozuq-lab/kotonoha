"""変換サービス。再試行と締切をここで一元管理する（計画 D4）。"""

from __future__ import annotations

import asyncio

from app.ai.prompts import PolitenessLevel, Prompt, conversion_prompt, regeneration_prompt
from app.ai.providers import Provider
from app.errors import ErrorCode, SafeError


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
        return await self._run(conversion_prompt(input_text, level))

    async def regenerate(
        self, input_text: str, level: PolitenessLevel, previous_result: str
    ) -> str:
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
