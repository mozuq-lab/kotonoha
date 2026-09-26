/// 誤操作防止ダイアログが満たすべき並びの契約（台帳 L-130・L-131）
///
/// 仕様は全消去などを「誤操作防止の対象」としている。
/// これらのダイアログは**取り消し**と**取り消せない実行**を並べるので、
/// 2 つが接していたり、説明文が画面から消えていたりすると、そのまま誤操作になる。
/// 利用者は発話で訂正できず、消した入力は打ち直せない。
///
/// 契約は 4 つ。
///   1. 取り消しと実行が 16px 以上離れている（`app_shell.dart` と同じ基準）
///   2. 並び方が定まっている（横並びなら「取り消し」が左、縦積みなら上）
///   3. どちらもタップ目標 44px 以上
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

/// タップ目標の下限。同じ理由で `AppSizes.minTapTarget` は参照しない
const double minTapTarget = 44.0;

/// 変換行列を通った double の比較に許す誤差（44.0 が 43.99999999999994 になる）
const double epsilon = 0.01;

/// 契約を当てる画面幅。320〜375 はスマホ縦持ち、768 はタブレット
const widths = [320.0, 360.0, 375.0, 768.0];

/// 契約を当てる文字倍率。2.4 は設定「大」(1.2) と OS の拡大 (2.0) が重なった形
const scales = [1.0, 1.3, 2.0, 2.4];

/// ソフトキーボードが押し上げる高さ。
/// **本文に `TextField` があるダイアログだけに当てる**（`withKeyboard`）。
/// 0 だけだと `scrollable` が効く場面を一度も見ない（キーボードが出ると
/// 幅 320・倍率 2.0 で 16px、倍率 2.4 で 42px あふれる。2026-09-20 実測）。
/// 文字盤はアプリ内のキーボードなので `viewInsets` は立たず、ほかの経路に
/// 当てると入口のボタンが画面の外へ出てタップできなくなるだけ
const softKeyboardInset = 340.0;

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

/// ダイアログが全ての幅・倍率で契約を満たすことを確かめる
///
/// [home] には**本番の画面／ウィジェット**を渡し、[open] で**本番と同じ入口**を
/// タップして開く。テストの中で `ConfirmationDialog` を組み直すと、呼び出し元が
/// 素の `AlertDialog` に戻されても緑のまま通ってしまう（台帳 L-135）。
void expectMeetsContract(
  String name, {
  required Widget Function() home,
  required Future<void> Function(WidgetTester tester) open,
  required String cancelLabel,
  required String confirmLabel,

  /// `ProviderScope` など、`MaterialApp` の外に要る包みを足す
  Widget Function(Widget app)? scope,

  /// `pumpAndSettle` が返らない画面のための差し替え口
  /// （`HomeScreen` は永久に動くアニメーションを持つ）
  Future<void> Function(WidgetTester tester)? settle,

  /// 本文に `TextField` があるものは、キーボードが出た状態でも当てる
  bool withKeyboard = false,
}) {
  final insets = withKeyboard ? [0.0, softKeyboardInset] : [0.0];
  for (final width in widths) {
    for (final scale in scales) {
      for (final inset in insets) {
        final where = inset == 0
            ? '幅 $width・文字倍率 $scale'
            : '幅 $width・文字倍率 $scale・キーボード $inset';
        testWidgets('$name: $where で契約を満たす', (tester) async {
          tester.view.physicalSize = Size(width, 640);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          final app = MaterialApp(
            theme: lightTheme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                viewInsets: EdgeInsets.only(bottom: inset),
              ),
              child: child!,
            ),
            home: home(),
          );
          Future<void> waitForFrames() async {
            if (settle != null) return settle(tester);
            await tester.pumpAndSettle();
          }

          await tester.pumpWidget(scope == null ? app : scope(app));
          await waitForFrames();
          await open(tester);
          await waitForFrames();

          // 4. あふれない（本文が画面の外へ出て読めなくならない）
          expect(tester.takeException(), isNull,
              reason: '$name が $where であふれた');

          Rect rectOf(String label) =>
              tester.getRect(confirmationButton(label).first);
          final cancel = rectOf(cancelLabel);
          final confirm = rectOf(confirmLabel);
          final layout = placementOf(cancel, confirm);
          final at = '取り消し=$cancel 実行=$confirm';

          // 2. 並び方が定まっている（逆順・斜め・接触はここで落ちる）
          expect(layout.placement, isNot(Placement.none),
              reason: '$name: 取り消しと実行が接している／並んでいない。$at');

          // 1. 16px 以上離れている
          expect(layout.gap, greaterThanOrEqualTo(minGap - epsilon),
              reason: '$name: 取り消しと実行が近すぎる（誤操作になる）。$at');

          // 3. タップ目標。**この 1 本は `minimumSize` を変えても赤にならない。**
          // 実寸はテーマの `minimumSize` と `materialTapTargetSize` /
          // `visualDensity` で決まるため（2026-09-20 実測）。
          // `tapTargetSize: shrinkWrap` ＋ padding 0 にすると 48 本が赤になる。
          // **見ているのはテストの既定プラットフォーム（Android 相当）だけ**で、
          // デスクトップのブラウザでは `visualDensity` が効いて「いいえ」が
          // 36px になる（main からの既存の穴。台帳 L-134）
          for (final (label, rect) in [
            (cancelLabel, cancel),
            (confirmLabel, confirm),
          ]) {
            expect(rect.height, greaterThanOrEqualTo(minTapTarget - epsilon),
                reason: '$name: 「$label」の高さが足りない');
            expect(rect.width, greaterThanOrEqualTo(minTapTarget - epsilon),
                reason: '$name: 「$label」の幅が足りない');
          }

          // どちらのボタンも押せる（あふれてクリップされていない）。
          // `hitTestable()` が見るのは**ボタン中央の 1 点が Flutter の木の
          // hit test に出るか**だけで、キーボードに隠れているかは分からない
          // （キーボードは Flutter の外側にあり、遮蔽物としては存在しない）。
          // そこで、キーボードの上端より下に出ていないことを別に見る
          for (final label in [cancelLabel, confirmLabel]) {
            expect(confirmationButton(label).hitTestable(), findsWidgets,
                reason: '$name: 「$label」が押せない');
          }
          for (final (label, rect) in [
            (cancelLabel, cancel),
            (confirmLabel, confirm),
          ]) {
            expect(rect.bottom, lessThanOrEqualTo(640 - inset + epsilon),
                reason: '$name: 「$label」がキーボードの下に隠れる'
                    '（下端 ${rect.bottom} > ${640 - inset}）');
          }

          // 開いた直後のフレームで測っていないこと。遷移の途中でも寸法と
          // hit test は通り得るので、もう 1 フレーム進めて動かないことを見る
          final settled =
              tester.getRect(confirmationButton(confirmLabel).first);
          await tester.pump(const Duration(milliseconds: 300));
          expect(
              tester.getRect(confirmationButton(confirmLabel).first), settled,
              reason: '$name: まだ動いている（遷移の途中で測っている）');
        });
      }
    }
  }
}

