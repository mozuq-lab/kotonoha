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
  // Android は修正前に 10px はみ出していた条件。iPhone は修正前から
  // はみ出さない（文字盤に残る高さが違う）が、同じ作りの横向きとして見張る。
  for (final (name, size, top, keyboard) in [
    ('Android 915×412', const Size(915, 412), 24.0, 250.0),
    ('iPhone 844×390', const Size(844, 390), 0.0, 210.0),
  ]) {
    testWidgets('$name で入力欄を押してキーボードが出ても、はみ出さない', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      tester.view.padding = FakeViewPadding(top: top);
      tester.view.viewPadding = FakeViewPadding(top: top);
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({'tutorial_completed': true});

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
