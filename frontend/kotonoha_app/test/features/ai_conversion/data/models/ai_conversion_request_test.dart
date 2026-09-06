/// AI変換リクエストモデル テスト
///
/// TASK-0067: AI変換APIクライアント実装
/// TDD Redフェーズ: TC-067-015, TC-067-016
///
/// 信頼性レベル: 青信号（api-endpoints.mdベース）
/// 関連要件: REQ-901, REQ-902, REQ-903, REQ-904
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/ai_conversion/data/models/ai_conversion_request.dart';
import 'package:kotonoha_app/features/ai_conversion/domain/models/politeness_level.dart';

void main() {
  group('AI変換リクエストモデル テスト', () {
    // =========================================================================
    // TC-067-015: AIConversionRequestのtoJsonが正しくシリアライズされる
    // =========================================================================

    group('TC-067-015: AIConversionRequestのtoJsonが正しくシリアライズされる', () {
      // テスト目的: リクエストモデルがAPI仕様に準拠したJSONを生成することを確認
      // テスト内容: toJsonメソッドがsnake_case形式のJSONを返すことを検証
      // 期待される動作: camelCase → snake_case変換が正しく行われる
      // 青信号: api-endpoints.mdに明確に定義

      test('normalレベルでtoJsonが正しいJSON形式を返す', () {
        // テストデータ準備: 標準的なリクエストデータ
        // 初期条件設定: REQ-903の3段階レベルのうちnormal
        const request = AIConversionRequest(
          inputText: 'テスト',
          politenessLevel: PolitenessLevel.normal,
        );

        // 実行: toJsonを呼び出し
        final json = request.toJson();

        // 結果検証: snake_case形式で出力されること
        // 確認内容: api-endpoints.mdの仕様通り
        expect(json['input_text'], 'テスト');
        expect(json['politeness_level'], 'normal');
      });

      test('casualレベルでtoJsonが正しいJSON形式を返す', () {
        // テストデータ準備: カジュアルレベルのリクエスト
        const request = AIConversionRequest(
          inputText: 'ありがとう',
          politenessLevel: PolitenessLevel.casual,
        );

        // 実行: toJsonを呼び出し
        final json = request.toJson();

        // 結果検証: casual値が正しく出力されること
        expect(json['input_text'], 'ありがとう');
        expect(json['politeness_level'], 'casual');
      });

      test('politeレベルでtoJsonが正しいJSON形式を返す', () {
        // テストデータ準備: 丁寧レベルのリクエスト
        const request = AIConversionRequest(
          inputText: '水 ぬるく',
          politenessLevel: PolitenessLevel.polite,
        );

        // 実行: toJsonを呼び出し
        final json = request.toJson();

        // 結果検証: polite値が正しく出力されること
        expect(json['input_text'], '水 ぬるく');
        expect(json['politeness_level'], 'polite');
      });

      test('toJsonがMap<String, dynamic>を返す', () {
        // テスト目的: 戻り値の型が正しいことを確認
        const request = AIConversionRequest(
          inputText: 'test',
          politenessLevel: PolitenessLevel.normal,
        );

        // 実行: toJsonを呼び出し
        final json = request.toJson();

        // 結果検証: Map<String, dynamic>型であること
        expect(json, isA<Map<String, dynamic>>());
        expect(json.keys.length, 2);
      });
    });

    // =========================================================================
    // TC-067-016: AIRegenerateRequestのtoJsonが正しくシリアライズされる
    // =========================================================================

    group('TC-067-016: AIRegenerateRequestのtoJsonが正しくシリアライズされる', () {
      // テスト目的: 再変換リクエストがAPI仕様に準拠したJSONを生成することを確認
      // テスト内容: previous_resultフィールドを含むJSONを検証
      // 期待される動作: 3つのフィールドが正しくシリアライズされる
      // 青信号: api-endpoints.mdに明確に定義

      test('politeレベルでtoJsonが正しいJSON形式を返す', () {
        // テストデータ準備: 再生成リクエストデータ
        // 初期条件設定: REQ-904の再生成機能
        const request = AIRegenerateRequest(
          inputText: 'テスト',
          politenessLevel: PolitenessLevel.polite,
          previousResult: '前回の結果',
        );

        // 実行: toJsonを呼び出し
        final json = request.toJson();

        // 結果検証: 3つのフィールドがsnake_case形式で出力されること
        expect(json['input_text'], 'テスト');
        expect(json['politeness_level'], 'polite');
        expect(json['previous_result'], '前回の結果');
      });

      test('全てのフィールドが正しく含まれる', () {
        // テストデータ準備: 典型的なregenerateシナリオ
        const request = AIRegenerateRequest(
          inputText: '水 ぬるく',
          politenessLevel: PolitenessLevel.normal,
          previousResult: 'お水をぬるめでお願いします',
        );

        // 実行: toJsonを呼び出し
        final json = request.toJson();

        // 結果検証: 3つのキーが存在すること
        expect(json.keys.length, 3);
        expect(json.containsKey('input_text'), true);
        expect(json.containsKey('politeness_level'), true);
        expect(json.containsKey('previous_result'), true);
      });

      test('toJsonがMap<String, dynamic>を返す', () {
        // テスト目的: 戻り値の型が正しいことを確認
        const request = AIRegenerateRequest(
          inputText: 'test',
          politenessLevel: PolitenessLevel.casual,
          previousResult: 'previous',
        );

        // 実行: toJsonを呼び出し
        final json = request.toJson();

        // 結果検証: Map<String, dynamic>型であること
        expect(json, isA<Map<String, dynamic>>());
      });
    });
  });
}
