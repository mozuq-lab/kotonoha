"""
FastAPIメインアプリケーション

【ファイル目的】: kotonoha APIのエントリーポイント、エンドポイント定義、CORS設定
【ファイル内容】: ルートエンドポイント、ヘルスチェックエンドポイント、CORS設定
🔵 TASK-0010要件定義書に基づく実装
"""

from datetime import datetime, timezone

from fastapi import Depends, FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.db.session import get_db
from app.schemas.health import HealthErrorResponse, HealthResponse, RootResponse


# 【設定定数】: APIバージョン情報
# 【調整可能性】: 将来的なバージョンアップ時はこの定数を変更
# 【一元管理】: 全エンドポイントで同じバージョン情報を使用
# 🔵 要件定義書（line 80, 98, 109）、main.py（line 23）に基づく
API_VERSION = "1.0.0"


def get_current_timestamp() -> str:
    """
    【機能概要】: 現在時刻をISO 8601形式で取得するヘルパー関数
    【改善内容】: タイムスタンプ生成ロジックを関数化し、重複を削除
    【設計方針】: DRY原則に基づき、タイムスタンプ生成を一箇所に集約
    【再利用性】: ヘルスチェックエンドポイントの正常時・異常時の両方で使用
    【単一責任】: ISO 8601形式のタイムスタンプ生成のみを担当
    🔵 要件定義書（line 99, 110）に基づく

    Returns:
        str: ISO 8601形式のタイムスタンプ（UTC、例: "2025-11-20T12:34:56Z"）

    Example:
        >>> timestamp = get_current_timestamp()
        >>> print(timestamp)
        "2025-11-20T12:34:56Z"
    """
    # 【現在時刻取得】: UTC時刻を取得し、ISO 8601形式に変換
    # 【実装詳細】: datetime.now(timezone.utc)でUTC時刻を取得、strftimeで整形
    # 【形式保証】: YYYY-MM-DDTHH:MM:SSZ形式を保証
    # 🔵 ISO 8601国際標準形式に基づく
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

# 【FastAPIアプリケーション作成】: kotonoha APIのメインアプリケーションを初期化
# 【実装方針】: title, versionを設定し、OpenAPI仕様の自動生成を有効化
# 【改善内容】: API_VERSION定数を使用し、バージョン情報を一元管理
# 🔵 要件定義書に基づく、NFR-504要件（OpenAPI自動生成）を満たす
app = FastAPI(title="kotonoha API", version=API_VERSION)

# 【CORS設定】: Cross-Origin Resource Sharingを有効化
# 【実装方針】: Flutter Webアプリからの安全なアクセスを許可
# 【テスト対応】: test_cors.pyのテストケースを通すための実装
# 🔵 要件定義書（line 141-147）、config.py（line 67-69）に基づく
app.add_middleware(
    CORSMiddleware,
    # 【許可オリジン】: 開発環境のオリジンを許可（http://localhost:3000, http://localhost:5173）
    # 【セキュリティ】: 本番環境では環境変数で設定されたオリジンのみ許可
    allow_origins=settings.CORS_ORIGINS_LIST,
    # 【認証情報許可】: Cookieやヘッダーの送信を許可
    allow_credentials=True,
    # 【許可メソッド】: 全HTTPメソッドを許可（GET, POST, PUT, DELETE等）
    allow_methods=["*"],
    # 【許可ヘッダー】: 全カスタムヘッダーを許可
    allow_headers=["*"],
)


@app.get("/", response_model=RootResponse)
async def root() -> RootResponse:
    """
    【機能概要】: ルートエンドポイント - アプリケーション稼働確認
    【実装方針】: 最もシンプルなエンドポイント、データベースアクセスなし
    【テスト対応】: test_root_endpoint_returns_success（testcases.md A-1）を通すための実装
    🔵 要件定義書（line 72-82）に基づく

    Returns:
        RootResponse: メッセージとバージョン情報を含むレスポンス

    Example:
        ```bash
        curl http://localhost:8000/
        # {"message": "kotonoha API is running", "version": "1.0.0"}
        ```
    """
    # 【レスポンス生成】: 固定メッセージとバージョン情報を返却
    # 【パフォーマンス】: データベースアクセスなし、100ms以内に応答（NFR-003）
    # 【改善内容】: API_VERSION定数を使用し、バージョン情報を一元管理
    # 🔵 要件定義書（line 78-81）に基づく
    return RootResponse(message="kotonoha API is running", version=API_VERSION)


