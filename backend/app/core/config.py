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
    API_HOST: str = "0.0.0.0"
    API_PORT: int = 8000

    # 環境設定
    ENVIRONMENT: str = "development"

    # CORS設定
    CORS_ORIGINS: str = "http://localhost:3000,http://localhost:5173"

    # セッション設定
    SESSION_EXPIRE_MINUTES: int = 60

    # レート制限設定
    RATE_LIMIT_PER_MINUTE: int = 10

    # ログレベル
    LOG_LEVEL: str = "INFO"

    # AI変換機能設定（オプション）
    OPENAI_API_KEY: str | None = None
    OPENAI_MODEL: str = "gpt-4o-mini"

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
    )

    @property
    def DATABASE_URL(self) -> str:
        """データベース接続URL（非同期用）"""
        return (
            f"postgresql+asyncpg://{self.POSTGRES_USER}:{self.POSTGRES_PASSWORD}"
            f"@{self.POSTGRES_HOST}:{self.POSTGRES_PORT}/{self.POSTGRES_DB}"
        )

    @property
    def DATABASE_URL_SYNC(self) -> str:
        """データベース接続URL（同期用、Alembicマイグレーション用）"""
        return (
            f"postgresql://{self.POSTGRES_USER}:{self.POSTGRES_PASSWORD}"
            f"@{self.POSTGRES_HOST}:{self.POSTGRES_PORT}/{self.POSTGRES_DB}"
        )

    @property
    def CORS_ORIGINS_LIST(self) -> list[str]:
        """CORS許可オリジンのリスト"""
        return [origin.strip() for origin in self.CORS_ORIGINS.split(",")]


# グローバル設定インスタンス
settings = Settings()
