"""
TASK-0009: 初回マイグレーション実行・DB接続テスト（Redフェーズ）

カテゴリB: マイグレーション実行テスト
カテゴリC: テーブル作成確認テスト
カテゴリD: マイグレーションロールバックテスト

このファイルは失敗するテストケースを含んでいます（Redフェーズ）。
"""

import pytest
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
    # 【テストデータ準備】: alembic_versionテーブルの存在を確認
    # 【初期条件設定】: マイグレーションが実行済みの状態
    # 【前提条件確認】: PostgreSQLデータベースが起動していること

    # 【実際の処理実行】: alembic_versionテーブルからリビジョンIDを取得
    # 【処理内容】: マイグレーションが実行された証拠を確認
    result = await db_session.execute(
        text("SELECT version_num FROM alembic_version")
    )
    version = result.scalar()

    # 【結果検証】: リビジョンIDが記録されていることを確認
    # 【期待値確認】: version_numが存在し、文字列型であること
    # 【品質保証】: マイグレーション履歴が正しく管理されていることを保証

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
    # 【テストデータ準備】: マイグレーション実行後のデータベース状態
    # 【初期条件設定】: alembic_versionテーブルが存在すること

    # 【実際の処理実行】: alembic_versionテーブルのレコード数を取得
    # 【処理内容】: Alembicがリビジョン管理に使用する内部テーブルの確認
    result = await db_session.execute(
        text("SELECT COUNT(*) FROM alembic_version")
    )
    count = result.scalar()

    # 【結果検証】: リビジョンが1件だけ記録されていることを確認
    # 【期待値確認】: Alembicはリビジョンを1行のみ保持する仕様

    # 【検証項目】: alembic_versionテーブルのレコード数が1件であるか
    # 🔵 要件定義書（line 68, line 299-304）に基づくリビジョン管理の検証
    assert count == 1  # 【確認内容】: リビジョンが正確に1件記録されている


# ================================================================================
# カテゴリC: テーブル作成確認テスト
# ================================================================================


async def test_ai_conversion_history_table_exists(db_session):
    """
    C-1. ai_conversion_historyテーブルが作成される

    【テスト目的】: マイグレーション実行後、ai_conversion_historyテーブルが存在することを確認
    【テスト内容】: information_schema.tablesから該当テーブルが検出されること
    【期待される動作】: テーブルが正常に作成されている
    🔵 この内容は要件定義書（line 82-89, line 397-398）とテストケース仕様書（line 158-173）に基づく
    """
    # 【テストデータ準備】: テーブル名 "ai_conversion_history"
    # 【初期条件設定】: マイグレーションが実行済みの状態
    # 【前提条件確認】: PostgreSQLのメタデータカタログにアクセス可能

    # 【実際の処理実行】: information_schema.tablesからテーブルを検索
    # 【処理内容】: PostgreSQLのメタデータカタログを使用してテーブル存在確認
    result = await db_session.execute(
        text("""
            SELECT EXISTS (
                SELECT 1 FROM information_schema.tables
                WHERE table_schema = 'public'
                AND table_name = 'ai_conversion_history'
            )
        """)
    )
    table_exists = result.scalar()

    # 【結果検証】: テーブルが存在することを確認
    # 【期待値確認】: マイグレーションによりテーブルが正常に作成される
    # 【品質保証】: テーブル作成が設計通りに実装されていることを保証

    # 【検証項目】: ai_conversion_historyテーブルが実際に存在するか
    # 🔵 要件定義書（line 82-89, line 397-398）に基づくテーブル作成の検証
    assert table_exists is True  # 【確認内容】: ai_conversion_historyテーブルが正常に作成されている


async def test_ai_conversion_history_table_has_all_columns(db_session):
    """
    C-2. ai_conversion_historyテーブルに必須カラムがすべて存在する

    【テスト目的】: テーブルに必要なすべてのカラムが作成されていることを確認
    【テスト内容】: information_schema.columnsから7つのカラムが検出されること
    【期待される動作】: 設計書に定義された7つのカラムが存在する
    🔵 この内容は要件定義書（line 52-66）とテストケース仕様書（line 175-190）に基づく
    """
    # 【テストデータ準備】: 期待されるカラム名のリスト
    # 【初期条件設定】: ai_conversion_historyテーブルが作成済み
    expected_columns = {
        "id",
        "input_text",
        "converted_text",
        "politeness_level",
        "created_at",
        "conversion_time_ms",
        "user_session_id",
    }

    # 【実際の処理実行】: information_schema.columnsからカラム名を取得
    # 【処理内容】: データベーススキーマ定義と一致するか確認
    result = await db_session.execute(
        text("""
            SELECT column_name FROM information_schema.columns
            WHERE table_schema = 'public'
            AND table_name = 'ai_conversion_history'
        """)
    )
    actual_columns = {row[0] for row in result.fetchall()}

    # 【結果検証】: すべてのカラムが存在することを確認
    # 【期待値確認】: モデル定義がデータベーススキーマに正しく反映される
    # 【品質保証】: テーブル構造が設計書通りに作成されていることを保証

    # 【検証項目】: 期待されるすべてのカラムが存在するか
    # 🔵 要件定義書（line 52-66）とdatabase-schema.sql（line 36-51）に基づく検証
    assert expected_columns == actual_columns  # 【確認内容】: カラム名とカラム数が設計書と一致している


