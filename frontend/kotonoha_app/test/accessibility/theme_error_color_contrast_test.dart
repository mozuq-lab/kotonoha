/// テーマのエラー色のコントラスト比回帰テスト
/// テスト対象: lib/core/themes/{light,dark,high_contrast}_theme.dart の
/// `colorScheme.error` / `colorScheme.onError`
/// WCAG 2.1 AA を満たし続けることを保証する。
/// 1. 前景として: `TextField.errorText` やエラーアイコンなど
/// テーマの surface 上に `error` 色そのものを描画する使い方
/// 2. 背景として: 削除ボタンなど、`error` を背景に `onError` を載せる使い方
/// 背景（実障害）
/// ダークテーマは error に #D32F2F（ライト用の濃い赤）を流用していたため
/// surface(#1E1E1E) 上で 3.35:1、onError(黒)との組み合わせで 4.22:1 と
/// どちらの使い方でもAA未達だった
/// 高コントラストテーマは error に純赤 #FF0000 を使い、白背景・白文字の
/// いずれに対しても 4.00:1 しかなかった（コード上のコメントは 5.25:1 と
/// 誤記されていた）
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kotonoha_app/core/themes/dark_theme.dart';
import 'package:kotonoha_app/core/themes/high_contrast_theme.dart';
import 'package:kotonoha_app/core/themes/light_theme.dart';

import '../support/contrast_helpers.dart';

final Map<String, ThemeData> _themes = {
  'ライト': lightTheme,
  'ダーク': darkTheme,
  '高コントラスト': highContrastTheme,
};

void main() {
  group('colorScheme.error を背景にした SnackBar', () {
    // history_screen / favorites_screen は backgroundColor に error だけを渡し
    // 本文の色は SnackBar 既定（onInverseSurface）に任せている。
    // 「背景を固定しつつ前景をテーマ継承にする」形なので、error を変えると
    // 気付かないうちに破綻しうる。実際に使っている組み合わせで固定する。
    for (final entry in _themes.entries) {
      testWidgets('${entry.key}テーマで本文が 4.5:1 以上', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: entry.value,
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () =>
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: const Text('読み上げに失敗しました'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  )),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 800));

        final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
        final background = snackBar.backgroundColor!;
        final text = resolvedTextColor(tester, find.text('読み上げに失敗しました'));

        expectOpaque(background, '${entry.key}テーマのスナックバー背景');
        expectOpaque(text, '${entry.key}テーマのスナックバー本文色');

        final ratio = contrastRatio(text, background);
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason: '${entry.key}テーマのスナックバー本文のコントラスト比が '
              '${ratio.toStringAsFixed(2)}:1 で WCAG 2.1 AA (4.5:1) 未達',
        );
      });
    }
  });

  group('colorScheme.error', () {
    for (final entry in _themes.entries) {
      test('${entry.key}テーマ: surface上の文字色として 4.5:1 以上', () {
        final scheme = entry.value.colorScheme;

        expectOpaque(scheme.error, '${entry.key}テーマの error');
        expectOpaque(scheme.surface, '${entry.key}テーマの surface');

        final ratio = contrastRatio(scheme.error, scheme.surface);
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason: '${entry.key}テーマの error を surface 上の文字に使うと '
              '${ratio.toStringAsFixed(2)}:1 で WCAG 2.1 AA (4.5:1) 未達',
        );
      });

      test('${entry.key}テーマ: 背景として onError と 4.5:1 以上', () {
        final scheme = entry.value.colorScheme;

        expectOpaque(scheme.onError, '${entry.key}テーマの onError');

        final ratio = contrastRatio(scheme.onError, scheme.error);
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason: '${entry.key}テーマの error 背景 + onError 文字が '
              '${ratio.toStringAsFixed(2)}:1 で WCAG 2.1 AA (4.5:1) 未達',
        );
      });
    }
  });
}
