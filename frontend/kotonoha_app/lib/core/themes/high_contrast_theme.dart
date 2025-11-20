import 'package:flutter/material.dart';
import 'package:kotonoha_app/core/constants/app_colors.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';

/// High contrast theme configuration
/// WCAG 2.1 AA compliant (REQ-5006: Contrast ratio 4.5:1 or higher)
final ThemeData highContrastTheme = ThemeData(
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: AppColors.primaryHighContrast,
    surface: AppColors.surfaceHighContrast,
    onSurface: AppColors.onSurfaceHighContrast,
    error: AppColors.emergency,
    outline: Colors.black,
  ),
  scaffoldBackgroundColor: AppColors.backgroundHighContrast,

  // Text theme with high contrast
  textTheme: const TextTheme(
    bodyLarge: TextStyle(
      fontSize: AppSizes.fontSizeMedium,
      color: AppColors.onBackgroundHighContrast,
      fontWeight: FontWeight.w600, // Slightly bolder for better visibility
    ),
    bodyMedium: TextStyle(
      fontSize: AppSizes.fontSizeMedium,
      color: AppColors.onBackgroundHighContrast,
      fontWeight: FontWeight.w600,
    ),
    titleLarge: TextStyle(
      fontSize: AppSizes.fontSizeLarge,
      fontWeight: FontWeight.bold,
      color: AppColors.onBackgroundHighContrast,
    ),
  ),

  // Elevated button theme with high contrast borders
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      minimumSize: const Size(
        AppSizes.recommendedTapTarget,
        AppSizes.recommendedTapTarget,
      ),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      textStyle: const TextStyle(
        fontSize: AppSizes.fontSizeMedium,
        fontWeight: FontWeight.bold,
      ),
      side: const BorderSide(
        color: Colors.black,
        width: 2.0, // Thick border for high contrast
      ),
    ),
  ),

  // Icon button theme with high contrast
  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(
      minimumSize: const Size(
        AppSizes.minTapTarget,
        AppSizes.minTapTarget,
      ),
      foregroundColor: Colors.black,
    ),
  ),

  // Input decoration theme with high contrast borders
  inputDecorationTheme: const InputDecorationTheme(
    border: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.black, width: 2.0),
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.black, width: 2.0),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.black, width: 3.0),
    ),
  ),

  useMaterial3: true,
);
