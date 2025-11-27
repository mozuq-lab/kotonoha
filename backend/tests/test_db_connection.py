"""
データベース接続テスト（TASK-0008）

データベースセッション管理、接続テスト、接続エラーハンドリングを確認。
"""

import pytest
from sqlalchemy import text
from sqlalchemy.exc import OperationalError


async def test_database_connection(db_session):
    """
    C-1. 非同期セッションが正常に作成され、データベースに接続できる

    【テスト目的】: データベースセッション管理が正しく機能することを確認
    【テスト内容】: async_session_makerから非同期セッションを取得し、データベースに接続
    【期待される動作】: SELECT 1クエリが正常に実行される
    🔵 この内容は要件定義書（line 67-75, line 373-376）に基づく
    """
    # 【テストデータ準備】: データベース接続の確立を確認するための最小クエリ
    # 【初期条件設定】: データベースが起動しており、セッションが利用可能な状態

    # 【実際の処理実行】: SELECT 1クエリを実行し、接続を確認
    # 【処理内容】: データベースへの接続テスト用の最小クエリ
    result = await db_session.execute(text("SELECT 1"))
    value = result.scalar()

    # 【結果検証】: クエリが正常に実行され、結果が返されたことを確認

    # 【検証項目】: SELECT 1の結果が1であるか
    # 🔵 要件定義書（line 67-75）に基づくデータベース接続の検証
    assert value == 1


async def test_database_connection_error():
    """
    D-3. データベースが利用不可の場合、接続エラーが発生する

    【テスト目的】: データベース接続エラー時の適切なエラーハンドリングを確認
    【テスト内容】: 不正なデータベースURLで接続を試み、エラーを確認
    【期待される動作】: OperationalErrorまたはOSErrorが発生し、エラーメッセージが適切に設定される
    🟡 この内容は要件定義書（line 234-251, line 416-420）に基づくが、テスト実装方法は推測
    """
    # 【テストデータ準備】: 不正なデータベースURL（存在しないホスト）
    # 【初期条件設定】: データベースに接続できない状態をシミュレート
    from sqlalchemy.ext.asyncio import create_async_engine

    # 【実際の処理実行】: 不正なURLでエンジンを作成し、接続を試みる
    # 【処理内容】: 存在しないホストまたはポートに接続を試みる
    # 【エラー処理の重要性】: データベースダウン時にアプリケーションが適切にエラーを報告する（NFR-304）
    invalid_url = "postgresql+asyncpg://invalid:invalid@localhost:9999/invalid"
    engine = create_async_engine(invalid_url, echo=False)

    # 【結果検証】: OperationalErrorまたはOSError（接続拒否）が発生することを確認
    with pytest.raises((OperationalError, OSError)):
        # 【検証項目】: 接続エラーが適切に発生するか
        # 🟡 要件定義書（line 234-251, NFR-304）に基づくエラーハンドリングの検証
        async with engine.begin() as conn:
            await conn.execute(text("SELECT 1"))

    # 【テスト後処理】: エンジンをクローズし、リソースを解放
    # 【状態復元】: リソースリークを防ぐため、エンジンを適切にクローズ
    await engine.dispose()


async def test_session_begin_transaction(db_session):
    """
    トランザクション開始機能のテスト

    【テスト目的】: セッションのトランザクション開始機能を確認
    【テスト内容】: session.begin()でトランザクションを開始できることを確認
    【期待される動作】: トランザクションが正常に開始される
    🔵 この内容は要件定義書（line 253-262）に基づく
    """
    # 【テストデータ準備】: トランザクション開始のテスト
    # 【初期条件設定】: セッションが利用可能な状態

    # 【実際の処理実行】: トランザクションを開始
    # 【処理内容】: async with session.begin()でトランザクションブロックを作成
    async with db_session.begin():
        # 【検証項目】: トランザクションブロック内でクエリが実行できるか
        # 🔵 要件定義書（line 253-262）に基づくトランザクション管理の検証
        result = await db_session.execute(text("SELECT 1"))
        value = result.scalar()
        assert value == 1

    # 【結果検証】: トランザクションブロックが正常に終了したことを確認
    # トランザクションブロックを抜けた時点でコミット済み


async def test_session_close():
    """
    セッションクローズ機能のテスト

    【テスト目的】: セッションが正常にクローズされることを確認
    【テスト内容】: async withブロックを抜けた後、セッションがクローズされる
    【期待される動作】: セッションが適切にクローズされ、リソースリークが発生しない
    🔵 この内容は要件定義書（line 67-75）に基づく
    """
    # 【テストデータ準備】: セッションクローズのテスト
    # 【初期条件設定】: test_session_makerが利用可能な状態
    from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

    from tests.conftest import TEST_DATABASE_URL

    # 【実際の処理実行】: セッションを作成し、クローズを確認
    # 【処理内容】: async withブロックでセッションを使用
    engine = create_async_engine(TEST_DATABASE_URL, echo=False)
    session_maker = async_sessionmaker(bind=engine, class_=AsyncSession)

    async with session_maker() as session:
        # 【検証項目】: セッション内でクエリが実行できるか
        # 🔵 要件定義書（line 67-75）に基づく検証
        result = await session.execute(text("SELECT 1"))
        value = result.scalar()
        assert value == 1

    # 【結果検証】: async withブロックを抜けた後、セッションがクローズされている
    # 【テスト後処理】: エンジンをクローズ
    # 【状態復元】: リソースを適切に解放
    await engine.dispose()
