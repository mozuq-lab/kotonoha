"""再試行と締切（B-1 べき等性・時間）。"""

from __future__ import annotations

import asyncio

import pytest

from app.ai.prompts import PolitenessLevel, Prompt
from app.ai.service import ConversionService
from app.config import ProviderName
from app.errors import ErrorCode, SafeError


class ScriptedProvider:
    name: ProviderName = "anthropic"

    def __init__(self, *outcomes: str | SafeError | float) -> None:
        self._outcomes = list(outcomes)
        self.calls = 0

    async def complete(self, prompt: Prompt) -> str:
        self.calls += 1
        outcome = self._outcomes.pop(0)
        if isinstance(outcome, float):
            await asyncio.sleep(outcome)
            return "遅い"
        if isinstance(outcome, SafeError):
            raise outcome
        return outcome

    async def aclose(self) -> None:
        return None


def service(
    provider: ScriptedProvider | None, *, max_retries: int = 1, deadline: float = 1.0
) -> ConversionService:
    return ConversionService(
        provider, max_retries=max_retries, deadline_seconds=deadline, backoff_seconds=0.0
    )


async def test_success_returns_text() -> None:
    provider = ScriptedProvider("お水をください")
    assert await service(provider).convert("水", PolitenessLevel.NORMAL) == "お水をください"
    assert provider.calls == 1


async def test_retryable_error_is_retried_up_to_max() -> None:
    provider = ScriptedProvider(SafeError(ErrorCode.AI_RATE_LIMIT, retryable=True), "二回目")
    assert (
        await service(provider, max_retries=1).regenerate("水", PolitenessLevel.POLITE, "前")
        == "二回目"
    )
    assert provider.calls == 2


async def test_retries_exhausted_raises_last_error() -> None:
    provider = ScriptedProvider(
        *(SafeError(ErrorCode.AI_RATE_LIMIT, retryable=True) for _ in range(3))
    )
    with pytest.raises(SafeError) as info:
        await service(provider, max_retries=2).convert("水", PolitenessLevel.NORMAL)
    assert info.value.code is ErrorCode.AI_RATE_LIMIT and provider.calls == 3


async def test_non_retryable_error_is_not_retried() -> None:
    provider = ScriptedProvider(SafeError(ErrorCode.AI_API_TIMEOUT), "never")
    with pytest.raises(SafeError) as info:
        await service(provider, max_retries=3).convert("水", PolitenessLevel.NORMAL)
    assert info.value.code is ErrorCode.AI_API_TIMEOUT and provider.calls == 1


async def test_deadline_covers_all_attempts() -> None:
    provider = ScriptedProvider(5.0)
    with pytest.raises(SafeError) as info:
        await service(provider, deadline=0.2).convert("水", PolitenessLevel.NORMAL)
    assert info.value.code is ErrorCode.AI_API_TIMEOUT and info.value.__context__ is None


async def test_missing_provider_is_provider_error() -> None:
    svc = service(None)
    assert svc.provider_name == "none"
    with pytest.raises(SafeError) as info:
        await svc.convert("水", PolitenessLevel.NORMAL)
    assert info.value.code is ErrorCode.AI_PROVIDER_ERROR
