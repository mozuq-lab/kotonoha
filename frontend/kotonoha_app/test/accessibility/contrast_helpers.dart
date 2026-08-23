/// コントラスト比検証の共通ヘルパー
///
/// 【ファイル目的】: WCAG 2.1 のコントラスト比を実際の描画色から算出する
/// 【判定基準】:
/// - テキスト（18px未満・太字でない）: 4.5:1 以上
/// - 非テキストUI要素（枠線・アイコン）: 3:1 以上
///
/// 🔵 信頼性レベル: 青信号 - NFR（高コントラストモード WCAG 2.1 AA・4.5:1以上）
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG 2.1 の相対輝度を算出する。
///
/// https://www.w3.org/TR/WCAG21/#dfn-relative-luminance
double relativeLuminance(Color color) {
  double channel(double value) {
    return value <= 0.03928
        ? value / 12.92
        : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
  }

  // Flutter 3.27以降の正規化済みコンポーネント（0.0〜1.0）を使用する。
  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

/// WCAG 2.1 のコントラスト比を算出する（1.0〜21.0）。
double contrastRatio(Color foreground, Color background) {
  final l1 = relativeLuminance(foreground);
  final l2 = relativeLuminance(background);
  final lighter = math.max(l1, l2);
  final darker = math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

/// 色が完全不透明であることを検証する。
///
/// コントラスト比は合成後の色で決まるため、アルファ値が1未満だと
/// この計算（合成前の色を使う）は実際より良い値を出してしまう。
/// 半透明色を使い始めた時点でテストが気付けるようにする。
void expectOpaque(Color color, String label) {
  expect(
    color.a,
    1.0,
    reason: '$label が半透明（alpha=${color.a}）。'
        'コントラスト比は合成後の色で決まるため、'
        'この計算では実際の値を保証できない',
  );
}

/// テキストの**解決済み**の色を取得する。
///
/// 【重要】: `tester.widget<Text>(...).style?.color` は、ウィジェットが色を
/// 明示していない場合に null を返す。色未指定でテーマから継承させるのは
/// まさに今回修正したバグの形（背景を固定しつつ前景をテーマ任せにする）なので、
/// 宣言値を読むとその状態を「測れずにクラッシュ」してしまい、
/// コントラスト値による回帰検出ができない。
///
/// RenderParagraph は DefaultTextStyle をマージした後の実際の描画スタイルを
/// 保持しているため、そこから解決済みの色を読む。
Color resolvedTextColor(WidgetTester tester, Finder finder) {
  final paragraph = tester.renderObject<RenderParagraph>(finder);
  final color = paragraph.text.style?.color;
  expect(
    color,
    isNotNull,
    reason: '解決済みのテキスト色を取得できなかった',
  );
  return color!;
}

/// アイコンの解決済みの色を取得する。
///
/// `Icon` も色未指定なら IconTheme から継承するため、同様に実際の描画値を読む。
Color resolvedIconColor(WidgetTester tester, IconData icon) {
  final widget = tester.widget<Icon>(find.byIcon(icon));
  final color =
      widget.color ?? IconTheme.of(tester.element(find.byIcon(icon))).color;
  expect(color, isNotNull, reason: '解決済みのアイコン色を取得できなかった');
  return color!;
}
