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
    // primary(#000000)上の白文字は最大コントラスト（21:1）でAA適合。
    onPrimary: Colors.white,
    surface: AppColors.surfaceHighContrast,
    onSurface: AppColors.onSurfaceHighContrast,
    // 【訂正】: 以前は「純赤(#FF0000)は白背景上で約5.25:1」と記載していたが
    // 実測は 4.00:1 で WCAG AA(4.5:1) 未達。白文字を載せた場合も同じく 4.00:1 で、
    // 前景・背景のどちらの使い方でも基準を満たしていなかった。
    // （5.25:1 は「純赤の上に黒文字を載せた場合」の値で、白背景との比ではない）
    // 色相を保ったまま暗くした #CC0000 に変更し、白に対し 5.89:1 を確保する。
    // 全面赤の緊急画面には引き続き純赤 emergencyHighContrast を使う
    // （背景専用。前景は輝度から黒を選ぶため 5.25:1 で AA を満たす）。
    error: AppColors.errorHighContrast,
    onError: Colors.white,
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
      foregroundColor: AppColors.primaryTextHighContrast,
    ),
  ),

  // Text button theme
  // 【AA対応】: ダイアログ等のTextButtonは既定36pxでタップターゲット不足のため44pxを保証。
  // 【AA対応】: 前景色を明示する。未指定だと Material 3 が colorScheme.primary を
  // 使うが、primary は「塗り」用途の色で面に載る文字としては AA 未達のため、
  // 文字専用の AppColors.primaryTextHighContrast を指定する
  // （このテーマでは値としては黒で同一だが、3テーマで参照の構造を揃える）。
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      minimumSize: const Size(
        AppSizes.minTapTarget,
        AppSizes.minTapTarget,
      ),
      foregroundColor: AppColors.primaryTextHighContrast,
    ),
  ),

  // Outlined button theme
  // 【AA対応】: TextButton と同じ理由で前景色を明示する。枠線の色は
  // 各利用側が用途に応じて指定するため、ここでは前景色とタップターゲットのみ揃える。
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(
        AppSizes.minTapTarget,
        AppSizes.minTapTarget,
      ),
      foregroundColor: AppColors.primaryTextHighContrast,
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
