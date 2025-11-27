"""
TASK-0024: ログモデルのテスト

TDD Red Phase: AI変換ログとエラーログモデルに関するテストケースを定義する。
テストケース仕様書（testcases.md）のUT-001〜UT-026に対応。

テスト対象:
    - AIConversionLogモデル
    - ErrorLogモデル
    - create_logクラスメソッド
    - バリデーション・制約
"""

import re
import uuid
from datetime import datetime

import pytest
from sqlalchemy.exc import IntegrityError


class TestAIConversionLogModel:
    """
    AIConversionLogモデルのテストクラス

    FR-001: ログテーブルの定義
    FR-003: ログエントリ作成メソッド
    """

    @pytest.mark.asyncio
    async def test_ai_conversion_log_create(self, db_session) -> None:
        """
        UT-001: AIConversionLogの正常作成（create_logメソッド）

        テスト手順:
            1. AIConversionLog.create_logメソッドを呼び出す
            2. 作成されたインスタンスをdb_sessionに追加しcommit
            3. db_session.refreshでデータベースから最新状態を取得

        期待結果:
            - log.id が自動生成されている（整数値）
            - log.input_text_hash が64文字の16進数文字列である
            - log.input_length が5（"ありがとう"の文字数）である
            - log.output_length が11（"ありがとうございます"の文字数）である
            - log.politeness_level が"polite"である
            - log.conversion_time_ms が1500である
            - log.is_success がTrueである
            - log.session_id がUUID形式である
            - log.created_at がdatetime型である

        関連要件ID: FR-001, FR-003, AC-001
        優先度: 高
        """
        from app.models.ai_conversion_logs import AIConversionLog

        # create_logメソッドでログエントリを作成
        log = AIConversionLog.create_log(
            input_text="ありがとう",
            output_text="ありがとうございます",
            politeness_level="polite",
            conversion_time_ms=1500,
            ai_provider="anthropic",
        )

        # データベースに保存
        db_session.add(log)
        await db_session.commit()
        await db_session.refresh(log)

        # アサーション
        assert log.id is not None, "ID should be auto-generated"
        assert isinstance(log.id, int), "ID should be an integer"
        hash_len = len(log.input_text_hash)
        assert hash_len == 64, f"Hash should be 64 chars, got {hash_len}"
        assert re.match(r"^[0-9a-f]{64}$", log.input_text_hash), "Hash should be hex string"
        assert log.input_length == 5, f"Input length should be 5, got {log.input_length}"
        # "ありがとうございます" は10文字
        assert log.output_length == 10, f"Output length should be 10, got {log.output_length}"
        pol_level = log.politeness_level
        assert pol_level == "polite", f"Politeness level should be polite, got {pol_level}"
        conv_time = log.conversion_time_ms
        assert conv_time == 1500, f"Conversion time should be 1500, got {conv_time}"
        assert log.is_success is True, "is_success should be True"
        assert isinstance(log.session_id, uuid.UUID), "session_id should be UUID"
        assert isinstance(log.created_at, datetime), "created_at should be datetime"

    @pytest.mark.asyncio
    async def test_ai_conversion_log_hash_consistency(self, db_session) -> None:
        """
        UT-002: ハッシュ化の一貫性

        テスト手順:
            1. 同一テキスト"ありがとう"に対してhash_textを2回実行
            2. 2つのハッシュ値を比較

        期待結果:
            - hash1 == hash2（同一のハッシュ値が返される）
            - len(hash1) == 64（SHA-256の出力長）

        関連要件ID: FR-002, AC-002
        優先度: 高
        """
        from app.models.ai_conversion_logs import AIConversionLog

        text = "ありがとう"
        hash1 = AIConversionLog.hash_text(text)
        hash2 = AIConversionLog.hash_text(text)

        assert hash1 == hash2, f"Hash values should be consistent: {hash1} != {hash2}"
        assert len(hash1) == 64, f"Hash should be 64 characters, got {len(hash1)}"

    @pytest.mark.asyncio
    async def test_ai_conversion_log_different_hash(self, db_session) -> None:
        """
        UT-003: 異なるテキストで異なるハッシュ

        テスト手順:
            1. "ありがとう"に対してhash_textを実行
            2. "こんにちは"に対してhash_textを実行
            3. 2つのハッシュ値を比較

        期待結果:
            - hash1 != hash2（異なるハッシュ値が返される）

        関連要件ID: FR-002, AC-003
        優先度: 高
        """
        from app.models.ai_conversion_logs import AIConversionLog

        hash1 = AIConversionLog.hash_text("ありがとう")
        hash2 = AIConversionLog.hash_text("こんにちは")

        assert hash1 != hash2, f"Hash values should be different: {hash1} == {hash2}"

    @pytest.mark.asyncio
    async def test_ai_conversion_log_with_session_id(self, db_session) -> None:
        """
        UT-004: セッションIDでのグループ化

        テスト手順:
            1. 固定のsession_id（uuid4()）を生成
            2. 同一session_idで2つのログエントリを作成
            3. 両方のエントリをデータベースに保存

        期待結果:
            - log1.session_id == log2.session_id
            - 両方のログが正常に保存される

        関連要件ID: FR-003, AC-004
        優先度: 中
        """
        from app.models.ai_conversion_logs import AIConversionLog

        # 固定のsession_idを生成
        session_id = uuid.uuid4()

        # 同一session_idで2つのログを作成
        log1 = AIConversionLog.create_log(
            input_text="テスト1",
            output_text="テスト結果1",
            politeness_level="normal",
            conversion_time_ms=100,
            session_id=session_id,
        )
        log2 = AIConversionLog.create_log(
            input_text="テスト2",
            output_text="テスト結果2",
            politeness_level="polite",
            conversion_time_ms=200,
            session_id=session_id,
        )

        # データベースに保存
        db_session.add(log1)
        db_session.add(log2)
        await db_session.commit()
        await db_session.refresh(log1)
        await db_session.refresh(log2)

        # session_idが同一
        assert log1.session_id == log2.session_id, "Session IDs should be the same"
        assert log1.session_id == session_id, "Session ID should match specified value"
        # 両方のログが保存されている
        assert log1.id is not None
        assert log2.id is not None

    @pytest.mark.asyncio
    async def test_ai_conversion_log_with_error(self, db_session) -> None:
        """
        UT-005: エラー情報を含むログ作成

        テスト手順:
            1. AIConversionLog.create_logを呼び出す
               - is_success: False
               - error_message: "AI API timeout"
            2. データベースに保存

        期待結果:
            - log.is_success がFalseである
            - log.error_message が"AI API timeout"である
            - ログが正常に保存される

        関連要件ID: FR-003
        優先度: 中
        """
        from app.models.ai_conversion_logs import AIConversionLog

        log = AIConversionLog.create_log(
            input_text="エラーテスト",
            output_text="",
            politeness_level="normal",
            conversion_time_ms=5000,
            is_success=False,
            error_message="AI API timeout",
        )

        db_session.add(log)
        await db_session.commit()
        await db_session.refresh(log)

        assert log.is_success is False, "is_success should be False"
        assert log.error_message == "AI API timeout", f"Error message mismatch: {log.error_message}"
        assert log.id is not None

    @pytest.mark.asyncio
    async def test_ai_conversion_log_auto_session_id(self, db_session) -> None:
        """
        UT-006: セッションID自動生成

        テスト手順:
            1. session_idを指定せずにcreate_logを呼び出す
            2. 生成されたsession_idを確認

        期待結果:
            - log.session_id がNoneではない
            - log.session_id がUUID形式である

        関連要件ID: FR-003
        優先度: 中
        """
        from app.models.ai_conversion_logs import AIConversionLog

        # session_idを指定せずに作成
        log = AIConversionLog.create_log(
            input_text="自動生成テスト",
            output_text="結果",
            politeness_level="casual",
            conversion_time_ms=100,
        )

        assert log.session_id is not None, "session_id should be auto-generated"
        assert isinstance(log.session_id, uuid.UUID), "session_id should be UUID type"

    @pytest.mark.asyncio
    async def test_ai_conversion_log_direct_instantiation(self, db_session) -> None:
        """
        UT-007: インスタンス直接作成（create_logを使用しない場合）

        テスト手順:
            1. AIConversionLogコンストラクタを直接呼び出す
               - 全必須フィールドを指定
            2. インスタンスの各フィールドを確認

        期待結果:
            - 指定した値がすべて正しく設定されている
            - idとcreated_atはDB保存前はNone

        関連要件ID: FR-001
        優先度: 低
        """
        from app.models.ai_conversion_logs import AIConversionLog

        session_id = uuid.uuid4()
        log = AIConversionLog(
            input_text_hash="a" * 64,
            input_length=10,
            output_length=20,
            politeness_level="polite",
            conversion_time_ms=500,
            ai_provider="openai",
            is_success=True,
            session_id=session_id,
        )

        # 指定した値が正しく設定されている
        assert log.input_text_hash == "a" * 64
        assert log.input_length == 10
        assert log.output_length == 20
        assert log.politeness_level == "polite"
        assert log.conversion_time_ms == 500
        assert log.ai_provider == "openai"
        assert log.is_success is True
        assert log.session_id == session_id

        # DB保存前はidはNone
        assert log.id is None, "ID should be None before saving"


