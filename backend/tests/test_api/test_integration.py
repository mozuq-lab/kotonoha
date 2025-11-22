"""
統合テスト

【ファイル目的】: AI変換APIのフルワークフローテスト
【ファイル内容】: 統合テスト（ヘルスチェック → AI変換 → AI再変換）

TASK-0030: Week 6 統合テスト・パフォーマンステスト
🔵 NFR-002（AI変換応答時間）、NFR-502（テストカバレッジ90%以上）に基づく
"""

from unittest.mock import AsyncMock, patch

import pytest
from httpx import ASGITransport, AsyncClient

from app.core.rate_limit import limiter
from app.main import app


@pytest.fixture(autouse=True)
async def reset_limiter():
    """各テスト実行前にリミッターのストレージをリセット"""
    limiter.reset()
    yield
    limiter.reset()


@pytest.mark.asyncio
async def test_full_conversion_workflow_with_mock():
    """
    【テスト目的】: AI変換フルワークフローテスト（モック使用）
    【テスト内容】: ヘルスチェック → AI変換 → AI再変換の一連の流れをテスト
    【期待される動作】: すべてのエンドポイントが正常に応答する
    🔵 TASK-0030に基づく統合テスト
    """
    # AI変換のモックレスポンス (converted_text, processing_time_ms)
    mock_convert_response = ("いつもありがとうございます。心より感謝申し上げます。", 1500)
    mock_regenerate_response = ("ありがとうございます。深く感謝いたします。", 1200)

    with (
        patch("app.main.get_ai_provider_status", return_value="anthropic"),
        patch("app.utils.ai_client.ai_client") as mock_ai_client,
        patch("app.api.v1.endpoints.ai.create_conversion_log", new_callable=AsyncMock),
    ):
        mock_ai_client.convert_text = AsyncMock(return_value=mock_convert_response)
        mock_ai_client.regenerate_text = AsyncMock(return_value=mock_regenerate_response)

        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            # Step 1: ルートエンドポイント確認
            root_response = await client.get("/")
            assert root_response.status_code == 200
            root_data = root_response.json()
            assert root_data["message"] == "kotonoha API is running"

            # Step 2: AI変換
            convert_response = await client.post(
                "/api/v1/ai/convert",
                json={
                    "input_text": "ありがとう",
                    "politeness_level": "polite",
                },
            )
            assert convert_response.status_code == 200
            convert_data = convert_response.json()
            assert convert_data["original_text"] == "ありがとう"
            assert convert_data["politeness_level"] == "polite"
            assert convert_data["converted_text"] == mock_convert_response[0]

            # Step 3: AI再変換（正しいスキーマフィールド名を使用）
            regenerate_response = await client.post(
                "/api/v1/ai/regenerate",
                json={
                    "input_text": "ありがとう",
                    "politeness_level": "polite",
                    "previous_result": convert_data["converted_text"],
                },
            )
            assert regenerate_response.status_code == 200
            regenerate_data = regenerate_response.json()
            assert regenerate_data["original_text"] == "ありがとう"
            assert regenerate_data["converted_text"] == mock_regenerate_response[0]


@pytest.mark.asyncio
async def test_multiple_conversions_different_levels_with_mock():
    """
    【テスト目的】: 複数の丁寧さレベルでの変換テスト
    【テスト内容】: casual、normal、politeの3レベルでAI変換を実行
    【期待される動作】: 各レベルで正常に変換が行われる
    🔵 TASK-0030に基づく統合テスト
    """
    # 各丁寧さレベルに対応するモックレスポンス
    mock_responses = {
        "casual": ("お疲れ〜", 800),
        "normal": ("お疲れ様です", 1000),
        "polite": ("お疲れ様でございます。本日もありがとうございました。", 1200),
    }

    async def mock_convert_text(input_text: str, politeness_level: str):
        """キーワード引数で呼ばれるモック関数"""
        return mock_responses.get(politeness_level, (input_text, 1000))

    with (
        patch("app.utils.ai_client.ai_client") as mock_ai_client,
        patch("app.api.v1.endpoints.ai.create_conversion_log", new_callable=AsyncMock),
    ):
        mock_ai_client.convert_text = AsyncMock(side_effect=mock_convert_text)

        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            input_text = "お疲れ様"
            results = {}

            for level in ["casual", "normal", "polite"]:
                # 各リクエスト前にリミッターをリセット（レート制限を回避）
                limiter.reset()
                response = await client.post(
                    "/api/v1/ai/convert",
                    json={
                        "input_text": input_text,
                        "politeness_level": level,
                    },
                )
                assert response.status_code == 200
                results[level] = response.json()

            # 各レベルで正しい結果が得られることを確認
            assert results["casual"]["converted_text"] == mock_responses["casual"][0]
            assert results["casual"]["politeness_level"] == "casual"

            assert results["normal"]["converted_text"] == mock_responses["normal"][0]
            assert results["normal"]["politeness_level"] == "normal"

            assert results["polite"]["converted_text"] == mock_responses["polite"][0]
            assert results["polite"]["politeness_level"] == "polite"