@app.get(
    "/health",
    response_model=HealthResponse,
    responses={
        200: {"description": "ヘルスチェック成功（データベース接続正常）"},
        500: {
            "description": "ヘルスチェック失敗（データベース接続失敗）",
            "model": HealthErrorResponse,
        },
    },
)
async def health_check(db: AsyncSession = Depends(get_db)) -> HealthResponse | HealthErrorResponse:
    """
    【機能概要】: ヘルスチェックエンドポイント - システム稼働状況とデータベース接続確認
    【実装方針】: データベース接続確認（SELECT 1実行）、タイムスタンプ、バージョン情報を含む
    【テスト対応】: test_health_endpoint_returns_database_connected（testcases.md B-1）を通すための実装
    🔵 要件定義書（line 89-120）に基づく

    Args:
        db (AsyncSession): データベースセッション（依存性注入）

    Returns:
        HealthResponse: 正常時のヘルスチェックレスポンス
        HealthErrorResponse: 異常時のヘルスチェックレスポンス（HTTPステータスコード500）

    Raises:
        HTTPException: データベース接続失敗時に500エラーを返す

    Example:
        ```bash
        curl http://localhost:8000/health
        # 正常時: {"status": "ok", "database": "connected", "version": "1.0.0", "timestamp": "2025-11-20T12:34:56Z"}
        # 異常時: {"status": "error", "database": "disconnected", "error": "connection timeout", "version": "1.0.0", "timestamp": "2025-11-20T12:34:56Z"}
        ```
    """
    try:
        # 【現在時刻取得】: ISO 8601形式のタイムスタンプを生成
        # 【改善内容】: get_current_timestamp()ヘルパー関数を使用し、重複を削除
        # 【設計方針】: DRY原則に基づき、タイムスタンプ生成を一箇所に集約
        # 🔵 要件定義書（line 99）に基づく
        timestamp = get_current_timestamp()
        # 【データベース接続確認】: SELECT 1クエリを実行してデータベース接続を確認
        # 【実装方針】: 軽量なクエリで接続状態を確認、1秒以内に応答（NFR-002）
        # 【テスト対応】: test_health_endpoint_returns_database_connected（testcases.md B-1）を通すための実装
        # 🔵 要件定義書（line 114-119）に基づく
        await db.execute(text("SELECT 1"))

        # 【正常レスポンス生成】: データベース接続成功時のレスポンス
        # 【パフォーマンス】: 1秒以内に応答（NFR-002）
        # 【改善内容】: API_VERSION定数を使用し、バージョン情報を一元管理
        # 🔵 要件定義書（line 93-101）に基づく
        return HealthResponse(
            status="ok", database="connected", version=API_VERSION, timestamp=timestamp
        )

    except Exception as e:
        # 【エラーハンドリング】: データベース接続失敗時のエラー処理
        # 【実装方針】: 具体的なエラーメッセージを返し、運用チームに原因を通知
        # 【テスト対応】: test_health_endpoint_database_connection_failure_returns_500（testcases.md B-5）を通すための実装
        # 🔵 要件定義書（line 103-112, 258-281）、NFR-304、EDGE-001に基づく

        # 【エラーメッセージ生成】: データベースエラーの種類に応じたメッセージ
        # 【セキュリティ】: 詳細なエラー情報は開発環境のみ、本番環境では汎用的なメッセージ
        # 🟡 妥当な推測（エラーメッセージの詳細レベル）
        error_message = str(e) if settings.ENVIRONMENT == "development" else "Database connection failed"

        # 【エラー時のタイムスタンプ取得】: エラー発生時も現在時刻を記録
        # 【改善内容】: get_current_timestamp()ヘルパー関数を使用し、コードの重複を削除
        # 【一貫性保証】: 正常時・異常時で同じタイムスタンプ生成ロジックを使用
        # 🔵 要件定義書（line 110）に基づく
        error_timestamp = get_current_timestamp()

        # 【エラーレスポンス生成】: 500エラーとエラー情報を返す
        # 【システムの安全性】: エラー時もアプリケーションはクラッシュせず、エラー情報を返却（NFR-301）
        # 【改善内容】: API_VERSION定数を使用し、バージョン情報を一元管理
        # 🔵 要件定義書（line 103-112）に基づく
        error_response = HealthErrorResponse(
            status="error",
            database="disconnected",
            error=error_message,
            version=API_VERSION,
            timestamp=error_timestamp,
        )

        # 【HTTPException送出】: 500 Internal Server Errorを返す
        # 【実装方針】: FastAPIのHTTPExceptionを使用し、適切なステータスコードとレスポンスを返す
        # 🔵 要件定義書（line 233-241）に基づく
        raise HTTPException(status_code=500, detail=error_response.model_dump())
