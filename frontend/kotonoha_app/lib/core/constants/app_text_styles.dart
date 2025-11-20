import 'package:flutter/material.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';

/// Application text style constants
class AppTextStyles {
  // Private constructor to prevent instantiation
  AppTextStyles._();

  // Small font size styles
  static TextStyle get bodySmall => const TextStyle(
        fontSize: AppSizes.fontSizeSmall,
        fontWeight: FontWeight.normal,
      );

  static TextStyle get headingSmall => const TextStyle(
        fontSize: AppSizes.fontSizeSmall,
        fontWeight: FontWeight.bold,
      );

  // Medium font size styles (default)
  static TextStyle get bodyMedium => const TextStyle(
        fontSize: AppSizes.fontSizeMedium,
        fontWeight: FontWeight.normal,
      );

  static TextStyle get headingMedium => const TextStyle(
        fontSize: AppSizes.fontSizeMedium,
        fontWeight: FontWeight.bold,
      );

  // Large font size styles
  static TextStyle get bodyLarge => const TextStyle(
        fontSize: AppSizes.fontSizeLarge,
        fontWeight: FontWeight.normal,
      );

  static TextStyle get headingLarge => const TextStyle(
        fontSize: AppSizes.fontSizeLarge,
        fontWeight: FontWeight.bold,
      );

  // Extra large for character board
  static TextStyle get characterBoard => const TextStyle(
        fontSize: 32.0,
        fontWeight: FontWeight.bold,
      );

  // Button text styles
  static TextStyle get button => const TextStyle(
        fontSize: AppSizes.fontSizeMedium,
        fontWeight: FontWeight.bold,
      );

  static TextStyle get buttonLarge => const TextStyle(
        fontSize: AppSizes.fontSizeLarge,
        fontWeight: FontWeight.bold,
      );
}
