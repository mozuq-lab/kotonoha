"""
FastAPI依存性注入モジュール

【機能概要】: エンドポイントで使用する共通の依存性を提供
【実装方針】: データベースセッション、認証、その他の共通依存性を集約管理
"""

from typing import AsyncGenerator

from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db


async def get_db_session() -> AsyncGenerator[AsyncSession, None]:
    """
    【機能概要】: データベースセッションを取得する依存性関数
    【実装方針】: get_db関数をラップして、依存性注入で使用可能にする

    Yields:
        AsyncSession: 非同期データベースセッション
    """
    async for session in get_db():
        yield session
