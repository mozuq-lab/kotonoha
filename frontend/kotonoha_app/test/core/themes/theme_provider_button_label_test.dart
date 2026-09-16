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

  TextStyle styleOf(WidgetTester tester, String text) =>
      tester.renderObject<RenderParagraph>(find.text(text)).text.style!;

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

  group('「大」でも fontSize 以外（fontWeight・letterSpacing・fontFamily）は変わらない（再レビュー反映）',
      () {
    // なぜ: サイズだけを見るテストは、テーマの既定スタイル（太さ・字間・
    // フォントファミリー等）を丸ごと素の TextStyle(fontSize:...) に
    // 置き換えてしまう実装のバグを検出できない（fontSize さえ合っていれば
    // 通ってしまう）。
    //
    // 「中」の基準値は独立した pump で実測した値（下記の一覧参照。
    // 同一テスト内で `pumpButtons` を 2 回呼んで「中→大」を比較する方法は
    // 採らない: `ProviderScope.overrides` は既存の container に対して
    // ホットスワップされず、2 回目の pump も 1 回目の設定のまま描画され続ける
    // ため、常に「変化なし」を観測してしまい、テストとして機能しない
    // （実際にこの罠で 4 本とも偽の green になることを確認した）。
    //
    // 中の基準値（実測、TextButton/OutlinedButton/FilledButton で共通）:
    //   fontWeight: FontWeight.w500, letterSpacing: 0.1, fontFamily: 'Roboto'
    //   （Material 3 既定 = `Theme.of(context).textTheme.labelLarge`。
    //   実体は `Typography.englishLike2021.labelLarge`。round 2 の報告参照）
    const defaultLabelFontWeight = FontWeight.w500;
    const defaultLabelLetterSpacing = 0.1;
    const defaultLabelFontFamily = 'Roboto';

    testWidgets('ElevatedButton は「大」でもテーマの太字のまま', (tester) async {
      await pumpButtons(tester, FontSize.large);
      final style = styleOf(tester, '保存');
      expect(style.fontWeight, FontWeight.bold);
    });

    testWidgets('TextButton は「大」でも太さ・字間・フォントファミリーが変わらない', (tester) async {
      await pumpButtons(tester, FontSize.large);
      final style = styleOf(tester, 'キャンセル');
      expect(style.fontWeight, defaultLabelFontWeight);
      expect(style.letterSpacing, defaultLabelLetterSpacing);
      expect(style.fontFamily, defaultLabelFontFamily);
    });

    testWidgets('OutlinedButton は「大」でも太さ・字間・フォントファミリーが変わらない', (tester) async {
      await pumpButtons(tester, FontSize.large);
      final style = styleOf(tester, '枠線');
      expect(style.fontWeight, defaultLabelFontWeight);
      expect(style.letterSpacing, defaultLabelLetterSpacing);
      expect(style.fontFamily, defaultLabelFontFamily);
    });

    testWidgets('FilledButton は「大」でも太さ・字間・フォントファミリーが変わらない', (tester) async {
      await pumpButtons(tester, FontSize.large);
      final style = styleOf(tester, '塗り');
      expect(style.fontWeight, defaultLabelFontWeight);
      expect(style.letterSpacing, defaultLabelLetterSpacing);
      expect(style.fontFamily, defaultLabelFontFamily);
    });
  });

  group('「中」でも Material 既定の太さ・字間・フォントファミリーである（基準値の裏付け）', () {
    testWidgets('TextButton', (tester) async {
      await pumpButtons(tester, FontSize.medium);
      final style = styleOf(tester, 'キャンセル');
      expect(style.fontWeight, FontWeight.w500);
      expect(style.letterSpacing, 0.1);
      expect(style.fontFamily, 'Roboto');
    });

    testWidgets('OutlinedButton', (tester) async {
      await pumpButtons(tester, FontSize.medium);
      final style = styleOf(tester, '枠線');
      expect(style.fontWeight, FontWeight.w500);
      expect(style.letterSpacing, 0.1);
      expect(style.fontFamily, 'Roboto');
    });

    testWidgets('FilledButton', (tester) async {
      await pumpButtons(tester, FontSize.medium);
      final style = styleOf(tester, '塗り');
      expect(style.fontWeight, FontWeight.w500);
      expect(style.letterSpacing, 0.1);
      expect(style.fontFamily, 'Roboto');
    });

    testWidgets('ElevatedButton', (tester) async {
      await pumpButtons(tester, FontSize.medium);
      final style = styleOf(tester, '保存');
      expect(style.fontWeight, FontWeight.bold);
    });
  });
}
