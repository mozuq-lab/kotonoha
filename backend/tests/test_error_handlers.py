"""
グローバルエラーハンドラーテスト

【ファイル目的】: グローバルエラーハンドラーの動作をテスト
【ファイル内容】: バリデーションエラー、データベースエラー、グローバル例外ハンドラーのテスト

TASK-0031: グローバルエラーハンドラー・例外処理実装
🔵 NFR-301（基本機能継続利用）、NFR-304（データベースエラーハンドリング）に基づく
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
async def test_validation_error_handler_empty_input():
    """
    【テスト目的】: バリデーションエラーハンドラーのテスト（空入力）
    【テスト内容】: 空のinput_textを送信した場合のエラーレスポンスを確認
    【期待される動作】: 422エラーと統一フォーマットのレスポンスを返す
    🔵 TASK-0031に基づくテスト
    """
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post(
            "/api/v1/ai/convert",
            json={
                "input_text": "",
                "politeness_level": "polite",
            },
        )

        assert response.status_code == 422
        data = response.json()
        assert "error" in data
        assert data["error_code"] == "VALIDATION_ERROR"


@pytest.mark.asyncio
async def test_validation_error_handler_invalid_politeness():
    """
    【テスト目的】: バリデーションエラーハンドラーのテスト（不正な丁寧さレベル）
    【テスト内容】: 無効なpoliteness_levelを送信した場合のエラーレスポンスを確認
    【期待される動作】: 422エラーと統一フォーマットのレスポンスを返す
    🔵 TASK-0031に基づくテスト
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

        assert response.status_code == 422
        data = response.json()
        assert "error" in data
        assert data["error_code"] == "VALIDATION_ERROR"


@pytest.mark.asyncio
async def test_validation_error_handler_missing_field():
    """
    【テスト目的】: バリデーションエラーハンドラーのテスト（必須フィールド欠落）
    【テスト内容】: 必須フィールドが欠落している場合のエラーレスポンスを確認
    【期待される動作】: 422エラーと統一フォーマットのレスポンスを返す
    🔵 TASK-0031に基づくテスト
    """
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post(
            "/api/v1/ai/convert",
            json={
                "politeness_level": "polite",
                # input_text を省略
            },
        )

        assert response.status_code == 422
        data = response.json()
        assert "error" in data
        assert data["error_code"] == "VALIDATION_ERROR"


@pytest.mark.asyncio
async def test_validation_error_handler_invalid_json():
    """
    【テスト目的】: バリデーションエラーハンドラーのテスト（不正なJSON）
    【テスト内容】: 不正な形式のJSONを送信した場合のエラーレスポンスを確認
    【期待される動作】: 422エラーと統一フォーマットのレスポンスを返す
    🔵 TASK-0031に基づくテスト
    """
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post(
            "/api/v1/ai/convert",
            content="invalid json",
            headers={"Content-Type": "application/json"},
        )

        assert response.status_code == 422
        data = response.json()
        assert "error" in data
        assert data["error_code"] == "VALIDATION_ERROR"


@pytest.mark.asyncio
async def test_log_error_to_db_function():
    """
    【テスト目的】: エラーログのデータベース保存機能テスト
    【テスト内容】: log_error_to_db関数が正しくエラーログを保存することを確認
    【期待される動作】: エラーログがデータベースに保存される
    🔵 TASK-0031に基づくテスト
    """
    from app.core.exceptions import log_error_to_db

    # モックセッションを使用してデータベース保存をテスト
    with patch("app.core.exceptions.async_session_maker") as mock_session_maker:
        mock_session = AsyncMock()
        mock_session_maker.return_value.__aenter__.return_value = mock_session

        await log_error_to_db(
            error_type="TestError",
            error_message="This is a test error",
            error_code="TEST_001",
            endpoint="/api/v1/test",
            http_method="POST",
            stack_trace="Test stack trace",
        )

        # セッションにaddが呼ばれたことを確認
        mock_session.add.assert_called_once()
        mock_session.commit.assert_called_once()


