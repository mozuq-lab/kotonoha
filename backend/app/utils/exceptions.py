"""
カスタム例外定義モジュール

【機能概要】: アプリケーション固有の例外クラスを定義
【実装方針】: HTTPステータスコードと対応するエラーメッセージを管理
"""


class AppException(Exception):
    """
    【機能概要】: アプリケーション基底例外クラス
    【実装方針】: 全てのカスタム例外の基底クラス

    Attributes:
        message: エラーメッセージ
        status_code: HTTPステータスコード
    """

    def __init__(self, message: str, status_code: int = 400):
        self.message = message
        self.status_code = status_code
        super().__init__(self.message)


class NetworkException(AppException):
    """
    【機能概要】: ネットワークエラー例外
    【実装方針】: 外部API通信エラー時に使用

    HTTPステータスコード: 503 Service Unavailable
    """

    def __init__(self, message: str = "Network error occurred"):
        super().__init__(message, status_code=503)


class TimeoutException(AppException):
    """
    【機能概要】: タイムアウトエラー例外
    【実装方針】: リクエストタイムアウト時に使用

    HTTPステータスコード: 504 Gateway Timeout
    """

    def __init__(self, message: str = "Request timeout"):
        super().__init__(message, status_code=504)


class AIServiceException(AppException):
    """
    【機能概要】: AIサービスエラー例外
    【実装方針】: AI変換API呼び出しエラー時に使用

    HTTPステータスコード: 503 Service Unavailable
    """

    def __init__(self, message: str = "AI service error"):
        super().__init__(message, status_code=503)


class RateLimitException(AppException):
    """
    【機能概要】: レート制限エラー例外
    【実装方針】: APIレート制限超過時に使用

    HTTPステータスコード: 429 Too Many Requests
    """

    def __init__(self, message: str = "Rate limit exceeded"):
        super().__init__(message, status_code=429)


# ============================================================
# AI変換関連例外クラス (TASK-0026)
# ============================================================


class AIConversionException(AppException):
    """
    【機能概要】: AI変換基底例外クラス
    【実装方針】: AI変換に関連するすべての例外の基底クラス

    HTTPステータスコード: 500 Internal Server Error
    🔵 REQ-901に基づく
    """

    def __init__(self, message: str = "AI conversion error"):
        super().__init__(message, status_code=500)


class AITimeoutException(AIConversionException):
    """
    【機能概要】: AI APIタイムアウト例外
    【実装方針】: AI API呼び出しがタイムアウトした場合に使用

    HTTPステータスコード: 504 Gateway Timeout
    🔵 NFR-002に基づく（30秒タイムアウト）
    """

    def __init__(self, message: str = "AI API timeout"):
        # AIConversionExceptionを継承しつつ、status_codeを504に変更
        AppException.__init__(self, message, status_code=504)


class AIRateLimitException(AIConversionException):
    """
    【機能概要】: AI APIレート制限例外
    【実装方針】: AI APIのレート制限に達した場合に使用

    HTTPステータスコード: 429 Too Many Requests
    🔵 NFR-101に基づく
    """

    def __init__(self, message: str = "AI API rate limit exceeded"):
        AppException.__init__(self, message, status_code=429)


class AIProviderException(AIConversionException):
    """
    【機能概要】: AIプロバイダーエラー例外
    【実装方針】: AIプロバイダーが利用できない、または設定エラーの場合に使用

    HTTPステータスコード: 503 Service Unavailable
    🔵 EDGE-001に基づく
    """

    def __init__(self, message: str = "AI provider error"):
        AppException.__init__(self, message, status_code=503)
