/// 保存されたテーマ設定に対応するThemeDataを提供する。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kotonoha_app/features/settings/providers/settings_provider.dart';
import 'package:kotonoha_app/features/settings/models/app_theme.dart';
import 'package:kotonoha_app/features/settings/models/font_size.dart';
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
      final base = switch (settings.theme) {
        AppTheme.light => lightTheme,
        AppTheme.dark => darkTheme,
        AppTheme.highContrast => highContrastTheme,
      };
      return _scaled(base, settings.fontSize.scaleFactor);
    },
    // ローディング中: デフォルトでlightThemeを返す
    loading: () => lightTheme,
    // エラー時: デフォルトでlightThemeを返す（: 基本機能継続）
    error: (_, __) => lightTheme,
  );
});

/// テーマ由来の文字サイズにフォント設定の倍率を掛ける（REQ-802・REQ-2007、台帳 L-74）
/// 明示サイズ（`copyWith(fontSize:)`）を持つ箇所は影響を受けない。
///
/// [TextTheme.apply] は使わない: 本アプリの各テーマは `bodyLarge` 等の
/// 一部スタイルしか明示せず、それ以外は `fontSize` が null のまま残る
/// （[TextTheme] の未指定フィールドは null 参照ではなく `fontSize: null` を
/// 含む既定の [TextStyle] になる）。`apply(fontSizeFactor:)` は
/// 「fontSize が null なら倍率は 1.0 でなければならない」と assert しており、
/// 倍率 1.0 以外ではこの null フィールドで例外になる。fontSize を持つ
/// フィールドだけを個別に倍率がけする。
ThemeData _scaled(ThemeData base, double factor) {
  if (factor == 1.0) return base;
  return base.copyWith(
    textTheme: _scaledTextTheme(base.textTheme, factor),
    primaryTextTheme: _scaledTextTheme(base.primaryTextTheme, factor),
  );
}

/// [TextTheme] の各スタイルに [_scaledStyle] を適用する
TextTheme _scaledTextTheme(TextTheme theme, double factor) {
  return TextTheme(
    displayLarge: _scaledStyle(theme.displayLarge, factor),
    displayMedium: _scaledStyle(theme.displayMedium, factor),
    displaySmall: _scaledStyle(theme.displaySmall, factor),
    headlineLarge: _scaledStyle(theme.headlineLarge, factor),
    headlineMedium: _scaledStyle(theme.headlineMedium, factor),
    headlineSmall: _scaledStyle(theme.headlineSmall, factor),
    titleLarge: _scaledStyle(theme.titleLarge, factor),
    titleMedium: _scaledStyle(theme.titleMedium, factor),
    titleSmall: _scaledStyle(theme.titleSmall, factor),
    bodyLarge: _scaledStyle(theme.bodyLarge, factor),
    bodyMedium: _scaledStyle(theme.bodyMedium, factor),
    bodySmall: _scaledStyle(theme.bodySmall, factor),
    labelLarge: _scaledStyle(theme.labelLarge, factor),
    labelMedium: _scaledStyle(theme.labelMedium, factor),
    labelSmall: _scaledStyle(theme.labelSmall, factor),
  );
}

/// fontSize を持つスタイルだけ倍率をかける。fontSize が null なら手を付けない。
TextStyle? _scaledStyle(TextStyle? style, double factor) {
  final fontSize = style?.fontSize;
  if (style == null || fontSize == null) return style;
  return style.copyWith(fontSize: fontSize * factor);
}
