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
    // ボタンラベル（REQ-802「ボタンラベル」もフォントサイズ設定の対象）。
    // ElevatedButton はテーマが textStyle を明示しているのでそれに倍率を掛け、
    // TextButton/OutlinedButton/FilledButton はテーマに textStyle の明示が無く
    // Material の実効既定値（14px、_defaultButtonLabelFontSize）で描かれているため
    // その既定値を基準に倍率を掛けた textStyle を新たに与える。
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: _scaledButtonStyle(base.elevatedButtonTheme.style, factor),
    ),
    textButtonTheme: TextButtonThemeData(
      style: _scaledButtonStyle(base.textButtonTheme.style, factor),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: _scaledButtonStyle(base.outlinedButtonTheme.style, factor),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: _scaledButtonStyle(base.filledButtonTheme.style, factor),
    ),
  );
}

/// [TextTheme] の 15 フィールドすべてを列挙している。フィールドを漏らすと
/// そのスタイルだけフォント設定に追従しなくなるため、[TextTheme] にフィールドが
/// 増えたらここにも追加すること。各スタイルに [_scaledStyle] を適用する。
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

/// テーマがボタンの textStyle を明示していないときに描画される実効フォントサイズ。
/// [TextButton]・[OutlinedButton]・[FilledButton] はいずれもテーマ側に textStyle を
/// 明示していない。この場合 Material 3 のボタン既定スタイルは `Theme.of(context)`
/// の `textTheme` ではなく Flutter 組込みの Typography（englishLike 等）の
/// labelLarge をそのまま使うため、本アプリの `textTheme.labelLarge`（本アプリでは
/// fontSize が null）には影響されず、常にこの既定値で描かれる。
/// 実測（`RenderParagraph` で測定、3 テーマ・3 ボタン種すべて一致）して確認済み。
const double _defaultButtonLabelFontSize = 14.0;

/// ボタン種ごとの [ButtonStyle] にフォント設定の倍率を掛ける。
/// テーマが `textStyle` を明示していればその `fontSize` に倍率を掛ける
/// （[TextStyle.copyWith] を使うので `fontWeight` 等の他の属性は保たれる）。
/// 明示が無いボタン種は [_defaultButtonLabelFontSize] を基準に倍率を掛けた
/// `textStyle` を新たに与える。呼び出し元の [_scaled] が `factor == 1.0` で
/// 早期リターンするため、ここに来る時点で必ず `factor != 1.0`
/// （「中」では呼ばれず、実効サイズは 1px も変わらない）。
///
/// `inherit: false` を明示する理由: Material 3 のボタン既定スタイルの
/// `TextStyle` は `inherit: false`（Typography 由来の完結したスタイル）。
/// `ButtonStyleButton` はボタンの状態変化時に `AnimatedDefaultTextStyle` で
/// 直前のスタイルからここのスタイルへ補間するため、`inherit` が食い違うと
/// `TextStyle.lerp` が「Failed to interpolate TextStyles with different
/// inherit values」で例外を投げる（実際に踏んだ: 設定読み込み中は
/// `currentThemeProvider` が未倍率の既定スタイル [inherit: false] を返し、
/// 設定確定後にここで作るスタイルへ遷移する瞬間に再現した）。
ButtonStyle _scaledButtonStyle(ButtonStyle? style, double factor) {
  final currentTextStyle = style?.textStyle?.resolve(const <WidgetState>{});
  final scaledTextStyle = currentTextStyle != null
      ? _scaledStyle(currentTextStyle, factor)
      : TextStyle(
          fontSize: _defaultButtonLabelFontSize * factor, inherit: false);
  return (style ?? const ButtonStyle()).copyWith(
    textStyle: WidgetStatePropertyAll(scaledTextStyle),
  );
}
