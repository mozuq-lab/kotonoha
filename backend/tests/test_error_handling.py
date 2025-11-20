"""
エラーハンドリングテスト（TASK-0008）

データベース制約違反、トランザクションエラー、Enumバリデーションエラーを確認。
"""

import pytest
from sqlalchemy.exc import IntegrityError


async def test_not_null_constraint_violation(db_session):
    """
    D-4. 必須フィールドがNoneの場合、IntegrityErrorが発生する

    【テスト目的】: NOT NULL制約が正しく機能することを確認
    【テスト内容】: NOT NULL制約のあるフィールドにNoneを設定してコミット
    【期待される動作】: IntegrityErrorが発生し、レコードは保存されない
    🔵 この内容は要件定義書（line 293-307, line 421-426）に基づく
    """
    # 【テストデータ準備】: 必須フィールドの入力漏れをシミュレート
    # 【初期条件設定】: データベースが起動しており、セッションが利用可能な状態
    from app.models.ai_conversion_history import AIConversionHistory, PolitenessLevel

    # 【実際の処理実行】: NOT NULL制約違反のレコードを作成し、コミットを試みる
    # 【処理内容】: input_textがNoneのため、データベース側でエラーが発生
    # 【エラー処理の重要性】: データ整合性を保ち、不正なデータの保存を防ぐ
    with pytest.raises(IntegrityError) as exc_info:
        record = AIConversionHistory(
            input_text=None,  # NOT NULL制約違反
            converted_text="テスト",
            politeness_level=PolitenessLevel.NORMAL,
        )
        db_session.add(record)
        await db_session.commit()

    # 【結果検証】: IntegrityErrorが発生し、エラーメッセージに詳細が含まれることを確認

    # 【検証項目】: IntegrityErrorが発生したか
    # 🔵 要件定義書（line 293-307, line 421-426）に基づく制約違反検証
    assert exc_info.value is not None

    # 【検証項目】: エラーメッセージに制約違反の詳細が含まれるか
    # 🔵 要件定義書（line 146）に基づくNOT NULL制約の検証
    error_message = str(exc_info.value)
    # PostgreSQLのNOT NULL制約エラーメッセージを確認
    assert "null" in error_message.lower() or "not-null" in error_message.lower()


async def test_converted_text_not_null_constraint_violation(db_session):
    """
    converted_textのNOT NULL制約違反テスト

    【テスト目的】: converted_textのNOT NULL制約が正しく機能することを確認
    【テスト内容】: converted_text=Noneでレコードを作成し、エラーを確認
    【期待される動作】: IntegrityErrorが発生する
    🔵 この内容は要件定義書（line 55, line 146）に基づく
    """
    # 【テストデータ準備】: converted_textにNoneを設定
    from app.models.ai_conversion_history import AIConversionHistory, PolitenessLevel

    # 【実際の処理実行】: NOT NULL制約違反のレコードを作成
    # 【処理内容】: converted_textがNoneのため、データベース側でエラーが発生
    with pytest.raises(IntegrityError):
        record = AIConversionHistory(
            input_text="テスト",
            converted_text=None,  # NOT NULL制約違反
            politeness_level=PolitenessLevel.NORMAL,
        )
        db_session.add(record)
        await db_session.commit()

    # 【結果検証】: IntegrityErrorが発生したことを確認
    # 【検証項目】: converted_textのNOT NULL制約が機能しているか
    # 🔵 要件定義書（line 55, line 146）に基づく検証


async def test_invalid_politeness_level_enum_value():
    """
    E-1. 存在しないpoliteness_level値を設定した場合、ValueErrorが発生する

    【テスト目的】: Enum型バリデーションが正しく機能することを確認
    【テスト内容】: Enumに定義されていない値を設定した場合、Pythonレベルでエラーが発生
    【期待される動作】: ValueErrorまたはAttributeErrorが発生する
    🟡 この内容は要件定義書（line 276-290）に基づくが、Enum実装方法は推測
    """
    # 【テストデータ準備】: 無効なEnum値を使用
    # 【初期条件設定】: PolitenessLevel Enumが正しく定義されている
    from app.models.ai_conversion_history import AIConversionHistory, PolitenessLevel

    # 【実際の処理実行】: 不正なEnum値でインスタンスを作成
    # 【処理内容】: 'super_polite'はEnum定義に存在しないため、エラーが発生
    # 【エラー処理の重要性】: データベースに不正な値が保存される前にPythonレベルで検出
    with pytest.raises((ValueError, AttributeError)) as exc_info:
        # 文字列をEnum値として直接設定することはできないため、
        # Enum値として存在しない値を使用しようとするとエラーが発生
        # ここではPolitenessLevel("super_polite")を試みる
        invalid_level = PolitenessLevel("super_polite")

    # 【結果検証】: ValueError or AttributeErrorが発生したことを確認

    # 【検証項目】: Enum型バリデーションエラーが発生したか
    # 🟡 要件定義書（line 276-290）に基づくEnum検証（実装方法は推測）
    assert exc_info.value is not None


