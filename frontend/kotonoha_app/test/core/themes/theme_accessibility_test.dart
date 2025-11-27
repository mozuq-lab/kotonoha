/// アクセシビリティ要件テスト
///
/// テストケース: TC-501〜TC-503
///
/// テスト対象:
/// - lib/core/themes/light_theme.dart
/// - lib/core/themes/dark_theme.dart
/// - lib/core/themes/high_contrast_theme.dart
///
/// 【TDD Redフェーズ】: 全テーマ共通のアクセシビリティ要件を検証
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/core/themes/dark_theme.dart';
import 'package:kotonoha_app/core/themes/high_contrast_theme.dart';
import 'package:kotonoha_app/core/themes/light_theme.dart';

void main() {
  group('アクセシビリティ要件テスト', () {
    /// TC-501: 全テーマでElevatedButtonの最小サイズが60px以上である
    ///
    /// 前提条件:
    /// - lightTheme、darkTheme、highContrastThemeがインポートされている
    ///
    /// 期待結果:
    /// - lightTheme.elevatedButtonTheme.style.minimumSize >= 60px x 60px
    /// - darkTheme.elevatedButtonTheme.style.minimumSize >= 60px x 60px
    /// - highContrastTheme.elevatedButtonTheme.style.minimumSize >= 60px x 60px
    group('TC-501: 全テーマでElevatedButtonの最小サイズが60px以上である', () {
      test('ライトテーマのElevatedButton最小サイズが60px以上である', () {
        // Arrange
        final buttonStyle = lightTheme.elevatedButtonTheme.style;
        final minimumSize = buttonStyle?.minimumSize?.resolve({});

        // Assert
        expect(minimumSize, isNotNull);
        expect(minimumSize?.width, greaterThanOrEqualTo(60.0));
        expect(minimumSize?.height, greaterThanOrEqualTo(60.0));
      });

      test('ダークテーマのElevatedButton最小サイズが60px以上である', () {
        // Arrange
        final buttonStyle = darkTheme.elevatedButtonTheme.style;
        final minimumSize = buttonStyle?.minimumSize?.resolve({});

        // Assert
        expect(minimumSize, isNotNull);
        expect(minimumSize?.width, greaterThanOrEqualTo(60.0));
        expect(minimumSize?.height, greaterThanOrEqualTo(60.0));
      });

      test('高コントラストテーマのElevatedButton最小サイズが60px以上である', () {
        // Arrange
        final buttonStyle = highContrastTheme.elevatedButtonTheme.style;
        final minimumSize = buttonStyle?.minimumSize?.resolve({});

        // Assert
        expect(minimumSize, isNotNull);
        expect(minimumSize?.width, greaterThanOrEqualTo(60.0));
        expect(minimumSize?.height, greaterThanOrEqualTo(60.0));
      });

      test('全テーマでElevatedButton最小サイズがAppSizes.recommendedTapTargetと一致する', () {
        // Arrange
        final lightMinSize =
            lightTheme.elevatedButtonTheme.style?.minimumSize?.resolve({});
        final darkMinSize =
            darkTheme.elevatedButtonTheme.style?.minimumSize?.resolve({});
        final highContrastMinSize = highContrastTheme
            .elevatedButtonTheme.style?.minimumSize
            ?.resolve({});

        // Assert - 全テーマで同じサイズ
        expect(lightMinSize?.width, equals(AppSizes.recommendedTapTarget));
        expect(lightMinSize?.height, equals(AppSizes.recommendedTapTarget));
        expect(darkMinSize?.width, equals(AppSizes.recommendedTapTarget));
        expect(darkMinSize?.height, equals(AppSizes.recommendedTapTarget));
        expect(
            highContrastMinSize?.width, equals(AppSizes.recommendedTapTarget));
        expect(
            highContrastMinSize?.height, equals(AppSizes.recommendedTapTarget));
      });
    });

    /// TC-502: 全テーマでIconButtonの最小サイズが44px以上である
    ///
    /// 前提条件:
    /// - lightTheme、darkTheme、highContrastThemeがインポートされている
    ///
    /// 期待結果:
    /// - lightTheme.iconButtonTheme.style.minimumSize >= 44px x 44px
    /// - darkTheme.iconButtonTheme.style.minimumSize >= 44px x 44px
    /// - highContrastTheme.iconButtonTheme.style.minimumSize >= 44px x 44px
    group('TC-502: 全テーマでIconButtonの最小サイズが44px以上である', () {
      test('ライトテーマのIconButton最小サイズが44px以上である', () {
        // Arrange
        final buttonStyle = lightTheme.iconButtonTheme.style;
        final minimumSize = buttonStyle?.minimumSize?.resolve({});

        // Assert
        expect(minimumSize, isNotNull);
        expect(minimumSize?.width, greaterThanOrEqualTo(44.0));
        expect(minimumSize?.height, greaterThanOrEqualTo(44.0));
      });

      test('ダークテーマのIconButton最小サイズが44px以上である', () {
        // Arrange
        final buttonStyle = darkTheme.iconButtonTheme.style;
        final minimumSize = buttonStyle?.minimumSize?.resolve({});

        // Assert
        expect(minimumSize, isNotNull);
        expect(minimumSize?.width, greaterThanOrEqualTo(44.0));
        expect(minimumSize?.height, greaterThanOrEqualTo(44.0));
      });

      test('高コントラストテーマのIconButton最小サイズが44px以上である', () {
        // Arrange
        final buttonStyle = highContrastTheme.iconButtonTheme.style;
        final minimumSize = buttonStyle?.minimumSize?.resolve({});

        // Assert
        expect(minimumSize, isNotNull);
        expect(minimumSize?.width, greaterThanOrEqualTo(44.0));
        expect(minimumSize?.height, greaterThanOrEqualTo(44.0));
      });

      test('全テーマでIconButton最小サイズがAppSizes.minTapTargetと一致する', () {
        // Arrange
        final lightMinSize =
            lightTheme.iconButtonTheme.style?.minimumSize?.resolve({});
        final darkMinSize =
            darkTheme.iconButtonTheme.style?.minimumSize?.resolve({});
        final highContrastMinSize =
            highContrastTheme.iconButtonTheme.style?.minimumSize?.resolve({});

        // Assert - 全テーマで同じサイズ
        expect(lightMinSize?.width, equals(AppSizes.minTapTarget));
        expect(lightMinSize?.height, equals(AppSizes.minTapTarget));
        expect(darkMinSize?.width, equals(AppSizes.minTapTarget));
        expect(darkMinSize?.height, equals(AppSizes.minTapTarget));
        expect(highContrastMinSize?.width, equals(AppSizes.minTapTarget));
        expect(highContrastMinSize?.height, equals(AppSizes.minTapTarget));
      });
    });

    /// TC-503: 全テーマで同じフォントサイズが使用されている
    ///
    /// 前提条件:
    /// - lightTheme、darkTheme、highContrastThemeがインポートされている
    ///
    /// 期待結果:
    /// - 全テーマでbodyMediumのフォントサイズがAppSizes.fontSizeMedium（20px）である
    /// - テーマ間でフォントサイズの一貫性が保たれている
    group('TC-503: 全テーマで同じフォントサイズが使用されている', () {
      test('ライトテーマのbodyMediumフォントサイズがAppSizes.fontSizeMediumである', () {
        // Assert
        expect(
          lightTheme.textTheme.bodyMedium?.fontSize,
          equals(AppSizes.fontSizeMedium),
        );
      });

      test('ダークテーマのbodyMediumフォントサイズがAppSizes.fontSizeMediumである', () {
        // Assert
        expect(
          darkTheme.textTheme.bodyMedium?.fontSize,
          equals(AppSizes.fontSizeMedium),
        );
      });

      test('高コントラストテーマのbodyMediumフォントサイズがAppSizes.fontSizeMediumである', () {
        // Assert
        expect(
          highContrastTheme.textTheme.bodyMedium?.fontSize,
          equals(AppSizes.fontSizeMedium),
        );
      });

      test('全テーマでbodyMediumのフォントサイズが一致する', () {
        // Arrange
        final lightFontSize = lightTheme.textTheme.bodyMedium?.fontSize;
        final darkFontSize = darkTheme.textTheme.bodyMedium?.fontSize;
        final highContrastFontSize =
            highContrastTheme.textTheme.bodyMedium?.fontSize;

        // Assert - 全テーマで同じフォントサイズ
        expect(lightFontSize, equals(darkFontSize));
        expect(darkFontSize, equals(highContrastFontSize));
        expect(lightFontSize, equals(20.0));
      });

      test('全テーマでbodyLargeのフォントサイズが一致する', () {
        // Arrange
        final lightFontSize = lightTheme.textTheme.bodyLarge?.fontSize;
        final darkFontSize = darkTheme.textTheme.bodyLarge?.fontSize;
        final highContrastFontSize =
            highContrastTheme.textTheme.bodyLarge?.fontSize;

        // Assert - 全テーマで同じフォントサイズ
        expect(lightFontSize, equals(darkFontSize));
        expect(darkFontSize, equals(highContrastFontSize));
      });

      test('全テーマでtitleLargeのフォントサイズが一致する', () {
        // Arrange
        final lightFontSize = lightTheme.textTheme.titleLarge?.fontSize;
        final darkFontSize = darkTheme.textTheme.titleLarge?.fontSize;
        final highContrastFontSize =
            highContrastTheme.textTheme.titleLarge?.fontSize;

        // Assert - 全テーマで同じフォントサイズ
        expect(lightFontSize, equals(darkFontSize));
        expect(darkFontSize, equals(highContrastFontSize));
        expect(lightFontSize, equals(AppSizes.fontSizeLarge));
      });
    });

    /// AppSizes定数のテスト
    group('AppSizes定数のテスト', () {
      test('AppSizes.minTapTargetが44px以上である', () {
        // Assert
        expect(AppSizes.minTapTarget, greaterThanOrEqualTo(44.0));
        expect(AppSizes.minTapTarget, equals(44.0));
      });

      test('AppSizes.recommendedTapTargetが60px以上である', () {
        // Assert
        expect(AppSizes.recommendedTapTarget, greaterThanOrEqualTo(60.0));
        expect(AppSizes.recommendedTapTarget, equals(60.0));
      });

      test('フォントサイズ定数が小(16px)・中(20px)・大(24px)である', () {
        // Assert
        expect(AppSizes.fontSizeSmall, equals(16.0));
        expect(AppSizes.fontSizeMedium, equals(20.0));
        expect(AppSizes.fontSizeLarge, equals(24.0));
      });

      test('文字盤ボタンサイズがrecommendedTapTarget以上である', () {
        // Assert
        expect(
          AppSizes.characterBoardButtonSize,
          greaterThanOrEqualTo(AppSizes.recommendedTapTarget),
        );
      });
    });

    /// 全テーマでMaterial3が有効であることを確認
    group('Material3の有効化テスト', () {
      test('全テーマでMaterial3が有効である', () {
        // Assert
        expect(lightTheme.useMaterial3, isTrue);
        expect(darkTheme.useMaterial3, isTrue);
        expect(highContrastTheme.useMaterial3, isTrue);
      });
    });
  });
}
