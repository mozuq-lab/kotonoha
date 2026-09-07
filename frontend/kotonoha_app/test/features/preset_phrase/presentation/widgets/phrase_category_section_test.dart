/// PhraseCategorySection ウィジェットテスト
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/widgets/phrase_category_section.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';

void main() {
  // テストデータ準備

  /// テストデータ準備: テスト用の定型文データを生成するヘルパー関数
  PresetPhrase createTestPhrase({
    required String id,
    required String content,
    String category = 'daily',
  }) {
    final now = DateTime.now();
    return PresetPhrase(
      id: id,
      content: content,
      category: category,
      displayOrder: 0,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('PhraseCategorySection - 正常系テスト', () {
    // カテゴリセクションヘッダーが表示される
    /// PhraseCategorySectionがカテゴリ名を表示することを確認
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

      // 結果検証: カテゴリヘッダーが表示されることを確認
      expect(find.text('日常'), findsOneWidget);
    });

    // 日常カテゴリの表示名が正しい
    /// 日常カテゴリの表示名が「日常」であることを確認
    testWidgets('TC-040-018: 日常カテゴリの表示名が「日常」である', (tester) async {
      // 結果検証: 静的メソッドで表示名を確認
      expect(
        PhraseCategorySection.getCategoryDisplayName('daily'),
        equals('日常'),
      );
    });

    // 体調カテゴリの表示名が正しい
    /// 体調カテゴリの表示名が「体調」であることを確認
    testWidgets('TC-040-019: 体調カテゴリの表示名が「体調」である', (tester) async {
      // 結果検証: 静的メソッドで表示名を確認
      expect(
        PhraseCategorySection.getCategoryDisplayName('health'),
        equals('体調'),
      );
    });

    // その他カテゴリの表示名が正しい
    /// その他カテゴリの表示名が「その他」であることを確認
    testWidgets('TC-040-020: その他カテゴリの表示名が「その他」である', (tester) async {
      // 結果検証: 静的メソッドで表示名を確認
      expect(
        PhraseCategorySection.getCategoryDisplayName('other'),
        equals('その他'),
      );
    });

    // セクション内の定型文が表示される
    /// カテゴリセクション内に定型文が表示されることを確認
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

      // 結果検証: 3件の定型文が表示されることを確認
      expect(find.text('定型文1'), findsOneWidget);
      expect(find.text('定型文2'), findsOneWidget);
      expect(find.text('定型文3'), findsOneWidget);
    });
  });

  group('PhraseCategorySection - コールバックテスト', () {
    // セクション内定型文タップでコールバック発火
    /// セクション内の定型文タップでonPhraseSelectedが発火することを確認
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

      // 実際の処理実行: 定型文をタップ
      await tester.tap(find.text('タップテスト'));
      await tester.pumpAndSettle();

      // 結果検証: コールバックが呼び出されたことを確認
      expect(selectedPhrase?.id, equals('1'));
    });
  });
}
