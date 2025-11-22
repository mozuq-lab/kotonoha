/// ダークテーマ設定
///
/// TASK-0016: テーマ実装（ライト・ダーク・高コントラスト）
/// 要件: REQ-803（テーマ設定）
/// 信頼性レベル: 🔵 青信号（要件定義書ベース）
///
/// ダークモード用のThemeData設定。
/// - 暗い背景色と明るいテキスト色
/// - 目の疲れを軽減するカラースキーム
/// - アクセシビリティ要件に準拠したタップターゲットサイズ
/// - Material 3デザインシステム準拠
library;

import 'package:flutter/material.dart';
import 'package:kotonoha_app/core/constants/app_colors.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';

/// ダークテーマの定義
///
/// アクセシビリティ要件:
/// - タップターゲットサイズ: 最小44px x 44px、推奨60px x 60px
/// - フォントサイズ: AppSizesの定義に従う
/// - 暗い背景に白いテキストで十分なコントラストを確保
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
