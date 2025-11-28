/// EmptyFavoriteWidget ウィジェット
///
/// TASK-0064: お気に入り一覧UI実装
/// 【TDD Greenフェーズ】: EmptyFavoriteWidgetウィジェット実装
///
/// 信頼性レベル: 🔵 青信号（要件定義書ベース）
/// 関連要件: FR-064-004, EDGE-064-004
library;

import 'package:flutter/material.dart';
import '../constants/favorite_ui_constants.dart';

/// 空状態表示ウィジェット
///
/// お気に入りが0件の場合に表示するウィジェット。
///
/// 表示内容:
/// - 空状態アイコン
/// - 「お気に入りがありません」メッセージ
/// - 使い方のヒント
///
/// アクセシビリティ:
/// - 情報提示のみなので、スクリーンリーダーには読み上げさせる
class EmptyFavoriteWidget extends StatelessWidget {
  /// コンストラクタ
  const EmptyFavoriteWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          '${FavoriteUIConstants.emptyStateTitle}。${FavoriteUIConstants.emptyStateHint}',
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 空状態アイコン
            Icon(
              Icons.favorite_border,
              size: FavoriteUIConstants.emptyStateIconSize,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: FavoriteUIConstants.emptyStateIconOpacity),
            ),
            const SizedBox(height: FavoriteUIConstants.emptyStateIconSpacing),
            // 空状態メッセージ
            Text(
              FavoriteUIConstants.emptyStateTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(
                        alpha: FavoriteUIConstants.emptyStateTitleOpacity),
                  ),
            ),
            const SizedBox(height: FavoriteUIConstants.emptyStateTextSpacing),
            // 使い方のヒント
            Text(
              FavoriteUIConstants.emptyStateHint,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(
                        alpha: FavoriteUIConstants.emptyStateHintOpacity),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
