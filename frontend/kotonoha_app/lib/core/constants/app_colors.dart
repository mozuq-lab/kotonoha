/// アプリケーションカラー定義
/// 各テーマ（ライト・ダーク・高コントラスト）で使用するカラー定数。
/// アクセシビリティ要件に準拠したコントラスト比を確保。
library;

import 'package:flutter/material.dart';

/// アプリケーション全体で使用するカラー定数
/// テーマごとに以下のカラーセットを定義
/// primary: プライマリカラー（アクセントカラー）
/// background: 画面背景色
/// onBackground: 背景上のテキスト色
/// surface: カード・ボタンなどのサーフェス色
/// onSurface: サーフェス上のテキスト色
/// 高コントラストモードはWCAG 2.1 AAレベル（コントラスト比4.5:1以上）に準拠。
class AppColors {
  /// プライベートコンストラクタ（インスタンス化防止）
  AppColors._();

  // ライトモード

  /// 青緑のアクセント色。
  static const Color primaryLight = Color(0xFF006D77);

  /// 青緑の上に載せる白文字。
  static const Color onPrimaryLight = Colors.white;

  /// 少し温かみのある背景色。
  static const Color backgroundLight = Color(0xFFFAFAF8);

  /// 背景上の濃い文字色。
  static const Color onBackgroundLight = Color(0xFF17242B);

  /// ホームと各画面のサーフェス色。
  static const Color surfaceLight = backgroundLight;

  /// サーフェス上の文字色。
  static const Color onSurfaceLight = onBackgroundLight;

  // ダークモード

  /// 暗い背景で読める明るい青緑。
  static const Color primaryDark = Color(0xFF71D6D7);

  /// 明るい青緑の上に載せる濃い文字色。
  static const Color onPrimaryDark = Color(0xFF002F34);

  /// 青緑を含む暗い背景色。
  static const Color backgroundDark = Color(0xFF142124);

  /// 背景上の明るい文字色。
  static const Color onBackgroundDark = Color(0xFFEDF3F4);

  /// ホームと各画面のサーフェス色。
  static const Color surfaceDark = backgroundDark;

  /// サーフェス上の文字色。
  static const Color onSurfaceDark = onBackgroundDark;

  // 高コントラストモード（WCAG 2.1 AA準拠）

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

  // 機能カラー

  // エラー・破壊的操作
  // 各テーマの `colorScheme.error` に使う。エラー色は
  // 「surface 上の文字色（errorText・エラーアイコン）」と
  // 「ボタン背景（+ onError）」の双方で使われるため、どちらでも
  // 4.5:1 を満たす必要がある。
  /// ライトモードのエラー色（前景・背景の両用）
  static const Color errorLight = Color(0xFF8C1D18);

  /// ダークモードのエラー色（前景・背景の両用）
  /// 暗い背景では文字としても読める明るい赤が必要なため
  /// Material 3 のダーク既定エラー色と同系の淡い赤を採る。
  static const Color errorDark = Color(0xFFF2B8B5);

  /// 高コントラストモードのエラー色（前景・背景の両用）
  /// 純赤 (#FF0000) は白に対しても白文字に対しても 4.00:1 で AA 未達のため
  /// 色相を保ったまま暗くした #CC0000 を使う（白との比 5.89:1）。
  static const Color errorHighContrast = Color(0xFFCC0000);

  // 面に載る操作ラベルの色。塗りと文字の役割を分けて参照する。

  /// ライトモードの操作ラベル色。
  static const Color primaryTextLight = primaryLight;

  /// ダークモードの操作ラベル色。
  static const Color primaryTextDark = primaryDark;

  /// 高コントラストモードのプライマリ文字色（面に載る操作ラベル用）
  /// backgroundHighContrast / surfaceHighContrast (#FFFFFF) 上で 21.00:1。
  /// 高コントラストでは [primaryHighContrast] が既に黒であり値としては同一だが
  /// 「塗り」と「文字」で別のトークンを参照する構造を3テーマで揃えるために定義する。
  static const Color primaryTextHighContrast = Color(0xFF000000);

  /// キャンセルボタン用グレー（ライトモード）
  static const Color cancelButtonLight = Color(0xFF757575);

  /// キャンセルボタン用グレー（ダークモード - 明るいグレー）
  static const Color cancelButtonDark = Color(0xFFBDBDBD);

  /// キャンセルボタン用（高コントラストモード - 黒）
  static const Color cancelButtonHighContrast = Color(0xFF000000);

  // 警告表示
  // 2系統ある。前者は自前の背景（コンテナ）を持つ表示、後者は背景を持たず
  // テーマの surface に直接載せる表示で、基準となる背景色が異なる。
  // 取り違えるとコントラストが破綻するため、命名で区別している。

  /// 警告コンテナの背景色（淡いオレンジ）
  /// 前景には [onWarningContainer]（テキスト・アイコン）と
  /// [warningOutline]（枠線）を組み合わせること。
  static const Color warningContainer = Color(0xFFFFE0B2);

  /// 警告コンテナ上のテキスト・アイコン色
  /// [warningContainer] に対しコントラスト比 8.2:1 で WCAG 2.1 AA を満たす。
  static const Color onWarningContainer = Color(0xFF6D2C00);

  /// 警告コンテナの枠線色
  /// [warningContainer] に対しコントラスト比 6.1:1。
  static const Color warningOutline = Color(0xFF8C3A00);

  /// テーマの surface 上に載せる警告アイコン色（ライト・高コントラスト）
  /// [warningContainer] ではなくテーマ背景に対する値である点に注意。
  /// 高コントラストの白背景に対し 5.9:1。
  static const Color warningIcon = Color(0xFFB23C00);

  /// テーマの surface 上に載せる警告アイコン色（ダーク）
  static const Color warningIconDark = Color(0xFFFFB74D);

  // AI変換結果の強調表示。背景と枠線は不透明色で指定する。

  /// AI変換結果ボックスの背景（ライト）。
  static const Color aiResultContainerLight = Color(0xFFE6F2F0);

  /// AI変換結果ボックスの背景（ダーク）。
  static const Color aiResultContainerDark = Color(0xFF1A353B);

  /// AI変換結果ボックスの背景（高コントラスト）。
  static const Color aiResultContainerHighContrast = Color(0xFFFFF9C4);

  /// AI変換結果ボックスと「元の文を使う」ボタンの枠線（ライト）。
  static const Color aiResultOutlineLight = primaryTextLight;

  /// AI変換結果ボックスと「元の文を使う」ボタンの枠線（ダーク）。
  static const Color aiResultOutlineDark = primaryTextDark;

  /// AI変換結果ボックスと「元の文を使う」ボタンの枠線（高コントラスト）。
  static const Color aiResultOutlineHighContrast = Color(0xFF000000);
}
