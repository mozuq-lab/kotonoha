"""
ヘルスチェック・基本APIエンドポイントテスト

カテゴリA: ルートエンドポイント（GET /）
カテゴリB: ヘルスチェックエンドポイント（GET /health）

【テストファイル目的】: バックエンドヘルスチェック・基本APIエンドポイントの動作を検証
【テストファイル内容】: 正常系、異常系、境界値のテストケースを網羅
【期待されるカバレッジ】: 90%以上のテストカバレッジを達成（NFR-502要件）
🔵 backend-health-api-testcases.md に基づく実装
"""

import time
from datetime import datetime

import pytest
from httpx import ASGITransport, AsyncClient

from app.main import app

# ================================================================================
# カテゴリA: ルートエンドポイント（GET /）
# ================================================================================


@pytest.mark.asyncio
async def test_root_endpoint_returns_success():
    """
    【テスト目的】: ルートエンドポイントが正常に応答することを確認
    【テスト内容】: GET /が正しいJSONレスポンスを返すことを検証
    【期待される動作】: ステータスコード200、messageとversionを含むJSON
    🔵 testcases.md A-1（line 70-87）に基づく

    【テストシナリオ】:
    - Given: FastAPIアプリケーションが起動している
    - When: GET /にアクセス
    - Then: HTTPステータスコード200、messageとversionフィールドを持つJSONレスポンス
    """
    # 【テストデータ準備】: HTTPクライアントを作成し、FastAPIアプリケーションにアクセス
    # 【初期条件設定】: ルートエンドポイントへの最も基本的なリクエストを送信
    # 🔵 testcases.md A-1（line 76-77）に基づく
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        # 【実際の処理実行】: GET /にリクエストを送信
        # 【処理内容】: アプリケーション稼働確認のための最も基本的なエンドポイントを呼び出す
        response = await client.get("/")

        # 【結果検証】: HTTPステータスコードが200であることを確認
        # 【期待値確認】: 正常に応答していることを検証
        assert response.status_code == 200  # 【確認内容】: HTTPステータスコード200（成功） 🔵

        # 【結果検証】: レスポンスボディがJSON形式であることを確認
        # 【期待値確認】: 期待されるフィールド（message, version）を含むことを検証
        response_json = response.json()
        assert "message" in response_json  # 【確認内容】: messageフィールドが存在する 🔵
        assert "version" in response_json  # 【確認内容】: versionフィールドが存在する 🔵
        assert (
            response_json["message"] == "kotonoha API is running"
        )  # 【確認内容】: メッセージ内容が正しい 🔵
        assert response_json["version"] == "1.0.0"  # 【確認内容】: バージョン情報が正しい 🔵


@pytest.mark.asyncio
async def test_root_endpoint_sets_correct_content_type():
    """
    【テスト目的】: ルートエンドポイントがContent-Typeヘッダーを正しく設定することを確認
    【テスト内容】: レスポンスヘッダーにContent-Type: application/jsonが含まれることを検証
    【期待される動作】: Content-Type: application/json; charset=utf-8が設定される
    🔵 testcases.md A-2（line 89-100）に基づく

    【テストシナリオ】:
    - Given: FastAPIアプリケーションが起動している
    - When: GET /にアクセス
    - Then: レスポンスヘッダーにContent-Type: application/jsonが設定される
    """
    # 【テストデータ準備】: HTTPクライアントを作成
    # 【初期条件設定】: APIクライアントがレスポンス形式を判断するための情報を確認
    # 🔵 testcases.md A-2（line 93-96）に基づく
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        # 【実際の処理実行】: GET /にリクエストを送信
        # 【処理内容】: レスポンスヘッダーの内容を確認するためのリクエスト
        response = await client.get("/")

        # 【結果検証】: Content-Typeヘッダーが正しく設定されていることを確認
        # 【期待値確認】: JSON APIの標準仕様（NFR-504）に準拠
        assert response.status_code == 200  # 【確認内容】: HTTPステータスコード200 🔵
        assert (
            "application/json" in response.headers["content-type"]
        )  # 【確認内容】: Content-Typeヘッダーがapplication/jsonを含む 🔵


