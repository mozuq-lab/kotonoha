/// ボタンラベルの文字サイズがフォント設定に追従する（REQ-802、タスクレビュー反映）
/// 「中」では基準値（実測値）そのままで 1px も変えない。
/// 基準値（このテストで実測・記録した値）:
/// ElevatedButton: 20.0（テーマの ElevatedButtonThemeData.style.textStyle が明示）
/// TextButton / OutlinedButton / FilledButton: 14.0（テーマに textStyle の明示が無く、
/// Material のレンダリング既定値で描かれている）
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/themes/theme_provider.dart';
import 'package:kotonoha_app/features/settings/models/app_settings.dart';
import 'package:kotonoha_app/features/settings/models/font_size.dart';
import 'package:kotonoha_app/features/settings/providers/settings_provider.dart';

/// 設定を固定して返す Notifier（SharedPreferences を読まない）
/// テーマ倍率テスト（theme_provider_font_size_test.dart）と同じもの
class _FixedSettings extends SettingsNotifier {
  _FixedSettings(this._settings);
  final AppSettings _settings;

  @override
  Future<AppSettings> build() async => _settings;
}

void main() {
  // ButtonStyle の実効フォントサイズはテーマの ThemeData だけでは測れない
  // （M3 の既定値との合成は実際の描画時に解決される）ため、
  // 実際にボタンを描画して RenderParagraph で測る。
  Future<void> pumpButtons(WidgetTester tester, FontSize size) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsNotifierProvider.overrideWith(
            () => _FixedSettings(AppSettings(fontSize: size)),
          ),
        ],
        child: Consumer(
          builder: (context, ref, _) => MaterialApp(
            theme: ref.watch(currentThemeProvider),
            home: Scaffold(
              body: Column(
                children: [
                  ElevatedButton(onPressed: () {}, child: const Text('保存')),
                  TextButton(onPressed: () {}, child: const Text('キャンセル')),
                  OutlinedButton(onPressed: () {}, child: const Text('枠線')),
                  FilledButton(onPressed: () {}, child: const Text('塗り')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  double sizeOf(WidgetTester tester, String text) => tester
      .renderObject<RenderParagraph>(find.text(text))
      .text
      .style!
      .fontSize!;

  const elevatedBase = 20.0;
  const textOutlinedFilledBase = 14.0;

  group('「中」（既定）ではボタンラベルの実効サイズが 1px も変わらない', () {
    testWidgets('ElevatedButton', (tester) async {
      await pumpButtons(tester, FontSize.medium);
      expect(sizeOf(tester, '保存'), elevatedBase);
    });

    testWidgets('TextButton', (tester) async {
      await pumpButtons(tester, FontSize.medium);
      expect(sizeOf(tester, 'キャンセル'), textOutlinedFilledBase);
    });

    testWidgets('OutlinedButton', (tester) async {
      await pumpButtons(tester, FontSize.medium);
      expect(sizeOf(tester, '枠線'), textOutlinedFilledBase);
    });

    testWidgets('FilledButton', (tester) async {
      await pumpButtons(tester, FontSize.medium);
      expect(sizeOf(tester, '塗り'), textOutlinedFilledBase);
    });
  });

  group('「大」ではボタンラベルが基準値 × 1.2 になる', () {
    testWidgets('ElevatedButton', (tester) async {
      await pumpButtons(tester, FontSize.large);
      expect(sizeOf(tester, '保存'), closeTo(elevatedBase * 1.2, 0.01));
    });

    testWidgets('TextButton', (tester) async {
      await pumpButtons(tester, FontSize.large);
      expect(
        sizeOf(tester, 'キャンセル'),
        closeTo(textOutlinedFilledBase * 1.2, 0.01),
      );
    });

    testWidgets('OutlinedButton', (tester) async {
      await pumpButtons(tester, FontSize.large);
      expect(
        sizeOf(tester, '枠線'),
        closeTo(textOutlinedFilledBase * 1.2, 0.01),
      );
    });

    testWidgets('FilledButton', (tester) async {
      await pumpButtons(tester, FontSize.large);
      expect(
        sizeOf(tester, '塗り'),
        closeTo(textOutlinedFilledBase * 1.2, 0.01),
      );
    });
  });
}
