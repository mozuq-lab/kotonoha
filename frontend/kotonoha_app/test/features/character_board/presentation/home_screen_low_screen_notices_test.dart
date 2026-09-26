/// 低い画面でのオフライン告知の表示 ウィジェットテスト（台帳 L-156）
/// 対象
///   lib/features/network/presentation/widgets/offline_banner.dart
///   lib/features/network/presentation/widgets/online_recovery_notification.dart
///   lib/features/ai_conversion/presentation/widgets/ai_conversion_button.dart
/// 条件: 実AppShell・フォント設定「大」・OSの文字拡大・幅320（と2ペインの
/// 左ペイン）。告知のRowが横にはみ出して文言の後半が読めなくなる形を
/// 「読めるか」で見る。文字盤のキー（L-155）は別ファイル
/// home_screen_low_screen_board_test.dart の観測点。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/features/ai_conversion/presentation/widgets/ai_conversion_button.dart';
import 'package:kotonoha_app/features/character_board/presentation/home_screen.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/character_board_widget.dart';
import 'package:kotonoha_app/features/character_board/providers/input_buffer_provider.dart';
import 'package:kotonoha_app/features/network/presentation/widgets/offline_banner.dart';
import 'package:kotonoha_app/features/network/providers/network_provider.dart';

import 'home_layout_test_support.dart';

void main() {
  final harness = HomeLayoutHarness.install();

  /// 画面いっぱいの矩形（物理サイズ＝DPR1の論理サイズ）
  Rect screenOf(WidgetTester tester) => Offset.zero & tester.view.physicalSize;

  /// AI変換ボタン脇の告知が、自分の箱の中で全文読めること。
  /// スクロールする操作域の中にあるため縦位置は利用者のスクロール次第で
  /// L-156は横方向のはみ出しなので、横方向が画面内であることも見る。
  void expectIndicatorReadable(WidgetTester tester, Rect screen) {
    final indicator = find.byType(OfflineIndicator);
    expect(indicator, findsOneWidget);
    final box = tester.getRect(indicator);
    expect(box.left, greaterThanOrEqualTo(screen.left - 0.01),
        reason: 'AI変換脇の告知$boxが画面$screenの左外にある');
    expect(box.right, lessThanOrEqualTo(screen.right + 0.01),
        reason: 'AI変換脇の告知$boxが画面$screenの右外にある');
    expectNoticeReadable(
        tester,
        find.descendant(
            of: indicator, matching: find.text(offlineIndicatorText)),
        box,
        'AI変換脇の告知');
  }

  // L-156: 幅320のオフライン表示で、告知のRowが横にはみ出していた
  // （AppShellの高さ844/690でoffline_bannerのRowが右247px）。
  // リスク「offline状態を読めない」を、折り返しを含めて見る。
  for (final height in [844.0, 690.0]) {
    testWidgets('320x${height.toInt()} オフラインの告知が切れず全文読める（L-156）',
        (tester) async {
      final exception = await harness.pumpOffline(tester, Size(320, height));
      expect(exception, isNull, reason: 'レイアウト例外が出ている: $exception');

      final screen = screenOf(tester);
      final banner = find.text(offlineBannerText);
      expect(banner, findsOneWidget);
      expect(encloses(screen, tester.getRect(banner)), isTrue,
          reason: 'バナーの文言${tester.getRect(banner)}が画面$screenの外にある');
      expectNoticeReadable(
          tester, banner, tester.getRect(find.byType(OfflineBanner)), 'バナー');
      // 幅320・OS2.0では2行になる。2行目だけ左に寄らないこと。
      expectLinesCentered(tester, banner, 'バナー');

      expectIndicatorReadable(tester, screen);
    });
  }

  // 入力が上限に達すると InputLimitNotice が増えて再レイアウトされる。
  // その描画フレームでも告知が横にはみ出さないこと。
  testWidgets('320x690 オフラインで入力上限の告知が増えても例外が出ない（L-156）', (tester) async {
    final exception = await harness.pumpOffline(tester, const Size(320, 690));
    expect(exception, isNull, reason: 'レイアウト例外が出ている: $exception');
    await tester.tap(boardCell('こ'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'タップ後にレイアウト例外が出ている');
    expect(harness.container.read(inputBufferProvider), hasLength(1000));
    expectIndicatorReadable(tester, screenOf(tester));
  });

  // 告知を折り返すとオフラインバナーが56→96pxに増え、可視高さがその分
  // 下がる。320x568（iPhone SE 初代の縦持ち。可視高324）でも文字盤は
  // 全幅の縦積みのままで、セルが2ペインの25.12pxに痩せないこと
  // （バナーを2行にしたこのbranchでだけ到達する組み合わせ。台帳 L-155）。
  testWidgets('320x568 オフライン・バナー2行でも文字盤は縦積みのまま（L-155/L-156）', (tester) async {
    final exception = await harness.pumpOffline(tester, const Size(320, 568));
    expect(exception, isNull, reason: 'レイアウト例外が出ている: $exception');
    final banner = tester.getRect(find.byType(OfflineBanner));
    expect(banner.height, greaterThan(56),
        reason: '前提: バナーが2行（56pxを超える）になっていない: $banner');

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
    expect(find.text('上へ'), findsOneWidget);
    expect(find.text('下へ'), findsOneWidget);
  });

  // 2ペインの左ペインは幅が乏しく、境界付近（内部幅478）でOSの文字拡大を
  // 併用すると OfflineIndicator のRowが右へ71pxはみ出していた。
  testWidgets('横持ち 内部幅478・OS2.0倍の左ペインでも告知が切れない（L-156）', (tester) async {
    final exception = await harness.pumpOffline(tester, const Size(478, 375));
    expect(exception, isNull, reason: 'レイアウト例外が出ている: $exception');
    expectIndicatorReadable(tester, screenOf(tester));
  });

  // オフラインからオンラインに戻したフレームで、復帰の緑帯が右へはみ出して
  // 文言が切れていた（実Chromiumで右51px。fontSizeは14固定なのでアプリの
  // フォント設定に依らず幅320では常に起きる）。
  for (final height in [844.0, 690.0]) {
    testWidgets('320x${height.toInt()} オンライン復帰の告知が切れず全文読める（L-156同型）',
        (tester) async {
      final exception =
          await harness.pumpOffline(tester, Size(320, height), scale: 1.0);
      expect(exception, isNull, reason: 'レイアウト例外が出ている: $exception');
      await harness.container.read(networkProvider.notifier).setOnline();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '復帰フレームでレイアウト例外');

      final notice = find.text(onlineRecoveryText);
      expect(notice, findsOneWidget);
      final band =
          find.ancestor(of: notice, matching: find.byType(Material)).first;
      final screen = screenOf(tester);
      expect(encloses(screen, tester.getRect(notice)), isTrue,
          reason: '復帰の文言${tester.getRect(notice)}が画面$screenの外にある');
      expectNoticeReadable(tester, notice, tester.getRect(band), '復帰の告知');
      // 幅320では1行に収まらず折り返すので、2行目の揃えまで見る。
      expectLinesCentered(tester, notice, '復帰の告知');

      // 自動で消える動きは変えていない（タイマーを残さず片付ける）。
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(notice, findsNothing);
    });
  }
}