class TestErrorLogModel:
    """
    ErrorLogモデルのテストクラス

    FR-004: エラーログテーブルの定義
    """

    @pytest.mark.asyncio
    async def test_error_log_create(self, db_session) -> None:
        """
        UT-008: ErrorLogの正常作成

        テスト手順:
            1. ErrorLogインスタンスを作成
               - error_type: "NetworkException"
               - error_message: "AI API接続エラー"
               - error_code: "AI_001"
               - endpoint: "/api/v1/ai/convert"
               - http_method: "POST"
            2. データベースに保存しrefresh

        期待結果:
            - error_log.id が自動生成されている
            - error_log.error_type が"NetworkException"である
            - error_log.error_message が"AI API接続エラー"である
            - error_log.created_at がdatetime型である

        関連要件ID: FR-004, AC-005
        優先度: 高
        """
        from app.models.error_logs import ErrorLog

        error_log = ErrorLog(
            error_type="NetworkException",
            error_message="AI API接続エラー",
            error_code="AI_001",
            endpoint="/api/v1/ai/convert",
            http_method="POST",
        )

        db_session.add(error_log)
        await db_session.commit()
        await db_session.refresh(error_log)

        assert error_log.id is not None, "ID should be auto-generated"
        assert isinstance(error_log.id, int), "ID should be an integer"
        assert error_log.error_type == "NetworkException"
        assert error_log.error_message == "AI API接続エラー"
        assert error_log.error_code == "AI_001"
        assert error_log.endpoint == "/api/v1/ai/convert"
        assert error_log.http_method == "POST"
        assert isinstance(error_log.created_at, datetime)

    @pytest.mark.asyncio
    async def test_error_log_required_fields_only(self, db_session) -> None:
        """
        UT-009: ErrorLogの必須フィールドのみで作成

        テスト手順:
            1. ErrorLogインスタンスを作成（必須フィールドのみ）
               - error_type: "ValidationError"
               - error_message: "Invalid input"
            2. データベースに保存

        期待結果:
            - ログが正常に保存される
            - オプションフィールド（error_code, endpoint, http_method, stack_trace）がNullである

        関連要件ID: FR-004
        優先度: 中
        """
        from app.models.error_logs import ErrorLog

        error_log = ErrorLog(
            error_type="ValidationError",
            error_message="Invalid input",
        )

        db_session.add(error_log)
        await db_session.commit()
        await db_session.refresh(error_log)

        assert error_log.id is not None
        assert error_log.error_type == "ValidationError"
        assert error_log.error_message == "Invalid input"
        # オプションフィールドがNone
        assert error_log.error_code is None
        assert error_log.endpoint is None
        assert error_log.http_method is None
        assert error_log.stack_trace is None

    @pytest.mark.asyncio
    async def test_error_log_with_stack_trace(self, db_session) -> None:
        """
        UT-010: ErrorLogのスタックトレース保存

        テスト手順:
            1. ErrorLogインスタンスを作成（stack_trace含む）
               - stack_trace: "Traceback (most recent call last):\n  File..."
            2. データベースに保存

        期待結果:
            - stack_traceが切り捨てられずに保存される

        関連要件ID: FR-004
        優先度: 低
        """
        from app.models.error_logs import ErrorLog

        # 長いスタックトレース
        stack_trace = """Traceback (most recent call last):
  File "/app/api/routes.py", line 45, in convert_text
    result = await ai_service.convert(text)
  File "/app/services/ai_service.py", line 100, in convert
    response = await client.post(url, json=payload)
  File "/usr/local/lib/python3.10/httpx/client.py", line 500, in post
    return await self.request("POST", url, **kwargs)
TimeoutError: Connection timed out after 30 seconds"""

        error_log = ErrorLog(
            error_type="TimeoutError",
            error_message="Connection timed out",
            stack_trace=stack_trace,
        )

        db_session.add(error_log)
        await db_session.commit()
        await db_session.refresh(error_log)

        # スタックトレースが切り捨てられずに保存される
        assert error_log.stack_trace == stack_trace, "Stack trace should be preserved"


