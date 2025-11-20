import 'package:flutter/material.dart';
import 'package:kotonoha_app/core/constants/app_colors.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';

/// Light theme configuration
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: AppColors.primaryLight,
    surface: AppColors.surfaceLight,
    onSurface: AppColors.onSurfaceLight,
    error: AppColors.emergency,
  ),
  scaffoldBackgroundColor: AppColors.backgroundLight,

  // Text theme
  textTheme: const TextTheme(
    bodyLarge: TextStyle(
      fontSize: AppSizes.fontSizeMedium,
      color: AppColors.onBackgroundLight,
    ),
    bodyMedium: TextStyle(
      fontSize: AppSizes.fontSizeMedium,
      color: AppColors.onBackgroundLight,
    ),
    titleLarge: TextStyle(
      fontSize: AppSizes.fontSizeLarge,
      fontWeight: FontWeight.bold,
      color: AppColors.onBackgroundLight,
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
