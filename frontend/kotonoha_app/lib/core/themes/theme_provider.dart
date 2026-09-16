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
    // ローディング中: デフォルトでlightThemeを返す（倍率 1.0。_scaled を通す理由は
    // 下記 _scaled のコメント参照——ボタンテーマの textStyle を「中」相当でも
    // 非 null にし、読み込み完了後に非中設定へ変わる遷移で null↔非null の
    // 段差を作らないため）。
    loading: () => _scaled(lightTheme, 1.0),
    // エラー時: デフォルトでlightThemeを返す（: 基本機能継続）。理由は loading と同じ。
    error: (_, __) => _scaled(lightTheme, 1.0),
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
///
/// `factor == 1.0`（「中」）でも早期リターンしない（P0、リスクレビュー反映）:
/// 以前は `if (factor == 1.0) return base;` としており、`base` は
/// TextButton/OutlinedButton/FilledButton の `textStyle` が null のまま
/// （テーマが明示していないため）。すると「中」でだけ `textStyle` が null、
/// 「大」「小」では非 null という非対称ができる。`MaterialApp` は既定で
/// `theme:` を `AnimatedTheme`（200ms）に渡しており、`TextStyle.lerp` は
/// 片方が null だと `t < 0.5` で旧値のまま静止、`t >= 0.5` で null へ
/// ジャンプするステップ関数になる（`text_style.dart`）。「中」に/から
/// 切り替える瞬間、ボタンラベルが最初の 100ms 止まり、200ms を超えても
/// 目標値に収束しない不具合が実測された
/// （`test/core/themes/theme_provider_button_label_test.dart` の
/// P0 テスト参照）。「大」↔「小」のように両側とも非 null な遷移は
/// 早期リターンが無くても最初から滑らかだった。
/// 早期リターンを外しても「中」の見た目は 1px も変えない:
/// `_scaledStyle`/`_scaledButtonStyle` は `factor == 1.0` のとき
/// `fontSize * 1.0` で数値上は元の値のまま（オブジェクトとしては新しいが
/// 値は等しい）になるよう作ってある。
ThemeData _scaled(ThemeData base, double factor) {
  // ボタン種のうちテーマが textStyle を明示していないもの
  // （TextButton/OutlinedButton/FilledButton）向けの既定ラベルスタイル。
  // 一度だけ導出して 3 種で使い回す。
  final defaultButtonLabelStyle = _defaultButtonLabelStyle(base);
  return base.copyWith(
    textTheme: _scaledTextTheme(base.textTheme, factor),
    primaryTextTheme: _scaledTextTheme(base.primaryTextTheme, factor),
    // ボタンラベル（REQ-802「ボタンラベル」もフォントサイズ設定の対象）。
    // ElevatedButton はテーマが textStyle を明示しているのでそれに倍率を掛け、
    // TextButton/OutlinedButton/FilledButton はテーマに textStyle の明示が無く
    // Material 既定スタイル（[_defaultButtonLabelStyle] 参照）で描かれているため
    // その既定スタイルの fontSize にだけ倍率を掛けた textStyle を新たに与える。
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: _scaledButtonStyle(
        base.elevatedButtonTheme.style,
        factor,
        defaultButtonLabelStyle,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: _scaledButtonStyle(
        base.textButtonTheme.style,
        factor,
        defaultButtonLabelStyle,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: _scaledButtonStyle(
        base.outlinedButtonTheme.style,
        factor,
        defaultButtonLabelStyle,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: _scaledButtonStyle(
        base.filledButtonTheme.style,
        factor,
        defaultButtonLabelStyle,
      ),
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

/// テーマがボタンの `textStyle` を明示していないとき（[TextButton]・
/// [OutlinedButton]・[FilledButton]）に実際に使われる Material 3 既定の
/// ラベルスタイルを、`Theme.of(context)` を介さずに再現する。
///
/// 導出の根拠（SDK ソースで確認済み）:
/// - 各ボタンの M3 既定スタイル（`_TextButtonDefaultsM3` 等、
///   `text_button.dart`/`outlined_button.dart`/`filled_button.dart`）は
///   `textStyle: MaterialStatePropertyAll(Theme.of(context).textTheme.labelLarge)`
///   を使う。
/// - `Theme.of(context)`（`theme.dart` の `Theme.of`）は
///   `ThemeData.localize(theme, theme.typography.geometryThemeFor(category))`
///   を呼び、`category` はロケールの `MaterialLocalizations.scriptCategory`。
/// - `ThemeData.localize`（`theme_data.dart`）は
///   `textTheme: localTextGeometry.merge(baseTheme.textTheme)` で textTheme を
///   作る。`labelLarge` については
///   `geometry.labelLarge.merge(base.textTheme.labelLarge)` となり、
///   `merge` は他方が非 null のフィールドだけ上書きする
///   （`TextStyle.merge`、`text_style.dart`）。本アプリの `textTheme.labelLarge`
///   は `fontSize`/`fontWeight`/`letterSpacing` が null で `color` のみ設定
///   されているため、結果は「geometry の書体情報＋テーマの色」になる。
/// - `category` は本アプリの `MaterialApp`（`app.dart`）が `locale`/
///   `localizationsDelegates` を指定していないため、既定の
///   `ScriptCategory.englishLike` になる（コード上は日本語ロケールを想定した
///   `ScriptCategory.dense` になり得るが、`typography.dart` の
///   `_M3Typography.englishLike`/`dense`/`tall` の `labelLarge` は
///   `fontSize: 14.0, fontWeight: FontWeight.w500, letterSpacing: 0.1` が
///   3 つとも同一値のため、どちらが選ばれても本メソッドの結果は変わらない。
///   差があるのは `textBaseline`（`alphabetic`/`ideographic`）のみ）。
///
/// `Typography.englishLike2021` は locale/platform に依存しない定数のため
/// `Typography.material2021()` を構築せずに直接参照できる。
TextStyle _defaultButtonLabelStyle(ThemeData base) {
  return Typography.englishLike2021.labelLarge!
      .merge(base.textTheme.labelLarge);
}

/// ボタン種ごとの [ButtonStyle] にフォント設定の倍率を掛ける。
/// テーマが `textStyle` を明示していればその `fontSize` に倍率を掛ける
/// （[TextStyle.copyWith] を使うので `fontWeight` 等の他の属性は保たれる）。
/// 明示が無いボタン種は [defaultLabelStyle]（[_defaultButtonLabelStyle] で
/// 導出した Material 既定スタイル）の `fontSize` にだけ倍率を掛ける
/// （同じく `copyWith` なので `fontWeight`・`letterSpacing`・`fontFamily`・
/// `inherit` は既定のまま保たれ、太さ・字間が失われない——再レビューで
/// 検出された不具合: 以前は `TextStyle(fontSize: ...)` を素で合成しており、
/// `ButtonStyleButton.build()` はプロパティ単位ではなく
/// `widgetValue ?? themeValue ?? defaultValue` の全置換で解決するため
/// （`button_style_button.dart`）、太さ・字間が丸ごと落ちていた）。
///
/// `factor == 1.0`（「中」）でもここを通る（P0、リスクレビュー反映）:
/// [_scaled] は「中」で早期リターンしない。ここで常に非 null な `textStyle` を
/// 与えることで、「中」に/から切り替わる瞬間に `textStyle` が null↔非null に
/// ならないようにしている（`_scaled` のコメント参照）。「中」では
/// `fontSize * 1.0` で数値上は既定スタイルのままなので、実効スタイルは
/// 1px も変わらない。
///
/// `inherit` を明示的に上書きしない理由: [defaultLabelStyle] の `inherit` は
/// 導出元（`Typography.englishLike2021.labelLarge`）の `inherit: false` を
/// そのまま引き継ぐ（`TextStyle.merge`/`copyWith` は `inherit` に触れない）。
/// これは Material 3 のボタン既定スタイルの `inherit` と一致するため、
/// `ButtonStyleButton` が状態変化時に `AnimatedDefaultTextStyle` で
/// 直前のスタイルとここのスタイルを補間しても
/// 「Failed to interpolate TextStyles with different inherit values」には
/// ならない（round 1 で素の `TextStyle(fontSize: ..., inherit: false)` を
/// 手で合成したときに実際にこの例外を踏んだ）。
ButtonStyle _scaledButtonStyle(
  ButtonStyle? style,
  double factor,
  TextStyle defaultLabelStyle,
) {
  final currentTextStyle =
      style?.textStyle?.resolve(const <WidgetState>{}) ?? defaultLabelStyle;
  final scaledTextStyle = _scaledStyle(currentTextStyle, factor);
  return (style ?? const ButtonStyle()).copyWith(
    textStyle: WidgetStatePropertyAll(scaledTextStyle),
  );
}
