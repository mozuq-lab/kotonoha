/// 緊急確認ダイアログの文字がフォントサイズ設定に追従する（REQ-2007、台帳 L-111）
/// 設定 → currentThemeProvider → ダイアログ の実際の経路を通し、
/// 描画された RenderParagraph の fontSize（OS の文字拡大を掛ける前の値）で測る。
/// 「中」では 1px も変えない（20 / 20 / 16 / 20）。
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/themes/theme_provider.dart';
import 'package:kotonoha_app/features/emergency/presentation/widgets/emergency_button_with_confirmation.dart';
import 'package:kotonoha_app/features/emergency/presentation/widgets/emergency_confirmation_dialog.dart';
import 'package:kotonoha_app/features/settings/models/app_settings.dart';
import 'package:kotonoha_app/features/settings/models/app_theme.dart';
import 'package:kotonoha_app/features/settings/models/font_size.dart';
import 'package:kotonoha_app/features/settings/providers/settings_provider.dart';

/// 設定を固定して返す Notifier（SharedPreferences を読まない）
class _FixedSettings extends SettingsNotifier {
  _FixedSettings(this._settings);
  final AppSettings _settings;

  @override
  Future<AppSettings> build() async => _settings;
}

const _supplementaryText = '周囲に緊急音が鳴り、画面が赤くなります。';

/// 設定を固定したアプリ相当の木で、緊急ボタンから確認ダイアログを開く。
/// 設定ごとに独立した pump にする（同じ木で override だけ作り直しても、生成済みの
/// [_FixedSettings] とその設定値が残るので、設定が変わらないまま緑になる）。
Future<void> _openDialog(
  WidgetTester tester, {
  required FontSize fontSize,
  AppTheme theme = AppTheme.light,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsNotifierProvider.overrideWith(
          () => _FixedSettings(AppSettings(fontSize: fontSize, theme: theme)),
        ),
      ],
      child: Consumer(
        builder: (context, ref, _) => MaterialApp(
          theme: ref.watch(currentThemeProvider),
          home: Scaffold(
            body: Center(
              child: EmergencyButtonWithConfirmation(
                onEmergencyConfirmed: () {},
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byType(EmergencyButtonWithConfirmation));
  await tester.pumpAndSettle();
  expect(find.byType(EmergencyConfirmationDialog), findsOneWidget);
}

double _renderedFontSize(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(find.text(text)).text.style!.fontSize!;

void main() {
  group('緊急確認ダイアログの文字サイズ（L-111）', () {
    // 基準は「中」の 20 / 20 / 16 / 20。設定の倍率は 0.8 / 1.0 / 1.2
    for (final (fontSize, factor) in [
      (FontSize.small, 0.8),
      (FontSize.medium, 1.0),
      (FontSize.large, 1.2),
    ]) {
      testWidgets('「${fontSize.name}」で見出し・本文・補足・ボタンが倍率 $factor で描かれる',
          (tester) async {
        await _openDialog(tester, fontSize: fontSize);

        expect(
          _renderedFontSize(tester, EmergencyConfirmationDialog.dialogTitle),
          closeTo(20 * factor, 0.01),
        );
        expect(
          _renderedFontSize(
            tester,
            EmergencyConfirmationDialog.confirmationMessage,
          ),
          closeTo(20 * factor, 0.01),
        );
        expect(
          _renderedFontSize(tester, _supplementaryText),
          closeTo(16 * factor, 0.01),
        );
        expect(
          _renderedFontSize(tester, EmergencyConfirmationDialog.confirmLabel),
          closeTo(20 * factor, 0.01),
        );
        expect(
          _renderedFontSize(tester, EmergencyConfirmationDialog.cancelLabel),
          closeTo(20 * factor, 0.01),
        );
      });
    }

    // 「中」の見た目はテーマが違っても変えない
    for (final theme in AppTheme.values) {
      testWidgets('「中」は ${theme.name} テーマでも 20 / 20 / 16 / 20 のまま',
          (tester) async {
        await _openDialog(tester, fontSize: FontSize.medium, theme: theme);

        expect(
          _renderedFontSize(tester, EmergencyConfirmationDialog.dialogTitle),
          closeTo(20, 0.01),
        );
        expect(
          _renderedFontSize(
            tester,
            EmergencyConfirmationDialog.confirmationMessage,
          ),
          closeTo(20, 0.01),
        );
        expect(
            _renderedFontSize(tester, _supplementaryText), closeTo(16, 0.01));
        expect(
          _renderedFontSize(tester, EmergencyConfirmationDialog.confirmLabel),
          closeTo(20, 0.01),
        );
      });
    }

    // リスク: ボタンの箱（120×44）は固定。ラベルが収まらないと折り返して
    // 高さ 44 で切られ、「いいえ」が「いい」（肯定）と読める。アプリの「大」に
    // OS の文字拡大が重なると起きる（Android の最大は 1.3 倍）。
    // Text は箱の幅に制約されるだけで矩形は箱を出ないので、制約後の大きさでは
    // 測れない。「折り返していない」と「描かれた矩形が箱に入っている」で測る
    for (final osScale in [1.0, 1.3, 2.0]) {
      testWidgets('「大」と OS の文字拡大 $osScale 倍でも、ボタンのラベルが欠けない', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = osScale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await _openDialog(tester, fontSize: FontSize.large);

        for (final label in [
          EmergencyConfirmationDialog.confirmLabel,
          EmergencyConfirmationDialog.cancelLabel,
        ]) {
          final paragraph =
              tester.renderObject<RenderParagraph>(find.text(label));
          expect(
            paragraph.size.width,
            closeTo(paragraph.getMaxIntrinsicWidth(double.infinity), 0.01),
            reason: '「$label」が折り返している（1 行の自然な幅で置かれていない）',
          );
          final button = tester.getRect(
            find.ancestor(
              of: find.text(label),
              matching: find.byType(ElevatedButton),
            ),
          );
          final drawn = tester.getRect(find.text(label));
          expect(
            button.expandToInclude(drawn),
            equals(button),
            reason: '「$label」の描かれた矩形 $drawn がボタン $button からはみ出している',
          );
        }
        expect(tester.takeException(), isNull);
      });
    }
  });
}
