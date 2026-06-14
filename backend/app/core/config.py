"""
アプリケーション設定

環境変数から設定を読み込み、型安全に管理する。
"""

from pydantic import model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

DEV_SECRET_KEY = "dev-secret-key-change-me"  # noqa: S105
DEV_POSTGRES_PASSWORD = "your_secure_password_here"  # noqa: S105


class Settings(BaseSettings):
    """アプリケーション設定クラス"""

    # データベース設定
    POSTGRES_USER: str = "kotonoha_user"
    POSTGRES_PASSWORD: str = DEV_POSTGRES_PASSWORD
    POSTGRES_HOST: str = "localhost"
    POSTGRES_PORT: int = 5432
    POSTGRES_DB: str = "kotonoha_db"

    # API設定
    SECRET_KEY: str = DEV_SECRET_KEY
    API_HOST: str = "0.0.0.0"  # noqa: S104
    API_PORT: int = 8000
    API_V1_STR: str = "/api/v1"
    PROJECT_NAME: str = "kotonoha API"
    VERSION: str = "1.0.0"

    # 認証設定
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 8  # 8日間

    # 端末APIキー認証設定
    # AI変換APIへのアクセスに必要な端末APIキー（カンマ区切りで複数指定可）。
    # MVPはアカウント管理を持たないため、端末発行の共有シークレットで保護する。
    # 未設定の場合: development/test では認証をスキップ、production では全リクエストを拒否。
    API_KEYS: str = ""

    # 環境設定
    ENVIRONMENT: str = "development"

    # CORS設定
    CORS_ORIGINS: str = "http://localhost:3000,http://localhost:5173"

    # セッション設定
    SESSION_EXPIRE_MINUTES: int = 60

    # レート制限設定
    # AI変換APIのレート制限（RATE_LIMIT_TIMES 回 / RATE_LIMIT_SECONDS 秒 / IP）。
    # デフォルトは NFR-101（1リクエスト/10秒/IP）。
    RATE_LIMIT_TIMES: int = 1
    RATE_LIMIT_SECONDS: int = 10

    # 信頼するリバースプロキシの段数。
    # 0 の場合: X-Forwarded-For を信頼せず、接続元IP（request.client）でレート制限する。
    # N>=1 の場合: 自身が運用するプロキシ N 段を信頼し、X-Forwarded-For の右からN番目を
    # クライアントIPとして採用する（クライアントが偽装した左側の値による制限回避を防ぐ）。
    TRUSTED_PROXY_COUNT: int = 0

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

    @property
    def API_KEYS_LIST(self) -> list[str]:  # noqa: N802
        """有効な端末APIキーのリスト（空要素は除外）"""
        return [key.strip() for key in self.API_KEYS.split(",") if key.strip()]

    @model_validator(mode="after")
    def validate_production_settings(self) -> "Settings":
        """本番環境では開発用の弱い既定値を拒否する。"""
        if self.ENVIRONMENT != "production":
            return self

        if self.SECRET_KEY == DEV_SECRET_KEY:
            raise ValueError("SECRET_KEY must be set explicitly in production")
        if self.POSTGRES_PASSWORD == DEV_POSTGRES_PASSWORD:
            raise ValueError("POSTGRES_PASSWORD must be set explicitly in production")

        return self


# グローバル設定インスタンス
settings = Settings()
