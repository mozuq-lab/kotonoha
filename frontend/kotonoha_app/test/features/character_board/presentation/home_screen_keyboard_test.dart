/// ホームの入力欄を押してキーボードが出ても、キーボードが閉じない
///
/// iPad を横にして入力欄を押すと、キーボードの分だけ表示できる高さが縮む。
/// その高さで配置（縦積み／左右 2 ペイン）が切り替わると入力欄が作り直され、
/// 入力の対象から外れてキーボードが閉じていた。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/widgets/app_shell.dart';
import 'package:kotonoha_app/features/character_board/presentation/home_screen.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/home_input_field.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// iPad (A16) を横にしたときの画面（論理ピクセル）
const _ipadLandscape = Size(1180, 820);

/// 横向きの iPad のソフトウェアキーボードの高さの目安（予測変換の帯を含む）
const _keyboardHeight = 400.0;

void main() {
  testWidgets('iPad 横向きで入力欄を押してキーボードが出ても、入力欄は入力の対象のまま', (tester) async {
    tester.view.physicalSize = _ipadLandscape;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'tutorial_completed': true});

    // 本番と同じく AppShell の中に置く（AppShell がキーボードの高さを取り除くかも含めて見る）
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
    expect(tester.testTextInput.isVisible, isTrue, reason: '入力欄を押してもキーボードが出ない');

    // キーボードが出て、画面の下が塞がる
    tester.view.viewInsets = const FakeViewPadding(bottom: _keyboardHeight);
    await tester.pumpAndSettle();

    expect(field, findsOneWidget);
    expect(tester.widget<EditableText>(field).focusNode.hasFocus, isTrue,
        reason: 'キーボードが出たら入力欄が入力の対象から外れた');
    expect(tester.testTextInput.isVisible, isTrue, reason: 'キーボードが閉じた');
    // 配置を保ったまま、入力欄がキーボードの上に見えている
    expect(tester.getRect(field).bottom,
        lessThanOrEqualTo(_ipadLandscape.height - _keyboardHeight),
        reason: '入力欄がキーボードに隠れる');
  });
}
