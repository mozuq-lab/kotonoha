"""
アプリケーション設定

環境変数から設定を読み込み、型安全に管理する。
"""

import logging
import os
from pathlib import Path
from typing import Any, Literal

from pydantic import Field, ValidationError
from pydantic_settings import BaseSettings, PydanticBaseSettingsSource, SettingsConfigDict

logger = logging.getLogger(__name__)

DEV_POSTGRES_PASSWORD = "your_secure_password_here"  # noqa: S105

# ENVIRONMENT に許可される値。表記ゆれ（"prod" 等）は起動時エラーとして拒否する。
EnvironmentName = Literal["development", "test", "staging", "production"]


# 本番同等の必須設定チェックを免除する環境のallowlist。
#
# 【単一比較 (`== "production"`) にしない理由】: 免除されるべきなのは開発者の
# ローカルとCIだけで、staging を含むそれ以外は本番同等に扱う必要がある。
# 実際 require_api_key（app/api/deps.py）は _AUTH_OPTIONAL_ENVIRONMENTS
# （development / test）以外で全リクエストを 503 で fail-close するため、
# staging を免除すると「起動はするが AI変換が全滅する」状態が作れてしまう。
# アプリ内の他の判定（deps.py の認証、main.py のドキュメント公開）と同じ
# allowlist 方式に揃え、未知の環境名はフェイルクローズさせる。
_SETTINGS_CHECK_OPTIONAL_ENVIRONMENTS = frozenset({"development", "test"})


class ProductionSettingsError(RuntimeError):
    """本番環境の必須設定が満たされていない場合に送出される。

    【pydanticのバリデータではなく独立した例外にしている理由】:
    `@model_validator` の中で例外を投げると、pydantic が `ValidationError` に
    包む際に「バリデーション対象の入力（＝統合済みの設定辞書）」の repr を
    メッセージへ埋め込む。本番の設定漏れはまさに実物のシークレットが
    読み込まれている状況で起きるため、ANTHROPIC_API_KEY や POSTGRES_PASSWORD が
    そのまま stderr／コンテナログへ出力されてしまう。
    設定値を一切含まない独立した例外として送出することで、これを防ぐ。
    """


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
    # JWT実装の削除により署名用途が無くなり、アプリ内の消費者がゼロになったため削除。
    # 何も署名しない値を本番で用意・ローテーションし続ける運用コストだけが残っていた。
    # 署名用途が再び必要になったら、その用途と一緒に定義し直すこと。
    "SECRET_KEY": "JWT実装の削除により消費者が無くなったため廃止（この設定は無視されます）",
    # 同じくJWT実装の削除で読むコードが無くなった。SECRET_KEY と同じ規則を適用する。
    "SESSION_EXPIRE_MINUTES": (
        "JWT実装の削除により消費者が無くなったため廃止（この設定は無視されます）"
    ),
}


class _RemovedKeyFilter:
    """設定ソースをラップし、削除済みキーを取り除いて警告する。

    【ソース単位でラップする理由】: どのソースから来たかを、マージ後の辞書からは
    判別できない。以前は `key in data` を「.env 由来」とみなし、`model_config` の
    env_file を CWD 基準で解決して案内していたが、
      - init引数で渡した場合も .env を直せと案内する
      - `_env_file=` の上書きを無視して常に CWD の .env を見る
      - 自前の行パースが `KEY = "value"` 等を取りこぼす
    という誤案内を生んだ。各ソースが自分の素性を知っているので、そこで判定する。

    Attributes:
        source: ラップ対象の設定ソース。
        label: 警告に出す供給元の表示名。
    """

    def __init__(self, source: PydanticBaseSettingsSource, label: str) -> None:
        self._source = source
        self._label = label

    def __call__(self) -> dict[str, Any]:
        values = self._source()
        for key, reason in _REMOVED_SETTINGS.items():
            if key in values:
                del values[key]
                _warn_removed_setting(key, reason, self._label)
        return values


