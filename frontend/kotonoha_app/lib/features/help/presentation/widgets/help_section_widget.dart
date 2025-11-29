/// ヘルプセクションウィジェット
///
/// TASK-0075: ヘルプ画面・初回チュートリアル実装
///
/// 信頼性レベル: 🔵 青信号（要件定義書ベース）
library;

import 'package:flutter/material.dart';

/// ヘルプセクションウィジェット
///
/// セクションヘッダーとアイコン、子ウィジェットをまとめて表示する。
///
/// [title] セクションのタイトル（例: 「基本操作」「緊急ボタン」）
/// [icon] セクションのアイコン（オプション）
/// [children] セクション内のヘルプ項目ウィジェット
class HelpSectionWidget extends StatelessWidget {
  /// セクションのタイトル
  final String title;

  /// セクションのアイコン（オプション）
  final IconData? icon;

  /// セクション内の設定項目
  final List<Widget> children;

  /// コンストラクタ
  const HelpSectionWidget({
    super.key,
    required this.title,
    this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // セクションヘッダー
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 24,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        // ヘルプ内容
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
