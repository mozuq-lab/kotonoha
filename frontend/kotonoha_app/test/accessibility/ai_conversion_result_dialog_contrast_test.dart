/// AI変換結果ダイアログのコントラスト比回帰テスト
/// テスト対象
/// lib/features/ai_conversion/presentation/widgets/ai_conversion_result_dialog.dart
/// WCAG 2.1 AA を満たし続けることを保証する。
/// 背景（実障害）: 変換結果ボックスの背景を
/// `withValues(alpha:)` の半透明色にしていたため、実際の色はダイアログ背景との
/// 合成結果に依存していた。さらに枠線にはテーマのプライマリ色をそのまま使って
/// おり、ライトテーマで 2.59:1（ボックス背景に対して）／2.87:1（ダイアログ背景に
/// 対して）と非テキスト基準(3:1)未達だった。
/// 方針: 合成後の色をそのまま不透明な定数として AppColors に持たせ
/// 見た目を変えずにコントラストを計算・検証できる状態にする。枠線は
/// テーマごとに背景から 3:1 以上離れた専用色にする。
/// 重要: 半透明色は [expectOpaque] で弾く。コントラスト比は合成後の色で
/// 決まるため、宣言値のまま計算すると実際より良い値が出てしまう。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kotonoha_app/core/themes/dark_theme.dart';
import 'package:kotonoha_app/core/themes/high_contrast_theme.dart';
import 'package:kotonoha_app/core/themes/light_theme.dart';
import 'package:kotonoha_app/features/ai_conversion/domain/models/politeness_level.dart';
import 'package:kotonoha_app/features/ai_conversion/presentation/widgets/ai_conversion_result_dialog.dart';

import '../support/contrast_helpers.dart';

/// 検証対象の3テーマ
final Map<String, ThemeData> _themes = {
  'ライト': lightTheme,
  'ダーク': darkTheme,
  '高コントラスト': highContrastTheme,
};

const String _originalText = '水 ぬるく';
const String _convertedText = 'お水をぬるめにしていただけますか。';
const PolitenessLevel _politenessLevel = PolitenessLevel.polite;

/// ダイアログの実描画背景色を取り出す
Color _dialogBackground(WidgetTester tester) {
  final material = tester.widget<Material>(
    find
        .descendant(
            of: find.byType(AlertDialog), matching: find.byType(Material))
        .first,
  );
  return material.color!;
}