class TestPolitenessLevelValidation:
    """
    丁寧さレベル（politeness_level）のバリデーションテスト

    AC-007: 丁寧さレベルの制約確認
    """

    @pytest.mark.asyncio
    async def test_politeness_level_casual(self, db_session) -> None:
        """
        UT-015: 丁寧さレベルの有効値テスト（casual）

        テスト手順:
            1. politeness_level="casual"でログを作成
            2. データベースに保存

        期待結果:
            - ログが正常に保存される

        関連要件ID: FR-001, AC-007
        優先度: 中
        """
        from app.models.ai_conversion_logs import AIConversionLog

        log = AIConversionLog.create_log(
            input_text="テスト",
            output_text="結果",
            politeness_level="casual",
            conversion_time_ms=100,
        )

        db_session.add(log)
        await db_session.commit()
        await db_session.refresh(log)

        assert log.id is not None
        assert log.politeness_level == "casual"

    @pytest.mark.asyncio
    async def test_politeness_level_normal(self, db_session) -> None:
        """
        UT-016: 丁寧さレベルの有効値テスト（normal）

        テスト手順:
            1. politeness_level="normal"でログを作成
            2. データベースに保存

        期待結果:
            - ログが正常に保存される

        関連要件ID: FR-001, AC-007
        優先度: 中
        """
        from app.models.ai_conversion_logs import AIConversionLog

        log = AIConversionLog.create_log(
            input_text="テスト",
            output_text="結果",
            politeness_level="normal",
            conversion_time_ms=100,
        )

        db_session.add(log)
        await db_session.commit()
        await db_session.refresh(log)

        assert log.id is not None
        assert log.politeness_level == "normal"

    @pytest.mark.asyncio
    async def test_politeness_level_polite(self, db_session) -> None:
        """
        UT-017: 丁寧さレベルの有効値テスト（polite）

        テスト手順:
            1. politeness_level="polite"でログを作成
            2. データベースに保存

        期待結果:
            - ログが正常に保存される

        関連要件ID: FR-001, AC-007
        優先度: 中
        """
        from app.models.ai_conversion_logs import AIConversionLog

        log = AIConversionLog.create_log(
            input_text="テスト",
            output_text="結果です",
            politeness_level="polite",
            conversion_time_ms=100,
        )

        db_session.add(log)
        await db_session.commit()
        await db_session.refresh(log)

        assert log.id is not None
        assert log.politeness_level == "polite"

    @pytest.mark.asyncio
    async def test_politeness_level_invalid(self, db_session) -> None:
        """
        UT-018: 丁寧さレベルの不正値テスト

        テスト手順:
            1. politeness_level="invalid_level"でログを作成
            2. バリデーションエラーが発生することを確認

        期待結果:
            - ValueError（バリデーションエラー）またはIntegrityError（CHECK制約違反）が発生する

        関連要件ID: FR-001, AC-007
        優先度: 高
        """
        from app.models.ai_conversion_logs import AIConversionLog

        # create_logメソッドでバリデーションエラーが発生
        with pytest.raises((IntegrityError, ValueError)):
            AIConversionLog.create_log(
                input_text="テスト",
                output_text="結果",
                politeness_level="invalid_level",  # 不正な値
                conversion_time_ms=100,
            )


