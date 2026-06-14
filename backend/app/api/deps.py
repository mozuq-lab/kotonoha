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
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.security import is_valid_api_key
from app.db.session import get_db

logger = logging.getLogger(__name__)

# 端末APIキーを受け取るHTTPヘッダー名
API_KEY_HEADER_NAME = "X-API-Key"

# auto_error=False: ヘッダー欠如時もFastAPI標準403ではなく、本モジュールで統一的に処理する
api_key_header = APIKeyHeader(name=API_KEY_HEADER_NAME, auto_error=False)


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


async def require_api_key(
    api_key: str | None = Security(api_key_header),
) -> None:
    """端末APIキーによるアクセス制御を行う依存性関数。

    AI変換APIを保護し、無認証・無制限の外部AI API課金消費を防ぐ。
    MVPはアカウント管理を持たないため、端末発行の共有シークレットで認証する。

    挙動:
        - APIキーが未設定（settings.API_KEYS が空）の場合:
            - production 環境では全リクエストを拒否（503: フェイルクローズ、設定漏れ防止）
            - それ以外（development / test）では認証をスキップ（警告ログ）
        - APIキーが設定されている場合:
            - 有効な X-API-Key ヘッダーを要求し、不一致・欠如は 401 で拒否

    Args:
        api_key: X-API-Key ヘッダーの値（未指定の場合None）

    Raises:
        HTTPException: 認証失敗時（401）またはサーバー設定不備時（503）
    """
    if not settings.API_KEYS_LIST:
        if settings.ENVIRONMENT == "production":
            logger.error("API_KEYS is not configured in production; rejecting request.")
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="API key authentication is not configured.",
            )
        # 開発・テスト環境では認証をスキップ（誤って本番で無効化しないよう警告）
        logger.warning("API_KEYS is not configured; skipping authentication (non-production).")
        return

    if not is_valid_api_key(api_key):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or missing API key.",
            headers={"WWW-Authenticate": API_KEY_HEADER_NAME},
        )