@pytest.mark.asyncio
async def test_root_endpoint_responds_within_100ms():
    """
    【テスト目的】: ルートエンドポイントが100ms以内に応答することを確認
    【テスト内容】: パフォーマンス要件（NFR-003）を満たすことを検証
    【期待される動作】: 100ms以内にレスポンスが返される
    🔵 testcases.md A-3（line 102-113）に基づく

    【テストシナリオ】:
    - Given: FastAPIアプリケーションが起動している
    - When: GET /にアクセスし、レスポンス時間を計測
    - Then: レスポンス時間が100ms以内である
    """
    # 【テストデータ準備】: HTTPクライアントと時間計測の準備
    # 【初期条件設定】: データベースアクセスなしの最軽量エンドポイントをテスト
    # 🔵 testcases.md A-3（line 105-109）、NFR-003に基づく
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        # 【実際の処理実行】: レスポンス時間を計測
        # 【処理内容】: パフォーマンス要件を満たすかを検証
        start_time = time.perf_counter()
        response = await client.get("/")
        end_time = time.perf_counter()

        # 【結果検証】: レスポンス時間が100ms以内であることを確認
        # 【期待値確認】: NFR-003要件を満たすことを検証
        response_time_ms = (end_time - start_time) * 1000
        assert response.status_code == 200  # 【確認内容】: HTTPステータスコード200 🔵
        assert response_time_ms < 100  # 【確認内容】: レスポンス時間が100ms未満 🔵


# ================================================================================
# カテゴリB: ヘルスチェックエンドポイント（GET /health）
# ================================================================================


@pytest.mark.asyncio
async def test_health_endpoint_returns_database_connected(test_client_with_db):
    """
    【テスト目的】: ヘルスチェックエンドポイントがデータベース接続を確認して正常に応答することを確認
    【テスト内容】: GET /healthがデータベース接続を確認し、成功時に正しいレスポンスを返すことを検証
    【期待される動作】: ステータスコード200、status=ok、database=connected、ai_providerを含むJSON
    🔵 testcases.md B-1（line 164-183）に基づく
    🔵 TASK-0029: AI プロバイダー確認機能を追加

    【テストシナリオ】:
    - Given: データベースが起動しており、接続可能な状態
    - When: GET /healthにアクセス
    - Then: HTTPステータスコード200、status=ok、database=connected、ai_provider、version、timestampを含むJSONレスポンス
    """
    # 【テストデータ準備】: HTTPクライアントを作成（テスト用データベースを使用）
    # 【初期条件設定】: システム稼働状況の確認、運用監視ツールからの定期ポーリングを想定
    # 🔵 testcases.md B-1（line 167-172）に基づく
    async with AsyncClient(
        transport=ASGITransport(app=test_client_with_db), base_url="http://test"
    ) as client:
        # 【実際の処理実行】: GET /healthにリクエストを送信
        # 【処理内容】: データベース接続確認とシステム稼働状況の把握
        response = await client.get("/health")

        # 【結果検証】: HTTPステータスコードが200であることを確認
        # 【期待値確認】: 正常に応答していることを検証
        assert response.status_code == 200  # 【確認内容】: HTTPステータスコード200 🔵

        # 【結果検証】: レスポンスボディが期待される形式であることを確認
        # 【期待値確認】: status, database, ai_provider, version, timestampフィールドを含むことを検証
        response_json = response.json()
        assert response_json["status"] == "ok"  # 【確認内容】: statusフィールドが"ok" 🔵
        assert (
            response_json["database"] == "connected"
        )  # 【確認内容】: databaseフィールドが"connected" 🔵
        assert "ai_provider" in response_json  # 【確認内容】: ai_providerフィールドが存在する 🔵
        assert response_json["ai_provider"] in [
            "anthropic",
            "openai",
            "none",
        ]  # 【確認内容】: ai_providerが有効な値 🔵
        assert response_json["version"] == "1.0.0"  # 【確認内容】: versionフィールドが"1.0.0" 🔵
        assert "timestamp" in response_json  # 【確認内容】: timestampフィールドが存在する 🔵