class _RemovedKeyEnvFilter(_RemovedKeyFilter):
    """OS環境変数ソース用のラッパー。

    【os.environ を直接見る理由】: EnvSettingsSource は宣言済みフィールドしか
    os.environ から拾わないため、削除済みキーはこのソースの戻り値に現れない。
    削除前の SECRET_KEY は docker-compose と CI が環境変数として渡していたので、
    ここを見ないと実際の利用者に通知が届かない。
    """

    def __call__(self) -> dict[str, Any]:
        values = self._source()
        for key, reason in _REMOVED_SETTINGS.items():
            if key in values:
                del values[key]
            if key in os.environ:
                _warn_removed_setting(key, reason, self._label)
        return values


def _warn_removed_setting(key: str, reason: str, location: str) -> None:
    """削除済み設定キーが指定されていることを警告する。

    setup_logging() 前に評価されることがあるが、ハンドラ未設定でも WARNING は
    Python の last resort ハンドラにより stderr へ出力される。

    Args:
        key: 削除済みの設定キー名。
        reason: 廃止理由。
        location: 指定が見つかった場所の表示名。
    """
    note = ""
    if "環境変数" in location:
        # SECRET_KEY のような一般的な名前は Django / Flask / CIランナー等でも
        # 使われる。本アプリと無関係に export されている場合に「消せ」とだけ
        # 言うと、存在しない設定を探させることになる。
        note = "（本アプリと無関係に同名の環境変数を設定している場合は無視して構いません）"
    logger.warning(
        "設定 %s は削除済みです（%s）。この値は読み込まれません。"
        "指定が残っている場合は %s から削除してください。%s",
        key,
        reason,
        location,
        note,
    )


class Settings(BaseSettings):
    """アプリケーション設定クラス"""

    # データベース設定
    POSTGRES_USER: str = "kotonoha_user"
    POSTGRES_PASSWORD: str = DEV_POSTGRES_PASSWORD
    POSTGRES_HOST: str = "localhost"
    POSTGRES_PORT: int = 5432
    POSTGRES_DB: str = "kotonoha_db"

    # API設定
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
    # ENVIRONMENT=production では未設定を許容しない（app/main.py が起動時に呼ぶ
    # validate_production_settings がアプリ起動を失敗させる。alembic 等 API を
    # 起動しないタスクは対象外）。単一プロセスで意図的にインメモリを使う場合も、暗黙の既定値
    # ではなく "memory://" を明示すること。
    RATE_LIMIT_STORAGE_URI: str = ""

    # 信頼するリバースプロキシの段数。
    # 0 の場合: X-Forwarded-For を信頼せず、接続元IP（request.client）でレート制限する。
    # N>=1 の場合: 自身が運用するプロキシ N 段を信頼し、X-Forwarded-For の右からN番目を
    # クライアントIPとして採用する（クライアントが偽装した左側の値による制限回避を防ぐ）。
    # 負値は意味を持たない（get_client_ip の `proxy_count > 0` が false になり
    # 挙動は 0 と同じ）。タイポやテンプレートの既定値 -1 が黙って通ると、
    # 全ユーザーが単一のレート制限カウンタを共有する状態に警告なしで入るため拒否する。
    TRUSTED_PROXY_COUNT: int = Field(default=0, ge=0)

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

    @classmethod
    def settings_customise_sources(
        cls,
        settings_cls: type[BaseSettings],
        init_settings: PydanticBaseSettingsSource,
        env_settings: PydanticBaseSettingsSource,
        dotenv_settings: PydanticBaseSettingsSource,
        file_secret_settings: PydanticBaseSettingsSource,
    ) -> tuple[PydanticBaseSettingsSource, ...]:
        """各設定ソースを、削除済みキーの読み捨て付きでラップする。

        本クラスは extra="forbid"（pydantic-settings既定）で動作するため、
        削除済みキーが各開発者の backend/.env や env ファイル方式のデプロイに
        残っていると "Extra inputs are not permitted" で起動できなくなる。
        .env.example を直しても既存の設定は自動では直らないため、既知の
        削除済みキーだけは読み捨てて、どこに残っているかを警告する。

        extra="ignore" に緩めない理由: 未知キーを一律無視すると RATE_LIMIT_SECOND の
        ようなタイポが黙って既定値で動いてしまい、レート制限の設定漏れを検出できなく
        なる。ここに列挙した「削除済みと分かっているキー」だけを対象にする。
        """
        dotenv_label = "設定ファイル（.env）"
        env_file = getattr(dotenv_settings, "env_file", None)
        if env_file:
            # `_env_file=` の上書きも含めて、実際に読まれるファイルを名指しする。
            # 【絶対パスにする理由】: `env_file=".env"` はプロセスのカレント
            # ディレクトリ基準で解決される。相対名のまま案内すると、backend/ 以外から
            # 起動した場合に読まれているファイルと違うものを直させてしまう。
            paths = env_file if isinstance(env_file, (list, tuple)) else [env_file]
            dotenv_label = " / ".join(str(Path(path).resolve()) for path in paths)

        return (
            _RemovedKeyFilter(init_settings, "アプリに渡している設定"),
            _RemovedKeyEnvFilter(
                env_settings, "環境変数（docker-compose.yml / タスク定義 / CI設定など）"
            ),
            _RemovedKeyFilter(dotenv_settings, dotenv_label),
            file_secret_settings,
        )


