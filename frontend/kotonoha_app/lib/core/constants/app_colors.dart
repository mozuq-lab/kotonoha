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

  /// 成功・完了表示用（緑）
  static const Color success = Color(0xFF4CAF50);

  /// 警告表示用（オレンジ）
  static const Color warning = Color(0xFFFF9800);

  /// 情報表示用（青）
  static const Color info = Color(0xFF2196F3);
}
