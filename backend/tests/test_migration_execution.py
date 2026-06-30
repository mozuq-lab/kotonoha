"""
TASK-0009: 初回マイグレーション実行・DB接続テスト

カテゴリB: マイグレーション実行テスト
カテゴリE: データベース接続テスト
"""

from sqlalchemy import text

# ================================================================================
# カテゴリB: マイグレーション実行テスト
# ================================================================================


async def test_alembic_upgrade_head_success(db_session):
    """
    B-1. 初回マイグレーション実行が成功する

    【テスト目的】: alembic upgrade head コマンドが正常に完了することを確認
    【テスト内容】: マイグレーション実行後、alembic_versionテーブルにリビジョンが記録されること
    【期待される動作】: マイグレーションがエラーなく実行され、リビジョンが記録される
    🔵 この内容は要件定義書（line 60-69, line 169-183）とテストケース仕様書（line 122-138）に基づく
    """
    # 【実際の処理実行】: alembic_versionテーブルからリビジョンIDを取得
    # 【処理内容】: マイグレーションが実行された証拠を確認
    result = await db_session.execute(text("SELECT version_num FROM alembic_version"))
    version = result.scalar()

    # 【検証項目】: リビジョンIDが記録されているか
    # 🔵 要件定義書（line 68）に基づくマイグレーション成功の検証
    assert version is not None  # 【確認内容】: リビジョンIDが記録されている
    assert isinstance(version, str)  # 【確認内容】: リビジョンIDが文字列型である


async def test_alembic_version_table_updated(db_session):
    """
    B-2. マイグレーション実行後にalembic_versionテーブルにリビジョンが記録される

    【テスト目的】: alembic_versionテーブルに最新のリビジョンが記録されることを確認
    【テスト内容】: alembic_versionテーブルのレコード数が1件であること
    【期待される動作】: 最新のリビジョンIDが1行だけ記録される
    🔵 この内容は要件定義書（line 68, line 299-304）とテストケース仕様書（line 140-154）に基づく
    """
    # 【実際の処理実行】: alembic_versionテーブルのレコード数を取得
    # 【処理内容】: Alembicがリビジョン管理に使用する内部テーブルの確認
    result = await db_session.execute(text("SELECT COUNT(*) FROM alembic_version"))
    count = result.scalar()

    # 【検証項目】: alembic_versionテーブルのレコード数が1件であるか
    # 🔵 要件定義書（line 68, line 299-304）に基づくリビジョン管理の検証
    assert count == 1  # 【確認内容】: リビジョンが正確に1件記録されている


# ================================================================================
# カテゴリE: データベース接続テスト
# ================================================================================


async def test_session_begin_transaction_after_migration(db_session):
    """
    E-2. トランザクション開始機能が正常に動作する（マイグレーション後）

    【テスト目的】: マイグレーション後、セッションのトランザクション開始機能が正常に動作することを確認
    【テスト内容】: async with session.begin()でトランザクションブロックが正常に動作する
    【期待される動作】: トランザクションが正常に開始され、クエリを実行できる
    🔵 この内容は要件定義書（line 253-262）とテストケース仕様書（line 337-351）に基づく
    """
    # 【実際の処理実行】: トランザクションを開始
    # 【処理内容】: async with session.begin()でトランザクションブロックを作成
    async with db_session.begin():
        # 【検証項目】: トランザクションブロック内でクエリが実行できるか
        # 🔵 要件定義書（line 253-262）に基づくトランザクション管理の検証
        result = await db_session.execute(text("SELECT 1"))
        value = result.scalar()
        assert value == 1  # 【確認内容】: クエリが正常に実行される

    # 【結果検証】: トランザクションブロックが正常に終了したことを確認
    # トランザクションブロックを抜けた時点でコミット済み