def validate_production_settings(target: "Settings") -> None:
    """本番環境では開発用の弱い既定値・安全でない既定値を拒否する。

    本番で見落とすと実害が出る設定を検出し、`ProductionSettingsError`（＝アプリ
    起動失敗）として弾く。警告ログではデプロイ時に見落とされ、設定漏れのまま
    稼働してしまうため、フェイルファストで揃えている。

    【`Settings` 生成時ではなくアプリ起動時に呼ぶ理由】:
    以前はこの検査を `@model_validator(mode="after")` として `Settings()` の
    生成時に走らせていたが、それだと `app.core.config` を import するだけの
    プロセスまで巻き添えになる。とくに `alembic/env.py` は settings を無条件に
    import するため、レート制限と無関係な `alembic upgrade head` が
    RATE_LIMIT_STORAGE_URI 未設定で起動不能になっていた。
    本関数は API アプリのエントリーポイント（`app/main.py`）から明示的に呼ぶ。
    マイグレーション等、APIを起動しないタスクは対象外となる。

    Args:
        target: 検査対象の設定インスタンス。

    Raises:
        ProductionSettingsError: 本番で必須の設定が満たされていない場合。
            例外メッセージには設定値を一切含めない（ログ経由の漏えいを防ぐため）。
    """
    if target.ENVIRONMENT in _SETTINGS_CHECK_OPTIONAL_ENVIRONMENTS:
        return

    # 【1件ずつ落とさない理由】: 最初の違反で止めると、漏れの数だけデプロイを
    # やり直すことになる。フェイルファストの目的は「起動させないこと」であって
    # 「1件ずつ知らせること」ではないので、まとめて報告する。
    problems: list[str] = []

    # 【空文字も弾く理由】: 開発既定値との完全一致しか見ていないと、
    # シークレットマネージャの取得が空を返したときにパスワード無しのDSN
    # （postgresql+asyncpg://user:@host/db）で起動できてしまう。
    # API_KEYS / RATE_LIMIT_STORAGE_URI は空を弾いており、扱いが割れていた。
    if not target.POSTGRES_PASSWORD.strip() or target.POSTGRES_PASSWORD == DEV_POSTGRES_PASSWORD:
        problems.append(
            "POSTGRES_PASSWORD must be set explicitly (empty or still the development default)"
        )
    # レート制限カウンタが未設定だとプロセス内メモリになる。マルチワーカー
    # （uvicorn --workers）／マルチインスタンス構成ではカウンタがプロセスごとに
    # 分裂して実効レート制限が「設定値 × プロセス数」まで緩む（NFR-101違反）。
    # 単一プロセス運用であっても再起動でカウンタが消えるため、共有ストレージ
    # （Redis等）の明示指定を必須とする。意図的にインメモリを使う場合は
    # "memory://" を明示すること。
    if not target.RATE_LIMIT_STORAGE_URI:
        problems.append(
            "RATE_LIMIT_STORAGE_URI must be set explicitly "
            "(unset means per-process in-memory counters, which weakens the "
            "effective rate limit under multi-worker/multi-instance deployments; "
            'set a shared storage URI such as "redis://host:6379", or "memory://" '
            "to opt in to in-memory counters intentionally)"
        )
    # API_KEYS が未設定でも起動自体はできてしまうが、app/api/deps.py の
    # require_api_key は development / test 以外では全リクエストを 503 で拒否する
    # （フェイルクローズ）。つまり「起動はするがAI変換が全滅する」状態になり、
    # 設定漏れに気付くのが実トラフィックを受けた後になる。起動時に落とす。
    if not target.API_KEYS_LIST:
        problems.append(
            "API_KEYS must be set explicitly "
            "(unset means every AI-conversion request is rejected with 503 by "
            "require_api_key, so the outage would only surface from real traffic)"
        )

    # TRUSTED_PROXY_COUNT は 0 が正当な構成（ALB等を挟まない直接公開）でもあるため
    # 起動失敗にはしない。ただし ALB / CDN 配下で 0 のままだと X-Forwarded-For を
    # 一切信用せず全リクエストがプロキシの接続元IPに収束し、レート制限が
    # 全ユーザー共有＝実質的なサービス停止になる。取り違えが起きやすいので警告する。
    # （負値はフィールド定義の ge=0 で拒否済み）
    if target.TRUSTED_PROXY_COUNT == 0:
        logger.warning(
            "TRUSTED_PROXY_COUNT=0 in %s: X-Forwarded-For is ignored and the "
            "connecting IP is used for rate limiting. This is correct only when the app "
            "is exposed directly. Behind a reverse proxy (ALB/CDN), set it to the actual "
            "number of trusted proxy hops, or all clients will share a single rate-limit "
            "counter.",
            target.ENVIRONMENT,
        )

    # 【警告を raise より前に出す理由】: 後ろに置くと、他に設定漏れがあるときに
    # 到達しない。「複数の漏れを1回でまとめて報告する」という目的は、
    # 例外だけでなく警告にも同じく当てはまる。
    # 【AIプロバイダのキーを含める理由】: API_KEYS と同じ失敗の形になる。
    # 未設定だと AIClient がクライアントを生成せず、変換要求がすべて
    # AIProviderException で失敗する一方、起動自体は成功してしまう。
    if not (target.ANTHROPIC_API_KEY or target.OPENAI_API_KEY):
        problems.append(
            "ANTHROPIC_API_KEY or OPENAI_API_KEY must be set explicitly "
            "(without a provider key every AI-conversion request fails, "
            "while the app still starts)"
        )

    if problems:
        raise ProductionSettingsError(
            f"ENVIRONMENT={target.ENVIRONMENT} requires the following settings: "
            + " / ".join(problems)
        )


