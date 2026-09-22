/// 低い画面での文字盤の表示 ウィジェットテスト（台帳 L-155）
/// 対象
///   lib/features/character_board/presentation/home_screen.dart
///   lib/features/character_board/presentation/widgets/character_board_widget.dart
/// 条件: 実AppShell・フォント設定「大」・OSの文字拡大・オフライン。
/// 320x690はオフラインバナーのぶんだけHomeの可視高さが500pxを下回り
/// レイアウトが切り替わる境界。
/// 告知の横オーバーフロー（台帳 L-156）はこのファイルの観測点ではないので
/// 取り出して捨てる（別ファイル home_screen_low_screen_notices_test.dart）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/features/character_board/presentation/home_screen.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/character_board_widget.dart';
import 'package:kotonoha_app/features/character_board/providers/input_buffer_provider.dart';
import 'package:kotonoha_app/features/emergency/presentation/widgets/emergency_button_with_confirmation.dart';
import 'package:kotonoha_app/features/network/domain/models/network_state.dart';
import 'package:kotonoha_app/features/network/presentation/widgets/offline_banner.dart';
import 'package:kotonoha_app/features/network/providers/network_provider.dart';

import 'home_layout_test_support.dart';

void main() {
  final harness = HomeLayoutHarness.install();

  // L-155: 大設定×OS2.0の実AppShellで320x690からオフラインになると
  // Homeの可視高さが542→486pxとなりレイアウトが切り替わり、文字盤のセルが
  // 25.12x44px（幅が44px未満）になっていた。
  // リスク「キーを押せない」は矩形だけでなくhitTestableと実タップで見る。
  testWidgets('320x690 オフラインでも文字盤のキーは44px以上で押せる（L-155）', (tester) async {
    await harness.pumpOffline(tester, const Size(320, 690));
    expect(harness.container.read(networkProvider), NetworkState.offline);

    final viewport = tester.getRect(find.byType(GridView));
    for (final label in boardKeys) {
      final rect = tester.getRect(boardCell(label));
      expect(rect.width, greaterThanOrEqualTo(AppSizes.minTapTarget),
          reason: '「$label」のキーが$rect（幅が44px未満）');
      expect(rect.height, greaterThanOrEqualTo(AppSizes.minTapTarget),
          reason: '「$label」のキーが$rect（高さが44px未満）');
      expect(encloses(viewport, rect), isTrue,
          reason: '「$label」のキー$rectが文字盤の表示域$viewportの外にある');
      expect(boardCell(label).hitTestable(), findsOneWidget,
          reason: '「$label」のキーがタップを受け取れない');
    }

    // 押せることは矩形では分からない。実際に叩いて入力が増えるか。
    await tester.tap(boardCell('こ'));
    await tester.pumpAndSettle();
    tester.takeException();
    expect(harness.container.read(inputBufferProvider), hasLength(1000));
    expect(harness.container.read(inputBufferProvider).endsWith('こ'), isTrue);
  });

  // リスク「緊急ボタンの誤発報」: 緊急ボタンは専用の帯で領域を確保して
  // いるので、画面本体・文字盤・オフライン告知のどれとも重ならない。
  for (final height in [690.0, 844.0]) {
    testWidgets('320x${height.toInt()} オフラインで緊急ボタンが誤発報しない（L-155）',
        (tester) async {
      await harness.pumpOffline(tester, Size(320, height));
      final emergency =
          tester.getRect(find.byType(EmergencyButtonWithConfirmation));
      expect(
          emergency.width, greaterThanOrEqualTo(AppSizes.recommendedTapTarget));
      expect(emergency.height,
          greaterThanOrEqualTo(AppSizes.recommendedTapTarget));
      for (final other in [
        find.byType(HomeScreen),
        find.byType(CharacterBoardWidget),
        find.byType(OfflineBanner),
      ]) {
        final rect = tester.getRect(other);
        expect(emergency.overlaps(rect), isFalse,
            reason: '緊急ボタン$emergencyが$other（$rect）と重なっている');
      }
      expect(find.byType(EmergencyButtonWithConfirmation).hitTestable(),
          findsOneWidget);
    });
  }

  // 2ペインをやめる条件は「右ペインに文字盤を置けるか」。幅が足りていれば
  // 可視高さが乏しくても2ペインのまま（横持ちスマホで文字盤の同時可視行を
  // 失わない）。内部幅の境界は
  // (W - paddingXSmall) * 3/5 >= CharacterBoardWidget.minLayoutWidth + 2*8
  // → W >= 477.34 なので、478 で2ペイン・477 で縦積みに分かれる。
  // AppShellは横持ちで右に92pxの緊急サイドレールを取るため外側幅は +92。
  for (final scale in [1.0, 2.0]) {
    for (final bodyWidth in [478.0, 477.0]) {
      final twoPane = bodyWidth >= 478;
      testWidgets(
          '横持ち 内部幅${bodyWidth.toInt()}・OS$scale倍は'
          '${twoPane ? '2ペインを保つ' : '縦積みへ落ちる'}（L-155）', (tester) async {
        await harness.pumpOffline(
            tester, Size(bodyWidth + AppSizes.emergencyButtonBarThickness, 375),
            scale: scale);

        final home = tester.getRect(find.byType(HomeScreen));
        final body = home.bottom - tester.getRect(find.byType(AppBar)).bottom;
        expect(home.width, closeTo(bodyWidth, 0.01), reason: '内部幅の前提が違う');

        final board = tester.getRect(find.byType(CharacterBoardWidget));
        if (twoPane) {
          expect(board.left, greaterThan(home.left + home.width / 3),
              reason: '文字盤$boardが右ペインに置かれていない（縦積みに落ちている）');
          expect(board.height, closeTo(body, 0.5),
              reason: '文字盤$boardが可視高さ$bodyを使い切っていない');
          expect(board.width,
              greaterThanOrEqualTo(CharacterBoardWidget.minLayoutWidth),
              reason: '右ペインが文字盤の最小幅を下回っている');
        } else {
          expect(board.left, closeTo(home.left + AppSizes.paddingSmall, 0.01),
              reason: '文字盤$boardが全幅に置かれていない（2ペインのまま）');
          expect(board.height, lessThan(body),
              reason: '縦積みなら操作域のぶん文字盤は可視高さより低い');
        }
        // 2ペインは可視高さを全部使うので あ〜こ の2行が出る。縦積みは
        // 文字盤の予約ぶんしか無く、低い横持ちでは1行しか出ないことがある
        // （行数はL-155の観測点ではない）ので先頭キーだけを見る。
        for (final label in twoPane ? boardKeys : ['あ']) {
          final rect = tester.getRect(boardCell(label));
          expect(rect.width, greaterThanOrEqualTo(AppSizes.minTapTarget),
              reason: '「$label」のキーが$rect（幅が44px未満）');
          expect(rect.height, greaterThanOrEqualTo(AppSizes.minTapTarget),
              reason: '「$label」のキーが$rect（高さが44px未満）');
          expect(boardCell(label).hitTestable(), findsOneWidget,
              reason: '「$label」のキーがタップを受け取れない');
        }
      });
    }
  }

  // 実在端末（iPhone SE/8 横持ち 667x375 = 内部幅575）では2ペインのまま。
  testWidgets('667x375 横持ち・OS1.0倍のオフラインで2ペインを保つ（L-155）', (tester) async {
    await harness.pumpOffline(tester, const Size(667, 375), scale: 1.0);
    final home = tester.getRect(find.byType(HomeScreen));
    final body = home.bottom - tester.getRect(find.byType(AppBar)).bottom;
    final board = tester.getRect(find.byType(CharacterBoardWidget));
    expect(board.left, greaterThan(home.left + home.width / 3),
        reason: '文字盤$boardが右ペインに置かれていない（縦積みに落ちている）');
    expect(board.height, closeTo(body, 0.5),
        reason: '文字盤$boardが可視高さ$bodyを使い切っていない');
    for (final label in boardKeys) {
      expect(tester.getRect(boardCell(label)).width,
          greaterThanOrEqualTo(AppSizes.minTapTarget));
      expect(boardCell(label).hitTestable(), findsOneWidget);
    }
  });

  // 可視高さが文字盤の予約分（200px）より低い画面（320x400・OS2.0では
  // 可視高さ156px）。ここで保証するのは「負の制約を作らない」ことだけで
  // 44pxの行が入ることは主張しない（台帳 L-172）。
  // 負の制約はConstrainedBoxのassertでbuild時に投げるため、操作域は
  // ErrorWidgetに置き換わる。矩形が測れること自体が観測点になる。
  testWidgets('320x400 オフライン: 文字盤の予約高さを下回ってもHomeが壊れない', (tester) async {
    await harness.pumpOffline(tester, const Size(320, 400));
    final home = tester.getRect(find.byType(HomeScreen));
    for (final part in [
      find.byType(CharacterBoardWidget),
      find.byKey(const ValueKey('home-controls-scroll')),
    ]) {
      expect(part, findsOneWidget);
      final rect = tester.getRect(part);
      expect(rect.width, greaterThanOrEqualTo(0), reason: '$part: $rect が負');
      expect(rect.height, greaterThanOrEqualTo(0), reason: '$part: $rect が負');
      expect(encloses(home, rect), isTrue,
          reason: '$part: $rect が画面本体$homeの外にある');
    }
  });
}
