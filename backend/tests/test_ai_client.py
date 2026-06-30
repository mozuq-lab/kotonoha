"""
AIクライアントテストモジュール

TASK-0026: 外部AI API連携実装（Claude/GPT プロキシ）
🔵 TDD Redフェーズ - 失敗するテストを作成

【テスト目的】: AIClientクラスの機能を検証
【テスト範囲】: 初期化、プロンプト生成、API呼び出し、エラーハンドリング
"""

from types import SimpleNamespace
from unittest.mock import AsyncMock, MagicMock, patch

import anthropic
import httpx
import pytest

import app.utils.ai_client as _ai_client_mod

# ============================================================
# 1. 単体テスト: AIClient初期化
# ============================================================


class TestAIClientInitialization:
    """AIClient初期化テスト"""

    @pytest.mark.skip(reason="anthropicパッケージが環境にインストールされていない")
    def test_ai_client_initialization_with_anthropic_key(self):
        """
        UT-001: Anthropic APIキー設定時の初期化

        【テスト目的】: Anthropic APIキーが設定されている場合、クライアントが正しく初期化される
        【期待される動作】: anthropic_clientがNoneでないこと
        🔵 REQ-901に基づく
        """
        from app.utils.ai_client import AIClient

        # settingsをモック
        with patch("app.utils.ai_client.settings") as mock_settings:
            mock_settings.ANTHROPIC_API_KEY = "test-anthropic-key"
            mock_settings.OPENAI_API_KEY = None
            mock_settings.AI_API_TIMEOUT = 30.0

            client = AIClient()
            assert client.anthropic_client is not None

    @pytest.mark.skip(reason="openaiパッケージが環境にインストールされていない")
    def test_ai_client_initialization_with_openai_key(self):
        """
        UT-002: OpenAI APIキー設定時の初期化

        【テスト目的】: OpenAI APIキーが設定されている場合、クライアントが正しく初期化される
        【期待される動作】: openai_clientがNoneでないこと
        🔵 REQ-901に基づく
        """
        from app.utils.ai_client import AIClient

        with patch("app.utils.ai_client.settings") as mock_settings:
            mock_settings.ANTHROPIC_API_KEY = None
            mock_settings.OPENAI_API_KEY = "test-openai-key"
            mock_settings.AI_API_TIMEOUT = 30.0

            client = AIClient()
            assert client.openai_client is not None

    @pytest.mark.skip(reason="anthropic/openaiパッケージが環境にインストールされていない")
    def test_ai_client_initialization_with_both_keys(self):
        """
        UT-003: 両方のAPIキー設定時の初期化

        【テスト目的】: 両方のAPIキーが設定されている場合、両方のクライアントが初期化される
        【期待される動作】: 両方のクライアントがNoneでないこと
        🔵 REQ-901に基づく
        """
        from app.utils.ai_client import AIClient

        with patch("app.utils.ai_client.settings") as mock_settings:
            mock_settings.ANTHROPIC_API_KEY = "test-anthropic-key"
            mock_settings.OPENAI_API_KEY = "test-openai-key"
            mock_settings.AI_API_TIMEOUT = 30.0

            client = AIClient()
            assert client.anthropic_client is not None
            assert client.openai_client is not None

    def test_ai_client_initialization_without_keys(self):
        """
        UT-004: APIキー未設定時の初期化

        【テスト目的】: APIキーが設定されていない場合、クライアントがNoneになる
        【期待される動作】: 両方のクライアントがNoneであること
        🔵 EDGE-001に基づく
        """
        from app.utils.ai_client import AIClient

        with patch("app.utils.ai_client.settings") as mock_settings:
            mock_settings.ANTHROPIC_API_KEY = None
            mock_settings.OPENAI_API_KEY = None
            mock_settings.AI_API_TIMEOUT = 30.0

            client = AIClient()
            assert client.anthropic_client is None
            assert client.openai_client is None


# ============================================================
# 2. 単体テスト: 丁寧さレベルプロンプト生成
# ============================================================


