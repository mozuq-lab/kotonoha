"""
AI変換機能Pydanticスキーマのテスト

TASK-0023: Pydanticスキーマ定義（AI変換リクエスト・レスポンス）
テストケース一覧（testcases.md）に基づくTDDレッドフェーズ実装

【テストカテゴリ】:
- A. PolitenessLevel列挙型テスト
- B. AIConversionRequestバリデーションテスト
- C. AIConversionResponseテスト
- D. AIRegenerateRequestテスト
- E. ApiResponseラッパーテスト
- F. ErrorDetail/ErrorResponseテスト
"""

import pytest
from pydantic import ValidationError

from app.schemas.ai_conversion import (
    AIConversionRequest,
    AIConversionResponse,
    AIRegenerateRequest,
)
from app.schemas.common import (
    ApiResponse,
    ErrorDetail,
    PolitenessLevel,
)

# ==============================================================================
# A. PolitenessLevel列挙型テスト
# ==============================================================================


class TestPolitenessLevel:
    """
    PolitenessLevel列挙型のテストクラス

    【テスト目的】: 丁寧さレベル列挙型が正しく定義されていることを確認
    【関連要件】: FR-1, VR-2
    """

    def test_casual_value(self) -> None:
        """
        TC-A01: casual値の定義

        【テスト内容】: PolitenessLevel.CASUALの値が"casual"であることを確認
        【期待結果】: PolitenessLevel.CASUAL.value == "casual"
        【関連要件】: FR-1
        """
        assert PolitenessLevel.CASUAL.value == "casual"

    def test_normal_value(self) -> None:
        """
        TC-A02: normal値の定義

        【テスト内容】: PolitenessLevel.NORMALの値が"normal"であることを確認
        【期待結果】: PolitenessLevel.NORMAL.value == "normal"
        【関連要件】: FR-1
        """
        assert PolitenessLevel.NORMAL.value == "normal"

    def test_polite_value(self) -> None:
        """
        TC-A03: polite値の定義

        【テスト内容】: PolitenessLevel.POLITEの値が"polite"であることを確認
        【期待結果】: PolitenessLevel.POLITE.value == "polite"
        【関連要件】: FR-1
        """
        assert PolitenessLevel.POLITE.value == "polite"

    def test_invalid_value_raises_error(self) -> None:
        """
        TC-A04: 不正な値の拒否

        【テスト内容】: 定義されていない値が拒否されることを確認
        【期待結果】: ValueError が発生
        【関連要件】: VR-2
        """
        with pytest.raises(ValueError):
            PolitenessLevel("invalid")

    def test_uppercase_value_raises_error(self) -> None:
        """
        TC-A04: 大文字の値の拒否

        【テスト内容】: 大文字の"CASUAL"が拒否されることを確認
        【期待結果】: ValueError が発生
        【関連要件】: VR-2
        """
        with pytest.raises(ValueError):
            PolitenessLevel("CASUAL")

    def test_string_conversion(self) -> None:
        """
        TC-A05: 文字列からの変換

        【テスト内容】: 文字列"casual", "normal", "polite"から列挙型への変換が正しく動作する
        【期待結果】: 対応するPolitenessLevel列挙型に変換される
        【関連要件】: FR-1
        """
        assert PolitenessLevel("casual") == PolitenessLevel.CASUAL
        assert PolitenessLevel("normal") == PolitenessLevel.NORMAL
        assert PolitenessLevel("polite") == PolitenessLevel.POLITE


# ==============================================================================
# B. AIConversionRequestバリデーションテスト
# ==============================================================================


