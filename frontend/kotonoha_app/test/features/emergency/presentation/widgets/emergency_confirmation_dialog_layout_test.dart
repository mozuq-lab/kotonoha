/// 緊急確認ダイアログの「いいえ」「はい」が、どの画面幅でも離れていること（台帳 L-112）
///
/// このダイアログは取り消し（いいえ）と実行（はい）が並ぶ。実行すると周囲に警報音が
/// 鳴るので、**誤タップは誤発報**になり、利用者は声で取り消せない。
/// `AlertDialog` の actions は幅が足りないと縦積みに切り替わる（`OverflowBar`）。
/// そのとき縦の隙間は `actionsOverflowButtonSpacing` で決まり、既定は 0 だったため
/// 2 つのボタンが接していた（幅 360 で「いいえ」の下端 ＝「はい」の上端。2026-09-19 実測）。
/// 基準は `app_shell.dart` と同じ「他の操作ボタンとの間隔 16px 以上」。
///
/// 縦・横それぞれの隙間だけでなく、**どちらに並ぶか（折り返しの境界）** も見る。
/// 横の隙間は `buttonPadding.horizontal / 2` から来るので、これを縮めると
/// 折り返しの境界も一緒に動き、これまで横並びだった幅が縦積みに変わる。
/// 隙間の下限だけを見ていると、その入れ替わりを緑のまま通す。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/themes/light_theme.dart';
import 'package:kotonoha_app/features/emergency/presentation/widgets/emergency_button_with_confirmation.dart';
import 'package:kotonoha_app/features/emergency/presentation/widgets/emergency_confirmation_dialog.dart';

/// 誤発報を防ぐための下限。`app_shell.dart` の「他の操作ボタンとの間隔 16px 以上」。
/// 実装が使う `AppSizes.paddingMedium` は**参照しない**。参照すると、定数を 8 に
/// 変えたときに検査対象の隙間と合格下限が一緒に下がり、この検査が空になる。
const double _minGap = 16.0;

/// 横並びのときの隙間。この修正より前からの見た目で、変えない
const double _rowGap = 24.0;

/// タップ目標の下限（REQ-3001）。上と同じ理由で `AppSizes.minTapTarget` は参照しない
const double _minTapTarget = 44.0;

/// 変換行列を通った double の比較に許す誤差。
/// 画面幅と文字拡大の組み合わせによっては 44.0 が 43.99999999999994 になる
const double _epsilon = 0.01;

/// 「いいえ」から見た「はい」の並び方
enum _Placement {
  /// 縦積み（「いいえ」が上）
  column,

  /// 横並び（「いいえ」が左）
  row,

  /// 接している・重なっている・逆順・斜め — いずれも「離れている」とは言えない
  none,
}

/// 2 つの矩形の並び方と、その方向の隙間
({_Placement placement, double gap}) _layoutOf(Rect cancel, Rect confirm) {
  final horizontal = confirm.left - cancel.right;
  final vertical = confirm.top - cancel.bottom;
  // 片方の軸で離れていて、もう片方の軸では重なっている（＝並んでいる）ことを見る。
  // 斜めにずれただけの配置を「離れている」と数えない
  if (horizontal > 0 &&
      confirm.top < cancel.bottom &&
      confirm.bottom > cancel.top) {
    return (placement: _Placement.row, gap: horizontal);
  }
  if (vertical > 0 &&
      confirm.left < cancel.right &&
      confirm.right > cancel.left) {
    return (placement: _Placement.column, gap: vertical);
  }
  return (placement: _Placement.none, gap: 0);
}

void main() {
  /// 緊急ボタンから確認ダイアログを開く（本番と同じ経路）
  Future<void> openDialog(WidgetTester tester, {required double width}) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: Scaffold(
          body: Center(
            child: EmergencyButtonWithConfirmation(
              onEmergencyConfirmed: () {},
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(EmergencyButtonWithConfirmation));
    await tester.pumpAndSettle();
    expect(find.byType(EmergencyConfirmationDialog), findsOneWidget);
  }

  Rect buttonRect(WidgetTester tester, String label) => tester.getRect(
        find.ancestor(
          of: find.text(label),
          matching: find.byType(ElevatedButton),
        ),
      );

  // 320: 小さめのスマホ / 360・375: よくあるスマホ縦持ち / 376: 横並びに切り替わる
  // 境界（actions の必要幅 240 + 24 = 264 が、ダイアログ幅 - 余白 に収まる最小の幅）
  // / 768・1024: タブレット
  const expected = <({double width, _Placement placement})>[
    (width: 320.0, placement: _Placement.column),
    (width: 360.0, placement: _Placement.column),
    (width: 375.0, placement: _Placement.column),
    (width: 376.0, placement: _Placement.row),
    (width: 768.0, placement: _Placement.row),
    (width: 1024.0, placement: _Placement.row),
  ];

  for (final (:width, :placement) in expected) {
    testWidgets('画面幅 $width で「いいえ」と「はい」が ${placement.name} に離れている',
        (tester) async {
      await openDialog(tester, width: width);

      final cancel =
          buttonRect(tester, EmergencyConfirmationDialog.cancelLabel);
      final confirm =
          buttonRect(tester, EmergencyConfirmationDialog.confirmLabel);
      final layout = _layoutOf(cancel, confirm);
      final where = 'いいえ=$cancel はい=$confirm';

      // 並び方（折り返しの境界）。「いいえ」が先（上／左）であることも含む
      expect(layout.placement, placement,
          reason: '並び方が変わると、押し慣れた位置に別のボタンが来る。$where');

      // 誤タップで誤発報にならない隙間
      expect(layout.gap, greaterThanOrEqualTo(_minGap - _epsilon),
          reason: '取り消しと実行が近すぎる（誤タップで誤発報になる）。$where');

      // 横並びの見た目はこの修正の前から 24。縦積みを直すために横を変えていない
      if (placement == _Placement.row) {
        expect(layout.gap, closeTo(_rowGap, _epsilon), reason: where);
      }
    });
  }

  testWidgets('狭い画面でも、どちらのボタンもタップ目標を下回らない', (tester) async {
    await openDialog(tester, width: 320);

    for (final label in [
      EmergencyConfirmationDialog.cancelLabel,
      EmergencyConfirmationDialog.confirmLabel,
    ]) {
      final rect = buttonRect(tester, label);
      expect(rect.height, greaterThanOrEqualTo(_minTapTarget - _epsilon),
          reason: '「$label」の高さが足りない');
      expect(rect.width, greaterThanOrEqualTo(_minTapTarget - _epsilon),
          reason: '「$label」の幅が足りない');
    }
    expect(tester.takeException(), isNull);
  });
}
