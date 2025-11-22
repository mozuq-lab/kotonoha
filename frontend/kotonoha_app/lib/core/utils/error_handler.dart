/// Error handling utility
///
/// Provides centralized error handling with user-friendly messages
/// and logging integration.
library;

import 'package:kotonoha_app/core/utils/exceptions.dart';
import 'package:kotonoha_app/core/utils/logger.dart';

/// Error handler class
///
/// Provides static methods for handling errors consistently
/// throughout the application.
class ErrorHandler {
  ErrorHandler._();

  /// User-friendly error message for network errors
  static const String _networkErrorMessage =
      'ネットワークエラーが発生しました。インターネット接続を確認してください。';

  /// User-friendly error message for timeout errors
  static const String _timeoutErrorMessage = 'タイムアウトしました。もう一度お試しください。';

  /// User-friendly error message for AI conversion errors
  static const String _aiConversionErrorMessage =
      '変換に失敗しました。元の文をそのまま使用するか、もう一度お試しください。';

  /// User-friendly error message for unknown errors
  static const String _genericErrorMessage = '予期しないエラーが発生しました。';

  /// Handles an error by logging it and returning a user-friendly message
  ///
  /// This method will log the error using AppLogger and return
  /// an appropriate Japanese message for display to the user.
  static String handleError(Object? error, {StackTrace? stackTrace}) {
    // Log the error
    final message = getUserMessage(error);
    AppLogger.error(
      'Error occurred: ${error?.toString() ?? 'null'}',
      tag: 'ErrorHandler',
      error: error,
      stackTrace: stackTrace,
    );

    return message;
  }

  /// Gets a user-friendly error message for the given error
  ///
  /// Returns a Japanese message appropriate for displaying to users.
  static String getUserMessage(Object? error) => switch (error) {
        NetworkException() => _networkErrorMessage,
        AppTimeoutException() => _timeoutErrorMessage,
        AiConversionException() => _aiConversionErrorMessage,
        ValidationException(:final message) => message,
        _ => _genericErrorMessage,
      };

  /// Checks if the error is retryable
  ///
  /// Returns true for network, timeout, and AI conversion errors,
  /// false for validation and other errors.
  static bool isRetryable(Object? error) => switch (error) {
        // Network/timeout/AI errors are retryable
        NetworkException() ||
        AppTimeoutException() ||
        AiConversionException() =>
          true,
        // Validation errors require user correction, not retry
        // Unknown errors should not be retried automatically
        _ => false,
      };

  /// Gets SnackBar display data for an error
  ///
  /// Returns a map with 'message' and optional 'actionLabel' keys.
  static Map<String, String> getSnackBarData(Object? error) {
    final message = getUserMessage(error);
    final result = <String, String>{
      'message': message,
    };

    // Add retry action for retryable errors
    if (isRetryable(error)) {
      result['actionLabel'] = '再試行';
    }

    return result;
  }
}