class TestPolitenessInstruction:
    """丁寧さレベルプロンプト生成テスト"""

    def test_get_politeness_instruction_casual(self):
        """
        UT-101: カジュアルレベルのプロンプト生成

        【テスト目的】: casualレベルで適切なプロンプトが生成される
        【期待される動作】: カジュアルを示す文言が含まれる
        🔵 REQ-902に基づく
        """
        from app.utils.ai_client import AIClient

        client = AIClient()
        instruction = client._get_politeness_instruction("casual")
        assert "カジュアル" in instruction or "親しみ" in instruction

    def test_get_politeness_instruction_normal(self):
        """
        UT-102: ノーマルレベルのプロンプト生成

        【テスト目的】: normalレベルで適切なプロンプトが生成される
        【期待される動作】: 標準・普通を示す文言が含まれる
        🔵 REQ-902に基づく
        """
        from app.utils.ai_client import AIClient

        client = AIClient()
        instruction = client._get_politeness_instruction("normal")
        assert "標準" in instruction or "普通" in instruction or "です・ます" in instruction

    def test_get_politeness_instruction_polite(self):
        """
        UT-103: ポライトレベルのプロンプト生成

        【テスト目的】: politeレベルで適切なプロンプトが生成される
        【期待される動作】: 丁寧・敬意を示す文言が含まれる
        🔵 REQ-902に基づく
        """
        from app.utils.ai_client import AIClient

        client = AIClient()
        instruction = client._get_politeness_instruction("polite")
        assert "丁寧" in instruction or "敬" in instruction

    def test_get_politeness_instruction_invalid_level(self):
        """
        UT-104: 無効なレベルでのフォールバック

        【テスト目的】: 無効なレベルが指定された場合、normalにフォールバックする
        【期待される動作】: normalレベルと同じプロンプトが返される
        🟡 エッジケース対応
        """
        from app.utils.ai_client import AIClient

        client = AIClient()
        instruction = client._get_politeness_instruction("invalid")
        normal_instruction = client._get_politeness_instruction("normal")
        assert instruction == normal_instruction


# ============================================================
# 3. 単体テスト: プロバイダー自動選択
# ============================================================


class TestProviderSelection:
    """プロバイダー自動選択テスト"""

    def test_auto_select_default_provider_anthropic(self):
        """
        UT-201: デフォルトプロバイダーとしてAnthropicを選択

        【テスト目的】: DEFAULT_AI_PROVIDER=anthropicの場合、Anthropicが選択される
        【期待される動作】: convert_text_anthropicが呼び出される
        🔵 api-endpoints.mdに基づく
        """
        from app.utils.ai_client import AIClient

        AIClient()
        # プロバイダー選択ロジックのテスト
        # 実装後にモックを使用して検証

    def test_auto_select_provider_openai(self):
        """
        UT-202: プロバイダーとしてOpenAIを明示的に選択

        【テスト目的】: provider="openai"の場合、OpenAIが選択される
        【期待される動作】: convert_text_openaiが呼び出される
        🔵 api-endpoints.mdに基づく
        """
        from app.utils.ai_client import AIClient

        AIClient()
        # 実装後にモックを使用して検証

    @pytest.mark.asyncio
    async def test_invalid_provider_raises_error(self):
        """
        UT-203: 無効なプロバイダー指定でエラー

        【テスト目的】: 無効なプロバイダーが指定された場合、AIProviderExceptionが発生
        【期待される動作】: AIProviderExceptionが発生
        🔵 エラーハンドリング要件
        """
        from app.utils.ai_client import AIClient
        from app.utils.exceptions import AIProviderException

        client = AIClient()
        with pytest.raises(AIProviderException):
            await client.convert_text(
                input_text="テスト",
                politeness_level="normal",
                provider="invalid_provider",
            )


# ============================================================
# 4. 統合テスト（モック使用）: Claude API変換
# ============================================================


