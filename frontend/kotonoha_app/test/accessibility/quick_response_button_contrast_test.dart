/// 即答ボタンのコントラスト比回帰テスト
///
/// 【テスト対象】:
/// lib/features/quick_response/presentation/widgets/quick_response_button.dart
/// 【テスト目的】: 3テーマ × 全即答ボタンで WCAG 2.1 AA を満たし続けること、
/// および外部から任意の背景色を渡されても破綻しないことを保証する。
///
/// 【背景（レビュー指摘）】: 双子ウィジェットである StatusButton は
/// 「カテゴリ色は変えず、前景を背景輝度から選ぶ」方式に直された一方、
/// QuickResponseButton は `widget.textColor ?? Colors.white` のままだった。
/// home_screen は両者を同じ画面に並べて描画するため、見た目が同じ役割の
/// ボタンに2つの相反する規則が同居し、どちらに倣えばよいか分からなくなる。
///
/// さらに `backgroundColor` は public なパラメータなので、
/// `QuickResponseButton(backgroundColor: 明るい色)` と書くと
/// 白文字が明るい背景に載って AA 未達になる——StatusButton から
/// 取り除いたばかりの危険がそのまま残っていた。
///
/// 【設計判断】: StatusButton と同じ `bestContrastingTextColor()` に統一する。
/// 既定パレット（#2E7D32 / #C62828 / #616161）はいずれも暗色で、
/// この関数も白を選ぶため既定の見た目は変わらない。
///
/// 🔵 信頼性レベル: 青信号 - NFR（高コントラストモード WCAG 2.1 AA・4.5:1以上）
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kotonoha_app/core/themes/dark_theme.dart';
import 'package:kotonoha_app/core/themes/high_contrast_theme.dart';
import 'package:kotonoha_app/core/themes/light_theme.dart';
import 'package:kotonoha_app/features/quick_response/domain/quick_response_type.dart';
import 'package:kotonoha_app/features/quick_response/presentation/widgets/quick_response_button.dart';

import '../support/contrast_helpers.dart';

/// 検証対象の3テーマ
final Map<String, ThemeData> _themes = {
  'ライト': lightTheme,
  'ダーク': darkTheme,
  '高コントラスト': highContrastTheme,
};

Future<void> _pumpButton(
  WidgetTester tester,
  ThemeData theme,
  QuickResponseType type, {
  Color? backgroundColor,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(
        body: Center(
          child: QuickResponseButton(
            responseType: type,
            backgroundColor: backgroundColor,
            onPressed: () {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// 実際に描画されている背景色を取り出す。
Color _renderedBackground(WidgetTester tester) {
  return tester
      .widget<Material>(
        find
            .descendant(
              of: find.byType(ElevatedButton),
              matching: find.byType(Material),
            )
            .first,
      )
      .color!;
}

void _expectAA(WidgetTester tester, String themeName, String label) {
  final background = _renderedBackground(tester);
  final text = resolvedTextColor(tester, find.text(label));

  expectOpaque(background, '$themeNameテーマの「$label」背景');
  expectOpaque(text, '$themeNameテーマの「$label」文字');

  final ratio = contrastRatio(text, background);
  expect(
    ratio,
    greaterThanOrEqualTo(4.5),
    reason: '$themeNameテーマの「$label」のコントラスト比が '
        '${ratio.toStringAsFixed(2)}:1 で WCAG 2.1 AA (4.5:1) 未達',
  );
}

void main() {
  group('即答ボタンの文字色（既定パレット）', () {
    for (final entry in _themes.entries) {
      for (final type in QuickResponseType.values) {
        testWidgets('${entry.key}テーマ・「${type.label}」が 4.5:1 以上',
            (tester) async {
          await _pumpButton(tester, entry.value, type);
          _expectAA(tester, entry.key, type.label);
        });
      }
    }
  });

  group('即答ボタンの文字色（外部から背景色を渡した場合）', () {
    // 【このテストが本体である理由】: backgroundColor は public なパラメータなので、
    // 明るい色を渡されたときに白文字を固定していると黙って AA 未達になる。
    // StatusButton から取り除いた危険が双子側に残っていた、というのが指摘の要点。
    const brightBackgrounds = <String, Color>{
      '身体状態のオレンジ': Color(0xFFFF9800),
      '要求の青': Color(0xFF2196F3),
      '感情の緑': Color(0xFF4CAF50),
      '明るい黄': Color(0xFFFFEB3B),
    };

    for (final bg in brightBackgrounds.entries) {
      testWidgets('${bg.key}を渡しても 4.5:1 以上', (tester) async {
        await _pumpButton(
          tester,
          lightTheme,
          QuickResponseType.yes,
          backgroundColor: bg.value,
        );
        _expectAA(tester, 'ライト', QuickResponseType.yes.label);
      });
    }
  });

  group('既定パレットの見た目', () {
    testWidgets('既定パレットでは従来どおり白文字が選ばれる', (tester) async {
      // 【この確認の理由】: 前景の決定方式を変えた結果として既定の見た目まで
      // 変わっていないことを明示する（パレットは暗色なので白が選ばれる）。
      for (final type in QuickResponseType.values) {
        await _pumpButton(tester, lightTheme, type);
        expect(
          resolvedTextColor(tester, find.text(type.label)),
          equals(Colors.white),
          reason: '「${type.label}」の既定の文字色が白でなくなっている',
        );
      }
    });
  });
}
