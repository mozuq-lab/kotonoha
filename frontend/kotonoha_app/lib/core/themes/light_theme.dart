/// ライトテーマ設定
///
/// TASK-0016: テーマ実装（ライト・ダーク・高コントラスト）
/// 要件: REQ-803（テーマ設定）
/// 信頼性レベル: 🔵 青信号（要件定義書ベース）
///
/// ライトモード用のThemeData設定。
/// - 明るい背景色と暗いテキスト色
/// - アクセシビリティ要件に準拠したタップターゲットサイズ
/// - Material 3デザインシステム準拠
library;

import 'package:flutter/material.dart';
import 'package:kotonoha_app/core/constants/app_colors.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';

/// ライトテーマの定義
///
/// アクセシビリティ要件:
/// - タップターゲットサイズ: 最小44px x 44px、推奨60px x 60px
/// - フォントサイズ: AppSizesの定義に従う
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: AppColors.primaryLight,
    // primary(#2196F3)上の白文字は約3.1:1でAA不足のため、
    // onPrimaryを黒(#000000)に設定（コントラスト比 約6.7:1でAA適合）。
    onPrimary: AppColors.onPrimaryLight,
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

  // Text button theme
  // 【AA対応】: ダイアログ等のTextButtonは既定36pxでタップターゲット不足のため44pxを保証。
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      minimumSize: const Size(
        AppSizes.minTapTarget,
        AppSizes.minTapTarget,
      ),
    ),
  ),

  useMaterial3: true,
);
