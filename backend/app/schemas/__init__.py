"""
Pydanticスキーマモジュール

【モジュール目的】: APIのリクエスト/レスポンススキーマを定義
【モジュール内容】: 型安全性を確保し、OpenAPI仕様の自動生成を支援
🔵 TASK-0010要件定義書に基づく実装
🔵 TASK-0023: AI変換スキーマ追加
"""

from app.schemas.ai_conversion import (
    # 定数
    ERROR_INPUT_TEXT_EMPTY,
    ERROR_INPUT_TEXT_MAX_LENGTH,
    ERROR_INPUT_TEXT_MIN_LENGTH,
    ERROR_INPUT_TEXT_REQUIRED,
    ERROR_PREVIOUS_RESULT_EMPTY,
    ERROR_PREVIOUS_RESULT_REQUIRED,
    INPUT_TEXT_MAX_LENGTH,
    INPUT_TEXT_MIN_LENGTH,
    # スキーマ
    AIConversionRequest,
    AIConversionResponse,
    AIRegenerateRequest,
)
from app.schemas.common import (
    ApiResponse,
    ErrorDetail,
    ErrorResponse,
    PolitenessLevel,
)

__all__ = [
    # Common schemas
    "PolitenessLevel",
    "ErrorDetail",
    "ErrorResponse",
    "ApiResponse",
    # AI conversion schemas
    "AIConversionRequest",
    "AIConversionResponse",
    "AIRegenerateRequest",
    # AI conversion constants
    "INPUT_TEXT_MIN_LENGTH",
    "INPUT_TEXT_MAX_LENGTH",
    "ERROR_INPUT_TEXT_REQUIRED",
    "ERROR_INPUT_TEXT_EMPTY",
    "ERROR_INPUT_TEXT_MIN_LENGTH",
    "ERROR_INPUT_TEXT_MAX_LENGTH",
    "ERROR_PREVIOUS_RESULT_REQUIRED",
    "ERROR_PREVIOUS_RESULT_EMPTY",
]
