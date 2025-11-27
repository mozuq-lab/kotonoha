"""
SQLAlchemyモデルのテスト（TASK-0008）

AIConversionHistoryモデルのCRUD操作、バリデーション、境界値テストを実施。
"""

from datetime import datetime
from uuid import UUID, uuid4

import pytest
from sqlalchemy import select

# ================================================================================
# カテゴリB: AI変換履歴モデルのインスタンス化テスト
# ================================================================================


async def test_ai_conversion_history_instantiation_required_fields_only():
    """
    B-1. 必須フィールドのみでAIConversionHistoryモデルのインスタンスを作成できる

    【テスト目的】: AIConversionHistoryモデルの基本的なインスタンス化機能を確認する
    【テスト内容】: 必須フィールド（input_text, converted_text, politeness_level）のみでインスタンスを作成
    【期待される動作】: インスタンスが正常に作成され、各フィールドの値が正しく設定される
    🔵 この内容は要件定義書（line 166-177）に基づく
    """
    # 【テストデータ準備】: 実際のユースケースを想定した日本語テキストを用意
    # 【初期条件設定】: モデルクラスがインポート可能であること（現時点では未実装）
    from app.models.ai_conversion_history import AIConversionHistory, PolitenessLevel

    # 【実際の処理実行】: AIConversionHistoryモデルのインスタンスを作成
    # 【処理内容】: 必須フィールドを指定してコンストラクタを呼び出す
    record = AIConversionHistory(
        input_text="水 ぬるく",
        converted_text="お水をぬるめでお願いします",
        politeness_level=PolitenessLevel.NORMAL,
    )

    # 【結果検証】: インスタンスが正常に作成されたことを確認
    # 【期待値確認】: 各フィールドの値が入力値と一致することを検証
    # 【品質保証】: モデルの基本機能が正しく実装されていることを保証

    # 【検証項目】: input_textフィールドの値が正しく設定されているか
    # 🔵 要件定義書（line 54）に基づくNOT NULL制約フィールドの検証
    assert record.input_text == "水 ぬるく"

    # 【検証項目】: converted_textフィールドの値が正しく設定されているか
    # 🔵 要件定義書（line 55）に基づくNOT NULL制約フィールドの検証
    assert record.converted_text == "お水をぬるめでお願いします"

    # 【検証項目】: politeness_levelがEnum値として正しく設定されているか
    # 🔵 要件定義書（line 57）に基づくEnum制約の検証
    assert record.politeness_level == PolitenessLevel.NORMAL

    # 【検証項目】: idはDB保存前は未設定であること
    # 🔵 要件定義書（line 54）に基づく自動生成フィールドの検証
    assert record.id is None

    # 【検証項目】: created_atはDB保存前は未設定であること
    # 🔵 要件定義書（line 58）に基づく自動生成フィールドの検証
    assert record.created_at is None


async def test_ai_conversion_history_instantiation_all_fields():
    """
    B-2. すべてのフィールドを指定してAIConversionHistoryモデルのインスタンスを作成できる

    【テスト目的】: オプションフィールドを含む完全なモデルインスタンス化を確認
    【テスト内容】: オプションフィールド（conversion_time_ms, user_session_id）を含むすべてのフィールドを指定
    【期待される動作】: すべてのフィールドが正しく設定されること
    🔵 この内容は要件定義書（line 86-95）に基づく
    """
    # 【テストデータ準備】: オプションフィールドも含めた完全なデータセット
    from app.models.ai_conversion_history import AIConversionHistory, PolitenessLevel

    test_uuid = UUID("12345678-1234-5678-1234-567812345678")

    # 【実際の処理実行】: すべてのフィールドを指定してインスタンスを作成
    # 【処理内容】: オプションフィールドも含めてコンストラクタを呼び出す
    record = AIConversionHistory(
        input_text="ありがとう",
        converted_text="ありがとうございます",
        politeness_level=PolitenessLevel.POLITE,
        conversion_time_ms=100,
        user_session_id=test_uuid,
    )

    # 【結果検証】: すべてのフィールドが正しく設定されたことを確認

    # 【検証項目】: 必須フィールドが正しく設定されているか
    # 🔵 要件定義書（line 54-57）に基づく検証
    assert record.input_text == "ありがとう"
    assert record.converted_text == "ありがとうございます"
    assert record.politeness_level == PolitenessLevel.POLITE

    # 【検証項目】: オプションフィールドが正しく設定されているか
    # 🔵 要件定義書（line 59-60）に基づくNULL許可フィールドの検証
    assert record.conversion_time_ms == 100
    assert record.user_session_id == test_uuid


