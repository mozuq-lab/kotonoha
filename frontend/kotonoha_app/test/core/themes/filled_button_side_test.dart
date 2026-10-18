/// 色で塗ったボタンの縁
///
/// テーマ既定の灰色の枠（白いボタンと背景の境目のためのもの）が、色で塗った
/// ボタンにも付き、灰色の縁に見えていた（iPad、2026-10-18）。塗ったボタンの縁は
/// 塗りと同じ色、白や淡い色のボタンは灰色の枠のまま、を描かれた縁で確かめる。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/themes/dark_theme.dart';
import 'package:kotonoha_app/core/themes/high_contrast_theme.dart';
import 'package:kotonoha_app/core/themes/light_theme.dart';
import 'package:kotonoha_app/features/tts/presentation/widgets/tts_button.dart';
import 'package:kotonoha_app/shared/widgets/confirmation_dialog.dart';

final Map<String, ThemeData> _themes = {
  'ライト': lightTheme,
  'ダーク': darkTheme,
  '高コントラスト': highContrastTheme,
};

/// [label] のボタンが描いている塗りと縁
({Color fill, Color border}) _painted(WidgetTester tester, String label) {
  final button = find.ancestor(
    of: find.text(label),
    matching: find.bySubtype<ButtonStyleButton>(),
  );
  final material = tester.widget<Material>(
    find.descendant(of: button, matching: find.byType(Material)).first,
  );
  final shape = material.shape! as OutlinedBorder;
  return (fill: material.color!, border: shape.side.color);
}

void main() {
  for (final entry in _themes.entries) {
    final theme = entry.value;

    testWidgets('${entry.key}: 基本色で塗った「読み上げ」の縁は塗りと同じ色', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: theme,
            home: Scaffold(
              body: TTSButton(
                text: 'こんにちは',
                onSpeak: () {},
                // ホームと同じ渡し方
                speakButtonColor: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
      );

      final painted = _painted(tester, '読み上げ');
      expect(painted.border, painted.fill);
    });

    testWidgets('${entry.key}: 淡い色の「読み上げ」は灰色の枠のまま', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: theme,
            home: Scaffold(
              body: TTSButton(text: 'こんにちは', onSpeak: () {}),
            ),
          ),
        ),
      );

      final painted = _painted(tester, '読み上げ');
      expect(painted.border, isNot(painted.fill), reason: '淡い塗りと背景の境目が無くなる');
    });

    for (final kind in ConfirmKind.values) {
      testWidgets('${entry.key}: 確認ダイアログの実行ボタン（$kind）の縁は塗りと同じ色',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: ConfirmationDialog(
                title: '削除',
                message: '削除しますか',
                cancelLabel: 'キャンセル',
                confirmLabel: '削除する',
                onCancel: () {},
                onConfirm: () {},
                kind: kind,
              ),
            ),
          ),
        );

        final painted = _painted(tester, '削除する');
        expect(painted.border, painted.fill);
      });
    }
  }
}
