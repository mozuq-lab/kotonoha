/// EmptyHistoryWidget ウィジェット
///
/// TASK-0061: 履歴一覧UI実装
/// TDD Refactorフェーズ: 定数抽出・constコンストラクタ・アクセシビリティ改善
///
/// 信頼性レベル: 青信号（要件定義書ベース）
/// 関連要件: FR-061-004, EDGE-061-004
library;

import 'package:flutter/material.dart';
import '../constants/history_ui_constants.dart';

/// 空状態表示ウィジェット
///
/// 履歴が0件の場合に表示するウィジェット。
///
/// 表示内容:
/// - 空状態アイコン
/// - 「履歴がありません」メッセージ
/// - 使い方のヒント
///
/// アクセシビリティ:
/// - 情報提示のみなので、スクリーンリーダーには読み上げさせる
class EmptyHistoryWidget extends StatelessWidget {
  /// コンストラクタ
  const EmptyHistoryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          '${HistoryUIConstants.emptyStateTitle}。${HistoryUIConstants.emptyStateHint}',
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 空状態アイコン
            Icon(
              Icons.history,
              size: HistoryUIConstants.emptyStateIconSize,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: HistoryUIConstants.emptyStateIconOpacity),
            ),
            const SizedBox(height: HistoryUIConstants.emptyStateIconSpacing),
            // 空状態メッセージ
            Text(
              HistoryUIConstants.emptyStateTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(
                        alpha: HistoryUIConstants.emptyStateTitleOpacity),
                  ),
            ),
            const SizedBox(height: HistoryUIConstants.emptyStateTextSpacing),
            // 使い方のヒント
            Text(
              HistoryUIConstants.emptyStateHint,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(
                        alpha: HistoryUIConstants.emptyStateHintOpacity),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