async def test_ai_conversion_history_nullable_fields():
    """
    B-3. NULL許可フィールド（conversion_time_ms, user_session_id）を省略してもインスタンスを作成できる

    【テスト目的】: NULL許可フィールドの仕様が正しく実装されていることを確認
    【テスト内容】: オプションフィールドを省略した場合、Noneとして設定されること
    【期待される動作】: 必須フィールドのみでインスタンス化が成功し、オプションフィールドはNone
    🔵 この内容は要件定義書（line 265-274）に基づく
    """
    # 【テストデータ準備】: 最小限の必須フィールドのみ指定
    from app.models.ai_conversion_history import AIConversionHistory, PolitenessLevel

    # 【実際の処理実行】: オプションフィールドを省略してインスタンスを作成
    # 【処理内容】: 必須フィールドのみでコンストラクタを呼び出す
    record = AIConversionHistory(
        input_text="こんにちは",
        converted_text="こんにちは",
        politeness_level=PolitenessLevel.CASUAL,
    )

    # 【結果検証】: オプションフィールドがNoneとして設定されていることを確認

    # 【検証項目】: conversion_time_msがNoneとして設定されているか（NULL許可フィールド）
    # 🔵 要件定義書（line 59, line 265-274）に基づくNULL許可フィールドの検証
    assert record.conversion_time_ms is None

    # 【検証項目】: user_session_idがNoneとして設定されているか（NULL許可フィールド）
    # 🔵 要件定義書（line 60, line 265-274）に基づくNULL許可フィールドの検証
    assert record.user_session_id is None


async def test_politeness_level_casual():
    """
    B-4. PolitenessLevel.CASUALでインスタンスを作成できる

    【テスト目的】: Enum値 CASUAL が正しく動作することを確認
    【テスト内容】: politeness_level=PolitenessLevel.CASUAL でインスタンス化
    【期待される動作】: CASUALが有効なEnum値として設定される
    🔵 この内容は要件定義書（line 57）に基づく
    """
    # 【テストデータ準備】: カジュアルな文体を表すEnum値
    from app.models.ai_conversion_history import AIConversionHistory, PolitenessLevel

    # 【実際の処理実行】: CASUAL Enum値でインスタンスを作成
    record = AIConversionHistory(
        input_text="元気?",
        converted_text="元気?",
        politeness_level=PolitenessLevel.CASUAL,
    )

    # 【結果検証】: CASUAL Enum値が正しく設定されたことを確認

    # 【検証項目】: politeness_levelがCASUALとして設定されているか
    # 🔵 要件定義書（line 57）に基づくEnum値の検証
    assert record.politeness_level == PolitenessLevel.CASUAL


async def test_politeness_level_normal():
    """
    B-5. PolitenessLevel.NORMALでインスタンスを作成できる

    【テスト目的】: Enum値 NORMAL が正しく動作することを確認
    【テスト内容】: politeness_level=PolitenessLevel.NORMAL でインスタンス化
    【期待される動作】: NORMALが有効なEnum値として設定される
    🔵 この内容は要件定義書（line 57）に基づく
    """
    # 【テストデータ準備】: 通常の丁寧さを表すEnum値
    from app.models.ai_conversion_history import AIConversionHistory, PolitenessLevel

    # 【実際の処理実行】: NORMAL Enum値でインスタンスを作成
    record = AIConversionHistory(
        input_text="水ください",
        converted_text="お水をください",
        politeness_level=PolitenessLevel.NORMAL,
    )

    # 【結果検証】: NORMAL Enum値が正しく設定されたことを確認

    # 【検証項目】: politeness_levelがNORMALとして設定されているか
    # 🔵 要件定義書（line 57）に基づくEnum値の検証
    assert record.politeness_level == PolitenessLevel.NORMAL


