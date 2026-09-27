/// 電話を横にしてキーボードを出しても、ホームがはみ出さない
///
/// 横向きの電話は左右 2 ペイン。キーボードが出ると本文の高さが大きく削られ、
/// 右ペインの文字盤が縦にはみ出していた（Android 915×412、キーボード 250 で 10px）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/widgets/app_shell.dart';
import 'package:kotonoha_app/features/character_board/presentation/home_screen.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/home_input_field.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final (name, size, top, keyboard, scale, fontSize) in [
    ('Android 915×412', const Size(915, 412), 24.0, 250.0, 1.0, 'medium'),
    ('iPhone 844×390', const Size(844, 390), 0.0, 210.0, 1.0, 'medium'),
    (
      'Android 915×412・文字大・OS 2 倍',
      const Size(915, 412),
      24.0,
      250.0,
      2.0,
      'large'
    ),
  ]) {
    testWidgets('$name で入力欄を押してキーボードが出ても、はみ出さない', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      tester.view.padding = FakeViewPadding(top: top);
      tester.view.viewPadding = FakeViewPadding(top: top);
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues(
          {'tutorial_completed': true, 'fontSize': fontSize});

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: AppShell(child: HomeScreen())),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'キーボードを出す前からはみ出している');

      await tester.tap(find.descendant(
        of: find.byType(HomeInputField),
        matching: find.byType(EditableText),
      ));
      await tester.pumpAndSettle();
      tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'キーボードを出すとはみ出す');
    });
  }
}
