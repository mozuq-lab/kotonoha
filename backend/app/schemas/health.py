"""
ヘルスチェック・基本APIエンドポイントのPydanticスキーマ定義

【ファイル目的】: ルートエンドポイントとヘルスチェックエンドポイントのレスポンススキーマを定義
【ファイル内容】: RootResponse, HealthResponse, HealthErrorResponseの3つのスキーマ
🔵 TASK-0010要件定義書（line 72-112）に基づく実装
"""

from pydantic import BaseModel, Field


class RootResponse(BaseModel):
    """
    【機能概要】: ルートエンドポイント（GET /）のレスポンススキーマ
    【実装方針】: 最もシンプルなレスポンス形式、アプリケーション稼働確認用
    【テスト対応】: test_root_endpoint_returns_success（testcases.md A-1）を通すための実装
    🔵 要件定義書（line 72-82）に基づく

    Attributes:
        message (str): APIの稼働メッセージ（固定値: "kotonoha API is running"）
        version (str): APIのバージョン情報（例: "1.0.0"）
    """

    # 【フィールド定義】: APIの稼働メッセージ
    # 【データ型】: 文字列（固定値）
    # 🔵 要件定義書（line 79）に基づく
    message: str = Field(
        ...,
        description="APIの稼働メッセージ",
        examples=["kotonoha API is running"],
    )

    # 【フィールド定義】: APIのバージョン情報
    # 【データ型】: 文字列（セマンティックバージョニング形式）
    # 🔵 要件定義書（line 80）、main.py（line 3）に基づく
    version: str = Field(
        ..., description="APIのバージョン情報", examples=["1.0.0"]
    )


class HealthResponse(BaseModel):
    """
    【機能概要】: ヘルスチェックエンドポイント（GET /health）のレスポンススキーマ（正常時）
    【実装方針】: データベース接続確認、AIプロバイダー情報、タイムスタンプ、バージョン情報を含む
    【テスト対応】: test_health_endpoint_returns_database_connected（testcases.md B-1）を通すための実装
    🔵 要件定義書（line 93-101）に基づく
    🔵 TASK-0029: AI プロバイダー確認機能を追加

    Attributes:
        status (str): ヘルスチェックステータス（正常時: "ok"、一部機能低下時: "degraded"）
        database (str): データベース接続状態（正常時: "connected"）
        ai_provider (str): 有効なAIプロバイダー（"anthropic", "openai", "none"）
        version (str): APIのバージョン情報（例: "1.0.0"）
        timestamp (str): ヘルスチェック実行時刻（ISO 8601形式）
    """

    # 【フィールド定義】: ヘルスチェックステータス
    # 【データ型】: 文字列（正常時: "ok"、一部機能低下時: "degraded"）
    # 🔵 要件定義書（line 96）に基づく
    status: str = Field(
        ..., description="ヘルスチェックステータス", examples=["ok", "degraded"]
    )

    # 【フィールド定義】: データベース接続状態
    # 【データ型】: 文字列（正常時: "connected"）
    # 🔵 要件定義書（line 97）に基づく
    database: str = Field(
        ..., description="データベース接続状態", examples=["connected"]
    )

    # 【フィールド定義】: 有効なAIプロバイダー
    # 【データ型】: 文字列（"anthropic", "openai", "none"）
    # 🔵 TASK-0029に基づく
    ai_provider: str = Field(
        ...,
        description="有効なAIプロバイダー",
        examples=["anthropic", "openai", "none"],
    )

    # 【フィールド定義】: APIのバージョン情報
    # 【データ型】: 文字列（セマンティックバージョニング形式）
    # 🔵 要件定義書（line 98）に基づく
    version: str = Field(..., description="APIのバージョン情報", examples=["1.0.0"])

    # 【フィールド定義】: ヘルスチェック実行時刻
    # 【データ型】: 文字列（ISO 8601形式、UTC）
    # 🔵 要件定義書（line 99）に基づく
    timestamp: str = Field(
        ...,
        description="ヘルスチェック実行時刻（ISO 8601形式）",
        examples=["2025-11-20T12:34:56Z"],
    )


class HealthErrorResponse(BaseModel):
    """
    【機能概要】: ヘルスチェックエンドポイント（GET /health）のレスポンススキーマ（異常時）
    【実装方針】: データベース接続失敗時のエラー情報を含む
    【テスト対応】: test_health_endpoint_database_connection_failure_returns_500（testcases.md B-5）を通すための実装
    🔵 要件定義書（line 103-112）に基づく

    Attributes:
        status (str): ヘルスチェックステータス（異常時: "error"）
        database (str): データベース接続状態（異常時: "disconnected"）
        error (str): エラーメッセージ（具体的なエラー原因）
        version (str): APIのバージョン情報（例: "1.0.0"）
        timestamp (str): ヘルスチェック実行時刻（ISO 8601形式）
    """

    # 【フィールド定義】: ヘルスチェックステータス
    # 【データ型】: 文字列（異常時: "error"）
    # 🔵 要件定義書（line 106）に基づく
    status: str = Field(..., description="ヘルスチェックステータス", examples=["error"])

    # 【フィールド定義】: データベース接続状態
    # 【データ型】: 文字列（異常時: "disconnected"）
    # 🔵 要件定義書（line 107）に基づく
    database: str = Field(
        ..., description="データベース接続状態", examples=["disconnected"]
    )

    # 【フィールド定義】: エラーメッセージ
    # 【データ型】: 文字列（具体的なエラー原因）
    # 🔵 要件定義書（line 108）、EDGE-001に基づく
    error: str = Field(
        ...,
        description="エラーメッセージ（具体的なエラー原因）",
        examples=["connection timeout", "Database authentication failed"],
    )

    # 【フィールド定義】: APIのバージョン情報
    # 【データ型】: 文字列（セマンティックバージョニング形式）
    # 🔵 要件定義書（line 109）に基づく
    version: str = Field(..., description="APIのバージョン情報", examples=["1.0.0"])

    # 【フィールド定義】: ヘルスチェック実行時刻
    # 【データ型】: 文字列（ISO 8601形式、UTC）
    # 🔵 要件定義書（line 110）に基づく
    timestamp: str = Field(
        ...,
        description="ヘルスチェック実行時刻（ISO 8601形式）",
        examples=["2025-11-20T12:34:56Z"],
    )
