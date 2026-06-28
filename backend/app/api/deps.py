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

from collections.abc import AsyncGenerator

from fastapi import HTTPException, Security, status
from fastapi.security import APIKeyHeader
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.db.session import get_db

api_key_header = APIKeyHeader(name="X-API-Key", auto_error=False)


async def verify_api_key(api_key: str | None = Security(api_key_header)) -> None:
    """X-API-Key ヘッダーを検証する依存性。

    Raises:
        HTTPException: API_KEY 未設定時は 503、キー不一致/欠如時は 401。
    """
    if not settings.API_KEY:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="AI endpoint is disabled: API_KEY is not configured.",
        )
    if api_key != settings.API_KEY:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or missing API key.",
        )


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