@pytest.mark.asyncio
async def test_health_endpoint_returns_iso8601_timestamp(test_client_with_db):
    """
    【テスト目的】: ヘルスチェックエンドポイントがISO 8601形式のタイムスタンプを返すことを確認
    【テスト内容】: timestampフィールドがISO 8601形式（YYYY-MM-DDTHH:MM:SSZ）であることを検証
    【期待される動作】: タイムスタンプが正しい形式で返される
    🔵 testcases.md B-2（line 185-196）に基づく

    【テストシナリオ】:
    - Given: FastAPIアプリケーションが起動している
    - When: GET /healthにアクセス
    - Then: timestampフィールドがISO 8601形式である
    """
    # 【テストデータ準備】: HTTPクライアントを作成（テスト用データベースを使用）
    # 【初期条件設定】: ヘルスチェック実行時刻の記録、ログ相関分析に使用
    # 🔵 testcases.md B-2（line 188-193）に基づく
    async with AsyncClient(
        transport=ASGITransport(app=test_client_with_db), base_url="http://test"
    ) as client:
        # 【実際の処理実行】: GET /healthにリクエストを送信
        # 【処理内容】: タイムスタンプの形式を確認
        response = await client.get("/health")

        # 【結果検証】: timestampフィールドがISO 8601形式であることを確認
        # 【期待値確認】: 国際標準形式での時刻表現を検証
        assert response.status_code == 200  # 【確認内容】: HTTPステータスコード200 🔵
        response_json = response.json()
        timestamp = response_json.get("timestamp")
        assert timestamp is not None  # 【確認内容】: timestampフィールドが存在する 🔵

        # 【ISO 8601形式検証】: timestampがISO 8601形式でパース可能であることを確認
        # 【期待値確認】: タイムゾーンUTC表記（Z）を含むことを検証
        try:
            parsed_time = datetime.fromisoformat(timestamp.replace("Z", "+00:00"))
            assert parsed_time is not None  # 【確認内容】: ISO 8601形式でパース可能 🔵
        except ValueError:
            pytest.fail(
                "Timestamp is not in ISO 8601 format"
            )  # 【エラー処理】: パース失敗時はテスト失敗 🔵


@pytest.mark.asyncio
async def test_health_endpoint_responds_within_1_second(test_client_with_db):
    """
    【テスト目的】: ヘルスチェックエンドポイントが1秒以内に応答することを確認
    【テスト内容】: パフォーマンス要件（NFR-002）を満たすことを検証
    【期待される動作】: 1秒以内にレスポンスが返される
    🔵 testcases.md B-3（line 198-209）に基づく

    【テストシナリオ】:
    - Given: FastAPIアプリケーションとデータベースが起動している
    - When: GET /healthにアクセスし、レスポンス時間を計測
    - Then: レスポンス時間が1秒以内である
    """
    # 【テストデータ準備】: HTTPクライアントと時間計測の準備
    # 【初期条件設定】: 軽量なSELECT 1クエリのみを実行するヘルスチェック
    # 🔵 testcases.md B-3（line 201-206）、NFR-002に基づく
    async with AsyncClient(
        transport=ASGITransport(app=test_client_with_db), base_url="http://test"
    ) as client:
        # 【実際の処理実行】: レスポンス時間を計測
        # 【処理内容】: パフォーマンス要件を満たすかを検証
        start_time = time.perf_counter()
        response = await client.get("/health")
        end_time = time.perf_counter()

        # 【結果検証】: レスポンス時間が1秒以内であることを確認
        # 【期待値確認】: NFR-002要件を満たすことを検証
        response_time_ms = (end_time - start_time) * 1000
        assert response.status_code == 200  # 【確認内容】: HTTPステータスコード200 🔵
        assert response_time_ms < 1000  # 【確認内容】: レスポンス時間が1000ms未満 🔵


@pytest.mark.asyncio
async def test_health_endpoint_returns_correct_version(test_client_with_db):
    """
    【テスト目的】: ヘルスチェックエンドポイントがversionフィールドを正しく返すことを確認
    【テスト内容】: versionフィールドが"1.0.0"であることを検証
    【期待される動作】: バージョン情報が正しく返される
    🔵 testcases.md B-4（line 211-222）に基づく

    【テストシナリオ】:
    - Given: FastAPIアプリケーションが起動している
    - When: GET /healthにアクセス
    - Then: versionフィールドが"1.0.0"である
    """
    # 【テストデータ準備】: HTTPクライアントを作成（テスト用データベースを使用）
    # 【初期条件設定】: APIバージョン情報の確認、デプロイ検証
    # 🔵 testcases.md B-4（line 214-219）に基づく
    async with AsyncClient(
        transport=ASGITransport(app=test_client_with_db), base_url="http://test"
    ) as client:
        # 【実際の処理実行】: GET /healthにリクエストを送信
        # 【処理内容】: バージョン情報の確認
        response = await client.get("/health")

        # 【結果検証】: versionフィールドが正しいことを確認
        # 【期待値確認】: main.py（line 3）のバージョン定義と一致することを検証
        assert response.status_code == 200  # 【確認内容】: HTTPステータスコード200 🔵
        response_json = response.json()
        assert response_json["version"] == "1.0.0"  # 【確認内容】: versionフィールドが"1.0.0" 🔵


