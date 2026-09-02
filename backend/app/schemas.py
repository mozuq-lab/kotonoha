"""HTTP の入出力スキーマ。旧実装の外部契約（フィールド名・制約・検証文言）を維持する。"""

from __future__ import annotations

from pydantic import BaseModel, Field, field_validator

from app.ai.prompts import PolitenessLevel

INPUT_TEXT_MIN_LENGTH = 2
INPUT_TEXT_MAX_LENGTH = 500
PREVIOUS_RESULT_MAX_LENGTH = 1000


def _required_trimmed(value: object, *, required: str, empty: str) -> str:
    if value is None:
        raise ValueError(required)
    trimmed = str(value).strip()
    if not trimmed:
        raise ValueError(empty)
    return trimmed


class ConversionRequest(BaseModel):
    input_text: str = Field(
        ...,
        min_length=INPUT_TEXT_MIN_LENGTH,
        max_length=INPUT_TEXT_MAX_LENGTH,
        description=f"変換する入力文字列（{INPUT_TEXT_MIN_LENGTH}文字以上{INPUT_TEXT_MAX_LENGTH}文字以下）",
        examples=["ありがとう"],
    )
    politeness_level: PolitenessLevel = Field(
        ..., description="丁寧さレベル（casual/normal/polite）", examples=["polite"]
    )

    @field_validator("input_text", mode="before")
    @classmethod
    def _trim_input_text(cls, value: object) -> str:
        trimmed = _required_trimmed(
            value, required="入力文字列は必須です", empty="入力文字列が空です"
        )
        if len(trimmed) < INPUT_TEXT_MIN_LENGTH:
            raise ValueError(f"入力文字列は{INPUT_TEXT_MIN_LENGTH}文字以上にしてください")
        if len(trimmed) > INPUT_TEXT_MAX_LENGTH:
            raise ValueError(f"入力文字列は{INPUT_TEXT_MAX_LENGTH}文字以下にしてください")
        return trimmed


class RegenerateRequest(ConversionRequest):
    previous_result: str = Field(
        ...,
        max_length=PREVIOUS_RESULT_MAX_LENGTH,
        description=f"前回の変換結果（重複回避用、{PREVIOUS_RESULT_MAX_LENGTH}文字以下）",
        examples=["ありがとうございます"],
    )

    @field_validator("previous_result", mode="before")
    @classmethod
    def _trim_previous_result(cls, value: object) -> str:
        trimmed = _required_trimmed(
            value, required="前回の変換結果は必須です", empty="前回の変換結果が空です"
        )
        if len(trimmed) > PREVIOUS_RESULT_MAX_LENGTH:
            raise ValueError(f"前回の変換結果は{PREVIOUS_RESULT_MAX_LENGTH}文字以下にしてください")
        return trimmed


class ConversionResponse(BaseModel):
    converted_text: str = Field(..., description="変換後の文字列")
    original_text: str = Field(..., description="元の入力文字列（前後の空白を除く）")
    politeness_level: PolitenessLevel = Field(..., description="適用された丁寧さレベル")
    processing_time_ms: int = Field(..., description="変換処理時間（ミリ秒）")


class HealthResponse(BaseModel):
    status: str = Field(..., examples=["ok"])
    ai_provider: str = Field(
        ..., description="実際に使う AI プロバイダ", examples=["anthropic", "openai", "none"]
    )
    version: str = Field(..., examples=["1.0.0"])
    timestamp: str = Field(..., description="ISO 8601（UTC）", examples=["2026-09-02T12:34:56Z"])
