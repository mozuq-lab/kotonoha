"""
共通Pydanticスキーマ定義

TASK-0023: AI変換機能の共通スキーマ
🔵 api-endpoints.mdに基づく実装
"""

from enum import Enum
from typing import Generic, TypeVar

from pydantic import BaseModel, Field


class PolitenessLevel(str, Enum):
    """丁寧さレベル列挙型

    AI変換APIで使用する丁寧さレベルを定義する列挙型。
    casual（カジュアル）、normal（普通）、polite（丁寧）の3段階。

    Attributes:
        CASUAL: カジュアルな表現（タメ口）
        NORMAL: 普通の丁寧さ（です・ます調）
        POLITE: 丁寧な表現（敬語）
    """

    CASUAL = "casual"
    NORMAL = "normal"
    POLITE = "polite"


class ErrorDetail(BaseModel):
    """エラー詳細スキーマ

    APIエラー時の詳細情報を格納するスキーマ。

    Attributes:
        code: エラーコード（例: VALIDATION_ERROR, AI_API_ERROR）
        message: ユーザー向けエラーメッセージ
        status_code: HTTPステータスコード
    """

    code: str = Field(
        ...,
        description="エラーコード",
        examples=["VALIDATION_ERROR"],
    )
    message: str = Field(
        ...,
        description="エラーメッセージ",
        examples=["入力が不正です"],
    )
    status_code: int = Field(
        ...,
        description="HTTPステータスコード",
        examples=[400],
    )


class ErrorResponse(BaseModel):
    """エラーレスポンススキーマ（後方互換用）

    後方互換性を保つためのシンプルなエラーレスポンス形式。

    Attributes:
        error: エラーメッセージ
        detail: 詳細情報（オプション）
        error_code: エラーコード（オプション）
    """

    error: str = Field(..., description="エラーメッセージ")
    detail: str | None = Field(None, description="詳細情報")
    error_code: str | None = Field(None, description="エラーコード")


T = TypeVar("T")


class ApiResponse(BaseModel, Generic[T]):
    """統一APIレスポンススキーマ

    すべてのAPIエンドポイントで使用する統一レスポンス形式。

    Attributes:
        success: リクエストが成功したかどうか
        data: レスポンスデータ（成功時）
        error: エラー詳細（失敗時）

    Examples:
        成功時:
            >>> response = ApiResponse(success=True, data=result, error=None)

        失敗時:
            >>> error = ErrorDetail(code="VALIDATION_ERROR", message="入力エラー", status_code=400)
            >>> response = ApiResponse(success=False, data=None, error=error)
    """

    success: bool = Field(..., description="成功/失敗")
    data: T | None = Field(None, description="レスポンスデータ")
    error: ErrorDetail | None = Field(None, description="エラー詳細")
