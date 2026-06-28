"""
AI再変換エンドポイントテスト

TASK-0028: AI再変換エンドポイント実装（POST /api/v1/ai/regenerate）

【テストファイル目的】: AI再変換エンドポイントの動作を検証（TDDレッドフェーズ）
【テストファイル内容】: 正常系、バリデーション、レート制限、エラーハンドリング、ログ記録のテストケースを網羅
【期待されるカバレッジ】: 90%以上のテストカバレッジを達成（NFR-502要件）

🔵 REQ-904（同じ丁寧さで再変換可能）に基づく実装
"""

import hashlib
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
    AITimeoutException,
)
from tests.conftest import AUTH_HEADERS


@pytest.fixture(autouse=True)
async def reset_limiter():
    """各テスト実行前にリミッターのストレージをリセット"""
    limiter.reset()
    yield
    limiter.reset()


# ================================================================================
# カテゴリA: 正常系テストケース
# ================================================================================


class TestAIRegenerateSuccess:
    """AI再変換正常系テスト"""

    @pytest.mark.asyncio
    async def test_tc501_基本的なai再変換成功テスト(self):
        """
        【テスト目的】: 基本的なAI再変換が成功することを確認
        【テスト内容】: 有効な入力でAI再変換が正常に処理されることを検証
        【期待される動作】: 200 OKとAI変換結果が返され、前回結果と異なる
        🔵 REQ-904に基づく
        """
        request_body = {
            "input_text": "水 ぬるく",
            "politeness_level": "polite",
            "previous_result": "お水をぬるめでお願いいたします",
        }

        with (
            patch("app.utils.ai_client.ai_client") as mock_ai_client,
            patch("app.api.v1.endpoints.ai.create_conversion_log", new_callable=AsyncMock),
        ):
            # 前回と異なる結果を返すようにモック設定
            mock_ai_client.regenerate_text = AsyncMock(
                return_value=("ぬるいお水をいただけますでしょうか", 1800)
            )

            async with AsyncClient(
                transport=ASGITransport(app=app), base_url="http://test"
            ) as client:
                response = await client.post(
                    "/api/v1/ai/regenerate", json=request_body, headers=AUTH_HEADERS
                )

                # 【結果検証】: HTTPステータスコードが200であることを確認
                assert response.status_code == 200

                # 【結果検証】: レスポンスボディの内容を確認
                response_json = response.json()
                assert "converted_text" in response_json
                assert response_json["converted_text"] == "ぬるいお水をいただけますでしょうか"
                assert response_json["original_text"] == "水 ぬるく"
                assert response_json["politeness_level"] == "polite"
                assert "processing_time_ms" in response_json
                assert response_json["processing_time_ms"] == 1800

                # 【結果検証】: 前回結果と異なることを確認
                assert response_json["converted_text"] != request_body["previous_result"]

    @pytest.mark.asyncio
    async def test_tc502_丁寧さレベルcasual再変換テスト(self):
        """
        【テスト目的】: 丁寧さレベル「casual」でAI再変換が成功することを確認
        【テスト内容】: casualレベルでの再変換結果を検証
        【期待される動作】: 200 OKとカジュアルな変換結果が返される
        🔵 REQ-904に基づく
        """
        request_body = {
            "input_text": "ありがとう",
            "politeness_level": "casual",
            "previous_result": "サンキュー",
        }

        with (
            patch("app.utils.ai_client.ai_client") as mock_ai_client,
            patch("app.api.v1.endpoints.ai.create_conversion_log", new_callable=AsyncMock),
        ):
            mock_ai_client.regenerate_text = AsyncMock(return_value=("ありがとね", 1200))

            async with AsyncClient(
                transport=ASGITransport(app=app), base_url="http://test"
            ) as client:
                response = await client.post(
                    "/api/v1/ai/regenerate", json=request_body, headers=AUTH_HEADERS
                )

                assert response.status_code == 200
                response_json = response.json()
                assert response_json["politeness_level"] == "casual"
                assert response_json["converted_text"] == "ありがとね"

    @pytest.mark.asyncio
    async def test_tc503_丁寧さレベルnormal再変換テスト(self):
        """
        【テスト目的】: 丁寧さレベル「normal」でAI再変換が成功することを確認
        【テスト内容】: normalレベルでの再変換結果を検証
        【期待される動作】: 200 OKとです・ます調の変換結果が返される
        🔵 REQ-904に基づく
        """
        request_body = {
            "input_text": "これ ほしい",
            "politeness_level": "normal",
            "previous_result": "これをいただけますか",
        }

        with (
            patch("app.utils.ai_client.ai_client") as mock_ai_client,
            patch("app.api.v1.endpoints.ai.create_conversion_log", new_callable=AsyncMock),
        ):
            mock_ai_client.regenerate_text = AsyncMock(return_value=("これがほしいです", 1300))

            async with AsyncClient(
                transport=ASGITransport(app=app), base_url="http://test"
            ) as client:
                response = await client.post(
                    "/api/v1/ai/regenerate", json=request_body, headers=AUTH_HEADERS
                )

                assert response.status_code == 200
                response_json = response.json()
                assert response_json["politeness_level"] == "normal"

    @pytest.mark.asyncio
    async def test_tc504_丁寧さレベルpolite再変換テスト(self):
        """
        【テスト目的】: 丁寧さレベル「polite」でAI再変換が成功することを確認
        【テスト内容】: politeレベルでの再変換結果を検証
        【期待される動作】: 200 OKと敬語の変換結果が返される
        🔵 REQ-904に基づく
        """
        request_body = {
            "input_text": "ありがとう",
            "politeness_level": "polite",
            "previous_result": "誠にありがとうございます",
        }

        with (
            patch("app.utils.ai_client.ai_client") as mock_ai_client,
            patch("app.api.v1.endpoints.ai.create_conversion_log", new_callable=AsyncMock),
        ):
            mock_ai_client.regenerate_text = AsyncMock(
                return_value=("心より感謝申し上げます", 1400)
            )

            async with AsyncClient(
                transport=ASGITransport(app=app), base_url="http://test"
            ) as client:
                response = await client.post(
                    "/api/v1/ai/regenerate", json=request_body, headers=AUTH_HEADERS
                )

                assert response.status_code == 200
                response_json = response.json()
                assert response_json["politeness_level"] == "polite"
                assert response_json["converted_text"] == "心より感謝申し上げます"

    @pytest.mark.asyncio
    async def test_tc505_レスポンスヘッダー検証テスト(self):
        """
        【テスト目的】: レスポンスにX-RateLimit-*ヘッダーが含まれることを確認
        【テスト内容】: レート制限ヘッダーの存在と値を検証
        【期待される動作】: X-RateLimit-Limit, Remaining, Resetが返される
        """
        request_body = {
            "input_text": "テスト入力",
            "politeness_level": "normal",
            "previous_result": "変換済みテスト",
        }

        with (
            patch("app.utils.ai_client.ai_client") as mock_ai_client,
            patch("app.api.v1.endpoints.ai.create_conversion_log", new_callable=AsyncMock),
        ):
            mock_ai_client.regenerate_text = AsyncMock(return_value=("新しい変換テスト", 1000))

            async with AsyncClient(
                transport=ASGITransport(app=app), base_url="http://test"
            ) as client:
                response = await client.post(
                    "/api/v1/ai/regenerate", json=request_body, headers=AUTH_HEADERS
                )

                assert response.status_code == 200

                # 【結果検証】: X-RateLimit-*ヘッダーが存在することを確認
                assert "x-ratelimit-limit" in response.headers
                assert "x-ratelimit-remaining" in response.headers
                assert "x-ratelimit-reset" in response.headers


