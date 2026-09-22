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
    expectOnlyKnownOverflow(harness);
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
    // 1000文字に達するとInputLimitNoticeが増えて再レイアウトされるので
    // そのフレームの例外も、既知の横overflow以外は赤にする。
    await tester.tap(boardCell('こ'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), anyOf(isNull, isKnownHorizontalOverflow),
        reason: 'タップ後に既知の横overflow以外の例外が出ている');
    expect(harness.container.read(inputBufferProvider), hasLength(1000));
    expect(harness.container.read(inputBufferProvider).endsWith('こ'), isTrue);
  });

  // リスク「緊急ボタンの誤発報」: 緊急ボタンは専用の帯で領域を確保して
  // いるので、画面本体・文字盤・オフライン告知のどれとも重ならない。
  for (final height in [690.0, 844.0]) {
    testWidgets('320x${height.toInt()} オフラインで緊急ボタンが誤発報しない（L-155）',
        (tester) async {
      await harness.pumpOffline(tester, Size(320, height));
      expectOnlyKnownOverflow(harness);
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

  // 2ペインをやめる条件は幅だけで決まる（可視高さは見ない。低いことを
  // 理由に2ペインへ戻すと幅320でセル25.12pxを選んでしまう）。内部幅の境界は
  // (W - paddingXSmall) * 3/5 >= minLayoutWidth + 2*8 - 1（1pxの丸め許容）
  // → W >= 475.67 なので、476 で2ペイン・475 で縦積みに分かれる。
  // 縦向きなので緊急帯は画面下（サイドレールではない）＝外側幅＝内部幅。
  for (final scale in [1.0, 2.0]) {
    for (final bodyWidth in [476.0, 475.0]) {
      final twoPane = bodyWidth >= 476;
      testWidgets(
          '縦向き 内部幅${bodyWidth.toInt()}・OS$scale倍は'
          '${twoPane ? '2ペインを保つ' : '縦積みへ落ちる'}（L-155）', (tester) async {
        await harness.pumpOffline(tester, Size(bodyWidth, 660), scale: scale);
        expectOnlyKnownOverflow(harness);

        final home = tester.getRect(find.byType(HomeScreen));
        final body = home.bottom - tester.getRect(find.byType(AppBar)).bottom;
        expect(home.width, closeTo(bodyWidth, 0.01), reason: '内部幅の前提が違う');
        expect(body, lessThan(AppSizes.compactHeightThreshold),
            reason: '前提: 可視高さ$bodyがcompactの帯に入っていない');
        expect(body, greaterThanOrEqualTo(400),
            reason: '前提: 可視高さ$bodyでは縦積みの文字盤が200pxに届かない');

        final board = tester.getRect(find.byType(CharacterBoardWidget));
        if (twoPane) {
          expect(board.left, greaterThan(home.left + home.width / 3),
              reason: '文字盤$boardが右ペインに置かれていない（縦積みに落ちている）');
          expect(board.height, closeTo(body, 0.5),
              reason: '文字盤$boardが可視高さ$bodyを使い切っていない');
          // 1pxの丸め許容ぶんだけ最小幅を下回りうる（セルは43.9px台）。
          expect(board.width,
              greaterThanOrEqualTo(CharacterBoardWidget.minLayoutWidth - 1),
              reason: '右ペインが文字盤の最小幅を1px以上下回っている');
        } else {
          expect(board.left, closeTo(home.left + AppSizes.paddingSmall, 0.01),
              reason: '文字盤$boardが全幅に置かれていない（2ペインのまま）');
          expect(board.height, lessThan(body),
              reason: '縦積みなら操作域のぶん文字盤は可視高さより低い');
        }
        // どちらのレイアウトでも あ〜こ の2行が出る高さを選んでいる
        // （2ペインは可視高さ全部、縦積みは予約の200px）。2ペイン側の幅は
        // 1pxの丸め許容ぶん44pxを0.2pxまで下回りうる。
        final minCellWidth =
            twoPane ? AppSizes.minTapTarget - 0.3 : AppSizes.minTapTarget;
        for (final label in boardKeys) {
          final rect = tester.getRect(boardCell(label));
          expect(rect.width, greaterThanOrEqualTo(minCellWidth),
              reason: '「$label」のキーが$rect（幅が$minCellWidth未満）');
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
    expectOnlyKnownOverflow(harness);
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

  // 幅320は可視高さがどれだけ低くても縦積み。2ペインにすると右ペインが
  // 189pxで五十音の5列が25.12pxまで痩せる（L-155そのもの）。告知を
  // 折り返すとバナーが56→96pxに増えるので、その40pxを帯で足した
  // 320x568（iPhone SE 初代の縦持ち）でも縦積みであること。可視高は
  // このbranch単独では324、折り返しを積んだ状態では284（厳しい側）。
  testWidgets('320x568・バナー2行ぶんを足した低い画面でも縦積み（L-155）', (tester) async {
    await harness.pumpOffline(tester, const Size(320, 568), extraChrome: 40);
    expectOnlyKnownOverflow(harness);
    final home = tester.getRect(find.byType(HomeScreen));
    final board = tester.getRect(find.byType(CharacterBoardWidget));
    expect(board.left, closeTo(home.left + AppSizes.paddingSmall, 0.01),
        reason: '文字盤$boardが全幅に置かれていない（2ペインに落ちている）');
    final key = tester.getRect(boardCell('あ'));
    expect(key.width, greaterThanOrEqualTo(AppSizes.minTapTarget),
        reason: '「あ」のキーが$key（2ペインなら25.12pxまで痩せる）');
    expect(key.height, greaterThanOrEqualTo(AppSizes.minTapTarget),
        reason: '「あ」のキーが$key（高さが44px未満）');
    expect(boardCell('あ').hitTestable(), findsOneWidget);
    // 縦積みなら操作群へタップで到達できる（2ペインには上下ボタンが無い）。
    expect(find.text('上へ'), findsOneWidget);
    expect(find.text('下へ'), findsOneWidget);
  });

  // 569x375（内部幅477・右ペイン283.8px）は、右ペインの幅が最小幅を
  // 0.2px下回るだけ。縦積みにすると文字盤は85pxしか無く2行目のセルが
  // 25pxに切れる（実Chromium）ので、1pxの丸め許容で2ペインを保つ。
  // 2ペインのセル幅は43.96pxで44pxを0.2pxだけ下回る（44px未満ではあるが
  // 縦積みの25pxより良い。台帳 L-155）。
  testWidgets('569x375 横持ち・右ペインが1px足りないだけなら2ペインを保つ（L-155）', (tester) async {
    await harness.pumpOffline(tester, const Size(569, 375), scale: 1.0);
    expectOnlyKnownOverflow(harness);
    final home = tester.getRect(find.byType(HomeScreen));
    final body = home.bottom - tester.getRect(find.byType(AppBar)).bottom;
    final board = tester.getRect(find.byType(CharacterBoardWidget));
    expect(board.left, greaterThan(home.left + home.width / 3),
        reason: '文字盤$boardが右ペインに置かれていない（縦積みに落ちている）');
    expect(board.height, closeTo(body, 0.5),
        reason: '文字盤$boardが可視高さ$bodyを使い切っていない');
    final key = tester.getRect(boardCell('あ'));
    expect(key.width, greaterThanOrEqualTo(43),
        reason: '「あ」のキーが$key（縦積みだと2行目は25pxに切れる）');
    expect(key.height, greaterThanOrEqualTo(AppSizes.minTapTarget),
        reason: '「あ」のキーが$key（高さが44px未満）');
    expect(boardCell('あ').hitTestable(), findsOneWidget);
  });

  // 可視高さが文字盤の予約（200px）を大きく下回る画面（320x400・OS2.0では
  // 156px → 縦積みの盤は78px）。44pxの行は入らない領域なので寸法は主張せず
  // 壊れないことだけを見る（台帳 L-172）。幅が足りなくても2ペインには
  // 戻さない（戻すとセル25.12px）。負の制約（NOT NORMALIZED）は
  // expectOnlyKnownOverflow が赤にする。
  testWidgets('320x400 オフライン: 予約を下回る可視高さでもHomeが壊れない', (tester) async {
    await harness.pumpOffline(tester, const Size(320, 400));
    expectOnlyKnownOverflow(harness);
    final home = tester.getRect(find.byType(HomeScreen));
    final board = find.byType(CharacterBoardWidget);
    expect(board, findsOneWidget);
    final rect = tester.getRect(board);
    expect(rect.width, greaterThanOrEqualTo(0), reason: '文字盤$rectの幅が負');
    expect(rect.height, greaterThanOrEqualTo(0), reason: '文字盤$rectの高さが負');
    expect(encloses(home, rect), isTrue, reason: '文字盤$rectが画面本体$homeの外にある');
  });
}
