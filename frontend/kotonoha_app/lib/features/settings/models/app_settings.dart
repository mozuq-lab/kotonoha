/// 【機能概要】: アプリ設定データモデル（フォントサイズ・テーマ）
/// 【実装方針】: テストを通すために最小限の実装（フォントサイズとテーマのみ）
/// 【テスト対応】: TC-001からTC-016までの全テストケースで使用される設定モデル
/// 🔵 信頼性レベル: interfaces.dartの定義に基づく確実な実装
library;

import 'font_size.dart';
import 'app_theme.dart';

// 【実装内容】: アプリ設定を保持する不変オブジェクト
// 【REQ-801, REQ-803対応】: フォントサイズとテーマの設定を管理
class AppSettings {
  // 【フォントサイズ設定】: 3段階（小・中・大）
  // 🔵 青信号: REQ-801のフォントサイズ要件に基づく
  final FontSize fontSize;

  // 【テーマ設定】: 3種類（ライト・ダーク・高コントラスト）
  // 🔵 青信号: REQ-803のテーマ要件に基づく
  final AppTheme theme;

  // 【コンストラクタ】: デフォルト値を設定（medium、light）
  // 【デフォルト値】: interfaces.dartで定義されたデフォルト値
  // 🔵 青信号: REQ-801、REQ-803のデフォルト値定義に基づく
  const AppSettings({
    this.fontSize = FontSize.medium,
    this.theme = AppTheme.light,
  });

  /// 【機能概要】: 設定の一部を変更した新しいインスタンスを生成
  /// 【実装方針】: 不変オブジェクトパターン（Dartの標準的な実装方法）
  /// 【テスト対応】: setFontSize()、setTheme()で設定変更時に使用
  /// 🔵 信頼性レベル: Dartの標準的なcopyWithパターン
  AppSettings copyWith({
    FontSize? fontSize,
    AppTheme? theme,
  }) {
    // 【実装内容】: 指定されたフィールドのみ更新し、それ以外は既存値を保持
    // 【null安全性】: Dart Null Safetyに準拠した実装
    // 🔵 青信号: Dartの標準的なパターン
    return AppSettings(
      fontSize: fontSize ?? this.fontSize,
      theme: theme ?? this.theme,
    );
  }
}