async def test_ai_conversion_history_table_column_types(db_session):
    """
    C-3. ai_conversion_historyテーブルのカラムに正しいデータ型が設定されている

    【テスト目的】: 各カラムのデータ型がdatabase-schema.sqlの定義と一致することを確認
    【テスト内容】: information_schema.columnsから各カラムのデータ型を取得し、検証
    【期待される動作】: すべてのカラムが期待通りのデータ型で作成されている
    🔵 この内容はdatabase-schema.sql（line 37-51）とテストケース仕様書（line 192-212）に基づく
    """
    # 【テストデータ準備】: 期待されるデータ型の定義
    # 【初期条件設定】: ai_conversion_historyテーブルが作成済み
    expected_types = {
        "id": "integer",
        "input_text": "text",
        "converted_text": "text",
        "politeness_level": "USER-DEFINED",  # Enum型はPostgreSQLでCUSTOM ENUMタイプ（USER-DEFINED）として実装される
        "created_at": "timestamp with time zone",
        "conversion_time_ms": "integer",
        "user_session_id": "uuid",
    }

    # 【実際の処理実行】: 各カラムのデータ型を取得
    # 【処理内容】: PostgreSQLのデータ型定義を確認
    result = await db_session.execute(
        text("""
            SELECT column_name, data_type
            FROM information_schema.columns
            WHERE table_schema = 'public'
            AND table_name = 'ai_conversion_history'
        """)
    )
    actual_types = {row[0]: row[1] for row in result.fetchall()}

    # 【結果検証】: すべてのカラムが期待通りのデータ型であることを確認
    # 【期待値確認】: SQLAlchemyモデルの型定義がデータベースに正しく反映される
    # 【品質保証】: データ型定義が正確に実装されていることを保証

    # 【検証項目】: 各カラムのデータ型が期待値と一致するか
    # 🔵 database-schema.sql（line 37-51）とAIConversionHistoryモデル定義に基づく検証
    for column, expected_type in expected_types.items():
        assert column in actual_types  # 【確認内容】: カラムが存在する
        assert actual_types[column] == expected_type  # 【確認内容】: データ型が設計書と一致する


async def test_ai_conversion_history_not_null_constraints(db_session):
    """
    C-4. ai_conversion_historyテーブルにNOT NULL制約が正しく設定されている

    【テスト目的】: 必須カラムにNOT NULL制約が設定されていることを確認
    【テスト内容】: information_schema.columnsのis_nullableカラムから制約を確認
    【期待される動作】: 必須フィールドにはNOT NULL制約が設定されている
    🔵 この内容は要件定義書（line 122, line 146）とテストケース仕様書（line 214-229）に基づく
    """
    # 【テストデータ準備】: NOT NULL制約が必要なカラムのリスト
    # 【初期条件設定】: ai_conversion_historyテーブルが作成済み
    not_null_columns = {"id", "input_text", "converted_text", "politeness_level", "created_at"}
    nullable_columns = {"conversion_time_ms", "user_session_id"}

    # 【実際の処理実行】: is_nullableカラムから制約を取得
    # 【処理内容】: データベース制約の検証
    result = await db_session.execute(
        text("""
            SELECT column_name, is_nullable
            FROM information_schema.columns
            WHERE table_schema = 'public'
            AND table_name = 'ai_conversion_history'
        """)
    )
    nullability = {row[0]: row[1] for row in result.fetchall()}

    # 【結果検証】: NOT NULL制約が正しく設定されていることを確認
    # 【期待値確認】: モデル定義のnullable=False/Trueが正しく反映される
    # 【品質保証】: データ整合性制約が正しく実装されていることを保証

    # 【検証項目】: NOT NULL制約が必要なカラムがNOであるか
    # 🔵 要件定義書（line 122, line 146）とdatabase-schema.sql（line 37-51）に基づく検証
    for column in not_null_columns:
        assert nullability[column] == "NO"  # 【確認内容】: NOT NULL制約が設定されている

    # 【検証項目】: NULL許可カラムがYESであるか
    for column in nullable_columns:
        assert nullability[column] == "YES"  # 【確認内容】: NULL許可である


