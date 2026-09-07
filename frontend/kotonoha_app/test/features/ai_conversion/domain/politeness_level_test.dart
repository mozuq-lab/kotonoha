/// PolitenessLevel テスト
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/ai_conversion/domain/models/politeness_level.dart';

void main() {
  group('PolitenessLevel テスト', () {
    // PolitenessLevel enumが正しく動作する

    group('TC-067-017: PolitenessLevel enumが正しく動作する', () {
      test('casualの値が正しい', () {
        // テストデータ準備: casualレベルを取得
        // 初期条件設定: で定義された3段階の1つ
        final level = PolitenessLevel.casual;

        // 結果検証: name値がAPIで使用される"casual"と一致する
        // snake_case変換なしでそのまま使用可能
        expect(level.name, 'casual');
      });

      test('normalの値が正しい', () {
        // テストデータ準備: normalレベルを取得
        // 初期条件設定: で定義された3段階の1つ
        final level = PolitenessLevel.normal;

        // 結果検証: name値がAPIで使用される"normal"と一致する
        // デフォルトの丁寧さレベル
        expect(level.name, 'normal');
      });

      test('politeの値が正しい', () {
        // テストデータ準備: politeレベルを取得
        // 初期条件設定: で定義された3段階の1つ
        final level = PolitenessLevel.polite;

        // 結果検証: name値がAPIで使用される"polite"と一致する
        // 最も丁寧なレベル
        expect(level.name, 'polite');
      });

      test('displayNameが日本語で正しく設定されている', () {
        // casual = "カジュアル"
        expect(PolitenessLevel.casual.displayName, 'カジュアル');

        // normal = "普通"
        expect(PolitenessLevel.normal.displayName, '普通');

        // polite = "丁寧"
        expect(PolitenessLevel.polite.displayName, '丁寧');
      });

      test('enumのvaluesが3つ存在する', () {
        // 3段階の丁寧さレベルが定義されている
        expect(PolitenessLevel.values.length, 3);
      });
    });
  });
}