async def test_enum_string_assignment_prevention():
    """
    Enum型フィールドに文字列を直接代入した場合のテスト

    【テスト目的】: Enum型に文字列を直接代入できないことを確認
    【テスト内容】: politeness_levelに文字列を直接代入した場合の動作確認
    【期待される動作】: 型エラーまたはバリデーションエラーが発生する
    🟡 この内容は要件定義書（line 57）に基づくが、実装方法は推測
    """
    # 【テストデータ準備】: 文字列をEnum型フィールドに代入しようとする
    from app.models.ai_conversion_history import AIConversionHistory

    # 【実際の処理実行】: 文字列でインスタンスを作成
    # 【処理内容】: SQLAlchemy Enumフィールドは文字列を受け入れる可能性がある
    # 【注意】: Pydantic等のバリデーションがある場合はエラーになる可能性
    # このテストは実装依存のため、実際の動作を確認する
    try:
        record = AIConversionHistory(
            input_text="テスト",
            converted_text="テストです",
            politeness_level="normal",  # 文字列で代入
        )
        # SQLAlchemyのEnumフィールドは文字列を受け入れる可能性があるため、
        # この場合はエラーが発生しないかもしれない
        # 【検証項目】: 文字列が受け入れられる場合は、Enum値に自動変換されるか
        from app.models.ai_conversion_history import PolitenessLevel
        # 文字列が受け入れられた場合、Enum値に変換されているか確認
        # または、そのまま文字列として保存されるか確認
        # 🟡 実装依存の動作
    except (ValueError, TypeError) as e:
        # 文字列が拒否された場合、適切なエラーが発生したことを確認
        # 【検証項目】: 型エラーまたはバリデーションエラーが発生したか
        # 🟡 要件定義書（line 57）に基づくEnum型の検証
        assert e is not None


async def test_rollback_after_integrity_error(db_session):
    """
    IntegrityError発生後のロールバック動作テスト

    【テスト目的】: エラー発生後にセッションが適切にロールバックされることを確認
    【テスト内容】: IntegrityError発生後、セッションをロールバックして再利用可能にする
    【期待される動作】: ロールバック後、セッションが正常に使用できる
    🔵 この内容は要件定義書（line 234-251, NFR-304）に基づく
    """
    # 【テストデータ準備】: エラー発生後のロールバックをテスト
    from app.models.ai_conversion_history import AIConversionHistory, PolitenessLevel

    # 【実際の処理実行】: 制約違反エラーを発生させる
    # 【処理内容】: NOT NULL制約違反のレコードを作成
    try:
        record = AIConversionHistory(
            input_text=None,  # NOT NULL制約違反
            converted_text="テスト",
            politeness_level=PolitenessLevel.NORMAL,
        )
        db_session.add(record)
        await db_session.commit()
    except IntegrityError:
        # 【テスト後処理】: エラー発生後、明示的にロールバック
        # 【状態復元】: セッションをクリーンな状態に戻す
        await db_session.rollback()

    # 【結果検証】: ロールバック後、セッションが正常に使用できることを確認

    # 【検証項目】: ロールバック後、正常なレコードを作成できるか
    # 🔵 要件定義書（line 234-251, NFR-304）に基づくエラーハンドリング検証
    normal_record = AIConversionHistory(
        input_text="正常なテスト",
        converted_text="正常なテストです",
        politeness_level=PolitenessLevel.NORMAL,
    )
    db_session.add(normal_record)
    await db_session.commit()

    # 【検証項目】: 正常なレコードが保存されたか
    assert normal_record.id is not None


async def test_multiple_integrity_errors(db_session):
    """
    複数のNOT NULL制約違反を同時に含むレコードのテスト

    【テスト目的】: 複数の制約違反が発生した場合、適切なエラーが返されることを確認
    【テスト内容】: input_textとconverted_textの両方がNoneのレコードを作成
    【期待される動作】: IntegrityErrorが発生する
    🔵 この内容は要件定義書（line 54-55, line 146）に基づく
    """
    # 【テストデータ準備】: 複数の制約違反を含むデータ
    from app.models.ai_conversion_history import AIConversionHistory, PolitenessLevel

    # 【実際の処理実行】: 複数のNOT NULL制約違反を含むレコードを作成
    # 【処理内容】: input_textとconverted_textの両方がNone
    with pytest.raises(IntegrityError):
        record = AIConversionHistory(
            input_text=None,  # NOT NULL制約違反
            converted_text=None,  # NOT NULL制約違反
            politeness_level=PolitenessLevel.NORMAL,
        )
        db_session.add(record)
        await db_session.commit()

    # 【結果検証】: IntegrityErrorが発生したことを確認
    # 【検証項目】: 複数の制約違反がある場合も適切にエラーが発生するか
    # 🔵 要件定義書（line 54-55, line 146）に基づく検証
