"""
TC-CV-002: utils/exceptions.py テストケース

【テスト対象】: app/utils/exceptions.py
【テスト数】: 6ケース
【推定工数】: 0.5時間
【目的】: カスタム例外クラスのテスト
"""

import pytest

from app.utils.exceptions import (
    AIConversionException,
    AIProviderException,
    AIRateLimitException,
    AIServiceException,
    AITimeoutException,
    AppException,
    NetworkException,
    RateLimitException,
    TimeoutException,
)


class TestCustomExceptions:
    """カスタム例外クラステスト"""

    def test_tc_cv_002_001_exception_creation(self):
        """
        TC-CV-002-001: カスタム例外の生成テスト
        【説明】: 各例外クラスが正常にインスタンス化できることを確認
        【期待結果】: すべての例外クラスがインスタンス化できる
        """
        # Arrange & Act & Assert
        app_exc = AppException("Test error")
        assert isinstance(app_exc, AppException)
        assert isinstance(app_exc, Exception)

        network_exc = NetworkException()
        assert isinstance(network_exc, NetworkException)
        assert isinstance(network_exc, AppException)

        timeout_exc = TimeoutException()
        assert isinstance(timeout_exc, TimeoutException)
        assert isinstance(timeout_exc, AppException)

        ai_service_exc = AIServiceException()
        assert isinstance(ai_service_exc, AIServiceException)
        assert isinstance(ai_service_exc, AppException)

        rate_limit_exc = RateLimitException()
        assert isinstance(rate_limit_exc, RateLimitException)
        assert isinstance(rate_limit_exc, AppException)

    def test_tc_cv_002_002_exception_message(self):
        """
        TC-CV-002-002: 例外メッセージテスト
        【説明】: 例外メッセージが正しく設定されることを確認
        【期待結果】: カスタムメッセージとデフォルトメッセージが設定される
        """
        # Arrange & Act
        custom_message = "Custom error message"
        app_exc = AppException(custom_message)

        # Assert
        assert app_exc.message == custom_message
        assert str(app_exc) == custom_message

        # デフォルトメッセージの確認
        network_exc = NetworkException()
        assert network_exc.message == "Network error occurred"

        timeout_exc = TimeoutException()
        assert timeout_exc.message == "Request timeout"

        ai_service_exc = AIServiceException()
        assert ai_service_exc.message == "AI service error"

        rate_limit_exc = RateLimitException()
        assert rate_limit_exc.message == "Rate limit exceeded"

    def test_tc_cv_002_003_exception_status_code(self):
        """
        TC-CV-002-003: 例外のHTTPステータスコードテスト
        【説明】: 各例外に適切なHTTPステータスコードが設定されることを確認
        【期待結果】: 各例外に正しいステータスコードが設定される
        """
        # Arrange & Act & Assert
        app_exc = AppException("Error", status_code=400)
        assert app_exc.status_code == 400

        network_exc = NetworkException()
        assert network_exc.status_code == 503

        timeout_exc = TimeoutException()
        assert timeout_exc.status_code == 504

        ai_service_exc = AIServiceException()
        assert ai_service_exc.status_code == 503

        rate_limit_exc = RateLimitException()
        assert rate_limit_exc.status_code == 429

    def test_tc_cv_002_004_exception_inheritance(self):
        """
        TC-CV-002-004: 例外の継承関係テスト
        【説明】: 例外クラスの継承関係が正しいことを確認
        【期待結果】: 各例外がAppExceptionを継承している
        """
        # Arrange & Act & Assert
        assert issubclass(NetworkException, AppException)
        assert issubclass(TimeoutException, AppException)
        assert issubclass(AIServiceException, AppException)
        assert issubclass(RateLimitException, AppException)
        assert issubclass(AIConversionException, AppException)
        assert issubclass(AITimeoutException, AIConversionException)
        assert issubclass(AIRateLimitException, AIConversionException)
        assert issubclass(AIProviderException, AIConversionException)

    def test_tc_cv_002_005_exception_raise(self):
        """
        TC-CV-002-005: 例外の再raiseテスト
        【説明】: 例外が正しくraiseされることを確認
        【期待結果】: 各例外が正しくraiseされ、catchできる
        """
        # Arrange & Act & Assert
        with pytest.raises(NetworkException) as exc_info:
            raise NetworkException("Test network error")
        assert exc_info.value.message == "Test network error"
        assert exc_info.value.status_code == 503

        with pytest.raises(TimeoutException) as exc_info:
            raise TimeoutException()
        assert exc_info.value.message == "Request timeout"

        with pytest.raises(RateLimitException) as exc_info:
            raise RateLimitException()
        assert exc_info.value.status_code == 429

    def test_tc_cv_002_006_ai_conversion_exceptions(self):
        """
        TC-CV-002-006: AI変換関連例外の詳細テスト
        【説明】: AI変換関連の例外クラスが正しく動作することを確認
        【期待結果】: AI変換例外のステータスコードとメッセージが正しい
        """
        # Arrange & Act & Assert
        ai_conv_exc = AIConversionException()
        assert ai_conv_exc.status_code == 500
        assert ai_conv_exc.message == "AI conversion error"

        ai_timeout_exc = AITimeoutException()
        assert ai_timeout_exc.status_code == 504
        assert ai_timeout_exc.message == "AI API timeout"

        ai_rate_limit_exc = AIRateLimitException()
        assert ai_rate_limit_exc.status_code == 429
        assert ai_rate_limit_exc.message == "AI API rate limit exceeded"

        ai_provider_exc = AIProviderException()
        assert ai_provider_exc.status_code == 503
        assert ai_provider_exc.message == "AI provider error"

        # カスタムメッセージの確認
        ai_custom_exc = AIProviderException("Custom AI error")
        assert ai_custom_exc.message == "Custom AI error"
        assert ai_custom_exc.status_code == 503