@pytest.mark.asyncio
async def test_log_error_to_db_handles_failure():
    """
    【テスト目的】: エラーログ保存失敗時のハンドリングテスト
    【テスト内容】: エラーログ保存が失敗しても例外が伝播しないことを確認
    【期待される動作】: 例外が抑制され、エラーログが出力される
    🔵 TASK-0031に基づくテスト
    """
    from app.core.exceptions import log_error_to_db

    # データベース保存が失敗するようにモック
    with patch("app.core.exceptions.async_session_maker") as mock_session_maker:
        mock_session_maker.return_value.__aenter__.side_effect = Exception("DB Error")

        # 例外が伝播せずに完了することを確認
        await log_error_to_db(
            error_type="TestError",
            error_message="This is a test error",
            error_code="TEST_001",
            endpoint="/api/v1/test",
            http_method="POST",
        )
        # 例外が発生しなければテスト成功


@pytest.mark.asyncio
async def test_global_exception_handler_response_format():
    """
    【テスト目的】: グローバル例外ハンドラーのレスポンス形式テスト
    【テスト内容】: 予期しない例外発生時のレスポンス形式を確認
    【期待される動作】: 500エラーと統一フォーマットのレスポンスを返す
    🔵 TASK-0031に基づくテスト
    """
    from unittest.mock import MagicMock

    from app.core.exceptions import global_exception_handler

    # モックリクエストを作成
    mock_request = MagicMock()
    mock_request.url.path = "/api/v1/test"
    mock_request.method = "POST"

    # エラーログ保存をモック
    with patch("app.core.exceptions.log_error_to_db", new_callable=AsyncMock):
        response = await global_exception_handler(mock_request, Exception("Test exception"))

        assert response.status_code == 500
        import json

        data = json.loads(response.body)
        assert data["error_code"] == "INTERNAL_ERROR"
        assert "error" in data


@pytest.mark.asyncio
async def test_database_exception_handler_response_format():
    """
    【テスト目的】: データベース例外ハンドラーのレスポンス形式テスト
    【テスト内容】: データベースエラー発生時のレスポンス形式を確認
    【期待される動作】: 503エラーと統一フォーマットのレスポンスを返す
    🔵 TASK-0031に基づくテスト
    """
    from unittest.mock import MagicMock

    from sqlalchemy.exc import SQLAlchemyError

    from app.core.exceptions import database_exception_handler

    # モックリクエストを作成
    mock_request = MagicMock()
    mock_request.url.path = "/api/v1/test"
    mock_request.method = "GET"

    # エラーログ保存をモック
    with patch("app.core.exceptions.log_error_to_db", new_callable=AsyncMock):
        response = await database_exception_handler(
            mock_request, SQLAlchemyError("Test database error")
        )

        assert response.status_code == 503
        import json

        data = json.loads(response.body)
        assert data["error_code"] == "DATABASE_ERROR"
        assert "error" in data


@pytest.mark.asyncio
async def test_validation_exception_handler_response_format():
    """
    【テスト目的】: バリデーション例外ハンドラーのレスポンス形式テスト
    【テスト内容】: バリデーションエラー発生時のレスポンス形式を確認
    【期待される動作】: 422エラーと統一フォーマットのレスポンスを返す
    🔵 TASK-0031に基づくテスト
    """
    from unittest.mock import MagicMock

    from fastapi.exceptions import RequestValidationError

    from app.core.exceptions import validation_exception_handler

    # モックリクエストを作成
    mock_request = MagicMock()
    mock_request.url.path = "/api/v1/test"

    # RequestValidationErrorを作成
    validation_error = RequestValidationError(
        errors=[{"loc": ["body", "input_text"], "msg": "field required", "type": "missing"}]
    )

    response = await validation_exception_handler(mock_request, validation_error)

    assert response.status_code == 422
    import json

    data = json.loads(response.body)
    assert data["error_code"] == "VALIDATION_ERROR"
    assert "error" in data
    assert "detail" in data
