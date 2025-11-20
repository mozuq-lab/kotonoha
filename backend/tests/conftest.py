"""
pytestテスト設定ファイル

テスト用のフィクスチャとセットアップを定義する。

【実装方針】: pytest-asyncio 0.25.x の推奨パターンに従い、各テストで独立したイベントループを使用
【セキュリティ】: テスト用データベースと本番データベースを分離し、データ漏洩を防止
🔵 この実装は要件定義書（line 67-75）とpytest-asyncio公式ドキュメントに基づく
"""

import os
from collections.abc import AsyncGenerator

import pytest
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

# 【テスト前準備】: テスト用のデータベース接続URLを環境変数から取得
# 【環境初期化】: 本番環境とは異なるテストデータベースを使用し、データの分離を保証
# 【セキュリティ】: 本番データベースへの誤接続を防ぐため、明示的にテストDB URLを指定
# 🔵 NFR-105（環境変数をアプリ内にハードコードせず、安全に管理）に基づく
TEST_DATABASE_URL = os.getenv(
    "TEST_DATABASE_URL",
    "postgresql+asyncpg://kotonoha_user:your_secure_password_here@localhost:5432/kotonoha_test"
)


@pytest.fixture(scope="function")
async def test_engine():
    """
    テスト用の非同期エンジンを作成（各テスト関数ごとに作成）

    【テスト目的】: テスト用データベースへの接続エンジンを提供
    【テスト内容】: SQLAlchemy 2.x の非同期エンジンを作成し、テスト完了後にクリーンアップ
    【期待される動作】: テストデータベースに接続し、セッション作成の基盤を提供
    【実装方針】: 各テストごとにエンジンを作成・破棄し、イベントループ問題を回避
    🔵 この内容は要件定義書（line 67-75）に基づく

    Yields:
        AsyncEngine: テスト用の非同期データベースエンジン
    """
    # 【テストデータ準備】: テスト用データベース接続エンジンを作成
    # 【初期条件設定】: echo=False でSQL出力を抑制（必要に応じてTrueに変更可能）
    # 【パフォーマンス最適化】: pool_size=5 で接続プールを制限（テスト環境では少数で十分）
    engine = create_async_engine(
        TEST_DATABASE_URL,
        echo=False,
        pool_pre_ping=True,  # 【接続健全性チェック】: 接続の有効性を確認してから使用
        pool_size=5,  # 【接続プールサイズ】: テスト用に小さめに設定
        max_overflow=5,  # 【追加接続数】: 必要に応じて追加接続を許可
    )

    yield engine

    # 【テスト後処理】: エンジンとすべての接続を適切にクローズ
    # 【リソースリーク防止】: イベントループクローズ前に接続プールをクリーンアップ
    # 🔵 SQLAlchemy 2.x の推奨クリーンアップ手順
    await engine.dispose()


@pytest.fixture(scope="function")
async def test_session_maker(test_engine):
    """
    テスト用のセッションメーカーを作成

    【テスト目的】: 各テストケースで使用するセッションファクトリを提供
    【テスト内容】: async_sessionmakerを作成し、テストセッションの生成を可能にする
    【期待される動作】: テスト用のデータベースセッションを生成できる
    【実装方針】: test_engineに依存し、エンジンのライフサイクルと同期
    🔵 この内容は要件定義書（line 67-75）に基づく

    Returns:
        async_sessionmaker: テストセッション生成ファクトリ
    """
    # 【テストデータ準備】: セッションメーカーを作成
    # 【初期条件設定】: expire_on_commit=False でコミット後もオブジェクトにアクセス可能
    session_maker = async_sessionmaker(
        bind=test_engine,
        class_=AsyncSession,
        expire_on_commit=False,
        autocommit=False,
        autoflush=False,
    )
    return session_maker


@pytest.fixture(scope="function")
async def db_session(test_session_maker) -> AsyncGenerator[AsyncSession, None]:
    """
    各テストケース用のデータベースセッションを作成

    【テスト目的】: 各テストケースに独立したデータベースセッションを提供
    【テスト内容】: セッションを作成し、テスト完了後にロールバック
    【期待される動作】: テスト間のデータ分離を保証し、各テストが独立して実行される
    【実装方針】: トランザクションをロールバックすることで、テストデータをクリーンアップ
    🔵 この内容は要件定義書（line 180-188）に基づく

    Yields:
        AsyncSession: テスト用の非同期データベースセッション
    """
    # 【テスト前準備】: 新しいセッションを作成
    # 【環境初期化】: テスト用のクリーンなセッションを提供
    async with test_session_maker() as session:
        yield session
        # 【テスト後処理】: テスト完了後、トランザクションをロールバック
        # 【状態復元】: テストで作成されたデータをすべて破棄し、次のテストに影響しないようにする
        await session.rollback()
        # 【セッションクローズ】: セッションを明示的にクローズ
        await session.close()
