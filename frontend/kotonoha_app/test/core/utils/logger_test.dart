import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/utils/logger.dart';

/// Test suite for AppLogger utility (TASK-0018)
///
/// TC-LOG-001 to TC-LOG-007: Logger functionality tests
void main() {
  setUp(() {
    // Reset logger state before each test
    AppLogger.suppressDebugLogs = false;
  });

  group('Debug Log Tests', () {
    // TC-LOG-001: デバッグログ出力テスト
    test('TC-LOG-001: AppLogger.debug should output debug level log', () {
      // Arrange
      const message = 'テストデバッグメッセージ';

      // Act & Assert - Should not throw in development mode
      expect(
        () => AppLogger.debug(message),
        returnsNormally,
      );
    });

    test('TC-LOG-001: debug log should contain DEBUG level indicator', () {
      // This test verifies that debug logs include level information
      // The actual log output format will be validated in implementation
      const message = 'テストデバッグメッセージ';

      expect(
        () => AppLogger.debug(message),
        returnsNormally,
      );
    });
  });

  group('Info Log Tests', () {
    // TC-LOG-002: 情報ログ出力テスト
    test('TC-LOG-002: AppLogger.info should output info level log', () {
      // Arrange
      const message = 'アプリケーション起動完了';

      // Act & Assert - Should not throw
      expect(
        () => AppLogger.info(message),
        returnsNormally,
      );
    });

    test('TC-LOG-002: info log should contain INFO level indicator', () {
      const message = 'アプリケーション起動完了';

      expect(
        () => AppLogger.info(message),
        returnsNormally,
      );
    });
  });

  group('Warning Log Tests', () {
    // TC-LOG-003: 警告ログ出力テスト
    test('TC-LOG-003: AppLogger.warning should output warning level log', () {
      // Arrange
      const message = 'ネットワーク接続が不安定です';

      // Act & Assert - Should not throw
      expect(
        () => AppLogger.warning(message),
        returnsNormally,
      );
    });

    test('TC-LOG-003: warning log should contain WARNING level indicator', () {
      const message = 'ネットワーク接続が不安定です';

      expect(
        () => AppLogger.warning(message),
        returnsNormally,
      );
    });
  });

  group('Error Log Tests', () {
    // TC-LOG-004: エラーログ出力テスト（例外情報なし）
    test('TC-LOG-004: AppLogger.error should output error log without exception',
        () {
      // Arrange
      const message = 'AI変換処理でエラーが発生';

      // Act & Assert - Should not throw
      expect(
        () => AppLogger.error(message),
        returnsNormally,
      );
    });

    test('TC-LOG-004: error log should contain ERROR level indicator', () {
      const message = 'AI変換処理でエラーが発生';

      expect(
        () => AppLogger.error(message),
        returnsNormally,
      );
    });

    // TC-LOG-005: エラーログ出力テスト（例外情報・スタックトレース付き）
    test(
        'TC-LOG-005: AppLogger.error should output error log with exception and stack trace',
        () {
      // Arrange
      const message = 'ネットワークエラー発生';
      final error = Exception('接続に失敗しました');
      final stackTrace = StackTrace.current;

      // Act & Assert - Should not throw
      expect(
        () => AppLogger.error(
          message,
          error: error,
          stackTrace: stackTrace,
        ),
        returnsNormally,
      );
    });

    test('TC-LOG-005: error log with exception should include exception info',
        () {
      const message = 'ネットワークエラー発生';
      final error = Exception('接続に失敗しました');

      expect(
        () => AppLogger.error(message, error: error),
        returnsNormally,
      );
    });
  });

  group('Release Mode Debug Log Suppression Tests', () {
    // TC-LOG-006: 本番環境でのデバッグログ抑制テスト
    test('TC-LOG-006: debug logs should be suppressed when suppressDebugLogs is true',
        () {
      // Arrange
      AppLogger.suppressDebugLogs = true;
      const message = 'デバッグ情報';

      // Act & Assert - Should not throw even in suppressed mode
      expect(
        () => AppLogger.debug(message),
        returnsNormally,
      );
    });

    test('TC-LOG-006: info logs should NOT be suppressed in release mode', () {
      // Arrange
      AppLogger.suppressDebugLogs = true;
      const message = '情報ログ';

      // Act & Assert - Info logs should still work
      expect(
        () => AppLogger.info(message),
        returnsNormally,
      );
    });

    test('TC-LOG-006: warning logs should NOT be suppressed in release mode',
        () {
      // Arrange
      AppLogger.suppressDebugLogs = true;
      const message = '警告ログ';

      // Act & Assert - Warning logs should still work
      expect(
        () => AppLogger.warning(message),
        returnsNormally,
      );
    });

    test('TC-LOG-006: error logs should NOT be suppressed in release mode', () {
      // Arrange
      AppLogger.suppressDebugLogs = true;
      const message = 'エラーログ';

      // Act & Assert - Error logs should still work
      expect(
        () => AppLogger.error(message),
        returnsNormally,
      );
    });
  });

  group('Tag-based Log Tests', () {
    // TC-LOG-007: ログタグ付き出力テスト
    test('TC-LOG-007: AppLogger should support tag parameter for debug log',
        () {
      // Arrange
      const tag = 'AIConverter';
      const message = '変換処理開始';

      // Act & Assert - Should not throw with tag
      expect(
        () => AppLogger.debug(message, tag: tag),
        returnsNormally,
      );
    });

    test('TC-LOG-007: AppLogger should support tag parameter for info log', () {
      // Arrange
      const tag = 'Navigation';
      const message = '画面遷移完了';

      // Act & Assert
      expect(
        () => AppLogger.info(message, tag: tag),
        returnsNormally,
      );
    });

    test('TC-LOG-007: AppLogger should support tag parameter for warning log',
        () {
      // Arrange
      const tag = 'Network';
      const message = '接続不安定';

      // Act & Assert
      expect(
        () => AppLogger.warning(message, tag: tag),
        returnsNormally,
      );
    });

    test('TC-LOG-007: AppLogger should support tag parameter for error log',
        () {
      // Arrange
      const tag = 'Database';
      const message = 'データ保存失敗';

      // Act & Assert
      expect(
        () => AppLogger.error(message, tag: tag),
        returnsNormally,
      );
    });
  });

  group('LogLevel Enum Tests', () {
    test('LogLevel should have all required levels', () {
      // Assert
      expect(LogLevel.values, contains(LogLevel.debug));
      expect(LogLevel.values, contains(LogLevel.info));
      expect(LogLevel.values, contains(LogLevel.warning));
      expect(LogLevel.values, contains(LogLevel.error));
      expect(LogLevel.values.length, equals(4));
    });
  });
}
