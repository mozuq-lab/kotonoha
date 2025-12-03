"""
TASK-0097: NFR-105 環境変数管理テスト（バックエンド）

信頼性レベル: 🔵 青信号（NFR-105に基づく）
テスト対象: 環境変数がアプリ内にハードコードされていないこと
"""

import re
from pathlib import Path

import pytest


class TestEnvironmentVariables:
    """NFR-105: 環境変数管理テスト"""

    @pytest.fixture
    def backend_app_dir(self) -> Path:
        """バックエンドアプリディレクトリ"""
        return Path(__file__).parent.parent.parent / "app"

    @pytest.fixture
    def project_root(self) -> Path:
        """プロジェクトルートディレクトリ"""
        return Path(__file__).parent.parent.parent.parent

    def test_api_keys_not_hardcoded_in_python_files(self, backend_app_dir: Path):
        """TC-105-001: appディレクトリにAPIキーがハードコードされていない"""
        if not backend_app_dir.exists():
            pytest.skip("app directory not found")

        # Anthropic APIキーパターン: sk-ant-
        anthropic_pattern = re.compile(r"sk-ant-[a-zA-Z0-9_-]{20,}")

        # OpenAI APIキーパターン: sk-（長いキーのみ）
        openai_pattern = re.compile(r'["\']sk-[a-zA-Z0-9]{20,}["\']')

        for py_file in backend_app_dir.rglob("*.py"):
            content = py_file.read_text()

            # Anthropic APIキーのチェック
            assert not anthropic_pattern.search(
                content
            ), f"Anthropic APIキーが {py_file} にハードコードされています"

            # OpenAI APIキーのチェック
            assert not openai_pattern.search(
                content
            ), f"OpenAI APIキーが {py_file} にハードコードされています"

    def test_secret_key_from_env(self, backend_app_dir: Path):
        """TC-105-002: SECRET_KEYが環境変数から読み込まれる"""
        config_file = backend_app_dir / "core" / "config.py"
        if not config_file.exists():
            pytest.skip("config.py not found")

        content = config_file.read_text()

        # Settingsクラスで SECRET_KEY が定義されていることを確認
        assert "SECRET_KEY" in content, "SECRET_KEY が config.py に定義されていません"

        # pydantic_settingsを使用していることを確認
        assert (
            "BaseSettings" in content or "pydantic_settings" in content
        ), "pydantic_settingsを使用していません"

    def test_database_credentials_from_env(self, backend_app_dir: Path):
        """TC-105-003: データベース接続情報が環境変数から読み込まれる"""
        config_file = backend_app_dir / "core" / "config.py"
        if not config_file.exists():
            pytest.skip("config.py not found")

        content = config_file.read_text()

        # PostgreSQL関連の環境変数が定義されていることを確認
        required_vars = [
            "POSTGRES_USER",
            "POSTGRES_PASSWORD",
            "POSTGRES_HOST",
            "POSTGRES_DB",
        ]

        for var in required_vars:
            assert var in content, f"{var} が config.py に定義されていません"

    def test_env_file_in_gitignore(self, project_root: Path):
        """TC-105-004: .envがgitignoreに含まれる"""
        gitignore_file = project_root / ".gitignore"
        if not gitignore_file.exists():
            pytest.skip(".gitignore not found")

        content = gitignore_file.read_text()

        # .envがgitignoreに含まれることを確認
        assert ".env" in content, ".env がgitignoreに含まれていません"

    def test_backend_env_file_in_gitignore(self):
        """TC-105-004: backend/.envがgitignoreに含まれる"""
        backend_dir = Path(__file__).parent.parent.parent
        gitignore_file = backend_dir / ".gitignore"

        if not gitignore_file.exists():
            # バックエンドにgitignoreがない場合、プロジェクトルートで管理
            return

        content = gitignore_file.read_text()
        assert ".env" in content, "backend/.env がgitignoreに含まれていません"


class TestHTTPSConfiguration:
    """NFR-104: HTTPS通信設定テスト"""

    @pytest.fixture
    def backend_app_dir(self) -> Path:
        """バックエンドアプリディレクトリ"""
        return Path(__file__).parent.parent.parent / "app"

    def test_cors_configuration_exists(self, backend_app_dir: Path):
        """TC-104-003: CORSが正しく設定される"""
        config_file = backend_app_dir / "core" / "config.py"
        if not config_file.exists():
            pytest.skip("config.py not found")

        content = config_file.read_text()

        # CORS設定が存在することを確認
        assert "CORS" in content, "CORS設定が config.py に存在しません"

    def test_cors_origins_from_env(self, backend_app_dir: Path):
        """TC-104-003: CORS_ORIGINSが環境変数から読み込まれる"""
        config_file = backend_app_dir / "core" / "config.py"
        if not config_file.exists():
            pytest.skip("config.py not found")

        content = config_file.read_text()

        # CORS_ORIGINS環境変数が定義されていることを確認
        assert (
            "CORS_ORIGINS" in content
        ), "CORS_ORIGINS が config.py に定義されていません"


class TestPrivacyProtection:
    """NFR-102: プライバシー保護テスト"""

    @pytest.fixture
    def backend_app_dir(self) -> Path:
        """バックエンドアプリディレクトリ"""
        return Path(__file__).parent.parent.parent / "app"

    def test_ai_conversion_does_not_log_plain_text(self, backend_app_dir: Path):
        """TC-102-NFR: AI変換でプレーンテキストがログに保存されない設計"""
        # 設計確認: AI変換のログはハッシュ化して保存（database-schema.sql参照）
        # input_text_hashカラムが使用され、平文は保存されない

        # database-schema.sqlを確認
        schema_file = (
            Path(__file__).parent.parent.parent.parent
            / "docs"
            / "design"
            / "kotonoha"
            / "database-schema.sql"
        )

        if not schema_file.exists():
            pytest.skip("database-schema.sql not found")

        content = schema_file.read_text()

        # ハッシュカラムが存在することを確認
        assert (
            "input_text_hash" in content
        ), "input_text_hash カラムがスキーマに存在しません"