class SettingsValidationError(RuntimeError):
    """設定の読み込みに失敗した場合に送出される（値を一切含まない）。

    【pydantic の ValidationError をそのまま伝播させない理由】:
    extra="forbid" の ValidationError は `input_value='sk-ant-...'` のように
    **違反した値そのもの**をメッセージに含む。シークレットの環境変数名を
    タイポすると（例: ANTHROPIC_API_KEYS）、起動を試みるたびにシークレットが
    stderr とコンテナログへ出力される。
    [ProductionSettingsError] と同じ理由で、値を含まない例外に置き換える。
    """


def _describe_validation_error(exc: ValidationError) -> str:
    """ValidationError を、値を含まない形で要約する。

    診断に必要なのは「どのキーが」「なぜ」であって、値そのものではない。

    Args:
        exc: pydantic の検証エラー。

    Returns:
        str: 値を含まない要約。
    """
    lines = []
    for error in exc.errors():
        location = ".".join(str(part) for part in error["loc"]) or "(unknown)"
        lines.append(f"{location}: {error['msg']}")
    return " / ".join(lines)


def _load_settings() -> Settings:
    """設定を読み込む。失敗時は値を含まない例外へ置き換える。"""
    try:
        return Settings()
    except ValidationError as exc:
        raise SettingsValidationError(
            "設定の読み込みに失敗しました。"
            "backend/.env.example と綴りを照合してください: " + _describe_validation_error(exc)
        ) from None


# グローバル設定インスタンス
settings = _load_settings()
