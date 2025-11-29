/// チュートリアルオーバーレイウィジェットテスト
///
/// TASK-0075: ヘルプ画面・初回チュートリアル実装
/// 信頼性レベル: 🟡 黄信号（REQ-3001から推測）
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kotonoha_app/features/help/presentation/widgets/tutorial_overlay.dart';

void main() {
  group('TutorialOverlay', () {
    testWidgets('オーバーレイが表示される', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TutorialOverlay(
            onComplete: () {},
            child: const Scaffold(
              body: Center(child: Text('メインコンテンツ')),
            ),
          ),
        ),
      );

      // オーバーレイが表示される
      expect(find.byType(TutorialOverlay), findsOneWidget);
    });

    testWidgets('ウェルカムメッセージが表示される', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TutorialOverlay(
            onComplete: () {},
            child: const Scaffold(
              body: Center(child: Text('メインコンテンツ')),
            ),
          ),
        ),
      );

      expect(find.textContaining('ようこそ'), findsOneWidget);
    });

    testWidgets('「次へ」ボタンが表示される', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TutorialOverlay(
            onComplete: () {},
            child: const Scaffold(
              body: Center(child: Text('メインコンテンツ')),
            ),
          ),
        ),
      );

      expect(find.text('次へ'), findsOneWidget);
    });

    testWidgets('「次へ」ボタンで次のステップに進む', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TutorialOverlay(
            onComplete: () {},
            child: const Scaffold(
              body: Center(child: Text('メインコンテンツ')),
            ),
          ),
        ),
      );

      // 「次へ」ボタンをタップ
      await tester.tap(find.text('次へ'));
      await tester.pumpAndSettle();

      // 次のステップの内容が表示される
      expect(find.textContaining('文字盤'), findsAtLeastNWidgets(1));
    });

    testWidgets('「スキップ」ボタンが表示される', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TutorialOverlay(
            onComplete: () {},
            child: const Scaffold(
              body: Center(child: Text('メインコンテンツ')),
            ),
          ),
        ),
      );

      expect(find.text('スキップ'), findsOneWidget);
    });

    testWidgets('「スキップ」ボタンでチュートリアルが終了する', (tester) async {
      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: TutorialOverlay(
            onComplete: () => completed = true,
            child: const Scaffold(
              body: Center(child: Text('メインコンテンツ')),
            ),
          ),
        ),
      );

      await tester.tap(find.text('スキップ'));
      await tester.pumpAndSettle();

      expect(completed, isTrue);
    });

    testWidgets('最後のステップで「はじめる」ボタンが表示される', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TutorialOverlay(
            onComplete: () {},
            child: const Scaffold(
              body: Center(child: Text('メインコンテンツ')),
            ),
          ),
        ),
      );

      // 最後のステップまで進む
      while (find.text('次へ').evaluate().isNotEmpty) {
        await tester.tap(find.text('次へ'));
        await tester.pumpAndSettle();
      }

      expect(find.text('はじめる'), findsOneWidget);
    });

    testWidgets('「はじめる」ボタンでチュートリアルが完了する', (tester) async {
      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: TutorialOverlay(
            onComplete: () => completed = true,
            child: const Scaffold(
              body: Center(child: Text('メインコンテンツ')),
            ),
          ),
        ),
      );

      // 最後のステップまで進む
      while (find.text('次へ').evaluate().isNotEmpty) {
        await tester.tap(find.text('次へ'));
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('はじめる'));
      await tester.pumpAndSettle();

      expect(completed, isTrue);
    });

    testWidgets('ステップインジケーターが表示される', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TutorialOverlay(
            onComplete: () {},
            child: const Scaffold(
              body: Center(child: Text('メインコンテンツ')),
            ),
          ),
        ),
      );

      // ドットインジケーターが表示される
      expect(find.byType(TutorialStepIndicator), findsOneWidget);
    });

    testWidgets('各ステップの説明が正しく表示される', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TutorialOverlay(
            onComplete: () {},
            child: const Scaffold(
              body: Center(child: Text('メインコンテンツ')),
            ),
          ),
        ),
      );

      // ステップ1: ウェルカム
      expect(find.textContaining('ようこそ'), findsOneWidget);

      // ステップ2へ進む
      await tester.tap(find.text('次へ'));
      await tester.pumpAndSettle();
      expect(find.textContaining('文字盤'), findsAtLeastNWidgets(1));

      // ステップ3へ進む
      await tester.tap(find.text('次へ'));
      await tester.pumpAndSettle();
      expect(find.textContaining('定型文'), findsAtLeastNWidgets(1));
    });
  });
}
