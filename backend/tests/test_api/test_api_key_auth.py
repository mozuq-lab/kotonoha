"""
端末APIキー認証テスト

AI変換エンドポイント（/convert, /regenerate）の端末APIキー認証を検証する。

【テストファイル目的】: 無認証・無制限の外部AI API課金消費を防ぐ認証の動作確認
【背景】: MVPはアカウント管理を持たないため、端末発行の共有シークレットで保護する
"""

from unittest.mock import AsyncMock, patch

import pytest
from httpx import ASGITransport, AsyncClient

from app.core.config import settings
from app.core.rate_limit import limiter
from app.main import app

VALID_KEY = "device-key-valid-001"
OTHER_VALID_KEY = "device-key-valid-002"


@pytest.fixture(autouse=True)
def reset_limiter():
    """各テスト前後でレート制限をリセット（認証検証をレート制限と分離）"""
    limiter.reset()
    yield
    limiter.reset()


@pytest.fixture
def mock_ai_client():
    """AIクライアントとログ記録をモック"""
    with (
        patch("app.utils.ai_client.ai_client") as mock_client,
        patch("app.api.v1.endpoints.ai.create_conversion_log", new_callable=AsyncMock),
    ):
        mock_client.convert_text = AsyncMock(return_value=("変換済み", 1000))
        mock_client.regenerate_text = AsyncMock(return_value=("再変換済み", 1000))
        yield mock_client


@pytest.fixture
def api_keys_configured(monkeypatch):
    """APIキーを設定した状態（カンマ区切りで複数キー）"""
    monkeypatch.setattr(settings, "API_KEYS", f"{VALID_KEY},{OTHER_VALID_KEY}")
    yield


CONVERT_BODY = {"input_text": "水 ぬるく", "politeness_level": "normal"}
REGENERATE_BODY = {
    "input_text": "水 ぬるく",
    "politeness_level": "normal",
    "previous_result": "前回の結果",
}


class TestAPIKeyEnforced:
    """APIキー設定時の認証強制"""

    @pytest.mark.asyncio
    async def test_convert_without_key_returns_401(self, mock_ai_client, api_keys_configured):
        """APIキー設定時、ヘッダーなしのconvertは401で拒否される"""
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            response = await client.post("/api/v1/ai/convert", json=CONVERT_BODY)
        assert response.status_code == 401
        # AIクライアントは呼ばれない（課金が発生しない）
        mock_ai_client.convert_text.assert_not_called()

    @pytest.mark.asyncio
    async def test_convert_with_invalid_key_returns_401(self, mock_ai_client, api_keys_configured):
        """APIキー設定時、不正なキーのconvertは401で拒否される"""
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            response = await client.post(
                "/api/v1/ai/convert",
                json=CONVERT_BODY,
                headers={"X-API-Key": "wrong-key"},
            )
        assert response.status_code == 401
        mock_ai_client.convert_text.assert_not_called()

    @pytest.mark.asyncio
    async def test_convert_with_valid_key_returns_200(self, mock_ai_client, api_keys_configured):
        """APIキー設定時、有効なキーのconvertは成功する"""
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            response = await client.post(
                "/api/v1/ai/convert",
                json=CONVERT_BODY,
                headers={"X-API-Key": VALID_KEY},
            )
        assert response.status_code == 200
        mock_ai_client.convert_text.assert_called_once()

    @pytest.mark.asyncio
    async def test_convert_accepts_any_configured_key(self, mock_ai_client, api_keys_configured):
        """複数設定されたキーのいずれでも認証が通る"""
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            response = await client.post(
                "/api/v1/ai/convert",
                json=CONVERT_BODY,
                headers={"X-API-Key": OTHER_VALID_KEY},
            )
        assert response.status_code == 200

    @pytest.mark.asyncio
    async def test_regenerate_without_key_returns_401(self, mock_ai_client, api_keys_configured):
        """APIキー設定時、ヘッダーなしのregenerateは401で拒否される"""
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            response = await client.post("/api/v1/ai/regenerate", json=REGENERATE_BODY)
        assert response.status_code == 401
        mock_ai_client.regenerate_text.assert_not_called()

    @pytest.mark.asyncio
    async def test_regenerate_with_valid_key_returns_200(self, mock_ai_client, api_keys_configured):
        """APIキー設定時、有効なキーのregenerateは成功する"""
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            response = await client.post(
                "/api/v1/ai/regenerate",
                json=REGENERATE_BODY,
                headers={"X-API-Key": VALID_KEY},
            )
        assert response.status_code == 200


