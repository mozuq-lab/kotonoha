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
        from app.api.deps import get_db_session

        @app.post("/api/v1/ai/convert")
        async def convert_text(
            request: AIConversionRequest,
            db: AsyncSession = Depends(get_db_session)
        ):
            log = AIConversionLog.create_log(...)
            db.add(log)
            await db.commit()
            return {"success": True}
"""

import logging
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from starlette.exceptions import HTTPException

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


def get_session_maker() -> async_sessionmaker[AsyncSession]:
    """現在有効なセッションファクトリを返す。

    【この間接参照がある理由】: 依存性注入を経由しない箇所（例外ハンドラの
    エラーログ書き込み等）が `async_session_maker` をモジュール変数として
    直接参照すると、FastAPIの依存性オーバーライドが効かず、テスト実行中の
    書き込みが開発用DBへ飛んでしまう。DIを使えない箇所は本関数を経由し、
    テストは本関数を差し替えて書き込み先をテスト用DBへ向ける。

    Returns:
        async_sessionmaker[AsyncSession]: セッションファクトリ。
    """
    return async_session_maker


@asynccontextmanager
async def db_session_scope() -> AsyncIterator[AsyncSession]:
    """セッションの生成・commit/rollback・closeを一手に担うコンテキストマネージャ。

    【この関数がある理由】: 以前は本処理が `get_db()` の中に直接書かれており、
    `app.api.deps.get_db_session` が `async for session in get_db():` で
    ラップしていた。この形だと、エンドポイントが例外を投げたときに
    FastAPI が投げ込む例外は外側のジェネレータで止まり、内側の `get_db()` には
    伝播しない。内側は放置されて後から GeneratorExit で終了するため、
    `except Exception` の rollback とエラーログが**一度も実行されない**
    （close も遅延する）。セッション寿命を本コンテキストマネージャに集約し、
    利用側は `async with` で包むことで、例外が確実に本ブロックへ届くようにする。

    Yields:
        AsyncSession: 非同期データベースセッション。

    Raises:
        Exception: データベース操作中に発生した例外を、rollback後に再スローする。
    """
    # 【get_session_maker() を経由する理由】: 解決点を1つにしないと、
    # テストでの差し替えが一部の書き込み経路にしか効かない。
    async with get_session_maker()() as session:
        try:
            yield session
            await session.commit()
        except Exception as e:
            # 【rollback を守る理由】: DB障害時は rollback 自体も失敗する。
            # その例外が元の例外を置き換えると、エンドポイントが用意した
            # エラーレスポンス（例: /health の database="disconnected"）が
            # 汎用エラーに差し替わってしまう。
            try:
                await session.rollback()
            except Exception:
                logger.warning("セッションのロールバックに失敗した", exc_info=True)

            # 【HTTPException を DBエラーとして記録しない理由】: 例外が本スコープへ
            # 届くようになった結果、エンドポイントが投げる通常の 401/404/500 まで
            # "Database session error" として ERROR＋トレースバックで記録されてしまう。
            # /health は Docker の HEALTHCHECK が定期的に叩くため、DB障害時は
            # ハンドラ自身のエラーに加えて偽のERRORが延々と出て、ログベースの
            # アラートを誤らせる。HTTPException は「アプリが意図した応答」なので除く。
            if not isinstance(e, HTTPException):
                logger.error(
                    "Database session error: %s: %s",
                    type(e).__name__,
                    str(e),
                    exc_info=True,
                )
            raise
        # close は async_session_maker のコンテキストマネージャが行う
        # （ここで明示的に close すると二重になり、寿命の所有者が曖昧になる）
