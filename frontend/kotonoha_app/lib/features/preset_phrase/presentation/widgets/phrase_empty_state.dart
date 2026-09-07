/// PhraseEmptyState ウィジェット
/// 定型文が0件の場合に表示する空状態ウィジェット。
/// 中央配置でメッセージとアイコンを表示する。
/// 定型文が0件の場合の表示
/// AC-005: 0件の場合「定型文がありません」と表示される
library;

import 'package:flutter/material.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';

/// 機能概要: 空状態ウィジェット
/// 実装方針: 中央配置でアイコンとメッセージを縦並びに表示
/// 定型文が登録されていない場合に表示するメッセージ。
class PhraseEmptyState extends StatelessWidget {
  /// パラメータ定義: 表示するメッセージ
  final String message;

  /// PhraseEmptyStateを作成する
  const PhraseEmptyState({
    super.key,
    this.message = '定型文がありません',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // レイアウト実装: 中央配置でアイコンとメッセージを表示
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // アイコン表示: 空状態を視覚的に示すアイコン
          Icon(
            Icons.inbox_outlined,
            size: AppSizes.iconSizeXLarge,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSizes.paddingMedium),
          // メッセージ表示: 空状態メッセージ
          Text(
            message,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
