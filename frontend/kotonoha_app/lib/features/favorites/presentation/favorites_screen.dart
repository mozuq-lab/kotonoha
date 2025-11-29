/// Favorites screen widget
///
/// TASK-0064: お気に入り一覧UI実装
/// TASK-0066: お気に入り追加・削除・並び替え機能
/// 【TDD Greenフェーズ】: FavoritesScreen本実装
///
/// 信頼性レベル: 🔵 青信号（要件定義書ベース）
/// 関連要件: FR-064-001〜015, AC-064-001〜008, REQ-703
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../favorite/providers/favorite_provider.dart';
import '../../favorite/domain/models/favorite.dart';
import '../../tts/providers/tts_provider.dart';
import '../../tts/domain/models/tts_state.dart';
import 'widgets/favorite_item_card.dart';
import 'widgets/empty_favorite_widget.dart';
import 'constants/favorite_ui_constants.dart';

/// お気に入り画面ウィジェット
///
/// お気に入り登録したテキストを表示・管理する画面。
///
/// 機能:
/// - お気に入り一覧表示（displayOrder昇順）
/// - お気に入りタップで再読み上げ
/// - 個別削除機能
/// - 全削除機能
/// - 空状態表示
/// - 並び替え機能（REQ-703）
///
/// 実装要件:
/// - FR-064-001: お気に入りをdisplayOrder昇順に表示
/// - FR-064-006: タップで再読み上げ
/// - FR-064-007〜010: 削除機能（個別・全削除）
/// - NFR-064-001: 100件を1秒以内に表示
/// - NFR-064-005: タップターゲット44px以上
/// - REQ-703: 並び替え機能
class FavoritesScreen extends ConsumerStatefulWidget {
  /// お気に入り画面を作成する。
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  /// 編集モードフラグ
  bool _isEditMode = false;

  @override
  Widget build(BuildContext context) {
    // お気に入り状態を監視
    final favoriteState = ref.watch(favoriteProvider);
    final favorites = favoriteState.favorites;

    // displayOrder昇順にソート（FR-064-001, FR-064-011）
    final sortedFavorites = List<Favorite>.from(favorites)
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    // エラーメッセージを表示
    ref.listen<TTSServiceState>(ttsProvider, (previous, next) {
      if (next.state == TTSState.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(FavoriteUIConstants.screenTitle),
        actions: _buildAppBarActions(sortedFavorites),
      ),
      body: sortedFavorites.isEmpty
          ? const EmptyFavoriteWidget() // 空状態表示
          : _isEditMode
              ? _buildReorderableList(sortedFavorites)
              : _buildNormalList(sortedFavorites),
    );
  }

  /// AppBarのアクションボタンを構築
  List<Widget>? _buildAppBarActions(List<Favorite> favorites) {
    if (favorites.isEmpty) {
      return null;
    }

    return [
      // 編集ボタン（2件以上の場合のみ表示）
      if (favorites.length >= 2)
        IconButton(
          icon: Icon(_isEditMode ? Icons.check : Icons.edit),
          onPressed: _toggleEditMode,
          tooltip: _isEditMode
              ? FavoriteUIConstants.editDoneTooltip
              : FavoriteUIConstants.editTooltip,
        ),
      // 全削除ボタン（編集モードでない場合のみ表示）
      if (!_isEditMode)
        IconButton(
          icon: const Icon(Icons.delete_sweep),
          onPressed: () => _showDeleteAllDialog(context),
          tooltip: FavoriteUIConstants.deleteAllTooltip,
        ),
    ];
  }

  /// 編集モードをトグル
  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
    });
  }

  /// 通常表示のリストを構築
  Widget _buildNormalList(List<Favorite> favorites) {
    return ListView.builder(
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final favorite = favorites[index];
        return FavoriteItemCard(
          key: Key('favorite_item_card_${favorite.id}'),
          favorite: favorite,
          onTap: () => _onFavoriteTap(favorite.content),
          onDelete: () => _showDeleteDialog(context, favorite.id),
        );
      },
    );
  }

  /// 並び替え可能なリストを構築
  Widget _buildReorderableList(List<Favorite> favorites) {
    return ReorderableListView.builder(
      itemCount: favorites.length,
      onReorder: (oldIndex, newIndex) {
        _onReorder(favorites, oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final favorite = favorites[index];
        return _buildReorderableItem(favorite, index);
      },
    );
  }

  /// 並び替え用アイテムを構築
  Widget _buildReorderableItem(Favorite favorite, int index) {
    return Card(
      key: Key('reorderable_item_${favorite.id}'),
      margin: const EdgeInsets.symmetric(
        horizontal: FavoriteUIConstants.cardHorizontalMargin,
        vertical: FavoriteUIConstants.cardVerticalMargin,
      ),
      child: ListTile(
        leading: ReorderableDragStartListener(
          index: index,
          child: const Icon(Icons.drag_handle),
        ),
        title: Text(
          favorite.content,
          maxLines: FavoriteUIConstants.maxTextLines,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => _showDeleteDialog(context, favorite.id),
          tooltip: FavoriteUIConstants.deleteTooltip,
        ),
      ),
    );
  }

  /// 並び替え処理
  void _onReorder(List<Favorite> favorites, int oldIndex, int newIndex) {
    // ReorderableListViewの仕様: newIndex > oldIndex の場合、newIndex を -1 する
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final item = favorites[oldIndex];
    ref.read(favoriteProvider.notifier).reorderFavorite(item.id, newIndex);
  }

  /// お気に入り項目タップ時の処理
  ///
  /// FR-064-006: お気に入り項目をタップすると再読み上げを実行
  /// FR-064-013: 空文字列の読み上げを防止
  void _onFavoriteTap(String content) {
    // 空文字列の場合は読み上げを実行しない
    if (content.isEmpty) {
      return;
    }

    final ttsNotifier = ref.read(ttsProvider.notifier);
    ttsNotifier.speak(content);
  }

  /// 個別削除確認ダイアログを表示
  ///
  /// FR-064-008: 削除時に確認ダイアログを表示
  void _showDeleteDialog(BuildContext context, String id) {
    showDialog<void>(
      context: context,
      barrierDismissible: false, // FR-064-008: 誤操作防止
      builder: (BuildContext dialogContext) {
        return _ConfirmDialog(
          title: FavoriteUIConstants.confirmDialogTitle,
          content: FavoriteUIConstants.deleteConfirmMessage,
          onConfirm: () {
            Navigator.of(dialogContext).pop();
            ref.read(favoriteProvider.notifier).deleteFavorite(id);
          },
          onCancel: () => Navigator.of(dialogContext).pop(),
        );
      },
    );
  }

  /// 全削除確認ダイアログを表示
  ///
  /// FR-064-010: 全削除時に確認ダイアログを表示
  void _showDeleteAllDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false, // FR-064-010: 誤操作防止
      builder: (BuildContext dialogContext) {
        return _ConfirmDialog(
          title: FavoriteUIConstants.confirmDialogTitle,
          content: FavoriteUIConstants.deleteAllConfirmMessage,
          onConfirm: () {
            Navigator.of(dialogContext).pop();
            ref.read(favoriteProvider.notifier).clearAllFavorites();
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
          child: const Text(FavoriteUIConstants.cancelButtonLabel),
        ),
        TextButton(
          onPressed: onConfirm,
          child: const Text(FavoriteUIConstants.deleteButtonLabel),
        ),
      ],
    );
  }
}
