/// HistoryItemCard ウィジェットテスト
///
/// TASK-0061: 履歴一覧UI実装
/// テストフレームワーク: flutter_test
///
/// 対象: HistoryItemCard（履歴項目カードウィジェット）
///
/// 【TDD Redフェーズ】: UIが未実装、テストが失敗するはず
///
/// 信頼性レベル凡例:
/// - 🔵 青信号: 要件定義書・テストケース定義書に基づく確実なテスト
/// - 🟡 黄信号: 要件定義書から妥当な推測によるテスト
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/history/domain/models/history.dart';
import 'package:kotonoha_app/features/history/domain/models/history_type.dart';
import 'package:kotonoha_app/features/history/presentation/widgets/history_item_card.dart';

void main() {
  group('HistoryItemCard', () {
    // =========================================================================
    // 2.1 正常系テスト
    // =========================================================================
    group('正常系テスト', () {
      /// TC-061-023: 履歴項目カードが正しく表示される 🔵
      testWidgets('TC-061-023: HistoryItemCardが履歴内容を正しく表示する',
          (WidgetTester tester) async {
        // Given: 履歴データを作成する
        final testHistory = History(
          id: 'test_1',
          content: 'こんにちは',
          type: HistoryType.manualInput,
          createdAt: DateTime(2024, 11, 28, 14, 30),
        );

        // When: HistoryItemCardを表示する
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HistoryItemCard(
                history: testHistory,
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

        // キーボードアイコンが表示される
        expect(find.byIcon(Icons.keyboard), findsOneWidget);
      });

      /// TC-061-024: タップ時にコールバックが発火する 🔵
      testWidgets('TC-061-024: HistoryItemCardタップでonTapコールバックが発火する',
          (WidgetTester tester) async {
        // Given: 履歴データとコールバック関数を準備する
        final testHistory = History(
          id: 'test_1',
          content: 'こんにちは',
          type: HistoryType.manualInput,
          createdAt: DateTime.now(),
        );

        var tapCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HistoryItemCard(
                history: testHistory,
                onTap: () => tapCalled = true,
                onDelete: () {},
              ),
            ),
          ),
        );

        // When: カードをタップする
        await tester.tap(find.byType(HistoryItemCard));
        await tester.pumpAndSettle();

        // Then: コールバックが1回呼び出される
        expect(tapCalled, isTrue);
      });

      /// TC-061-025: 削除ボタンが表示される 🔵
      testWidgets('TC-061-025: HistoryItemCardに削除ボタンが表示される',
          (WidgetTester tester) async {
        // Given: 履歴データを作成する
        final testHistory = History(
          id: 'test_1',
          content: 'こんにちは',
          type: HistoryType.manualInput,
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HistoryItemCard(
                history: testHistory,
                onTap: () {},
                onDelete: () {},
              ),
            ),
          ),
        );

        // Then: 削除ボタン（ゴミ箱アイコン）が表示される
        expect(find.byIcon(Icons.delete), findsOneWidget);
      });

      /// TC-061-026: 削除ボタンタップでコールバックが発火する 🔵
      testWidgets('TC-061-026: 削除ボタンタップでonDeleteコールバックが発火する',
          (WidgetTester tester) async {
        // Given: 履歴データと削除コールバック関数を準備する
        final testHistory = History(
          id: 'test_1',
          content: 'こんにちは',
          type: HistoryType.manualInput,
          createdAt: DateTime.now(),
        );

        var deleteCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HistoryItemCard(
                history: testHistory,
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
    // 2.2 種類別アイコンテスト
    // =========================================================================
    group('種類別アイコンテスト', () {
      /// TC-061-028: 文字盤入力アイコンが表示される 🟡
      testWidgets('TC-061-028: 文字盤入力の履歴にキーボードアイコンが表示される',
          (WidgetTester tester) async {
        final testHistory = History(
          id: 'test_1',
          content: 'テスト',
          type: HistoryType.manualInput,
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HistoryItemCard(
                history: testHistory,
                onTap: () {},
                onDelete: () {},
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.keyboard), findsOneWidget);
      });

      /// TC-061-029: 定型文アイコンが表示される 🟡
      testWidgets('TC-061-029: 定型文の履歴にリストアイコンが表示される',
          (WidgetTester tester) async {
        final testHistory = History(
          id: 'test_1',
          content: 'テスト',
          type: HistoryType.preset,
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HistoryItemCard(
                history: testHistory,
                onTap: () {},
                onDelete: () {},
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.list), findsOneWidget);
      });

      /// TC-061-030: AI変換アイコンが表示される 🟡
      testWidgets('TC-061-030: AI変換結果の履歴にAIアイコンが表示される',
          (WidgetTester tester) async {
        final testHistory = History(
          id: 'test_1',
          content: 'テスト',
          type: HistoryType.aiConverted,
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HistoryItemCard(
                history: testHistory,
                onTap: () {},
                onDelete: () {},
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
      });

      /// TC-061-031: 大ボタンアイコンが表示される 🟡
      testWidgets('TC-061-031: 大ボタンの履歴にボタンアイコンが表示される',
          (WidgetTester tester) async {
        final testHistory = History(
          id: 'test_1',
          content: 'テスト',
          type: HistoryType.quickButton,
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HistoryItemCard(
                history: testHistory,
                onTap: () {},
                onDelete: () {},
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.smart_button), findsOneWidget);
      });
    });

    // =========================================================================
    // 2.4 星ボタン（お気に入り追加のタップ代替）テスト
    // =========================================================================
    group('星ボタンテスト', () {
      /// onFavoriteTapが指定されない場合、星ボタンは表示されない
      testWidgets('onFavoriteTapが未指定の場合、星ボタンが表示されない',
          (WidgetTester tester) async {
        final testHistory = History(
          id: 'test_1',
          content: 'こんにちは',
          type: HistoryType.manualInput,
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HistoryItemCard(
                history: testHistory,
                onTap: () {},
                onDelete: () {},
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.star), findsNothing);
        expect(find.byIcon(Icons.star_border), findsNothing);
      });

      /// 未お気に入りの場合、star_borderアイコンが表示されタップでコールバックが発火する
      testWidgets('未お気に入りの場合star_borderが表示され、タップでonFavoriteTapが発火する',
          (WidgetTester tester) async {
        final testHistory = History(
          id: 'test_1',
          content: 'こんにちは',
          type: HistoryType.manualInput,
          createdAt: DateTime.now(),
        );
        var favoriteTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HistoryItemCard(
                history: testHistory,
                onTap: () {},
                onDelete: () {},
                isFavorited: false,
                onFavoriteTap: () => favoriteTapped = true,
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.star_border), findsOneWidget);
        expect(find.byIcon(Icons.star), findsNothing);

        await tester.tap(find.byIcon(Icons.star_border));
        await tester.pump();

        expect(favoriteTapped, isTrue);
      });

      /// 既にお気に入り登録済みの場合、塗りつぶしのstarアイコンが表示される
      testWidgets('お気に入り登録済みの場合、塗りつぶしのstarアイコンが表示される',
          (WidgetTester tester) async {
        final testHistory = History(
          id: 'test_1',
          content: 'こんにちは',
          type: HistoryType.manualInput,
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HistoryItemCard(
                history: testHistory,
                onTap: () {},
                onDelete: () {},
                isFavorited: true,
                onFavoriteTap: () {},
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.star), findsOneWidget);
        expect(find.byIcon(Icons.star_border), findsNothing);
      });
    });

    // =========================================================================
    // 2.5 「入力欄へ」ボタンテスト
    // =========================================================================
    group('入力欄へボタンテスト', () {
      testWidgets('「入力欄へ」ラベルが表示される', (WidgetTester tester) async {
        final testHistory = History(
          id: 'test_1',
          content: 'こんにちは',
          type: HistoryType.manualInput,
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HistoryItemCard(
                history: testHistory,
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
    // 2.3 サイズ・アクセシビリティテスト
    // =========================================================================
    group('サイズ・アクセシビリティテスト', () {
      /// TC-061-032: カードの最小高さが44px以上 🔵
      testWidgets('TC-061-032: HistoryItemCardの最小高さが44px以上',
          (WidgetTester tester) async {
        // Given: 短いテキストの履歴を作成する
        final testHistory = History(
          id: 'test_1',
          content: 'テスト',
          type: HistoryType.manualInput,
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HistoryItemCard(
                history: testHistory,
                onTap: () {},
                onDelete: () {},
              ),
            ),
          ),
        );

        // When: カードの高さを測定する
        final cardSize = tester.getSize(find.byType(HistoryItemCard));

        // Then: 高さが44px以上
        expect(cardSize.height, greaterThanOrEqualTo(44.0));
      });
    });
  });
}
