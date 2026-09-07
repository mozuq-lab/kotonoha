/// 設定セクションウィジェット
library;

import 'package:flutter/material.dart';

/// 設定セクションウィジェット
/// セクションヘッダーと子ウィジェットをまとめて表示する。
/// [title] セクションのタイトル（例: 「表示設定」「音声設定」）
/// [children] セクション内の設定項目ウィジェット
class SettingsSectionWidget extends StatelessWidget {
  /// セクションのタイトル
  final String title;

  /// セクション内の設定項目
  final List<Widget> children;

  /// コンストラクタ
  const SettingsSectionWidget({
    super.key,
    required this.title,
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
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        // 設定項目
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
