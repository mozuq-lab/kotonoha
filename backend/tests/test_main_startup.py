"""app/main.py の起動時ガードのテスト

【テスト対象】: app/main.py が import 時に validate_production_settings を呼ぶこと
【テスト目的】: 本番固有の必須設定チェックが「実際に起動経路で走る」ことを保証する。

【この回帰テストの理由】:
本番チェックは元々 Settings の @model_validator として動いており、
`Settings()` を作るだけで必ず走っていた。しかしそれだと app.core.config を
import するだけのプロセス（alembic/env.py 等）まで巻き添えになるため、
app/main.py からの明示的な1行の呼び出しに変更した。

その結果、ガード全体がテストされていない1行に依存するようになった。
validate_production_settings() を直接呼ぶテストと「Settings 生成時には
検査しない」テストだけでは、main.py からその1行を消しても全テストが通ってしまい、
本番がプロセス内メモリのカウンタや APIキー未設定のまま静かに起動してしまう。

【サブプロセスで検証する理由】:
検査は import 時に一度だけ走るため、同一プロセス内では再現できない
（importlib.reload で無理に再現すると FastAPI アプリを作り直すことになり、
他のテストへ影響する）。実際の起動と同じく、独立したプロセスで
`import app.main` を実行して終了コードと出力を確認する。
"""

import subprocess
import sys
from pathlib import Path

import pytest

# backend/ ディレクトリ（app パッケージの親）
_BACKEND_ROOT = Path(__file__).resolve().parents[1]

# 本番として成立する最小構成。RATE_LIMIT_STORAGE_URI だけを欠けさせて検査を発火させる。
_PRODUCTION_ENV = {
    "ENVIRONMENT": "production",
    "POSTGRES_PASSWORD": "a-sufficiently-random-production-password",
    "API_KEYS": "device-key-must-not-leak",
    "ANTHROPIC_API_KEY": "sk-ant-must-not-leak",
}


def _run_import(
    module: str, env_overrides: dict[str, str], cwd: Path
) -> subprocess.CompletedProcess:
    """独立したプロセスでモジュールを import し、結果を返す。

    【cwd を backend/ にしない理由】: Settings は env_file=".env" を
    カレントディレクトリ基準で探すため、backend/ で実行すると開発者の
    backend/.env に結果が左右される（RATE_LIMIT_STORAGE_URI がそこに
    書かれているだけでテストが緑になってしまう）。
    空の一時ディレクトリで実行し、モジュールの解決は PYTHONPATH で行う。
    """
    import os

    env = os.environ.copy()
    # 開発者ローカルの環境変数が結果を左右しないよう、関係するキーを一度落とす。
    for key in ("ENVIRONMENT", "RATE_LIMIT_STORAGE_URI", "POSTGRES_PASSWORD"):
        env.pop(key, None)
    env.update(env_overrides)
    env["PYTHONPATH"] = str(_BACKEND_ROOT)

    # S603: 実行するのは sys.executable と、本ファイル内で定数として与える
    # モジュール名のみ。外部入力は混入しない。
    return subprocess.run(  # noqa: S603
        [sys.executable, "-c", f"import {module}"],
        cwd=cwd,
        env=env,
        capture_output=True,
        text=True,
        timeout=120,
    )


class TestMainInvokesProductionValidation:
    """app.main の import が本番チェックを実際に発火させることのテスト"""

    def test_importing_main_fails_when_production_setting_is_missing(self, tmp_path):
        """本番で RATE_LIMIT_STORAGE_URI が欠けていれば app.main の import が失敗する"""
        result = _run_import("app.main", _PRODUCTION_ENV, tmp_path)

        assert result.returncode != 0, (
            "本番の必須設定が欠けているのに app.main の import が成功した。"
            "app/main.py の validate_production_settings(settings) 呼び出しが"
            "消えていないか確認すること"
        )
        assert "RATE_LIMIT_STORAGE_URI" in result.stderr
        assert "ProductionSettingsError" in result.stderr

    def test_importing_main_succeeds_when_production_settings_are_complete(self, tmp_path):
        """本番の必須設定が揃っていれば app.main は正常に import できる"""
        result = _run_import(
            "app.main",
            {**_PRODUCTION_ENV, "RATE_LIMIT_STORAGE_URI": "memory://"},
            tmp_path,
        )

        assert result.returncode == 0, f"import に失敗した: {result.stderr}"

    def test_importing_config_alone_succeeds_without_production_setting(self, tmp_path):
        """app.core.config だけの import は本番設定が欠けていても成功する

        alembic/env.py は settings を無条件に import するため、
        ここが失敗すると `alembic upgrade head` が実行できなくなる。
        """
        result = _run_import("app.core.config", _PRODUCTION_ENV, tmp_path)

        assert result.returncode == 0, f"config の import に失敗した: {result.stderr}"

    @pytest.mark.parametrize(
        "secret_value",
        ["device-key-must-not-leak", "sk-ant-must-not-leak"],
    )
    def test_startup_failure_output_does_not_leak_secrets(self, secret_value: str, tmp_path):
        """起動失敗時の実際の出力（stderr/stdout）にシークレットが出ないこと

        単体の例外メッセージだけでなく、プロセスが実際に吐く出力全体で確認する。
        """
        result = _run_import("app.main", _PRODUCTION_ENV, tmp_path)

        assert secret_value not in result.stderr
        assert secret_value not in result.stdout


class TestStartupOutputDoesNotLeakStorageCredentials:
    """レート制限ストレージの初期化失敗が、実プロセスの出力に資格情報を出さないこと。

    【プロセス全体を見る理由】: 単体では例外オブジェクトの各属性を検証しているが、
    運用者が実際に目にするのは「起動に失敗したコンテナの stdout/stderr 全体」である。
    連鎖トレースバックは未捕捉例外としてそこへ出るため、戻り値ではなく
    最も外側の観測面で確認する。
    （app.main は app.core.rate_limit を import した時点で失敗するので、
    本番相当の起動失敗そのものを再現できる。）
    """

    _SECRET = "s3cr3t-pw-must-not-appear"

    @pytest.mark.parametrize(
        "uri_template",
        [
            "foobar://:{secret}@prod-redis:6379",
            "redis-sentinel://:{secret}@prod-redis:6379/0",
        ],
        ids=["password_only", "with_path"],
    )
    def test_startup_failure_output_has_no_storage_credentials(self, uri_template, tmp_path):
        result = _run_import(
            "app.main",
            {
                **_PRODUCTION_ENV,
                "RATE_LIMIT_STORAGE_URI": uri_template.format(secret=self._SECRET),
            },
            tmp_path,
        )

        assert result.returncode != 0, "不正なストレージURIなのに起動が成功した"
        combined = result.stdout + result.stderr
        assert self._SECRET not in combined, "起動失敗時のプロセス出力に資格情報が含まれている"
        # 診断に必要な手掛かりは残っていること
        assert "RATE_LIMIT_STORAGE_URI" in combined