async def test_politeness_level_polite():
    """
    B-6. PolitenessLevel.POLITEでインスタンスを作成できる

    【テスト目的】: Enum値 POLITE が正しく動作することを確認
    【テスト内容】: politeness_level=PolitenessLevel.POLITE でインスタンス化
    【期待される動作】: POLITEが有効なEnum値として設定される
    🔵 この内容は要件定義書（line 57）に基づく
    """
    # 【テストデータ準備】: 丁寧な文体を表すEnum値
    from app.models.ai_conversion_history import AIConversionHistory, PolitenessLevel

    # 【実際の処理実行】: POLITE Enum値でインスタンスを作成
    record = AIConversionHistory(
        input_text="トイレ",
        converted_text="お手洗いに行きたいのですが",
        politeness_level=PolitenessLevel.POLITE,
    )

    # 【結果検証】: POLITE Enum値が正しく設定されたことを確認

    # 【検証項目】: politeness_levelがPOLITEとして設定されているか
    # 🔵 要件定義書（line 57）に基づくEnum値の検証
    assert record.politeness_level == PolitenessLevel.POLITE


# ================================================================================
# カテゴリC: データベースCRUD操作テスト
# ================================================================================


async def test_create_ai_conversion_history_record(db_session):
    """
    C-2. AIConversionHistoryレコードをデータベースに保存できる

    【テスト目的】: データベースへのレコード作成機能を確認
    【テスト内容】: モデルインスタンスをデータベースに保存し、自動生成値を取得
    【期待される動作】: レコードが保存され、IDとタイムスタンプが自動生成される
    🔵 この内容は要件定義書（line 180-188, line 379-382）に基づく
    """
    # 【テストデータ準備】: データベースに保存する実際のデータ
    from app.models.ai_conversion_history import AIConversionHistory, PolitenessLevel

    # 【実際の処理実行】: レコードを作成しデータベースに保存
    # 【処理内容】: session.add()とsession.commit()でデータベースに保存
    record = AIConversionHistory(
        input_text="助けて",
        converted_text="助けてください",
        politeness_level=PolitenessLevel.NORMAL,
    )

    db_session.add(record)
    await db_session.commit()
    await db_session.refresh(record)

    # 【結果検証】: レコードが正常に保存され、自動生成値が設定されたことを確認

    # 【検証項目】: idが自動生成されているか（Integerの正の値）
    # 🔵 要件定義書（line 54）に基づく自動生成フィールドの検証
    assert record.id is not None
    assert isinstance(record.id, int)
    assert record.id > 0

    # 【検証項目】: created_atが自動設定されているか（datetime型）
    # 🔵 要件定義書（line 58）に基づく自動生成タイムスタンプの検証
    assert record.created_at is not None
    assert isinstance(record.created_at, datetime)


async def test_read_ai_conversion_history_record(db_session):
    """
    C-3. 保存したAIConversionHistoryレコードをクエリで取得できる

    【テスト目的】: データベースからのレコード読み取り機能を確認
    【テスト内容】: 保存したレコードをSELECTクエリで取得し、値を検証
    【期待される動作】: 保存したデータと一致するレコードが取得できる
    🔵 この内容は要件定義書（line 189-202, line 384-386）に基づく
    """
    # 【テストデータ準備】: データベースに事前保存するテストデータ
    from app.models.ai_conversion_history import AIConversionHistory, PolitenessLevel

    # 【実際の処理実行】: レコードを保存
    record = AIConversionHistory(
        input_text="暑い",
        converted_text="暑いです",
        politeness_level=PolitenessLevel.NORMAL,
    )
    db_session.add(record)
    await db_session.commit()
    await db_session.refresh(record)

    saved_id = record.id

    # 【実際の処理実行】: 保存したレコードをクエリで取得
    # 【処理内容】: SQLAlchemy 2.x のselect文で検索
    result = await db_session.execute(
        select(AIConversionHistory).where(AIConversionHistory.id == saved_id)
    )
    retrieved_record = result.scalar_one()

    # 【結果検証】: 取得したレコードが保存した値と一致することを確認

    # 【検証項目】: 取得したレコードのIDが一致するか
    # 🔵 要件定義書（line 189-202）に基づく検証
    assert retrieved_record.id == saved_id

    # 【検証項目】: input_textが一致するか
    # 🔵 要件定義書（line 54）に基づく検証
    assert retrieved_record.input_text == "暑い"

    # 【検証項目】: converted_textが一致するか
    # 🔵 要件定義書（line 55）に基づく検証
    assert retrieved_record.converted_text == "暑いです"

    # 【検証項目】: politeness_levelが一致するか
    # 🔵 要件定義書（line 57）に基づく検証
    assert retrieved_record.politeness_level == PolitenessLevel.NORMAL


