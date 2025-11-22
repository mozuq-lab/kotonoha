import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/utils/validators.dart';

/// Test suite for Validators utility (TASK-0018)
///
/// TC-VAL-001 to TC-VAL-022: Validation functionality tests
void main() {
  group('Input Text Validation Tests', () {
    // TC-VAL-001: 入力テキスト正常値テスト（短い文字列）
    test('TC-VAL-001: short input text should pass validation', () {
      // Arrange
      const text = 'こんにちは'; // 5 characters

      // Act
      final result = Validators.validateInputText(text);

      // Assert
      expect(result, isNull, reason: 'Short text should pass (no error)');
    });

    // TC-VAL-002: 入力テキスト境界値テスト（ちょうど1000文字）
    test('TC-VAL-002: exactly 1000 characters should pass validation', () {
      // Arrange
      final text = 'あ' * 1000; // Exactly 1000 characters

      // Act
      final result = Validators.validateInputText(text);

      // Assert
      expect(result, isNull, reason: '1000 characters should pass');
    });

    // TC-VAL-003: 入力テキスト上限超過テスト（1001文字）
    test('TC-VAL-003: 1001 characters should fail validation', () {
      // Arrange
      final text = 'あ' * 1001; // 1001 characters

      // Act
      final result = Validators.validateInputText(text);

      // Assert
      expect(result, isNotNull, reason: '1001 characters should fail');
      expect(result, contains('1000文字以内'));
    });

    // TC-VAL-004: 入力テキスト上限大幅超過テスト（2000文字）
    test('TC-VAL-004: 2000 characters should fail validation', () {
      // Arrange
      final text = 'あ' * 2000; // 2000 characters

      // Act
      final result = Validators.validateInputText(text);

      // Assert
      expect(result, isNotNull, reason: '2000 characters should fail');
      expect(result, contains('1000文字以内'));
    });

    // TC-VAL-005: 入力テキスト空文字テスト
    test('TC-VAL-005: empty string should pass validation (empty allowed)', () {
      // Arrange
      const text = ''; // Empty string

      // Act
      final result = Validators.validateInputText(text);

      // Assert
      expect(result, isNull, reason: 'Empty input is allowed');
    });

    // TC-VAL-006: 入力テキストnullテスト
    test('TC-VAL-006: null input should pass validation', () {
      // Arrange
      const String? text = null;

      // Act
      final result = Validators.validateInputText(text);

      // Assert
      expect(result, isNull, reason: 'Null input is allowed (treated as empty)');
    });
  });

  group('Template Phrase Validation Tests', () {
    // TC-VAL-007: 定型文正常値テスト
    test('TC-VAL-007: short template phrase should pass validation', () {
      // Arrange
      const text = 'ありがとうございます'; // 10 characters

      // Act
      final result = Validators.validateTemplatePhrase(text);

      // Assert
      expect(result, isNull, reason: 'Short template should pass');
    });

    // TC-VAL-008: 定型文境界値テスト（ちょうど500文字）
    test('TC-VAL-008: exactly 500 characters should pass validation', () {
      // Arrange
      final text = 'あ' * 500; // Exactly 500 characters

      // Act
      final result = Validators.validateTemplatePhrase(text);

      // Assert
      expect(result, isNull, reason: '500 characters should pass');
    });

    // TC-VAL-009: 定型文上限超過テスト（501文字）
    test('TC-VAL-009: 501 characters should fail validation', () {
      // Arrange
      final text = 'あ' * 501; // 501 characters

      // Act
      final result = Validators.validateTemplatePhrase(text);

      // Assert
      expect(result, isNotNull, reason: '501 characters should fail');
      expect(result, contains('500文字以内'));
    });

    // TC-VAL-010: 定型文空文字テスト
    test('TC-VAL-010: empty template phrase should fail validation', () {
      // Arrange
      const text = ''; // Empty string

      // Act
      final result = Validators.validateTemplatePhrase(text);

      // Assert
      expect(result, isNotNull, reason: 'Empty template is not allowed');
      expect(result, contains('定型文を入力してください'));
    });

    // TC-VAL-011: 定型文nullテスト
    test('TC-VAL-011: null template phrase should fail validation', () {
      // Arrange
      const String? text = null;

      // Act
      final result = Validators.validateTemplatePhrase(text);

      // Assert
      expect(result, isNotNull, reason: 'Null template is not allowed');
      expect(result, contains('定型文を入力してください'));
    });

    // TC-VAL-012: 定型文空白のみテスト
    test('TC-VAL-012: whitespace-only template phrase should fail validation (half-width)',
        () {
      // Arrange
      const text = '   '; // Whitespace only (half-width)

      // Act
      final result = Validators.validateTemplatePhrase(text);

      // Assert
      expect(result, isNotNull, reason: 'Whitespace-only is not allowed');
      expect(result, contains('定型文を入力してください'));
    });

    test('TC-VAL-012: whitespace-only template phrase should fail validation (full-width)',
        () {
      // Arrange
      const text = '\u3000'; // Full-width space only

      // Act
      final result = Validators.validateTemplatePhrase(text);

      // Assert
      expect(result, isNotNull, reason: 'Full-width space only is not allowed');
      expect(result, contains('定型文を入力してください'));
    });

    test('TC-VAL-012: tab-only template phrase should fail validation', () {
      // Arrange
      const text = '\t'; // Tab only

      // Act
      final result = Validators.validateTemplatePhrase(text);

      // Assert
      expect(result, isNotNull, reason: 'Tab only is not allowed');
      expect(result, contains('定型文を入力してください'));
    });
  });

  group('AI Conversion Validation Tests', () {
    // TC-VAL-013: AI変換可能判定テスト（変換可能：2文字）
    test('TC-VAL-013: 2 characters should be AI convertible', () {
      // Arrange
      const text = 'ああ'; // 2 characters (boundary)

      // Act
      final result = Validators.canConvertWithAi(text);

      // Assert
      expect(result, isTrue, reason: '2 characters should be convertible');
    });

    // TC-VAL-014: AI変換可能判定テスト（変換可能：長い文字列）
    test('TC-VAL-014: long text should be AI convertible', () {
      // Arrange
      const text = 'おはようございます今日もよろしくお願いします'; // 20 characters

      // Act
      final result = Validators.canConvertWithAi(text);

      // Assert
      expect(result, isTrue, reason: 'Long text should be convertible');
    });

    // TC-VAL-015: AI変換可能判定テスト（変換不可：1文字）
    test('TC-VAL-015: 1 character should NOT be AI convertible', () {
      // Arrange
      const text = 'あ'; // 1 character

      // Act
      final result = Validators.canConvertWithAi(text);

      // Assert
      expect(result, isFalse, reason: '1 character should not be convertible');
    });

    // TC-VAL-016: AI変換可能判定テスト（変換不可：空文字）
    test('TC-VAL-016: empty string should NOT be AI convertible', () {
      // Arrange
      const text = ''; // Empty

      // Act
      final result = Validators.canConvertWithAi(text);

      // Assert
      expect(result, isFalse, reason: 'Empty should not be convertible');
    });

    // TC-VAL-017: AI変換可能判定テスト（変換不可：null）
    test('TC-VAL-017: null should NOT be AI convertible', () {
      // Arrange
      const String? text = null;

      // Act
      final result = Validators.canConvertWithAi(text);

      // Assert
      expect(result, isFalse, reason: 'Null should not be convertible');
    });

    // TC-VAL-018: AI変換可能判定テスト（空白のみは変換不可）
    test('TC-VAL-018: whitespace-only should NOT be AI convertible', () {
      // Arrange
      const text = '   '; // Whitespace only

      // Act
      final result = Validators.canConvertWithAi(text);

      // Assert
      expect(result, isFalse,
          reason: 'Whitespace-only should not be convertible (empty after sanitize)');
    });
  });

  group('Sanitization Tests', () {
    // TC-VAL-019: 入力テキストサニタイズテスト（前後空白除去）
    test('TC-VAL-019: should remove leading and trailing half-width spaces', () {
      // Arrange
      const text = '  こんにちは  '; // Leading/trailing half-width spaces

      // Act
      final result = Validators.sanitize(text);

      // Assert
      expect(result, equals('こんにちは'));
    });

    // TC-VAL-020: 入力テキストサニタイズテスト（全角スペース除去）
    test('TC-VAL-020: should remove leading and trailing full-width spaces', () {
      // Arrange
      const text = '\u3000こんにちは\u3000'; // Full-width spaces (U+3000)

      // Act
      final result = Validators.sanitize(text);

      // Assert
      expect(result, equals('こんにちは'));
    });

    // TC-VAL-021: 入力テキストサニタイズテスト（タブ・改行除去）
    test('TC-VAL-021: should remove leading and trailing tabs and newlines', () {
      // Arrange
      const text = '\n\tこんにちは\t\n'; // Tabs and newlines

      // Act
      final result = Validators.sanitize(text);

      // Assert
      expect(result, equals('こんにちは'));
    });

    // TC-VAL-022: 入力テキストサニタイズテスト（中間の空白は保持）
    test('TC-VAL-022: should preserve whitespace in the middle', () {
      // Arrange
      const text = '  こんにちは 世界  '; // Space in the middle

      // Act
      final result = Validators.sanitize(text);

      // Assert
      expect(result, equals('こんにちは 世界'),
          reason: 'Middle space should be preserved');
    });

    test('should handle null input in sanitize', () {
      // Arrange
      const String? text = null;

      // Act
      final result = Validators.sanitize(text);

      // Assert
      expect(result, equals(''));
    });

    test('should handle empty input in sanitize', () {
      // Arrange
      const text = '';

      // Act
      final result = Validators.sanitize(text);

      // Assert
      expect(result, equals(''));
    });
  });

  group('Validators Constants Tests', () {
    test('maxInputLength should be 1000', () {
      expect(Validators.maxInputLength, equals(1000));
    });

    test('maxTemplatePhraseLength should be 500', () {
      expect(Validators.maxTemplatePhraseLength, equals(500));
    });

    test('minAiConversionLength should be 2', () {
      expect(Validators.minAiConversionLength, equals(2));
    });
  });
}
