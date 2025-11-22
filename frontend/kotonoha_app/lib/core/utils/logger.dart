/// Application logging utility
///
/// Provides structured logging with different log levels
/// and optional tag-based categorization.
library;

import 'package:logger/logger.dart';

/// Log level enumeration
enum LogLevel {
  /// Debug level - detailed information for debugging
  debug,

  /// Info level - general information about app flow
  info,

  /// Warning level - potential issues that may need attention
  warning,

  /// Error level - errors that need immediate attention
  error,
}

/// Application logger class
///
/// Provides methods for logging at different levels with optional tags.
/// In release mode, debug logs are suppressed.
class AppLogger {
  AppLogger._();

  /// The underlying logger instance
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: false,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  /// Sets whether to suppress debug logs (for testing release mode behavior)
  static bool suppressDebugLogs = false;

  /// Formats a message with an optional tag
  static String _formatMessage(String message, String? tag) {
    if (tag != null && tag.isNotEmpty) {
      return '[$tag] $message';
    }
    return message;
  }

  /// Logs a debug message
  static void debug(String message, {String? tag}) {
    if (suppressDebugLogs) {
      return;
    }
    _logger.d(_formatMessage(message, tag));
  }

  /// Logs an info message
  static void info(String message, {String? tag}) {
    _logger.i(_formatMessage(message, tag));
  }

  /// Logs a warning message
  static void warning(String message, {String? tag}) {
    _logger.w(_formatMessage(message, tag));
  }

  /// Logs an error message with optional error and stack trace
  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger.e(
      _formatMessage(message, tag),
      error: error,
      stackTrace: stackTrace,
    );
  }
}
