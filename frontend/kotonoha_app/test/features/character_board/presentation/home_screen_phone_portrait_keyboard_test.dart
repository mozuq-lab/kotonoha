/// 電話を縦にしてキーボードで打つとき、読み上げボタンが押せる
///
/// 縦向きの電話では、キーボードが出ると入力欄の周りの操作部が小さな
/// スクロール領域（iPhone 17 で 134px、iPhone SE で 50px）に押し込まれ、
/// 読み上げボタンがその外に切れて押せなかった。打ち終えた人が次に押す
/// ボタンが見えないと、そこで止まってしまう。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/widgets/app_shell.dart';
import 'package:kotonoha_app/features/character_board/presentation/home_screen.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/home_input_field.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [finder] の中心を押したときに、その部品に届くか（切れて見えない・覆われて
/// いると届かない）
bool _tappable(WidgetTester tester, Finder finder) {
  final target = tester.renderObject(finder);
  return tester
      .hitTestOnBinding(tester.getRect(finder).center)
      .path
      .any((entry) => entry.target == target);
}

void main() {
  for (final (name, size, top, bottom, keyboard, scale) in [
    ('iPhone 17', const Size(402, 874), 62.0, 34.0, 336.0, 1.0),
    ('iPhone 17・OS 2 倍', const Size(402, 874), 62.0, 34.0, 336.0, 2.0),
    ('iPhone SE・OS 2 倍', const Size(375, 667), 20.0, 0.0, 260.0, 2.0),
    ('Android・OS 2 倍', const Size(412, 915), 24.0, 24.0, 300.0, 2.0),
  ]) {
    testWidgets('$name: キーボードで打つ間、打った文字が見え、読み上げボタンに届く', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      tester.view.padding = FakeViewPadding(top: top, bottom: bottom);
      tester.view.viewPadding = FakeViewPadding(top: top, bottom: bottom);
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({'tutorial_completed': true});

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: AppShell(child: HomeScreen())),
        ),
      );
      await tester.pumpAndSettle();

      final field = find.descendant(
        of: find.byType(HomeInputField),
        matching: find.byType(EditableText),
      );
      await tester.tap(field);
      await tester.pumpAndSettle();
      // キーボードが出る（下の安全領域は dart:ui が 0 にする）
      tester.view.padding = FakeViewPadding(top: top);
      tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
      await tester.pumpAndSettle();
      if (scale == 1.0) {
        // 全部が収まる大きさなら、キーボードが出たときに読み上げボタンも見える
        // （収まらないときは、入力欄が自分を見せる動きが優先される）
        expect(_tappable(tester, find.text('読み上げ')), isTrue,
            reason: 'キーボードが出たとき、読み上げボタンが見えず押せない');
      }

      await tester.enterText(field, 'すこしやすみたい');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.testTextInput.isVisible, isTrue, reason: 'キーボードが閉じた');
      // 打った文字は、読み上げる前に確かめられる
      expect(_tappable(tester, field), isTrue, reason: '打った文字が見えない');

      // 読み上げボタンは、見えていなければ「下へ」で届く
      // （文字 2 倍の電話では、入力欄と読み上げボタンの行の両方は収まらない）
      for (var i = 0; i < 10 && !_tappable(tester, find.text('読み上げ')); i++) {
        expect(find.text('下へ'), findsOneWidget, reason: '読み上げボタンが見えず、「下へ」も無い');
        await tester.tap(find.text('下へ'));
        await tester.pumpAndSettle();
      }
      expect(_tappable(tester, find.text('読み上げ')), isTrue,
          reason: '「下へ」を押しても読み上げボタンに届かない');
      if (scale == 1.0) {
        expect(find.text('下へ'), findsNothing,
            reason: '通常の文字の大きさでは、スクロールせずに全部見える');
      }

      // 上へ戻した位置は、そのまま保たれる（下端へ引き戻さない）
      await tester.ensureVisible(find.text('はい'));
      await tester.pumpAndSettle();
      expect(_tappable(tester, find.text('はい')), isTrue,
          reason: '上へ戻しても引き戻されて「はい」が押せない');
    });
  }
}
