"""
AIクライアント堅牢化テスト

ai_client.py の以下の堅牢化を検証する:
- SDKの型付き例外（APITimeoutError / RateLimitError）→ アプリ例外への正確なマッピング
- 空content/不正レスポンスの検証（None参照による未捕捉500の防止）
- 明示生成した httpx クライアントの aclose によるクリーンアップ
"""

from types import SimpleNamespace
from unittest.mock import AsyncMock

import anthropic
import httpx
import openai
import pytest

from app.utils.ai_client import (
    AIClient,
    _extract_anthropic_text,
    _extract_openai_text,
    _map_provider_exception,
)
from app.utils.exceptions import (
    AIConversionException,
    AIRateLimitException,
    AITimeoutException,
)

_REQ = httpx.Request("POST", "http://test")


# ============================================================
# 例外マッピング（型付き優先）
# ============================================================


class TestMapProviderException:
    def test_anthropic_timeout_maps_to_ai_timeout(self):
        err = anthropic.APITimeoutError(request=_REQ)
        mapped = _map_provider_exception(err, "Claude")
        assert isinstance(mapped, AITimeoutException)

    def test_anthropic_rate_limit_maps_to_ai_rate_limit(self):
        err = anthropic.RateLimitError(
            "rate limited", response=httpx.Response(429, request=_REQ), body=None
        )
        mapped = _map_provider_exception(err, "Claude")
        assert isinstance(mapped, AIRateLimitException)

    def test_openai_timeout_maps_to_ai_timeout(self):
        err = openai.APITimeoutError(request=_REQ)
        mapped = _map_provider_exception(err, "OpenAI")
        assert isinstance(mapped, AITimeoutException)

    def test_status_code_429_maps_to_rate_limit(self):
        err = Exception("boom")
        err.status_code = 429  # type: ignore[attr-defined]
        mapped = _map_provider_exception(err, "AI")
        assert isinstance(mapped, AIRateLimitException)

    def test_string_fallback_timeout(self):
        mapped = _map_provider_exception(Exception("Connection timeout occurred"), "AI")
        assert isinstance(mapped, AITimeoutException)

    def test_generic_error_maps_to_conversion_error(self):
        mapped = _map_provider_exception(Exception("something else"), "AI")
        assert isinstance(mapped, AIConversionException)


# ============================================================
# レスポンス本文抽出（空/不正レスポンス検証）
# ============================================================


class TestExtractText:
    def test_anthropic_valid(self):
        response = SimpleNamespace(content=[SimpleNamespace(text="  こんにちは  ")])
        assert _extract_anthropic_text(response) == "こんにちは"

    def test_anthropic_empty_content_raises(self):
        with pytest.raises(AIConversionException):
            _extract_anthropic_text(SimpleNamespace(content=[]))

    def test_anthropic_no_text_attr_raises(self):
        response = SimpleNamespace(content=[SimpleNamespace(text=None)])
        with pytest.raises(AIConversionException):
            _extract_anthropic_text(response)

    def test_openai_valid(self):
        response = SimpleNamespace(
            choices=[SimpleNamespace(message=SimpleNamespace(content=" ありがとう "))]
        )
        assert _extract_openai_text(response) == "ありがとう"

    def test_openai_no_choices_raises(self):
        with pytest.raises(AIConversionException):
            _extract_openai_text(SimpleNamespace(choices=[]))

    def test_openai_none_content_raises(self):
        response = SimpleNamespace(choices=[SimpleNamespace(message=SimpleNamespace(content=None))])
        with pytest.raises(AIConversionException):
            _extract_openai_text(response)


# ============================================================
# 変換メソッドの統合（型付き例外→アプリ例外）
# ============================================================


class TestConvertExceptionMapping:
    @pytest.mark.asyncio
    async def test_anthropic_timeout_raises_ai_timeout(self):
        client = AIClient()
        client.anthropic_client = AsyncMock()
        client.anthropic_client.messages.create = AsyncMock(
            side_effect=anthropic.APITimeoutError(request=_REQ)
        )
        with pytest.raises(AITimeoutException):
            await client.convert_text_anthropic("テスト入力", "normal")

    @pytest.mark.asyncio
    async def test_anthropic_empty_content_raises_conversion(self):
        client = AIClient()
        client.anthropic_client = AsyncMock()
        client.anthropic_client.messages.create = AsyncMock(
            return_value=SimpleNamespace(content=[])
        )
        with pytest.raises(AIConversionException):
            await client.convert_text_anthropic("テスト入力", "normal")

    @pytest.mark.asyncio
    async def test_openai_rate_limit_raises_ai_rate_limit(self):
        client = AIClient()
        client.openai_client = AsyncMock()
        client.openai_client.chat.completions.create = AsyncMock(
            side_effect=openai.RateLimitError(
                "rate", response=httpx.Response(429, request=_REQ), body=None
            )
        )
        with pytest.raises(AIRateLimitException):
            await client.convert_text_openai("テスト入力", "normal")


# ============================================================
# aclose によるクリーンアップ
# ============================================================


class TestAClose:
    @pytest.mark.asyncio
    async def test_aclose_closes_http_and_openai_clients(self):
        client = AIClient()
        http_client = AsyncMock()
        client._anthropic_http_client = http_client
        openai_client = AsyncMock()
        client.openai_client = openai_client

        await client.aclose()

        http_client.aclose.assert_awaited_once()
        openai_client.close.assert_awaited_once()
        assert client._anthropic_http_client is None

    @pytest.mark.asyncio
    async def test_aclose_is_safe_when_nothing_initialized(self):
        client = AIClient()
        client._anthropic_http_client = None
        client.openai_client = None
        # 例外を投げずに完了すること
        await client.aclose()
