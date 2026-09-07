/// ライトテーマ設定
/// ライトモード用のThemeData設定。
/// 明るい背景色と暗いテキスト色
/// アクセシビリティ要件に準拠したタップターゲットサイズ
/// Material 3デザインシステム準拠
library;

import 'package:flutter/material.dart';
import 'package:kotonoha_app/core/constants/app_colors.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';

/// ライトテーマの定義
/// アクセシビリティ要件
/// タップターゲットサイズ: 最小44px x 44px、推奨60px x 60px
/// フォントサイズ: AppSizesの定義に従う
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: AppColors.primaryLight,
    // primary(#2196F3)上の白文字は約3.1:1でAA不足のため
    // onPrimaryを黒(#000000)に設定（コントラスト比 約6.7:1でAA適合）。
    onPrimary: AppColors.onPrimaryLight,
    surface: AppColors.surfaceLight,
    onSurface: AppColors.onSurfaceLight,
    // 緊急色 emergency(#D32F2F) をそのまま流用しており、緊急ボタンと
    // 全消去ボタン（error 背景）が同一色で区別できなかった。
    // errorLight(#8C1D18) は surface 上の文字として 8.36:1
    // 白文字を載せて 9.11:1、緊急色との分離 1.83:1。
    error: AppColors.errorLight,
    onError: Colors.white,
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
  // AA対応: 前景色を明示する。Material 3 の ElevatedButton は primary で
  // 塗りつぶすのではなく、surfaceContainerLow の面に primary のラベルを載せる設計で
  // TextButton と同じく「面に載る文字」になる。未指定だと AA 未達のため
  // 文字専用の AppColors.primaryTextLight を指定する。
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: AppColors.primaryTextLight,
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
  // AA対応: ダイアログ等のTextButtonは既定36pxでタップターゲット不足のため44pxを保証。
  // AA対応: 前景色を明示する。未指定だと Material 3 が colorScheme.primary を
  // 使うが、primary は「塗り」用途の色で面に載る文字としては AA 未達のため
  // 文字専用の AppColors.primaryTextLight を指定する。
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primaryTextLight,
      minimumSize: const Size(
        AppSizes.minTapTarget,
        AppSizes.minTapTarget,
      ),
    ),
  ),

  // Outlined button theme
  // AA対応: TextButton と同じ理由で前景色を明示する。枠線の色は
  // 各利用側が用途に応じて指定するため、ここでは前景色とタップターゲットのみ揃える。
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primaryTextLight,
      minimumSize: const Size(
        AppSizes.minTapTarget,
        AppSizes.minTapTarget,
      ),
    ),
  ),

  useMaterial3: true,
);
