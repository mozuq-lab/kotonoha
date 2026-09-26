/// ダークテーマ設定
/// ダークモード用のThemeData設定。
/// 暗い背景色と明るいテキスト色
/// 目の疲れを軽減するカラースキーム
/// アクセシビリティ要件に準拠したタップターゲットサイズ
/// Material 3デザインシステム準拠
library;

import 'package:flutter/material.dart';
import 'package:kotonoha_app/core/constants/app_colors.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'app_visual_theme.dart';

final _darkButtonSide = WidgetStateProperty.resolveWith<BorderSide?>((states) {
  const enabled = BorderSide(color: Colors.white);
  if (states.contains(WidgetState.disabled)) {
    return enabled.copyWith(color: enabled.color.withValues(alpha: 0.38));
  }
  return enabled;
});

/// ダークテーマの定義
/// アクセシビリティ要件
/// タップターゲットサイズ: 最小44px x 44px、推奨60px x 60px
/// フォントサイズ: AppSizesの定義に従う
/// 暗い背景に白いテキストで十分なコントラストを確保
final ThemeData darkTheme = appVisualTheme(_baseDarkTheme, highContrast: false);

final ThemeData _baseDarkTheme = ThemeData(
  brightness: Brightness.dark,
  visualDensity: VisualDensity.standard,
  materialTapTargetSize: MaterialTapTargetSize.padded,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.primaryDark,
    onPrimary: AppColors.onPrimaryDark,
    surface: AppColors.surfaceDark,
    onSurface: AppColors.onSurfaceDark,
    error: AppColors.errorDark,
    onError: Colors.black,
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
      foregroundColor: AppColors.primaryTextDark,
      minimumSize: const Size(
        AppSizes.recommendedTapTarget,
        AppSizes.recommendedTapTarget,
      ),
      textStyle: const TextStyle(
        fontSize: AppSizes.fontSizeMedium,
        fontWeight: FontWeight.bold,
      ),
    ).copyWith(side: _darkButtonSide),
  ),

  // チュートリアルの「次へ」は FilledButton を使う。ElevatedButton と同じく
  // 面から境界を作る枠線はテーマで一元化する（台帳 L-140〜L-142）。
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom().copyWith(side: _darkButtonSide),
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
      foregroundColor: AppColors.primaryTextDark,
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
      foregroundColor: AppColors.primaryTextDark,
      minimumSize: const Size(
        AppSizes.minTapTarget,
        AppSizes.minTapTarget,
      ),
    ),
  ),

  useMaterial3: true,
);
