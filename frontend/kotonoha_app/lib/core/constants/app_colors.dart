/// アプリケーションカラー定義
///
/// TASK-0016: テーマ実装（ライト・ダーク・高コントラスト）
/// 要件: REQ-803（テーマ設定）、REQ-5006（WCAG 2.1 AA準拠）
/// 信頼性レベル: 🔵 青信号（要件定義書ベース）
///
/// 各テーマ（ライト・ダーク・高コントラスト）で使用するカラー定数。
/// アクセシビリティ要件に準拠したコントラスト比を確保。
library;

import 'package:flutter/material.dart';

/// アプリケーション全体で使用するカラー定数
///
/// テーマごとに以下のカラーセットを定義:
/// - primary: プライマリカラー（アクセントカラー）
/// - background: 画面背景色
/// - onBackground: 背景上のテキスト色
/// - surface: カード・ボタンなどのサーフェス色
/// - onSurface: サーフェス上のテキスト色
///
/// 高コントラストモードはWCAG 2.1 AAレベル（コントラスト比4.5:1以上）に準拠。
class AppColors {
  /// プライベートコンストラクタ（インスタンス化防止）
  AppColors._();

  // ===========================================================================
  // ライトモード (Light Mode)
  // ===========================================================================

  /// ライトモードのプライマリカラー（青系）
  static const Color primaryLight = Color(0xFF2196F3);

  /// ライトモードのプライマリ上テキスト色（黒）
  ///
  /// primary(#2196F3)上では白文字が約3.1:1でWCAG AA不足のため、
  /// 黒文字（コントラスト比 約6.7:1）を採用しAAを満たす。
  static const Color onPrimaryLight = Color(0xFF000000);

  /// ライトモードの背景色（白）
  static const Color backgroundLight = Color(0xFFFFFFFF);

  /// ライトモードの背景上テキスト色（黒）
  static const Color onBackgroundLight = Color(0xFF000000);

  /// ライトモードのサーフェス色（薄いグレー）
  static const Color surfaceLight = Color(0xFFF5F5F5);

  /// ライトモードのサーフェス上テキスト色（黒）
  static const Color onSurfaceLight = Color(0xFF000000);

  // ===========================================================================
  // ダークモード (Dark Mode)
  // ===========================================================================

  /// ダークモードのプライマリカラー（やや暗い青系）
  static const Color primaryDark = Color(0xFF1976D2);

  /// ダークモードの背景色（濃い灰色）
  static const Color backgroundDark = Color(0xFF121212);

  /// ダークモードの背景上テキスト色（白）
  static const Color onBackgroundDark = Color(0xFFFFFFFF);

  /// ダークモードのサーフェス色（やや明るい灰色）
  static const Color surfaceDark = Color(0xFF1E1E1E);

  /// ダークモードのサーフェス上テキスト色（白）
  static const Color onSurfaceDark = Color(0xFFFFFFFF);

  // ===========================================================================
  // 高コントラストモード (High Contrast Mode)
  // WCAG 2.1 AAレベル準拠（コントラスト比4.5:1以上）
  // ===========================================================================

  /// 高コントラストモードのプライマリカラー（黒）
  static const Color primaryHighContrast = Color(0xFF000000);

  /// 高コントラストモードの背景色（白）
  static const Color backgroundHighContrast = Color(0xFFFFFFFF);

  /// 高コントラストモードの背景上テキスト色（黒）
  static const Color onBackgroundHighContrast = Color(0xFF000000);

  /// 高コントラストモードのサーフェス色（白）
  static const Color surfaceHighContrast = Color(0xFFFFFFFF);

  /// 高コントラストモードのサーフェス上テキスト色（黒）
  static const Color onSurfaceHighContrast = Color(0xFF000000);

  // ===========================================================================
  // 機能カラー (Functional Colors)
  // ===========================================================================

  // --- 緊急表示 ---
  //
  // 【エラー色との使い分け】: 緊急色は「周囲に気付いてもらう」ための色で、
  // エラー色（破壊的操作・エラー表示）とは意味が違う。home_screen の
  // ClearAllButton と app_shell の緊急ボタンは同時に描画されるため、
  // 同じ色にすると区別が付かない。エラー色には error{Light,Dark,HighContrast}
  // を使い、こちらは緊急表示専用とする。

  /// 緊急ボタン・緊急画面用（赤・ライトモード）
  ///
  /// 白文字・白アイコンに対し 4.98:1。
  static const Color emergency = Color(0xFFD32F2F);

  /// 緊急ボタン・緊急画面用（ダークモード - 明るい赤）
  ///
  /// 黒文字を載せた場合 6.02:1。暗いUI上でボタン自体を見つけやすくするため
  /// 明るい赤にしている（surface #1E1E1E に対し 4.78:1、
  /// scaffold #121212 に対し 5.37:1）。
  static const Color emergencyDark = Color(0xFFEF5350);

