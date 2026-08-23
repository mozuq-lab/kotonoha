/// エラーダイアログ／スナックバーのコントラスト比回帰テスト
///
/// 【テスト対象】: lib/core/widgets/error_dialog.dart
/// 【テスト目的】: 3テーマ（ライト／ダーク／高コントラスト）すべてで
/// WCAG 2.1 AA を満たし続けることを保証する
///
/// 【背景（実障害）】: これらのダイアログは背景色を自前で持たずテーマの surface に
/// 載るため、固定色ではライト・ダークの一方で必ずコントラスト不足になっていた。
/// - 警告アイコンは Colors.orange[700] で、ライト 2.5:1 / 高コントラスト 2.7:1
/// - 元テキストボックスは背景を grey[100] に固定しつつ本文は色未指定だったため、
///   ダークテーマで白文字が near-white 背景に載り 1.09:1
/// - スナックバーは背景を red[700] に固定しつつ本文は色未指定で、ダークで 3.35:1
///
/// 【重要】: 色は宣言値ではなく**解決済みの描画色**から読む。色未指定でテーマ継承
/// させるのがまさにバグの形であり、宣言値を読むと null で測れずクラッシュしてしまい、
/// コントラスト値による回帰検出ができないため。
///
/// 🔵 信頼性レベル: 青信号 - NFR（高コントラストモード WCAG 2.1 AA・4.5:1以上）
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kotonoha_app/core/themes/dark_theme.dart';
import 'package:kotonoha_app/core/themes/high_contrast_theme.dart';
import 'package:kotonoha_app/core/themes/light_theme.dart';
import 'package:kotonoha_app/core/widgets/error_dialog.dart';

import 'contrast_helpers.dart';

/// 検証対象の3テーマ
final Map<String, ThemeData> _themes = {
  'ライト': lightTheme,
  'ダーク': darkTheme,
  '高コントラスト': highContrastTheme,
};

/// ダイアログの実描画背景色を取り出す。
///
/// `AlertDialog.backgroundColor` は未指定のことが多く、その場合の実際の色は
/// Flutter 内部のデフォルト解決（M3 では colorScheme.surfaceContainerHigh、
/// 未定義なら surface へフォールバック）に依存する。宣言値ではなく
/// 実際に描画される Material の色を読むことで、テーマ設定の変更で
/// テストだけが古い値を見て緑のままになる事態を防ぐ。
Color _dialogBackground(WidgetTester tester) {
  final material = tester.widget<Material>(
    find
        .descendant(
            of: find.byType(AlertDialog), matching: find.byType(Material))
        .first,
  );
  return material.color!;
}

void main() {
  group('警告アイコン', () {
    Future<Color> pumpAndReadIcon(WidgetTester tester, ThemeData theme) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () =>
                    showNetworkErrorDialog(context: context, onRetry: () {}),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return resolvedIconColor(tester, Icons.wifi_off);
    }

    for (final entry in _themes.entries) {
      testWidgets('${entry.key}テーマで警告アイコンが 3:1 以上', (tester) async {
        final icon = await pumpAndReadIcon(tester, entry.value);
        final background = _dialogBackground(tester);

        expectOpaque(background, '${entry.key}テーマのダイアログ背景');
        expectOpaque(icon, '${entry.key}テーマの警告アイコン');

        final ratio = contrastRatio(icon, background);
        expect(
          ratio,
          greaterThanOrEqualTo(3.0),
          reason: '${entry.key}テーマの警告アイコンのコントラスト比が '
              '${ratio.toStringAsFixed(2)}:1 で非テキスト基準 (3:1) 未達',
        );
      });
    }
  });

  group('AI変換エラーの元テキストボックス', () {
    for (final entry in _themes.entries) {
      testWidgets('${entry.key}テーマで本文・ラベル・枠線が基準を満たす', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: entry.value,
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => showAIConversionErrorDialog(
                    context: context,
                    originalText: '水 ぬるく',
                    onUseOriginal: () {},
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        // ボックス本体（BoxDecoration を持つ Container）をダイアログ配下に限定して取る
        final boxFinder = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byWidgetPredicate(
            (w) => w is Container && w.decoration is BoxDecoration,
          ),
        );
        expect(
          boxFinder,
          findsOneWidget,
          reason: 'ボックスの特定が曖昧になっている（構造変更の可能性）',
        );

        final decoration =
            tester.widget<Container>(boxFinder).decoration! as BoxDecoration;
        final background = decoration.color!;
        final borderColor = decoration.border!.top.color;
        final label = resolvedTextColor(tester, find.text('元のテキスト:'));
        final body = resolvedTextColor(tester, find.text('水 ぬるく'));

        expectOpaque(background, '${entry.key}テーマのボックス背景');
        expectOpaque(body, '${entry.key}テーマの本文色');

        // 本文・ラベルはテキストなので 4.5:1
        for (final target
            in <String, Color>{'本文': body, 'ラベル': label}.entries) {
          final ratio = contrastRatio(target.value, background);
          expect(
            ratio,
            greaterThanOrEqualTo(4.5),
            reason: '${entry.key}テーマの${target.key}のコントラスト比が '
                '${ratio.toStringAsFixed(2)}:1 で WCAG 2.1 AA (4.5:1) 未達',
          );
        }

        // 枠線は非テキスト。WCAG 1.4.11 は「隣接する色」に対して評価するため、
        // ダイアログ背景側とボックス背景側の両方を見て、厳しい方で判定する。
        final dialogBg = _dialogBackground(tester);
        final borderRatio = [
          contrastRatio(borderColor, dialogBg),
          contrastRatio(borderColor, background),
        ].reduce((a, b) => a < b ? a : b);
        expect(
          borderRatio,
          greaterThanOrEqualTo(3.0),
          reason: '${entry.key}テーマの枠線のコントラスト比（隣接色のうち厳しい方）が '
              '${borderRatio.toStringAsFixed(2)}:1 で非テキスト基準 (3:1) 未達',
        );
      });
    }
  });

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
