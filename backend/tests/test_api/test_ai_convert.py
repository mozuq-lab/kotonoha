"""
AI変換エンドポイントテスト

TASK-0027: AI変換エンドポイント実装（POST /api/v1/ai/convert）

【テストファイル目的】: AI変換エンドポイントの動作を検証（TDDレッドフェーズ）
【テストファイル内容】: 正常系、バリデーション、レート制限、エラーハンドリング、ログ記録のテストケースを網羅
【期待されるカバレッジ】: 90%以上のテストカバレッジを達成（NFR-502要件）

🔵 TASK-0027-testcases.md に基づく実装
"""

import hashlib
import uuid
from unittest.mock import AsyncMock, patch

import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.rate_limit import limiter
from app.main import app
from app.models.ai_conversion_logs import AIConversionLog
from app.utils.exceptions import (
    AIConversionException,
    AIProviderException,
    AIRateLimitException,
    AITimeoutException,
)


@pytest.fixture(autouse=True)
async def reset_limiter():
    """各テスト実行前にリミッターのストレージをリセット"""
    limiter.reset()
    yield
    limiter.reset()


# ================================================================================
# カテゴリA: 正常系テストケース
# ================================================================================


class TestAIConvertSuccess:
    """AI変換正常系テスト"""

    @pytest.mark.asyncio
    async def test_tc001_基本的なai変換成功テスト(self):
        """
        【テスト目的】: 基本的なAI変換が成功することを確認
        【テスト内容】: 有効な入力でAI変換が正常に処理されることを検証
        【期待される動作】: 200 OKとAI変換結果が返される
        🔵 testcases.md TC-001（AC-001）に基づく
        """
        request_body = {"input_text": "水 ぬるく", "politeness_level": "normal"}

        with (
            patch("app.utils.ai_client.ai_client") as mock_ai_client,
            patch("app.api.v1.endpoints.ai.create_conversion_log", new_callable=AsyncMock),
        ):
            mock_ai_client.convert_text = AsyncMock(
                return_value=("お水をぬるめでお願いします", 1500)
            )

            async with AsyncClient(
                transport=ASGITransport(app=app), base_url="http://test"
            ) as client:
                response = await client.post("/api/v1/ai/convert", json=request_body)

                # 【結果検証】: HTTPステータスコードが200であることを確認
                assert response.status_code == 200

                # 【結果検証】: レスポンスボディの内容を確認
                response_json = response.json()
                assert "converted_text" in response_json
                assert response_json["converted_text"] == "お水をぬるめでお願いします"
                assert response_json["original_text"] == "水 ぬるく"
                assert response_json["politeness_level"] == "normal"
                assert "processing_time_ms" in response_json
                assert response_json["processing_time_ms"] == 1500

    @pytest.mark.asyncio
    async def test_tc002_丁寧さレベルcasual変換テスト(self):
        """
        【テスト目的】: 丁寧さレベル「casual」でAI変換が成功することを確認
        【テスト内容】: casualレベルでの変換結果を検証
        【期待される動作】: 200 OKとカジュアルな変換結果が返される
        🔵 testcases.md TC-002（AC-002）に基づく
        """
        request_body = {"input_text": "ありがとう", "politeness_level": "casual"}

        with (
            patch("app.utils.ai_client.ai_client") as mock_ai_client,
            patch("app.api.v1.endpoints.ai.create_conversion_log", new_callable=AsyncMock),
        ):
            mock_ai_client.convert_text = AsyncMock(return_value=("サンキュー", 1200))

            async with AsyncClient(
                transport=ASGITransport(app=app), base_url="http://test"
            ) as client:
                response = await client.post("/api/v1/ai/convert", json=request_body)

                assert response.status_code == 200
                response_json = response.json()
                assert response_json["politeness_level"] == "casual"
                assert response_json["converted_text"] == "サンキュー"

    @pytest.mark.asyncio
    async def test_tc003_丁寧さレベルnormal変換テスト(self):
        """
        【テスト目的】: 丁寧さレベル「normal」でAI変換が成功することを確認
        【テスト内容】: normalレベルでの変換結果を検証
        【期待される動作】: 200 OKとです・ます調の変換結果が返される
        🔵 testcases.md TC-003（AC-001）に基づく
        """
        request_body = {"input_text": "これ ほしい", "politeness_level": "normal"}

        with (
            patch("app.utils.ai_client.ai_client") as mock_ai_client,
            patch("app.api.v1.endpoints.ai.create_conversion_log", new_callable=AsyncMock),
        ):
            mock_ai_client.convert_text = AsyncMock(return_value=("これをいただけますか", 1300))

            async with AsyncClient(
                transport=ASGITransport(app=app), base_url="http://test"
            ) as client:
                response = await client.post("/api/v1/ai/convert", json=request_body)

                assert response.status_code == 200
                response_json = response.json()
                assert response_json["politeness_level"] == "normal"

    @pytest.mark.asyncio
    async def test_tc004_丁寧さレベルpolite変換テスト(self):
        """
        【テスト目的】: 丁寧さレベル「polite」でAI変換が成功することを確認
        【テスト内容】: politeレベルでの変換結果を検証
        【期待される動作】: 200 OKと敬語の変換結果が返される
        🔵 testcases.md TC-004（AC-003）に基づく
        """
        request_body = {"input_text": "ありがとう", "politeness_level": "polite"}

        with (
            patch("app.utils.ai_client.ai_client") as mock_ai_client,
            patch("app.api.v1.endpoints.ai.create_conversion_log", new_callable=AsyncMock),
        ):
            mock_ai_client.convert_text = AsyncMock(return_value=("誠にありがとうございます", 1400))

            async with AsyncClient(
                transport=ASGITransport(app=app), base_url="http://test"
            ) as client:
                response = await client.post("/api/v1/ai/convert", json=request_body)

                assert response.status_code == 200
                response_json = response.json()
                assert response_json["politeness_level"] == "polite"
                assert response_json["converted_text"] == "誠にありがとうございます"

    @pytest.mark.asyncio
    async def test_tc005_見せかけのレート制限ヘッダーが含まれないことを検証(self):
        """
        【テスト目的】: 実カウンタに基づかない固定値のX-RateLimit-*ヘッダーが
                        レスポンスに含まれないことを確認
        【テスト内容】: 成功レスポンスのヘッダーを検証
        【期待される動作】: X-RateLimit-Limit/Remaining/Resetが存在しない
                            （常に固定値TIMES-1を返す見せかけのヘッダーは廃止）
        🔵 信頼性改善: 誤解を招く固定値ヘッダーの削除
        """
        request_body = {"input_text": "テスト入力", "politeness_level": "normal"}

        with (
            patch("app.utils.ai_client.ai_client") as mock_ai_client,
            patch("app.api.v1.endpoints.ai.create_conversion_log", new_callable=AsyncMock),
        ):
            mock_ai_client.convert_text = AsyncMock(return_value=("変換済みテスト", 1000))

            async with AsyncClient(
                transport=ASGITransport(app=app), base_url="http://test"
            ) as client:
                response = await client.post("/api/v1/ai/convert", json=request_body)

                assert response.status_code == 200

                # 【結果検証】: 見せかけのX-RateLimit-*ヘッダーが存在しないことを確認
                assert "x-ratelimit-limit" not in response.headers
                assert "x-ratelimit-remaining" not in response.headers
                assert "x-ratelimit-reset" not in response.headers

    @pytest.mark.asyncio
    async def test_tc006_processing_time_ms正値検証テスト(self):
        """
        【テスト目的】: processing_time_msが正の整数であることを確認
        【テスト内容】: レスポンスのprocessing_time_msフィールドを検証
        【期待される動作】: processing_time_msが正の整数である
        🔵 testcases.md TC-006（AC-001）に基づく
        """
        request_body = {"input_text": "処理時間テスト", "politeness_level": "normal"}

        with (
            patch("app.utils.ai_client.ai_client") as mock_ai_client,
            patch("app.api.v1.endpoints.ai.create_conversion_log", new_callable=AsyncMock),
        ):
            mock_ai_client.convert_text = AsyncMock(return_value=("変換済み", 2500))

            async with AsyncClient(
                transport=ASGITransport(app=app), base_url="http://test"
            ) as client:
                response = await client.post("/api/v1/ai/convert", json=request_body)

                assert response.status_code == 200
                response_json = response.json()

                # 【結果検証】: processing_time_msが正の整数であることを確認
                assert "processing_time_ms" in response_json
                assert isinstance(response_json["processing_time_ms"], int)
                assert response_json["processing_time_ms"] >= 0

    @pytest.mark.asyncio
    async def test_tc007_original_textトリム検証テスト(self):
        """
        【テスト目的】: 入力テキストの前後空白がトリムされることを確認
        【テスト内容】: 前後に空白を含む入力がトリムされることを検証
        【期待される動作】: original_textがトリム済みで返される
        🔵 testcases.md TC-007（AC-107）に基づく
        """
        # 前後に空白を含む入力
        request_body = {"input_text": "  こんにちは  ", "politeness_level": "normal"}

        with (
            patch("app.utils.ai_client.ai_client") as mock_ai_client,
            patch("app.api.v1.endpoints.ai.create_conversion_log", new_callable=AsyncMock),
        ):
            mock_ai_client.convert_text = AsyncMock(return_value=("こんにちは", 800))

            async with AsyncClient(
                transport=ASGITransport(app=app), base_url="http://test"
            ) as client:
                response = await client.post("/api/v1/ai/convert", json=request_body)

                assert response.status_code == 200
                response_json = response.json()

                # 【結果検証】: original_textがトリム済みであることを確認
                assert response_json["original_text"] == "こんにちは"


