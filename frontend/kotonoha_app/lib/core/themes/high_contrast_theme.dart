/// 高コントラストテーマ設定
///
/// TASK-0016: テーマ実装（ライト・ダーク・高コントラスト）
/// 要件: REQ-803（テーマ設定）、REQ-5006（WCAG 2.1 AA準拠）
/// 信頼性レベル: 🔵 青信号（要件定義書ベース）
///
/// 視覚障害を持つユーザー向けの高コントラストテーマ。
/// - WCAG 2.1 AAレベル準拠（コントラスト比4.5:1以上）
/// - 白背景に黒テキストで最大のコントラスト
/// - 太い境界線で要素の区別を明確化
/// - ボタンや入力フィールドに明確な輪郭
/// - Material 3デザインシステム準拠
library;

import 'package:flutter/material.dart';
import 'package:kotonoha_app/core/constants/app_colors.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';

/// 高コントラストテーマの定義
///
/// アクセシビリティ要件:
/// - コントラスト比: 4.5:1以上（WCAG 2.1 AAレベル）
/// - タップターゲットサイズ: 最小44px x 44px、推奨60px x 60px
/// - フォントサイズ: AppSizesの定義に従う
/// - テキストの太さ: 視認性向上のためやや太め（w600）
/// - 境界線: 2px以上の黒色で明確な区別
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
