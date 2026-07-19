/// History screen widget
///
/// TASK-0061: 履歴一覧UI実装
/// TASK-0066: お気に入り追加・削除・並び替え機能
/// 【TDD Refactorフェーズ】: 定数抽出・ダイアログ分離・アクセシビリティ改善
///
/// 信頼性レベル: 🔵 青信号（要件定義書ベース）
/// 関連要件: FR-061-001〜015, AC-061-001〜008, REQ-701
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/history_provider.dart';
import '../domain/models/history.dart';
import '../../favorite/providers/favorite_provider.dart';
import '../../tts/providers/tts_provider.dart';
import '../../tts/domain/models/tts_state.dart';
import 'widgets/history_item_card.dart';
import 'widgets/empty_history_widget.dart';
import 'constants/history_ui_constants.dart';
import 'package:kotonoha_app/shared/widgets/undo_snack_bar.dart';

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
/// - お気に入り追加機能（REQ-701）
///
/// 実装要件:
/// - FR-061-001: 履歴を時系列順（新しい順）に表示
/// - FR-061-006: タップで再読み上げ
/// - FR-061-007〜010: 削除機能（個別・全削除）
/// - NFR-061-001: 50件を1秒以内に表示
/// - NFR-061-004: タップターゲット44px以上
/// - REQ-701: お気に入り追加機能
class HistoryScreen extends ConsumerStatefulWidget {
  /// 履歴画面を作成する。
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  /// 現在読み上げ中の履歴項目ID
  ///
  /// 【バグ修正】: 以前はTTSのspeaking状態を全カードに一律で渡していたため、
  /// 1件を読み上げ中に全カードが停止アイコンに変わっていた。読み上げ対象の
  /// 項目IDを保持し、その項目のみ読み上げ中表示にする。
  String? _speakingId;

  @override
  Widget build(BuildContext context) {
    // 履歴状態を監視
    final historyState = ref.watch(historyProvider);
    final histories = historyState.histories;

    // 【星ボタン用】: お気に入り登録済みかどうかをcontent一致で判定する
    // （既存のお気に入り重複判定ロジックと同様の方式）
    final favoriteContents =
        ref.watch(favoriteProvider).favorites.map((f) => f.content).toSet();

    // TTS状態を監視
    final ttsState = ref.watch(ttsProvider);

    // TTSの状態変更を監視
    ref.listen<TTSServiceState>(ttsProvider, (previous, next) {
      // エラーメッセージを表示（FR-063-009）
      if (next.state == TTSState.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      // 読み上げが終了（speaking以外）したら読み上げ中ハイライトを解除
      if (next.state != TTSState.speaking && _speakingId != null) {
        setState(() => _speakingId = null);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(HistoryUIConstants.screenTitle),
        // 全削除ボタン（履歴が存在する場合のみ表示）
        actions: histories.isNotEmpty
            ? [
                IconButton(
                  icon: const Icon(Icons.delete_sweep),
                  onPressed: () => _showDeleteAllDialog(context),
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
                // 読み上げ中かつ対象項目が一致する場合のみ読み上げ中表示
                final isSpeaking = ttsState.state == TTSState.speaking &&
                    _speakingId == history.id;
                return HistoryItemCard(
                  key: Key('history_item_card_${history.id}'),
                  history: history,
                  isSpeaking: isSpeaking,
                  isFavorited: favoriteContents.contains(history.content),
                  onTap: () => _onHistoryTap(history.id, history.content),
                  onDelete: () => _deleteHistoryWithUndo(context, history),
                  onStop: _onStop,
                  onLongPress: () => _showContextMenu(context, history.content),
                  onFavoriteTap: () => _addToFavorite(context, history.content),
                );
              },
            ),
    );
  }

  /// 履歴項目タップ時の処理
  ///
  /// FR-061-006: 履歴項目をタップすると再読み上げを実行
  /// FR-063-008: 空文字列の読み上げを防止
  void _onHistoryTap(String id, String content) {
    // 空文字列の場合は読み上げを実行しない
    if (content.isEmpty) {
      return;
    }

    // 読み上げ対象の項目を記録（per-item表示のため）
    setState(() => _speakingId = id);
    ref.read(ttsProvider.notifier).speak(content);
  }

  /// 読み上げ停止処理
  void _onStop() {
    ref.read(ttsProvider.notifier).stop();
    setState(() => _speakingId = null);
  }

  /// 個別削除処理（確認なし・即削除 + Undo）
  ///
  /// 【改善】: 確認ダイアログは「はい」誤タップ時に復元できず、
  /// タップ数も増えるため廃止した。即削除のうえ、SnackBarの
  /// 「元に戻す」操作（8秒間）で誤操作から復元できるようにする。
  void _deleteHistoryWithUndo(BuildContext context, History history) {
    ref.read(historyProvider.notifier).deleteHistory(history.id);
    showUndoSnackBar(
      context,
      message: '削除しました',
      onUndo: () => ref.read(historyProvider.notifier).restoreLastDeleted(),
    );
  }

  /// 全削除確認ダイアログを表示
  ///
  /// FR-061-010: 全削除時に確認ダイアログを表示
  /// 【改善】: 全削除は影響範囲が大きいため確認ダイアログは維持しつつ、
  /// 実行後にUndo SnackBarを表示し誤操作から復元できるようにする。
  void _showDeleteAllDialog(BuildContext context) {
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
            showUndoSnackBar(
              context,
              message: 'すべて削除しました',
              onUndo: () =>
                  ref.read(historyProvider.notifier).restoreClearedHistories(),
            );
          },
          onCancel: () => Navigator.of(dialogContext).pop(),
        );
      },
    );
  }

  /// コンテキストメニューを表示
  ///
  /// REQ-701: 履歴からお気に入りに追加
  void _showContextMenu(BuildContext context, String content) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.favorite_border),
                title: const Text(HistoryUIConstants.addToFavoriteLabel),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _addToFavorite(context, content);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// お気に入りに追加
  ///
  /// REQ-701: お気に入り追加機能
  void _addToFavorite(BuildContext context, String content) {
    final favoriteState = ref.read(favoriteProvider);
    final isDuplicate =
        favoriteState.favorites.any((f) => f.content == content);

    if (isDuplicate) {
      // 重複の場合
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(HistoryUIConstants.addToFavoriteDuplicate),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } else {
      // 追加成功
      ref.read(favoriteProvider.notifier).addFavorite(content);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(HistoryUIConstants.addToFavoriteSuccess),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
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
