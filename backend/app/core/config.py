"""
アプリケーション設定

環境変数から設定を読み込み、型安全に管理する。
"""

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """アプリケーション設定クラス"""

    # データベース設定
    POSTGRES_USER: str
    POSTGRES_PASSWORD: str
    POSTGRES_HOST: str = "localhost"
    POSTGRES_PORT: int = 5432
    POSTGRES_DB: str

    # API設定
    SECRET_KEY: str
    API_HOST: str = "0.0.0.0"  # noqa: S104
    API_PORT: int = 8000
    API_V1_STR: str = "/api/v1"
    PROJECT_NAME: str = "kotonoha API"
    VERSION: str = "1.0.0"

    # 認証設定
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 8  # 8日間

    # 環境設定
    ENVIRONMENT: str = "development"

    # CORS設定
    CORS_ORIGINS: str = "http://localhost:3000,http://localhost:5173"

    # セッション設定
    SESSION_EXPIRE_MINUTES: int = 60

    # レート制限設定
    RATE_LIMIT_PER_MINUTE: int = 10

    # ログ設定
    LOG_LEVEL: str = "INFO"
    LOG_FILE_PATH: str = "logs/app.log"

    # AI変換機能設定（OpenAI）
    OPENAI_API_KEY: str | None = None
    OPENAI_MODEL: str = "gpt-4o-mini"

    # AI変換機能設定（Anthropic）
    ANTHROPIC_API_KEY: str | None = None
    DEFAULT_AI_PROVIDER: str = "anthropic"
    AI_API_TIMEOUT: int = 30
    AI_MAX_RETRIES: int = 3

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
    )

    @property
    def DATABASE_URL(self) -> str:  # noqa: N802
        """データベース接続URL（非同期用）"""
        return (
            f"postgresql+asyncpg://{self.POSTGRES_USER}:{self.POSTGRES_PASSWORD}"
            f"@{self.POSTGRES_HOST}:{self.POSTGRES_PORT}/{self.POSTGRES_DB}"
        )

    @property
    def DATABASE_URL_SYNC(self) -> str:  # noqa: N802
        """データベース接続URL（同期用、Alembicマイグレーション用）"""
        return (
            f"postgresql://{self.POSTGRES_USER}:{self.POSTGRES_PASSWORD}"
            f"@{self.POSTGRES_HOST}:{self.POSTGRES_PORT}/{self.POSTGRES_DB}"
        )

    @property
    def CORS_ORIGINS_LIST(self) -> list[str]:  # noqa: N802
        """CORS許可オリジンのリスト"""
        return [origin.strip() for origin in self.CORS_ORIGINS.split(",")]


# グローバル設定インスタンス
settings = Settings()
