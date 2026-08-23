"""
アプリケーション設定

環境変数から設定を読み込み、型安全に管理する。
"""

import logging
from typing import Any, Literal

from pydantic import model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

logger = logging.getLogger(__name__)

DEV_SECRET_KEY = "dev-secret-key-change-me"  # noqa: S105
DEV_POSTGRES_PASSWORD = "your_secure_password_here"  # noqa: S105

# ENVIRONMENT に許可される値。表記ゆれ（"prod" 等）は起動時エラーとして拒否する。
EnvironmentName = Literal["development", "test", "staging", "production"]

# 過去に存在したが削除された設定キー（キー: 削除理由）。
#
# 本クラスは extra="forbid"（pydantic-settings既定）で動作するため、削除済みキーが
# 各開発者の backend/.env や env ファイル方式のデプロイに残っていると、
# "Extra inputs are not permitted" で起動できなくなる。.env.example を直しても
# 既存の .env は自動では直らないため、既知の削除済みキーだけは読み捨てて警告する。
#
# extra="ignore" に緩めない理由: 未知キーを一律無視すると RATE_LIMIT_SECOND のような
# タイポが黙って既定値で動いてしまい、レート制限の設定漏れを検出できなくなる。
# ここに列挙した「削除済みと分かっているキー」だけを対象にし、それ以外の未知キーは
# これまで通り起動時エラーとして弾く。
_REMOVED_SETTINGS: dict[str, str] = {
    # 未使用のJWT実装（create_access_token）と共に削除。MVPは端末APIキー認証のみ。
    "ACCESS_TOKEN_EXPIRE_MINUTES": "JWT実装の削除に伴い廃止（この設定は無視されます）",
}