class TestRequiredFieldValidation:
    """
    必須フィールドのバリデーションテスト
    """

    @pytest.mark.asyncio
    async def test_missing_input_text_hash(self, db_session) -> None:
        """
        UT-019: 必須フィールド欠落テスト（input_text_hash）

        テスト手順:
            1. input_text_hashを指定せずにAIConversionLogを作成（直接インスタンス化）
            2. データベースに保存を試みる

        期待結果:
            - IntegrityError（NOT NULL制約違反）が発生する

        関連要件ID: FR-001
        優先度: 高
        """
        from app.models.ai_conversion_logs import AIConversionLog

        # input_text_hashを指定せずに直接インスタンス化
        log = AIConversionLog(
            # input_text_hash intentionally missing
            input_length=5,
            output_length=10,
            politeness_level="normal",
            session_id=uuid.uuid4(),
        )

        db_session.add(log)

        # NOT NULL制約違反でIntegrityErrorが発生
        with pytest.raises(IntegrityError):
            await db_session.commit()

    @pytest.mark.asyncio
    async def test_missing_error_type(self, db_session) -> None:
        """
        UT-020: 必須フィールド欠落テスト（error_type）

        テスト手順:
            1. error_typeを指定せずにErrorLogを作成
            2. データベースに保存を試みる

        期待結果:
            - IntegrityError（NOT NULL制約違反）が発生する

        関連要件ID: FR-004
        優先度: 高
        """
        from app.models.error_logs import ErrorLog

        # error_typeを指定せずにインスタンス化
        error_log = ErrorLog(
            # error_type intentionally missing
            error_message="Test error message",
        )

        db_session.add(error_log)

        # NOT NULL制約違反でIntegrityErrorが発生
        with pytest.raises(IntegrityError):
            await db_session.commit()


