// 【モデル定義】: アプリ設定モデル
// 【実装内容】: フォントサイズ、テーマ、TTS速度、AI丁寧さレベルを保持
// 【設計根拠】: REQ-801（フォントサイズ）、REQ-803（テーマ）、REQ-404（TTS速度）、REQ-903（丁寧さレベル）
// 🔵 信頼性レベル: 青信号 - EARS要件定義書に基づく

/// 【列挙型定義】: フォントサイズ
/// 【実装内容】: 小/中/大の3段階
/// 🔵 信頼性レベル: 青信号 - REQ-801「フォントサイズを小・中・大の3段階から選択」
enum FontSize {
  /// 小サイズ
  small,

  /// 中サイズ（デフォルト、高齢者向け標準サイズ）
  medium,

  /// 大サイズ
  large,
}

/// 【列挙型定義】: アプリテーマ
/// 【実装内容】: ライト/ダーク/高コントラストの3種類
/// 🔵 信頼性レベル: 青信号 - REQ-803「ライトモード・ダークモード・高コントラストモード」
enum AppTheme {
  /// ライトモード（デフォルト）
  light,

  /// ダークモード
  dark,

  /// 高コントラストモード（WCAG 2.1 AA準拠）
  highContrast,
}

/// 【列挙型定義】: TTS読み上げ速度
/// 【実装内容】: 遅い/普通/速いの3段階
/// 🔵 信頼性レベル: 青信号 - REQ-404「読み上げ速度を遅い・普通・速いの3段階」
enum TtsSpeed {
  /// 遅い
  slow,

  /// 普通（デフォルト）
  normal,

  /// 速い
  fast,
}

/// 【列挙型定義】: AI変換の丁寧さレベル
/// 【実装内容】: カジュアル/普通/丁寧の3段階
/// 🔵 信頼性レベル: 青信号 - REQ-903「丁寧さレベルをカジュアル・普通・丁寧の3段階」
enum PolitenessLevel {
  /// カジュアル（友人向け）
  casual,

  /// 普通（デフォルト）
  normal,

  /// 丁寧（目上の人向け）
  polite,
}

/// 【クラス定義】: アプリ設定
/// 【実装内容】: 全設定項目をイミュータブルに保持
/// 🔵 信頼性レベル: 青信号 - アーキテクチャ設計のローカルストレージ設計に基づく
class AppSettings {
  /// 【フィールド定義】: フォントサイズ
  /// 🔵 信頼性レベル: 青信号 - REQ-801
  final FontSize fontSize;

  /// 【フィールド定義】: テーマ
  /// 🔵 信頼性レベル: 青信号 - REQ-803
  final AppTheme theme;

  /// 【フィールド定義】: TTS速度
  /// 🔵 信頼性レベル: 青信号 - REQ-404
  final TtsSpeed ttsSpeed;

  /// 【フィールド定義】: AI丁寧さレベル
  /// 🔵 信頼性レベル: 青信号 - REQ-903
  final PolitenessLevel politenessLevel;

  /// 【コンストラクタ】: 全フィールドを受け取る
  const AppSettings({
    required this.fontSize,
    required this.theme,
    required this.ttsSpeed,
    required this.politenessLevel,
  });

  /// 【ファクトリコンストラクタ】: デフォルト設定を生成
  /// 【実装内容】: 高齢者にも見やすいデフォルト値を設定
  /// 🔵 信頼性レベル: 青信号 - REQ-804「標準フォントサイズを高齢者にも見やすいサイズ」
  factory AppSettings.defaults() {
    return const AppSettings(
      fontSize: FontSize.medium,
      theme: AppTheme.light,
      ttsSpeed: TtsSpeed.normal,
      politenessLevel: PolitenessLevel.normal,
    );
  }

  /// 【メソッド定義】: copyWithパターンでイミュータブルな更新
  AppSettings copyWith({
    FontSize? fontSize,
    AppTheme? theme,
    TtsSpeed? ttsSpeed,
    PolitenessLevel? politenessLevel,
  }) {
    return AppSettings(
      fontSize: fontSize ?? this.fontSize,
      theme: theme ?? this.theme,
      ttsSpeed: ttsSpeed ?? this.ttsSpeed,
      politenessLevel: politenessLevel ?? this.politenessLevel,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppSettings &&
        other.fontSize == fontSize &&
        other.theme == theme &&
        other.ttsSpeed == ttsSpeed &&
        other.politenessLevel == politenessLevel;
  }

  @override
  int get hashCode {
    return Object.hash(fontSize, theme, ttsSpeed, politenessLevel);
  }
}
