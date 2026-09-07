/// PresetPhraseValidator テスト
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/preset_phrase/domain/preset_phrase_validator.dart';

void main() {
  group('PresetPhraseValidator - 正常系テスト', () {
    // 有効な定型文内容を検証する
    /// 有効な定型文内容（1-500文字）がバリデーションを通過する
    test('TC-041-001: 有効な定型文内容（1-500文字）がバリデーションを通過する', () {
      // 入力データ: "おはようございます"（8文字）- 一般的な定型文
      const content = 'おはようございます';

      // 実行: バリデーション実行
      final result = PresetPhraseValidator.validateContent(content);

      // 結果検証: nullが返されること（バリデーション成功）
      expect(result, isNull);
    });

    // 1文字の定型文がバリデーションを通過する
    /// 最小文字数（1文字）の定型文がバリデーションを通過する
    test('TC-041-002: 最小文字数（1文字）の定型文がバリデーションを通過する', () {
      // 入力データ: "あ"（1文字）- 最小有効文字数
      const content = 'あ';

      // 実行: バリデーション実行
      final result = PresetPhraseValidator.validateContent(content);

      // 結果検証: nullが返されること（バリデーション成功）
      expect(result, isNull);
    });

    // 500文字の定型文がバリデーションを通過する
    /// 最大文字数（500文字）の定型文がバリデーションを通過する
    test('TC-041-003: 最大文字数（500文字）の定型文がバリデーションを通過する', () {
      // 入力データ: 500文字のテキスト - 最大有効文字数
      final content = 'あ' * 500;

      // 実行: バリデーション実行
      final result = PresetPhraseValidator.validateContent(content);

      // 結果検証: nullが返されること（バリデーション成功）
      expect(result, isNull);
    });
  });

  group('PresetPhraseValidator - 異常系テスト', () {
    // 空文字列でエラーを返す
    /// 空文字列入力時にエラーメッセージを返す
    test('TC-041-004: 空文字列入力時にエラーメッセージを返す', () {
      // 入力データ: ""（空文字列）- 無効な入力
      const content = '';

      // 実行: バリデーション実行
      final result = PresetPhraseValidator.validateContent(content);

      // 結果検証: エラーメッセージが返されること
      expect(result, equals('定型文を入力してください'));
    });

    // 空白のみの文字列でエラーを返す
    /// 空白のみの入力時にエラーメッセージを返す
    test('TC-041-005: 空白のみの入力時にエラーメッセージを返す', () {
      // 入力データ: "   "（空白3文字）- 実質的に空の入力
      const content = '   ';

      // 実行: バリデーション実行
      final result = PresetPhraseValidator.validateContent(content);

      // 結果検証: エラーメッセージが返されること
      expect(result, equals('定型文を入力してください'));
    });

    // 501文字でエラーを返す
    /// 501文字入力時にエラーメッセージを返す
    test('TC-041-006: 501文字入力時にエラーメッセージを返す', () {
      // 入力データ: 501文字のテキスト - 上限超過
      final content = 'あ' * 501;

      // 実行: バリデーション実行
      final result = PresetPhraseValidator.validateContent(content);

      // 結果検証: エラーメッセージが返されること
      expect(result, equals('定型文は500文字以内で入力してください'));
    });
  });

  group('PresetPhraseValidator - 特殊文字テスト', () {
    // 絵文字を含む定型文がバリデーションを通過する
    /// 絵文字を含む定型文がバリデーションを通過する
    test('TC-041-007: 絵文字を含む定型文がバリデーションを通過する', () {
      // 入力データ: 絵文字を含むテキスト
      const content = 'ありがとう\u{1F60A}';

      // 実行: バリデーション実行
      final result = PresetPhraseValidator.validateContent(content);

      // 結果検証: nullが返されること（バリデーション成功）
      expect(result, isNull);
    });

    // 改行を含む定型文がバリデーションを通過する
    /// 改行を含む定型文がバリデーションを通過する
    test('TC-041-008: 改行を含む定型文がバリデーションを通過する', () {
      // 入力データ: 改行を含むテキスト
      const content = 'おはようございます\nよろしくお願いします';

      // 実行: バリデーション実行
      final result = PresetPhraseValidator.validateContent(content);

      // 結果検証: nullが返されること（バリデーション成功）
      expect(result, isNull);
    });

    // 全角・半角混在テキストがバリデーションを通過する
    /// 全角・半角混在テキストがバリデーションを通過する
    test('TC-041-009: 全角・半角混在テキストがバリデーションを通過する', () {
      // 入力データ: 全角・半角混在テキスト
      const content = 'ABC123あいうえお';

      // 実行: バリデーション実行
      final result = PresetPhraseValidator.validateContent(content);

      // 結果検証: nullが返されること（バリデーション成功）
      expect(result, isNull);
    });
  });

  group('PresetPhraseValidator - カテゴリバリデーションテスト', () {
    // カテゴリバリデーション - 有効なカテゴリ
    /// 有効なカテゴリ（daily, health, other）がバリデーションを通過する
    test('TC-041-010: 有効なカテゴリ（daily）がバリデーションを通過する', () {
      // 入力データ: "daily" - 有効なカテゴリ値
      const category = 'daily';

      // 実行: バリデーション実行
      final result = PresetPhraseValidator.validateCategory(category);

      // 結果検証: nullが返されること（バリデーション成功）
      expect(result, isNull);
    });

    test('TC-041-010: 有効なカテゴリ（health）がバリデーションを通過する', () {
      // 入力データ: "health" - 有効なカテゴリ値
      const category = 'health';

      // 実行: バリデーション実行
      final result = PresetPhraseValidator.validateCategory(category);

      // 結果検証: nullが返されること（バリデーション成功）
      expect(result, isNull);
    });

    test('TC-041-010: 有効なカテゴリ（other）がバリデーションを通過する', () {
      // 入力データ: "other" - 有効なカテゴリ値
      const category = 'other';

      // 実行: バリデーション実行
      final result = PresetPhraseValidator.validateCategory(category);

      // 結果検証: nullが返されること（バリデーション成功）
      expect(result, isNull);
    });

    test('TC-041-010: 無効なカテゴリでエラーを返す', () {
      // 入力データ: "invalid" - 無効なカテゴリ値
      const category = 'invalid';

      // 実行: バリデーション実行
      final result = PresetPhraseValidator.validateCategory(category);

      // 結果検証: エラーメッセージが返されること
      expect(result, equals('無効なカテゴリです'));
    });
  });

  group('PresetPhraseValidator - 境界値テスト', () {
    // 0文字入力（下限境界値-1）
    /// 0文字入力時のバリデーション
    test('TC-041-059: 0文字入力時のバリデーション', () {
      // 入力データ: ""（0文字）- 境界外
      const content = '';

      // 実行: バリデーション実行
      final result = PresetPhraseValidator.validateContent(content);

      // 結果検証: エラーメッセージが返されること
      expect(result, isNotNull);
    });

    // 499文字入力（上限境界値-1）
    /// 499文字入力時のバリデーション
    test('TC-041-060: 499文字入力時のバリデーション', () {
      // 入力データ: 499文字のテキスト - 境界内
      final content = 'あ' * 499;

      // 実行: バリデーション実行
      final result = PresetPhraseValidator.validateContent(content);

      // 結果検証: nullが返されること（バリデーション成功）
      expect(result, isNull);
    });

    // 500文字入力（上限境界値）
    /// 500文字入力時のバリデーション
    test('TC-041-061: 500文字入力時のバリデーション', () {
      // 入力データ: 500文字のテキスト - 境界
      final content = 'あ' * 500;

      // 実行: バリデーション実行
      final result = PresetPhraseValidator.validateContent(content);

      // 結果検証: nullが返されること（バリデーション成功）
      expect(result, isNull);
    });

    // 501文字入力（上限境界値+1）
    /// 501文字入力時のバリデーション
    test('TC-041-062: 501文字入力時のバリデーション', () {
      // 入力データ: 501文字のテキスト - 境界外
      final content = 'あ' * 501;

      // 実行: バリデーション実行
      final result = PresetPhraseValidator.validateContent(content);

      // 結果検証: エラーメッセージが返されること
      expect(result, isNotNull);
    });
  });
}