class TestAPIKeyNotConfigured:
    """APIキー未設定時のフォールバック挙動（環境依存・allowlist方式）"""

    @pytest.mark.asyncio
    async def test_skips_auth_in_test_environment(self, mock_ai_client, monkeypatch):
        """allowlist対象（test環境）でAPIキー未設定なら認証はスキップされる"""
        monkeypatch.setattr(settings, "API_KEYS", "")
        monkeypatch.setattr(settings, "ENVIRONMENT", "test")
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            response = await client.post("/api/v1/ai/convert", json=CONVERT_BODY)
        assert response.status_code == 200

    @pytest.mark.asyncio
    async def test_skips_auth_in_development_environment(self, mock_ai_client, monkeypatch):
        """allowlist対象（development環境）でAPIキー未設定なら認証はスキップされる"""
        monkeypatch.setattr(settings, "API_KEYS", "")
        monkeypatch.setattr(settings, "ENVIRONMENT", "development")
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            response = await client.post("/api/v1/ai/convert", json=CONVERT_BODY)
        assert response.status_code == 200

    @pytest.mark.asyncio
    async def test_rejects_in_production_when_not_configured(self, mock_ai_client, monkeypatch):
        """本番でAPIキー未設定なら全リクエストを503で拒否（フェイルクローズ）"""
        monkeypatch.setattr(settings, "API_KEYS", "")
        monkeypatch.setattr(settings, "ENVIRONMENT", "production")
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            response = await client.post("/api/v1/ai/convert", json=CONVERT_BODY)
        assert response.status_code == 503
        mock_ai_client.convert_text.assert_not_called()

    @pytest.mark.asyncio
    async def test_rejects_in_staging_when_not_configured(self, mock_ai_client, monkeypatch):
        """staging（allowlist対象外）でAPIキー未設定なら全リクエストを503で拒否（フェイルクローズ）"""
        monkeypatch.setattr(settings, "API_KEYS", "")
        monkeypatch.setattr(settings, "ENVIRONMENT", "staging")
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            response = await client.post("/api/v1/ai/convert", json=CONVERT_BODY)
        assert response.status_code == 503
        mock_ai_client.convert_text.assert_not_called()

    @pytest.mark.asyncio
    async def test_accepts_valid_key_in_staging(self, mock_ai_client, monkeypatch):
        """stagingでAPIキーが設定済みなら、正しいキーで200になる"""
        monkeypatch.setattr(settings, "API_KEYS", VALID_KEY)
        monkeypatch.setattr(settings, "ENVIRONMENT", "staging")
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            response = await client.post(
                "/api/v1/ai/convert",
                json=CONVERT_BODY,
                headers={"X-API-Key": VALID_KEY},
            )
        assert response.status_code == 200
        mock_ai_client.convert_text.assert_called_once()

    @pytest.mark.asyncio
    async def test_non_ascii_key_returns_401_not_500(self, mock_ai_client, api_keys_configured):
        """非ASCII文字を含むAPIキーは500ではなく401で拒否される"""
        # httpxはstrヘッダー値をASCIIとして扱い非ASCII文字を拒否するため、
        # 実際のHTTPクライアントが送信しうる生のUTF-8バイト列として明示的に渡す。
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            response = await client.post(
                "/api/v1/ai/convert",
                json=CONVERT_BODY,
                headers={"X-API-Key": "日本語キー不正".encode()},
            )
        assert response.status_code == 401
        mock_ai_client.convert_text.assert_not_called()
