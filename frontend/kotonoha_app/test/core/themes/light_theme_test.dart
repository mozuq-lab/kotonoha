/// ライトテーマのプロパティテスト
///
/// テストケース: TC-101〜TC-105
///
/// テスト対象: lib/core/themes/light_theme.dart (実装済み)
///
/// 【TDD Redフェーズ】: テーマのプロパティを検証
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/constants/app_colors.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/core/themes/light_theme.dart';

void main() {
  group('ライトテーマのプロパティテスト', () {
    /// TC-101: ライトテーマのbrightnessがlightである
    ///
    /// 前提条件:
    /// - lightThemeがインポートされている
    ///
    /// 期待結果:
    /// - lightTheme.brightnessがBrightness.lightである
    test('TC-101: ライトテーマのbrightnessがlightである', () {
      // Assert
      expect(lightTheme.brightness, equals(Brightness.light));
    });

    /// TC-102: ライトテーマの背景色が白系である
    ///
    /// 前提条件:
    /// - lightThemeがインポートされている
    ///
    /// 期待結果:
    /// - lightTheme.scaffoldBackgroundColorがAppColors.backgroundLight（#FFFFFF）である
    test('TC-102: ライトテーマの背景色が白系である', () {
      // Assert
      expect(lightTheme.scaffoldBackgroundColor, equals(AppColors.backgroundLight));
      expect(lightTheme.scaffoldBackgroundColor, equals(const Color(0xFFFFFFFF)));
    });

    /// TC-103: ライトテーマのプライマリ色が青系である
    ///
    /// 前提条件:
    /// - lightThemeがインポートされている
    ///
    /// 期待結果:
    /// - lightTheme.colorScheme.primaryがAppColors.primaryLight（#2196F3）である
    test('TC-103: ライトテーマのプライマリ色が青系である', () {
      // Assert
      expect(lightTheme.colorScheme.primary, equals(AppColors.primaryLight));
      expect(lightTheme.colorScheme.primary, equals(const Color(0xFF2196F3)));
    });

    /// TC-104: ライトテーマのElevatedButton最小サイズが60pxである
    ///
    /// 前提条件:
    /// - lightThemeがインポートされている
    ///
    /// 期待結果:
    /// - minimumSizeがSize(60.0, 60.0)である
    test('TC-104: ライトテーマのElevatedButton最小サイズが60pxである', () {
      // Arrange
      final buttonStyle = lightTheme.elevatedButtonTheme.style;

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

    /// TC-105: ライトテーマのIconButton最小サイズが44pxである
    ///
    /// 前提条件:
    /// - lightThemeがインポートされている
    ///
    /// 期待結果:
    /// - minimumSizeがSize(44.0, 44.0)である
    test('TC-105: ライトテーマのIconButton最小サイズが44pxである', () {
      // Arrange
      final buttonStyle = lightTheme.iconButtonTheme.style;

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

    /// ライトテーマのテキスト色が黒系である
    ///
    /// 期待結果:
    /// - bodyLargeの色がAppColors.onBackgroundLight（#000000）である
    test('ライトテーマのテキスト色が黒系である', () {
      // Assert
      expect(
        lightTheme.textTheme.bodyLarge?.color,
        equals(AppColors.onBackgroundLight),
      );
      expect(
        lightTheme.textTheme.bodyLarge?.color,
        equals(const Color(0xFF000000)),
      );
    });

    /// ライトテーマのフォントサイズがAppSizes.fontSizeMediumである
    ///
    /// 期待結果:
    /// - bodyMediumのfontSizeがAppSizes.fontSizeMedium（20.0）である
    test('ライトテーマのフォントサイズがAppSizes.fontSizeMediumである', () {
      // Assert
      expect(
        lightTheme.textTheme.bodyMedium?.fontSize,
        equals(AppSizes.fontSizeMedium),
      );
      expect(
        lightTheme.textTheme.bodyMedium?.fontSize,
        equals(20.0),
      );
    });

    /// ライトテーマでMaterial3が有効である
    ///
    /// 期待結果:
    /// - useMaterial3がtrueである
    test('ライトテーマでMaterial3が有効である', () {
      // Assert
      expect(lightTheme.useMaterial3, isTrue);
    });
  });
}