# ================================================================================
# カテゴリB: 入力バリデーションテストケース
# ================================================================================


class TestAIRegenerateValidation:
    """AI再変換入力バリデーションテスト"""

    @pytest.mark.asyncio
    async def test_tc601_空文字列input_textエラーテスト(self):
        """
        【テスト目的】: 空文字列のinput_textがエラーになることを確認
        【テスト内容】: 空文字列の入力を検証
        【期待される動作】: 422 Unprocessable Entityが返される
        """
        request_body = {
            "input_text": "",
            "politeness_level": "normal",
            "previous_result": "前回結果",
        }

        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            response = await client.post(
                "/api/v1/ai/regenerate", json=request_body, headers=AUTH_HEADERS
            )

            # 【結果検証】: 422エラーが返されることを確認
            assert response.status_code == 422

    @pytest.mark.asyncio
    async def test_tc602_空文字列previous_resultエラーテスト(self):
        """
        【テスト目的】: 空文字列のprevious_resultがエラーになることを確認
        【テスト内容】: 空文字列のprevious_resultを検証
        【期待される動作】: 422 Unprocessable Entityが返される
        """
        request_body = {
            "input_text": "こんにちは",
            "politeness_level": "normal",
            "previous_result": "",
        }

        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            response = await client.post(
                "/api/v1/ai/regenerate", json=request_body, headers=AUTH_HEADERS
            )

            # 【結果検証】: 422エラーが返されることを確認
            assert response.status_code == 422

    @pytest.mark.asyncio
    async def test_tc603_文字数超過501文字エラーテスト(self):
        """
        【テスト目的】: 501文字の入力がエラーになることを確認
        【テスト内容】: 最大文字数超過（501文字）の入力を検証
        【期待される動作】: 422 Unprocessable Entityが返される
        """
        # 501文字の入力テキストを作成
        input_text = "あ" * 501
        request_body = {
            "input_text": input_text,
            "politeness_level": "normal",
            "previous_result": "前回結果",
        }

        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            response = await client.post(
                "/api/v1/ai/regenerate", json=request_body, headers=AUTH_HEADERS
            )

            # 【結果検証】: 422エラーが返されることを確認
            assert response.status_code == 422

    @pytest.mark.asyncio
    async def test_tc604_不正な丁寧さレベルエラーテスト(self):
        """
        【テスト目的】: 不正な丁寧さレベルがエラーになることを確認
        【テスト内容】: 無効なpoliteness_levelを検証
        【期待される動作】: 422 Unprocessable Entityが返される
        """
        request_body = {
            "input_text": "こんにちは",
            "politeness_level": "invalid",
            "previous_result": "前回結果",
        }

        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            response = await client.post(
                "/api/v1/ai/regenerate", json=request_body, headers=AUTH_HEADERS
            )

            # 【結果検証】: 422エラーが返されることを確認
            assert response.status_code == 422

    @pytest.mark.asyncio
    async def test_tc605_previous_result未指定エラーテスト(self):
        """
        【テスト目的】: previous_result未指定がエラーになることを確認
        【テスト内容】: previous_resultフィールドがないリクエストを検証
        【期待される動作】: 422 Unprocessable Entityが返される
        """
        request_body = {
            "input_text": "こんにちは",
            "politeness_level": "normal",
        }

        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            response = await client.post(
                "/api/v1/ai/regenerate", json=request_body, headers=AUTH_HEADERS
            )

            # 【結果検証】: 422エラーが返されることを確認
            assert response.status_code == 422


