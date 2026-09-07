/// 丁寧さレベル定義
library;

/// AI変換の丁寧さレベル
/// 丁寧さレベルを3段階から選択可能
enum PolitenessLevel {
  /// カジュアル（くだけた表現）
  casual('カジュアル'),

  /// 普通（標準的な丁寧さ）
  normal('普通'),

  /// 丁寧（敬語を使用）
  polite('丁寧');

  /// 表示名
  final String displayName;

  const PolitenessLevel(this.displayName);
}
