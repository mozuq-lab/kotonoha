/// 状態ボタンのコントラスト比回帰テスト
/// テスト対象
/// lib/features/status_buttons/presentation/widgets/status_button.dart
/// lib/features/status_buttons/domain/status_button_constants.dart
/// WCAG 2.1 AA を満たし続けることを保証する。
/// 背景（実障害）: 背景はカテゴリ別の色（オレンジ／青／緑）なのに
/// 文字色を `Colors.white` 固定にしていたため、いずれのカテゴリでも
/// WCAG AA(4.5:1)未達だった。
/// 身体状態 #FF9800 + 白: 2.16:1
/// 要求 #2196F3 + 白: 3.12:1
/// 感情 #4CAF50 + 白: 2.78:1
/// 設計判断: カテゴリ別の色分けは識別の手がかりなので
/// 変えず、前景を背景輝度から選ぶことで基準を満たす。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kotonoha_app/core/themes/dark_theme.dart';
import 'package:kotonoha_app/core/themes/high_contrast_theme.dart';
import 'package:kotonoha_app/core/themes/light_theme.dart';
import 'package:kotonoha_app/features/status_buttons/domain/status_button_constants.dart';
import 'package:kotonoha_app/features/status_buttons/domain/status_button_type.dart';
import 'package:kotonoha_app/features/status_buttons/presentation/widgets/status_button.dart';

import '../support/contrast_helpers.dart';

/// 検証対象の3テーマ
final Map<String, ThemeData> _themes = {
  'ライト': lightTheme,
  'ダーク': darkTheme,
  '高コントラスト': highContrastTheme,
};

void main() {
  group('状態ボタンの文字色', () {
    for (final entry in _themes.entries) {
      for (final type in allStatusTypes) {
        testWidgets('${entry.key}テーマ・「${type.label}」が 4.5:1 以上',
            (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              theme: entry.value,
              home: Scaffold(
                body: Center(
                  child: StatusButton(
                    statusType: type,
                    onPressed: () {},
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // 実際に描画されている背景（ButtonStyleButton が生成する Material）
          final background = tester
              .widget<Material>(
                find
                    .descendant(
                      of: find.byType(ElevatedButton),
                      matching: find.byType(Material),
                    )
                    .first,
              )
              .color!;
          final text = resolvedTextColor(tester, find.text(type.label));

          expectOpaque(background, '${entry.key}テーマの「${type.label}」背景');
          expectOpaque(text, '${entry.key}テーマの「${type.label}」文字');

          final ratio = contrastRatio(text, background);
          expect(
            ratio,
            greaterThanOrEqualTo(4.5),
            reason: '${entry.key}テーマの「${type.label}」のコントラスト比が '
                '${ratio.toStringAsFixed(2)}:1 で WCAG 2.1 AA (4.5:1) 未達',
          );
        });
      }
    }
  });

  group('カテゴリ色の定義', () {
    // ウィジェットを介さず色定義そのものも押さえる。
    // 「白文字前提で色を選び直す」といった逆行を検出するため。
    final categories = <String, Color>{
      '身体状態': StatusButtonColors.physical,
      '要求': StatusButtonColors.request,
      '感情': StatusButtonColors.emotion,
    };

    for (final entry in categories.entries) {
      test('${entry.key}の色は黒・白いずれかと 4.5:1 以上を確保できる', () {
        final best = [
          contrastRatio(Colors.white, entry.value),
          contrastRatio(Colors.black, entry.value),
        ].reduce((a, b) => a > b ? a : b);
        expect(
          best,
          greaterThanOrEqualTo(4.5),
          reason: '${entry.key}の色 ${entry.value} は黒・白どちらを載せても '
              '${best.toStringAsFixed(2)}:1 が上限で WCAG 2.1 AA (4.5:1) 未達',
        );
      });
    }
  });
}
