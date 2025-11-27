"""
TASK-0009: 初回マイグレーション実行・DB接続テスト（Redフェーズ）

カテゴリF: CRUD操作テスト（統合テスト）

このファイルは失敗するテストケースを含んでいます（Redフェーズ）。
マイグレーション後のテーブルに対するCRUD操作を検証します。
"""

from uuid import uuid4

from sqlalchemy import select

# ================================================================================
# カテゴリF: CRUD操作テスト（統合テスト）
# ================================================================================


async def test_insert_record_after_migration(db_session):
    """
    F-1. マイグレーション後のテーブルにレコードを挿入できる

    【テスト目的】: マイグレーション実行後、ai_conversion_historyテーブルにレコードを挿入できることを確認
    【テスト内容】: AIConversionHistoryモデルを使用してレコードを作成し、データベースに保存できる
    【期待される動作】: レコードが正常に保存され、idとcreated_atが自動生成される
    🔵 この内容は要件定義書（line 92-106, line 380-382）とテストケース仕様書（line 355-378）に基づく
    """
    # 【テストデータ準備】: 実際のユースケースを想定した日本語テキスト
    # 【初期条件設定】: マイグレーションが実行済みで、ai_conversion_historyテーブルが存在する
    # 【前提条件確認】: AIConversionHistoryモデルとPolitenessLevel Enumがインポート可能
    from app.models.ai_conversion_history import AIConversionHistory, PolitenessLevel

    # 【実際の処理実行】: レコードを作成しデータベースに保存
    # 【処理内容】: session.add()とsession.commit()でデータベースに保存
    # 【実行タイミング】: マイグレーション後の最初のデータ挿入テスト
    record = AIConversionHistory(
        input_text="ありがとう",
        converted_text="ありがとうございます",
        politeness_level=PolitenessLevel.POLITE,
        conversion_time_ms=100,
        user_session_id=uuid4(),
    )

    db_session.add(record)
    await db_session.commit()
    await db_session.refresh(record)

    # 【結果検証】: レコードが正常に保存され、自動生成フィールドが設定されたことを確認
    # 【期待値確認】: マイグレーションにより作成されたテーブルが正常にCRUD操作を受け付ける
    # 【品質保証】: マイグレーション後のテーブルが正常に動作することを保証

    # 【検証項目】: idが自動生成されているか（Integerの正の値）
    # 🔵 要件定義書（line 54）に基づく自動生成フィールドの検証
    assert record.id is not None  # 【確認内容】: idが自動生成されている
    assert isinstance(record.id, int)  # 【確認内容】: idがint型である
    assert record.id > 0  # 【確認内容】: idが正の値である

    # 【検証項目】: created_atが自動設定されているか（datetime型）
    # 🔵 要件定義書（line 58）に基づく自動生成タイムスタンプの検証
    from datetime import datetime

    assert record.created_at is not None  # 【確認内容】: created_atが自動設定されている
    assert isinstance(record.created_at, datetime)  # 【確認内容】: created_atがdatetime型である


