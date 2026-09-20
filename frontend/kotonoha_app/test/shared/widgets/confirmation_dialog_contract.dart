/// 誤操作防止ダイアログが満たすべき並びの契約（台帳 L-130・L-131）
///
/// REQ-5002 は緊急呼び出し・全消去などを「誤操作防止の対象」として並べている。
/// これらのダイアログは**取り消し**と**取り消せない実行**を並べるので、
/// 2 つが接していたり、説明文が画面から消えていたりすると、そのまま誤操作になる。
/// 利用者は発話で訂正できず、消した入力は打ち直せない。
///
/// 契約は 4 つ。
///   1. 取り消しと実行が 16px 以上離れている（`app_shell.dart` と同じ基準）
///   2. 並び方が定まっている（横並びなら「取り消し」が左、縦積みなら上）
///   3. どちらもタップ目標 44px 以上（REQ-3001）
///   4. 文字が大きくなっても内容が画面からあふれない（`scrollable`）
///
/// `AlertDialog` の既定は**横 8px・縦 0px**なので、何も指定しないとこの契約を
/// 満たさない。幅が足りないと actions は縦積みに切り替わり（`OverflowBar`）、
/// 縦の既定 0 がそのまま 2 つのボタンの間隔になる。**細いボタンでも、文字設定
/// 「大」と OS の文字拡大が重なれば縦積みに入る**（2026-09-20 実測。定型文の削除は
/// 幅 375・倍率 2.0 で 0.0px、全消去は幅 320・倍率 2.4 で 0.0px）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/themes/light_theme.dart';

/// 誤発報・誤削除を防ぐための下限。`app_shell.dart` の「他の操作ボタンとの
/// 間隔 16px 以上」。実装側の `AppSizes.paddingMedium` は**参照しない**
/// （参照すると、定数を動かしたときに合格下限まで一緒に動いて検査が空になる）
const double minGap = 16.0;

/// タップ目標の下限（REQ-3001）。同じ理由で `AppSizes.minTapTarget` は参照しない
const double minTapTarget = 44.0;

/// 変換行列を通った double の比較に許す誤差（44.0 が 43.99999999999994 になる）
const double epsilon = 0.01;

/// 契約を当てる画面幅。320〜375 はスマホ縦持ち、768 はタブレット
const widths = [320.0, 360.0, 375.0, 768.0];

/// 契約を当てる文字倍率。2.4 は設定「大」(1.2) と OS の拡大 (2.0) が重なった形
const scales = [1.0, 1.3, 2.0, 2.4];

/// ラベルから確認ダイアログのボタンを探す。
/// **見た目の型（`TextButton` / `ElevatedButton`）に依存しない。** 型で探すと、
/// 実行ボタンの見せ方を変えただけでテストが落ち、逆に「ボタンがある」ことを
/// 型でしか主張できなくなる
Finder confirmationButton(String label) => find.ancestor(
      of: find.text(label),
      matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
    );

/// 取り消しから見た実行の並び
enum Placement { column, row, none }

({Placement placement, double gap}) placementOf(Rect cancel, Rect confirm) {
  final horizontal = confirm.left - cancel.right;
  final vertical = confirm.top - cancel.bottom;
  if (horizontal > 0 &&
      confirm.top < cancel.bottom &&
      confirm.bottom > cancel.top) {
    return (placement: Placement.row, gap: horizontal);
  }
  if (vertical > 0 &&
      confirm.left < cancel.right &&
      confirm.right > cancel.left) {
    return (placement: Placement.column, gap: vertical);
  }
  // 接している・重なっている・逆順・斜め — いずれも「離れている」とは言えない
  return (placement: Placement.none, gap: 0);
}

/// [open] で開いたダイアログが、全ての幅・倍率で契約を満たすことを確かめる
void expectMeetsContract(
  String name, {
  required Widget Function(BuildContext context) dialog,
  required String cancelLabel,
  required String confirmLabel,
}) {
  for (final width in widths) {
    for (final scale in scales) {
      testWidgets('$name: 幅 $width・文字倍率 $scale で契約を満たす', (tester) async {
        final screen = Size(width, 640);
        tester.view.physicalSize = screen;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            theme: lightTheme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: dialog,
                  ),
                  child: const Text('開く'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('開く'));
        await tester.pumpAndSettle();

        // 4. あふれない（説明文が画面の外へ出て読めなくならない）
        expect(tester.takeException(), isNull,
            reason: '$name が幅 $width・倍率 $scale であふれた');

        Rect rectOf(String label) =>
            tester.getRect(confirmationButton(label).first);
        final cancel = rectOf(cancelLabel);
        final confirm = rectOf(confirmLabel);
        final layout = placementOf(cancel, confirm);
        final where = '取り消し=$cancel 実行=$confirm';

        // 2. 並び方が定まっている（逆順・斜め・接触はここで落ちる）
        expect(layout.placement, isNot(Placement.none),
            reason: '$name: 取り消しと実行が接している／並んでいない。$where');

        // 1. 16px 以上離れている
        expect(layout.gap, greaterThanOrEqualTo(minGap - epsilon),
            reason: '$name: 取り消しと実行が近すぎる（誤操作になる）。$where');

        // 3. タップ目標。**この 1 本はダイアログ側のコードでは赤にならない。**
        // アプリのテーマの `minimumSize`（`light_theme.dart`）と Material の
        // `MaterialTapTargetSize.padded` が二重に保証しているため。
        // 両方を外すと 40.0 で赤になることは確かめた（2026-09-20）。
        // その保証が外れたときに落ちる見張りとして置く
        for (final (label, rect) in [
          (cancelLabel, cancel),
          (confirmLabel, confirm),
        ]) {
          expect(rect.height, greaterThanOrEqualTo(minTapTarget - epsilon),
              reason: '$name: 「$label」の高さが足りない');
          expect(rect.width, greaterThanOrEqualTo(minTapTarget - epsilon),
              reason: '$name: 「$label」の幅が足りない');
        }

        // どちらのボタンも押せる（あふれてクリップされていない）
        for (final label in [cancelLabel, confirmLabel]) {
          expect(confirmationButton(label).hitTestable(), findsWidgets,
              reason: '$name: 「$label」が押せない');
        }
      });
    }
  }
}