async def test_ai_conversion_history_primary_key(db_session):
    """
    C-5. ai_conversion_historyテーブルに主キー制約が設定されている

    【テスト目的】: idカラムに主キー制約が設定されていることを確認
    【テスト内容】: information_schema.table_constraintsから主キー制約が検出されること
    【期待される動作】: idカラムがPRIMARY KEYとして定義されている
    🔵 この内容は要件定義書（line 124）とテストケース仕様書（line 231-246）に基づく
    """
    # 【テストデータ準備】: テーブル名 "ai_conversion_history"
    # 【初期条件設定】: ai_conversion_historyテーブルが作成済み

    # 【実際の処理実行】: 主キー制約の存在を確認
    # 【処理内容】: 主キー制約の検証
    result = await db_session.execute(
        text("""
            SELECT EXISTS (
                SELECT 1 FROM information_schema.table_constraints
                WHERE table_schema = 'public'
                AND table_name = 'ai_conversion_history'
                AND constraint_type = 'PRIMARY KEY'
            )
        """)
    )
    has_primary_key = result.scalar()

    # 【結果検証】: 主キー制約が存在することを確認
    # 【期待値確認】: モデル定義のprimary_key=Trueが正しく反映される
    # 【品質保証】: 主キー制約が正しく設定されていることを保証

    # 【検証項目】: 主キー制約が存在するか
    # 🔵 要件定義書（line 124）とdatabase-schema.sql（line 37）に基づく検証
    assert has_primary_key is True  # 【確認内容】: 主キー制約が存在する


async def test_ai_conversion_history_indexes_created(db_session):
    """
    C-6. ai_conversion_historyテーブルにインデックスが作成されている

    【テスト目的】: created_atとuser_session_idにインデックスが作成されていることを確認
    【テスト内容】: pg_indexesビューから2つのインデックスが検出されること
    【期待される動作】: パフォーマンス最適化のためのインデックスが作成されている
    🔵 この内容は要件定義書（line 126-128）とテストケース仕様書（line 248-265）に基づく
    """
    # 【テストデータ準備】: 期待されるインデックス名
    # 【初期条件設定】: ai_conversion_historyテーブルが作成済み
    expected_indexes = {
        "idx_ai_conversion_created_at",
        "idx_ai_conversion_session",
    }

    # 【実際の処理実行】: pg_indexesビューからインデックス名を取得
    # 【処理内容】: パフォーマンス最適化のためのインデックス検証
    result = await db_session.execute(
        text("""
            SELECT indexname FROM pg_indexes
            WHERE tablename = 'ai_conversion_history'
            AND schemaname = 'public'
            AND indexname LIKE 'idx_%'
        """)
    )
    actual_indexes = {row[0] for row in result.fetchall()}

    # 【結果検証】: 期待されるインデックスが作成されていることを確認
    # 【期待値確認】: database-schema.sqlで定義されたインデックスが正しく作成される
    # 【品質保証】: インデックス作成が正しく実装されていることを保証

    # 【検証項目】: 期待されるインデックスが存在するか
    # 🔵 要件定義書（line 126-128）とdatabase-schema.sql（line 54-68）に基づく検証
    assert expected_indexes.issubset(actual_indexes)  # 【確認内容】: すべてのインデックスが作成されている


# ================================================================================
# カテゴリD: マイグレーションロールバックテスト
# ================================================================================


async def test_table_deleted_after_downgrade(db_session):
    """
    D-2. ロールバック後にai_conversion_historyテーブルが削除される（スキップ）

    【テスト目的】: ロールバック後、テーブルがデータベースから削除されることを確認
    【テスト内容】: この テストは実際にはスキップされます（ロールバックはE2Eテストで確認）
    【期待される動作】: このテストは未実装のためスキップされる
    🟡 この内容は要件定義書（line 72-79, line 410-413）とテストケース仕様書（line 287-300）に基づく
    """
    # 【テストスキップの理由】: ロールバックテストは別途E2Eテストで実施するため
    pytest.skip("ロールバックテストは別途E2Eテストで実施")


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
    # 【テストデータ準備】: トランザクション開始のテスト
    # 【初期条件設定】: マイグレーション実行後のデータベース状態

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