# ================================================================================
# カテゴリC: レート制限テストケース
# ================================================================================


class TestAIRegenerateRateLimit:
    """AI再変換レート制限テスト"""

    @pytest.mark.asyncio
    async def test_tc701_レート制限超過429テスト(self):
        """
        【テスト目的】: レート制限超過で429エラーが返されることを確認
        【テスト内容】: 10秒以内に2回のリクエストを送信し、2回目が拒否されることを検証
        【期待される動作】: 1回目は成功、2回目は429 Too Many Requests
        """
        request_body = {
            "input_text": "レート制限テスト",
            "politeness_level": "normal",
            "previous_result": "前回結果",
        }

        with (
            patch("app.utils.ai_client.ai_client") as mock_ai_client,
            patch("app.api.v1.endpoints.ai.create_conversion_log", new_callable=AsyncMock),
        ):
            mock_ai_client.regenerate_text = AsyncMock(return_value=("変換済み", 1000))

            async with AsyncClient(
                transport=ASGITransport(app=app), base_url="http://test"
            ) as client:
                # 1回目のリクエスト
                response1 = await client.post(
                    "/api/v1/ai/regenerate", json=request_body, headers=AUTH_HEADERS
                )
                assert response1.status_code == 200

                # 2回目のリクエスト（即座に送信）
                response2 = await client.post(
                    "/api/v1/ai/regenerate", json=request_body, headers=AUTH_HEADERS
                )

                # 【結果検証】: 2回目は429エラーであることを確認
                assert response2.status_code == 429


# ================================================================================
# カテゴリD: エラーハンドリングテストケース
# ================================================================================