class Settings(BaseSettings):
    """アプリケーション設定クラス"""

    # データベース設定
    POSTGRES_USER: str = "kotonoha_user"
    POSTGRES_PASSWORD: str = DEV_POSTGRES_PASSWORD
    POSTGRES_HOST: str = "localhost"
    POSTGRES_PORT: int = 5432
    POSTGRES_DB: str = "kotonoha_db"

    # API設定
    # 【現状アプリ内に消費者はいない】JWT実装の削除により、SECRET_KEY を実際に使う
    # コードは無くなった（参照は本定義と validate_production_settings のみ）。
    # それでも残しているのは、docker-compose.yml が `:?` で必須化し CI もセットしている
    # 運用上の契約であること、および署名用途が発生した際の受け皿を維持するため。
    # 用途を追加しないまま棚卸しする場合は、docker-compose.yml とCIも併せて外すこと。
    SECRET_KEY: str = DEV_SECRET_KEY
    API_HOST: str = "0.0.0.0"  # noqa: S104
    API_PORT: int = 8000
    API_V1_STR: str = "/api/v1"
    PROJECT_NAME: str = "kotonoha API"
    VERSION: str = "1.0.0"

    # 端末APIキー認証設定
    # AI変換APIへのアクセスに必要な端末APIキー（カンマ区切りで複数指定可）。
    # MVPはアカウント管理を持たないため、端末発行の共有シークレットで保護する。
    # 未設定の場合: development/test では認証をスキップ、それ以外（staging/production等）は
    # 全リクエストを拒否（フェイルクローズ、allowlist方式）。
    API_KEYS: str = ""

    # 環境設定
    # 許可される値: development, test, staging, production のみ（表記ゆれは起動時エラー）。
    ENVIRONMENT: EnvironmentName = "development"

    # CORS設定
    CORS_ORIGINS: str = "http://localhost:3000,http://localhost:5173"

    # セッション設定
    # 【現状アプリ内に消費者はいない】サーバー側セッション管理は未実装のため、
    # この値を読むコードは存在しない。将来のセッション管理導入時の受け皿として
    # 残している。棚卸しする場合は _REMOVED_SETTINGS への追加を忘れないこと
    # （.env.example に載っており、各開発者の .env に残っているため）。
    SESSION_EXPIRE_MINUTES: int = 60

    # レート制限設定
    # AI変換APIのレート制限（RATE_LIMIT_TIMES 回 / RATE_LIMIT_SECONDS 秒 / IP）。
    # デフォルトは NFR-101（1リクエスト/10秒/IP）。
    RATE_LIMIT_TIMES: int = 1
    RATE_LIMIT_SECONDS: int = 10

    # レート制限カウンタの保存先URI（slowapi/limitsが解釈できる形式）。
    # 空文字列（デフォルト）: プロセス内メモリに保存する。マルチワーカー/マルチインスタンス
    # 構成では各プロセスが独立したカウンタを持つため実質的な制限が緩くなり、
    # プロセス再起動でもリセットされてしまう。本番でマルチワーカー/マルチインスタンス
    # 運用する場合は Redis 等の共有ストレージURIを指定すること（例: "redis://host:6379"）。
    # ENVIRONMENT=production では未設定を許容しない（validate_production_settings が
    # 起動時エラーにする）。単一プロセスで意図的にインメモリを使う場合も、暗黙の既定値
    # ではなく "memory://" を明示すること。
    RATE_LIMIT_STORAGE_URI: str = ""

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
    ANTHROPIC_MODEL: str = "claude-sonnet-4-6"
    DEFAULT_AI_PROVIDER: str = "anthropic"

    # AI API呼び出し1試行あたりのタイムアウト秒数（SDKクライアントに直接渡す値）。
    # フロントエンド（Dio）のconnect/receiveタイムアウト（各10秒）を踏まえ、
    # 1試行がそれを超えて居座らないよう8秒に設定する。
    AI_API_TIMEOUT: int = 8

    # リトライ回数（試行回数ではなく、初回呼び出しに加えて許容する再試行回数）。
    # 接続エラー（APIConnectionError。ただしタイムアウトは含まない）とレート制限
    # （429 / RateLimitError）のみを対象にリトライする。APIタイムアウトはリトライせず
    # AI_CALL_DEADLINE_SECONDSによる全体デッドラインに委ねる。
    # デフォルト1: 最大1回まで再試行する（初回+1回、合計最大2試行）。
    AI_MAX_RETRIES: int = 1

    # AI呼び出し1リクエスト全体（リトライ試行すべてを含む）に課す最大所要秒数。
    # フロントエンド（Dio）のconnect/receiveタイムアウト（各10秒）と整合させ、
    # クライアントが待受を諦めた後もバックエンドがAI APIへの課金呼び出しを
    # 継続してしまう事態を防ぐ。超過時はタイムアウトエラーとして扱われる。
    AI_CALL_DEADLINE_SECONDS: float = 10.0

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

    @model_validator(mode="before")
    @classmethod
    def drop_removed_settings(cls, data: Any) -> Any:  # noqa: ANN401
        """削除済みの設定キーを読み捨て、警告ログを出す。

        .env に古いキーが残っているだけで起動不能になるのを防ぐための移行措置。
        対象は `_REMOVED_SETTINGS` に明示したキーのみで、それ以外の未知キーは
        extra="forbid" により従来どおり起動時エラーになる（タイポ検出を維持するため）。

        Args:
            data: バリデーション前の入力（BaseSettingsからは各ソースを統合した辞書が渡る）。

        Returns:
            Any: 削除済みキーを取り除いた入力。
        """
        if not isinstance(data, dict):
            return data

        for key, reason in _REMOVED_SETTINGS.items():
            if key in data:
                del data[key]
                # setup_logging() 前に評価されるが、ハンドラ未設定でも WARNING は
                # Python の last resort ハンドラにより stderr へ出力される。
                logger.warning(
                    "設定 %s は削除済みです（%s）。backend/.env から該当行を削除してください。",
                    key,
                    reason,
                )
        return data

    @model_validator(mode="after")
    def validate_production_settings(self) -> "Settings":
        """本番環境では開発用の弱い既定値・安全でない既定値を拒否する。

        本番で見落とすと実害が出る設定を起動時に検出し、`ValueError`（＝設定読み込み
        失敗によるアプリ起動失敗）として弾く。警告ログではデプロイ時に見落とされ、
        設定漏れのまま稼働してしまうため、フェイルファストで揃えている。
        """
        if self.ENVIRONMENT != "production":
            return self

        if self.SECRET_KEY == DEV_SECRET_KEY:
            raise ValueError("SECRET_KEY must be set explicitly in production")
        if self.POSTGRES_PASSWORD == DEV_POSTGRES_PASSWORD:
            raise ValueError("POSTGRES_PASSWORD must be set explicitly in production")
        # レート制限カウンタが未設定だとプロセス内メモリになる。本番はマルチワーカー
        # （uvicorn --workers）／マルチインスタンス構成が前提であり、その場合カウンタが
        # プロセスごとに分裂して実効レート制限が「設定値 × プロセス数」まで緩む
        # （NFR-101違反）。単一プロセス運用であっても再起動でカウンタが消えるため、
        # 本番では共有ストレージ（Redis等）の明示指定を必須とする。
        # 単一プロセスで意図的にインメモリを使う場合は "memory://" を明示すること。
        if not self.RATE_LIMIT_STORAGE_URI:
            raise ValueError(
                "RATE_LIMIT_STORAGE_URI must be set explicitly in production "
                "(unset means per-process in-memory counters, which weakens the "
                "effective rate limit under multi-worker/multi-instance deployments; "
                'set a shared storage URI such as "redis://host:6379", or "memory://" '
                "to opt in to in-memory counters intentionally)"
            )

        return self


# グローバル設定インスタンス
settings = Settings()