@pytest.mark.asyncio
async def test_health_endpoint_database_connection_failure_returns_500():
    """
    【テスト目的】: データベース接続失敗時にヘルスチェックエンドポイントが500エラーを返すことを確認
    【テスト内容】: PostgreSQLが停止している、または接続できない状態での動作を検証
    【期待される動作】: HTTPステータスコード500、status=error、database=disconnectedを含むJSON
    🔵 testcases.md B-5（line 224-246）に基づく

    【テストシナリオ】:
    - Given: データベースが停止している、またはネットワーク障害がある状態
    - When: GET /healthにアクセス
    - Then: HTTPステータスコード500、エラー情報を含むJSONレスポンス
    """
    # 【テストデータ準備】: データベース接続失敗を模擬
    # 【初期条件設定】: データベースサーバーがダウンしている、ネットワーク障害を想定
    # 🔵 testcases.md B-5（line 227-232）、NFR-304に基づく

    # 【モックの作成】: データベース接続失敗をシミュレート
    # 【実装方針】: get_db依存性をオーバーライドし、接続エラーを発生させる
    # 🔵 testcases.md B-5（line 227-246）に基づく
    class MockFailingSession:
        """データベース接続失敗をシミュレートするモックセッション"""

        async def execute(self, *args, **kwargs):
            """executeメソッドでエラーを発生させる"""
            # 【エラー発生】: データベース接続エラーを発生させる
            # 【実装方針】: 実際のデータベースエラーを模擬
            # 🔵 NFR-304（データベースエラー発生時の適切なエラーハンドリング）に基づく
            raise Exception("Database connection timeout")

    async def mock_failing_db():
        """データベース接続失敗をシミュレートするモック"""
        yield MockFailingSession()

    # 【依存性オーバーライド】: get_db依存性をモックで置き換え
    # 【実装方針】: FastAPIの依存性注入をオーバーライドし、エラーを発生させる
    # 🟡 FastAPIの依存性オーバーライド機能を使用（妥当な推測）
    from app.db.session import get_db
    from app.main import app as test_app

    test_app.dependency_overrides[get_db] = mock_failing_db

    try:
        async with AsyncClient(
            transport=ASGITransport(app=test_app), base_url="http://test"
        ) as client:
            # 【実際の処理実行】: GET /healthにリクエストを送信（データベース接続失敗を想定）
            # 【処理内容】: データベース接続エラーを適切にハンドリングするかを検証
            response = await client.get("/health")

            # 【結果検証】: データベース接続失敗時の動作を確認
            # 【期待値確認】: 500エラーとエラー情報を返すことを検証
            assert response.status_code == 500  # 【確認内容】: HTTPステータスコード500 🔵
            response_json = response.json()
            assert "detail" in response_json  # 【確認内容】: detailフィールドが存在する 🔵
            detail = response_json["detail"]
            assert detail["status"] == "error"  # 【確認内容】: statusフィールドが"error" 🔵
            assert (
                detail["database"] == "disconnected"
            )  # 【確認内容】: databaseフィールドが"disconnected" 🔵
            assert "error" in detail  # 【確認内容】: errorフィールドが存在する 🔵
    finally:
        # 【テスト後処理】: 依存性オーバーライドをクリア
        # 【状態復元】: 次のテストに影響しないよう状態を復元
        test_app.dependency_overrides.clear()


@pytest.mark.asyncio
async def test_health_endpoint_handles_multiple_requests(test_client_with_db):
    """
    【テスト目的】: ヘルスチェックエンドポイントが同時アクセス（10リクエスト）に対応できることを確認
    【テスト内容】: 接続プール上限（pool_size=10）での動作を検証
    【期待される動作】: 全てのリクエストがエラーなく正常に応答する
    🔵 testcases.md B-10（line 326-339）に基づく

    【テストシナリオ】:
    - Given: FastAPIアプリケーションとデータベースが起動している
    - When: GET /healthを同時に10回実行
    - Then: 全てのリクエストがHTTPステータスコード200で応答する
    """
    # 【テストデータ準備】: HTTPクライアントを作成（テスト用データベースを使用）
    # 【初期条件設定】: 複数のFlutterアプリから同時にヘルスチェックを実行する状況を想定
    # 🔵 testcases.md B-10（line 329-333）、NFR-005に基づく
    async with AsyncClient(
        transport=ASGITransport(app=test_client_with_db), base_url="http://test"
    ) as client:
        # 【実際の処理実行】: 10個の同時リクエストを送信
        # 【処理内容】: 接続プールが適切に動作し、全リクエストに応答できるかを検証
        import asyncio

        tasks = [client.get("/health") for _ in range(10)]
        responses = await asyncio.gather(*tasks)

        # 【結果検証】: 全てのリクエストが正常に応答することを確認
        # 【期待値確認】: NFR-005要件（同時利用者数10人以下）を満たすことを検証
        for response in responses:
            assert (
                response.status_code == 200
            )  # 【確認内容】: 全リクエストがHTTPステータスコード200 🔵
            response_json = response.json()
            assert response_json["status"] == "ok"  # 【確認内容】: 全リクエストのstatusが"ok" 🔵


