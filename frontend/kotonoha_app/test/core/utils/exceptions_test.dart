import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/utils/exceptions.dart';

/// Test suite for custom exception classes (TASK-0018)
///
/// TC-ERR-001 to TC-ERR-004: Custom exception generation tests
void main() {
  group('NetworkException Tests', () {
    // TC-ERR-001: NetworkException生成テスト
    test('TC-ERR-001: should create NetworkException with message', () {
      // Arrange
      const message = '接続エラー';

      // Act
      final exception = NetworkException(message);

      // Assert
      expect(exception, isA<NetworkException>());
      expect(exception, isA<AppException>());
      expect(exception.message, contains('接続エラー'));
    });

    test(
        'TC-ERR-001: NetworkException.toString should return meaningful string',
        () {
      // Arrange
      const message = '接続エラー';

      // Act
      final exception = NetworkException(message);

      // Assert
      expect(exception.toString(), isA<String>());
      expect(exception.toString(), contains('接続エラー'));
    });
  });

  group('AppTimeoutException Tests', () {
    // TC-ERR-002: TimeoutException生成テスト
    test('TC-ERR-002: should create AppTimeoutException with message', () {
      // Arrange
      const message = 'タイムアウト';

      // Act
      final exception = AppTimeoutException(message);

      // Assert
      expect(exception, isA<AppTimeoutException>());
      expect(exception, isA<AppException>());
      expect(exception.message, contains('タイムアウト'));
    });

    test('TC-ERR-002: should create AppTimeoutException with duration', () {
      // Arrange
      const message = 'タイムアウト';
      const duration = Duration(seconds: 30);

      // Act
      final exception = AppTimeoutException(message, duration: duration);

      // Assert
      expect(exception, isA<AppTimeoutException>());
      expect(exception.message, contains('タイムアウト'));
      expect(exception.duration, equals(duration));
    });
  });

  group('AiConversionException Tests', () {
    // TC-ERR-003: AiConversionException生成テスト
    test('TC-ERR-003: should create AiConversionException with message', () {
      // Arrange
      const message = '変換失敗';

      // Act
      final exception = AiConversionException(message);

      // Assert
      expect(exception, isA<AiConversionException>());
      expect(exception, isA<AppException>());
      expect(exception.message, contains('変換失敗'));
    });

    test('TC-ERR-003: should create AiConversionException with originalText',
        () {
      // Arrange
      const message = '変換失敗';
      const originalText = 'こんにちは';

      // Act
      final exception =
          AiConversionException(message, originalText: originalText);

      // Assert
      expect(exception, isA<AiConversionException>());
      expect(exception.message, contains('変換失敗'));
      expect(exception.originalText, equals('こんにちは'));
    });
  });

  group('ValidationException Tests', () {
    // TC-ERR-004: ValidationException生成テスト
    test('TC-ERR-004: should create ValidationException with message', () {
      // Arrange
      const message = '入力値が無効です';

      // Act
      final exception = ValidationException(message);

      // Assert
      expect(exception, isA<ValidationException>());
      expect(exception, isA<AppException>());
      expect(exception.message, contains('入力値が無効です'));
    });

    test('TC-ERR-004: should create ValidationException with field', () {
      // Arrange
      const message = '入力値が無効です';
      const field = 'inputText';

      // Act
      final exception = ValidationException(message, field: field);

      // Assert
      expect(exception, isA<ValidationException>());
      expect(exception.message, contains('入力値が無効です'));
      expect(exception.field, equals('inputText'));
    });
  });

  group('AppException Base Class Tests', () {
    test('should implement Exception interface', () {
      // Arrange & Act
      final exception = NetworkException('テスト');

      // Assert
      expect(exception, isA<Exception>());
    });

    test('all exception types should have message property', () {
      // Arrange & Act
      final networkException = NetworkException('ネットワークエラー');
      final timeoutException = AppTimeoutException('タイムアウト');
      final aiException = AiConversionException('AI変換失敗');
      final validationException = ValidationException('バリデーションエラー');

      // Assert
      expect(networkException.message, equals('ネットワークエラー'));
      expect(timeoutException.message, equals('タイムアウト'));
      expect(aiException.message, equals('AI変換失敗'));
      expect(validationException.message, equals('バリデーションエラー'));
    });
  });
}
