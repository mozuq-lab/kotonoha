/// PhraseListItem ウィジェット
///
/// TASK-0040: 定型文一覧UI実装
///
/// 個別の定型文アイテムを表示するウィジェット。
/// タップ時にコールバックを発火し、お気に入りアイコンを表示する。
/// アクセシビリティ要件（REQ-5001: 44px以上、NFR-202: 60px推奨）に準拠。
///
/// 関連要件:
/// - REQ-101: 定型文を一覧表示
/// - REQ-105: お気に入り定型文を一覧上部に優先表示
/// - REQ-5001: タップターゲット44px以上
library;

import 'package:flutter/material.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';

/// 【機能概要】: 定型文アイテムウィジェット
/// 【実装方針】: ListTileベースで44px以上のタップターゲットを確保
/// 【テスト対応】: TC-040-011〜TC-040-016, TC-040-033〜TC-040-035
/// 🔵 信頼性レベル: 青信号 - REQ-101、REQ-105、REQ-5001に基づく
///
/// 個別の定型文をリストアイテムとして表示する。
/// タップ時にonTapコールバックを発火する。
class PhraseListItem extends StatelessWidget {
  /// 【パラメータ定義】: 表示する定型文
  /// 🔵 信頼性レベル: 青信号 - 要件定義に基づく
  final PresetPhrase phrase;

  /// 【パラメータ定義】: タップ時のコールバック
  /// 🔵 信頼性レベル: 青信号 - AC-004に基づく
  final VoidCallback? onTap;

  /// 【パラメータ定義】: お気に入り切り替え時のコールバック
  /// 🟡 信頼性レベル: 黄信号 - REQ-105から推測
  final VoidCallback? onFavoriteToggle;

  /// 【パラメータ定義】: 編集時のコールバック
  /// 🔵 信頼性レベル: 青信号 - REQ-104に基づく
  final VoidCallback? onEdit;

  /// 【パラメータ定義】: 削除時のコールバック
  /// 🔵 信頼性レベル: 青信号 - REQ-104に基づく
  final VoidCallback? onDelete;

  /// PhraseListItemを作成する
  const PhraseListItem({
    super.key,
    required this.phrase,
    this.onTap,
    this.onFavoriteToggle,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 【Semantics設定】: スクリーンリーダー対応
    // 🟡 信頼性レベル: 黄信号 - アクセシビリティ要件から推測
    return Semantics(
      label: phrase.content,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            // 【サイズ制約】: 最小44px、推奨60pxのタップターゲット
            // 🔵 信頼性レベル: 青信号 - REQ-5001、NFR-202に基づく
            constraints: const BoxConstraints(
              minHeight: AppSizes.recommendedTapTarget,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingMedium,
              vertical: AppSizes.paddingSmall,
            ),
            child: Row(
              children: [
                // 【メインコンテンツ】: 定型文テキスト
                // 🔵 信頼性レベル: 青信号 - REQ-101に基づく
                Expanded(
                  child: Text(
                    phrase.content,
                    style: theme.textTheme.bodyLarge,
                    // 【テキストオーバーフロー】: 長いテキストは省略
                    // 🟡 信頼性レベル: 黄信号 - UI品質のための推測
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
                // 【お気に入りアイコン】: お気に入り状態を表示・切り替え
                // 🟡 信頼性レベル: 黄信号 - REQ-105から推測
                IconButton(
                  icon: Icon(
                    phrase.isFavorite ? Icons.star : Icons.star_border,
                    color: phrase.isFavorite
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: onFavoriteToggle,
                  tooltip: phrase.isFavorite ? 'お気に入りから削除' : 'お気に入りに追加',
                ),
                // 【編集アイコン】: 定型文を編集
                // 🔵 信頼性レベル: 青信号 - REQ-104に基づく
                if (onEdit != null)
                  IconButton(
                    icon: Icon(
                      Icons.edit,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    onPressed: onEdit,
                    tooltip: '編集',
                  ),
                // 【削除アイコン】: 定型文を削除
                // 🔵 信頼性レベル: 青信号 - REQ-104に基づく
                if (onDelete != null)
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    onPressed: onDelete,
                    tooltip: '削除',
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
