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

  group('TutorialOverlay 低背丈画面での高さ適応レイアウト（Codexレビュー指摘 P2）', () {
    testWidgets('844x390(横持ちスマホ)でRenderFlexオーバーフローが発生せずNext/Skipボタンがタップ可能',
        (tester) async {
      tester.view.physicalSize = const Size(844, 390);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

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
      await tester.pumpAndSettle();

      // オーバーフローエラー等のレイアウト例外が発生していないことを確認
      expect(tester.takeException(), isNull);

      // Next(次へ)/Skip(スキップ)ボタンが可視であり、タップ可能であることを確認
      expect(find.text('次へ'), findsOneWidget);
      expect(find.text('スキップ'), findsOneWidget);
      await tester.tap(find.text('次へ'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('スキップ'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(completed, isTrue, reason: '低背丈画面でもスキップボタンが正しく操作できる');
    });

    testWidgets('390x844(縦持ちスマホ)でRenderFlexオーバーフローが発生せずNext/Skipボタンがタップ可能',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

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
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('次へ'), findsOneWidget);
      expect(find.text('スキップ'), findsOneWidget);

      // 最後のステップまで進めてもオーバーフローが発生しないことを確認
      while (find.text('次へ').evaluate().isNotEmpty) {
        await tester.tap(find.text('次へ'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      expect(find.text('はじめる'), findsOneWidget);
    });
  });
}
