import 'package:flutter/material.dart';

/// Application color constants for different themes
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // ライトモード (Light mode)
  static const Color primaryLight = Color(0xFF2196F3);
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color onBackgroundLight = Color(0xFF000000);
  static const Color surfaceLight = Color(0xFFF5F5F5);
  static const Color onSurfaceLight = Color(0xFF000000);

  // ダークモード (Dark mode)
  static const Color primaryDark = Color(0xFF1976D2);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color onBackgroundDark = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color onSurfaceDark = Color(0xFFFFFFFF);

  // 高コントラストモード (High contrast mode) - WCAG 2.1 AA compliant
  static const Color primaryHighContrast = Color(0xFF000000);
  static const Color backgroundHighContrast = Color(0xFFFFFFFF);
  static const Color onBackgroundHighContrast = Color(0xFF000000);
  static const Color surfaceHighContrast = Color(0xFFFFFFFF);
  static const Color onSurfaceHighContrast = Color(0xFF000000);

  // 機能カラー (Functional colors)
  static const Color emergency = Color(0xFFD32F2F); // 緊急ボタン
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);
}