  /// 緊急ボタン用（高コントラストモード - 純粋な赤）
  ///
  /// **背景として使う専用の色**（緊急画面の全面赤）。
  /// 高コントラストモードで最大限に目立たせるため純赤を維持しており、
  /// 前景は [bestContrastingTextColor] で黒を選ぶことで 5.25:1 を確保する。
  ///
  /// 白背景に対しては 4.00:1 しかないため、**文字色・アイコン色として
  /// 使ってはならない**。その用途には [errorHighContrast] を使うこと。
  static const Color emergencyHighContrast = Color(0xFFFF0000);

  // --- エラー・破壊的操作 ---
  //
  // 各テーマの `colorScheme.error` に使う。エラー色は
  // 「surface 上の文字色（errorText・エラーアイコン）」と
  // 「ボタン背景（+ onError）」の双方で使われるため、どちらでも
  // 4.5:1 を満たす必要がある。
  //
  // 【緊急色との「分離」について】: 同一画面に並ぶ緊急色（[emergency] 系）と
  // 別の色であることは必要だが、**輝度比で十分に離すことはAA要件と両立しない**。
  // 全色空間を探索した結果、「面の文字として4.5:1」「onErrorを載せて4.5:1」
  // 「緊急色と輝度比3:1」を同時に満たす色は、黒や白と見分けが付かない色しか
  // 存在しない（ダークに至っては下側の枝が最初から成立しない）。
  // 各定数に記した分離比は現状の実測値であって、守るべき閾値ではない。
  // 実際の識別は色以外の手段（ラベル・形状・枠線）が担う。
  // 詳細は test/accessibility/theme_error_color_contrast_test.dart を参照。

  /// ライトモードのエラー色（前景・背景の両用）
  ///
  /// surfaceLight (#F5F5F5) 上の文字として 8.36:1、白文字を載せて 9.11:1。
  /// 緊急色 [emergency] (#D32F2F) との分離は 1.83:1。
  /// 以前は [emergency] をそのまま流用しており、緊急ボタンと
  /// 全消去ボタンが同一色（#D32F2F）で区別できなかった。
  static const Color errorLight = Color(0xFF8C1D18);

  /// ダークモードのエラー色（前景・背景の両用）
  ///
  /// surfaceDark (#1E1E1E) 上の文字として 9.76:1、黒文字を載せて 12.30:1。
  /// 緊急色 [emergencyDark] (#EF5350) との分離は 2.04:1。
  /// 暗い背景では文字としても読める明るい赤が必要なため、
  /// Material 3 のダーク既定エラー色と同系の淡い赤を採る。
  static const Color errorDark = Color(0xFFF2B8B5);

  /// 高コントラストモードのエラー色（前景・背景の両用）
  ///
  /// 純赤 (#FF0000) は白に対しても白文字に対しても 4.00:1 で AA 未達のため、
  /// 色相を保ったまま暗くした #CC0000 を使う（白との比 5.89:1）。
  /// 緊急色 [emergencyHighContrast] (#FF0000) との分離は 1.47:1。
  static const Color errorHighContrast = Color(0xFFCC0000);

  // ---------------------------------------------------------------------------
  // 面に載る文字としてのプライマリ色（primaryText 系）
  // ---------------------------------------------------------------------------
  // [primaryLight] 等は「塗り」用途で選ばれた色であり、面に載る文字としては
  // 検証されていなかった。Material 3 は TextButton / OutlinedButton の既定の
  // 前景色に colorScheme.primary を使うため、そのままではダイアログの
  // 「キャンセル」「OK」といった操作ラベルが AA 未達になる
  // （primaryLight は surfaceLight 上で 2.87:1、primaryDark は surfaceDark 上で 3.62:1）。
  //
  // 塗りとしての primary は変えずに、文字としての役割だけを別トークンに分離する。
  // 色相は primary 系と揃え、明度だけを動かして見た目の一貫性を保つ。

  /// ライトモードのプライマリ文字色（面に載る操作ラベル用）
  ///
  /// backgroundLight (#FFFFFF) 上で 5.75:1、surfaceLight (#F5F5F5) 上で 5.27:1。
  /// [primaryLight] (#2196F3) と同じ青系で、明度だけを下げた色。
  static const Color primaryTextLight = Color(0xFF1565C0);

  /// ダークモードのプライマリ文字色（面に載る操作ラベル用）
  ///
  /// backgroundDark (#121212) 上で 8.46:1、surfaceDark (#1E1E1E) 上で 7.53:1。
  /// [primaryDark] (#1976D2) と同じ青系で、明度だけを上げた色。
  static const Color primaryTextDark = Color(0xFF64B5F6);

  /// 高コントラストモードのプライマリ文字色（面に載る操作ラベル用）
  ///
  /// backgroundHighContrast / surfaceHighContrast (#FFFFFF) 上で 21.00:1。
  /// 高コントラストでは [primaryHighContrast] が既に黒であり値としては同一だが、
  /// 「塗り」と「文字」で別のトークンを参照する構造を3テーマで揃えるために定義する。
  static const Color primaryTextHighContrast = Color(0xFF000000);

