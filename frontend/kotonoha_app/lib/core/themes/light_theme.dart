/// ライトテーマ設定
/// ライトモード用のThemeData設定。
/// 明るい背景色と暗いテキスト色
/// アクセシビリティ要件に準拠したタップターゲットサイズ
/// Material 3デザインシステム準拠
library;

import 'package:flutter/material.dart';
import 'package:kotonoha_app/core/constants/app_colors.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'app_visual_theme.dart';

final _lightButtonSide = WidgetStateProperty.resolveWith<BorderSide?>((states) {
  const enabled = BorderSide(color: Colors.black);
  if (states.contains(WidgetState.disabled)) {
    return enabled.copyWith(color: enabled.color.withValues(alpha: 0.38));
  }
  return enabled;
});

/// ライトテーマの定義
/// アクセシビリティ要件
/// タップターゲットサイズ: 最小44px x 44px、推奨60px x 60px
/// フォントサイズ: AppSizesの定義に従う
final ThemeData lightTheme =
    appVisualTheme(_baseLightTheme, highContrast: false);

final ThemeData _baseLightTheme = ThemeData(
  brightness: Brightness.light,
  visualDensity: VisualDensity.standard,
  materialTapTargetSize: MaterialTapTargetSize.padded,
  colorScheme: const ColorScheme.light(
    primary: AppColors.primaryLight,
    onPrimary: AppColors.onPrimaryLight,
    surface: AppColors.surfaceLight,
    onSurface: AppColors.onSurfaceLight,
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
    ).copyWith(side: _lightButtonSide),
  ),

  // チュートリアルの「次へ」は FilledButton を使う。ElevatedButton と同じく
  // 面から境界を作る枠線はテーマで一元化する（台帳 L-140〜L-142）。
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom().copyWith(side: _lightButtonSide),
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
