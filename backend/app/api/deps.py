"""FastAPI依存性注入モジュール。

エンドポイントで使用する共通の依存性を提供する。
データベースセッション、認証、その他の共通依存性を集約管理。

Example:
    エンドポイントでの使用::

        from fastapi import Depends
        from sqlalchemy.ext.asyncio import AsyncSession
        from app.api.deps import get_db_session

        @router.get("/items")
        async def get_items(db: AsyncSession = Depends(get_db_session)):
            # db を使用したデータベース操作
            ...
"""

import logging
from collections.abc import AsyncGenerator

from fastapi import HTTPException, Security, status
from fastapi.security import APIKeyHeader
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.core.config import settings
from app.core.security import is_valid_api_key
from app.db.session import async_session_maker, get_db

logger = logging.getLogger(__name__)

# 端末APIキーを受け取るHTTPヘッダー名
API_KEY_HEADER_NAME = "X-API-Key"

# auto_error=False: ヘッダー欠如時もFastAPI標準403ではなく、本モジュールで統一的に処理する
api_key_header = APIKeyHeader(name=API_KEY_HEADER_NAME, auto_error=False)

# APIキー未設定時に認証スキップを許可する環境のallowlist。
# ここに含まれない環境（staging, production、および将来追加されうる未知の値）は
# フェイルオープンを避けるため、常に認証必須（APIキー未設定なら503）とする。
_AUTH_OPTIONAL_ENVIRONMENTS = frozenset({"development", "test"})


async def get_db_session() -> AsyncGenerator[AsyncSession, None]:
    """データベースセッションを取得する依存性関数。

    get_db関数をラップして、依存性注入で使用可能にする。
    この関数は将来的に追加の前処理・後処理を行う拡張ポイントとして機能する。

    Yields:
        AsyncSession: 非同期データベースセッション

    Example:
        ::

            @router.post("/users")
            async def create_user(
                user: UserCreate,
                db: AsyncSession = Depends(get_db_session)
            ):
                db.add(User(**user.model_dump()))
                await db.commit()
    """
    async for session in get_db():
        yield session


def get_session_factory() -> async_sessionmaker[AsyncSession]:
    """独立した短命セッションを生成するファクトリを取得する依存性関数。

    バックグラウンドタスク（FastAPIの`BackgroundTasks`）内でDB書き込みを行う場合、
    リクエストスコープのセッション（`get_db_session`が提供するもの）は応答返却後に
    既にクローズされている可能性があるため再利用できない。この関数が返す
    ファクトリを呼び出す都度、新規セッションを開いて使い終わったら明示的に
    クローズすること。

    テストでは本関数をFastAPIの依存性オーバーライド機構でオーバーライドし、
    テスト用データベースにバックグラウンド書き込みを向けられるようにする。

    Returns:
        async_sessionmaker[AsyncSession]: 新規セッションを生成するファクトリ

    Example:
        バックグラウンドタスクでの使用例::

            async def write_log(session_factory: async_sessionmaker[AsyncSession]) -> None:
                session = session_factory()
                try:
                    ...
                    await session.commit()
                finally:
                    await session.close()
    """
    return async_session_maker


async def require_api_key(
    api_key: str | None = Security(api_key_header),
) -> None:
    """端末APIキーによるアクセス制御を行う依存性関数。

    AI変換APIを保護し、無認証・無制限の外部AI API課金消費を防ぐ。
    MVPはアカウント管理を持たないため、端末発行の共有シークレットで認証する。

    挙動:
        - APIキーが未設定（settings.API_KEYS が空）の場合:
            - development / test 環境（allowlist）でのみ認証をスキップ（警告ログ）
            - それ以外（staging, production を含む）では全リクエストを拒否
              （503: フェイルクローズ、設定漏れ防止）
        - APIキーが設定されている場合:
            - 有効な X-API-Key ヘッダーを要求し、不一致・欠如は 401 で拒否

    Args:
        api_key: X-API-Key ヘッダーの値（未指定の場合None）

    Raises:
        HTTPException: 認証失敗時（401）またはサーバー設定不備時（503）
    """
    if not settings.API_KEYS_LIST:
        if settings.ENVIRONMENT in _AUTH_OPTIONAL_ENVIRONMENTS:
            # 開発・テスト環境では認証をスキップ（誤って他環境で無効化しないよう警告）
            logger.warning(
                "API_KEYS is not configured; skipping authentication (environment=%s).",
                settings.ENVIRONMENT,
            )
            return
        # allowlist外（staging, production等）はフェイルオープンを避け、常に拒否する
        logger.error(
            "API_KEYS is not configured in %s; rejecting request (fail-closed).",
            settings.ENVIRONMENT,
        )
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="API key authentication is not configured.",
        )

    if not is_valid_api_key(api_key):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or missing API key.",
            headers={"WWW-Authenticate": API_KEY_HEADER_NAME},
        )