class TestAIConversionRequest:
    """
    AIConversionRequestスキーマのテストクラス

    【テスト目的】: AI変換リクエストスキーマのバリデーションが正しく動作することを確認
    【関連要件】: FR-2, VR-1, VR-2, VR-4
    """

    def test_valid_request_with_normal_text(self) -> None:
        """
        TC-B01: 正常なリクエスト（通常文字列）

        【テスト内容】: 正常なパラメータでAIConversionRequestが生成できることを確認
        【期待結果】: インスタンスが正常に生成される
        【関連要件】: FR-2
        """
        request = AIConversionRequest(
            input_text="水 ぬるく",
            politeness_level=PolitenessLevel.NORMAL,
        )
        assert request.input_text == "水 ぬるく"
        assert request.politeness_level == PolitenessLevel.NORMAL

    def test_minimum_length_boundary(self) -> None:
        """
        TC-B02: 最小文字数（2文字）の境界値

        【テスト内容】: 最小文字数（2文字）のinput_textが受け入れられることを確認
        【期待結果】: インスタンスが正常に生成される
        【関連要件】: VR-1, VR-4
        """
        request = AIConversionRequest(
            input_text="あい",
            politeness_level=PolitenessLevel.NORMAL,
        )
        assert len(request.input_text) == 2

    def test_maximum_length_boundary(self) -> None:
        """
        TC-B03: 最大文字数（500文字）の境界値

        【テスト内容】: 最大文字数（500文字）のinput_textが受け入れられることを確認
        【期待結果】: インスタンスが正常に生成される
        【関連要件】: VR-1, VR-4
        """
        text = "あ" * 500
        request = AIConversionRequest(
            input_text=text,
            politeness_level=PolitenessLevel.NORMAL,
        )
        assert len(request.input_text) == 500

    def test_below_minimum_length_error(self) -> None:
        """
        TC-B04: 最小未満（1文字）はエラー

        【テスト内容】: 1文字のinput_textがバリデーションエラーになることを確認
        【期待結果】: ValidationError発生（2文字未満）
        【関連要件】: VR-1, VR-4
        """
        with pytest.raises(ValidationError) as exc_info:
            AIConversionRequest(
                input_text="あ",
                politeness_level=PolitenessLevel.NORMAL,
            )
        # エラーメッセージに文字数制限に関する情報が含まれることを確認
        error_str = str(exc_info.value)
        assert "2" in error_str or "min_length" in error_str or "文字" in error_str

    def test_above_maximum_length_error(self) -> None:
        """
        TC-B05: 最大超過（501文字）はエラー

        【テスト内容】: 501文字のinput_textがバリデーションエラーになることを確認
        【期待結果】: ValidationError発生（500文字超過）
        【関連要件】: VR-1, VR-4
        """
        text = "あ" * 501
        with pytest.raises(ValidationError) as exc_info:
            AIConversionRequest(
                input_text=text,
                politeness_level=PolitenessLevel.NORMAL,
            )
        # エラーメッセージに文字数制限に関する情報が含まれることを確認
        error_str = str(exc_info.value)
        assert "500" in error_str or "max_length" in error_str or "文字" in error_str

    def test_empty_string_error(self) -> None:
        """
        TC-B06: 空文字列はエラー

        【テスト内容】: 空文字列のinput_textがバリデーションエラーになることを確認
        【期待結果】: ValidationError発生
        【関連要件】: VR-1
        """
        with pytest.raises(ValidationError):
            AIConversionRequest(
                input_text="",
                politeness_level=PolitenessLevel.NORMAL,
            )

    def test_whitespace_only_error(self) -> None:
        """
        TC-B07: 空白のみはエラー

        【テスト内容】: 空白のみのinput_textがバリデーションエラーになることを確認
        【期待結果】: ValidationError発生（トリム後に2文字未満）
        【関連要件】: VR-1
        """
        with pytest.raises(ValidationError):
            AIConversionRequest(
                input_text="   ",
                politeness_level=PolitenessLevel.NORMAL,
            )

    def test_whitespace_trimming(self) -> None:
        """
        TC-B08: 前後空白はトリムされる

        【テスト内容】: 前後の空白がトリムされることを確認
        【期待結果】: input_text == "水 ぬるく" （前後の空白がトリムされる）
        【関連要件】: VR-1
        """
        request = AIConversionRequest(
            input_text="  水 ぬるく  ",
            politeness_level=PolitenessLevel.NORMAL,
        )
        assert request.input_text == "水 ぬるく"

    def test_accepts_all_politeness_levels(self) -> None:
        """
        TC-B09: 各丁寧さレベルが受け入れられる

        【テスト内容】: casual, normal, politeの各丁寧さレベルが受け入れられることを確認
        【期待結果】: すべてのケースでインスタンスが正常に生成される
        【関連要件】: FR-2, VR-2
        """
        for level in [PolitenessLevel.CASUAL, PolitenessLevel.NORMAL, PolitenessLevel.POLITE]:
            request = AIConversionRequest(
                input_text="テスト",
                politeness_level=level,
            )
            assert request.politeness_level == level

    def test_missing_input_text_error(self) -> None:
        """
        TC-B10: 必須フィールドの欠落（input_text）

        【テスト内容】: input_textが欠落している場合にエラーになることを確認
        【期待結果】: ValidationError発生（必須フィールド欠落）
        【関連要件】: FR-2
        """
        with pytest.raises(ValidationError):
            AIConversionRequest(
                politeness_level=PolitenessLevel.NORMAL,
            )  # type: ignore[call-arg]

    def test_missing_politeness_level_error(self) -> None:
        """
        TC-B11: 必須フィールドの欠落（politeness_level）

        【テスト内容】: politeness_levelが欠落している場合にエラーになることを確認
        【期待結果】: ValidationError発生（必須フィールド欠落）
        【関連要件】: FR-2
        """
        with pytest.raises(ValidationError):
            AIConversionRequest(
                input_text="テスト",
            )  # type: ignore[call-arg]

    def test_invalid_politeness_level_error(self) -> None:
        """
        TC-B12: 不正なpoliteness_levelはエラー

        【テスト内容】: 不正なpoliteness_level値がバリデーションエラーになることを確認
        【期待結果】: ValidationError発生
        【関連要件】: VR-2
        """
        with pytest.raises(ValidationError):
            AIConversionRequest(
                input_text="テスト",
                politeness_level="invalid",  # type: ignore[arg-type]
            )

    def test_japanese_text_validation(self) -> None:
        """
        TC-B13: 日本語文字列のバリデーション

        【テスト内容】: 日本語文字列（ひらがな、カタカナ、漢字）が正しく処理されることを確認
        【期待結果】: インスタンスが正常に生成される
        【関連要件】: FR-2
        """
        request = AIConversionRequest(
            input_text="お腹すいた ご飯食べたい",
            politeness_level=PolitenessLevel.NORMAL,
        )
        assert request.input_text == "お腹すいた ご飯食べたい"

    def test_mixed_text_validation(self) -> None:
        """
        TC-B14: 混合文字列のバリデーション

        【テスト内容】: 日本語と英数字の混合文字列が正しく処理されることを確認
        【期待結果】: インスタンスが正常に生成される
        【関連要件】: FR-2
        """
        request = AIConversionRequest(
            input_text="ABC123テスト あいう",
            politeness_level=PolitenessLevel.NORMAL,
        )
        assert request.input_text == "ABC123テスト あいう"

    def test_special_characters_validation(self) -> None:
        """
        TC-B15: 絵文字・特殊文字の処理

        【テスト内容】: 絵文字や特殊文字を含む文字列の処理を確認
        【期待結果】: インスタンスが正常に生成される
        【関連要件】: FR-2
        """
        request = AIConversionRequest(
            input_text="こんにちは！テスト。",
            politeness_level=PolitenessLevel.NORMAL,
        )
        assert request.input_text == "こんにちは！テスト。"