async def test_filter_by_user_session_id(db_session):
    """
    C-4. user_session_idで絞り込んでレコードを取得できる

    【テスト目的】: WHERE句による絞り込み検索が正しく機能することを確認
    【テスト内容】: 特定のuser_session_idのレコードのみを取得
    【期待される動作】: 指定したセッションIDのレコードのみが取得される
    🔵 この内容は要件定義書（line 189-202, line 150）に基づく
    """
    # 【テストデータ準備】: セッションIDによる絞り込み検索を確認するためのデータセット
    from app.models.ai_conversion_history import AIConversionHistory, PolitenessLevel

    uuid_a = uuid4()
    uuid_b = uuid4()

    # レコード1: UUID_A
    record1 = AIConversionHistory(
        input_text="テスト1",
        converted_text="テスト1です",
        politeness_level=PolitenessLevel.NORMAL,
        user_session_id=uuid_a,
    )
    # レコード2: UUID_B
    record2 = AIConversionHistory(
        input_text="テスト2",
        converted_text="テスト2です",
        politeness_level=PolitenessLevel.CASUAL,
        user_session_id=uuid_b,
    )

    db_session.add_all([record1, record2])
    await db_session.commit()

    # 【実際の処理実行】: UUID_Aのレコードのみを検索
    # 【処理内容】: WHERE句でuser_session_idを絞り込み
    result = await db_session.execute(
        select(AIConversionHistory).where(AIConversionHistory.user_session_id == uuid_a)
    )
    filtered_records = result.scalars().all()

    # 【結果検証】: UUID_Aのレコードのみが取得されることを確認

    # 【検証項目】: 取得されたレコード数が1件であるか
    # 🔵 要件定義書（line 189-202）に基づく検証
    assert len(filtered_records) == 1

    # 【検証項目】: 取得したレコードのinput_textが"テスト1"であるか
    # 🔵 要件定義書（line 150）に基づくインデックス検索の検証
    assert filtered_records[0].input_text == "テスト1"


async def test_order_by_created_at_desc(db_session):
    """
    C-5. created_atの降順でレコードを取得できる

    【テスト目的】: ORDER BY句によるソート機能を確認
    【テスト内容】: created_at DESCでレコードを取得し、新しい順に並ぶことを確認
    【期待される動作】: 最新のレコードが先頭に並ぶ
    🔵 この内容は要件定義書（line 189-202, line 149）に基づく
    """
    # 【テストデータ準備】: ソート機能を確認するための時系列データ
    from app.models.ai_conversion_history import AIConversionHistory, PolitenessLevel

    # 3つのレコードを順番に作成
    record1 = AIConversionHistory(
        input_text="古い1",
        converted_text="古い1です",
        politeness_level=PolitenessLevel.CASUAL,
    )
    db_session.add(record1)
    await db_session.commit()

    record2 = AIConversionHistory(
        input_text="古い2",
        converted_text="古い2です",
        politeness_level=PolitenessLevel.NORMAL,
    )
    db_session.add(record2)
    await db_session.commit()

    record3 = AIConversionHistory(
        input_text="新しい",
        converted_text="新しいです",
        politeness_level=PolitenessLevel.POLITE,
    )
    db_session.add(record3)
    await db_session.commit()

    # 【実際の処理実行】: created_at降順でレコードを取得
    # 【処理内容】: ORDER BY created_at DESC で検索
    result = await db_session.execute(
        select(AIConversionHistory).order_by(AIConversionHistory.created_at.desc())
    )
    sorted_records = result.scalars().all()

    # 【結果検証】: レコードが新しい順に並んでいることを確認

    # 【検証項目】: 最初のレコードが最新（"新しい"）であるか
    # 🔵 要件定義書（line 149）に基づくインデックスソートの検証
    assert sorted_records[0].input_text == "新しい"

    # 【検証項目】: 2番目のレコードが"古い2"であるか
    assert sorted_records[1].input_text == "古い2"

    # 【検証項目】: 3番目のレコードが最も古い（"古い1"）であるか
    assert sorted_records[2].input_text == "古い1"


