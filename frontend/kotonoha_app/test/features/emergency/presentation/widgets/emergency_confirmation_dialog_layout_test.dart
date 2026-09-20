/// 緊急確認ダイアログの「いいえ」「はい」が、どの画面幅でも離れていること（台帳 L-112）
///
/// このダイアログは取り消し（いいえ）と実行（はい）が並ぶ。実行すると周囲に警報音が
/// 鳴るので、**誤タップは誤発報**になり、利用者は声で取り消せない。
/// `AlertDialog` の actions は幅が足りないと縦積みに切り替わる（`OverflowBar`）。
/// そのとき `overflowSpacing` は `actionsOverflowButtonSpacing` 由来で既定は 0 で、
/// 横並び用に挟んだ `SizedBox(width:)` は縦では高さ 0 になるため、2 つのボタンが
/// 接していた（幅 360 で「いいえ」の下端 ＝「はい」の上端。2026-09-19 実測）。
/// 基準は `app_shell.dart` と同じ「他の操作ボタンとの間隔 16px 以上」。
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/core/themes/light_theme.dart';
import 'package:kotonoha_app/features/emergency/presentation/widgets/emergency_button_with_confirmation.dart';
import 'package:kotonoha_app/features/emergency/presentation/widgets/emergency_confirmation_dialog.dart';

/// 2 つの矩形の間隔（縦積みなら上下の隙間、横並びなら左右の隙間）
/// 重なっていれば 0 を返す。
double _gapBetween(Rect a, Rect b) {
  final horizontal = math.max(a.left - b.right, b.left - a.right);
  final vertical = math.max(a.top - b.bottom, b.top - a.bottom);
  return math.max(0.0, math.max(horizontal, vertical));
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

  // 320: 小さめのスマホ / 360・375: よくあるスマホ縦持ち（縦積みになる）
  // 376: 横並びに切り替わる境界 / 768・1024: タブレット
  for (final width in [320.0, 360.0, 375.0, 376.0, 768.0, 1024.0]) {
    testWidgets('画面幅 $width で「いいえ」と「はい」が 16px 以上離れている', (tester) async {
      await openDialog(tester, width: width);

      final cancel =
          buttonRect(tester, EmergencyConfirmationDialog.cancelLabel);
      final confirm =
          buttonRect(tester, EmergencyConfirmationDialog.confirmLabel);

      expect(
        _gapBetween(cancel, confirm),
        greaterThanOrEqualTo(AppSizes.paddingMedium),
        reason: '取り消しと実行が近すぎる（誤タップで誤発報になる）'
            '。いいえ=$cancel はい=$confirm',
      );
    });
  }

  testWidgets('狭い画面でも、どちらのボタンもタップ目標を下回らない', (tester) async {
    await openDialog(tester, width: 320);

    for (final label in [
      EmergencyConfirmationDialog.cancelLabel,
      EmergencyConfirmationDialog.confirmLabel,
    ]) {
      final rect = buttonRect(tester, label);
      expect(rect.height, greaterThanOrEqualTo(AppSizes.minTapTarget),
          reason: '「$label」の高さが足りない');
      expect(rect.width, greaterThanOrEqualTo(AppSizes.minTapTarget),
          reason: '「$label」の幅が足りない');
    }
    expect(tester.takeException(), isNull);
  });
}
