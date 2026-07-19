/// FavoriteItemCard ウィジェットテスト
///
/// TASK-0064: お気に入り一覧UI実装
/// テストフレームワーク: flutter_test
///
/// 対象: FavoriteItemCard（お気に入り項目カードウィジェット）
///
/// 【TDD Redフェーズ】: UIが未実装、テストが失敗するはず
///
/// 信頼性レベル凡例:
/// - 🔵 青信号: 要件定義書・テストケース定義書に基づく確実なテスト
/// - 🟡 黄信号: 要件定義書から妥当な推測によるテスト
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/favorite/domain/models/favorite.dart';
import 'package:kotonoha_app/features/favorites/presentation/widgets/favorite_item_card.dart';

void main() {
  group('FavoriteItemCard', () {
    // =========================================================================
    // 2.1 正常系テスト
    // =========================================================================
    group('正常系テスト', () {
      /// TC-064-029: お気に入り項目カードが正しく表示される 🔵
      testWidgets('TC-064-029: FavoriteItemCardがお気に入り内容を正しく表示する',
          (WidgetTester tester) async {
        // Given: お気に入りデータを作成する
        final testFavorite = Favorite(
          id: 'test_1',
          content: 'こんにちは',
          createdAt: DateTime(2024, 11, 28, 14, 30),
          displayOrder: 0,
        );

        // When: FavoriteItemCardを表示する
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FavoriteItemCard(
                favorite: testFavorite,
                onTap: () {},
                onDelete: () {},
              ),
            ),
          ),
        );

        // Then: 「こんにちは」が表示される
        expect(find.text('こんにちは'), findsOneWidget);

        // 日時が「11/28 14:30」形式で表示される
        expect(find.text('11/28 14:30'), findsOneWidget);
      });

      /// TC-064-030: タップ時にコールバックが発火する 🔵
      testWidgets('TC-064-030: FavoriteItemCardタップでonTapコールバックが発火する',
          (WidgetTester tester) async {
        // Given: お気に入りデータとコールバック関数を準備する
        final testFavorite = Favorite(
          id: 'test_1',
          content: 'こんにちは',
          createdAt: DateTime.now(),
          displayOrder: 0,
        );

        var tapCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FavoriteItemCard(
                favorite: testFavorite,
                onTap: () => tapCalled = true,
                onDelete: () {},
              ),
            ),
          ),
        );

        // When: カードをタップする
        await tester.tap(find.byType(FavoriteItemCard));
        await tester.pumpAndSettle();

        // Then: コールバックが1回呼び出される
        expect(tapCalled, isTrue);
      });

      /// TC-064-031: 削除ボタンが表示される 🔵
      testWidgets('TC-064-031: FavoriteItemCardに削除ボタンが表示される',
          (WidgetTester tester) async {
        // Given: お気に入りデータを作成する
        final testFavorite = Favorite(
          id: 'test_1',
          content: 'こんにちは',
          createdAt: DateTime.now(),
          displayOrder: 0,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FavoriteItemCard(
                favorite: testFavorite,
                onTap: () {},
                onDelete: () {},
              ),
            ),
          ),
        );

        // Then: 削除ボタン（ゴミ箱アイコン）が表示される
        expect(find.byIcon(Icons.delete), findsOneWidget);
      });

      /// TC-064-032: 削除ボタンタップでコールバックが発火する 🔵
      testWidgets('TC-064-032: 削除ボタンタップでonDeleteコールバックが発火する',
          (WidgetTester tester) async {
        // Given: お気に入りデータと削除コールバック関数を準備する
        final testFavorite = Favorite(
          id: 'test_1',
          content: 'こんにちは',
          createdAt: DateTime.now(),
          displayOrder: 0,
        );

        var deleteCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FavoriteItemCard(
                favorite: testFavorite,
                onTap: () {},
                onDelete: () => deleteCalled = true,
              ),
            ),
          ),
        );

        // When: 削除ボタンをタップする
        await tester.tap(find.byIcon(Icons.delete));
        await tester.pumpAndSettle();

        // Then: 削除コールバックが1回呼び出される
        expect(deleteCalled, isTrue);
      });
    });

    // =========================================================================
    // 2.1b 「入力欄へ」ボタンテスト
    // =========================================================================
    group('入力欄へボタンテスト', () {
      testWidgets('「入力欄へ」ラベルが表示される', (WidgetTester tester) async {
        final testFavorite = Favorite(
          id: 'test_1',
          content: 'こんにちは',
          createdAt: DateTime.now(),
          displayOrder: 0,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FavoriteItemCard(
                favorite: testFavorite,
                onTap: () {},
                onDelete: () {},
              ),
            ),
          ),
        );

        expect(find.text('入力欄へ'), findsOneWidget);
      });
    });

    // =========================================================================
    // 2.2 サイズ・アクセシビリティテスト
    // =========================================================================
    group('サイズ・アクセシビリティテスト', () {
      /// TC-064-033: カードの最小高さが44px以上 🔵
      testWidgets('TC-064-033: FavoriteItemCardの最小高さが44px以上',
          (WidgetTester tester) async {
        // Given: 短いテキストのお気に入りを作成する
        final testFavorite = Favorite(
          id: 'test_1',
          content: 'テスト',
          createdAt: DateTime.now(),
          displayOrder: 0,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FavoriteItemCard(
                favorite: testFavorite,
                onTap: () {},
                onDelete: () {},
              ),
            ),
          ),
        );

        // When: カードの高さを測定する
        final cardSize = tester.getSize(find.byType(FavoriteItemCard));

        // Then: 高さが44px以上
        expect(cardSize.height, greaterThanOrEqualTo(44.0));
      });
    });
  });
}