# ==============================================================================
# C. AIConversionResponseテスト
# ==============================================================================


class TestAIConversionResponse:
    """
    AIConversionResponseスキーマのテストクラス

    【テスト目的】: AI変換レスポンススキーマが正しく動作することを確認
    【関連要件】: FR-3, NFR-3
    """

    def test_valid_response(self) -> None:
        """
        TC-C01: 正常なレスポンス生成

        【テスト内容】: 正常なパラメータでAIConversionResponseが生成できることを確認
        【期待結果】: インスタンスが正常に生成される、各フィールドに正しい値が設定される
        【関連要件】: FR-3
        """
        response = AIConversionResponse(
            converted_text="お水をぬるめでお願いします",
            original_text="水 ぬるく",
            politeness_level=PolitenessLevel.NORMAL,
            processing_time_ms=2500,
        )
        assert response.converted_text == "お水をぬるめでお願いします"
        assert response.original_text == "水 ぬるく"
        assert response.politeness_level == PolitenessLevel.NORMAL
        assert response.processing_time_ms == 2500

    def test_processing_time_integer(self) -> None:
        """
        TC-C02: 変換時間がintegerで保持される

        【テスト内容】: processing_time_msがinteger型で正しく保持されることを確認
        【期待結果】: processing_time_ms == 1234、型がint
        【関連要件】: FR-3
        """
        response = AIConversionResponse(
            converted_text="テスト",
            original_text="test",
            politeness_level=PolitenessLevel.NORMAL,
            processing_time_ms=1234,
        )
        assert response.processing_time_ms == 1234
        assert isinstance(response.processing_time_ms, int)

    def test_all_politeness_levels_in_response(self) -> None:
        """
        TC-C03: 丁寧さレベルが正しく設定される

        【テスト内容】: 各丁寧さレベルが正しく設定されることを確認
        【期待結果】: すべてのケースで正しい丁寧さレベルが設定される
        【関連要件】: FR-3
        """
        for level in [PolitenessLevel.CASUAL, PolitenessLevel.NORMAL, PolitenessLevel.POLITE]:
            response = AIConversionResponse(
                converted_text="テスト",
                original_text="test",
                politeness_level=level,
                processing_time_ms=100,
            )
            assert response.politeness_level == level

    def test_json_serialization(self) -> None:
        """
        TC-C04: JSONシリアライズ

        【テスト内容】: AIConversionResponseがJSON形式に正しくシリアライズされることを確認
        【期待結果】: JSON形式で正しくシリアライズされる
        【関連要件】: NFR-3
        """
        response = AIConversionResponse(
            converted_text="お水をぬるめでお願いします",
            original_text="水 ぬるく",
            politeness_level=PolitenessLevel.NORMAL,
            processing_time_ms=2500,
        )
        json_data = response.model_dump()
        assert json_data["converted_text"] == "お水をぬるめでお願いします"
        assert json_data["original_text"] == "水 ぬるく"
        assert json_data["politeness_level"] == "normal"
        assert json_data["processing_time_ms"] == 2500

    def test_processing_time_zero(self) -> None:
        """
        TC-C05: processing_time_msが0の場合

        【テスト内容】: processing_time_msが0の場合でも正常に動作することを確認
        【期待結果】: インスタンスが正常に生成される
        【関連要件】: FR-3
        """
        response = AIConversionResponse(
            converted_text="テスト",
            original_text="test",
            politeness_level=PolitenessLevel.NORMAL,
            processing_time_ms=0,
        )
        assert response.processing_time_ms == 0


