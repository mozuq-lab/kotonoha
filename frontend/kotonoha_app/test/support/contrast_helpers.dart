/// コントラスト比検証の共通ヘルパー
///
/// 【ファイル目的】: WCAG 2.1 のコントラスト比を実際の描画色から算出する
/// 【判定基準】:
/// - テキスト（18px未満・太字でない）: 4.5:1 以上
/// - 非テキストUI要素（枠線・アイコン）: 3:1 以上
///
/// 相対輝度は Flutter 組込みの `Color.computeLuminance()` を使う。
/// WCAG 2.1 の定義式と同一で、自前実装と完全に一致することを確認済み。
///
/// 🔵 信頼性レベル: 青信号 - NFR（高コントラストモード WCAG 2.1 AA・4.5:1以上）
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG 2.1 のコントラスト比を算出する（1.0〜21.0）。
double contrastRatio(Color foreground, Color background) {
  final l1 = foreground.computeLuminance();
  final l2 = background.computeLuminance();
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
/// 「背景を固定しつつ前景をテーマ任せにする」というバグの形そのものなので、
/// 宣言値を読むとその状態を測れずクラッシュし、回帰検出ができない。
///
/// RenderParagraph は DefaultTextStyle をマージした後の実際の描画スタイルを
/// 保持しているため、そこから解決済みの色を読む。
Color resolvedTextColor(WidgetTester tester, Finder finder) {
  final paragraph = tester.renderObject<RenderParagraph>(finder);
  final color = paragraph.text.style?.color;
  expect(color, isNotNull, reason: '解決済みのテキスト色を取得できなかった');
  return color!;
}

/// アイコンの解決済みの色を取得する。
///
/// `Icon` も色未指定なら IconTheme から継承するため、同様に実際の描画値を読む。
Color resolvedIconColor(WidgetTester tester, Finder finder) {
  final widget = tester.widget<Icon>(finder);
  final color = widget.color ?? IconTheme.of(tester.element(finder)).color;
  expect(color, isNotNull, reason: '解決済みのアイコン色を取得できなかった');
  return color!;
}

/// 2つの色が、実際に描画される8bit値として同一であることを検証する。
///
/// 【8bitに丸めて比べる理由】: Flutter の [Color] は各チャンネルを double で
/// 保持し、[Color.alphaBlend] も浮動小数で合成する。そのため「同じ色」を
/// 別経路で求めると 1/255 未満の差が残り、`equals()` では落ちてしまう。
/// 画面に出るのは8bitに量子化された値なので、そこで比較する。
void expectSameRenderedColor(Color actual, Color expected, String label) {
  int ch(double v) => (v * 255).round();
  expect(
    [ch(actual.r), ch(actual.g), ch(actual.b), ch(actual.a)],
    equals([ch(expected.r), ch(expected.g), ch(expected.b), ch(expected.a)]),
    reason: '$label が期待した色と異なる（実際: $actual / 期待: $expected）',
  );
}