class TestBoundaryValues:
    """
    境界値テスト
    """

    @pytest.mark.asyncio
    async def test_input_length_zero(self, db_session) -> None:
        """
        UT-021: input_lengthの境界値テスト（0）

        テスト手順:
            1. 空文字列でcreate_logを呼び出す

        期待結果:
            - input_lengthが0である

        関連要件ID: FR-001
        優先度: 低
        """
        from app.models.ai_conversion_logs import AIConversionLog

        log = AIConversionLog.create_log(
            input_text="",  # 空文字列
            output_text="結果",
            politeness_level="normal",
            conversion_time_ms=100,
        )

        assert log.input_length == 0, f"Input length should be 0, got {log.input_length}"

    @pytest.mark.asyncio
    async def test_conversion_time_ms_zero(self, db_session) -> None:
        """
        UT-022: conversion_time_msの境界値テスト（0）

        テスト手順:
            1. conversion_time_ms=0でログを作成
            2. データベースに保存

        期待結果:
            - ログが正常に保存される
            - conversion_time_msが0である（Noneではない）

        関連要件ID: FR-001, NFR-004
        優先度: 低
        """
        from app.models.ai_conversion_logs import AIConversionLog

        log = AIConversionLog.create_log(
            input_text="テスト",
            output_text="結果",
            politeness_level="normal",
            conversion_time_ms=0,
        )

        db_session.add(log)
        await db_session.commit()
        await db_session.refresh(log)

        assert log.id is not None
        assert log.conversion_time_ms == 0, f"Expected 0, got {log.conversion_time_ms}"
        assert log.conversion_time_ms is not None

    @pytest.mark.asyncio
    async def test_conversion_time_ms_large(self, db_session) -> None:
        """
        UT-023: conversion_time_msの境界値テスト（大きい値）

        テスト手順:
            1. conversion_time_ms=999999でログを作成
            2. データベースに保存

        期待結果:
            - ログが正常に保存される
            - conversion_time_msが999999である

        関連要件ID: FR-001, NFR-004
        優先度: 低
        """
        from app.models.ai_conversion_logs import AIConversionLog

        log = AIConversionLog.create_log(
            input_text="テスト",
            output_text="結果",
            politeness_level="normal",
            conversion_time_ms=999999,
        )

        db_session.add(log)
        await db_session.commit()
        await db_session.refresh(log)

        assert log.id is not None
        assert log.conversion_time_ms == 999999