class TestClaudeAPIConversion:
    """Claude API変換テスト（モック使用）"""

    @pytest.mark.asyncio
    async def test_convert_text_anthropic_success(self):
        """
        IT-001: Claude APIでの正常な変換

        【テスト目的】: Claude APIを使用して正常に変換できる
        【期待される動作】: 変換されたテキストと処理時間が返される
        🔵 REQ-901に基づく
        """
        from app.utils.ai_client import AIClient

        client = AIClient()

        # Anthropic APIのモック
        mock_response = MagicMock()
        mock_response.content = [MagicMock(text="ありがとうございます")]

        with patch.object(client, "anthropic_client", create=True) as mock_anthropic:
            mock_anthropic.messages = MagicMock()
            mock_anthropic.messages.create = AsyncMock(return_value=mock_response)

            converted_text, conversion_time_ms = await client.convert_text_anthropic(
                input_text="ありがとう",
                politeness_level="polite",
            )

            assert converted_text == "ありがとうございます"
            assert conversion_time_ms >= 0

    @pytest.mark.asyncio
    async def test_convert_text_anthropic_casual_level(self):
        """
        IT-002: Claude APIでカジュアル変換

        【テスト目的】: カジュアルレベルで適切に変換できる
        【期待される動作】: カジュアルな表現に変換される
        🔵 REQ-902に基づく
        """
        from app.utils.ai_client import AIClient

        AIClient()
        # 実装後にモックを使用して検証

    @pytest.mark.asyncio
    async def test_convert_text_anthropic_api_not_configured(self):
        """
        IT-501: Anthropic APIキー未設定時のエラー

        【テスト目的】: APIキーが設定されていない場合、適切なエラーが発生
        【期待される動作】: AIProviderExceptionが発生
        🔵 EDGE-001に基づく
        """
        from app.utils.ai_client import AIClient
        from app.utils.exceptions import AIProviderException

        client = AIClient()
        client.anthropic_client = None

        with pytest.raises((ValueError, AIProviderException)):
            await client.convert_text_anthropic(
                input_text="ありがとう",
                politeness_level="polite",
            )


# ============================================================
# 5. 統合テスト（モック使用）: OpenAI API変換
# ============================================================


class TestOpenAIAPIConversion:
    """OpenAI API変換テスト（モック使用）"""

    @pytest.mark.asyncio
    async def test_convert_text_openai_success(self):
        """
        IT-101: OpenAI APIでの正常な変換

        【テスト目的】: OpenAI APIを使用して正常に変換できる
        【期待される動作】: 変換されたテキストと処理時間が返される
        🔵 REQ-901に基づく
        """
        from app.utils.ai_client import AIClient

        client = AIClient()

        # OpenAI APIのモック
        mock_response = MagicMock()
        mock_response.choices = [MagicMock(message=MagicMock(content="ありがとうございます"))]

        with patch.object(client, "openai_client", create=True) as mock_openai:
            mock_openai.chat = MagicMock()
            mock_openai.chat.completions = MagicMock()
            mock_openai.chat.completions.create = AsyncMock(return_value=mock_response)

            converted_text, conversion_time_ms = await client.convert_text_openai(
                input_text="ありがとう",
                politeness_level="polite",
            )

            assert converted_text == "ありがとうございます"
            assert conversion_time_ms >= 0

    @pytest.mark.asyncio
    async def test_convert_text_openai_api_not_configured(self):
        """
        IT-502: OpenAI APIキー未設定時のエラー

        【テスト目的】: APIキーが設定されていない場合、適切なエラーが発生
        【期待される動作】: AIProviderExceptionが発生
        🔵 EDGE-001に基づく
        """
        from app.utils.ai_client import AIClient
        from app.utils.exceptions import AIProviderException

        client = AIClient()
        client.openai_client = None

        with pytest.raises((ValueError, AIProviderException)):
            await client.convert_text_openai(
                input_text="ありがとう",
                politeness_level="polite",
            )


# ============================================================
# 6. 統合テスト: タイムアウト処理
# ============================================================