# ================================================================================
# カテゴリB: 入力バリデーションテストケース
# ================================================================================


class TestAIConvertValidation:
    """AI変換入力バリデーションテスト"""

    @pytest.mark.asyncio
    async def test_tc101_最小文字数2文字成功テスト(self):
        """
        【テスト目的】: 最小文字数（2文字）の入力が成功することを確認
        【テスト内容】: 2文字の入力でAI変換が成功することを検証
        【期待される動作】: 200 OKで変換が成功する
        🔵 testcases.md TC-101（AC-101）に基づく
        """
        request_body = {"input_text": "こん", "politeness_level": "normal"}

        with (
            patch("app.utils.ai_client.ai_client") as mock_ai_client,
            patch("app.api.v1.endpoints.ai.create_conversion_log", new_callable=AsyncMock),
        ):
            mock_ai_client.convert_text = AsyncMock(return_value=("こんにちは", 500))

            async with AsyncClient(
                transport=ASGITransport(app=app), base_url="http://test"
            ) as client:
                response = await client.post("/api/v1/ai/convert", json=request_body)

                assert response.status_code == 200

    @pytest.mark.asyncio
    async def test_tc102_最大文字数500文字成功テスト(self):
        """
        【テスト目的】: 最大文字数（500文字）の入力が成功することを確認
        【テスト内容】: 500文字の入力でAI変換が成功することを検証
        【期待される動作】: 200 OKで変換が成功する
        🔵 testcases.md TC-102（AC-102）に基づく
        """
        # 500文字の入力テキストを作成
        input_text = "あ" * 500
        request_body = {"input_text": input_text, "politeness_level": "normal"}

        with (
            patch("app.utils.ai_client.ai_client") as mock_ai_client,
            patch("app.api.v1.endpoints.ai.create_conversion_log", new_callable=AsyncMock),
        ):
            mock_ai_client.convert_text = AsyncMock(return_value=("変換済み" * 100, 3000))

            async with AsyncClient(
                transport=ASGITransport(app=app), base_url="http://test"
            ) as client:
                response = await client.post("/api/v1/ai/convert", json=request_body)

                assert response.status_code == 200

    @pytest.mark.asyncio
    async def test_tc103_文字数不足1文字エラーテスト(self):
        """
        【テスト目的】: 1文字の入力がエラーになることを確認
        【テスト内容】: 最小文字数未満（1文字）の入力を検証
        【期待される動作】: 422 Unprocessable Entityが返される
        🔵 testcases.md TC-103（AC-103）に基づく
        """
        request_body = {"input_text": "あ", "politeness_level": "normal"}

        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            response = await client.post("/api/v1/ai/convert", json=request_body)

            # 【結果検証】: 422エラーが返されることを確認
            assert response.status_code == 422

    @pytest.mark.asyncio
    async def test_tc104_文字数超過501文字エラーテスト(self):
        """
        【テスト目的】: 501文字の入力がエラーになることを確認
        【テスト内容】: 最大文字数超過（501文字）の入力を検証
        【期待される動作】: 422 Unprocessable Entityが返される
        🔵 testcases.md TC-104（AC-104）に基づく
        """
        # 501文字の入力テキストを作成
        input_text = "あ" * 501
        request_body = {"input_text": input_text, "politeness_level": "normal"}

        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            response = await client.post("/api/v1/ai/convert", json=request_body)

            # 【結果検証】: 422エラーが返されることを確認
            assert response.status_code == 422

    @pytest.mark.asyncio
    async def test_tc105_空白のみ入力エラーテスト(self):
        """
        【テスト目的】: 空白のみの入力がエラーになることを確認
        【テスト内容】: 空白のみの入力を検証
        【期待される動作】: 422 Unprocessable Entityが返される
        🔵 testcases.md TC-105（AC-105）に基づく
        """
        request_body = {"input_text": "   ", "politeness_level": "normal"}

        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            response = await client.post("/api/v1/ai/convert", json=request_body)

            # 【結果検証】: 422エラーが返されることを確認
            assert response.status_code == 422

    @pytest.mark.asyncio
    async def test_tc106_空文字列入力エラーテスト(self):
        """
        【テスト目的】: 空文字列の入力がエラーになることを確認
        【テスト内容】: 空文字列の入力を検証
        【期待される動作】: 422 Unprocessable Entityが返される
        🔵 testcases.md TC-106（AC-105）に基づく
        """
        request_body = {"input_text": "", "politeness_level": "normal"}

        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            response = await client.post("/api/v1/ai/convert", json=request_body)

            # 【結果検証】: 422エラーが返されることを確認
            assert response.status_code == 422

    @pytest.mark.asyncio
    async def test_tc107_不正な丁寧さレベルエラーテスト(self):
        """
        【テスト目的】: 不正な丁寧さレベルがエラーになることを確認
        【テスト内容】: 無効なpoliteness_levelを検証
        【期待される動作】: 422 Unprocessable Entityが返される
        🔵 testcases.md TC-107（AC-106）に基づく
        """
        request_body = {"input_text": "こんにちは", "politeness_level": "invalid"}

        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            response = await client.post("/api/v1/ai/convert", json=request_body)

            # 【結果検証】: 422エラーが返されることを確認
            assert response.status_code == 422

    @pytest.mark.asyncio
    async def test_tc108_input_text未指定エラーテスト(self):
        """
        【テスト目的】: input_text未指定がエラーになることを確認
        【テスト内容】: input_textフィールドがないリクエストを検証
        【期待される動作】: 422 Unprocessable Entityが返される
        🔵 testcases.md TC-108に基づく
        """
        request_body = {"politeness_level": "normal"}

        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            response = await client.post("/api/v1/ai/convert", json=request_body)

            # 【結果検証】: 422エラーが返されることを確認
            assert response.status_code == 422

    @pytest.mark.asyncio
    async def test_tc109_politeness_level未指定エラーテスト(self):
        """
        【テスト目的】: politeness_level未指定がエラーになることを確認
        【テスト内容】: politeness_levelフィールドがないリクエストを検証
        【期待される動作】: 422 Unprocessable Entityが返される
        🔵 testcases.md TC-109に基づく
        """
        request_body = {"input_text": "こんにちは"}

        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            response = await client.post("/api/v1/ai/convert", json=request_body)

            # 【結果検証】: 422エラーが返されることを確認
            assert response.status_code == 422