class TestPrivacyProtection:
    """
    プライバシー保護のテスト

    NFR-001: 入力テキストのハッシュ化必須
    NFR-002: 個人情報の非保存
    """

    @pytest.mark.asyncio
    async def test_privacy_no_plaintext_stored(self, db_session) -> None:
        """
        UT-024: プライバシー保護確認テスト

        テスト手順:
            1. 特定のテキスト"秘密のメッセージ"でログを作成
            2. データベースに保存
            3. 保存されたログを取得
            4. モデルの全属性を調査

        期待結果:
            - input_text_hashには元のテキストが含まれていない
            - モデルにinput_text属性が存在しない（またはNone）
            - ハッシュ値から元のテキストを復元できない

        関連要件ID: NFR-001, NFR-002
        優先度: 高
        """
        from app.models.ai_conversion_logs import AIConversionLog

        secret_text = "秘密のメッセージ"  # noqa: S105
        log = AIConversionLog.create_log(
            input_text=secret_text,
            output_text="変換結果",
            politeness_level="polite",
            conversion_time_ms=100,
        )

        db_session.add(log)
        await db_session.commit()
        await db_session.refresh(log)

        # input_text_hashには元のテキストが含まれていない
        assert secret_text not in log.input_text_hash, "Plain text should not be in hash"

        # モデルにinput_text属性が存在しない（またはNone）
        assert (
            not hasattr(log, "input_text") or getattr(log, "input_text", None) is None
        ), "Model should not have input_text attribute"

        # ハッシュ値は64文字の16進数
        assert len(log.input_text_hash) == 64
        assert re.match(r"^[0-9a-f]{64}$", log.input_text_hash)

        # モデルの全属性をチェック（平文が含まれていないことを確認）
        for attr in dir(log):
            if not attr.startswith("_"):
                value = getattr(log, attr, None)
                if isinstance(value, str):
                    assert secret_text not in value, f"Plain text found in attribute {attr}"


