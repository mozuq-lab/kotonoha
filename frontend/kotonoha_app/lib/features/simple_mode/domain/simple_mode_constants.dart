/// シンプルモード機能で使用する定数
///
/// fix/improvement-p0-p2: シンプルモード（疲労時・症状進行時の簡易画面）
/// 🟡 信頼性レベル: 黄信号 - 要件定義書にない新規機能のため妥当な推測
library;

/// シンプルモード関連の定数
class SimpleModeConstants {
  SimpleModeConstants._();

  /// シンプルモード画面に表示するお気に入りの最大件数
  ///
  /// 疲労時・症状進行時に見渡しやすい画面にするため、
  /// お気に入り全件ではなく上位数件（displayOrder昇順）のみを表示する。
  static const int maxFavoritesDisplayCount = 6;

  /// お気に入りグリッドの列数
  static const int favoritesGridColumns = 2;

  /// お気に入りグリッド各セルの高さ
  ///
  /// 幅に依存せず60px以上のタップターゲットを保証するため、
  /// aspectRatioではなく固定高さ（mainAxisExtent）で指定する。
  static const double favoritesGridCellHeight = 64.0;

  /// グリッドセル間のスペース
  static const double favoritesGridSpacing = 8.0;
}
