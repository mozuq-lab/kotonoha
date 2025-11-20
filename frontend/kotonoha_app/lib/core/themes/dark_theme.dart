import 'package:flutter/material.dart';
import 'package:kotonoha_app/core/constants/app_colors.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';

/// Dark theme configuration
final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.primaryDark,
    surface: AppColors.surfaceDark,
    onSurface: AppColors.onSurfaceDark,
    error: AppColors.emergency,
  ),
  scaffoldBackgroundColor: AppColors.backgroundDark,

  // Text theme
  textTheme: const TextTheme(
    bodyLarge: TextStyle(
      fontSize: AppSizes.fontSizeMedium,
      color: AppColors.onBackgroundDark,
    ),
    bodyMedium: TextStyle(
      fontSize: AppSizes.fontSizeMedium,
      color: AppColors.onBackgroundDark,
    ),
    titleLarge: TextStyle(
      fontSize: AppSizes.fontSizeLarge,
      fontWeight: FontWeight.bold,
      color: AppColors.onBackgroundDark,
    ),
  ),

  // Elevated button theme
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      minimumSize: const Size(
        AppSizes.recommendedTapTarget,
        AppSizes.recommendedTapTarget,
      ),
      textStyle: const TextStyle(
        fontSize: AppSizes.fontSizeMedium,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),

  // Icon button theme
  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(
      minimumSize: const Size(
        AppSizes.minTapTarget,
        AppSizes.minTapTarget,
      ),
    ),
  ),

  useMaterial3: true,
);
