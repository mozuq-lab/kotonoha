/// テーマ選択検証の共通ヘルパー
/// ファイル目的: 「どのテーマが選ばれたか」を、フォント設定の倍率がけに
/// 影響されない属性で検証する
/// 2 ファイル（`theme_application_test.dart`・`settings_provider_theme_test.dart`）
/// が同じ比較をするため、ここ 1 箇所に置く（各ファイルに複製すると片方だけ
/// 弱いまま取り残される）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 「同じテーマが選ばれたか」を検証する。
///
/// 完全一致（`==`）は使えない: `currentThemeProvider` はフォント設定の倍率がけ
/// （`_scaled`）を必ず通すため、「中」設定でも `lightTheme`/`darkTheme`/
/// `highContrastTheme` の定数そのものとは等しくない（`textTheme` と
/// ボタンテーマ 4 種が `copyWith` で作り直されるため、値として同じ見た目でも
/// オブジェクトとしては別になる）。
///
/// 代わりに、倍率がけが触らない属性のうち「どのテーマか」を決めるものを比較する:
/// - `brightness`: dark と light の取り違えはここで落ちる。
/// - `scaffoldBackgroundColor`: 画面の地の色。
/// - `colorScheme`: **light と highContrast はこれでしか区別できない**。
///   両者は `brightness`（ともに `Brightness.light`）も
///   `scaffoldBackgroundColor`（ともに `#FFFFFF`）も同じで、分かれるのは配色
///   （`primary` が `#2196F3` と `#000000`、`onPrimary` が黒と白、など）。
///   高コントラストは WCAG 2.1 AA のアクセシビリティ機能なので、ライトテーマに
///   化ける回帰を検出できなければ意味が無い。
///
/// `textTheme`・`elevatedButtonTheme`・`textButtonTheme` などフォント倍率がけの
/// 対象は比較しない（「中」でも `copyWith` されるため、正しく動いていても
/// 一致しない）。
void expectSameTheme(ThemeData actual, ThemeData expected) {
  expect(actual.brightness, expected.brightness);
  expect(actual.scaffoldBackgroundColor, expected.scaffoldBackgroundColor);
  expect(actual.colorScheme, expected.colorScheme);
}
