/// History UI constants
///
/// TASK-0061: 履歴一覧UI実装
/// 【TDD Refactorフェーズ】: UI定数の集約
library;

/// 履歴画面UI定数クラス
///
/// マジックナンバー排除とメンテナンス性向上のため、
/// 履歴画面で使用する定数を集約。
class HistoryUIConstants {
  HistoryUIConstants._();

  // Spacing
  static const double cardHorizontalMargin = 8.0;
  static const double cardVerticalMargin = 4.0;
  static const double cardPadding = 12.0;
  static const double iconTextSpacing = 12.0;
  static const double textDateSpacing = 4.0;
  static const double emptyStateIconSpacing = 16.0;
  static const double emptyStateTextSpacing = 8.0;

  // Sizes
  static const double historyIconSize = 24.0;
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
  static const String screenTitle = '履歴';
  static const String deleteAllTooltip = '全削除';
  static const String deleteTooltip = '削除';
  static const String confirmDialogTitle = '確認';
  static const String deleteConfirmMessage = 'この履歴を削除しますか?';
  static const String deleteAllConfirmMessage = 'すべての履歴を削除しますか?';
  static const String cancelButtonLabel = 'キャンセル';
  static const String deleteButtonLabel = '削除';
  static const String emptyStateTitle = '履歴がありません';
  static const String emptyStateHint = '読み上げた内容が履歴として保存されます';
  static const String dateTimeFormat = 'MM/dd HH:mm';
}
