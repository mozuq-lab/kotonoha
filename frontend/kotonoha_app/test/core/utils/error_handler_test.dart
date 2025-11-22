import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/utils/error_handler.dart';
import 'package:kotonoha_app/core/utils/exceptions.dart';

/// Test suite for ErrorHandler utility (TASK-0018)
///
/// TC-ERR-005 to TC-ERR-016: Error handling functionality tests
void main() {
  group('User-Friendly Error Message Tests', () {
    // TC-ERR-005: ネットワークエラーメッセージ生成テスト
    test('TC-ERR-005: should generate network error message in Japanese', () {
      // Arrange
      final error = NetworkException('接続エラー');

      // Act
      final message = ErrorHandler.getUserMessage(error);

      // Assert
      expect(message, contains('ネットワークエラー'));
      expect(message, contains('インターネット接続を確認'));
    });

    // TC-ERR-006: タイムアウトエラーメッセージ生成テスト
    test('TC-ERR-006: should generate timeout error message in Japanese', () {
      // Arrange
      final error = AppTimeoutException('タイムアウト');

      // Act
      final message = ErrorHandler.getUserMessage(error);

      // Assert
      expect(message, contains('タイムアウト'));
      expect(message, contains('もう一度お試しください'));
    });

    // TC-ERR-007: AI変換エラーメッセージ生成テスト
    test('TC-ERR-007: should generate AI conversion error message in Japanese',
        () {
      // Arrange
      final error = AiConversionException('変換失敗');

      // Act
      final message = ErrorHandler.getUserMessage(error);

      // Assert
      expect(message, contains('変換に失敗しました'));
      expect(message, contains('元の文'));
    });

    // TC-ERR-008: 汎用エラーメッセージ生成テスト
    test('TC-ERR-008: should generate generic error message for unknown errors',
        () {
      // Arrange
      final error = Exception('未知のエラー');

      // Act
      final message = ErrorHandler.getUserMessage(error);

      // Assert
      expect(message, contains('予期しないエラー'));
    });

    // TC-ERR-009: ValidationExceptionメッセージ生成テスト
    test('TC-ERR-009: should return validation error message directly', () {
      // Arrange
      final error = ValidationException('入力値が無効です');

      // Act
      final message = ErrorHandler.getUserMessage(error);

      // Assert
      expect(message, contains('入力値が無効です'));
    });
  });

  group('Error Handling with Logging Tests', () {
    // TC-ERR-010: エラーハンドリング時のログ記録テスト
    test('TC-ERR-010: handleError should return user-friendly message and log',
        () {
      // Arrange
      final error = NetworkException('テストエラー');
      final stackTrace = StackTrace.current;

      // Act
      final message = ErrorHandler.handleError(error, stackTrace: stackTrace);

      // Assert
      expect(message, isA<String>());
      expect(message, isNotEmpty);
      // Log verification would require mock - here we just verify no crash
    });

    test('TC-ERR-010: handleError should not throw for any error type', () {
      // Arrange
      final errors = [
        NetworkException('ネットワーク'),
        AppTimeoutException('タイムアウト'),
        AiConversionException('AI変換'),
        ValidationException('バリデーション'),
        Exception('一般例外'),
      ];

      // Act & Assert
      for (final error in errors) {
        expect(
          () => ErrorHandler.handleError(error),
          returnsNormally,
          reason: 'handleError should not throw for ${error.runtimeType}',
        );
      }
    });
  });

  group('Retryable Error Tests', () {
    // TC-ERR-011: エラー再試行可能判定テスト（ネットワークエラー）
    test('TC-ERR-011: NetworkException should be retryable', () {
      // Arrange
      final error = NetworkException('接続エラー');

      // Act
      final isRetryable = ErrorHandler.isRetryable(error);

      // Assert
      expect(isRetryable, isTrue,
          reason: 'Network errors should be retryable');
    });

    // TC-ERR-012: エラー再試行可能判定テスト（タイムアウト）
    test('TC-ERR-012: AppTimeoutException should be retryable', () {
      // Arrange
      final error = AppTimeoutException('タイムアウト');

      // Act
      final isRetryable = ErrorHandler.isRetryable(error);

      // Assert
      expect(isRetryable, isTrue,
          reason: 'Timeout errors should be retryable');
    });

    // TC-ERR-013: エラー再試行可能判定テスト（バリデーションエラー）
    test('TC-ERR-013: ValidationException should NOT be retryable', () {
      // Arrange
      final error = ValidationException('入力値が無効');

      // Act
      final isRetryable = ErrorHandler.isRetryable(error);

      // Assert
      expect(isRetryable, isFalse,
          reason: 'Validation errors require user correction, not retry');
    });

    test('AiConversionException should be retryable', () {
      // Arrange
      final error = AiConversionException('変換失敗');

      // Act
      final isRetryable = ErrorHandler.isRetryable(error);

      // Assert
      expect(isRetryable, isTrue,
          reason: 'AI conversion errors might succeed on retry');
    });

    test('Generic Exception should NOT be retryable', () {
      // Arrange
      final error = Exception('未知のエラー');

      // Act
      final isRetryable = ErrorHandler.isRetryable(error);

      // Assert
      expect(isRetryable, isFalse,
          reason: 'Unknown errors should not be retried automatically');
    });
  });

  group('SnackBar Data Tests', () {
    // TC-ERR-014: SnackBar表示用データ生成テスト
    test('TC-ERR-014: should generate SnackBar data with message', () {
      // Arrange
      final error = NetworkException('接続エラー');

      // Act
      final data = ErrorHandler.getSnackBarData(error);

      // Assert
      expect(data, containsPair('message', isA<String>()));
      expect(data['message'], isNotEmpty);
    });

    test('TC-ERR-014: retryable errors should have action label', () {
      // Arrange
      final error = NetworkException('接続エラー');

      // Act
      final data = ErrorHandler.getSnackBarData(error);

      // Assert
      expect(data.containsKey('actionLabel'), isTrue,
          reason: 'Retryable errors should have retry action');
    });

    test('TC-ERR-014: non-retryable errors may not have action label', () {
      // Arrange
      final error = ValidationException('入力エラー');

      // Act
      final data = ErrorHandler.getSnackBarData(error);

      // Assert
      expect(data, containsPair('message', isA<String>()));
      // actionLabel may or may not be present for validation errors
    });
  });

  group('App Continuity Tests', () {
    // TC-ERR-015: エラー発生時のアプリ継続動作テスト
    test('TC-ERR-015: handleError should not crash the app', () {
      // Arrange
      final error = Exception('テストエラー');

      // Act & Assert
      expect(
        () => ErrorHandler.handleError(error),
        returnsNormally,
        reason: 'handleError should catch exceptions and not rethrow',
      );
    });

    test('TC-ERR-015: handleError should return valid message even for unexpected errors',
        () {
      // Arrange
      final error = StateError('予期しない状態');

      // Act
      final message = ErrorHandler.handleError(error);

      // Assert
      expect(message, isA<String>());
      expect(message, isNotEmpty);
    });

    test('TC-ERR-015: all error handler methods should be resilient', () {
      // Arrange
      final error = TypeError();

      // Act & Assert
      expect(() => ErrorHandler.getUserMessage(error), returnsNormally);
      expect(() => ErrorHandler.isRetryable(error), returnsNormally);
      expect(() => ErrorHandler.getSnackBarData(error), returnsNormally);
      expect(() => ErrorHandler.handleError(error), returnsNormally);
    });
  });

  group('Null Error Handling Tests', () {
    // TC-ERR-016: nullエラーオブジェクト処理テスト
    test('TC-ERR-016: getUserMessage should handle null error', () {
      // Arrange
      const Object? error = null;

      // Act
      final message = ErrorHandler.getUserMessage(error);

      // Assert
      expect(message, isA<String>());
      expect(message, isNotEmpty);
      expect(message, contains('予期しないエラー'),
          reason: 'Null error should return generic message');
    });

    test('TC-ERR-016: handleError should handle null error', () {
      // Arrange
      const Object? error = null;

      // Act & Assert
      expect(
        () => ErrorHandler.handleError(error),
        returnsNormally,
        reason: 'handleError should not crash for null',
      );

      final message = ErrorHandler.handleError(error);
      expect(message, isA<String>());
      expect(message, isNotEmpty);
    });

    test('TC-ERR-016: isRetryable should handle null error', () {
      // Arrange
      const Object? error = null;

      // Act
      final isRetryable = ErrorHandler.isRetryable(error);

      // Assert
      expect(isRetryable, isFalse,
          reason: 'Null error should not be retryable');
    });

    test('TC-ERR-016: getSnackBarData should handle null error', () {
      // Arrange
      const Object? error = null;

      // Act
      final data = ErrorHandler.getSnackBarData(error);

      // Assert
      expect(data, containsPair('message', isA<String>()));
    });
  });
}
