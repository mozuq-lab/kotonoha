/// 保存されたテーマ設定に対応するThemeDataを提供する。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kotonoha_app/features/settings/providers/settings_provider.dart';
import 'package:kotonoha_app/features/settings/models/app_theme.dart';
import 'light_theme.dart';
import 'dark_theme.dart';
import 'high_contrast_theme.dart';

/// 設定を読み込み中、または取得できない場合はライトテーマで表示を継続する。
final currentThemeProvider = Provider<ThemeData>((ref) {
  // settingsNotifierProvider監視: テーマ設定の変更を監視
  // AsyncValue対応: loading/data/error状態を適切に処理
  final settingsAsync = ref.watch(settingsNotifierProvider);

  return settingsAsync.when(
    // データ取得成功時: 設定に応じたThemeDataを返す
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
    // ローディング中: デフォルトでlightThemeを返す
    loading: () => lightTheme,
    // エラー時: デフォルトでlightThemeを返す（: 基本機能継続）
    error: (_, __) => lightTheme,
  );
});
