/// SendToInputButton テスト
///
/// 改善: 定型文・履歴・お気に入りタップ = 即時読み上げのみで、
/// 「入力欄に入れて編集してからAI変換したい」という導線が存在しなかった
/// （REQ-102未実装）。本ボタンはその導線を提供する。
///
/// 検証内容:
/// - 入力欄が空の場合: そのまま挿入してホーム画面へ遷移する
/// - 入力欄が空でない場合: 置換確認ダイアログを表示し、確定後にのみ置換する
/// - キャンセル時は入力欄が変更されない
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/features/character_board/providers/input_buffer_provider.dart';
import 'package:kotonoha_app/shared/widgets/send_to_input_button.dart';

void main() {
  /// テスト用の最小GoRouterを構築する。
  /// '/' をホーム相当、'/other' を送信元画面（SendToInputButtonを配置）とする。
  GoRouter buildRouter(Widget otherScreenChild) {
    return GoRouter(
      initialLocation: '/other',
      routes: [
        GoRoute(
          path: '/',
          name: 'home',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('HOME_SCREEN'))),
        ),
        GoRoute(
          path: '/other',
          builder: (context, state) => Scaffold(body: otherScreenChild),
        ),
      ],
    );
  }

  Widget buildTestApp(GoRouter router) {
    return ProviderScope(
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('SendToInputButton 表示テスト', () {
    testWidgets('アイコンとラベル「入力欄へ」が表示される', (tester) async {
      final router = buildRouter(const SendToInputButton(text: 'テスト'));
      await tester.pumpWidget(buildTestApp(router));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.input), findsOneWidget);
      expect(find.text('入力欄へ'), findsOneWidget);
    });

    testWidgets('タップターゲットの高さが44px以上である', (tester) async {
      final router = buildRouter(const SendToInputButton(text: 'テスト'));
      await tester.pumpWidget(buildTestApp(router));
      await tester.pumpAndSettle();

      final size = tester.getSize(find.byType(SendToInputButton));
      expect(size.height, greaterThanOrEqualTo(AppSizes.minTapTarget));
    });

    testWidgets('テキストが空の場合はタップしても何も起きない', (tester) async {
      final router = buildRouter(const SendToInputButton(text: ''));
      await tester.pumpWidget(buildTestApp(router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('入力欄へ'));
      await tester.pumpAndSettle();

      // ホーム画面へは遷移しない
      expect(find.text('HOME_SCREEN'), findsNothing);
    });
  });

  group('SendToInputButton タップ動作テスト', () {
    testWidgets('入力欄が空の場合、そのまま挿入してホーム画面へ遷移する', (tester) async {
      final router = buildRouter(const SendToInputButton(text: 'テストです'));
      await tester.pumpWidget(buildTestApp(router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('入力欄へ'));
      await tester.pumpAndSettle();

      // ホーム画面へ遷移している
      expect(find.text('HOME_SCREEN'), findsOneWidget);

      final context = tester.element(find.text('HOME_SCREEN'));
      final container = ProviderScope.containerOf(context);
      expect(container.read(inputBufferProvider), 'テストです');
    });

    testWidgets('入力欄が空でない場合、確認ダイアログを表示し置換前は変更しない', (tester) async {
      final router = buildRouter(const SendToInputButton(text: '新しいテキスト'));
      await tester.pumpWidget(buildTestApp(router));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(SendToInputButton));
      final container = ProviderScope.containerOf(context);
      container.read(inputBufferProvider.notifier).setText('既存の入力');

      await tester.tap(find.text('入力欄へ'));
      await tester.pumpAndSettle();

      // 確認ダイアログが表示される
      expect(find.byType(AlertDialog), findsOneWidget);
      // まだ置換されていない
      expect(container.read(inputBufferProvider), '既存の入力');
      // まだホーム画面へは遷移していない
      expect(find.text('HOME_SCREEN'), findsNothing);
    });

    testWidgets('確認ダイアログで「置き換える」を選択すると置換してホーム画面へ遷移する', (tester) async {
      final router = buildRouter(const SendToInputButton(text: '新しいテキスト'));
      await tester.pumpWidget(buildTestApp(router));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(SendToInputButton));
      final container = ProviderScope.containerOf(context);
      container.read(inputBufferProvider.notifier).setText('既存の入力');

      await tester.tap(find.text('入力欄へ'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('置き換える'));
      await tester.pumpAndSettle();

      expect(container.read(inputBufferProvider), '新しいテキスト');
      expect(find.text('HOME_SCREEN'), findsOneWidget);
    });

    testWidgets('確認ダイアログで「キャンセル」を選択すると入力欄は変更されない', (tester) async {
      final router = buildRouter(const SendToInputButton(text: '新しいテキスト'));
      await tester.pumpWidget(buildTestApp(router));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(SendToInputButton));
      final container = ProviderScope.containerOf(context);
      container.read(inputBufferProvider.notifier).setText('既存の入力');

      await tester.tap(find.text('入力欄へ'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      expect(container.read(inputBufferProvider), '既存の入力');
      // 送信元画面のまま（遷移していない）
      expect(find.byType(SendToInputButton), findsOneWidget);
      expect(find.text('HOME_SCREEN'), findsNothing);
    });
  });
}
