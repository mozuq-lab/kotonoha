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

  /// 緊急ボタン・エラー表示用（赤）
  static const Color emergency = Color(0xFFD32F2F);

  /// 緊急ボタン用（ダークモード - 明るい赤）
  static const Color emergencyDark = Color(0xFFEF5350);

  /// 緊急ボタン用（高コントラストモード - 純粋な赤）
  static const Color emergencyHighContrast = Color(0xFFFF0000);

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
}
