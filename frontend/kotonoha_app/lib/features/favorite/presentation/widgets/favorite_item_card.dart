/// FavoriteItemCard ウィジェット
library;

import 'package:flutter/material.dart';
import '../../../favorite/domain/models/favorite.dart';
import 'package:intl/intl.dart';
import '../constants/favorite_ui_constants.dart';
import 'package:kotonoha_app/shared/widgets/send_to_input_button.dart';

/// お気に入り項目カードウィジェット
/// 各お気に入り項目を表示するカード形式のウィジェット。
/// 表示内容
/// お気に入りテキスト
/// 作成日時（MM/DD HH:mm形式）
/// 削除ボタン
/// アクセシビリティ要件
/// タップターゲット最小44px以上
/// スクリーンリーダー対応（Semantics）
class FavoriteItemCard extends StatelessWidget {
  /// コンストラクタ
  const FavoriteItemCard({
    required this.favorite,
    required this.onTap,
    required this.onDelete,
    super.key,
  });

  /// お気に入りデータ
  final Favorite favorite;

  /// タップ時のコールバック
  final VoidCallback onTap;

  /// 削除ボタンタップ時のコールバック
  final VoidCallback onDelete;

  /// 日時フォーマッター（パフォーマンス最適化のため静的）
  static final DateFormat _dateFormatter =
      DateFormat(FavoriteUIConstants.dateTimeFormat);

  @override
  Widget build(BuildContext context) {
    final formattedDate = _formatDateTime(favorite.createdAt);

    return Semantics(
      label: 'お気に入り、${favorite.content}、$formattedDate',
      hint: 'タップして再読み上げ',
      button: true,
      child: Card(
        margin: const EdgeInsets.symmetric(
          horizontal: FavoriteUIConstants.cardHorizontalMargin,
          vertical: FavoriteUIConstants.cardVerticalMargin,
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(FavoriteUIConstants.cardPadding),
            child: Row(
              children: [
                // お気に入りアイコン
                Icon(
                  Icons.favorite,
                  size: FavoriteUIConstants.favoriteIconSize,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: FavoriteUIConstants.iconTextSpacing),
                // テキストと日時
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // お気に入りテキスト
                      Text(
                        favorite.content,
                        style: Theme.of(context).textTheme.bodyLarge,
                        maxLines: FavoriteUIConstants.maxTextLines,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(
                          height: FavoriteUIConstants.textDateSpacing),
                      // 作成日時
                      Text(
                        formattedDate,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(
                                      alpha:
                                          FavoriteUIConstants.dateTextOpacity),
                            ),
                      ),
                    ],
                  ),
                ),
                // 入力欄へボタン: お気に入りの内容を入力欄に入れて編集する動線
                SendToInputButton(text: favorite.content),
                // 削除ボタン
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: onDelete,
                  tooltip: FavoriteUIConstants.deleteTooltip,
                  constraints: const BoxConstraints(
                    minWidth: FavoriteUIConstants.minTapTargetSize,
                    minHeight: FavoriteUIConstants.minTapTargetSize,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 日時を「MM/DD HH:mm」形式にフォーマット
  /// 日時フォーマット要件
  String _formatDateTime(DateTime dateTime) {
    return _dateFormatter.format(dateTime);
  }
}