class TestAIRegenerateErrorHandling:
    """AI再変換エラーハンドリングテスト"""

    @pytest.mark.asyncio
    async def test_tc801_aiタイムアウトエラー504テスト(self):
        """
        【テスト目的】: AIタイムアウト時に504エラーが返されることを確認
        【テスト内容】: AIClientがAITimeoutExceptionをスローした場合の動作を検証
        【期待される動作】: 504 Gateway Timeoutとエラーコード"AI_API_TIMEOUT"
        """
        request_body = {
            "input_text": "タイムアウトテスト",
            "politeness_level": "normal",
            "previous_result": "前回結果",
        }

        with (
            patch("app.utils.ai_client.ai_client") as mock_ai_client,
            patch("app.api.v1.endpoints.ai.create_conversion_log", new_callable=AsyncMock),
        ):
            mock_ai_client.regenerate_text = AsyncMock(
                side_effect=AITimeoutException("AI API timeout")
            )

            async with AsyncClient(
                transport=ASGITransport(app=app), base_url="http://test"
            ) as client:
                response = await client.post(
                    "/api/v1/ai/regenerate", json=request_body, headers=AUTH_HEADERS
                )

                # 【結果検証】: 504エラーが返されることを確認
                assert response.status_code == 504

                # 【結果検証】: エラーレスポンス形式を確認
                response_json = response.json()
                assert response_json["success"] is False
                assert response_json["error"]["code"] == "AI_API_TIMEOUT"

    @pytest.mark.asyncio
    async def test_tc802_aiプロバイダーエラー503テスト(self):
        """
        【テスト目的】: AIプロバイダーエラー時に503エラーが返されることを確認
        【テスト内容】: AIClientがAIProviderExceptionをスローした場合の動作を検証
        【期待される動作】: 503 Service Unavailableとエラーコード"AI_PROVIDER_ERROR"
        """
        request_body = {
            "input_text": "プロバイダーエラーテスト",
            "politeness_level": "normal",
            "previous_result": "前回結果",
        }

        with (
            patch("app.utils.ai_client.ai_client") as mock_ai_client,
            patch("app.api.v1.endpoints.ai.create_conversion_log", new_callable=AsyncMock),
        ):
            mock_ai_client.regenerate_text = AsyncMock(
                side_effect=AIProviderException("Anthropic API key is not configured")
            )

            async with AsyncClient(
                transport=ASGITransport(app=app), base_url="http://test"
            ) as client:
                response = await client.post(
                    "/api/v1/ai/regenerate", json=request_body, headers=AUTH_HEADERS
                )

                # 【結果検証】: 503エラーが返されることを確認
                assert response.status_code == 503

                # 【結果検証】: エラーレスポンス形式を確認
                response_json = response.json()
                assert response_json["success"] is False
                assert response_json["error"]["code"] == "AI_PROVIDER_ERROR"

    @pytest.mark.asyncio
    async def test_tc803_ai変換一般エラー500テスト(self):
        """
        【テスト目的】: AI変換一般エラー時に500エラーが返されることを確認
        【テスト内容】: AIClientがAIConversionExceptionをスローした場合の動作を検証
        【期待される動作】: 500 Internal Server Errorとエラーコード"AI_API_ERROR"
        """
        request_body = {
            "input_text": "一般エラーテスト",
            "politeness_level": "normal",
            "previous_result": "前回結果",
        }

        with (
            patch("app.utils.ai_client.ai_client") as mock_ai_client,
            patch("app.api.v1.endpoints.ai.create_conversion_log", new_callable=AsyncMock),
        ):
            mock_ai_client.regenerate_text = AsyncMock(
                side_effect=AIConversionException("AI conversion failed")
            )

            async with AsyncClient(
                transport=ASGITransport(app=app), base_url="http://test"
            ) as client:
                response = await client.post(
                    "/api/v1/ai/regenerate", json=request_body, headers=AUTH_HEADERS
                )

                # 【結果検証】: 500エラーが返されることを確認
                assert response.status_code == 500

                # 【結果検証】: エラーレスポンス形式を確認
                response_json = response.json()
                assert response_json["success"] is False
                assert response_json["error"]["code"] == "AI_API_ERROR"


# ================================================================================
# カテゴリE: ログ記録テストケース
# ================================================================================


class TestAIRegenerateLogging:
    """AI再変換ログ記録テスト"""

    @pytest.mark.asyncio
    async def test_tc901_成功時ログ記録テスト(self, test_client_with_db, db_session: AsyncSession):
        """
        【テスト目的】: AI再変換成功時にログが記録されることを確認
        【テスト内容】: 成功レスポンス後にAIConversionLogが作成されることを検証
        【期待される動作】: ログレコードが作成され、is_success=True
        """
        input_text = "再変換ログテスト入力_TC901"
        expected_hash = hashlib.sha256(input_text.encode("utf-8")).hexdigest()
        request_body = {
            "input_text": input_text,
            "politeness_level": "normal",
            "previous_result": "前回結果",
        }

        # リクエスト前のログ数を記録
        result_before = await db_session.execute(
            select(AIConversionLog).where(AIConversionLog.input_text_hash == expected_hash)
        )
        logs_before = result_before.scalars().all()
        count_before = len(logs_before)

        with patch("app.utils.ai_client.ai_client") as mock_ai_client:
            mock_ai_client.regenerate_text = AsyncMock(return_value=("再変換ログテスト出力", 1500))

            async with AsyncClient(
                transport=ASGITransport(app=test_client_with_db), base_url="http://test"
            ) as client:
                response = await client.post(
                    "/api/v1/ai/regenerate", json=request_body, headers=AUTH_HEADERS
                )

                assert response.status_code == 200

                # 【結果検証】: 新しいログレコードが作成されたことを確認
                result_after = await db_session.execute(
                    select(AIConversionLog).where(AIConversionLog.input_text_hash == expected_hash)
                )
                logs_after = result_after.scalars().all()
                count_after = len(logs_after)

                # 【結果検証】: ログ数が1つ増えていることを確認
                assert count_after == count_before + 1

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