class TestDefaultValues:
    """
    デフォルト値のテスト
    """

    @pytest.mark.asyncio
    async def test_ai_provider_default(self, db_session) -> None:
        """
        UT-025: ai_providerデフォルト値テスト

        テスト手順:
            1. ai_providerを指定せずにログを作成
            2. データベースに保存

        期待結果:
            - ai_providerが"anthropic"である（デフォルト値）

        関連要件ID: FR-001
        優先度: 低
        """
        from app.models.ai_conversion_logs import AIConversionLog

        log = AIConversionLog.create_log(
            input_text="テスト",
            output_text="結果",
            politeness_level="normal",
            conversion_time_ms=100,
            # ai_provider not specified
        )

        db_session.add(log)
        await db_session.commit()
        await db_session.refresh(log)

        provider = log.ai_provider
        assert provider == "anthropic", f"Default ai_provider should be anthropic, got {provider}"

    @pytest.mark.asyncio
    async def test_is_success_default(self, db_session) -> None:
        """
        UT-026: is_successデフォルト値テスト

        テスト手順:
            1. is_successを指定せずにログを作成
            2. データベースに保存

        期待結果:
            - is_successがTrueである（デフォルト値）

        関連要件ID: FR-001
        優先度: 低
        """
        from app.models.ai_conversion_logs import AIConversionLog

        log = AIConversionLog.create_log(
            input_text="テスト",
            output_text="結果",
            politeness_level="normal",
            conversion_time_ms=100,
            # is_success not specified
        )

        db_session.add(log)
        await db_session.commit()
        await db_session.refresh(log)

        assert log.is_success is True, f"Default is_success should be True, got {log.is_success}"


class TestModelTableName:
    """
    モデルのテーブル名テスト
    """

    def test_ai_conversion_log_table_name(self) -> None:
        """
        AIConversionLogのテーブル名確認

        期待結果:
            - テーブル名が"ai_conversion_logs"である
        """
        from app.models.ai_conversion_logs import AIConversionLog

        assert AIConversionLog.__tablename__ == "ai_conversion_logs"

    def test_error_log_table_name(self) -> None:
        """
        ErrorLogのテーブル名確認

        期待結果:
            - テーブル名が"error_logs"である
        """
        from app.models.error_logs import ErrorLog

        assert ErrorLog.__tablename__ == "error_logs"


class TestModelRepr:
    """
    モデルの文字列表現（__repr__）テスト

    【改善内容】: Refactorフェーズでカバレッジ100%達成のために追加
    """

    def test_ai_conversion_log_repr(self) -> None:
        """
        AIConversionLogの__repr__テスト

        期待結果:
            - __repr__が期待されるフォーマットで文字列を返す
        """
        from app.models.ai_conversion_logs import AIConversionLog

        log = AIConversionLog.create_log(
            input_text="テスト",
            output_text="結果",
            politeness_level="normal",
            conversion_time_ms=100,
        )

        repr_str = repr(log)
        assert "<AIConversionLog(" in repr_str
        assert "politeness_level='normal'" in repr_str
        assert "is_success=True" in repr_str

    def test_error_log_repr(self) -> None:
        """
        ErrorLogの__repr__テスト

        期待結果:
            - __repr__が期待されるフォーマットで文字列を返す
        """
        from app.models.error_logs import ErrorLog

        error_log = ErrorLog(
            error_type="TestError",
            error_message="Test message",
            error_code="TEST_001",
        )

        repr_str = repr(error_log)
        assert "<ErrorLog(" in repr_str
        assert "error_type='TestError'" in repr_str
        assert "error_code='TEST_001'" in repr_str


class TestModelRegistration:
    """
    モデル登録のテスト

    FR-006: Baseへのモデル登録
    """

    def test_models_registered_in_base(self) -> None:
        """
        IT-015: app/db/base.pyへのモデル登録確認

        テスト手順:
            1. app.db.baseからインポートを試みる
            2. __all__の内容を確認

        期待結果:
            - AIConversionLogがインポート可能
            - ErrorLogがインポート可能
            - __all__に両モデルが含まれている

        関連要件ID: FR-006
        優先度: 高
        """
        from app.db.base import AIConversionLog, ErrorLog

        # インポートが成功すれば、モデルが登録されている
        assert AIConversionLog is not None
        assert ErrorLog is not None

        # __all__の確認（オプション）
        from app.db import base

        if hasattr(base, "__all__"):
            assert "AIConversionLog" in base.__all__
            assert "ErrorLog" in base.__all__
