/// 【機能概要】: 現在のテーマを提供するプロバイダー
/// 【実装方針】: settingsNotifierProviderと連携し、選択されたテーマに応じたThemeDataを返す
/// 【テスト対応】: TC-001〜TC-007のテーマプロバイダーテストを通すための実装
/// 🔵 信頼性レベル: 要件定義書とテストケースに基づく確実な実装
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kotonoha_app/features/settings/providers/settings_provider.dart';
import 'package:kotonoha_app/features/settings/models/app_theme.dart';
import 'light_theme.dart';
import 'dark_theme.dart';
import 'high_contrast_theme.dart';

/// 【機能概要】: 現在のテーマを提供するプロバイダー
/// 【実装方針】: settingsNotifierProviderを監視し、テーマ設定に応じたThemeDataを返す
/// 【テスト対応】: TC-001〜TC-007のテストケースを通すための最小限実装
/// 🔵 信頼性レベル: REQ-803（テーマ設定）に基づく
///
/// 設定プロバイダー（settingsNotifierProvider）と連携して、
/// 選択されたテーマに応じたThemeDataを返す。
/// - AppTheme.light → lightTheme
/// - AppTheme.dark → darkTheme
/// - AppTheme.highContrast → highContrastTheme
///
/// ローディング中またはエラー時はデフォルトでlightThemeを返す。
final currentThemeProvider = Provider<ThemeData>((ref) {
  // 【settingsNotifierProvider監視】: テーマ設定の変更を監視
  // 【AsyncValue対応】: loading/data/error状態を適切に処理
  // 🔵 青信号: Riverpod 2.xの標準的なパターン
  final settingsAsync = ref.watch(settingsNotifierProvider);

  return settingsAsync.when(
    // 【データ取得成功時】: 設定に応じたThemeDataを返す
    // 🔵 青信号: TC-002〜TC-007のテーマ切り替えテストに対応
    data: (settings) {
      switch (settings.theme) {
        case AppTheme.light:
          return lightTheme;
        case AppTheme.dark:
          return darkTheme;
        case AppTheme.highContrast:
          return highContrastTheme;
      }
    },
    // 【ローディング中】: デフォルトでlightThemeを返す
    // 🔵 青信号: TC-001の初期状態テストに対応
    loading: () => lightTheme,
    // 【エラー時】: デフォルトでlightThemeを返す（NFR-301: 基本機能継続）
    // 🟡 黄信号: エラー発生時もアプリがクラッシュせず動作継続
    error: (_, __) => lightTheme,
  );
});
