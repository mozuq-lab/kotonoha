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
    ProductionSettingsError,
    Settings,
    validate_production_settings,
)


def _production_settings(**overrides) -> dict:
    """production 環境として受理される最小構成の設定値を返す。

    validate_production_settings が要求する項目（開発用デフォルトのままでは
    起動できない項目）をすべて満たした辞書を返す。個別の必須項目を検証する
    テストは、この辞書の該当キーを不正な値にして「検証が失敗すること」を確認する。

    Args:
        **overrides: 上書きしたい設定値。

    Returns:
        dict: Settings に渡すキーワード引数。
    """
    base = {
        "_env_file": None,
        "ENVIRONMENT": "production",
        "POSTGRES_PASSWORD": "a-sufficiently-random-production-password",
        "RATE_LIMIT_STORAGE_URI": "redis://localhost:6379",
        "API_KEYS": "a-production-device-key",
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

        （開発用デフォルト値のままだと validate_production_settings がエラーに
        するため、production 固有の要件を満たした上でテストする）
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

    【検証のタイミング】: この検査は Settings() の生成時ではなく、APIアプリの
    エントリーポイント（app/main.py）が明示的に呼ぶ。app.core.config を import する
    だけのプロセス（alembic 等）を巻き添えにしないため。
    """

    def test_rejects_production_without_rate_limit_storage_uri(self):
        """
        production で RATE_LIMIT_STORAGE_URI 未設定なら起動時エラーになる。

        未設定＝プロセス内メモリのカウンタとなり、マルチワーカー/マルチインスタンス
        構成では実効レート制限が「設定値 × プロセス数」まで緩む（NFR-101違反）。
        """
        settings = Settings(**_production_settings(RATE_LIMIT_STORAGE_URI=""))

        with pytest.raises(ProductionSettingsError, match="RATE_LIMIT_STORAGE_URI"):
            validate_production_settings(settings)

    def test_accepts_explicit_memory_storage_uri_in_production(self):
        """
        単一プロセス運用で意図的にインメモリを使う場合は "memory://" の明示で受理される。

        「未設定（暗黙のインメモリ）」と「意図してインメモリを選んだ」を区別できるようにする。
        """
        settings = Settings(**_production_settings(RATE_LIMIT_STORAGE_URI="memory://"))
        validate_production_settings(settings)
        assert settings.RATE_LIMIT_STORAGE_URI == "memory://"

    def test_rejects_production_with_dev_postgres_password(self):
        """production で POSTGRES_PASSWORD が開発用デフォルトのままなら起動時エラーになる"""
        settings = Settings(**_production_settings(POSTGRES_PASSWORD=DEV_POSTGRES_PASSWORD))

        with pytest.raises(ProductionSettingsError, match="POSTGRES_PASSWORD"):
            validate_production_settings(settings)

    def test_rejects_production_without_api_keys(self):
        """production で API_KEYS 未設定なら起動時エラーになる

        未設定でも起動はできてしまうが、require_api_key が development / test 以外では
        全リクエストを 503 で拒否するため、AI変換が全滅した状態で稼働してしまう。
        設定漏れは本番トラフィックを受ける前に検出する。
        """
        settings = Settings(**_production_settings(API_KEYS=""))

        with pytest.raises(ProductionSettingsError, match="API_KEYS"):
            validate_production_settings(settings)

    def test_rejects_production_with_only_blank_api_keys(self):
        """カンマ区切りの中身が空白だけの場合も未設定として扱う"""
        settings = Settings(**_production_settings(API_KEYS="  ,  , "))

        with pytest.raises(ProductionSettingsError, match="API_KEYS"):
            validate_production_settings(settings)

    def test_warns_but_starts_when_trusted_proxy_count_is_zero(self, caplog):
        """TRUSTED_PROXY_COUNT=0 は起動を止めないが警告を出す

        0 は「ALB等を挟まない直接公開」という正当な構成でもあるため起動失敗にはしない。
        ただしリバースプロキシ配下で 0 のままだと全リクエストがプロキシの接続元IPに
        収束し、レート制限が全ユーザー共有＝実質的なサービス停止になる。
        """
        settings = Settings(**_production_settings(TRUSTED_PROXY_COUNT=0))

        with caplog.at_level(logging.WARNING, logger="app.core.config"):
            validate_production_settings(settings)

        assert "TRUSTED_PROXY_COUNT" in caplog.text

    def test_does_not_warn_when_trusted_proxy_count_is_configured(self, caplog):
        """TRUSTED_PROXY_COUNT が明示されていれば警告は出ない"""
        settings = Settings(**_production_settings(TRUSTED_PROXY_COUNT=1))

        with caplog.at_level(logging.WARNING, logger="app.core.config"):
            validate_production_settings(settings)

        assert "TRUSTED_PROXY_COUNT" not in caplog.text

    @pytest.mark.parametrize("environment", ["development", "test", "staging"])
    def test_does_not_require_rate_limit_storage_uri_outside_production(self, environment: str):
        """production 以外では RATE_LIMIT_STORAGE_URI 未設定でも起動できる（開発体験を損なわない）"""
        settings = Settings(_env_file=None, ENVIRONMENT=environment, RATE_LIMIT_STORAGE_URI="")

        validate_production_settings(settings)

        assert settings.RATE_LIMIT_STORAGE_URI == ""

    @pytest.mark.parametrize(
        "overrides",
        [
            {"RATE_LIMIT_STORAGE_URI": ""},
            {"POSTGRES_PASSWORD": DEV_POSTGRES_PASSWORD},
        ],
        ids=["missing_storage_uri", "dev_postgres_password"],
    )
    def test_error_message_does_not_leak_secret_values(self, overrides: dict):
        """
        設定漏れの例外メッセージに実際のシークレットが含まれないこと。

        【この回帰テストの理由】: 以前はこの検査を @model_validator の中で行っていたため、
        pydantic が ValidationError に包む際に「統合済みの設定辞書」の repr を
        メッセージへ埋め込み、ANTHROPIC_API_KEY 等が平文で stderr / コンテナログに
        出力されていた。本番の設定漏れは実物のシークレットが読み込まれている状況で
        起きるため、例外メッセージには設定値を一切含めない。
        """
        secrets = {
            "ANTHROPIC_API_KEY": "sk-ant-do-not-leak-this-value",
            "OPENAI_API_KEY": "sk-openai-do-not-leak-this-value",
            "API_KEYS": "device-key-do-not-leak-this-value",
        }
        settings = Settings(**_production_settings(**secrets, **overrides))

        with pytest.raises(ProductionSettingsError) as exc_info:
            validate_production_settings(settings)

        message = str(exc_info.value)
        for secret_value in secrets.values():
            assert secret_value not in message
        # 開発用デフォルト値を検出する経路でも、実パスワードは漏らさない
        assert settings.POSTGRES_PASSWORD not in message


class TestSettingsImportDoesNotValidateProduction:
    """Settings の生成そのものは production 固有の検査を行わないことのテスト。

    【この回帰テストの理由】: 検査を @model_validator に置くと、app.core.config を
    import するだけで例外になる。alembic/env.py は settings を無条件に import し、
    Dockerfile は alembic/ を本番イメージに含めるため、レート制限と無関係な
    `alembic upgrade head` が RATE_LIMIT_STORAGE_URI 未設定で実行不能になっていた。
    """

    def test_production_settings_can_be_constructed_without_rate_limit_storage_uri(self):
        """production でも Settings() の生成自体は成功する（＝マイグレーションは実行できる）"""
        settings = Settings(**_production_settings(RATE_LIMIT_STORAGE_URI=""))

        assert settings.ENVIRONMENT == "production"
        assert settings.RATE_LIMIT_STORAGE_URI == ""

    def test_production_settings_can_be_constructed_with_dev_defaults(self):
        """開発用デフォルトのままでも Settings() の生成自体は成功する"""
        settings = Settings(
            _env_file=None,
            ENVIRONMENT="production",
            POSTGRES_PASSWORD=DEV_POSTGRES_PASSWORD,
        )

        assert settings.POSTGRES_PASSWORD == DEV_POSTGRES_PASSWORD


class TestRemovedSettingsMigration:
    """削除済み設定キーの移行措置テスト。

    pydantic-settings は extra="forbid" が既定のため、フィールドを削除すると
    各開発者の backend/.env に残った古いキーで起動不能になる。既知の削除済みキー
    （_REMOVED_SETTINGS）だけは読み捨て、それ以外の未知キーは従来どおり
    起動時エラーにする、という切り分けを検証する。
    """

    def test_removed_key_in_env_file_does_not_break_startup(self, tmp_path, caplog, monkeypatch):
        """.env に削除済みキーが残っていても起動でき、警告ログが出る

        【POSTGRES_USER を環境変数から外す理由】: pydantic-settings の優先順位は
        init引数 > 環境変数 > .envファイル であり、CI（.github/workflows/python.yml）は
        POSTGRES_USER を環境変数として渡している。外さないと .env の値が必ず負け、
        「.envが実際に読まれたこと」を確認できないままCIでのみ失敗する。
        """
        monkeypatch.delenv("POSTGRES_USER", raising=False)
        env_file = tmp_path / ".env"
        # 【値が "kotonoha_user" ではない理由】: それは POSTGRES_USER の既定値でもあるため、
        # dotenv の読み込みが完全に壊れてもアサーションが通ってしまう。
        # 既定値からは絶対に出てこない値を使い、.env が実際に読まれたことを保証する。
        env_file.write_text(
            "ACCESS_TOKEN_EXPIRE_MINUTES=11520\nPOSTGRES_USER=dotenv_only_user\n",
            encoding="utf-8",
        )

        with caplog.at_level(logging.WARNING, logger="app.core.config"):
            settings = Settings(_env_file=env_file)

        assert settings.POSTGRES_USER == "dotenv_only_user"
        assert not hasattr(settings, "ACCESS_TOKEN_EXPIRE_MINUTES")
        assert "ACCESS_TOKEN_EXPIRE_MINUTES" in caplog.text
        assert "backend/.env" in caplog.text

    def test_removed_key_is_ignored_not_applied(self):
        """削除済みキーを渡しても、他の設定値は渡した値のまま影響を受けない

        削除済みキーの読み捨ては drop_removed_settings が入力辞書から該当キーを
        取り除くことで行われる。取り除き方が壊れて他のキーまで落ちると、
        明示的に渡した値が既定値へ戻ってしまうため、init引数で固定した値が
        そのまま残ることを確認する（環境変数の影響を受けないよう明示指定する）。
        """
        settings = Settings(
            _env_file=None,
            ACCESS_TOKEN_EXPIRE_MINUTES=11520,
            RATE_LIMIT_TIMES=5,
            RATE_LIMIT_SECONDS=60,
        )
        assert settings.RATE_LIMIT_TIMES == 5
        assert settings.RATE_LIMIT_SECONDS == 60

    def test_secret_key_is_read_and_discarded(self):
        """廃止した SECRET_KEY が .env に残っていても起動でき、フィールドにもならない

        JWT実装の削除により署名用途が無くなり消費者がゼロになったため設定ごと廃止した。
        既存の backend/.env や env ファイル方式のデプロイには残っているので、
        ACCESS_TOKEN_EXPIRE_MINUTES と同じく読み捨てて警告する。
        """
        # S106: 削除済みキーが読み捨てられることの確認用ダミー値（秘密ではない）
        settings = Settings(_env_file=None, SECRET_KEY="left-over-value")  # noqa: S106

        assert not hasattr(settings, "SECRET_KEY")

    def test_removed_key_from_os_environment_is_warned(self, monkeypatch, caplog):
        """OS環境変数で渡された削除済みキーにも警告が出る

        【この経路が本命である理由】: 削除前の SECRET_KEY は docker-compose が
        `SECRET_KEY: ${SECRET_KEY:?...}` として **OS環境変数**で渡しており、CI も
        env: で渡していた。つまり実際の利用者はこの経路にいる。
        pydantic-settings の EnvSettingsSource は宣言済みフィールドしか os.environ から
        拾わないため、削除済みキーはバリデータに到達せず、警告も出ないままだった。
        CHANGELOG と SETUP.md は「読み捨てて警告ログを出します」と約束している。
        """
        monkeypatch.setenv("SECRET_KEY", "left-over-from-compose")

        with caplog.at_level(logging.WARNING, logger="app.core.config"):
            settings = Settings(_env_file=None)

        assert not hasattr(settings, "SECRET_KEY")
        assert "SECRET_KEY" in caplog.text
        # env ファイルではなく環境変数側を直すよう案内すること
        assert "環境変数" in caplog.text

    def test_removed_key_from_env_file_points_at_env_file(self, tmp_path, caplog, monkeypatch):
        """.env 経由の場合は .env を直すよう案内する"""
        monkeypatch.delenv("SECRET_KEY", raising=False)
        env_file = tmp_path / ".env"
        env_file.write_text("SECRET_KEY=left-over\n", encoding="utf-8")

        with caplog.at_level(logging.WARNING, logger="app.core.config"):
            Settings(_env_file=env_file)

        assert "SECRET_KEY" in caplog.text
        assert "backend/.env" in caplog.text

    def test_removed_key_from_os_environment_does_not_become_a_field(self, monkeypatch):
        """OS環境変数経由でも設定値としては採用されない"""
        monkeypatch.setenv("ACCESS_TOKEN_EXPIRE_MINUTES", "11520")

        settings = Settings(_env_file=None)

        assert not hasattr(settings, "ACCESS_TOKEN_EXPIRE_MINUTES")

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
