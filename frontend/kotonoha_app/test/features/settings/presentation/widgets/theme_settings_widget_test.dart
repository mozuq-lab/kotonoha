/// テーマ設定ウィジェットのテスト
///
/// 電話の幅でも、選択肢の名前が語の途中で折り返さない（「高コントラス／ト」にならない）。
/// 折り返しは、描いた幅が 1 行で描くのに要る幅（intrinsic width）より狭いかで見る。
/// 固定の箱の中の Text の大きさは、折り返していても変わらないので使えない。
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/themes/theme_provider.dart';
import 'package:kotonoha_app/features/settings/presentation/widgets/theme_settings_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 小さめの電話で、設定画面のカードの内側に使える幅（論理ピクセル）
const _phoneCardWidth = 300.0;

Future<void> _pump(WidgetTester tester, String fontSize) async {
  SharedPreferences.setMockInitialValues({'fontSize': fontSize});
  await tester.pumpWidget(
    ProviderScope(
      child: Consumer(
        builder: (context, ref, _) => MaterialApp(
          theme: ref.watch(currentThemeProvider),
          home: const Scaffold(
            body: Center(
              child: SizedBox(
                width: _phoneCardWidth,
                child: ThemeSettingsWidget(),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void _expectSingleLine(WidgetTester tester, String label) {
  final paragraph = tester.renderObject<RenderParagraph>(find.text(label));
  final oneLine = paragraph.getMaxIntrinsicWidth(double.infinity);
  expect(paragraph.size.width, greaterThanOrEqualTo(oneLine - 0.5),
      reason: '「$label」が折り返している（幅 ${paragraph.size.width}、1 行に要る幅 $oneLine）');
}

void main() {
  for (final fontSize in ['medium', 'large']) {
    testWidgets('電話の幅（文字サイズ $fontSize）でも選択肢の名前が折り返さない', (tester) async {
      await _pump(tester, fontSize);
      for (final label in ['ライト', 'ダーク', '高コントラスト']) {
        _expectSingleLine(tester, label);
      }
    });
  }
}