/// ボタンに塗られた**解決済みの基底色**（`ButtonStyle` ではなく `Material.color`）
///
/// `style` を見ると、テーマ側で塗られている場合に `null` が返って
/// 「塗られていない」と誤読する。取り消しボタンを実行とまったく同じ色に
/// 塗っても `style` 比較は気づかなかった（2026-09-20 実測）。
/// **「描画結果そのもの」ではない**: `Material` はこの色のあとに surface tint・
/// ink・子の描画を重ねる。テーマ解決の結果を見る目的には足りるが、
/// 画面に出る最終的な画素とは別物。
Color? renderedButtonColor(WidgetTester tester, String label) {
  final material = find
      .descendant(
          of: confirmationButton(label), matching: find.byType(Material))
      .evaluate()
      .map((e) => e.widget as Material)
      .where((m) => m.color != null)
      .toList();
  return material.isEmpty ? null : material.first.color;
}

/// ボタンに**実際に描かれる**枠線。描かれないもの（`BorderStyle.none`、
/// 幅 0、透明）は `null` を返す。
///
/// `ButtonStyle.side` を直読みすると、この 3 つを見落とす。実際
/// `style: BorderStyle.none` を足しても「枠線あり」として緑のまま通った
/// （2026-09-20 実測）。テーマ側で付いた枠線も `style` からは見えない。
/// 描画に使われるのは `Material.shape` に解決されたあとの `side` なので、
/// そちらを読む。
BorderSide? paintedButtonSide(WidgetTester tester, String label) {
  final material = find
      .descendant(
          of: confirmationButton(label), matching: find.byType(Material))
      .evaluate()
      .map((e) => e.widget as Material)
      .where((m) => m.shape is OutlinedBorder)
      .toList();
  if (material.isEmpty) return null;
  final side = (material.first.shape! as OutlinedBorder).side;
  if (side.style != BorderStyle.solid) return null;
  if (side.width <= 0) return null;
  if (side.color.a == 0) return null;
  return side;
}
