/// HomeScreen レスポンシブレイアウト ウィジェットテスト
///
/// スマホレイアウト修正（fix/improvement-p0-p2）
/// 対象: lib/features/character_board/presentation/home_screen.dart
///
/// 検証内容:
/// - 縦持ちスマホ(390x844)でRenderFlexオーバーフローが発生しないこと
/// - 横持ちスマホ(844x390)でRenderFlexオーバーフローが発生せず、
///   文字盤（アプリの主機能）が表示され続けること
/// - タブレット(768x1024)で基本タブがスクロール不要で収まること
///   （既存の見た目を壊さないことの確認）
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kotonoha_app/features/character_board/presentation/home_screen.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/character_board_widget.dart';
import 'package:kotonoha_app/features/character_board/providers/input_buffer_provider.dart';
import 'package:kotonoha_app/features/history/domain/models/history_type.dart';
import 'package:kotonoha_app/features/history/providers/history_provider.dart';

void main() {
  group('HomeScreen レスポンシブレイアウトテスト', () {
    /// (a) 縦持ちスマホ(390x844)でRenderFlexオーバーフローが発生しない
    testWidgets(
      '390x844(縦持ちスマホ)でRenderFlexオーバーフローが発生せず文字盤が表示される',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(home: HomeScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // オーバーフローエラーなど、レイアウト例外が発生していないことを確認
        expect(tester.takeException(), isNull);

        // 文字盤（アプリの主機能）が表示されている
        expect(find.byType(CharacterBoardWidget), findsOneWidget);
        expect(find.text('あ'), findsOneWidget);
      },
    );

    /// (b) 横持ちスマホ(844x390)でRenderFlexオーバーフローが発生せず、
    ///     文字盤が高さ0で消えたりしない
    testWidgets(
      '844x390(横持ちスマホ)でRenderFlexオーバーフローが発生せず文字盤が表示される',
      (tester) async {
        tester.view.physicalSize = const Size(844, 390);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(home: HomeScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // 【回帰確認】: 修正前は可視高さ(約313px)が固定セクションの必要高さ
        // (約352px)を下回り、RenderFlexオーバーフロー(黄黒ストライプ)が
        // 発生していた。2ペインレイアウトへの切替でこれを解消する。
        expect(tester.takeException(), isNull);

        // 文字盤が実際に表示されている（高さ0で消えていない）ことを確認
        expect(find.byType(CharacterBoardWidget), findsOneWidget);
        expect(find.text('あ'), findsOneWidget);

        final boardSize = tester.getSize(find.byType(CharacterBoardWidget));
        expect(boardSize.height, greaterThan(0));
        expect(boardSize.width, greaterThan(0));
      },
    );

    /// (c) タブレット(768x1024)で基本タブがスクロール不要で収まる
    ///     （現行の見た目を維持できていることの確認）
    testWidgets(
      '768x1024(タブレット)で基本タブがスクロールなしで収まる',
      (tester) async {
        tester.view.physicalSize = const Size(768, 1024);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(home: HomeScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        // 文字盤内のGridViewが持つScrollableのスクロール可能量を検証する。
        // maxScrollExtentが実質0であれば、基本タブ50文字が1画面に収まって
        // おりスクロールが不要であることを意味する。
        final gridScrollable = find.descendant(
          of: find.byType(GridView),
          matching: find.byType(Scrollable),
        );
        expect(gridScrollable, findsOneWidget);

        final position = tester.state<ScrollableState>(gridScrollable).position;
        expect(
          position.maxScrollExtent,
          lessThanOrEqualTo(1.0),
          reason: 'タブレットでは基本タブ(50文字)がスクロールなしで収まる必要がある',
        );
      },
    );

    /// (d) 入力候補チップ行（fix/improvement-p0-p2: 頻度ベースの入力候補）が
    ///     表示された状態でも、縦持ちスマホ・横持ちスマホ・タブレットの
    ///     いずれでもRenderFlexオーバーフローが発生しないことを確認する。
    for (final size in const [
      Size(390, 844), // 縦持ちスマホ
      Size(844, 390), // 横持ちスマホ
      Size(768, 1024), // タブレット
    ]) {
      testWidgets(
        '${size.width.toInt()}x${size.height.toInt()}: 入力候補チップ表示時もオーバーフローしない',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          final container = ProviderContainer();
          addTearDown(container.dispose);

          // 候補チップが表示されるよう、前方一致する履歴を用意しておく
          await container
              .read(historyProvider.notifier)
              .addHistory('あいうえお', HistoryType.manualInput);

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: const MaterialApp(home: HomeScreen()),
            ),
          );
          await tester.pumpAndSettle();

          // 「あ」を入力し、候補チップ行を表示させる
          container.read(inputBufferProvider.notifier).addCharacter('あ');
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('あいうえお'), findsOneWidget);
        },
      );
    }
  });
}
