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
