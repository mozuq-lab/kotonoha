/// 高コントラストテーマのプロパティテスト
///
/// テストケース: TC-301〜TC-306, TC-401〜TC-403
///
/// テスト対象: lib/core/themes/high_contrast_theme.dart (実装済み)
///
/// 【TDD Redフェーズ】: テーマのプロパティとWCAG準拠を検証
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/constants/app_colors.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/core/themes/high_contrast_theme.dart';

/// WCAG 2.1に準拠したコントラスト比を計算する関数
///
/// 相対輝度（relative luminance）を計算し、
/// 2つの色のコントラスト比を算出する。
///
/// 参照: https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html
double calculateContrastRatio(Color foreground, Color background) {
  final luminance1 = _calculateRelativeLuminance(foreground);
  final luminance2 = _calculateRelativeLuminance(background);

  final lighter = math.max(luminance1, luminance2);
  final darker = math.min(luminance1, luminance2);

  return (lighter + 0.05) / (darker + 0.05);
}

/// 色の相対輝度を計算する
///
/// sRGB色空間からリニア空間への変換を行い、
/// 相対輝度を算出する。
double _calculateRelativeLuminance(Color color) {
  // Flutter 3.38+では color.red/green/blue は非推奨。
  // 代わりに color.r/g/b (0.0-1.0の範囲) を使用する。
  final r = _linearize(color.r);
  final g = _linearize(color.g);
  final b = _linearize(color.b);

  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/// sRGB値をリニア空間に変換する
double _linearize(double value) {
  if (value <= 0.03928) {
    return value / 12.92;
  }
  return math.pow((value + 0.055) / 1.055, 2.4).toDouble();
}

void main() {
  group('高コントラストテーマのプロパティテスト', () {
    /// TC-301: 高コントラストテーマの背景色が純白である
    ///
    /// 前提条件:
    /// - highContrastThemeがインポートされている
    ///
    /// 期待結果:
    /// - highContrastTheme.scaffoldBackgroundColorがAppColors.backgroundHighContrast（#FFFFFF）である
    test('TC-301: 高コントラストテーマの背景色が純白である', () {
      // Assert
      expect(
        highContrastTheme.scaffoldBackgroundColor,
        equals(AppColors.backgroundHighContrast),
      );
      expect(
        highContrastTheme.scaffoldBackgroundColor,
        equals(const Color(0xFFFFFFFF)),
      );
    });

    /// TC-302: 高コントラストテーマのテキスト色が純黒である
    ///
    /// 前提条件:
    /// - highContrastThemeがインポートされている
    ///
    /// 期待結果:
    /// - テキスト色がAppColors.onBackgroundHighContrast（#000000）である
    test('TC-302: 高コントラストテーマのテキスト色が純黒である', () {
      // Assert
      expect(
        highContrastTheme.textTheme.bodyLarge?.color,
        equals(AppColors.onBackgroundHighContrast),
      );
      expect(
        highContrastTheme.textTheme.bodyLarge?.color,
        equals(const Color(0xFF000000)),
      );
    });

    /// TC-303: 高コントラストテーマのElevatedButtonボーダーが2px以上である
    ///
    /// 前提条件:
    /// - highContrastThemeがインポートされている
    ///
    /// 期待結果:
    /// - ボーダー幅が2.0px以上である
    /// - ボーダー色が黒（Colors.black）である
    test('TC-303: 高コントラストテーマのElevatedButtonボーダーが2px以上である', () {
      // Arrange
      final buttonStyle = highContrastTheme.elevatedButtonTheme.style;

      // Assert
      expect(buttonStyle, isNotNull);

      // sideを取得
      final side = buttonStyle?.side?.resolve({});

      expect(side, isNotNull);
      expect(side?.width, greaterThanOrEqualTo(2.0));
      expect(side?.color, equals(Colors.black));
    });

    /// TC-304: 高コントラストテーマのInputFieldボーダーが2px以上である
    ///
    /// 前提条件:
    /// - highContrastThemeがインポートされている
    ///
    /// 期待結果:
    /// - enabledBorderのボーダー幅が2.0px以上である
    /// - ボーダー色が黒（Colors.black）である
    test('TC-304: 高コントラストテーマのInputFieldボーダーが2px以上である', () {
      // Arrange
      final inputTheme = highContrastTheme.inputDecorationTheme;
      final enabledBorder = inputTheme.enabledBorder;

      // Assert
      expect(enabledBorder, isNotNull);
      expect(enabledBorder, isA<OutlineInputBorder>());

      final outlineBorder = enabledBorder as OutlineInputBorder;
      expect(outlineBorder.borderSide.width, greaterThanOrEqualTo(2.0));
      expect(outlineBorder.borderSide.color, equals(Colors.black));
    });

    /// TC-305: 高コントラストテーマのElevatedButton最小サイズが60pxである
    ///
    /// 前提条件:
    /// - highContrastThemeがインポートされている
    ///
    /// 期待結果:
    /// - minimumSizeがSize(60.0, 60.0)である
    test('TC-305: 高コントラストテーマのElevatedButton最小サイズが60pxである', () {
      // Arrange
      final buttonStyle = highContrastTheme.elevatedButtonTheme.style;

      // Assert
      expect(buttonStyle, isNotNull);

      // minimumSizeを取得
      final minimumSize = buttonStyle?.minimumSize?.resolve({});

      expect(minimumSize, isNotNull);
      expect(minimumSize?.width, equals(AppSizes.recommendedTapTarget));
      expect(minimumSize?.height, equals(AppSizes.recommendedTapTarget));
      expect(minimumSize?.width, greaterThanOrEqualTo(60.0));
      expect(minimumSize?.height, greaterThanOrEqualTo(60.0));
    });

    /// TC-306: 高コントラストテーマのIconButton最小サイズが44pxである
    ///
    /// 前提条件:
    /// - highContrastThemeがインポートされている
    ///
    /// 期待結果:
    /// - minimumSizeがSize(44.0, 44.0)である
    test('TC-306: 高コントラストテーマのIconButton最小サイズが44pxである', () {
      // Arrange
      final buttonStyle = highContrastTheme.iconButtonTheme.style;

      // Assert
      expect(buttonStyle, isNotNull);

      // minimumSizeを取得
      final minimumSize = buttonStyle?.minimumSize?.resolve({});

      expect(minimumSize, isNotNull);
      expect(minimumSize?.width, equals(AppSizes.minTapTarget));
      expect(minimumSize?.height, equals(AppSizes.minTapTarget));
      expect(minimumSize?.width, greaterThanOrEqualTo(44.0));
      expect(minimumSize?.height, greaterThanOrEqualTo(44.0));
    });

    /// 高コントラストテーマのフォントサイズがAppSizes.fontSizeMediumである
    ///
    /// 期待結果:
    /// - bodyMediumのfontSizeがAppSizes.fontSizeMedium（20.0）である
    test('高コントラストテーマのフォントサイズがAppSizes.fontSizeMediumである', () {
      // Assert
      expect(
        highContrastTheme.textTheme.bodyMedium?.fontSize,
        equals(AppSizes.fontSizeMedium),
      );
      expect(
        highContrastTheme.textTheme.bodyMedium?.fontSize,
        equals(20.0),
      );
    });

    /// 高コントラストテーマでMaterial3が有効である
    ///
    /// 期待結果:
    /// - useMaterial3がtrueである
    test('高コントラストテーマでMaterial3が有効である', () {
      // Assert
      expect(highContrastTheme.useMaterial3, isTrue);
    });

    /// 高コントラストテーマのボタン背景色が白である
    test('高コントラストテーマのボタン背景色が白である', () {
      // Arrange
      final buttonStyle = highContrastTheme.elevatedButtonTheme.style;
      final backgroundColor = buttonStyle?.backgroundColor?.resolve({});

      // Assert
      expect(backgroundColor, equals(Colors.white));
    });

    /// 高コントラストテーマのボタンテキスト色が黒である
    test('高コントラストテーマのボタンテキスト色が黒である', () {
      // Arrange
      final buttonStyle = highContrastTheme.elevatedButtonTheme.style;
      final foregroundColor = buttonStyle?.foregroundColor?.resolve({});

      // Assert
      expect(foregroundColor, equals(Colors.black));
    });
  });

  group('WCAG準拠（コントラスト比）のテスト', () {
    /// TC-401: 高コントラストテーマのテキスト/背景コントラスト比が4.5:1以上である
    ///
    /// 前提条件:
    /// - highContrastThemeがインポートされている
    /// - コントラスト比計算関数が実装されている
    ///
    /// 期待結果:
    /// - コントラスト比が4.5:1以上である（実際は21:1）
    /// - WCAG 2.1 AAレベルの要件を満たす
    test('TC-401: 高コントラストテーマのテキスト/背景コントラスト比が4.5:1以上である', () {
      // Arrange
      final backgroundColor = highContrastTheme.scaffoldBackgroundColor;
      final textColor = highContrastTheme.textTheme.bodyLarge?.color;

      // Assert
      expect(textColor, isNotNull);

      final contrastRatio = calculateContrastRatio(textColor!, backgroundColor);

      // WCAG 2.1 AAレベル: 4.5:1以上
      expect(contrastRatio, greaterThanOrEqualTo(4.5));

      // 純白と純黒の組み合わせは21:1のコントラスト比
      expect(contrastRatio, closeTo(21.0, 0.1));
    });

    /// TC-402: 高コントラストテーマのボタン背景/テキストコントラスト比が4.5:1以上である
    ///
    /// 前提条件:
    /// - highContrastThemeがインポートされている
    /// - コントラスト比計算関数が実装されている
    ///
    /// 期待結果:
    /// - コントラスト比が4.5:1以上である（白背景に黒テキストで21:1）
    /// - WCAG 2.1 AAレベルの要件を満たす
    test('TC-402: 高コントラストテーマのボタン背景/テキストコントラスト比が4.5:1以上である', () {
      // Arrange
      final buttonStyle = highContrastTheme.elevatedButtonTheme.style;
      final backgroundColor = buttonStyle?.backgroundColor?.resolve({});
      final foregroundColor = buttonStyle?.foregroundColor?.resolve({});

      // Assert
      expect(backgroundColor, isNotNull);
      expect(foregroundColor, isNotNull);

      final contrastRatio =
          calculateContrastRatio(foregroundColor!, backgroundColor!);

      // WCAG 2.1 AAレベル: 4.5:1以上
      expect(contrastRatio, greaterThanOrEqualTo(4.5));

      // 白背景に黒テキストは21:1のコントラスト比
      expect(contrastRatio, closeTo(21.0, 0.1));
    });

    /// TC-403: 高コントラストテーマのボーダー/背景コントラスト比が3:1以上である
    ///
    /// 前提条件:
    /// - highContrastThemeがインポートされている
    /// - コントラスト比計算関数が実装されている
    ///
    /// 期待結果:
    /// - コントラスト比が3:1以上である（UIコンポーネント要件）
    /// - WCAG 2.1 AA UIコンポーネント要件を満たす
    test('TC-403: 高コントラストテーマのボーダー/背景コントラスト比が3:1以上である', () {
      // Arrange
      final backgroundColor = highContrastTheme.scaffoldBackgroundColor;
      final outlineColor = highContrastTheme.colorScheme.outline;

      // Assert
      final contrastRatio =
          calculateContrastRatio(outlineColor, backgroundColor);

      // WCAG 2.1 AA UIコンポーネント要件: 3:1以上
      expect(contrastRatio, greaterThanOrEqualTo(3.0));

      // 白背景に黒ボーダーは21:1のコントラスト比
      expect(contrastRatio, closeTo(21.0, 0.1));
    });

    /// コントラスト比計算関数の検証テスト
    test('コントラスト比計算関数が正しく動作する', () {
      // 純白と純黒のコントラスト比は21:1
      final whiteBlackRatio =
          calculateContrastRatio(Colors.white, Colors.black);
      expect(whiteBlackRatio, closeTo(21.0, 0.1));

      // 同じ色のコントラスト比は1:1
      final sameColorRatio = calculateContrastRatio(Colors.white, Colors.white);
      expect(sameColorRatio, closeTo(1.0, 0.01));

      // グレーと白のコントラスト比
      final grayWhiteRatio = calculateContrastRatio(Colors.grey, Colors.white);
      expect(grayWhiteRatio, greaterThan(1.0));
    });
  });
}
