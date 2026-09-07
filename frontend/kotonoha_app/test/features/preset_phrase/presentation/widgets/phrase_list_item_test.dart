/// PhraseListItem ウィジェットテスト
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/widgets/phrase_list_item.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';

void main() {
  // テストデータ準備

  /// テストデータ準備: テスト用の定型文データを生成するヘルパー関数
  PresetPhrase createTestPhrase({
    required String id,
    required String content,
    String category = 'daily',
    int displayOrder = 0,
  }) {
    final now = DateTime.now();
    return PresetPhrase(
      id: id,
      content: content,
      category: category,
      displayOrder: displayOrder,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('PhraseListItem - 正常系テスト', () {
    // 定型文アイテムが正しく表示される
    /// PhraseListItemが定型文内容を正しく表示することを確認
    testWidgets('TC-040-011: PhraseListItemが定型文内容を正しく表示する', (tester) async {
      final phrase = createTestPhrase(id: '1', content: 'こんにちは');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhraseListItem(
              phrase: phrase,
              isFavorite: false,
            ),
          ),
        ),
      );

      // 結果検証: 定型文内容が表示されることを確認
      expect(find.text('こんにちは'), findsOneWidget);
    });

    // お気に入りアイコンが表示される
    /// お気に入り定型文にお気に入りアイコンが表示されることを確認
    testWidgets('TC-040-012: お気に入り定型文にお気に入りアイコンが表示される', (tester) async {
      final phrase = createTestPhrase(id: '1', content: 'お気に入り');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhraseListItem(
              phrase: phrase,
              // 設計変更: Phase 3 / WP-2 / Stage 3b - お気に入りかどうかは
              // 定型文のフラグではなく、favoriteProviderを読む呼び出し側が渡す
              isFavorite: true,
            ),
          ),
        ),
      );

      // 結果検証: お気に入りアイコンが表示されることを確認
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    // タップ時にコールバックが発火する
    /// PhraseListItemタップでonTapコールバックが発火することを確認
    testWidgets('TC-040-013: PhraseListItemタップでonTapコールバックが発火する',
        (tester) async {
      bool tapped = false;
      final phrase = createTestPhrase(id: '1', content: 'タップテスト');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhraseListItem(
              phrase: phrase,
              isFavorite: false,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      // 実際の処理実行: アイテムをタップ
      await tester.tap(find.text('タップテスト'));
      await tester.pumpAndSettle();

      // 結果検証: コールバックが呼び出されたことを確認
      expect(tapped, isTrue);
    });

    // 長いテキストが省略表示される
    /// 長い定型文テキストが省略表示されることを確認
    testWidgets('TC-040-014: 長い定型文テキストが省略表示される', (tester) async {
      // テストデータ準備: 100文字の長いテキスト
      final longContent = 'あ' * 100;
      final phrase = createTestPhrase(id: '1', content: longContent);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200, // 幅を制限
              child: PhraseListItem(
                phrase: phrase,
                isFavorite: false,
              ),
            ),
          ),
        ),
      );

      // 結果検証: Textウィジェットがoverflow設定を持っていることを確認
      final textWidget = tester.widget<Text>(find.byType(Text).first);
      expect(textWidget.overflow, equals(TextOverflow.ellipsis));
    });
  });

  group('PhraseListItem - サイズ・アクセシビリティテスト', () {
    // アイテムの最小高さが44px以上
    /// PhraseListItemの最小高さが44px以上であることを確認
    testWidgets('TC-040-015: PhraseListItemの最小高さが44px以上', (tester) async {
      final phrase = createTestPhrase(id: '1', content: 'あ');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhraseListItem(
              phrase: phrase,
              isFavorite: false,
            ),
          ),
        ),
      );

      // 結果検証: 最小高さを確認
      final itemSize = tester.getSize(find.byType(PhraseListItem));
      expect(itemSize.height, greaterThanOrEqualTo(AppSizes.minTapTarget));
    });

    // アイテムの推奨高さ60px
    /// PhraseListItemの推奨高さが60pxであることを確認
    testWidgets('TC-040-016: PhraseListItemの推奨高さが60px', (tester) async {
      final phrase = createTestPhrase(id: '1', content: '推奨サイズテスト');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhraseListItem(
              phrase: phrase,
              isFavorite: false,
            ),
          ),
        ),
      );

      // 結果検証: 推奨高さを確認
      final itemSize = tester.getSize(find.byType(PhraseListItem));
      expect(
          itemSize.height, greaterThanOrEqualTo(AppSizes.recommendedTapTarget));
    });
  });

  group('PhraseListItem - 境界値テスト', () {
    // 定型文テキストが1文字の場合
    /// 定型文テキストが最短（1文字）の場合を確認
    testWidgets('TC-040-033: 定型文テキストが最短（1文字）の場合', (tester) async {
      final phrase = createTestPhrase(id: '1', content: 'あ');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhraseListItem(
              phrase: phrase,
              isFavorite: false,
            ),
          ),
        ),
      );

      // 結果検証: 1文字が表示されることを確認
      expect(find.text('あ'), findsOneWidget);
    });

    // 定型文テキストが500文字（上限値）の場合
    /// 定型文テキストが500文字（上限値）の場合を確認
    testWidgets('TC-040-034: 定型文テキストが500文字（上限値）の場合', (tester) async {
      // テストデータ準備: 500文字のテキスト
      final longContent = 'あ' * 500;
      final phrase = createTestPhrase(id: '1', content: longContent);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: PhraseListItem(
                phrase: phrase,
                isFavorite: false,
              ),
            ),
          ),
        ),
      );

      // 結果検証: ウィジェットがエラーなく表示されることを確認
      expect(find.byType(PhraseListItem), findsOneWidget);
    });
  });

  group('PhraseListItem - 入力欄へボタンテスト', () {
    /// 対応: 定型文タップ=即時読み上げのみだったところに
    /// 入力欄へ入れて編集する動線として「入力欄へ」ボタンを追加した。
    testWidgets('「入力欄へ」ラベルが表示される', (tester) async {
      final phrase = createTestPhrase(id: '1', content: '入力欄へテスト');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhraseListItem(
              phrase: phrase,
              isFavorite: false,
            ),
          ),
        ),
      );

      expect(find.text('入力欄へ'), findsOneWidget);
    });
  });

  group('PhraseListItem - お気に入り切り替えテスト', () {
    // お気に入り切り替えコールバックが発火する
    /// お気に入りアイコンタップでonFavoriteToggleが発火することを確認
    testWidgets('TC-040-035: お気に入りアイコンタップでonFavoriteToggleが発火する',
        (tester) async {
      bool favoriteToggled = false;
      final phrase = createTestPhrase(id: '1', content: 'お気に入りテスト');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhraseListItem(
              phrase: phrase,
              isFavorite: false,
              onFavoriteToggle: () => favoriteToggled = true,
            ),
          ),
        ),
      );

      // 実際の処理実行: お気に入りアイコンをタップ
      // お気に入りでない場合はstar_borderアイコン
      await tester.tap(find.byIcon(Icons.star_border));
      await tester.pumpAndSettle();

      // 結果検証: コールバックが呼び出されたことを確認
      expect(favoriteToggled, isTrue);
    });
  });
}
