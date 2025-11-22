"""
AI変換機能Pydanticスキーマ定義

TASK-0023: AI変換リクエスト・レスポンススキーマ
🔵 api-endpoints.md（line 86-276）に基づく実装
"""

from pydantic import BaseModel, Field, field_validator

from app.schemas.common import PolitenessLevel

# ==============================================================================
# 定数定義
# ==============================================================================

# 入力文字列の文字数制限
INPUT_TEXT_MIN_LENGTH: int = 2
INPUT_TEXT_MAX_LENGTH: int = 500

# エラーメッセージ定数
ERROR_INPUT_TEXT_REQUIRED: str = "入力文字列は必須です"
ERROR_INPUT_TEXT_EMPTY: str = "入力文字列が空です"
ERROR_INPUT_TEXT_MIN_LENGTH: str = f"入力文字列は{INPUT_TEXT_MIN_LENGTH}文字以上にしてください"
ERROR_INPUT_TEXT_MAX_LENGTH: str = f"入力文字列は{INPUT_TEXT_MAX_LENGTH}文字以下にしてください"
ERROR_PREVIOUS_RESULT_REQUIRED: str = "前回の変換結果は必須です"
ERROR_PREVIOUS_RESULT_EMPTY: str = "前回の変換結果が空です"


# ==============================================================================
# 共通バリデーション関数
# ==============================================================================


def validate_input_text(v: object) -> str:
    """入力文字列の共通バリデーションとトリム

    🔵 api-endpoints.mdのバリデーション仕様に基づく実装
    前後の空白を除去し、文字数制限をチェックする。

    Args:
        v: 入力値（文字列を期待）

    Returns:
        トリムされた入力文字列

    Raises:
        ValueError: 入力が空、空白のみ、または文字数制限違反の場合
    """
    if v is None:
        raise ValueError(ERROR_INPUT_TEXT_REQUIRED)
    trimmed = str(v).strip()
    if not trimmed:
        raise ValueError(ERROR_INPUT_TEXT_EMPTY)
    if len(trimmed) < INPUT_TEXT_MIN_LENGTH:
        raise ValueError(ERROR_INPUT_TEXT_MIN_LENGTH)
    if len(trimmed) > INPUT_TEXT_MAX_LENGTH:
        raise ValueError(ERROR_INPUT_TEXT_MAX_LENGTH)
    return trimmed


def validate_required_string(v: object, error_required: str, error_empty: str) -> str:
    """必須文字列の共通バリデーションとトリム

    Args:
        v: 入力値（文字列を期待）
        error_required: 必須エラーメッセージ
        error_empty: 空文字列エラーメッセージ

    Returns:
        トリムされた入力文字列

    Raises:
        ValueError: 入力が空または空白のみの場合
    """
    if v is None:
        raise ValueError(error_required)
    trimmed = str(v).strip()
    if not trimmed:
        raise ValueError(error_empty)
    return trimmed


# ==============================================================================
# リクエストスキーマ
# ==============================================================================


class AIConversionRequest(BaseModel):
    """AI変換リクエストスキーマ

    🔵 api-endpoints.md（line 86-150）に基づく実装
    AI変換APIへのリクエストデータを定義するスキーマ。
    入力テキストと丁寧さレベルを指定する。

    Attributes:
        input_text: 変換する入力文字列（2文字以上500文字以下）
        politeness_level: 丁寧さレベル（casual/normal/polite）

    Examples:
        >>> request = AIConversionRequest(
        ...     input_text="水 ぬるく",
        ...     politeness_level=PolitenessLevel.POLITE,
        ... )
    """

    input_text: str = Field(
        ...,
        min_length=INPUT_TEXT_MIN_LENGTH,
        max_length=INPUT_TEXT_MAX_LENGTH,
        description=f"変換する入力文字列（{INPUT_TEXT_MIN_LENGTH}文字以上{INPUT_TEXT_MAX_LENGTH}文字以下）",
        examples=["ありがとう"],
    )
    politeness_level: PolitenessLevel = Field(
        ...,
        description="丁寧さレベル（casual/normal/polite）",
        examples=["polite"],
    )

    @field_validator("input_text", mode="before")
    @classmethod
    def validate_and_trim_input_text(cls, v: object) -> str:
        """入力文字列のバリデーションとトリム"""
        return validate_input_text(v)


class AIConversionResponse(BaseModel):
    """AI変換レスポンススキーマ

    AI変換APIからのレスポンスデータを定義するスキーマ。

    Attributes:
        converted_text: 変換後の文字列
        original_text: 元の入力文字列
        politeness_level: 適用された丁寧さレベル
        processing_time_ms: 変換処理時間（ミリ秒）

    Examples:
        >>> response = AIConversionResponse(
        ...     converted_text="ありがとうございます",
        ...     original_text="ありがとう",
        ...     politeness_level=PolitenessLevel.POLITE,
        ...     processing_time_ms=1500,
        ... )
    """

    converted_text: str = Field(
        ...,
        description="変換後の文字列",
        examples=["ありがとうございます"],
    )
    original_text: str = Field(
        ...,
        description="元の入力文字列",
        examples=["ありがとう"],
    )
    politeness_level: PolitenessLevel = Field(
        ...,
        description="適用された丁寧さレベル",
        examples=["polite"],
    )
    processing_time_ms: int = Field(
        ...,
        description="変換処理時間（ミリ秒）",
        examples=[1500],
    )

    model_config = {
        "from_attributes": True,
        "json_schema_extra": {
            "example": {
                "converted_text": "ありがとうございます",
                "original_text": "ありがとう",
                "politeness_level": "polite",
                "processing_time_ms": 1500,
            }
        },
    }


class AIRegenerateRequest(BaseModel):
    """AI再変換リクエストスキーマ

    🔵 api-endpoints.md（line 151-276）に基づく実装
    AI再変換APIへのリクエストデータを定義するスキーマ。
    前回の結果と異なる変換結果を得るために使用する。

    Attributes:
        input_text: 変換元テキスト（2文字以上500文字以下）
        politeness_level: 丁寧さレベル
        previous_result: 前回の変換結果（重複回避用）

    Examples:
        >>> request = AIRegenerateRequest(
        ...     input_text="水 ぬるく",
        ...     politeness_level=PolitenessLevel.POLITE,
        ...     previous_result="お水をぬるめでお願いします",
        ... )
    """

    input_text: str = Field(
        ...,
        min_length=INPUT_TEXT_MIN_LENGTH,
        max_length=INPUT_TEXT_MAX_LENGTH,
        description=f"変換元テキスト（{INPUT_TEXT_MIN_LENGTH}文字以上{INPUT_TEXT_MAX_LENGTH}文字以下）",
        examples=["ありがとう"],
    )
    politeness_level: PolitenessLevel = Field(
        ...,
        description="丁寧さレベル",
        examples=["polite"],
    )
    previous_result: str = Field(
        ...,
        description="前回の変換結果（重複回避用）",
        examples=["ありがとうございます"],
    )

    @field_validator("input_text", mode="before")
    @classmethod
    def validate_and_trim_input_text(cls, v: object) -> str:
        """入力文字列のバリデーションとトリム"""
        return validate_input_text(v)

    @field_validator("previous_result", mode="before")
    @classmethod
    def validate_previous_result(cls, v: object) -> str:
        """前回結果のバリデーション"""
        return validate_required_string(
            v, ERROR_PREVIOUS_RESULT_REQUIRED, ERROR_PREVIOUS_RESULT_EMPTY
        )