  /// キャンセルボタン用グレー（ライトモード）
  static const Color cancelButtonLight = Color(0xFF757575);

  /// キャンセルボタン用グレー（ダークモード - 明るいグレー）
  static const Color cancelButtonDark = Color(0xFFBDBDBD);

  /// キャンセルボタン用（高コントラストモード - 黒）
  static const Color cancelButtonHighContrast = Color(0xFF000000);

  // --- 警告表示 ---
  //
  // 2系統ある。前者は自前の背景（コンテナ）を持つ表示、後者は背景を持たず
  // テーマの surface に直接載せる表示で、基準となる背景色が異なる。
  // 取り違えるとコントラストが破綻するため、命名で区別している。

  /// 警告コンテナの背景色（淡いオレンジ）
  ///
  /// 前景には [onWarningContainer]（テキスト・アイコン）と
  /// [warningOutline]（枠線）を組み合わせること。
  /// 🔵 信頼性レベル: 青信号 - 高コントラスト要件（4.5:1以上）
  static const Color warningContainer = Color(0xFFFFE0B2);

  /// 警告コンテナ上のテキスト・アイコン色
  ///
  /// [warningContainer] に対しコントラスト比 8.2:1 で WCAG 2.1 AA を満たす。
  static const Color onWarningContainer = Color(0xFF6D2C00);

  /// 警告コンテナの枠線色
  ///
  /// [warningContainer] に対しコントラスト比 6.1:1。
  static const Color warningOutline = Color(0xFF8C3A00);

  /// テーマの surface 上に載せる警告アイコン色（ライト・高コントラスト）
  ///
  /// [warningContainer] ではなくテーマ背景に対する値である点に注意。
  /// ライトテーマの背景 (#F5F5F5) に対し 5.4:1、
  /// 高コントラストの白背景に対し 5.9:1。
  static const Color warningIcon = Color(0xFFB23C00);

  /// テーマの surface 上に載せる警告アイコン色（ダーク）
  ///
  /// ダークテーマの背景 (#1E1E1E) に対し 9.6:1。
  /// ライト用の濃色をダークで使うと 2.81:1 まで落ちるため分ける。
  static const Color warningIconDark = Color(0xFFFFB74D);

  // --- AI変換結果の強調表示 ---
  //
  // 従来は `primary.withValues(alpha: 0.1〜0.3)` の半透明色を
  // ダイアログ背景に重ねていた。コントラスト比は合成後の色で決まるため
  // 半透明のままでは検証できず、枠線もテーマのプライマリ色そのままで
  // ライト 2.60:1 と非テキスト基準(3:1)未達だった。
  //
  // ここでは**合成後と同じ色**を不透明な定数として持つ。見た目は
  // 変わらないまま、実際に描画される色でコントラストを検証できる。

  /// AI変換結果ボックスの背景（ライト）
  ///
  /// primaryLight を alpha 0.1 で surfaceLight に重ねた合成色と同一。
  /// 黒文字に対し 17.5:1。
  static const Color aiResultContainerLight = Color(0xFFE0ECF5);

  /// AI変換結果ボックスの背景（ダーク）
  ///
  /// primaryDark を alpha 0.2 で surfaceDark に重ねた合成色と同一。
  /// 白文字に対し 13.5:1。
  static const Color aiResultContainerDark = Color(0xFF1D3042);

  /// AI変換結果ボックスの背景（高コントラスト）
  ///
  /// 黄色を alpha 0.3 で白に重ねた合成色と同一。黒文字に対し 19.6:1。
  static const Color aiResultContainerHighContrast = Color(0xFFFFF9C4);

  /// AI変換結果ボックスの枠線・「元の文を使う」ボタンの枠線（ライト）
  ///
  /// 枠線は「隣接する色」の双方から 3:1 以上離す必要がある。
  /// [aiResultContainerLight] に対し 4.78:1、surfaceLight に対し 5.27:1。
  /// primaryLight(#2196F3) では 2.60:1 / 2.87:1 で未達だった。
  static const Color aiResultOutlineLight = Color(0xFF1565C0);

  /// AI変換結果ボックスの枠線・「元の文を使う」ボタンの枠線（ダーク）
  ///
  /// [aiResultContainerDark] に対し 6.10:1、surfaceDark に対し 7.53:1。
  /// primaryDark(#1976D2) では 2.94:1 / 3.62:1 だった。
  static const Color aiResultOutlineDark = Color(0xFF64B5F6);

  /// AI変換結果ボックスの枠線・「元の文を使う」ボタンの枠線（高コントラスト）
  ///
  /// [aiResultContainerHighContrast] に対し 19.6:1、白背景に対し 21:1。
  static const Color aiResultOutlineHighContrast = Color(0xFF000000);
}
