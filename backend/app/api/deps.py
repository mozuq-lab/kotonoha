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

from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db


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
