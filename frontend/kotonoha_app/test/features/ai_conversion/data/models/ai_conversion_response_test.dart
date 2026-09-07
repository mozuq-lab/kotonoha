/// AI変換レスポンスモデル テスト
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/ai_conversion/data/models/ai_conversion_response.dart';
import 'package:kotonoha_app/features/ai_conversion/domain/models/politeness_level.dart';

void main() {
  group('AI変換レスポンスモデル テスト', () {
    // レスポンスのJSONパースが正しく行われる

    group('TC-067-005: レスポンスのJSONパースが正しく行われる', () {
      test('politeレベルのレスポンスが正しくパースされる', () {
        // テストデータ準備: バックエンドAPIの典型的なレスポンス形式
        // 初期条件設定: snake_case形式のJSON
        final json = {
          'converted_text': 'ありがとうございます',
          'original_text': 'ありがとう',
          'politeness_level': 'polite',
          'processing_time_ms': 1500,
        };

        // 実行: fromJsonでパース
        final response = AIConversionResponse.fromJson(json);

        // 結果検証: 各フィールドが正しく変換されること
        expect(response.convertedText, 'ありがとうございます');
        expect(response.originalText, 'ありがとう');
        expect(response.politenessLevel, PolitenessLevel.polite);
        expect(response.processingTimeMs, 1500);
      });

      test('normalレベルのレスポンスが正しくパースされる', () {
        // テストデータ準備: normalレベルのレスポンス
        final json = {
          'converted_text': '腰が痛いです',
          'original_text': '痛い 腰',
          'politeness_level': 'normal',
          'processing_time_ms': 1200,
        };

        // 実行: fromJsonでパース
        final response = AIConversionResponse.fromJson(json);

        // 結果検証: normalレベルが正しくパースされること
        expect(response.politenessLevel, PolitenessLevel.normal);
        expect(response.convertedText, '腰が痛いです');
      });

      test('casualレベルのレスポンスが正しくパースされる', () {
        // テストデータ準備: casualレベルのレスポンス
        final json = {
          'converted_text': 'ありがと',
          'original_text': 'ありがとう',
          'politeness_level': 'casual',
          'processing_time_ms': 800,
        };

        // 実行: fromJsonでパース
        final response = AIConversionResponse.fromJson(json);

        // 結果検証: casualレベルが正しくパースされること
        expect(response.politenessLevel, PolitenessLevel.casual);
        expect(response.processingTimeMs, 800);
      });

      test('処理時間が0の場合も正しくパースされる', () {
        // テストデータ準備: 処理時間0のエッジケース
        final json = {
          'converted_text': 'テスト',
          'original_text': 'テスト',
          'politeness_level': 'normal',
          'processing_time_ms': 0,
        };

        // 実行: fromJsonでパース
        final response = AIConversionResponse.fromJson(json);

        // 結果検証: 0値も正しく処理されること
        expect(response.processingTimeMs, 0);
      });

      test('長い文字列が正しくパースされる', () {
        // テストデータ準備: 長い変換テキスト
        final longText = 'あ' * 500;
        final json = {
          'converted_text': longText,
          'original_text': '長文テスト',
          'politeness_level': 'polite',
          'processing_time_ms': 3000,
        };

        // 実行: fromJsonでパース
        final response = AIConversionResponse.fromJson(json);

        // 結果検証: 長い文字列も正しくパースされること
        expect(response.convertedText.length, 500);
      });
    });
  });
}