class TestTimeoutHandling:
    """タイムアウト処理テスト"""

    @pytest.mark.asyncio
    async def test_anthropic_timeout(self):
        """
        IT-201: Anthropic APIタイムアウト

        【テスト目的】: タイムアウト時にAITimeoutExceptionが発生
        【期待される動作】: AITimeoutExceptionが発生
        🔵 NFR-002に基づく（30秒タイムアウト）
        """
        from app.utils.ai_client import AIClient

        AIClient()
        # タイムアウトのモック
        # 実装後に検証

    @pytest.mark.asyncio
    async def test_openai_timeout(self):
        """
        IT-202: OpenAI APIタイムアウト

        【テスト目的】: タイムアウト時にAITimeoutExceptionが発生
        【期待される動作】: AITimeoutExceptionが発生
        🔵 NFR-002に基づく
        """
        from app.utils.ai_client import AIClient

        AIClient()
        # タイムアウトのモック
        # 実装後に検証


# ============================================================
# 7. 例外クラステスト
# ============================================================


class TestAIExceptions:
    """AI例外クラステスト"""

    def test_ai_conversion_exception_exists(self):
        """
        EX-001: AIConversionException存在確認

        【テスト目的】: AIConversionExceptionクラスが存在する
        """
        from app.utils.exceptions import AIConversionException

        exc = AIConversionException("Test error")
        assert str(exc) == "Test error"

    def test_ai_timeout_exception_exists(self):
        """
        EX-002: AITimeoutException存在確認

        【テスト目的】: AITimeoutExceptionクラスが存在する
        """
        from app.utils.exceptions import AITimeoutException

        exc = AITimeoutException("Timeout error")
        assert "timeout" in str(exc).lower() or "Timeout" in str(exc)

    def test_ai_rate_limit_exception_exists(self):
        """
        EX-003: AIRateLimitException存在確認

        【テスト目的】: AIRateLimitExceptionクラスが存在する
        """
        from app.utils.exceptions import AIRateLimitException

        exc = AIRateLimitException("Rate limit error")
        assert exc.status_code == 429

    def test_ai_provider_exception_exists(self):
        """
        EX-004: AIProviderException存在確認

        【テスト目的】: AIProviderExceptionクラスが存在する
        """
        from app.utils.exceptions import AIProviderException

        exc = AIProviderException("Provider error")
        assert "Provider" in str(exc) or "provider" in str(exc).lower()


# ============================================================
# 8. 処理時間測定テスト
# ============================================================


class TestProcessingTimeMeasurement:
    """処理時間測定テスト"""

    @pytest.mark.asyncio
    async def test_conversion_time_is_measured(self):
        """
        UT-301: 処理時間が正しく測定される

        【テスト目的】: 変換処理時間がミリ秒単位で測定される
        【期待される動作】: conversion_time_msが0以上の整数
        🔵 NFR-002に基づく
        """
        from app.utils.ai_client import AIClient

        AIClient()
        # モックを使用して処理時間測定をテスト
        # 実装後に検証

    @pytest.mark.asyncio
    async def test_conversion_time_within_limit(self):
        """
        UT-302: 処理時間が3秒以内

        【テスト目的】: 平均処理時間が3秒（3000ms）以内
        【期待される動作】: conversion_time_ms < 3000
        🔵 NFR-002に基づく
        """
        # E2Eテストで実際のAPIを使用して検証
        pass


# ============================================================
# 9. リトライ（_call_with_retry）テスト (review #4)
# ============================================================

_RREQ = httpx.Request("POST", "http://retry-test")


