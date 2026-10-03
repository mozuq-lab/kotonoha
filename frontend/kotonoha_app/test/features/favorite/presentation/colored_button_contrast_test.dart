/// 色付きボタン（お気に入り・クイック応答）の、描かれた色の見やすさ。
///
/// - 文字は面に 4.5:1 以上
/// - 境界（台帳 L-141 の決定）: 塗りが背景に 3:1 以上、または
///   縁が背景と塗りの両方に 3:1 以上
///
/// 利用者が選べる全色・既定色 × 3 テーマで、実際に組み立てたボタンの
/// 解決済みの色を見る。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/themes/button_tone.dart';
import 'package:kotonoha_app/core/themes/dark_theme.dart';
import 'package:kotonoha_app/core/themes/high_contrast_theme.dart';
import 'package:kotonoha_app/core/themes/light_theme.dart';
import 'package:kotonoha_app/core/utils/contrast.dart';
import 'package:kotonoha_app/features/favorite/domain/models/favorite.dart';
import 'package:kotonoha_app/features/favorite/presentation/constants/favorite_colors.dart';
import 'package:kotonoha_app/features/favorite/presentation/widgets/favorite_shortcut_button.dart';
import 'package:kotonoha_app/features/quick_response/presentation/widgets/quick_response_buttons.dart';
import 'package:kotonoha_app/features/settings/models/font_size.dart';

const _themes = [
  ('ライト', 'light'),
  ('ダーク', 'dark'),
  ('高コントラスト', 'highContrast'),
];

ThemeData _theme(String name) => switch (name) {
      'light' => lightTheme,
      'dark' => darkTheme,
      _ => highContrastTheme,
    };

/// ボタンの面・文字・縁（ボタンの指定が無ければテーマの縁）を取り出して確かめる
void _expectReadable(
  WidgetTester tester,
  Finder button,
  ThemeData theme,
  String label,
) {
  final style = tester.widget<ElevatedButton>(button).style!;
  final fill = style.backgroundColor!.resolve({})!;
  final text = style.foregroundColor!.resolve({})!;
  final side = style.side?.resolve({}) ??
      theme.elevatedButtonTheme.style!.side!.resolve({})!;
  final background = theme.scaffoldBackgroundColor;

  expect(wcagContrastRatio(text, fill), greaterThanOrEqualTo(4.5),
      reason: '$label: 文字 $text が面 $fill に対し 4.5:1 未満');
  final fillStandsOut = wcagContrastRatio(fill, background) >= 3;
  final borderStandsOut = side.style != BorderStyle.none &&
      wcagContrastRatio(side.color, background) >= 3 &&
      wcagContrastRatio(side.color, fill) >= 3;
  expect(fillStandsOut || borderStandsOut, isTrue,
      reason: '$label: 面 $fill も縁 ${side.color} も背景 $background から'
          '見分けられない');
}

void main() {
  final colors = <(String, int?)>[
    ('既定', null),
    ...favoriteColorChoices.map((c) => (c.$1, c.$2)),
  ];

  for (final (themeLabel, themeName) in _themes) {
    for (final (colorLabel, value) in colors) {
      testWidgets('$themeLabel・お気に入り「$colorLabel」', (tester) async {
        final theme = _theme(themeName);
        await tester.pumpWidget(MaterialApp(
          theme: theme,
          home: Scaffold(
            body: FavoriteShortcutButton(
              favorite: Favorite(
                id: 'f',
                content: 'お水',
                createdAt: DateTime(2026),
                colorValue: value,
              ),
              onPressed: () {},
              height: 60,
              fontSize: FontSize.medium,
            ),
          ),
        ));
        _expectReadable(tester, find.byType(ElevatedButton), theme,
            '$themeLabel・$colorLabel');
      });
    }

    testWidgets('$themeLabel・クイック応答（はい・いいえ・わからない）', (tester) async {
      final theme = _theme(themeName);
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: Scaffold(
          body: QuickResponseButtons(onResponse: (_) {}, illustrated: true),
        ),
      ));
      for (final label in ['はい', 'いいえ', 'わからない']) {
        _expectReadable(
          tester,
          find.ancestor(
            of: find.text(label),
            matching: find.byType(ElevatedButton),
          ),
          theme,
          '$themeLabel・$label',
        );
      }
    });
  }

  // 淡くしても、利用者が選べる色同士・既定色が見分けられる
  // （面の差が小さい組は、縁の色の差で見分けられる）
  for (final (themeLabel, themeName) in _themes.take(2)) {
    test('$themeLabel: お気に入りの色同士が見分けられる', () {
      final scheme = _theme(themeName).colorScheme;
      final tones = [
        for (final (name, value) in colors)
          (
            name,
            favoriteTone(
              Favorite(
                id: name,
                content: '',
                createdAt: DateTime(2026),
                colorValue: value,
              ),
              scheme,
            )!,
          ),
      ];
      for (var i = 0; i < tones.length; i++) {
        for (var j = i + 1; j < tones.length; j++) {
          final (na, a) = tones[i];
          final (nb, b) = tones[j];
          final fill = perceptualDistance(a.fill, b.fill);
          final border = perceptualDistance(a.border, b.border);
          expect(fill >= 0.04 || border >= 0.06, isTrue,
              reason: '「$na」と「$nb」の面（差 ${fill.toStringAsFixed(3)}）も'
                  '縁（差 ${border.toStringAsFixed(3)}）も近すぎる');
        }
      }
    });
  }
}
