/// ダークテーマ設定
///
/// TASK-0016: テーマ実装（ライト・ダーク・高コントラスト）
/// 要件: REQ-803（テーマ設定）
/// 信頼性レベル: 青信号（要件定義書ベース）
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
    // primaryDark(#1976D2)上の白文字は約4.6:1でAA適合。
    onPrimary: Colors.white,
    surface: AppColors.surfaceDark,
    onSurface: AppColors.onSurfaceDark,
    // ライト用の濃い赤(#D32F2F)を流用しており surface(#1E1E1E) 上で 3.35:1、
    // 既定の onError(黒)との組み合わせでも 4.22:1 でAA未達だった。
    // 一度は緊急色 emergencyDark(#EF5350) を充てたが、それでは緊急ボタンと
    // 全消去ボタン（error 背景）が同一色になってしまうため専用色に分ける。
    // errorDark(#F2B8B5) は surface 上の文字として 9.76:1、
    // 黒文字を載せて 12.30:1、緊急色との分離 2.04:1。
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
  // AA対応: 前景色を明示する。Material 3 の ElevatedButton は primary で
  // 塗りつぶすのではなく、surfaceContainerLow の面に primary のラベルを載せる設計で、
  // TextButton と同じく「面に載る文字」になる。未指定だと AA 未達のため
  // 文字専用の AppColors.primaryTextDark を指定する。
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
  // 使うが、primary は「塗り」用途の色で面に載る文字としては AA 未達のため、
  // 文字専用の AppColors.primaryTextDark を指定する。
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