Future<void> _pumpDialog(WidgetTester tester, ThemeData theme) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () => showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (_) => AIConversionResultDialog(
                originalText: _originalText,
                convertedText: _convertedText,
                politenessLevel: _politenessLevel,
                onAdopt: (_) {},
                onRegenerate: () {},
                onCancel: () {},
                onLevelChanged: (_) async => '',
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

/// 枠で囲んだボタン（[label] の OutlinedButton）の枠線
BorderSide _outlinedSide(WidgetTester tester, String label) {
  final button = tester.widget<OutlinedButton>(
    find.widgetWithText(OutlinedButton, label),
  );
  return button.style!.side!.resolve(<WidgetState>{})!;
}

/// 枠線は「隣接する色」に対して評価する（WCAG 1.4.11）。
/// ボックスの内外どちらに対しても見分けられる必要があるため、厳しい方で判定する。
double _adjacentBorderRatio(Color border, Color inside, Color outside) => [
      contrastRatio(border, inside),
      contrastRatio(border, outside)
    ].reduce((a, b) => a < b ? a : b);

void main() {
  group('変換結果ボックス', () {
    for (final entry in _themes.entries) {
      testWidgets('${entry.key}テーマで本文と枠線が基準を満たす', (tester) async {
        await _pumpDialog(tester, entry.value);

        // 枠線を持つ Container は変換結果ボックスだけ
        final boxFinder = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.decoration is BoxDecoration &&
                (w.decoration! as BoxDecoration).border != null,
          ),
        );
        expect(boxFinder, findsOneWidget, reason: '変換結果ボックスの特定が曖昧（構造変更の可能性）');

        final decoration =
            tester.widget<Container>(boxFinder).decoration! as BoxDecoration;
        final background = decoration.color!;
        final borderColor = decoration.border!.top.color;
        final body = resolvedTextColor(tester, find.text(_convertedText));
        final dialogBg = _dialogBackground(tester);

        expectOpaque(background, '${entry.key}テーマの結果ボックス背景');
        expectOpaque(borderColor, '${entry.key}テーマの結果ボックス枠線');
        expectOpaque(body, '${entry.key}テーマの結果本文');

        final bodyRatio = contrastRatio(body, background);
        expect(
          bodyRatio,
          greaterThanOrEqualTo(4.5),
          reason: '${entry.key}テーマの結果本文のコントラスト比が '
              '${bodyRatio.toStringAsFixed(2)}:1 で WCAG 2.1 AA (4.5:1) 未達',
        );

        final borderRatio =
            _adjacentBorderRatio(borderColor, background, dialogBg);
        expect(
          borderRatio,
          greaterThanOrEqualTo(3.0),
          reason: '${entry.key}テーマの結果ボックス枠線のコントラスト比（隣接色のうち厳しい方）が '
              '${borderRatio.toStringAsFixed(2)}:1 で非テキスト基準 (3:1) 未達',
        );
      });
    }
  });

  group('操作ボタン', () {
    for (final entry in _themes.entries) {
      for (final label in ['再生成', 'キャンセル']) {
        testWidgets('${entry.key}テーマで「$label」の枠線が 3:1 以上', (tester) async {
          await _pumpDialog(tester, entry.value);

          final side = _outlinedSide(tester, label);
          final dialogBg = _dialogBackground(tester);

          expectOpaque(side.color, '${entry.key}テーマの「$label」枠線');
          final ratio = contrastRatio(side.color, dialogBg);
          expect(
            ratio,
            greaterThanOrEqualTo(3.0),
            reason: '${entry.key}テーマの「$label」枠線のコントラスト比が '
                '${ratio.toStringAsFixed(2)}:1 で非テキスト基準 (3:1) 未達',
          );
        });

        // この回帰テストの理由: 枠線だけをAA対応にしてラベル色を
        // colorScheme.primary の既定に任せていたため、枠線 3:1 のテストは緑のまま
        // ラベルが 2.87:1（ライト）／3.62:1（ダーク）でAA未達だった。
        // 枠線と文字は別々に検証する。
        testWidgets('${entry.key}テーマで「$label」の文字が 4.5:1 以上', (tester) async {
          await _pumpDialog(tester, entry.value);

          final dialogBg = _dialogBackground(tester);
          final text = resolvedTextColor(tester, find.text(label));

          expectOpaque(dialogBg, '${entry.key}テーマのダイアログ背景');
          expectOpaque(text, '${entry.key}テーマの「$label」文字');

          final ratio = contrastRatio(text, dialogBg);
          expect(
            ratio,
            greaterThanOrEqualTo(4.5),
            reason: '${entry.key}テーマの「$label」の文字のコントラスト比が '
                '${ratio.toStringAsFixed(2)}:1 で WCAG 2.1 AA (4.5:1) 未達',
          );
        });
      }

      // 「再生成」を灰色の塗りにしていたため、押せないボタンやキャンセルに見えた
      // （iPad、2026-10-18）。操作は基本色の太い枠、取りやめは灰色の細い枠で見分ける。
      // 高コントラストは枠も文字も黒なので、太さで見分ける
      testWidgets('${entry.key}テーマで「再生成」と「キャンセル」の枠が見分けられる', (tester) async {
        await _pumpDialog(tester, entry.value);
        final regenerate = _outlinedSide(tester, '再生成');
        final cancel = _outlinedSide(tester, 'キャンセル');
        expect(
          regenerate.color != cancel.color ||
              regenerate.width >= cancel.width * 2,
          isTrue,
          reason: '再生成=$regenerate キャンセル=$cancel',
        );
      });

      // 押せないとき（丁寧さを選び直して待つ間）に基本色の枠のままだと、押せそうに見える
      testWidgets('${entry.key}テーマで押せない「再生成」の枠は基本色でない', (tester) async {
        await _pumpDialog(tester, entry.value);
        final enabled = _outlinedSide(tester, '再生成');
        final button = tester.widget<OutlinedButton>(
          find.widgetWithText(OutlinedButton, '再生成'),
        );
        final disabled =
            button.style!.side!.resolve(<WidgetState>{WidgetState.disabled})!;
        expect(disabled.color, isNot(enabled.color));
      });

      // テーマの既定の灰色の枠が、色で塗ったボタンにも付いていた（iPad、2026-10-18）
      testWidgets('${entry.key}テーマで「採用」の枠線は塗りと同じ色', (tester) async {
        await _pumpDialog(tester, entry.value);
        final finder = find.widgetWithText(ElevatedButton, '採用');
        final button = tester.widget<ElevatedButton>(finder);
        final side = (button.style?.side ??
                Theme.of(tester.element(finder))
                    .elevatedButtonTheme
                    .style
                    ?.side)!
            .resolve(<WidgetState>{})!;
        final background = tester
            .widget<Material>(
              find
                  .descendant(of: finder, matching: find.byType(Material))
                  .first,
            )
            .color!;
        expect(side.color, background);
      });

      // 丁寧さの3択（選択中の「丁寧」だけ色味を付けている）
      for (final label in [
        '採用',
        for (final level in PolitenessLevel.values) level.displayName,
      ]) {
        testWidgets('${entry.key}テーマで「$label」ボタンの文字が 4.5:1 以上', (tester) async {
          await _pumpDialog(tester, entry.value);

          final buttonFinder = find.widgetWithText(ElevatedButton, label);
          final background = tester
              .widget<Material>(
                find
                    .descendant(
                        of: buttonFinder, matching: find.byType(Material))
                    .first,
              )
              .color!;
          final text = resolvedTextColor(tester, find.text(label));

          expectOpaque(background, '${entry.key}テーマの「$label」ボタン背景');
          expectOpaque(text, '${entry.key}テーマの「$label」ボタン文字');

          final ratio = contrastRatio(text, background);
          expect(
            ratio,
            greaterThanOrEqualTo(4.5),
            reason: '${entry.key}テーマの「$label」ボタンのコントラスト比が '
                '${ratio.toStringAsFixed(2)}:1 で WCAG 2.1 AA (4.5:1) 未達',
          );
        });
      }
    }
  });
}
