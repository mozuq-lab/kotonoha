// 列挙型定義: ネットワーク接続状態
// 実装内容: オンライン、オフライン、チェック中の3状態
// 設計根拠: , , （オフライン対応）

/// 列挙型定義: ネットワーク接続状態
/// 実装内容: AI変換機能の利用可否を決定する状態
enum NetworkState {
  /// オンライン（AI変換利用可能）
  online('オンライン'),

  /// オフライン（基本機能のみ）
  offline('オフライン'),

  /// 接続確認中
  checking('接続確認中');

  /// 表示名
  final String displayName;

  const NetworkState(this.displayName);
}
