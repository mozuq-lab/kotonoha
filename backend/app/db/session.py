"""データベースセッション管理モジュール。

SQLAlchemy 2.x の非同期エンジンとセッションメーカーを提供し、
FastAPIの依存性注入で使用するデータベースセッション管理を行う。

主な機能:
    - asyncpgドライバによる非同期PostgreSQL接続
    - 接続プール管理（NFR-005: 同時利用者数10人以下に対応）
    - FastAPI依存性注入用セッションジェネレータ

セキュリティ:
    環境変数からデータベース接続情報を読み込み、ハードコーディングを回避。

Example:
    FastAPIエンドポイントでの使用例::

        from fastapi import Depends
        from sqlalchemy.ext.asyncio import AsyncSession
        from app.db.session import get_db

        @app.post("/api/v1/ai/convert")
        async def convert_text(
            request: AIConversionRequest,
            db: AsyncSession = Depends(get_db)
        ):
            history = AIConversionHistory(...)
            db.add(history)
            await db.commit()
            return {"success": True}
"""

import logging
from collections.abc import AsyncGenerator

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.core.config import settings

# ============================================================================
# 接続プール設定定数
# ============================================================================

# 接続プールサイズ: NFR-005（同時利用者数10人以下）に対応
POOL_SIZE: int = 10

# 追加接続数: プールサイズを超えた場合の追加接続数
MAX_OVERFLOW: int = 10

# 接続再作成間隔（秒）: FR-001に基づき1時間で自動再作成
POOL_RECYCLE: int = 3600

# 接続取得タイムアウト（秒）: FR-001に基づき30秒
POOL_TIMEOUT: int = 30

# ============================================================================
# ロガー設定
# ============================================================================

logger = logging.getLogger(__name__)

# ============================================================================
# 非同期エンジン・セッションメーカー
# ============================================================================

engine = create_async_engine(
    settings.DATABASE_URL,
    echo=False,
    pool_pre_ping=True,
    pool_size=POOL_SIZE,
    max_overflow=MAX_OVERFLOW,
    pool_recycle=POOL_RECYCLE,
    pool_timeout=POOL_TIMEOUT,
)

async_session_maker = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """FastAPI依存性注入用のデータベースセッションジェネレータ。

    非同期ジェネレータでセッションを提供し、自動クリーンアップを実現する。
    正常終了時はcommit、例外発生時はrollbackを実行。

    Yields:
        AsyncSession: 非同期データベースセッション

    Raises:
        Exception: データベース操作中に発生した例外を再スロー

    Example:
        FastAPIエンドポイントでの使用::

            @app.post("/api/v1/ai/convert")
            async def convert_text(
                request: AIConversionRequest,
                db: AsyncSession = Depends(get_db)
            ):
                history = AIConversionHistory(...)
                db.add(history)
                # get_db()が自動的にcommitを実行
    """
    async with async_session_maker() as session:
        try:
            yield session
            await session.commit()
        except Exception as e:
            await session.rollback()
            logger.error(
                "Database session error: %s: %s",
                type(e).__name__,
                str(e),
                exc_info=True,
            )
            raise
        finally:
            await session.close()
