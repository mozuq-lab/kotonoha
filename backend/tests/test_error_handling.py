"""
エラーハンドリングテスト（TASK-0008）

ai_conversion_logs テーブルに対するデータベース制約違反、トランザクションエラー、
バリデーションエラーを確認する。
"""

import uuid

import pytest
from sqlalchemy.exc import IntegrityError

from app.models.ai_conversion_logs import AIConversionLog


async def test_not_null_constraint_violation(db_session):
    """
    D-4. 必須フィールド(input_text_hash)がNoneの場合、IntegrityErrorが発生する

    【テスト目的】: NOT NULL制約が正しく機能することを確認
    【テスト内容】: NOT NULL制約のあるinput_text_hashにNoneを設定してフラッシュ
    【期待される動作】: IntegrityErrorが発生し、レコードは保存されない
    """
    # 【実際の処理実行】: NOT NULL制約違反のレコードを作成し、フラッシュを試みる
    with pytest.raises(IntegrityError) as exc_info:
        record = AIConversionLog(
            input_text_hash=None,  # NOT NULL制約違反
            input_length=5,
            output_length=7,
            politeness_level="normal",
            session_id=uuid.uuid4(),
        )
        db_session.add(record)
        await db_session.flush()

    # 【検証項目】: IntegrityErrorが発生し、メッセージに制約違反の詳細が含まれるか
    assert exc_info.value is not None
    error_message = str(exc_info.value).lower()
    assert "null" in error_message or "not-null" in error_message


async def test_session_id_not_null_constraint_violation(db_session):
    """
    必須フィールド(session_id)のNOT NULL制約違反テスト

    【テスト目的】: session_idのNOT NULL制約が正しく機能することを確認
    【テスト内容】: session_id=Noneでレコードを作成し、エラーを確認
    【期待される動作】: IntegrityErrorが発生する
    """
    with pytest.raises(IntegrityError):
        record = AIConversionLog(
            input_text_hash="a" * 64,
            input_length=5,
            output_length=7,
            politeness_level="normal",
            session_id=None,  # NOT NULL制約違反
        )
        db_session.add(record)
        await db_session.flush()


async def test_invalid_politeness_level_raises_value_error():
    """
    E-1. create_logに無効なpoliteness_level値を渡すとValueErrorが発生する

    【テスト目的】: アプリケーションレベルの丁寧さレベルバリデーションを確認
    【テスト内容】: 定義外の値をcreate_logに渡す
    【期待される動作】: ValueErrorが発生し、不正な値がDBに到達しない
    """
    with pytest.raises(ValueError) as exc_info:
        AIConversionLog.create_log(
            input_text="テスト",
            output_text="テストです",
            politeness_level="super_polite",  # 定義外の値
        )

    assert exc_info.value is not None


async def test_invalid_politeness_level_check_constraint(db_session):
    """
    politeness_levelのCHECK制約違反テスト（DBレベル）

    【テスト目的】: create_logのバリデーションを迂回した場合でも、DBのCHECK制約で防御されることを確認
    【テスト内容】: モデルを直接構築し、許可値以外のpoliteness_levelでフラッシュ
    【期待される動作】: CHECK制約違反によりIntegrityErrorが発生する
    """
    with pytest.raises(IntegrityError):
        record = AIConversionLog(
            input_text_hash="a" * 64,
            input_length=5,
            output_length=7,
            politeness_level="super_polite",  # CHECK制約違反
            session_id=uuid.uuid4(),
        )
        db_session.add(record)
        await db_session.flush()


async def test_rollback_after_integrity_error(db_session):
    """
    IntegrityError発生後のロールバック動作テスト

    【テスト目的】: エラー発生後にセッションが適切にロールバックされることを確認
    【テスト内容】: IntegrityError発生後、ロールバックして正常なレコードを保存する
    【期待される動作】: ロールバック後、セッションが正常に使用できる
    🔵 この内容は要件定義書（line 234-251, NFR-304）に基づく
    """
    # 【実際の処理実行】: 制約違反エラーを発生させる
    try:
        record = AIConversionLog(
            input_text_hash=None,  # NOT NULL制約違反
            input_length=5,
            output_length=7,
            politeness_level="normal",
            session_id=uuid.uuid4(),
        )
        db_session.add(record)
        await db_session.flush()
    except IntegrityError:
        # 【テスト後処理】: エラー発生後、明示的にロールバック
        await db_session.rollback()

    # 【検証項目】: ロールバック後、正常なレコードを作成できるか
    normal_record = AIConversionLog.create_log(
        input_text="正常なテスト",
        output_text="正常なテストです",
        politeness_level="normal",
    )
    db_session.add(normal_record)
    await db_session.flush()

    # 【検証項目】: 正常なレコードが保存されたか
    assert normal_record.id is not None


async def test_multiple_integrity_errors(db_session):
    """
    複数のNOT NULL制約違反を同時に含むレコードのテスト

    【テスト目的】: 複数の制約違反が発生した場合、適切なエラーが返されることを確認
    【テスト内容】: input_text_hashとinput_lengthの両方がNoneのレコードを作成
    【期待される動作】: IntegrityErrorが発生する
    """
    with pytest.raises(IntegrityError):
        record = AIConversionLog(
            input_text_hash=None,  # NOT NULL制約違反
            input_length=None,  # NOT NULL制約違反
            output_length=7,
            politeness_level="normal",
            session_id=uuid.uuid4(),
        )
        db_session.add(record)
        await db_session.flush()


# ================================================================================
# カテゴリG: エラーハンドリングテスト（TASK-0009追加分）
# ================================================================================


async def test_insert_fails_with_not_null_constraint(db_session):
    """
    G-3. レコード挿入でNOT NULL制約違反(output_length)が発生する

    【テスト目的】: NOT NULL制約が正しく機能することを確認
    【テスト内容】: output_lengthにNoneを設定してレコード挿入
    【期待される動作】: IntegrityErrorが発生し、レコードが保存されない
    🔵 この内容は要件定義書（line 267-286, line 421-426, NFR-304）に基づく
    """
    with pytest.raises(IntegrityError) as exc_info:
        record = AIConversionLog(
            input_text_hash="a" * 64,
            input_length=5,
            output_length=None,  # NOT NULL制約違反
            politeness_level="normal",
            session_id=uuid.uuid4(),
        )
        db_session.add(record)
        await db_session.flush()

    # 【検証項目】: エラーメッセージに制約違反の詳細が含まれるか
    assert "null" in str(exc_info.value).lower()
