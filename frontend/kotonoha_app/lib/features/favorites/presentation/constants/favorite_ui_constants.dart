/// Favorite UI constants
///
/// TASK-0064: お気に入り一覧UI実装
/// 【TDD Greenフェーズ】: UI定数の集約
library;

/// お気に入り画面UI定数クラス
///
/// マジックナンバー排除とメンテナンス性向上のため、
/// お気に入り画面で使用する定数を集約。
class FavoriteUIConstants {
  FavoriteUIConstants._();

  // Spacing
  static const double cardHorizontalMargin = 8.0;
  static const double cardVerticalMargin = 4.0;
  static const double cardPadding = 12.0;
  static const double iconTextSpacing = 12.0;
  static const double textDateSpacing = 4.0;
  static const double emptyStateIconSpacing = 16.0;
  static const double emptyStateTextSpacing = 8.0;

  // Sizes
  static const double favoriteIconSize = 24.0;
  static const double emptyStateIconSize = 64.0;
  static const double minTapTargetSize = 44.0;

  // Text
  static const int maxTextLines = 2;

  // Opacity
  static const double dateTextOpacity = 0.6;
  static const double emptyStateIconOpacity = 0.3;
  static const double emptyStateTitleOpacity = 0.6;
  static const double emptyStateHintOpacity = 0.5;

  // Strings
  static const String screenTitle = 'お気に入り';
  static const String deleteAllTooltip = '全削除';
  static const String deleteTooltip = '削除';
  static const String confirmDialogTitle = '確認';
  static const String deleteConfirmMessage = 'このお気に入りを削除しますか?';
  static const String deleteAllConfirmMessage = 'すべてのお気に入りを削除しますか?';
  static const String cancelButtonLabel = 'キャンセル';
  static const String deleteButtonLabel = '削除';
  static const String emptyStateTitle = 'お気に入りがありません';
  static const String emptyStateHint = '履歴や定型文からお気に入りを登録できます';
  static const String dateTimeFormat = 'MM/dd HH:mm';

  // 編集モード関連
  static const String editTooltip = '並び替え';
  static const String editDoneTooltip = '完了';
}
