/// HistoryItemCard ウィジェット
///
/// TASK-0061: 履歴一覧UI実装
/// TASK-0066: お気に入り追加・削除・並び替え機能
/// 【TDD Refactorフェーズ】: 定数抽出・constコンストラクタ・アクセシビリティ改善
///
/// 信頼性レベル: 🔵 青信号（要件定義書ベース）
/// 関連要件: FR-061-002, FR-061-003, NFR-061-004, REQ-701
library;

import 'package:flutter/material.dart';
import '../../domain/models/history.dart';
import '../../domain/models/history_type.dart';
import 'package:intl/intl.dart';
import '../constants/history_ui_constants.dart';
import 'package:kotonoha_app/shared/widgets/send_to_input_button.dart';

/// 履歴項目カードウィジェット
///
/// 各履歴項目を表示するカード形式のウィジェット。
///
/// 表示内容:
/// - 履歴テキスト
/// - 作成日時（MM/DD HH:mm形式）
/// - 種類アイコン
/// - 削除ボタン
///
/// アクセシビリティ要件:
/// - タップターゲット最小44px以上
/// - スクリーンリーダー対応（Semantics）
class HistoryItemCard extends StatelessWidget {
  /// コンストラクタ
  const HistoryItemCard({
    required this.history,
    required this.onTap,
    required this.onDelete,
    this.isSpeaking = false,
    this.onStop,
    this.onLongPress,
    this.isFavorited = false,
    this.onFavoriteTap,
    super.key,
  });

  /// 履歴データ
  final History history;

  /// タップ時のコールバック
  final VoidCallback onTap;

  /// 削除ボタンタップ時のコールバック
  final VoidCallback onDelete;

  /// 読み上げ中フラグ
  final bool isSpeaking;

  /// 停止ボタンタップ時のコールバック
  final VoidCallback? onStop;

  /// 長押し時のコールバック（お気に入り追加メニュー表示用）
  final VoidCallback? onLongPress;

  /// 既にお気に入り登録済みかどうか
  ///
  /// 【改善】: 履歴からお気に入り追加は従来長押しメニューのみで、
  /// タップ主体の操作要件（REQ-5005）に反していた。星アイコンによる
  /// 明示的なタップ操作を追加し、長押しメニューは併存させる。
  final bool isFavorited;

  /// 星ボタンタップ時のコールバック（お気に入り追加）
  final VoidCallback? onFavoriteTap;

  /// 日時フォーマッター（パフォーマンス最適化のため静的）
  static final DateFormat _dateFormatter =
      DateFormat(HistoryUIConstants.dateTimeFormat);

  @override
  Widget build(BuildContext context) {
    final typeLabel = _getTypeLabel(history.type);
    final formattedDate = _formatDateTime(history.createdAt);

    return Semantics(
      label: '$typeLabel、${history.content}、$formattedDate',
      hint: 'タップして再読み上げ',
      button: true,
      child: Card(
        margin: const EdgeInsets.symmetric(
          horizontal: HistoryUIConstants.cardHorizontalMargin,
          vertical: HistoryUIConstants.cardVerticalMargin,
        ),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(HistoryUIConstants.cardPadding),
            child: Row(
              children: [
                // 種類アイコンまたは読み上げ中インジケーター
                Icon(
                  isSpeaking ? Icons.volume_up : _getIconForType(history.type),
                  size: HistoryUIConstants.historyIconSize,
                  color: isSpeaking
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: HistoryUIConstants.iconTextSpacing),
                // テキストと日時
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 履歴テキスト
                      Text(
                        history.content,
                        style: Theme.of(context).textTheme.bodyLarge,
                        maxLines: HistoryUIConstants.maxTextLines,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(
                          height: HistoryUIConstants.textDateSpacing),
                      // 作成日時
                      Text(
                        formattedDate,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(
                                      alpha:
                                          HistoryUIConstants.dateTextOpacity),
                            ),
                      ),
                    ],
                  ),
                ),
                // 【星ボタン】: 長押し不要でお気に入り追加できるタップ代替（REQ-5005）
                if (onFavoriteTap != null)
                  IconButton(
                    icon: Icon(
                      isFavorited ? Icons.star : Icons.star_border,
                      color: isFavorited
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    onPressed: onFavoriteTap,
                    tooltip: isFavorited ? 'お気に入り登録済み' : 'お気に入りに追加',
                    constraints: const BoxConstraints(
                      minWidth: HistoryUIConstants.minTapTargetSize,
                      minHeight: HistoryUIConstants.minTapTargetSize,
                    ),
                  ),
                // 【入力欄へボタン】: 履歴の内容を入力欄に入れて編集する動線（REQ-102）
                SendToInputButton(text: history.content),
                // 読み上げ中は停止ボタン、それ以外は削除ボタン
                if (isSpeaking && onStop != null)
                  IconButton(
                    icon: const Icon(Icons.stop),
                    onPressed: onStop,
                    tooltip: '停止',
                    constraints: const BoxConstraints(
                      minWidth: HistoryUIConstants.minTapTargetSize,
                      minHeight: HistoryUIConstants.minTapTargetSize,
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: onDelete,
                    tooltip: HistoryUIConstants.deleteTooltip,
                    constraints: const BoxConstraints(
                      minWidth: HistoryUIConstants.minTapTargetSize,
                      minHeight: HistoryUIConstants.minTapTargetSize,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 履歴種類に応じたアイコンを返す
  ///
  /// NFR-061-008: 履歴の種類を視覚的に区別
  IconData _getIconForType(HistoryType type) {
    return switch (type) {
      HistoryType.manualInput => Icons.keyboard, // 文字盤入力
      HistoryType.preset => Icons.list, // 定型文
      HistoryType.aiConverted => Icons.auto_awesome, // AI変換結果
      HistoryType.quickButton => Icons.smart_button, // 大ボタン
    };
  }

  /// 履歴種類に応じたラベルを返す（アクセシビリティ用）
  ///
  /// NFR-061-008: 履歴の種類を音声で区別
  String _getTypeLabel(HistoryType type) {
    return switch (type) {
      HistoryType.manualInput => '文字盤入力',
      HistoryType.preset => '定型文',
      HistoryType.aiConverted => 'AI変換',
      HistoryType.quickButton => '大ボタン',
    };
  }

  /// 日時を「MM/DD HH:mm」形式にフォーマット
  ///
  /// NFR-061-005: 日時フォーマット要件
  String _formatDateTime(DateTime dateTime) {
    return _dateFormatter.format(dateTime);
  }
}