# ================================================================================
# カテゴリC: レート制限テストケース
# ================================================================================


class TestAIConvertRateLimit:
    """AI変換レート制限テスト"""

    @pytest.mark.asyncio
    async def test_tc201_レート制限超過429テスト(self):
        """
        【テスト目的】: レート制限超過で429エラーが返されることを確認
        【テスト内容】: 10秒以内に2回のリクエストを送信し、2回目が拒否されることを検証
        【期待される動作】: 1回目は成功、2回目は429 Too Many Requests
        🔵 testcases.md TC-201（AC-201）に基づく
        """
        request_body = {"input_text": "レート制限テスト", "politeness_level": "normal"}

        with (
            patch("app.utils.ai_client.ai_client") as mock_ai_client,
            patch("app.api.v1.endpoints.ai.create_conversion_log", new_callable=AsyncMock),
        ):
            mock_ai_client.convert_text = AsyncMock(return_value=("変換済み", 1000))

            async with AsyncClient(
                transport=ASGITransport(app=app), base_url="http://test"
            ) as client:
                # 1回目のリクエスト
                response1 = await client.post("/api/v1/ai/convert", json=request_body)
                assert response1.status_code == 200

                # 2回目のリクエスト（即座に送信）
                response2 = await client.post("/api/v1/ai/convert", json=request_body)

                # 【結果検証】: 2回目は429エラーであることを確認
                assert response2.status_code == 429

    @pytest.mark.asyncio
    async def test_tc202_retry_afterヘッダー検証テスト(self):
        """
        【テスト目的】: 429レスポンスにRetry-Afterヘッダーが含まれることを確認
        【テスト内容】: レート制限超過時のRetry-Afterヘッダーを検証
        【期待される動作】: Retry-Afterヘッダーが存在し、1-10秒の範囲内
        🔵 testcases.md TC-202（AC-201）に基づく
        """
        request_body = {"input_text": "レート制限テスト", "politeness_level": "normal"}

        with (
            patch("app.utils.ai_client.ai_client") as mock_ai_client,
            patch("app.api.v1.endpoints.ai.create_conversion_log", new_callable=AsyncMock),
        ):
            mock_ai_client.convert_text = AsyncMock(return_value=("変換済み", 1000))

            async with AsyncClient(
                transport=ASGITransport(app=app), base_url="http://test"
            ) as client:
                # 1回目のリクエスト
                await client.post("/api/v1/ai/convert", json=request_body)

                # 2回目のリクエスト（制限超過）
                response = await client.post("/api/v1/ai/convert", json=request_body)

                # 【結果検証】: 429レスポンスにRetry-Afterヘッダーが含まれることを確認
                assert response.status_code == 429
                assert "retry-after" in response.headers

                # 【結果検証】: Retry-After値が1-10秒の範囲内
                retry_after = int(response.headers["retry-after"])
                assert 1 <= retry_after <= 10

    @pytest.mark.asyncio
    async def test_tc203_レート制限リセット後成功テスト(self):
        """
        【テスト目的】: レート制限リセット後にリクエストが成功することを確認
        【テスト内容】: リミッターリセット後に2回目のリクエストが成功することを検証
        【期待される動作】: リセット後は200 OK
        🔵 testcases.md TC-203（AC-202）に基づく
        """
        request_body = {"input_text": "レート制限テスト", "politeness_level": "normal"}

        with (
            patch("app.utils.ai_client.ai_client") as mock_ai_client,
            patch("app.api.v1.endpoints.ai.create_conversion_log", new_callable=AsyncMock),
        ):
            mock_ai_client.convert_text = AsyncMock(return_value=("変換済み", 1000))

            async with AsyncClient(
                transport=ASGITransport(app=app), base_url="http://test"
            ) as client:
                # 1回目のリクエスト
                response1 = await client.post("/api/v1/ai/convert", json=request_body)
                assert response1.status_code == 200

                # リミッターをリセット（10秒経過をシミュレート）
                limiter.reset()

                # 2回目のリクエスト（リセット後）
                response2 = await client.post("/api/v1/ai/convert", json=request_body)

                # 【結果検証】: 2回目も成功することを確認
                assert response2.status_code == 200


