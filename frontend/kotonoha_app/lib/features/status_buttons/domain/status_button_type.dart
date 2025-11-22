/// StatusButtonType Enum定義
///
/// TASK-0044: 状態ボタン（「痛い」「トイレ」等8-12個）実装
/// 要件: FR-001（状態ボタンの種類）、FR-002（ボタン数の範囲）、FR-005（ラベル表示）
/// 信頼性レベル: 青信号（要件定義書ベース）
///
/// 状態ボタンの種類を定義するEnum。
/// 必須の8個（痛い、トイレ、暑い、寒い、水、眠い、助けて、待って）と
/// オプションの4個（もう一度、ありがとう、ごめんなさい、大丈夫）をサポート。
library;

/// 状態ボタンの種類
///
/// ユーザーが自身の状態や要求を即座に伝えるための選択肢を定義。
/// REQ-202: 状態を表すボタン（「痛い」「トイレ」「暑い」「寒い」など）を表示
/// REQ-203: 8-12個の固定文言として提供
enum StatusButtonType {
  // 必須の8個
  /// 「痛い」- 身体状態
  pain,
  /// 「トイレ」- 要求
  toilet,
  /// 「暑い」- 身体状態
  hot,
  /// 「寒い」- 身体状態
  cold,
  /// 「水」- 要求
  water,
  /// 「眠い」- 身体状態
  sleepy,
  /// 「助けて」- 要求
  help,
  /// 「待って」- 要求
  wait,

  // オプションの4個
  /// 「もう一度」- コミュニケーション
  again,
  /// 「ありがとう」- 感情
  thanks,
  /// 「ごめんなさい」- 感情
  sorry,
  /// 「大丈夫」- 感情
  okay,
}

/// 状態ボタンのラベル定義
///
/// 各StatusButtonTypeに対応する日本語ラベルを定義。
/// FR-005: 各ボタンに状態を表すラベルを明確に表示
const Map<StatusButtonType, String> statusButtonLabels = {
  // 必須の8個
  StatusButtonType.pain: '痛い',
  StatusButtonType.toilet: 'トイレ',
  StatusButtonType.hot: '暑い',
  StatusButtonType.cold: '寒い',
  StatusButtonType.water: '水',
  StatusButtonType.sleepy: '眠い',
  StatusButtonType.help: '助けて',
  StatusButtonType.wait: '待って',
  // オプションの4個
  StatusButtonType.again: 'もう一度',
  StatusButtonType.thanks: 'ありがとう',
  StatusButtonType.sorry: 'ごめんなさい',
  StatusButtonType.okay: '大丈夫',
};

/// StatusButtonType拡張メソッド
///
/// Enumに便利なアクセサを追加
extension StatusButtonTypeExtension on StatusButtonType {
  /// このタイプの日本語ラベルを取得
  ///
  /// 使用例:
  /// ```dart
  /// final label = StatusButtonType.pain.label; // '痛い'
  /// ```
  String get label => statusButtonLabels[this]!;
}
