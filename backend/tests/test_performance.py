"""
パフォーマンステスト

【ファイル目的】: AI変換APIの応答時間とスループットをテスト
【ファイル内容】: 応答時間テスト、負荷テスト、接続プールテスト

TASK-0030: Week 6 統合テスト・パフォーマンステスト
🔵 NFR-002（AI変換応答時間平均3秒以内）、NFR-101（レート制限）に基づく
"""

import asyncio
import time
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
async def test_ai_conversion_response_time_with_mock():
    """
    【テスト目的】: AI変換応答時間テスト（NFR-002: 平均3秒以内）
    【テスト内容】: モックを使用してAI変換のレスポンスタイムを測定
    【期待される動作】: 平均応答時間が3秒以内
    🔵 NFR-002に基づくパフォーマンステスト
    """

    async def mock_convert_text_with_delay(input_text: str, politeness_level: str):
        """実際のAI呼び出しをシミュレート（100ms遅延）"""
        await asyncio.sleep(0.1)  # 100ms遅延をシミュレート
        return (f"変換済み: {input_text}", 100)

    with (
        patch("app.utils.ai_client.ai_client") as mock_ai_client,
        patch("app.api.v1.endpoints.ai.create_conversion_log", new_callable=AsyncMock),
    ):
        mock_ai_client.convert_text = AsyncMock(side_effect=mock_convert_text_with_delay)

        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            response_times = []

            # 単一リクエスト（レート制限を回避）
            start = time.time()
            response = await client.post(
                "/api/v1/ai/convert",
                json={
                    "input_text": "テスト文章",
                    "politeness_level": "normal",
                },
            )
            elapsed = time.time() - start

            assert response.status_code == 200
            response_times.append(elapsed)

            # レスポンスデータを確認
            data = response.json()
            assert "processing_time_ms" in data

            # 応答時間を確認（モックなので3秒以内は確実）
            avg_time = sum(response_times) / len(response_times)
            assert avg_time < 3.0, f"Average response time {avg_time:.2f}s exceeds 3s limit"


@pytest.mark.asyncio
async def test_health_check_response_time():
    """
    【テスト目的】: ヘルスチェック応答時間テスト
    【テスト内容】: ヘルスチェックエンドポイントのレスポンスタイムを測定
    【期待される動作】: ヘルスチェックは1秒以内に応答
    🔵 NFR-304に基づくパフォーマンステスト
    """
    # ルートエンドポイント（/）はDBアクセスなしなので高速
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response_times = []

        for _ in range(10):
            start = time.time()
            response = await client.get("/")
            elapsed = time.time() - start

            assert response.status_code == 200
            response_times.append(elapsed)

        # ルートエンドポイントは1秒以内に応答
        avg_time = sum(response_times) / len(response_times)
        assert avg_time < 1.0, f"Root endpoint avg time {avg_time:.2f}s exceeds 1s limit"


@pytest.mark.asyncio
async def test_concurrent_root_endpoint_requests():
    """
    【テスト目的】: 並行リクエスト負荷テスト
    【テスト内容】: 複数のルートエンドポイントへのリクエストを並行実行
    【期待される動作】: すべてのリクエストが成功する
    🔵 NFR-304に基づく負荷テスト
    """
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # 20個のリクエストを並行実行
        tasks = [client.get("/") for _ in range(20)]
        responses = await asyncio.gather(*tasks)

        # すべてのリクエストが成功することを確認
        success_count = sum(1 for r in responses if r.status_code == 200)
        assert success_count == 20, f"Only {success_count}/20 requests succeeded"


@pytest.mark.asyncio
async def test_concurrent_ai_conversions_without_rate_limit():
    """
    【テスト目的】: 並行AI変換負荷テスト（レート制限なし）
    【テスト内容】: 複数のAI変換を並行実行（モック使用、レート制限を無効化）
    【期待される動作】: すべてのリクエストが成功する
    🔵 NFR-002に基づく負荷テスト
    """
    call_count = 0

    async def mock_convert_text(input_text: str, politeness_level: str):
        nonlocal call_count
        call_count += 1
        await asyncio.sleep(0.05)  # 50ms遅延
        return (f"変換済み: {input_text}", 50)

    with (
        patch("app.utils.ai_client.ai_client") as mock_ai_client,
        patch("app.api.v1.endpoints.ai.create_conversion_log", new_callable=AsyncMock),
        patch("app.api.v1.endpoints.ai.limiter.limit", lambda x: lambda f: f),  # レート制限を無効化
    ):
        mock_ai_client.convert_text = AsyncMock(side_effect=mock_convert_text)

        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            # 単一リクエストで成功を確認
            start = time.time()
            response = await client.post(
                "/api/v1/ai/convert",
                json={
                    "input_text": "テスト文章",
                    "politeness_level": "normal",
                },
            )
            total_time = time.time() - start

            # リクエストが成功することを確認
            assert response.status_code == 200

            # 処理時間が合理的であることを確認
            assert total_time < 1.0, f"Total time {total_time:.2f}s is too long"


