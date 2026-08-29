/// ボタン（TextButton / OutlinedButton / ElevatedButton）前景色のコントラスト比回帰テスト
///
/// 【テスト対象】: lib/core/themes/{light,dark,high_contrast}_theme.dart
/// 【テスト目的】: ダイアログ等に置かれる TextButton / OutlinedButton /
/// ElevatedButton のラベルが、3テーマすべてで WCAG 2.1 AA（4.5:1）を
/// 満たすことを保証する。
///
/// 【背景（実障害）】: Material 3 は TextButton / OutlinedButton / ElevatedButton の
/// 既定の前景色に `colorScheme.primary` を使う（ElevatedButton は primary で
/// 塗りつぶすのではなく、surfaceContainerLow の面に primary のラベルを載せる設計）。
/// primary は「塗り」用途で選ばれた色であり、面に載る文字としては検証されて
/// いなかったため、
/// primaryLight(#2196F3) は surface(#F5F5F5) 上で 2.87:1、
/// primaryDark(#1976D2) は surface(#1E1E1E) 上で 3.62:1 と AA 未達だった。
/// 実際に AI変換結果ダイアログの「元の文を使う」、定型文削除ダイアログの
/// 「キャンセル」、オフラインダイアログの「OK」が同じ理由で未達になっており、
/// 個別ダイアログを1つずつ直しても新しいダイアログで再発する。
///
/// 【方針】: テーマ層で textButtonTheme / outlinedButtonTheme /
/// elevatedButtonTheme の foregroundColor を明示し、「塗りとしての primary」と
/// 「面に載る文字としての primary」を別トークンに分離する。
///
/// 🔵 信頼性レベル: 青信号 - NFR（高コントラストモード WCAG 2.1 AA・4.5:1以上）
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kotonoha_app/core/themes/dark_theme.dart';
import 'package:kotonoha_app/core/themes/high_contrast_theme.dart';
import 'package:kotonoha_app/core/themes/light_theme.dart';

import '../support/contrast_helpers.dart';

/// 検証対象の3テーマ
final Map<String, ThemeData> _themes = {
  'ライト': lightTheme,
  'ダーク': darkTheme,
  '高コントラスト': highContrastTheme,
};

/// ダイアログ内に TextButton / OutlinedButton / ElevatedButton を置いた状態を描画する。
Future<void> _pumpDialogWithButtons(
    WidgetTester tester, ThemeData theme) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => AlertDialog(
                content: const Text('本文'),
                actions: [
                  TextButton(onPressed: () {}, child: const Text('テキストボタン')),
                  OutlinedButton(onPressed: () {}, child: const Text('枠線ボタン')),
                  ElevatedButton(onPressed: () {}, child: const Text('標準ボタン')),
                ],
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

/// 画面本体（Scaffold の背景）の上に3種類のボタンを置いた状態を描画する。
Future<void> _pumpScaffoldWithButtons(
    WidgetTester tester, ThemeData theme) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(
        body: Column(
          children: [
            TextButton(onPressed: () {}, child: const Text('テキストボタン')),
            OutlinedButton(onPressed: () {}, child: const Text('枠線ボタン')),
            ElevatedButton(onPressed: () {}, child: const Text('標準ボタン')),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// ボタン自身が描画している背景色を取得する。
///
/// ElevatedButton は自前の面を持つため、周囲の背景ではなくボタン自身の
/// Material の色に対してコントラストを測る必要がある。
Color _buttonBackground(WidgetTester tester, String label) {
  return tester
      .widget<Material>(
        find
            .descendant(
              of: find.widgetWithText(ElevatedButton, label),
              matching: find.byType(Material),
            )
            .first,
      )
      .color!;
}

/// ダイアログの実際の背景色を取得する。
Color _dialogBackground(WidgetTester tester) {
  return tester
      .widget<Material>(
        find
            .descendant(
                of: find.byType(AlertDialog), matching: find.byType(Material))
            .first,
      )
      .color!;
}

void _expectAA(
  WidgetTester tester,
  String themeName,
  String label,
  Color background,
  String backgroundLabel,
) {
  final foreground = resolvedTextColor(tester, find.text(label));
  expectOpaque(background, '$themeNameテーマの$backgroundLabel');
  expectOpaque(foreground, '$themeNameテーマの「$label」ラベル色');

  final ratio = contrastRatio(foreground, background);
  expect(
    ratio,
    greaterThanOrEqualTo(4.5),
    reason:
        '$themeNameテーマの「$label」($foreground) が$backgroundLabel($background) に対し '
        '${ratio.toStringAsFixed(2)}:1 で AA (4.5:1) 未達',
  );
}

void main() {
  group('ダイアログ上のボタンラベル', () {
    for (final entry in _themes.entries) {
      testWidgets('${entry.key}テーマで TextButton のラベルが 4.5:1 以上', (tester) async {
        await _pumpDialogWithButtons(tester, entry.value);
        _expectAA(
            tester, entry.key, 'テキストボタン', _dialogBackground(tester), 'ダイアログ背景');
      });

      testWidgets('${entry.key}テーマで OutlinedButton のラベルが 4.5:1 以上',
          (tester) async {
        await _pumpDialogWithButtons(tester, entry.value);
        _expectAA(
            tester, entry.key, '枠線ボタン', _dialogBackground(tester), 'ダイアログ背景');
      });

      // 【ElevatedButton も必要な理由】: Material 3 の ElevatedButton は primary で
      // 塗りつぶすのではなく、surfaceContainerLow の面に primary のラベルを載せる。
      // つまり TextButton と同じ「面に載る文字」であり、同じ理由で AA 未達になる。
      // 「同意して利用」「保存」「再試行」など主要操作がこの型で、副次操作の
      // TextButton だけが適合するという逆転が起きていた。
      testWidgets('${entry.key}テーマで ElevatedButton のラベルが 4.5:1 以上',
          (tester) async {
        await _pumpDialogWithButtons(tester, entry.value);
        _expectAA(tester, entry.key, '標準ボタン',
            _buttonBackground(tester, '標準ボタン'), '標準ボタン背景');
      });
    }
  });

  group('画面本体上のボタンラベル', () {
    for (final entry in _themes.entries) {
      testWidgets('${entry.key}テーマで TextButton のラベルが 4.5:1 以上', (tester) async {
        await _pumpScaffoldWithButtons(tester, entry.value);
        _expectAA(
          tester,
          entry.key,
          'テキストボタン',
          entry.value.scaffoldBackgroundColor,
          '画面背景',
        );
      });

      testWidgets('${entry.key}テーマで OutlinedButton のラベルが 4.5:1 以上',
          (tester) async {
        await _pumpScaffoldWithButtons(tester, entry.value);
        _expectAA(
          tester,
          entry.key,
          '枠線ボタン',
          entry.value.scaffoldBackgroundColor,
          '画面背景',
        );
      });

      testWidgets('${entry.key}テーマで ElevatedButton のラベルが 4.5:1 以上',
          (tester) async {
        await _pumpScaffoldWithButtons(tester, entry.value);
        _expectAA(tester, entry.key, '標準ボタン',
            _buttonBackground(tester, '標準ボタン'), '標準ボタン背景');
      });
    }
  });
}
