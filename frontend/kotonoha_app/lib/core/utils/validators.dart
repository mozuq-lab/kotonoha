/// Validation utility functions
///
/// Provides input validation and sanitization for user-entered text.
library;

/// Validators class with static methods for input validation
class Validators {
  Validators._();

  /// Maximum length for general input text
  static const int maxInputLength = 1000;

  /// Maximum length for template phrases
  static const int maxTemplatePhraseLength = 500;

  /// Minimum length for AI conversion
  static const int minAiConversionLength = 2;

  /// Regular expression for trimming whitespace characters
  /// Includes: half-width space, full-width space (U+3000), tabs, newlines
  static final RegExp _whitespacePattern = RegExp(r'^[\s\u3000]+|[\s\u3000]+$');

  /// Validates general input text
  ///
  /// Returns null if valid, error message string if invalid.
  /// Empty or null input is allowed (returns null).
  static String? validateInputText(String? text) {
    // Empty or null input is allowed
    if (text == null || text.isEmpty) {
      return null;
    }

    // Check length limit
    if (text.length > maxInputLength) {
      return '入力は$maxInputLength文字以内にしてください';
    }

    return null;
  }

  /// Validates template phrase text
  ///
  /// Returns null if valid, error message string if invalid.
  /// Empty or null input is NOT allowed for template phrases.
  static String? validateTemplatePhrase(String? text) {
    // Sanitize first to check for whitespace-only input
    final sanitized = sanitize(text);

    // Empty or null input is NOT allowed for template phrases
    if (sanitized.isEmpty) {
      return '定型文を入力してください';
    }

    // Check length limit
    if (sanitized.length > maxTemplatePhraseLength) {
      return '定型文は$maxTemplatePhraseLength文字以内にしてください';
    }

    return null;
  }

  /// Checks if text is convertible by AI
  ///
  /// Returns true if text has at least [minAiConversionLength] characters
  /// after sanitization.
  static bool canConvertWithAi(String? text) {
    final sanitized = sanitize(text);
    return sanitized.length >= minAiConversionLength;
  }

  /// Sanitizes input text by removing leading/trailing whitespace
  ///
  /// Removes: half-width space, full-width space, tabs, newlines
  /// Preserves: whitespace in the middle of text
  static String sanitize(String? text) {
    if (text == null) {
      return '';
    }

    // Remove leading and trailing whitespace (including full-width spaces)
    return text.replaceAll(_whitespacePattern, '');
  }
}