# ================================================================================
# カテゴリC: AI プロバイダー確認テスト（TASK-0029追加）
# ================================================================================


@pytest.mark.asyncio
async def test_health_endpoint_ai_provider_with_mock():
    """
    【テスト目的】: ヘルスチェックでAIプロバイダー情報が正しく返されることを確認
    【テスト内容】: モックを使用してAIプロバイダー確認機能を検証
    【期待される動作】: ai_providerフィールドが有効な値を持つ
    🔵 TASK-0029に基づく

    【テストシナリオ】:
    - Given: AIクライアントがモック化されている
    - When: GET /healthにアクセス
    - Then: ai_providerフィールドが有効な値を持つ
    """
    from unittest.mock import AsyncMock, MagicMock, patch

    # データベースセッションをモック
    mock_session = MagicMock()
    mock_session.execute = AsyncMock()

    async def mock_get_db():
        yield mock_session

    from app.db.session import get_db
    from app.main import app as test_app

    test_app.dependency_overrides[get_db] = mock_get_db

    try:
        # main.pyのget_ai_provider_status関数を直接モック
        with patch("app.main.get_ai_provider_status", return_value="anthropic"):
            async with AsyncClient(
                transport=ASGITransport(app=test_app), base_url="http://test"
            ) as client:
                response = await client.get("/health")

                # 【結果検証】: ai_providerフィールドが存在し、有効な値を持つ
                assert response.status_code == 200
                response_json = response.json()
                assert "ai_provider" in response_json
                assert response_json["ai_provider"] == "anthropic"
    finally:
        test_app.dependency_overrides.clear()


@pytest.mark.asyncio
async def test_health_endpoint_ai_provider_openai_with_mock():
    """
    【テスト目的】: OpenAIがプロバイダーとして認識されることを確認
    【テスト内容】: OpenAIが有効な場合の動作を検証
    【期待される動作】: ai_provider="openai"が返される
    🔵 TASK-0029に基づく
    """
    from unittest.mock import AsyncMock, MagicMock, patch

    mock_session = MagicMock()
    mock_session.execute = AsyncMock()

    async def mock_get_db():
        yield mock_session

    from app.db.session import get_db
    from app.main import app as test_app

    test_app.dependency_overrides[get_db] = mock_get_db

    try:
        with patch("app.main.get_ai_provider_status", return_value="openai"):
            async with AsyncClient(
                transport=ASGITransport(app=test_app), base_url="http://test"
            ) as client:
                response = await client.get("/health")

                assert response.status_code == 200
                response_json = response.json()
                assert response_json["ai_provider"] == "openai"
    finally:
        test_app.dependency_overrides.clear()


@pytest.mark.asyncio
async def test_health_endpoint_ai_provider_none_with_mock():
    """
    【テスト目的】: AIプロバイダーが未設定の場合に"none"が返されることを確認
    【テスト内容】: 両方のAIプロバイダーが無効な場合の動作を検証
    【期待される動作】: ai_provider="none"が返される
    🔵 TASK-0029に基づく
    """
    from unittest.mock import AsyncMock, MagicMock, patch

    mock_session = MagicMock()
    mock_session.execute = AsyncMock()

    async def mock_get_db():
        yield mock_session

    from app.db.session import get_db
    from app.main import app as test_app

    test_app.dependency_overrides[get_db] = mock_get_db

    try:
        with patch("app.main.get_ai_provider_status", return_value="none"):
            async with AsyncClient(
                transport=ASGITransport(app=test_app), base_url="http://test"
            ) as client:
                response = await client.get("/health")

                assert response.status_code == 200
                response_json = response.json()
                assert response_json["ai_provider"] == "none"
    finally:
        test_app.dependency_overrides.clear()