@pytest.mark.asyncio
async def test_error_handling_invalid_politeness_level():
    """
    【テスト目的】: 不正な丁寧さレベルでのエラーハンドリングテスト
    【テスト内容】: 無効なpoliteness_levelを送信した場合のエラー応答を確認
    【期待される動作】: 422 Unprocessable Entityエラーを返す
    🔵 TASK-0030に基づく統合テスト
    """
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post(
            "/api/v1/ai/convert",
            json={
                "input_text": "テスト",
                "politeness_level": "invalid_level",
            },
        )
        assert response.status_code == 422  # Validation Error


@pytest.mark.asyncio
async def test_error_handling_empty_input_text():
    """
    【テスト目的】: 空文字列でのエラーハンドリングテスト
    【テスト内容】: 空のinput_textを送信した場合のエラー応答を確認
    【期待される動作】: 422 Unprocessable Entityエラーを返す
    🔵 TASK-0030に基づく統合テスト
    """
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post(
            "/api/v1/ai/convert",
            json={
                "input_text": "",
                "politeness_level": "normal",
            },
        )
        assert response.status_code == 422  # Validation Error


@pytest.mark.asyncio
async def test_root_endpoint_integration():
    """
    【テスト目的】: ルートエンドポイントの統合テスト
    【テスト内容】: GET / エンドポイントが正常に応答することを確認
    【期待される動作】: APIメッセージとバージョン情報を返す
    🔵 TASK-0030に基づく統合テスト
    """
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/")
        assert response.status_code == 200
        data = response.json()
        assert data["message"] == "kotonoha API is running"
        assert "version" in data


@pytest.mark.asyncio
async def test_regenerate_workflow_with_mock():
    """
    【テスト目的】: 再変換ワークフローテスト
    【テスト内容】: AI変換後に再変換を行う一連の流れをテスト
    【期待される動作】: 再変換が正常に行われ、異なる結果が返される
    🔵 TASK-0030に基づく統合テスト
    """
    mock_convert_response = ("変換結果1", 1500)
    mock_regenerate_response = ("再変換結果", 1200)

    with (
        patch("app.utils.ai_client.ai_client") as mock_ai_client,
        patch("app.api.v1.endpoints.ai.create_conversion_log", new_callable=AsyncMock),
    ):
        mock_ai_client.convert_text = AsyncMock(return_value=mock_convert_response)
        mock_ai_client.regenerate_text = AsyncMock(return_value=mock_regenerate_response)

        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            # Step 1: 最初の変換
            convert_response = await client.post(
                "/api/v1/ai/convert",
                json={
                    "input_text": "テスト入力",
                    "politeness_level": "normal",
                },
            )
            assert convert_response.status_code == 200
            convert_data = convert_response.json()
            first_converted_text = convert_data["converted_text"]

            # Step 2: 再変換（正しいスキーマフィールド名を使用）
            regenerate_response = await client.post(
                "/api/v1/ai/regenerate",
                json={
                    "input_text": "テスト入力",
                    "politeness_level": "normal",
                    "previous_result": first_converted_text,
                },
            )
            assert regenerate_response.status_code == 200
            regenerate_data = regenerate_response.json()

            # 再変換結果が元の変換結果と異なることを確認
            assert regenerate_data["converted_text"] == mock_regenerate_response[0]
            assert regenerate_data["original_text"] == "テスト入力"


@pytest.mark.asyncio
async def test_missing_required_field_error():
    """
    【テスト目的】: 必須フィールド欠落時のエラーハンドリングテスト
    【テスト内容】: input_textフィールドを省略した場合のエラー応答を確認
    【期待される動作】: 422 Unprocessable Entityエラーを返す
    🔵 TASK-0030に基づく統合テスト
    """
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post(
            "/api/v1/ai/convert",
            json={
                "politeness_level": "normal",
                # input_text を省略
            },
        )
        assert response.status_code == 422  # Validation Error


@pytest.mark.asyncio
async def test_invalid_json_error():
    """
    【テスト目的】: 不正なJSONでのエラーハンドリングテスト
    【テスト内容】: 不正な形式のリクエストボディを送信した場合のエラー応答を確認
    【期待される動作】: 422 Unprocessable Entityエラーを返す
    🔵 TASK-0030に基づく統合テスト
    """
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post(
            "/api/v1/ai/convert",
            content="invalid json",
            headers={"Content-Type": "application/json"},
        )
        assert response.status_code == 422  # Validation Error
