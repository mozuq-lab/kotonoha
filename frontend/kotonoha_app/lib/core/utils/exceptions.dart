/// Custom exception classes for kotonoha app
///
/// Provides application-specific exception types for better error handling.
library;

/// Base class for all app-specific exceptions
abstract class AppException implements Exception {
  /// Creates an [AppException] with the given [message].
  ///
  /// Optionally accepts [originalError] and [stackTrace] for chaining exceptions.
  AppException(this.message, {this.originalError, this.stackTrace});

  /// The error message describing what went wrong.
  final String message;

  /// The original error that caused this exception, if any.
  final Object? originalError;

  /// The stack trace at the point where the exception was thrown.
  final StackTrace? stackTrace;

  @override
  String toString() => message;
}

/// Exception thrown when a network error occurs
class NetworkException extends AppException {
  /// Creates a [NetworkException] with the given [message].
  NetworkException(super.message, {super.originalError, super.stackTrace});
}

/// Exception thrown when a request times out
class AppTimeoutException extends AppException {
  /// Creates an [AppTimeoutException] with the given [message].
  ///
  /// Optionally accepts [duration] to indicate the timeout duration.
  AppTimeoutException(
    super.message, {
    this.duration,
    super.originalError,
    super.stackTrace,
  });

  /// The timeout duration that was exceeded.
  final Duration? duration;
}

/// Exception thrown when AI conversion fails
class AiConversionException extends AppException {
  /// Creates an [AiConversionException] with the given [message].
  ///
  /// Optionally accepts [originalText] to preserve the input that failed conversion.
  AiConversionException(
    super.message, {
    this.originalText,
    super.originalError,
    super.stackTrace,
  });

  /// The original text that failed to convert.
  final String? originalText;
}

/// Exception thrown when validation fails
class ValidationException extends AppException {
  /// Creates a [ValidationException] with the given [message].
  ///
  /// Optionally accepts [field] to indicate which field failed validation.
  ValidationException(
    super.message, {
    this.field,
    super.originalError,
    super.stackTrace,
  });

  /// The name of the field that failed validation.
  final String? field;
}