async def test_query_inserted_record_after_migration(db_session):
    """
    F-2. 挿入したレコードを検索できる

    【テスト目的】: 挿入したレコードをSELECTクエリで取得できることを確認
    【テスト内容】: 挿入したレコードのIDで検索し、すべてのフィールド値が一致する
    【期待される動作】: 保存したデータと一致するレコードが取得できる
    🔵 この内容は要件定義書（line 189-202, line 384-386）とテストケース仕様書（line 380-394）に基づく
    """
    # 【テストデータ準備】: データベースに事前保存するテストデータ
    # 【初期条件設定】: マイグレーションが実行済みで、ai_conversion_historyテーブルが存在する
    from app.models.ai_conversion_history import AIConversionHistory, PolitenessLevel

    # 【実際の処理実行】: レコードを保存
    # 【処理内容】: 検索対象のレコードをデータベースに挿入
    record = AIConversionHistory(
        input_text="お水ください",
        converted_text="お水をいただけますか",
        politeness_level=PolitenessLevel.NORMAL,
    )
    db_session.add(record)
    await db_session.commit()
    await db_session.refresh(record)

    saved_id = record.id

    # 【実際の処理実行】: 保存したレコードをクエリで取得
    # 【処理内容】: SQLAlchemy 2.x のselect文で検索
    # 【実行タイミング】: 挿入直後に検索を実行し、データ整合性を確認
    result = await db_session.execute(
        select(AIConversionHistory).where(AIConversionHistory.id == saved_id)
    )
    retrieved_record = result.scalar_one()

    # 【結果検証】: 取得したレコードが保存した値と一致することを確認
    # 【期待値確認】: データベースに正しくデータが保存されている
    # 【品質保証】: CRUD操作のRead（読み取り）が正常に動作することを保証

    # 【検証項目】: 取得したレコードのIDが一致するか
    # 🔵 要件定義書（line 189-202）に基づく検証
    assert retrieved_record.id == saved_id  # 【確認内容】: IDが一致する

    # 【検証項目】: input_textが一致するか
    # 🔵 要件定義書（line 54）に基づく検証
    assert retrieved_record.input_text == "お水ください"  # 【確認内容】: input_textが一致する

    # 【検証項目】: converted_textが一致するか
    # 🔵 要件定義書（line 55）に基づく検証
    assert retrieved_record.converted_text == "お水をいただけますか"  # 【確認内容】: converted_textが一致する

    # 【検証項目】: politeness_levelが一致するか
    # 🔵 要件定義書（line 57）に基づく検証
    assert retrieved_record.politeness_level == PolitenessLevel.NORMAL  # 【確認内容】: politeness_levelが一致する


async def test_insert_multiple_records_and_sort_by_created_at(db_session):
    """
    F-3. 複数レコードを挿入し、created_atの降順でソートできる

    【テスト目的】: 複数レコードを挿入し、created_at DESCでソートできることを確認
    【テスト内容】: 3件のレコードを時系列順に挿入し、最新のレコードが先頭に並ぶことを確認
    【期待される動作】: 最新のレコードが先頭に並ぶ
    🔵 この内容は要件定義書（line 149, line 189-202）とテストケース仕様書（line 396-410）に基づく
    """
    # 【テストデータ準備】: ソート機能を確認するための時系列データ
    # 【初期条件設定】: マイグレーションが実行済みで、ai_conversion_historyテーブルが存在する
    from app.models.ai_conversion_history import AIConversionHistory, PolitenessLevel

    # 【実際の処理実行】: 3件のレコードを順番に作成
    # 【処理内容】: 時系列データの挿入
    # 【実行タイミング】: わずかな時間差で3件のレコードを挿入
    record1 = AIConversionHistory(
        input_text="古いレコード",
        converted_text="古いレコードです",
        politeness_level=PolitenessLevel.CASUAL,
    )
    db_session.add(record1)
    await db_session.commit()

    record2 = AIConversionHistory(
        input_text="中間レコード",
        converted_text="中間レコードです",
        politeness_level=PolitenessLevel.NORMAL,
    )
    db_session.add(record2)
    await db_session.commit()

    record3 = AIConversionHistory(
        input_text="最新レコード",
        converted_text="最新レコードです",
        politeness_level=PolitenessLevel.POLITE,
    )
    db_session.add(record3)
    await db_session.commit()

    # 【実際の処理実行】: created_at降順でレコードを取得
    # 【処理内容】: ORDER BY created_at DESC で検索
    result = await db_session.execute(
        select(AIConversionHistory)
        .order_by(AIConversionHistory.created_at.desc())
        .limit(3)
    )
    sorted_records = result.scalars().all()

    # 【結果検証】: レコードが新しい順に並んでいることを確認
    # 【期待値確認】: インデックスidx_ai_conversion_created_atが正しく機能する
    # 【品質保証】: インデックスを使用したソート機能が正常に動作することを保証

    # 【検証項目】: 取得されたレコード数が3件以上であるか
    assert len(sorted_records) >= 3  # 【確認内容】: 3件以上のレコードが取得される

    # 【検証項目】: 最初のレコードが最新（"最新レコード"）であるか
    # 🔵 要件定義書（line 149）に基づくインデックスソートの検証
    assert sorted_records[0].input_text == "最新レコード"  # 【確認内容】: 最新のレコードが先頭に来る

    # 【検証項目】: 2番目のレコードが"中間レコード"であるか
    assert sorted_records[1].input_text == "中間レコード"  # 【確認内容】: 中間のレコードが2番目に来る

    # 【検証項目】: 3番目のレコードが最も古い（"古いレコード"）であるか
    assert sorted_records[2].input_text == "古いレコード"  # 【確認内容】: 最も古いレコードが3番目に来る


