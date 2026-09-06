/// コントラスト比ユーティリティ
///
/// 要件: REQ-5006（WCAG 2.1 AA準拠）、NFR（高コントラストモード 4.5:1以上）
/// 信頼性レベル: 青信号 - 要件定義書ベース
///
/// 「背景色を固定しつつ前景をテーマ継承にする」「前景を固定しつつ背景を
/// テーマ依存にする」というコントラスト破綻を防ぐための共通処理。
/// 前景色をハードコードする代わりに、実際の背景色から最良の文字色を
/// 都度算出することで、どのテーマでも基準を満たせるようにする。
library;

import 'package:flutter/material.dart';

/// WCAG 2.1 のコントラスト比を算出する（1.0〜21.0）
///
/// 計算式: `(L1 + 0.05) / (L2 + 0.05)`（L1 は明るい方の相対輝度）。
/// 相対輝度は Flutter 組込みの [Color.computeLuminance] を使う。
/// WCAG 2.1 の定義式と同一である。
///
/// 注意: 半透明色を渡しても合成は行わない。コントラスト比は合成後の
/// 色で決まるため、呼び出し側で不透明な色を渡すこと。
double wcagContrastRatio(Color a, Color b) {
  final luminanceA = a.computeLuminance();
  final luminanceB = b.computeLuminance();
  final lighter = luminanceA > luminanceB ? luminanceA : luminanceB;
  final darker = luminanceA > luminanceB ? luminanceB : luminanceA;
  return (lighter + 0.05) / (darker + 0.05);
}

/// 背景色に対してより高いコントラスト比を確保できる文字色（黒 or 白）を返す
///
/// 設計方針: テーマが提供する `onPrimary` / `onError` などの
/// 「on色」に頼らず、実際の背景色の相対輝度から黒・白のうち
/// コントラスト比が高い方を採用する。これにより、テーマ側の色定義や
/// テーマ切り替えに依存せず、どの背景色でも常に最良のコントラストを確保できる。
///
/// 適用対象: 背景色がテーマや状態によって変わるボタン・オーバーレイなど。
/// 背景・前景の双方を固定できる箇所では、この関数ではなく
/// 検証済みの色の組み合わせを直接指定してよい。
///
/// 前提: [background] は不透明であること。[Color.computeLuminance] は
/// アルファ値を無視するため、半透明色を渡すと合成後の実際の見え方とは
/// 異なる輝度で判定し、**黙って誤った文字色を返す**。
/// 呼び出し側が外部から背景色を受け取れる場合（例: StatusButton の
/// backgroundColor）に備え、デバッグビルドでは assert で検出する。
Color bestContrastingTextColor(Color background) {
  assert(
    background.a == 1.0,
    '半透明の背景色（alpha=${background.a}）が渡された。'
    'computeLuminance() はアルファを無視するため、合成後の色を'
    '自分で求めてから渡すこと。',
  );
  final whiteContrast = wcagContrastRatio(Colors.white, background);
  final blackContrast = wcagContrastRatio(Colors.black, background);
  return whiteContrast >= blackContrast ? Colors.white : Colors.black;
}