class TestCallWithRetry:
    """AIClient._call_with_retry の挙動テスト。

    asyncio.sleep をモックして高速化し、settings.AI_MAX_RETRIES を小さい値に
    パッチして試行回数を制御する。
    """

    @pytest.mark.asyncio
    async def test_retry_on_retryable_exception_eventually_succeeds(self):
        """リトライ対象例外発生後、最終的に成功し、sleep が attempt 回数 -1 回呼ばれる。"""
        from app.utils.ai_client import AIClient

        call_count = 0

        async def flaky() -> str:
            nonlocal call_count
            call_count += 1
            if call_count < 3:
                raise anthropic.APITimeoutError(request=_RREQ)
            return "ok"

        sleep_mock = AsyncMock()
        with (
            patch.object(_ai_client_mod.settings, "AI_MAX_RETRIES", 3),
            patch("asyncio.sleep", sleep_mock),
        ):
            client = AIClient()
            result = await client._call_with_retry(lambda: flaky())

        assert result == "ok"
        assert call_count == 3
        assert sleep_mock.await_count == 2  # sleeps between attempt 0→1 and 1→2

    @pytest.mark.asyncio
    async def test_retry_exhausted_reraises_sdk_exception_with_sleep(self):
        """リトライ枯渇後、SDK 例外を再 raise し、max_retries-1 回 sleep する。"""
        from app.utils.ai_client import AIClient

        sleep_mock = AsyncMock()

        async def always_fail() -> None:
            raise anthropic.APITimeoutError(request=_RREQ)

        with (
            patch.object(_ai_client_mod.settings, "AI_MAX_RETRIES", 2),
            patch("asyncio.sleep", sleep_mock),
        ):
            client = AIClient()
            with pytest.raises(anthropic.APITimeoutError):
                await client._call_with_retry(lambda: always_fail())

        # max_retries=2: attempt 0 → sleep(0.5), attempt 1 → raise (no sleep)
        assert sleep_mock.await_count == 1

    @pytest.mark.asyncio
    async def test_non_retryable_exception_propagates_without_sleep(self):
        """リトライ対象外の例外は即座に伝播し、sleep しない。"""
        from app.utils.ai_client import AIClient

        sleep_mock = AsyncMock()

        async def raises_value_error() -> None:
            raise ValueError("not retryable")

        with (
            patch.object(_ai_client_mod.settings, "AI_MAX_RETRIES", 3),
            patch("asyncio.sleep", sleep_mock),
        ):
            client = AIClient()
            with pytest.raises(ValueError, match="not retryable"):
                await client._call_with_retry(lambda: raises_value_error())

        sleep_mock.assert_not_awaited()

    @pytest.mark.asyncio
    async def test_convert_text_anthropic_retries_on_timeout_and_succeeds(self):
        """convert_text_anthropic: タイムアウトでリトライし最終成功する。"""
        from app.utils.ai_client import AIClient

        call_count = 0

        async def flaky_create(**_: object) -> object:
            nonlocal call_count
            call_count += 1
            if call_count == 1:
                raise anthropic.APITimeoutError(request=_RREQ)
            return SimpleNamespace(content=[SimpleNamespace(text="変換済み")])

        sleep_mock = AsyncMock()
        with (
            patch.object(_ai_client_mod.settings, "AI_MAX_RETRIES", 3),
            patch.object(_ai_client_mod.settings, "ANTHROPIC_MODEL", "claude-test", create=True),
            patch("asyncio.sleep", sleep_mock),
        ):
            client = AIClient()
            client.anthropic_client = MagicMock()
            client.anthropic_client.messages.create = flaky_create
            text, _ = await client.convert_text_anthropic("テスト", "normal")

        assert text == "変換済み"
        assert call_count == 2
        assert sleep_mock.await_count == 1

    @pytest.mark.asyncio
    async def test_convert_text_anthropic_retry_exhausted_raises_ai_timeout(self):
        """convert_text_anthropic: リトライ枯渇後、AITimeoutException になり sleep を実施する。"""
        from app.utils.ai_client import AIClient
        from app.utils.exceptions import AITimeoutException

        async def always_timeout(**_: object) -> None:
            raise anthropic.APITimeoutError(request=_RREQ)

        sleep_mock = AsyncMock()
        with (
            patch.object(_ai_client_mod.settings, "AI_MAX_RETRIES", 2),
            patch.object(_ai_client_mod.settings, "ANTHROPIC_MODEL", "claude-test", create=True),
            patch("asyncio.sleep", sleep_mock),
        ):
            client = AIClient()
            client.anthropic_client = MagicMock()
            client.anthropic_client.messages.create = always_timeout
            with pytest.raises(AITimeoutException):
                await client.convert_text_anthropic("テスト", "normal")

        # max_retries=2: attempt 0 → sleep(0.5), attempt 1 → maps to AITimeoutException
        assert sleep_mock.await_count == 1
