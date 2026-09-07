/// QuickResponse 定数定義
/// クイック応答機能で使用する定数を一元管理。
/// デバウンス期間、ボタン間隔などの設定値を定義。
library;

/// クイック応答機能の定数
/// ボタンのデバウンス期間、間隔、サイズなどの設定値を管理。
class QuickResponseConstants {
  QuickResponseConstants._();

  /// デバウンス期間（ミリ秒）
  /// 連続タップを防止するための待機時間。
  /// 誤操作防止のため300ms以内の連続タップを無視
  static const int debounceDurationMs = 300;

  /// ボタン間のデフォルト間隔（ピクセル）
  /// ボタン間隔は8px以上、デフォルト12px
  static const double defaultButtonSpacing = 12.0;

  /// ボタン間の最小間隔（ピクセル）
  /// 誤タップ防止のため最小8px
  static const double minButtonSpacing = 8.0;

  /// ボタンのデフォルト幅（ピクセル）
  /// 適切なタップ領域を確保
  static const double defaultButtonWidth = 100.0;
}