async def test_filter_by_user_session_id_after_migration(db_session):
    """
    F-4. user_session_idで絞り込み検索ができる

    【テスト目的】: user_session_idによる絞り込み検索が正しく動作することを確認
    【テスト内容】: 2つの異なるセッションIDのレコードを作成し、特定のセッションIDのみを検索
    【期待される動作】: 指定したセッションIDのレコードのみが取得される
    🔵 この内容は要件定義書（line 150, line 189-202）とテストケース仕様書（line 412-427）に基づく
    """
    # 【テストデータ準備】: セッションIDによる絞り込み検索を確認するためのデータセット
    # 【初期条件設定】: マイグレーションが実行済みで、ai_conversion_historyテーブルが存在する
    from app.models.ai_conversion_history import AIConversionHistory, PolitenessLevel

    uuid_a = uuid4()
    uuid_b = uuid4()

    # 【実際の処理実行】: 2つの異なるセッションIDのレコードを作成
    # 【処理内容】: セッションごとの履歴検索を想定したデータ挿入
    # レコード1: UUID_A
    record1 = AIConversionHistory(
        input_text="セッションA",
        converted_text="セッションAのテキスト",
        politeness_level=PolitenessLevel.NORMAL,
        user_session_id=uuid_a,
    )
    # レコード2: UUID_B
    record2 = AIConversionHistory(
        input_text="セッションB",
        converted_text="セッションBのテキスト",
        politeness_level=PolitenessLevel.CASUAL,
        user_session_id=uuid_b,
    )

    db_session.add_all([record1, record2])
    await db_session.commit()

    # 【実際の処理実行】: UUID_Aのレコードのみを検索
    # 【処理内容】: WHERE句でuser_session_idを絞り込み
    # 【実行タイミング】: 挿入直後に絞り込み検索を実行
    result = await db_session.execute(
        select(AIConversionHistory).where(AIConversionHistory.user_session_id == uuid_a)
    )
    filtered_records = result.scalars().all()

    # 【結果検証】: UUID_Aのレコードのみが取得されることを確認
    # 【期待値確認】: インデックスidx_ai_conversion_sessionが正しく機能する
    # 【品質保証】: インデックスを使用した絞り込み検索が正常に動作することを保証

    # 【検証項目】: 取得されたレコード数が1件であるか
    # 🔵 要件定義書（line 189-202）に基づく検証
    assert len(filtered_records) == 1  # 【確認内容】: 1件のレコードが取得される

    # 【検証項目】: 取得したレコードのinput_textが"セッションA"であるか
    # 🔵 要件定義書（line 150）に基づくインデックス検索の検証
    assert filtered_records[0].input_text == "セッションA"  # 【確認内容】: 正しいセッションのレコードが取得される

    # 【検証項目】: 取得したレコードのuser_session_idがUUID_Aであるか
    assert filtered_records[0].user_session_id == uuid_a  # 【確認内容】: セッションIDが一致する
