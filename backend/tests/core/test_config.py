"""
app/core/config.py の Settings クラステスト

【テスト対象】: Settings のバリデーション、既定値、production固有の必須設定、削除済みキーの移行措置
【目的】: 設定ミス・設定漏れを起動時エラー（設定読み込み失敗）として拒否することを確認する。
          - "prod" 等の表記ゆれ → フェイルオープンな認証スキップ（app/api/deps.py）を防ぐ
          - production での必須設定漏れ → 本番で気付かないまま稼働することを防ぐ
"""

import logging

import pytest
from pydantic import ValidationError

from app.core.config import (
    _REMOVED_SETTINGS,
    DEV_POSTGRES_PASSWORD,
    DEV_SECRET_KEY,
    Settings,
)


def _production_settings(**overrides) -> dict:
    """production 環境として受理される最小構成の設定値を返す。

    validate_production_settings が要求する項目（開発用デフォルトのままでは
    起動できない項目）をすべて満たした辞書を返す。個別の必須項目を検証する
    テストは、この辞書から該当キーを外して「起動が失敗すること」を確認する。

    Args:
        **overrides: 上書きしたい設定値。

    Returns:
        dict: Settings に渡すキーワード引数。
    """
    base = {
        "_env_file": None,
        "ENVIRONMENT": "production",
        "SECRET_KEY": "a-sufficiently-random-production-secret",
        "POSTGRES_PASSWORD": "a-sufficiently-random-production-password",
        "RATE_LIMIT_STORAGE_URI": "redis://localhost:6379",
    }
    base.update(overrides)
    return base


class TestEnvironmentValidation:
    """ENVIRONMENT フィールドの値検証テスト"""

    @pytest.mark.parametrize("value", ["development", "test", "staging"])
    def test_accepts_known_environment_values(self, value: str):
        """development/test/staging は正常に受理される"""
        settings = Settings(ENVIRONMENT=value)
        assert settings.ENVIRONMENT == value

    def test_accepts_production_with_required_overrides(self):
        """
        production は必須設定を明示指定すれば受理される。

        （開発用デフォルト値のままだと別バリデータ validate_production_settings が
        エラーにするため、production 固有の要件を満たした上でテストする）
        """
        settings = Settings(**_production_settings())
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


class TestProductionSettingsValidation:
    """validate_production_settings（production固有の必須設定）のテスト。

    production で設定漏れがあった場合は「警告」ではなく「起動失敗」になることを検証する。
    警告ログはデプロイ時に見落とされ、設定漏れのまま稼働してしまうため。
    """

    def test_rejects_production_without_rate_limit_storage_uri(self):
        """
        production で RATE_LIMIT_STORAGE_URI 未設定なら起動時エラーになる。

        未設定＝プロセス内メモリのカウンタとなり、マルチワーカー/マルチインスタンス
        構成では実効レート制限が「設定値 × プロセス数」まで緩む（NFR-101違反）。
        """
        settings_kwargs = _production_settings(RATE_LIMIT_STORAGE_URI="")

        with pytest.raises(ValidationError, match="RATE_LIMIT_STORAGE_URI"):
            Settings(**settings_kwargs)

    def test_accepts_explicit_memory_storage_uri_in_production(self):
        """
        単一プロセス運用で意図的にインメモリを使う場合は "memory://" の明示で受理される。

        「未設定（暗黙のインメモリ）」と「意図してインメモリを選んだ」を区別できるようにする。
        """
        settings = Settings(**_production_settings(RATE_LIMIT_STORAGE_URI="memory://"))
        assert settings.RATE_LIMIT_STORAGE_URI == "memory://"

    def test_rejects_production_with_dev_secret_key(self):
        """production で SECRET_KEY が開発用デフォルトのままなら起動時エラーになる"""
        with pytest.raises(ValidationError, match="SECRET_KEY"):
            Settings(**_production_settings(SECRET_KEY=DEV_SECRET_KEY))

    def test_rejects_production_with_dev_postgres_password(self):
        """production で POSTGRES_PASSWORD が開発用デフォルトのままなら起動時エラーになる"""
        with pytest.raises(ValidationError, match="POSTGRES_PASSWORD"):
            Settings(**_production_settings(POSTGRES_PASSWORD=DEV_POSTGRES_PASSWORD))

    @pytest.mark.parametrize("environment", ["development", "test", "staging"])
    def test_does_not_require_rate_limit_storage_uri_outside_production(self, environment: str):
        """production 以外では RATE_LIMIT_STORAGE_URI 未設定でも起動できる（開発体験を損なわない）"""
        settings = Settings(_env_file=None, ENVIRONMENT=environment, RATE_LIMIT_STORAGE_URI="")
        assert settings.RATE_LIMIT_STORAGE_URI == ""


class TestRemovedSettingsMigration:
    """削除済み設定キーの移行措置テスト。

    pydantic-settings は extra="forbid" が既定のため、フィールドを削除すると
    各開発者の backend/.env に残った古いキーで起動不能になる。既知の削除済みキー
    （_REMOVED_SETTINGS）だけは読み捨て、それ以外の未知キーは従来どおり
    起動時エラーにする、という切り分けを検証する。
    """

    def test_removed_key_in_env_file_does_not_break_startup(self, tmp_path, caplog):
        """.env に削除済みキーが残っていても起動でき、警告ログが出る"""
        env_file = tmp_path / ".env"
        env_file.write_text(
            "ACCESS_TOKEN_EXPIRE_MINUTES=11520\nPOSTGRES_USER=kotonoha_user\n",
            encoding="utf-8",
        )

        with caplog.at_level(logging.WARNING, logger="app.core.config"):
            settings = Settings(_env_file=env_file)

        assert settings.POSTGRES_USER == "kotonoha_user"
        assert not hasattr(settings, "ACCESS_TOKEN_EXPIRE_MINUTES")
        assert "ACCESS_TOKEN_EXPIRE_MINUTES" in caplog.text
        assert "backend/.env" in caplog.text

    def test_removed_key_is_ignored_not_applied(self):
        """削除済みキーは読み捨てられるだけで、他の設定値には影響しない"""
        settings = Settings(_env_file=None, ACCESS_TOKEN_EXPIRE_MINUTES=11520)
        assert settings.RATE_LIMIT_TIMES == 1
        assert settings.RATE_LIMIT_SECONDS == 10

    def test_unknown_key_is_still_rejected(self):
        """未知キー（タイポ）は従来どおり起動時エラー

        RATE_LIMIT_SECOND（末尾のSが無い）のようなタイポを黙って無視すると、
        レート制限が意図せず既定値で動いてしまう。extra="ignore" に緩めず、
        削除済みと分かっているキーだけを例外扱いしていることを保証する。
        """
        with pytest.raises(ValidationError, match="RATE_LIMIT_SECOND"):
            Settings(_env_file=None, RATE_LIMIT_SECOND=10)

    def test_removed_settings_table_documents_reasons(self):
        """_REMOVED_SETTINGS の各エントリには削除理由が書かれている"""
        assert _REMOVED_SETTINGS
        for key, reason in _REMOVED_SETTINGS.items():
            assert key.isupper(), f"{key} は環境変数名（大文字）であるべき"
            assert reason.strip(), f"{key} に削除理由が書かれていない"
