/// PhraseCategorySection ウィジェットテスト
///
/// TASK-0040: 定型文一覧UI実装
/// テストケース: TC-040-017〜TC-040-021
///
/// テスト対象: lib/features/preset_phrase/presentation/widgets/phrase_category_section.dart
///
/// 【TDD Redフェーズ】: ウィジェットが未実装のため、このテストは失敗する
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/widgets/phrase_category_section.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';

void main() {
  // ==========================================================================
  // テストデータ準備
  // ==========================================================================

  /// 【テストデータ準備】: テスト用の定型文データを生成するヘルパー関数
  PresetPhrase createTestPhrase({
    required String id,
    required String content,
    String category = 'daily',
    bool isFavorite = false,
  }) {
    final now = DateTime.now();
    return PresetPhrase(
      id: id,
      content: content,
      category: category,
      isFavorite: isFavorite,
      displayOrder: 0,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('PhraseCategorySection - 正常系テスト', () {
    // =========================================================================
    // TC-040-017: カテゴリセクションヘッダーが表示される
    // =========================================================================
    /// TC-040-017: PhraseCategorySectionがカテゴリ名を表示することを確認
    ///
    /// 【テスト目的】: ヘッダー表示確認
    /// 【テスト内容】: カテゴリヘッダー表示
    /// 【期待される動作】: カテゴリ名（「日常」等）が表示される
    ///
    /// 信頼性レベル: 🔵 青信号
    /// 関連要件: REQ-106
    /// 優先度: P0 必須
    testWidgets('TC-040-017: PhraseCategorySectionがカテゴリ名を表示する', (tester) async {
      final phrases = [
        createTestPhrase(id: '1', content: 'テスト', category: 'daily'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhraseCategorySection(
              category: 'daily',
              phrases: phrases,
              favoritePresetIds: const <String>{},
            ),
          ),
        ),
      );

      // 【結果検証】: カテゴリヘッダーが表示されることを確認
      expect(find.text('日常'), findsOneWidget); // 【確認内容】: 日常ヘッダー表示 🔵
    });

    // =========================================================================
    // TC-040-018: 日常カテゴリの表示名が正しい
    // =========================================================================
    /// TC-040-018: 日常カテゴリの表示名が「日常」であることを確認
    ///
    /// 【テスト目的】: 表示名マッピング確認
    /// 【テスト内容】: カテゴリ表示名
    /// 【期待される動作】: "daily" → "日常"
    ///
    /// 信頼性レベル: 🔵 青信号
    /// 関連要件: REQ-106
    /// 優先度: P0 必須
    testWidgets('TC-040-018: 日常カテゴリの表示名が「日常」である', (tester) async {
      // 【結果検証】: 静的メソッドで表示名を確認
      expect(
        PhraseCategorySection.getCategoryDisplayName('daily'),
        equals('日常'),
      ); // 【確認内容】: daily → 日常 🔵
    });

    // =========================================================================
    // TC-040-019: 体調カテゴリの表示名が正しい
    // =========================================================================
    /// TC-040-019: 体調カテゴリの表示名が「体調」であることを確認
    ///
    /// 【テスト目的】: 表示名マッピング確認
    /// 【テスト内容】: カテゴリ表示名
    /// 【期待される動作】: "health" → "体調"
    ///
    /// 信頼性レベル: 🔵 青信号
    /// 関連要件: REQ-106
    /// 優先度: P0 必須
    testWidgets('TC-040-019: 体調カテゴリの表示名が「体調」である', (tester) async {
      // 【結果検証】: 静的メソッドで表示名を確認
      expect(
        PhraseCategorySection.getCategoryDisplayName('health'),
        equals('体調'),
      ); // 【確認内容】: health → 体調 🔵
    });

    // =========================================================================
    // TC-040-020: その他カテゴリの表示名が正しい
    // =========================================================================
    /// TC-040-020: その他カテゴリの表示名が「その他」であることを確認
    ///
    /// 【テスト目的】: 表示名マッピング確認
    /// 【テスト内容】: カテゴリ表示名
    /// 【期待される動作】: "other" → "その他"
    ///
    /// 信頼性レベル: 🔵 青信号
    /// 関連要件: REQ-106
    /// 優先度: P0 必須
    testWidgets('TC-040-020: その他カテゴリの表示名が「その他」である', (tester) async {
      // 【結果検証】: 静的メソッドで表示名を確認
      expect(
        PhraseCategorySection.getCategoryDisplayName('other'),
        equals('その他'),
      ); // 【確認内容】: other → その他 🔵
    });

    // =========================================================================
    // TC-040-021: セクション内の定型文が表示される
    // =========================================================================
    /// TC-040-021: カテゴリセクション内に定型文が表示されることを確認
    ///
    /// 【テスト目的】: セクション構成確認
    /// 【テスト内容】: セクション内アイテム表示
    /// 【期待される動作】: セクションヘッダーの下に定型文が表示される
    ///
    /// 信頼性レベル: 🔵 青信号
    /// 関連要件: REQ-101, REQ-106
    /// 優先度: P0 必須
    testWidgets('TC-040-021: カテゴリセクション内に定型文が表示される', (tester) async {
      final phrases = [
        createTestPhrase(id: '1', content: '定型文1', category: 'daily'),
        createTestPhrase(id: '2', content: '定型文2', category: 'daily'),
        createTestPhrase(id: '3', content: '定型文3', category: 'daily'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhraseCategorySection(
              category: 'daily',
              phrases: phrases,
              favoritePresetIds: const <String>{},
            ),
          ),
        ),
      );

      // 【結果検証】: 3件の定型文が表示されることを確認
      expect(find.text('定型文1'), findsOneWidget); // 【確認内容】: 定型文1 🔵
      expect(find.text('定型文2'), findsOneWidget); // 【確認内容】: 定型文2 🔵
      expect(find.text('定型文3'), findsOneWidget); // 【確認内容】: 定型文3 🔵
    });
  });

  group('PhraseCategorySection - コールバックテスト', () {
    // =========================================================================
    // セクション内定型文タップでコールバック発火
    // =========================================================================
    /// セクション内の定型文タップでonPhraseSelectedが発火することを確認
    ///
    /// 【テスト目的】: コールバック確認
    /// 【テスト内容】: セクション内アイテムのタップイベント
    /// 【期待される動作】: タップでコールバックが呼び出される
    ///
    /// 信頼性レベル: 🔵 青信号
    /// 関連要件: AC-004
    /// 優先度: P0 必須
    testWidgets('セクション内定型文タップでonPhraseSelectedが発火する', (tester) async {
      PresetPhrase? selectedPhrase;
      final phrase =
          createTestPhrase(id: '1', content: 'タップテスト', category: 'daily');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhraseCategorySection(
              category: 'daily',
              phrases: [phrase],
              favoritePresetIds: const <String>{},
              onPhraseSelected: (p) => selectedPhrase = p,
            ),
          ),
        ),
      );

      // 【実際の処理実行】: 定型文をタップ
      await tester.tap(find.text('タップテスト'));
      await tester.pumpAndSettle();

      // 【結果検証】: コールバックが呼び出されたことを確認
      expect(selectedPhrase?.id, equals('1')); // 【確認内容】: 正しい定型文が渡された 🔵
    });
  });
}