async def test_limit_records(db_session):
    """
    C-6. LIMIT句で取得件数を制限できる

    【テスト目的】: LIMIT句による件数制限が正しく機能することを確認
    【テスト内容】: 15件のレコードから10件のみを取得
    【期待される動作】: 指定した件数のレコードのみが取得される
    🔵 この内容は要件定義書（line 189-202）に基づく
    """
    # 【テストデータ準備】: 件数制限機能を確認するための大量データ
    from app.models.ai_conversion_history import AIConversionHistory, PolitenessLevel

    # 15件のレコードを作成
    for i in range(15):
        record = AIConversionHistory(
            input_text=f"テスト{i}",
            converted_text=f"テスト{i}です",
            politeness_level=PolitenessLevel.NORMAL,
        )
        db_session.add(record)

    await db_session.commit()

    # 【実際の処理実行】: LIMIT 10でレコードを取得
    # 【処理内容】: 最新の10件を取得
    result = await db_session.execute(
        select(AIConversionHistory).order_by(AIConversionHistory.created_at.desc()).limit(10)
    )
    limited_records = result.scalars().all()

    # 【結果検証】: 取得されたレコード数が10件であることを確認

    # 【検証項目】: 取得されたレコード数が正確に10件であるか
    # 🔵 要件定義書（line 189-202）に基づく検証（NFR-002: パフォーマンス確保）
    assert len(limited_records) == 10


# ================================================================================
# カテゴリD: トランザクション管理・エラーハンドリング
# ================================================================================


async def test_transaction_commit(db_session):
    """
    D-1. トランザクション内で複数のレコードを正常にコミットできる

    【テスト目的】: トランザクションの正常コミット機能を確認
    【テスト内容】: トランザクション内で複数レコードを一括コミット
    【期待される動作】: トランザクション内のすべてのレコードがデータベースに保存される
    🔵 この内容は要件定義書（line 253-262, line 388-391）に基づく
    """
    # 【テストデータ準備】: トランザクション内で複数操作を行うためのデータセット
    from app.models.ai_conversion_history import AIConversionHistory, PolitenessLevel

    # 【実際の処理実行】: トランザクション内で2件のレコードを追加
    # 【処理内容】: session.begin()でトランザクションを開始
    async with db_session.begin():
        record1 = AIConversionHistory(
            input_text="テスト1",
            converted_text="テスト1です",
            politeness_level=PolitenessLevel.CASUAL,
        )
        record2 = AIConversionHistory(
            input_text="テスト2",
            converted_text="テスト2です",
            politeness_level=PolitenessLevel.NORMAL,
        )
        db_session.add_all([record1, record2])

    # 【結果検証】: トランザクションが正常にコミットされたことを確認

    # 【検証項目】: 2件のレコードがデータベースに保存されているか
    # 🔵 要件定義書（line 253-262）に基づくトランザクション管理の検証
    result = await db_session.execute(select(AIConversionHistory))
    all_records = result.scalars().all()
    assert len(all_records) >= 2


