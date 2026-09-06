/// PolitenessLevel テスト
///
/// TASK-0067: AI変換APIクライアント実装
/// TDD Redフェーズ: TC-067-017
///
/// 信頼性レベル: 青信号（interfaces.dartベース）
/// 関連要件: REQ-903
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/ai_conversion/domain/models/politeness_level.dart';

void main() {
  group('PolitenessLevel テスト', () {
    // =========================================================================
    // TC-067-017: PolitenessLevel enumが正しく動作する
    // =========================================================================

    group('TC-067-017: PolitenessLevel enumが正しく動作する', () {
      // テスト目的: PolitenessLevelのenum値とname変換が正しいことを確認
      // テスト内容: casual, normal, politeの各値がAPI仕様に準拠したname値を持つ
      // 期待される動作: enumのnameプロパティがそのまま小文字のAPI値として使用可能
      // 青信号: interfaces.dart、api-endpoints.mdに明確に定義

      test('casualの値が正しい', () {
        // テストデータ準備: casualレベルを取得
        // 初期条件設定: REQ-903で定義された3段階の1つ
        final level = PolitenessLevel.casual;

        // 結果検証: name値がAPIで使用される"casual"と一致する
        // 確認内容: snake_case変換なしでそのまま使用可能
        expect(level.name, 'casual');
      });

      test('normalの値が正しい', () {
        // テストデータ準備: normalレベルを取得
        // 初期条件設定: REQ-903で定義された3段階の1つ
        final level = PolitenessLevel.normal;

        // 結果検証: name値がAPIで使用される"normal"と一致する
        // 確認内容: デフォルトの丁寧さレベル
        expect(level.name, 'normal');
      });

      test('politeの値が正しい', () {
        // テストデータ準備: politeレベルを取得
        // 初期条件設定: REQ-903で定義された3段階の1つ
        final level = PolitenessLevel.polite;

        // 結果検証: name値がAPIで使用される"polite"と一致する
        // 確認内容: 最も丁寧なレベル
        expect(level.name, 'polite');
      });

      test('displayNameが日本語で正しく設定されている', () {
        // テスト目的: UI表示用の日本語名が正しいことを確認
        // テスト内容: 各レベルのdisplayName値を検証
        // 期待される動作: ユーザーに表示する日本語名が適切に設定される
        // 青信号: interfaces.dartに定義

        // 確認内容: casual = "カジュアル"
        expect(PolitenessLevel.casual.displayName, 'カジュアル');

        // 確認内容: normal = "普通"
        expect(PolitenessLevel.normal.displayName, '普通');

        // 確認内容: polite = "丁寧"
        expect(PolitenessLevel.polite.displayName, '丁寧');
      });

      test('enumのvaluesが3つ存在する', () {
        // テスト目的: REQ-903の3段階要件を満たすことを確認
        // テスト内容: PolitenessLevel.valuesの要素数を検証
        // 期待される動作: 丁度3つの値が存在する
        // 青信号: REQ-903に明確に「3段階」と定義

        // 確認内容: 3段階の丁寧さレベルが定義されている
        expect(PolitenessLevel.values.length, 3);
      });
    });
  });
}