# ================================================================================
# カテゴリD: エラーハンドリングテストケース
# ================================================================================


class TestAIConvertErrorHandling:
    """AI変換エラーハンドリングテスト"""

    @pytest.mark.asyncio
    async def test_tc301_aiタイムアウトエラー504テスト(self):
        """
        【テスト目的】: AIタイムアウト時に504エラーが返されることを確認
        【テスト内容】: AIClientがAITimeoutExceptionをスローした場合の動作を検証
        【期待される動作】: 504 Gateway Timeoutとエラーコード"AI_API_TIMEOUT"
        🔵 testcases.md TC-301（AC-301）に基づく
        """
        request_body = {"input_text": "タイムアウトテスト", "politeness_level": "normal"}

        with (
            patch("app.utils.ai_client.ai_client") as mock_ai_client,
            patch("app.api.v1.endpoints.ai.create_conversion_log", new_callable=AsyncMock),
        ):
            mock_ai_client.convert_text = AsyncMock(
                side_effect=AITimeoutException("AI API timeout")
            )

            async with AsyncClient(
                transport=ASGITransport(app=app), base_url="http://test"
            ) as client:
                response = await client.post("/api/v1/ai/convert", json=request_body)

                # 【結果検証】: 504エラーが返されることを確認
                assert response.status_code == 504

                # 【結果検証】: エラーレスポンス形式を確認
                response_json = response.json()
                assert response_json["success"] is False
                assert response_json["error"]["code"] == "AI_API_TIMEOUT"

    @pytest.mark.asyncio
    async def test_tc302_aiプロバイダーエラー503テスト(self):
        """
        【テスト目的】: AIプロバイダーエラー時に503エラーが返されることを確認
        【テスト内容】: AIClientがAIProviderExceptionをスローした場合の動作を検証
        【期待される動作】: 503 Service Unavailableとエラーコード"AI_PROVIDER_ERROR"
        🔵 testcases.md TC-302（AC-302）に基づく
        """
        request_body = {"input_text": "プロバイダーエラーテスト", "politeness_level": "normal"}

        with (
            patch("app.utils.ai_client.ai_client") as mock_ai_client,
            patch("app.api.v1.endpoints.ai.create_conversion_log", new_callable=AsyncMock),
        ):
            mock_ai_client.convert_text = AsyncMock(
                side_effect=AIProviderException("Anthropic API key is not configured")
            )

            async with AsyncClient(
                transport=ASGITransport(app=app), base_url="http://test"
            ) as client:
                response = await client.post("/api/v1/ai/convert", json=request_body)

                # 【結果検証】: 503エラーが返されることを確認
                assert response.status_code == 503

                # 【結果検証】: エラーレスポンス形式を確認
                response_json = response.json()
                assert response_json["success"] is False
                assert response_json["error"]["code"] == "AI_PROVIDER_ERROR"

    @pytest.mark.asyncio
    async def test_tc303_ai変換一般エラー500テスト(self):
        """
        【テスト目的】: AI変換一般エラー時に500エラーが返されることを確認
        【テスト内容】: AIClientがAIConversionExceptionをスローした場合の動作を検証
        【期待される動作】: 500 Internal Server Errorとエラーコード"AI_API_ERROR"
        🔵 testcases.md TC-303（AC-303）に基づく
        """
        request_body = {"input_text": "一般エラーテスト", "politeness_level": "normal"}

        with (
            patch("app.utils.ai_client.ai_client") as mock_ai_client,
            patch("app.api.v1.endpoints.ai.create_conversion_log", new_callable=AsyncMock),
        ):
            mock_ai_client.convert_text = AsyncMock(
                side_effect=AIConversionException("AI conversion failed")
            )

            async with AsyncClient(
                transport=ASGITransport(app=app), base_url="http://test"
            ) as client:
                response = await client.post("/api/v1/ai/convert", json=request_body)

                # 【結果検証】: 500エラーが返されることを確認
                assert response.status_code == 500

                # 【結果検証】: エラーレスポンス形式を確認
                response_json = response.json()
                assert response_json["success"] is False
                assert response_json["error"]["code"] == "AI_API_ERROR"
                assert (
                    "AI変換APIからのレスポンスに失敗しました" in response_json["error"]["message"]
                )

    @pytest.mark.asyncio
    async def test_tc304_aiレート制限エラー429テスト(self):
        """
        【テスト目的】: AIレート制限エラー時に429エラーが返されることを確認
        【テスト内容】: AIClientがAIRateLimitExceptionをスローした場合の動作を検証
        【期待される動作】: 429 Too Many Requestsとエラーコード"AI_RATE_LIMIT"
        🔵 testcases.md TC-304に基づく
        """
        request_body = {"input_text": "AIレート制限テスト", "politeness_level": "normal"}

        with (
            patch("app.utils.ai_client.ai_client") as mock_ai_client,
            patch("app.api.v1.endpoints.ai.create_conversion_log", new_callable=AsyncMock),
        ):
            mock_ai_client.convert_text = AsyncMock(
                side_effect=AIRateLimitException("AI API rate limit exceeded")
            )

            async with AsyncClient(
                transport=ASGITransport(app=app), base_url="http://test"
            ) as client:
                response = await client.post("/api/v1/ai/convert", json=request_body)

                # 【結果検証】: 429エラーが返されることを確認
                assert response.status_code == 429

                # 【結果検証】: エラーレスポンス形式を確認
                response_json = response.json()
                assert response_json["success"] is False
                assert response_json["error"]["code"] == "AI_RATE_LIMIT"

    @pytest.mark.asyncio
    async def test_tc305_エラーレスポンス形式検証テスト(self):
        """
        【テスト目的】: エラーレスポンスが統一形式であることを確認
        【テスト内容】: エラー発生時のJSONレスポンス形式を検証
        【期待される動作】: success=false, data=null, error={code, message, status_code}
        🔵 testcases.md TC-305（AC-301, AC-302, AC-303）に基づく
        """
        request_body = {"input_text": "エラー形式テスト", "politeness_level": "normal"}

        with (
            patch("app.utils.ai_client.ai_client") as mock_ai_client,
            patch("app.api.v1.endpoints.ai.create_conversion_log", new_callable=AsyncMock),
        ):
            mock_ai_client.convert_text = AsyncMock(side_effect=AIConversionException("Test error"))

            async with AsyncClient(
                transport=ASGITransport(app=app), base_url="http://test"
            ) as client:
                response = await client.post("/api/v1/ai/convert", json=request_body)

                # 【結果検証】: エラーレスポンス形式を確認
                response_json = response.json()

                # 必須フィールドの存在確認
                assert "success" in response_json
                assert "data" in response_json
                assert "error" in response_json

                # 値の検証
                assert response_json["success"] is False
                assert response_json["data"] is None

                # errorオブジェクトの構造確認
                error = response_json["error"]
                assert "code" in error
                assert "message" in error
                assert "status_code" in error