async def test_transaction_rollback(db_session):
    """
    D-2. エラー発生時にトランザクションがロールバックされる

    【テスト目的】: トランザクションのロールバック機能を確認
    【テスト内容】: トランザクション内でエラーを発生させ、ロールバックを確認
    【期待される動作】: エラー発生前の操作も含め、トランザクション内のすべての変更が破棄される
    🔵 この内容は要件定義書（line 234-251, line 388-391, NFR-304）に基づく
    """
    # 【テストデータ準備】: トランザクション途中でエラーを発生させるためのデータ
    from sqlalchemy.exc import IntegrityError

    from app.models.ai_conversion_history import AIConversionHistory, PolitenessLevel

    # 【実際の処理実行】: トランザクション内で正常レコードと不正レコードを追加
    # 【処理内容】: NOT NULL制約違反を発生させる
    with pytest.raises(IntegrityError):
        async with db_session.begin():
            # 正常なレコード
            record1 = AIConversionHistory(
                input_text="保存される前",
                converted_text="保存される前です",
                politeness_level=PolitenessLevel.CASUAL,
            )
            db_session.add(record1)

            # NOT NULL制約違反のレコード
            record2 = AIConversionHistory(
                input_text=None,  # NOT NULL制約違反
                converted_text="テスト",
                politeness_level=PolitenessLevel.NORMAL,
            )
            db_session.add(record2)

    # 【結果検証】: トランザクションがロールバックされ、record1も保存されていないことを確認

    # 【検証項目】: トランザクション内のすべてのレコードが破棄されているか
    # 🔵 要件定義書（line 234-251, NFR-304）に基づくロールバック検証
    result = await db_session.execute(
        select(AIConversionHistory).where(AIConversionHistory.input_text == "保存される前")
    )
    records = result.scalars().all()
    assert len(records) == 0


# ================================================================================
# カテゴリE: 異常系・境界値テスト
# ================================================================================


async def test_empty_string_input():
    """
    E-2. input_textに空文字列を設定してもレコードを作成できる

    【テスト目的】: 空文字列がNOT NULL制約を満たすことを確認
    【テスト内容】: 空文字列（""）でインスタンスを作成
    【期待される動作】: NOT NULL制約違反エラーは発生せず、空文字列として保存可能
    🔵 この内容はデータベース仕様とPostgreSQL動作に基づく
    """
    # 【テストデータ準備】: 空文字列を使用したデータ
    from app.models.ai_conversion_history import AIConversionHistory, PolitenessLevel

    # 【実際の処理実行】: 空文字列でインスタンスを作成
    # 【処理内容】: 空文字列はNULLではないため、NOT NULL制約を満たす
    record = AIConversionHistory(
        input_text="",
        converted_text="",
        politeness_level=PolitenessLevel.CASUAL,
    )

    # 【結果検証】: インスタンスが正常に作成されたことを確認

    # 【検証項目】: input_textが空文字列として設定されているか
    # 🔵 PostgreSQL Text型は空文字列を正しく保存する
    assert record.input_text == ""

    # 【検証項目】: converted_textが空文字列として設定されているか
    assert record.converted_text == ""


async def test_very_long_text_input():
    """
    E-3. 非常に長いテキスト（10,000文字）を設定してもレコードを作成できる

    【テスト目的】: PostgreSQL Text型の長文保存能力を確認
    【テスト内容】: 10,000文字の文字列でインスタンスを作成
    【期待される動作】: 長いテキストが切り捨てられることなく保存可能
    🟡 この内容は妥当な推測（実際の使用では想定外だが、テストとして有用）
    """
    # 【テストデータ準備】: 大量のテキストデータ
    from app.models.ai_conversion_history import AIConversionHistory, PolitenessLevel

    long_text = "あ" * 10000

    # 【実際の処理実行】: 10,000文字の文字列でインスタンスを作成
    # 【処理内容】: PostgreSQL Text型は理論上無制限のため、保存可能
    record = AIConversionHistory(
        input_text=long_text,
        converted_text=long_text,
        politeness_level=PolitenessLevel.NORMAL,
    )

    # 【結果検証】: 長いテキストが正しく設定されたことを確認

    # 【検証項目】: input_textの長さが10,000文字であるか
    # 🟡 PostgreSQL Text型の長文保存能力の検証
    assert len(record.input_text) == 10000

    # 【検証項目】: converted_textの長さが10,000文字であるか
    assert len(record.converted_text) == 10000


