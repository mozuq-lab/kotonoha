// 列挙型定義: 履歴の種類
// 実装内容: 文字盤入力、定型文、AI変換結果、大ボタンの4種類
// 設計根拠: , （履歴機能）、interfaces.dart

/// 列挙型定義: 履歴の種類
/// 実装内容: 読み上げ・表示したテキストの入力元を示す
enum HistoryType {
  /// 文字盤からの手動入力
  manualInput('文字盤入力'),

  /// 定型文からの選択
  preset('定型文'),

  /// AI変換結果
  aiConverted('AI変換結果'),

  /// 大ボタン（はい/いいえ/わからない等）
  quickButton('大ボタン');

  /// 表示名
  final String displayName;

  const HistoryType(this.displayName);
}
