"""
データベースセッション管理モジュール

【機能概要】: SQLAlchemy 2.x の非同期エンジンとセッションメーカーを提供し、FastAPIの依存性注入で使用
【実装方針】: asyncpgドライバによる非同期PostgreSQL接続と接続プール管理を実現
【セキュリティ】: 環境変数からデータベース接続情報を読み込み、ハードコーディングを回避
【パフォーマンス】: 接続プール（サイズ10）により、同時利用者数10人以下の要件に対応
【テスト対応】: test_db_connection.pyのテストケースを通すための実装
🔵 この実装は要件定義書（line 67-75）とNFR-005、NFR-105に基づく

Example:
    FastAPIエンドポイントでの使用例:
    ```python
    from fastapi import Depends
    from sqlalchemy.ext.asyncio import AsyncSession
    from app.db.session import get_db

    @app.post("/api/v1/ai/convert")
    async def convert_text(
        request: AIConversionRequest,
        db: AsyncSession = Depends(get_db)
    ):
        # データベース操作
        history = AIConversionHistory(...)
        db.add(history)
        await db.commit()
        return {"success": True}
    ```
"""

from collections.abc import AsyncGenerator

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.core.config import settings

# 【非同期エンジン作成】: PostgreSQL非同期接続エンジンを作成
# 【実装方針】: asyncpgドライバを使用し、非同期データベース操作を実現
# 【テスト対応】: C-1（データベース接続テスト）を通すための実装
# 🔵 要件定義書（line 67-75）、tech-stack.md（line 56-87）に基づく
engine = create_async_engine(
    settings.DATABASE_URL,
    echo=False,  # 【SQL出力制御】: 本番環境ではFalse、開発時はTrueに変更可能
    pool_pre_ping=True,  # 【接続プール健全性チェック】: 接続の有効性を確認してから使用
    pool_size=10,  # 【接続プールサイズ】: 最大10接続（NFR-005: 同時利用者数10人以下に対応）
    max_overflow=10,  # 【追加接続数】: プールサイズを超えた場合の追加接続数
)

# 【非同期セッションメーカー作成】: 非同期セッションを生成するファクトリ
# 【実装方針】: async_sessionmakerを使用し、セッション生成を効率化
# 【テスト対応】: すべてのCRUD操作テスト（カテゴリC）を通すための実装
# 🔵 要件定義書（line 67-75）に基づく
async_session_maker = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,  # 【コミット後の有効性】: コミット後もオブジェクトにアクセス可能
    autocommit=False,  # 【自動コミット無効】: 明示的なコミットを要求
    autoflush=False,  # 【自動フラッシュ無効】: 明示的なフラッシュを要求
)


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """
    【機能概要】: FastAPI依存性注入用のデータベースセッションジェネレータ
    【実装方針】: 非同期ジェネレータでセッションを提供し、自動クリーンアップを実現
    【テスト対応】: FastAPIエンドポイントでの使用を想定（TASK-0009以降で使用）
    🔵 要件定義書（line 204-229）に基づく使用パターン

    Yields:
        AsyncSession: 非同期データベースセッション

    Example:
        ```python
        @app.post("/api/v1/ai/convert")
        async def convert_text(
            request: AIConversionRequest,
            db: AsyncSession = Depends(get_db)
        ):
            # dbセッションを使用したデータベース操作
            history = AIConversionHistory(...)
            db.add(history)
            await db.commit()
        ```
    """
    # 【セッション生成】: 非同期セッションを作成
    # 【リソース管理】: async withブロックで自動クリーンアップを保証
    async with async_session_maker() as session:
        try:
            # 【セッション提供】: FastAPIエンドポイントにセッションを提供
            yield session
        finally:
            # 【セッションクローズ】: 処理完了後、セッションを適切にクローズ
            # 【リソースリーク防止】: エラー発生時も確実にクローズ
            await session.close()
