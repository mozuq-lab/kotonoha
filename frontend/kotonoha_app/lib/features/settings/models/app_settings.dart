/// 【機能概要】: アプリ設定データモデル（フォントサイズ・テーマ）
/// 【実装方針】: テストを通すために最小限の実装（フォントサイズとテーマのみ）
/// 【テスト対応】: TC-001からTC-016までの全テストケースで使用される設定モデル
/// 🔵 信頼性レベル: interfaces.dartの定義に基づく確実な実装
library;

import 'font_size.dart';
import 'app_theme.dart';
import '../../tts/domain/models/tts_speed.dart';

// 【実装内容】: アプリ設定を保持する不変オブジェクト
// 【REQ-801, REQ-803, REQ-404対応】: フォントサイズ、テーマ、TTS速度の設定を管理
class AppSettings {
  // 【フォントサイズ設定】: 3段階（小・中・大）
  // 🔵 青信号: REQ-801のフォントサイズ要件に基づく
  final FontSize fontSize;

  // 【テーマ設定】: 3種類（ライト・ダーク・高コントラスト）
  // 🔵 青信号: REQ-803のテーマ要件に基づく
  final AppTheme theme;

  // 【TTS速度設定】: 3段階（遅い・普通・速い）
  // 🔵 青信号: REQ-404のTTS速度要件に基づく
  final TTSSpeed ttsSpeed;

  // 【コンストラクタ】: デフォルト値を設定（medium、light、normal）
  // 【デフォルト値】: interfaces.dartで定義されたデフォルト値
  // 🔵 青信号: REQ-801、REQ-803、REQ-404のデフォルト値定義に基づく
  const AppSettings({
    this.fontSize = FontSize.medium,
    this.theme = AppTheme.light,
    this.ttsSpeed = TTSSpeed.normal,
  });

  /// 【機能概要】: 設定の一部を変更した新しいインスタンスを生成
  /// 【実装方針】: 不変オブジェクトパターン（Dartの標準的な実装方法）
  /// 【テスト対応】: setFontSize()、setTheme()、setTTSSpeed()で設定変更時に使用
  /// 🔵 信頼性レベル: Dartの標準的なcopyWithパターン
  AppSettings copyWith({
    FontSize? fontSize,
    AppTheme? theme,
    TTSSpeed? ttsSpeed,
  }) {
    // 【実装内容】: 指定されたフィールドのみ更新し、それ以外は既存値を保持
    // 【null安全性】: Dart Null Safetyに準拠した実装
    // 🔵 青信号: Dartの標準的なパターン
    return AppSettings(
      fontSize: fontSize ?? this.fontSize,
      theme: theme ?? this.theme,
      ttsSpeed: ttsSpeed ?? this.ttsSpeed,
    );
  }

  /// 【機能概要】: AppSettingsをJSON形式に変換
  /// 【実装方針】: SharedPreferencesでの保存用にJSON形式に変換
  /// 【テスト対応】: TC-049-003（JSON変換）で使用
  /// 🔵 信頼性レベル: Dartの標準的なtoJsonパターン
  Map<String, dynamic> toJson() {
    // 【実装内容】: 各フィールドをJSON形式に変換
    // 【キー名】: snake_caseを使用（requirements.md仕様に準拠）
    // 【値の形式】: enum nameを文字列として保存
    // 🔵 青信号: REQ-5003（設定永続化）に基づく
    return {
      'font_size': fontSize.name,
      'theme': theme.name,
      'tts_speed': ttsSpeed.name,
    };
  }

  /// 【機能概要】: JSON形式からAppSettingsを復元
  /// 【実装方針】: SharedPreferencesから読み込んだデータから復元
  /// 【テスト対応】: TC-049-004（JSON復元）、TC-049-011（不正値フォールバック）で使用
  /// 🔵 信頼性レベル: Dartの標準的なfromJsonパターン
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    // 【実装内容】: JSON形式から各フィールドを復元
    // 【キー名】: snake_caseを使用（requirements.md仕様に準拠）
    // 【null安全性】: null値がある場合はデフォルト値を使用
    // 【不正値フォールバック】: 不正な値が来た場合はデフォルト値を使用
    // 🔵 青信号: TC-049-011（不正値フォールバック）に基づく

    // 【フォントサイズ復元】: enum nameから復元、不正値はmediumを使用
    final fontSizeName = json['font_size'] as String? ?? FontSize.medium.name;
    FontSize fontSize;
    try {
      fontSize = FontSize.values.firstWhere(
        (e) => e.name == fontSizeName,
        orElse: () => FontSize.medium,
      );
    } catch (_) {
      fontSize = FontSize.medium;
    }

    // 【テーマ復元】: enum nameから復元、不正値はlightを使用
    final themeName = json['theme'] as String? ?? AppTheme.light.name;
    AppTheme theme;
    try {
      theme = AppTheme.values.firstWhere(
        (e) => e.name == themeName,
        orElse: () => AppTheme.light,
      );
    } catch (_) {
      theme = AppTheme.light;
    }

    // 【TTS速度復元】: enum nameから復元、不正値はnormalを使用
    final ttsSpeedName = json['tts_speed'] as String? ?? TTSSpeed.normal.name;
    TTSSpeed ttsSpeed;
    try {
      ttsSpeed = TTSSpeed.values.firstWhere(
        (e) => e.name == ttsSpeedName,
        orElse: () => TTSSpeed.normal,
      );
    } catch (_) {
      // 【エラーハンドリング】: 不正な値が来た場合はデフォルト値を使用
      ttsSpeed = TTSSpeed.normal;
    }

    return AppSettings(
      fontSize: fontSize,
      theme: theme,
      ttsSpeed: ttsSpeed,
    );
  }
}