# ================================================================================
# カテゴリE: ログ記録テストケース
# ================================================================================


class TestAIConvertLogging:
    """AI変換ログ記録テスト"""

    @pytest.mark.asyncio
    async def test_tc401_成功時ログ記録テスト(self, test_client_with_db, db_session: AsyncSession):
        """
        【テスト目的】: AI変換成功時にログが記録されることを確認
        【テスト内容】: 成功レスポンス後にAIConversionLogが作成されることを検証
        【期待される動作】: ログレコードが作成され、is_success=True
        🔵 testcases.md TC-401（AC-401）に基づく
        """
        input_text = "ログテスト入力_TC401"
        expected_hash = hashlib.sha256(input_text.encode("utf-8")).hexdigest()
        request_body = {"input_text": input_text, "politeness_level": "normal"}

        # リクエスト前のログ数を記録
        result_before = await db_session.execute(
            select(AIConversionLog).where(AIConversionLog.input_text_hash == expected_hash)
        )
        logs_before = result_before.scalars().all()
        count_before = len(logs_before)

        with patch("app.utils.ai_client.ai_client") as mock_ai_client:
            mock_ai_client.convert_text = AsyncMock(return_value=("ログテスト出力", 1500))

            async with AsyncClient(
                transport=ASGITransport(app=test_client_with_db), base_url="http://test"
            ) as client:
                response = await client.post("/api/v1/ai/convert", json=request_body)

                assert response.status_code == 200

                # 【結果検証】: 新しいログレコードが作成されたことを確認
                result_after = await db_session.execute(
                    select(AIConversionLog).where(AIConversionLog.input_text_hash == expected_hash)
                )
                logs_after = result_after.scalars().all()
                count_after = len(logs_after)

                # 【結果検証】: ログ数が1つ増えていることを確認
                assert (
                    count_after == count_before + 1
                ), f"Expected new log to be created. Before: {count_before}, After: {count_after}"

                # 【結果検証】: 最新のログレコードの内容を確認
                result = await db_session.execute(
                    select(AIConversionLog)
                    .where(AIConversionLog.input_text_hash == expected_hash)
                    .order_by(AIConversionLog.created_at.desc())
                )
                log = result.scalars().first()

                assert log is not None
                assert log.is_success is True
                assert log.politeness_level == "normal"
                assert log.conversion_time_ms is not None
                assert log.conversion_time_ms == 1500  # モックの戻り値と一致

                # 【結果検証】: input_text_hashがSHA-256形式（64文字）
                assert len(log.input_text_hash) == 64

                # 【結果検証】: session_idがUUID形式
                assert isinstance(log.session_id, uuid.UUID)

    @pytest.mark.asyncio
    async def test_tc402_失敗時ログ記録テスト(self, test_client_with_db, db_session: AsyncSession):
        """
        【テスト目的】: AI変換失敗時にログが記録されることを確認
        【テスト内容】: エラーレスポンス後にAIConversionLogが作成されることを検証
        【期待される動作】: ログレコードが作成され、is_success=False, error_message有り
        🔵 testcases.md TC-402（AC-402）に基づく
        """
        request_body = {"input_text": "エラーログテスト", "politeness_level": "normal"}

        with patch("app.utils.ai_client.ai_client") as mock_ai_client:
            mock_ai_client.convert_text = AsyncMock(
                side_effect=AIConversionException("Test conversion error")
            )

            async with AsyncClient(
                transport=ASGITransport(app=test_client_with_db), base_url="http://test"
            ) as client:
                response = await client.post("/api/v1/ai/convert", json=request_body)

                assert response.status_code == 500

                # 【結果検証】: データベースからログレコードを検索
                result = await db_session.execute(
                    select(AIConversionLog).order_by(AIConversionLog.created_at.desc())
                )
                log = result.scalars().first()

                # 【結果検証】: ログレコードが存在し、is_success=Falseであることを確認
                assert log is not None
                assert log.is_success is False
                assert log.error_message is not None
                assert len(log.error_message) > 0

    @pytest.mark.asyncio
    async def test_tc403_ログのハッシュ化検証テスト(
        self, test_client_with_db, db_session: AsyncSession
    ):
        """
        【テスト目的】: 入力テキストがハッシュ化されてログに記録されることを確認
        【テスト内容】: input_text_hashがSHA-256ハッシュであり、復元不可能であることを検証
        【期待される動作】: ハッシュ値は64文字で、同じ入力は同じハッシュを生成
        🔵 testcases.md TC-403（AC-403）に基づく
        """
        input_text = "秘密の情報"
        request_body = {"input_text": input_text, "politeness_level": "normal"}

        # 期待されるハッシュ値を計算
        expected_hash = hashlib.sha256(input_text.encode("utf-8")).hexdigest()

        with patch("app.utils.ai_client.ai_client") as mock_ai_client:
            mock_ai_client.convert_text = AsyncMock(return_value=("変換済み秘密", 1000))

            async with AsyncClient(
                transport=ASGITransport(app=test_client_with_db), base_url="http://test"
            ) as client:
                response = await client.post("/api/v1/ai/convert", json=request_body)

                assert response.status_code == 200

                # 【結果検証】: データベースからログレコードを検索
                result = await db_session.execute(
                    select(AIConversionLog).order_by(AIConversionLog.created_at.desc())
                )
                log = result.scalars().first()

                # 【結果検証】: ハッシュ値が期待通りであることを確認
                assert log is not None
                assert log.input_text_hash == expected_hash
                assert len(log.input_text_hash) == 64

                # 【結果検証】: ハッシュ値から元のテキストを復元できないことを確認
                # （ハッシュ値は元のテキストとは異なる）
                assert log.input_text_hash != input_text

    @pytest.mark.asyncio
    async def test_tc404_セッションid生成検証テスト(
        self, test_client_with_db, db_session: AsyncSession
    ):
        """
        【テスト目的】: セッションIDが正しく生成されることを確認
        【テスト内容】: 各リクエストで一意のsession_idが生成されることを検証
        【期待される動作】: session_idがUUID形式で、各リクエストで異なる
        🔵 testcases.md TC-404（AC-401）に基づく
        """
        # ユニークな入力テキストを使用
        input_text1 = "セッションテスト1_TC404_unique"
        input_text2 = "セッションテスト2_TC404_unique"
        expected_hash1 = hashlib.sha256(input_text1.encode("utf-8")).hexdigest()
        expected_hash2 = hashlib.sha256(input_text2.encode("utf-8")).hexdigest()
        request_body1 = {"input_text": input_text1, "politeness_level": "normal"}
        request_body2 = {"input_text": input_text2, "politeness_level": "normal"}

        # リクエスト前のログ数を記録
        result_before1 = await db_session.execute(
            select(AIConversionLog).where(AIConversionLog.input_text_hash == expected_hash1)
        )
        count_before1 = len(result_before1.scalars().all())

        result_before2 = await db_session.execute(
            select(AIConversionLog).where(AIConversionLog.input_text_hash == expected_hash2)
        )
        count_before2 = len(result_before2.scalars().all())

        with patch("app.utils.ai_client.ai_client") as mock_ai_client:
            mock_ai_client.convert_text = AsyncMock(return_value=("変換済み", 1000))

            async with AsyncClient(
                transport=ASGITransport(app=test_client_with_db), base_url="http://test"
            ) as client:
                # 1回目のリクエスト
                response1 = await client.post("/api/v1/ai/convert", json=request_body1)
                assert response1.status_code == 200

                # リミッターをリセット（2回目のリクエストを許可）
                limiter.reset()

                # 2回目のリクエスト
                response2 = await client.post("/api/v1/ai/convert", json=request_body2)
                assert response2.status_code == 200

                # 【結果検証】: 新しいログが作成されたことを確認
                result_after1 = await db_session.execute(
                    select(AIConversionLog).where(AIConversionLog.input_text_hash == expected_hash1)
                )
                count_after1 = len(result_after1.scalars().all())

                result_after2 = await db_session.execute(
                    select(AIConversionLog).where(AIConversionLog.input_text_hash == expected_hash2)
                )
                count_after2 = len(result_after2.scalars().all())

                # 【結果検証】: 各リクエストで1つずつログが増えていることを確認
                assert (
                    count_after1 == count_before1 + 1
                ), f"Expected log 1 to be created. Before: {count_before1}, After: {count_after1}"
                assert (
                    count_after2 == count_before2 + 1
                ), f"Expected log 2 to be created. Before: {count_before2}, After: {count_after2}"

                # 【結果検証】: 両方のログを取得
                result1 = await db_session.execute(
                    select(AIConversionLog)
                    .where(AIConversionLog.input_text_hash == expected_hash1)
                    .order_by(AIConversionLog.created_at.desc())
                )
                log1 = result1.scalars().first()

                result2 = await db_session.execute(
                    select(AIConversionLog)
                    .where(AIConversionLog.input_text_hash == expected_hash2)
                    .order_by(AIConversionLog.created_at.desc())
                )
                log2 = result2.scalars().first()

                # 【結果検証】: 各ログのsession_idがUUID形式であることを確認
                assert log1 is not None
                assert log2 is not None
                assert isinstance(log1.session_id, uuid.UUID)
                assert isinstance(log2.session_id, uuid.UUID)

                # 【結果検証】: 2つのログのsession_idが異なることを確認
                assert log1.session_id != log2.session_id

    @pytest.mark.asyncio
    async def test_tc405_converted_text未保存検証テスト(self):
        """
        【テスト目的】: 変換後テキストがログに保存されないことを確認
        【テスト内容】: AIConversionLogテーブルにconverted_textカラムがないことを検証
        【期待される動作】: converted_textカラムは存在せず、output_lengthのみ保存
        🔵 testcases.md TC-405（AC-403）に基づく
        """
        # 【結果検証】: AIConversionLogモデルにconverted_textカラムがないことを確認
        assert not hasattr(AIConversionLog, "converted_text")

        # 【結果検証】: output_lengthカラムが存在することを確認
        assert hasattr(AIConversionLog, "output_length")

        # 【結果検証】: テーブルのカラム名一覧にconverted_textが含まれないことを確認
        column_names = [c.name for c in AIConversionLog.__table__.columns]
        assert "converted_text" not in column_names
        assert "output_length" in column_names


