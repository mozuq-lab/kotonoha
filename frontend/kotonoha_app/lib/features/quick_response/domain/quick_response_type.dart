/// QuickResponseType Enum定義
///
/// TASK-0043: 「はい」「いいえ」「わからない」大ボタン実装
/// 要件: FR-001（3種類の大ボタン）、FR-006（ラベル表示）
/// 信頼性レベル: 🔵 青信号（要件定義書ベース）
///
/// クイック応答ボタンの種類を定義するEnum。
/// 「はい」「いいえ」「わからない」の3種類をサポート。
library;

/// クイック応答ボタンの種類
///
/// ユーザーが質問に対して即座に回答するための3つの選択肢を定義。
/// REQ-201: 「はい」「いいえ」「わからない」の3つの大ボタンを常時表示
enum QuickResponseType {
  /// 「はい」- 肯定の応答
  yes,

  /// 「いいえ」- 否定の応答
  no,

  /// 「わからない」- 不明・保留の応答
  unknown,
}

/// クイック応答ボタンのラベル定義
///
/// 各QuickResponseTypeに対応する日本語ラベルを定義。
/// FR-006: 各ボタンに明確なラベルを表示
const Map<QuickResponseType, String> quickResponseLabels = {
  QuickResponseType.yes: 'はい',
  QuickResponseType.no: 'いいえ',
  QuickResponseType.unknown: 'わからない',
};

/// QuickResponseType拡張メソッド
///
/// Enumに便利なアクセサを追加
extension QuickResponseTypeExtension on QuickResponseType {
  /// このタイプの日本語ラベルを取得
  ///
  /// 使用例:
  /// ```dart
  /// final label = QuickResponseType.yes.label; // 'はい'
  /// ```
  String get label => quickResponseLabels[this]!;
}
