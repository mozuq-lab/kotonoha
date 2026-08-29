/// コントラスト比ユーティリティの単体テスト
///
/// 【テスト対象】: lib/core/utils/contrast.dart
/// 【テスト目的】: 共通化した算出ロジックが WCAG 2.1 の定義どおりに
/// 動き、背景色に応じて最良の文字色を選べることを保証する。
///
/// 🔵 信頼性レベル: 青信号 - NFR（WCAG 2.1 AA）
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/utils/contrast.dart';

import '../../support/contrast_helpers.dart';

void main() {
  group('wcagContrastRatio', () {
    test('白と黒は最大値 21:1', () {
      expect(
          wcagContrastRatio(Colors.white, Colors.black), closeTo(21.0, 0.01));
    });

    test('同色は最小値 1:1', () {
      expect(wcagContrastRatio(Colors.white, Colors.white), closeTo(1.0, 0.01));
    });

    test('引数の順序を入れ替えても同じ値', () {
      const a = Color(0xFF2196F3);
      const b = Color(0xFFF5F5F5);
      expect(wcagContrastRatio(a, b), closeTo(wcagContrastRatio(b, a), 1e-9));
    });

    test('テスト側ヘルパー contrastRatio と完全に一致する', () {
      const samples = <Color>[
        Color(0xFFFF9800),
        Color(0xFF4CAF50),
        Color(0xFFD32F2F),
        Color(0xFF1E1E1E),
      ];
      for (final fg in samples) {
        for (final bg in samples) {
          expect(
            wcagContrastRatio(fg, bg),
            closeTo(contrastRatio(fg, bg), 1e-9),
            reason: '実装側とテスト側で算出式がずれている',
          );
        }
      }
    });
  });

  group('bestContrastingTextColor', () {
    test('明るい背景では黒を選ぶ', () {
      expect(bestContrastingTextColor(const Color(0xFFFF9800)), Colors.black);
      expect(bestContrastingTextColor(const Color(0xFFEF5350)), Colors.black);
    });

    test('暗い背景では白を選ぶ', () {
      expect(bestContrastingTextColor(const Color(0xFF1E1E1E)), Colors.white);
      expect(bestContrastingTextColor(const Color(0xFFD32F2F)), Colors.white);
    });

    test('半透明の背景色を渡すと assert で検出される', () {
      // computeLuminance() はアルファを無視するため、半透明のまま判定すると
      // 合成後の見え方と食い違う文字色を黙って返してしまう。
      expect(
        () => bestContrastingTextColor(
          const Color(0xFF2196F3).withValues(alpha: 0.5),
        ),
        throwsAssertionError,
      );
    });

    test('選んだ色は黒・白のうち必ずコントラスト比が高い方', () {
      const backgrounds = <Color>[
        Color(0xFFFF9800),
        Color(0xFF2196F3),
        Color(0xFF4CAF50),
        Color(0xFFD32F2F),
        Color(0xFFEF5350),
        Color(0xFFFF0000),
        Color(0xFF757575),
        Color(0xFFBDBDBD),
      ];
      for (final background in backgrounds) {
        final chosen = bestContrastingTextColor(background);
        final other = chosen == Colors.white ? Colors.black : Colors.white;
        expect(
          wcagContrastRatio(chosen, background),
          greaterThanOrEqualTo(wcagContrastRatio(other, background)),
          reason: '$background に対して不利な文字色を選んでいる',
        );
      }
    });
  });
}