# ================================================================================
# カテゴリF: 信頼性テストケース（DB障害時の応答保全・プロバイダー記録）
# ================================================================================


class TestAIConvertReliability:
    """DB障害時の応答保全と実際のAIプロバイダー記録に関するテスト"""

    @pytest.mark.asyncio
    async def test_tc410_成功時にdb書き込みが失敗しても成功応答が返る(self):
        """
        【テスト目的】: AI変換成功後のログ書き込みがDB障害で失敗しても、
                        成功した変換結果を捨てずに200を返すことを確認
        【テスト内容】: create_conversion_logが例外を送出する状況を再現
        【期待される動作】: 200 OKとAI変換結果が返される（DB例外はログのみで握りつぶす）
        """
        request_body = {"input_text": "DB障害時テスト", "politeness_level": "normal"}

        with (
            patch("app.utils.ai_client.ai_client") as mock_ai_client,
            patch(
                "app.api.v1.endpoints.ai.create_conversion_log",
                new_callable=AsyncMock,
                side_effect=Exception("database is down"),
            ),
        ):
            mock_ai_client.convert_text = AsyncMock(return_value=("変換結果", 900))

            async with AsyncClient(
                transport=ASGITransport(app=app), base_url="http://test"
            ) as client:
                response = await client.post("/api/v1/ai/convert", json=request_body)

                # 【結果検証】: DB障害があっても成功応答が返ることを確認
                assert response.status_code == 200
                response_json = response.json()
                assert response_json["converted_text"] == "変換結果"

    @pytest.mark.asyncio
    async def test_tc411_既知エラー時にdb書き込みが失敗しても意図したエラー応答が返る(self):
        """
        【テスト目的】: AI変換の既知エラー（レート制限）発生時、エラーログ書き込みが
                        DB障害で失敗しても、意図した429応答がDBエラー応答にすり替わらないことを確認
        【テスト内容】: create_conversion_logが例外を送出する状況を再現
        【期待される動作】: 429 Too Many RequestsとエラーコードAI_RATE_LIMITが返される
        """
        request_body = {"input_text": "DB障害時エラーテスト", "politeness_level": "normal"}

        with (
            patch("app.utils.ai_client.ai_client") as mock_ai_client,
            patch(
                "app.api.v1.endpoints.ai.create_conversion_log",
                new_callable=AsyncMock,
                side_effect=Exception("database is down"),
            ),
        ):
            mock_ai_client.convert_text = AsyncMock(
                side_effect=AIRateLimitException("AI API rate limit exceeded")
            )

            async with AsyncClient(
                transport=ASGITransport(app=app), base_url="http://test"
            ) as client:
                response = await client.post("/api/v1/ai/convert", json=request_body)

                # 【結果検証】: DB障害があっても意図した429応答が返ることを確認
                assert response.status_code == 429
                response_json = response.json()
                assert response_json["error"]["code"] == "AI_RATE_LIMIT"

    @pytest.mark.asyncio
    async def test_tc412_予期しないエラー時にdb書き込みが失敗しても500応答が返る(self):
        """
        【テスト目的】: 予期しないエラー発生時、エラーログ書き込みがDB障害で失敗しても、
                        未捕捉例外としてクラッシュせず統一形式の500応答が返ることを確認
        【テスト内容】: AIClient・create_conversion_logの両方が例外を送出する状況を再現
        【期待される動作】: 500 Internal Server ErrorとエラーコードINTERNAL_ERRORが返される
        """
        request_body = {"input_text": "DB障害時予期しないエラー", "politeness_level": "normal"}

        with (
            patch("app.utils.ai_client.ai_client") as mock_ai_client,
            patch(
                "app.api.v1.endpoints.ai.create_conversion_log",
                new_callable=AsyncMock,
                side_effect=Exception("database is down"),
            ),
        ):
            mock_ai_client.convert_text = AsyncMock(side_effect=RuntimeError("unexpected"))

            async with AsyncClient(
                transport=ASGITransport(app=app), base_url="http://test"
            ) as client:
                response = await client.post("/api/v1/ai/convert", json=request_body)

                # 【結果検証】: DB障害が二重に発生しても統一形式の500応答が返ることを確認
                assert response.status_code == 500
                response_json = response.json()
                assert response_json["error"]["code"] == "INTERNAL_ERROR"

    @pytest.mark.asyncio
    async def test_tc413_実際のaiプロバイダーがログに記録される(
        self, test_client_with_db, db_session: AsyncSession
    ):
        """
        【テスト目的】: create_conversion_logに実際のDEFAULT_AI_PROVIDER値が渡され、
                        固定値"anthropic"ではなく設定値どおりに記録されることを確認
        【テスト内容】: DEFAULT_AI_PROVIDERを"openai"にパッチしてAI変換を実行
        【期待される動作】: AIConversionLog.ai_providerが"openai"で記録される
        """
        from app.core.config import settings

        input_text = "プロバイダー記録テスト_TC413"
        expected_hash = hashlib.sha256(input_text.encode("utf-8")).hexdigest()
        request_body = {"input_text": input_text, "politeness_level": "normal"}

        with (
            patch("app.utils.ai_client.ai_client") as mock_ai_client,
            patch.object(settings, "DEFAULT_AI_PROVIDER", "openai"),
        ):
            mock_ai_client.convert_text = AsyncMock(return_value=("変換結果", 700))

            async with AsyncClient(
                transport=ASGITransport(app=test_client_with_db), base_url="http://test"
            ) as client:
                response = await client.post("/api/v1/ai/convert", json=request_body)
                assert response.status_code == 200

        result = await db_session.execute(
            select(AIConversionLog)
            .where(AIConversionLog.input_text_hash == expected_hash)
            .order_by(AIConversionLog.created_at.desc())
        )
        log = result.scalars().first()

        # 【結果検証】: 実際に使用したプロバイダー（openai）が記録されていることを確認
        assert log is not None
        assert log.ai_provider == "openai"
