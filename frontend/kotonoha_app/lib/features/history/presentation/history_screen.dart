/// History screen widget
///
/// TASK-0061: 履歴一覧UI実装
/// 【TDD Refactorフェーズ】: 定数抽出・ダイアログ分離・アクセシビリティ改善
///
/// 信頼性レベル: 🔵 青信号（要件定義書ベース）
/// 関連要件: FR-061-001〜015, AC-061-001〜008
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/history_provider.dart';
import '../../tts/providers/tts_provider.dart';
import 'widgets/history_item_card.dart';
import 'widgets/empty_history_widget.dart';
import 'constants/history_ui_constants.dart';

/// 履歴画面ウィジェット
///
/// 過去の入力履歴を表示・管理する画面。
///
/// 機能:
/// - 履歴一覧表示（新しい順）
/// - 履歴タップで再読み上げ
/// - 個別削除機能
/// - 全削除機能
/// - 空状態表示
///
/// 実装要件:
/// - FR-061-001: 履歴を時系列順（新しい順）に表示
/// - FR-061-006: タップで再読み上げ
/// - FR-061-007〜010: 削除機能（個別・全削除）
/// - NFR-061-001: 50件を1秒以内に表示
/// - NFR-061-004: タップターゲット44px以上
class HistoryScreen extends ConsumerWidget {
  /// 履歴画面を作成する。
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 履歴状態を監視
    final historyState = ref.watch(historyProvider);
    final histories = historyState.histories;

    return Scaffold(
      appBar: AppBar(
        title: const Text(HistoryUIConstants.screenTitle),
        // 全削除ボタン（履歴が存在する場合のみ表示）
        actions: histories.isNotEmpty
            ? [
                IconButton(
                  icon: const Icon(Icons.delete_sweep),
                  onPressed: () => _showDeleteAllDialog(context, ref),
                  tooltip: HistoryUIConstants.deleteAllTooltip,
                ),
              ]
            : null,
      ),
      body: histories.isEmpty
          ? const EmptyHistoryWidget() // 空状態表示
          : ListView.builder(
              itemCount: histories.length,
              itemBuilder: (context, index) {
                final history = histories[index];
                return HistoryItemCard(
                  key: Key('history_item_card_${history.id}'),
                  history: history,
                  onTap: () => _onHistoryTap(ref, history.content),
                  onDelete: () => _showDeleteDialog(context, ref, history.id),
                );
              },
            ),
    );
  }

  /// 履歴項目タップ時の処理
  ///
  /// FR-061-006: 履歴項目をタップすると再読み上げを実行
  void _onHistoryTap(WidgetRef ref, String content) {
    final ttsNotifier = ref.read(ttsProvider.notifier);
    ttsNotifier.speak(content);
  }

  /// 個別削除確認ダイアログを表示
  ///
  /// FR-061-008: 削除時に確認ダイアログを表示
  void _showDeleteDialog(BuildContext context, WidgetRef ref, String id) {
    showDialog<void>(
      context: context,
      barrierDismissible: false, // FR-061-008: 誤操作防止
      builder: (BuildContext dialogContext) {
        return _ConfirmDialog(
          title: HistoryUIConstants.confirmDialogTitle,
          content: HistoryUIConstants.deleteConfirmMessage,
          onConfirm: () {
            Navigator.of(dialogContext).pop();
            ref.read(historyProvider.notifier).deleteHistory(id);
          },
          onCancel: () => Navigator.of(dialogContext).pop(),
        );
      },
    );
  }

  /// 全削除確認ダイアログを表示
  ///
  /// FR-061-010: 全削除時に確認ダイアログを表示
  void _showDeleteAllDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      barrierDismissible: false, // FR-061-010: 誤操作防止
      builder: (BuildContext dialogContext) {
        return _ConfirmDialog(
          title: HistoryUIConstants.confirmDialogTitle,
          content: HistoryUIConstants.deleteAllConfirmMessage,
          onConfirm: () {
            Navigator.of(dialogContext).pop();
            ref.read(historyProvider.notifier).clearAllHistories();
          },
          onCancel: () => Navigator.of(dialogContext).pop(),
        );
      },
    );
  }
}

/// 確認ダイアログウィジェット（内部使用）
///
/// 重複コード削減のため、共通の確認ダイアログを定義。
class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.title,
    required this.content,
    required this.onConfirm,
    required this.onCancel,
  });

  final String title;
  final String content;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text(HistoryUIConstants.cancelButtonLabel),
        ),
        TextButton(
          onPressed: onConfirm,
          child: const Text(HistoryUIConstants.deleteButtonLabel),
        ),
      ],
    );
  }
}