# ==============================================================================
# D. AIRegenerateRequestテスト
# ==============================================================================


class TestAIRegenerateRequest:
    """
    AIRegenerateRequestスキーマのテストクラス

    【テスト目的】: AI再生成リクエストスキーマのバリデーションが正しく動作することを確認
    【関連要件】: FR-4, VR-3
    """

    def test_valid_regenerate_request(self) -> None:
        """
        TC-D01: 正常なリクエスト

        【テスト内容】: 正常なパラメータでAIRegenerateRequestが生成できることを確認
        【期待結果】: インスタンスが正常に生成される、各フィールドに正しい値が設定される
        【関連要件】: FR-4
        """
        request = AIRegenerateRequest(
            input_text="水 ぬるく",
            politeness_level=PolitenessLevel.NORMAL,
            previous_result="お水をぬるめでお願いします",
        )
        assert request.input_text == "水 ぬるく"
        assert request.politeness_level == PolitenessLevel.NORMAL
        assert request.previous_result == "お水をぬるめでお願いします"

    def test_previous_result_required(self) -> None:
        """
        TC-D02: previous_resultフィールドが必須

        【テスト内容】: previous_resultが欠落している場合にエラーになることを確認
        【期待結果】: ValidationError発生（必須フィールド欠落）
        【関連要件】: FR-4, VR-3
        """
        with pytest.raises(ValidationError):
            AIRegenerateRequest(
                input_text="水 ぬるく",
                politeness_level=PolitenessLevel.NORMAL,
                # previous_result missing
            )  # type: ignore[call-arg]

    def test_previous_result_empty_string_error(self) -> None:
        """
        TC-D03: previous_resultが空文字列はエラー

        【テスト内容】: previous_resultが空文字列の場合にエラーになることを確認
        【期待結果】: ValidationError発生
        【関連要件】: VR-3
        """
        with pytest.raises(ValidationError):
            AIRegenerateRequest(
                input_text="水 ぬるく",
                politeness_level=PolitenessLevel.NORMAL,
                previous_result="",
            )

    def test_inherits_input_text_validation(self) -> None:
        """
        TC-D04: AIConversionRequestと同じバリデーションが適用される

        【テスト内容】: input_textに対してAIConversionRequestと同じ
            バリデーションが適用されることを確認
        【期待結果】: ValidationError発生（2文字未満）
        【関連要件】: VR-1
        """
        with pytest.raises(ValidationError):
            AIRegenerateRequest(
                input_text="水",  # 1文字（最小未満）
                politeness_level=PolitenessLevel.NORMAL,
                previous_result="前回結果",
            )

    def test_previous_result_whitespace_handling(self) -> None:
        """
        TC-D05: previous_resultの空白トリム

        【テスト内容】: previous_resultの前後空白がトリムされるかを確認
        【期待結果】: インスタンスが正常に生成される
        【関連要件】: FR-4
        """
        request = AIRegenerateRequest(
            input_text="テスト",
            politeness_level=PolitenessLevel.NORMAL,
            previous_result="  前回結果  ",
        )
        # 実装時にトリムするかどうかを決定（要件に従う）
        assert request.previous_result is not None
        assert len(request.previous_result.strip()) > 0


