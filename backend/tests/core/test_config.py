"""
app/core/config.py の Settings クラステスト

【テスト対象】: Settings.ENVIRONMENT のバリデーション
【目的】: "prod" 等の表記ゆれを起動時エラー（設定読み込み失敗）として拒否し、
          フェイルオープンな認証スキップ（app/api/deps.py）を防ぐことを確認する。
"""

import pytest
from pydantic import ValidationError

from app.core.config import Settings


class TestEnvironmentValidation:
    """ENVIRONMENT フィールドの値検証テスト"""

    @pytest.mark.parametrize("value", ["development", "test", "staging"])
    def test_accepts_known_environment_values(self, value: str):
        """development/test/staging は正常に受理される"""
        settings = Settings(ENVIRONMENT=value)
        assert settings.ENVIRONMENT == value

    def test_accepts_production_with_required_overrides(self):
        """
        production は SECRET_KEY / POSTGRES_PASSWORD を明示指定すれば受理される。

        （開発用デフォルト値のままだと別バリデータ validate_production_settings が
        エラーにするため、production 固有の要件を満たした上でテストする）
        """
        settings = Settings(
            ENVIRONMENT="production",
            SECRET_KEY="a-sufficiently-random-production-secret",  # noqa: S106
            POSTGRES_PASSWORD="a-sufficiently-random-production-password",  # noqa: S106
        )
        assert settings.ENVIRONMENT == "production"

    @pytest.mark.parametrize(
        "value",
        ["prod", "Production", "PROD", "stg", "dev", "Test", ""],
    )
    def test_rejects_unknown_environment_values(self, value: str):
        """表記ゆれ・未知の値は設定読み込み時にエラーとなり、アプリ起動が失敗する"""
        with pytest.raises(ValidationError):
            Settings(ENVIRONMENT=value)


class TestAIAndRateLimitDefaults:
    """AI呼び出し・レート制限まわりの既定値テスト。

    開発者ローカルの .env による上書きの影響を受けないよう、_env_file=None で
    純粋なクラス既定値を検証する。
    """

    def test_ai_api_timeout_default_is_8_seconds(self):
        """AI_API_TIMEOUT の既定値は8秒（フロントのconnect/receiveタイムアウトと整合）"""
        settings = Settings(_env_file=None)
        assert settings.AI_API_TIMEOUT == 8

    def test_ai_max_retries_default_is_1(self):
        """AI_MAX_RETRIES の既定値は1（接続エラー/429のみ最大1回再試行）"""
        settings = Settings(_env_file=None)
        assert settings.AI_MAX_RETRIES == 1

    def test_ai_call_deadline_seconds_default_is_10(self):
        """AI_CALL_DEADLINE_SECONDS の既定値は10秒（フロントの10秒タイムアウトと整合）"""
        settings = Settings(_env_file=None)
        assert settings.AI_CALL_DEADLINE_SECONDS == 10.0

    def test_rate_limit_storage_uri_default_is_empty(self):
        """RATE_LIMIT_STORAGE_URI の既定値は空文字列（インメモリストレージ）"""
        settings = Settings(_env_file=None)
        assert settings.RATE_LIMIT_STORAGE_URI == ""

    def test_rate_limit_storage_uri_can_be_overridden(self):
        """RATE_LIMIT_STORAGE_URIは明示指定した値で上書きできる（例: Redis URI）"""
        settings = Settings(_env_file=None, RATE_LIMIT_STORAGE_URI="redis://localhost:6379")
        assert settings.RATE_LIMIT_STORAGE_URI == "redis://localhost:6379"