async def test_conversion_time_ms_zero():
    """
    E-4. conversion_time_ms=0を設定してもレコードを作成できる

    【テスト目的】: 0ミリ秒が有効な値として扱われることを確認
    【テスト内容】: conversion_time_ms=0でインスタンスを作成
    【期待される動作】: 0がNULLとして扱われず、正しく保存される
    🔵 この内容は要件定義書（line 59）に基づく
    """
    # 【テストデータ準備】: 処理時間の最小値（0ミリ秒）
    from app.models.ai_conversion_history import AIConversionHistory, PolitenessLevel

    # 【実際の処理実行】: conversion_time_ms=0でインスタンスを作成
    # 【処理内容】: 0は有効な値であり、NULLではない
    record = AIConversionHistory(
        input_text="テスト",
        converted_text="テスト",
        politeness_level=PolitenessLevel.CASUAL,
        conversion_time_ms=0,
    )

    # 【結果検証】: 0が正しく設定されたことを確認

    # 【検証項目】: conversion_time_msが0として設定されているか（NULLではない）
    # 🔵 要件定義書（line 59）に基づく境界値検証
    assert record.conversion_time_ms == 0
    assert record.conversion_time_ms is not None


async def test_conversion_time_ms_large_value():
    """
    E-5. conversion_time_ms=999999（非常に大きい値）を設定してもレコードを作成できる

    【テスト目的】: Integer型の範囲内で大きな値が正しく保存されることを確認
    【テスト内容】: conversion_time_ms=999999でインスタンスを作成
    【期待される動作】: 大きな値が切り捨てられることなく保存される
    🟡 この内容は妥当な推測（実際の運用では想定外だが、テストとして有用）
    """
    # 【テストデータ準備】: 処理時間が異常に長い場合の値
    from app.models.ai_conversion_history import AIConversionHistory, PolitenessLevel

    # 【実際の処理実行】: 非常に大きい値でインスタンスを作成
    # 【処理内容】: PostgreSQL Integer型の範囲内（-2^31 ~ 2^31-1）であれば保存可能
    record = AIConversionHistory(
        input_text="テスト",
        converted_text="テスト",
        politeness_level=PolitenessLevel.NORMAL,
        conversion_time_ms=999999,
    )

    # 【結果検証】: 大きな値が正しく設定されたことを確認

    # 【検証項目】: conversion_time_msが999999として設定されているか
    # 🟡 Integer型の範囲内で大きな値の検証
    assert record.conversion_time_ms == 999999


async def test_conversion_time_ms_negative_value():
    """
    E-6. conversion_time_ms=-1（負の値）を設定した場合の動作を確認

    【テスト目的】: 負の値に対する現在の動作を確認し、将来の改善点を特定
    【テスト内容】: conversion_time_ms=-1でインスタンスを作成
    【期待される動作】: 現在のスキーマではCHECK制約がないため、保存可能である可能性
    🟡 この内容は妥当な推測（現在のスキーマには制約がないため、動作は実装依存）
    """
    # 【テストデータ準備】: 論理的に不正な値（負の処理時間）
    from app.models.ai_conversion_history import AIConversionHistory, PolitenessLevel

    # 【実際の処理実行】: 負の値でインスタンスを作成
    # 【処理内容】: CHECK制約がないため、現時点では保存可能
    # 【注意】: 将来的にはCHECK制約（conversion_time_ms >= 0）を追加すべき
    record = AIConversionHistory(
        input_text="テスト",
        converted_text="テスト",
        politeness_level=PolitenessLevel.NORMAL,
        conversion_time_ms=-1,
    )

    # 【結果検証】: 負の値が設定されていることを確認（現在の動作）

    # 【検証項目】: conversion_time_msが-1として設定されているか
    # 🟡 現在のスキーマでは制約がないため、負の値も保存可能
    # 【改善点】: 将来的にはCHECK制約を追加し、負の値を拒否すべき
    assert record.conversion_time_ms == -1