# ==============================================================================
# E. ApiResponseラッパーテスト
# ==============================================================================


class TestApiResponse:
    """
    ApiResponseスキーマのテストクラス

    【テスト目的】: 統一APIレスポンス形式が正しく動作することを確認
    【関連要件】: FR-5
    """

    def test_success_response(self) -> None:
        """
        TC-E01: 成功レスポンス（success=true）

        【テスト内容】: 成功時のApiResponseが正しく生成されることを確認
        【期待結果】: success == True、dataに変換結果が含まれる、error == None
        【関連要件】: FR-5
        """
        data = AIConversionResponse(
            converted_text="お水をぬるめでお願いします",
            original_text="水 ぬるく",
            politeness_level=PolitenessLevel.NORMAL,
            processing_time_ms=2500,
        )
        response = ApiResponse(success=True, data=data, error=None)
        assert response.success is True
        assert response.data is not None
        assert response.error is None

    def test_error_response(self) -> None:
        """
        TC-E02: エラーレスポンス（success=false）

        【テスト内容】: エラー時のApiResponseが正しく生成されることを確認
        【期待結果】: success == False、data == None、errorにエラー詳細が含まれる
        【関連要件】: FR-5, ER-1
        """
        error = ErrorDetail(
            code="VALIDATION_ERROR",
            message="入力文字列は2文字以上500文字以下にしてください",
            status_code=400,
        )
        response = ApiResponse(success=False, data=None, error=error)
        assert response.success is False
        assert response.data is None
        assert response.error is not None
        assert response.error.code == "VALIDATION_ERROR"
        assert response.error.status_code == 400


# ==============================================================================
# F. ErrorDetailテスト
# ==============================================================================


class TestErrorDetail:
    """
    ErrorDetailスキーマのテストクラス

    【テスト目的】: エラー詳細スキーマが正しく動作することを確認
    【関連要件】: FR-5
    """

    def test_error_detail_creation(self) -> None:
        """
        TC-E03: ErrorDetailが正しく設定される

        【テスト内容】: ErrorDetailスキーマが正しく設定されることを確認
        【期待結果】: すべてのフィールドが正しく設定される
        【関連要件】: FR-5
        """
        error = ErrorDetail(
            code="AI_API_ERROR",
            message="AI変換APIからのレスポンスに失敗しました。",
            status_code=500,
        )
        assert error.code == "AI_API_ERROR"
        assert error.message == "AI変換APIからのレスポンスに失敗しました。"
        assert error.status_code == 500

    def test_various_error_codes(self) -> None:
        """
        TC-E04: ErrorDetailのcodeがエラーコード一覧に対応

        【テスト内容】: 各エラーコードでErrorDetailが生成できることを確認
        【期待結果】: すべてのエラーコードでインスタンスが生成される
        【関連要件】: FR-5
        """
        error_cases = [
            ("VALIDATION_ERROR", "バリデーションエラー", 400),
            ("AI_API_ERROR", "AI APIエラー", 500),
            ("AI_API_TIMEOUT", "タイムアウト", 504),
            ("RATE_LIMIT_EXCEEDED", "レート制限超過", 429),
            ("INTERNAL_ERROR", "内部エラー", 500),
        ]

        for code, message, status_code in error_cases:
            error = ErrorDetail(
                code=code,
                message=message,
                status_code=status_code,
            )
            assert error.code == code
            assert error.message == message
            assert error.status_code == status_code

    def test_error_detail_json_serialization(self) -> None:
        """
        TC-E03: ErrorDetailのJSONシリアライズ

        【テスト内容】: ErrorDetailがJSON形式に正しくシリアライズされることを確認
        【期待結果】: JSON形式で正しくシリアライズされる
        【関連要件】: FR-5
        """
        error = ErrorDetail(
            code="VALIDATION_ERROR",
            message="入力が不正です",
            status_code=400,
        )
        json_data = error.model_dump()
        assert json_data["code"] == "VALIDATION_ERROR"
        assert json_data["message"] == "入力が不正です"
        assert json_data["status_code"] == 400