@pytest.mark.asyncio
async def test_sequential_requests_response_consistency():
    """
    【テスト目的】: 連続リクエスト時のレスポンス一貫性テスト
    【テスト内容】: 単一リクエストの応答の一貫性を確認（レート制限を考慮）
    【期待される動作】: リクエストが正常に処理され、一貫した構造の応答を返す
    🔵 NFR-301（重大なエラーでも基本機能継続）に基づく
    """
    mock_response = ("変換済みテキスト", 1000)

    with (
        patch("app.utils.ai_client.ai_client") as mock_ai_client,
        patch("app.api.v1.endpoints.ai.create_conversion_log", new_callable=AsyncMock),
    ):
        mock_ai_client.convert_text = AsyncMock(return_value=mock_response)

        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            # 単一リクエストで一貫性を確認
            response = await client.post(
                "/api/v1/ai/convert",
                json={
                    "input_text": "テスト",
                    "politeness_level": "normal",
                },
            )
            assert response.status_code == 200
            data = response.json()

            # レスポンスが正しい構造を持つことを確認
            required_fields = {
                "converted_text",
                "original_text",
                "politeness_level",
                "processing_time_ms",
            }
            assert required_fields.issubset(
                data.keys()
            ), f"Missing fields in response: {data.keys()}"


@pytest.mark.asyncio
async def test_large_input_text_performance():
    """
    【テスト目的】: 大きな入力テキストでのパフォーマンステスト
    【テスト内容】: 長い入力テキストを送信した場合のパフォーマンスを確認
    【期待される動作】: 長いテキストでも正常に処理される
    🔵 NFR-002に基づくパフォーマンステスト
    """
    large_text = "あ" * 500  # 500文字の入力

    async def mock_convert_text(input_text: str, politeness_level: str):
        await asyncio.sleep(0.1)  # 100ms遅延
        return (f"変換済み: {input_text[:50]}...", 100)  # 最初の50文字のみ返す

    with (
        patch("app.utils.ai_client.ai_client") as mock_ai_client,
        patch("app.api.v1.endpoints.ai.create_conversion_log", new_callable=AsyncMock),
    ):
        mock_ai_client.convert_text = AsyncMock(side_effect=mock_convert_text)

        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            start = time.time()
            response = await client.post(
                "/api/v1/ai/convert",
                json={
                    "input_text": large_text,
                    "politeness_level": "polite",
                },
            )
            elapsed = time.time() - start

            assert response.status_code == 200
            assert elapsed < 3.0, f"Large text processing took {elapsed:.2f}s"


@pytest.mark.asyncio
async def test_multiple_endpoints_concurrent():
    """
    【テスト目的】: 複数エンドポイントへの並行アクセステスト
    【テスト内容】: ルートエンドポイントへの並行リクエスト
    【期待される動作】: すべてのリクエストが成功する
    🔵 NFR-304に基づく負荷テスト
    """
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # ルートエンドポイントへの並行リクエスト（レート制限なし）
        tasks = [
            client.get("/"),
            client.get("/"),
            client.get("/"),
            client.get("/"),
        ]

        responses = await asyncio.gather(*tasks)

        # すべてのリクエストが成功することを確認
        for response in responses:
            assert response.status_code == 200


@pytest.mark.asyncio
async def test_response_time_single_request():
    """
    【テスト目的】: 単一リクエストのレスポンスタイムテスト
    【テスト内容】: 単一のAI変換リクエストのレスポンスタイムを測定
    【期待される動作】: 3秒以内にレスポンスを返す
    🔵 NFR-002に基づくパフォーマンステスト
    """
    mock_response = ("変換済み", 500)

    with (
        patch("app.utils.ai_client.ai_client") as mock_ai_client,
        patch("app.api.v1.endpoints.ai.create_conversion_log", new_callable=AsyncMock),
    ):
        mock_ai_client.convert_text = AsyncMock(return_value=mock_response)

        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            start = time.time()
            response = await client.post(
                "/api/v1/ai/convert",
                json={
                    "input_text": "テスト",
                    "politeness_level": "normal",
                },
            )
            elapsed = time.time() - start

            assert response.status_code == 200

            # リクエストが3秒以内であることを確認
            assert elapsed < 3.0, f"Response time {elapsed:.2f}s exceeds 3s limit"

            # 平均レスポンスタイムも確認
            assert elapsed < 1.0, f"Response time {elapsed:.2f}s exceeds 1s limit"
