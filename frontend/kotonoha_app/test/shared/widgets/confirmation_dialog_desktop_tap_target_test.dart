/// デスクトップでも確認ダイアログのタップ目標が REQ-3001 を満たすこと。
///
/// theme のトップレベル変数は初回参照時の platform 既定を取り込むため、
/// Android 相当で先に読む既存 theme test とは別 isolate で実行する。
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/themes/dark_theme.dart';
import 'package:kotonoha_app/core/themes/high_contrast_theme.dart';
import 'package:kotonoha_app/core/themes/light_theme.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/clear_all_button.dart';

const _minimumTapTarget = 44.0;
const _epsilon = 0.01;

Finder _button(String label) => find.ancestor(
      of: find.text(label),
      matching: find.byWidgetPredicate((widget) => widget is ButtonStyleButton),
    );

void main() {
  testWidgets('desktopでも全テーマの全消去キャンセル領域が44px以上ある', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    try {
      for (final (themeName, theme) in [
        ('ライト', lightTheme),
        ('ダーク', darkTheme),
        ('高コントラスト', highContrastTheme),
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: const Scaffold(
              body: Center(child: ClearAllButton(enabled: true)),
            ),
          ),
        );
        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();

        final cancel = _button('いいえ');
        final material = find.descendant(
          of: cancel,
          matching: find.byType(Material),
        );
        expect(material, findsOneWidget,
            reason: '$themeName: キャンセルボタンの描画Materialを取得できない');
        final materialRect = tester.getRect(material);
        final hitRect = tester.getRect(cancel);
        expect(
            hitRect.height, greaterThanOrEqualTo(_minimumTapTarget - _epsilon),
            reason: '$themeName: desktopで「いいえ」のhit領域が44px未満'
                '（hit=$hitRect, Material=$materialRect）');
        expect(
            hitRect.width, greaterThanOrEqualTo(_minimumTapTarget - _epsilon),
            reason: '$themeName: desktopで「いいえ」のhit領域が44px未満'
                '（hit=$hitRect, Material=$materialRect）');
        expect(theme.visualDensity, VisualDensity.standard,
            reason: '$themeName: platformによってボタン寸法を縮めない');
        expect(theme.materialTapTargetSize, MaterialTapTargetSize.padded,
            reason: '$themeName: platformによってhit領域を縮めない');

        await tester.tap(cancel);
        await tester.pumpAndSettle();
      }
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
