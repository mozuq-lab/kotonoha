/// ダークテーマのプロパティテスト
///
/// テストケース: TC-201〜TC-205
///
/// テスト対象: lib/core/themes/dark_theme.dart (実装済み)
///
/// 【TDD Redフェーズ】: テーマのプロパティを検証
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/constants/app_colors.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/core/themes/dark_theme.dart';

void main() {
  group('ダークテーマのプロパティテスト', () {
    /// TC-201: ダークテーマのbrightnessがdarkである
    ///
    /// 前提条件:
    /// - darkThemeがインポートされている
    ///
    /// 期待結果:
    /// - darkTheme.brightnessがBrightness.darkである
    test('TC-201: ダークテーマのbrightnessがdarkである', () {
      // Assert
      expect(darkTheme.brightness, equals(Brightness.dark));
    });

    /// TC-202: ダークテーマの背景色が暗い灰色系である
    ///
    /// 前提条件:
    /// - darkThemeがインポートされている
    ///
    /// 期待結果:
    /// - darkTheme.scaffoldBackgroundColorがAppColors.backgroundDark（#121212）である
    test('TC-202: ダークテーマの背景色が暗い灰色系である', () {
      // Assert
      expect(
          darkTheme.scaffoldBackgroundColor, equals(AppColors.backgroundDark));
      expect(
          darkTheme.scaffoldBackgroundColor, equals(const Color(0xFF121212)));
    });

    /// TC-203: ダークテーマのテキスト色が白系である
    ///
    /// 前提条件:
    /// - darkThemeがインポートされている
    ///
    /// 期待結果:
    /// - テキスト色がAppColors.onBackgroundDark（#FFFFFF）である
    test('TC-203: ダークテーマのテキスト色が白系である', () {
      // Assert
      expect(
        darkTheme.textTheme.bodyLarge?.color,
        equals(AppColors.onBackgroundDark),
      );
      expect(
        darkTheme.textTheme.bodyLarge?.color,
        equals(const Color(0xFFFFFFFF)),
      );
    });

    /// TC-204: ダークテーマのElevatedButton最小サイズが60pxである
    ///
    /// 前提条件:
    /// - darkThemeがインポートされている
    ///
    /// 期待結果:
    /// - minimumSizeがSize(60.0, 60.0)である
    test('TC-204: ダークテーマのElevatedButton最小サイズが60pxである', () {
      // Arrange
      final buttonStyle = darkTheme.elevatedButtonTheme.style;

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

    /// TC-205: ダークテーマのIconButton最小サイズが44pxである
    ///
    /// 前提条件:
    /// - darkThemeがインポートされている
    ///
    /// 期待結果:
    /// - minimumSizeがSize(44.0, 44.0)である
    test('TC-205: ダークテーマのIconButton最小サイズが44pxである', () {
      // Arrange
      final buttonStyle = darkTheme.iconButtonTheme.style;

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

    /// ダークテーマのプライマリ色が暗い青系である
    ///
    /// 期待結果:
    /// - darkTheme.colorScheme.primaryがAppColors.primaryDark（#1976D2）である
    test('ダークテーマのプライマリ色が暗い青系である', () {
      // Assert
      expect(darkTheme.colorScheme.primary, equals(AppColors.primaryDark));
      expect(darkTheme.colorScheme.primary, equals(const Color(0xFF1976D2)));
    });

    /// ダークテーマのフォントサイズがAppSizes.fontSizeMediumである
    ///
    /// 期待結果:
    /// - bodyMediumのfontSizeがAppSizes.fontSizeMedium（20.0）である
    test('ダークテーマのフォントサイズがAppSizes.fontSizeMediumである', () {
      // Assert
      expect(
        darkTheme.textTheme.bodyMedium?.fontSize,
        equals(AppSizes.fontSizeMedium),
      );
      expect(
        darkTheme.textTheme.bodyMedium?.fontSize,
        equals(20.0),
      );
    });

    /// ダークテーマでMaterial3が有効である
    ///
    /// 期待結果:
    /// - useMaterial3がtrueである
    test('ダークテーマでMaterial3が有効である', () {
      // Assert
      expect(darkTheme.useMaterial3, isTrue);
    });
  });
}
