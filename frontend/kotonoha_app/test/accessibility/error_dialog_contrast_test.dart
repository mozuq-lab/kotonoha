/// エラーダイアログ／スナックバーのコントラスト比回帰テスト
/// テスト対象: lib/core/widgets/error_dialog.dart
/// WCAG 2.1 AA を満たし続けることを保証する
/// 背景（実障害）: これらのダイアログは背景色を自前で持たずテーマの surface に
/// 載るため、固定色ではライト・ダークの一方で必ずコントラスト不足になっていた。
/// 警告アイコンは Colors.orange[700] で、ライト 2.5:1 / 高コントラスト 2.7:1
/// 元テキストボックスは背景を grey[100] に固定しつつ本文は色未指定だったため
/// ダークテーマで白文字が near-white 背景に載り 1.09:1
/// スナックバーは背景を red[700] に固定しつつ本文は色未指定で、ダークで 3.35:1
/// 重要: 色は宣言値ではなく**解決済みの描画色**から読む。色未指定でテーマ継承
/// させるのがまさにバグの形であり、宣言値を読むと null で測れずクラッシュしてしまい
/// コントラスト値による回帰検出ができないため。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kotonoha_app/core/themes/dark_theme.dart';
import 'package:kotonoha_app/core/themes/high_contrast_theme.dart';
import 'package:kotonoha_app/core/themes/light_theme.dart';
import 'package:kotonoha_app/core/widgets/error_dialog.dart';

import '../support/contrast_helpers.dart';

/// 検証対象の3テーマ
final Map<String, ThemeData> _themes = {
  'ライト': lightTheme,
  'ダーク': darkTheme,
  '高コントラスト': highContrastTheme,
};

void main() {
  group('エラースナックバー', () {
    for (final entry in _themes.entries) {
      testWidgets('${entry.key}テーマで本文が 4.5:1 以上', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: entry.value,
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => showErrorSnackBar(
                    context: context,
                    message: '接続できませんでした',
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
        final background = snackBar.backgroundColor!;
        final textColor = resolvedTextColor(tester, find.text('接続できませんでした'));

        expectOpaque(background, '${entry.key}テーマのスナックバー背景');
        expectOpaque(textColor, '${entry.key}テーマのスナックバー本文色');

        final ratio = contrastRatio(textColor, background);
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason: '${entry.key}テーマのスナックバー本文のコントラスト比が '
              '${ratio.toStringAsFixed(2)}:1 で WCAG 2.1 AA (4.5:1) 未達',
        );
      });
    }
  });
}
