/// チュートリアルオーバーレイウィジェットテスト
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/themes/dark_theme.dart';
import 'package:kotonoha_app/core/themes/high_contrast_theme.dart';
import 'package:kotonoha_app/core/themes/light_theme.dart';

import 'package:kotonoha_app/features/help/presentation/widgets/tutorial_overlay.dart';

import '../../../../support/contrast_helpers.dart';

BorderSide? _paintedNextButtonSide(WidgetTester tester) {
  final material = find
      .descendant(
        of: find.widgetWithText(FilledButton, '次へ'),
        matching: find.byType(Material),
      )
      .evaluate()
      .map((element) => element.widget as Material)
      .where((material) => material.shape is OutlinedBorder)
      .firstOrNull;
  if (material == null) return null;
  final side = (material.shape! as OutlinedBorder).side;
  if (side.style != BorderStyle.solid || side.width <= 0 || side.color.a == 0) {
    return null;
  }
  return side;
}

Color _tutorialCardSurface(WidgetTester tester) {
  final material = tester.widget<Material>(
    find
        .descendant(of: find.byType(Card), matching: find.byType(Material))
        .first,
  );
  expect(material.color, isNotNull, reason: '描画されたチュートリアル Card の面色を取得できなかった');
  return material.color!;
}

void main() {
  group('TutorialOverlay', () {
    for (final (name, theme) in [
      ('ライト', lightTheme),
      ('ダーク', darkTheme),
      ('高コントラスト', highContrastTheme),
    ]) {
      testWidgets('$name: 「次へ」の枠線はチュートリアル Card 面に対して 3:1 以上', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: TutorialOverlay(
              onComplete: () {},
              child: const Scaffold(body: SizedBox.expand()),
            ),
          ),
        );

        final side = _paintedNextButtonSide(tester);
        final surface = _tutorialCardSurface(tester);
        expect(side, isNotNull, reason: '$name: 「次へ」の枠線が描画されていない');
        expect(
          contrastRatio(side!.color, surface),
          greaterThanOrEqualTo(3.0),
          reason: '$name: 「次へ」の枠線が Card 面 $surface から浮かない',
        );
      });
    }

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
