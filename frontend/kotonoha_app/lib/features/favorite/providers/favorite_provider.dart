// 【Provider定義】: お気に入り管理プロバイダー
// 【実装内容】: お気に入りのCRUD操作、並び替え機能を提供
// 【設計根拠】: REQ-701, REQ-702, REQ-703, REQ-704（お気に入り機能）
// 🔵 信頼性レベル: 青信号 - EARS要件定義書に基づく

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kotonoha_app/shared/models/favorite_item.dart';
import 'package:kotonoha_app/shared/providers/repository_providers.dart';
import 'package:uuid/uuid.dart';
import '../domain/models/favorite.dart';

/// 【状態クラス定義】: お気に入り一覧の状態
/// 🔵 信頼性レベル: 青信号 - Riverpod標準パターン
class FavoriteState {
  /// お気に入り一覧
  final List<Favorite> favorites;

  /// ローディング状態
  final bool isLoading;

  /// エラーメッセージ
  final String? error;

  const FavoriteState({
    this.favorites = const [],
    this.isLoading = false,
    this.error,
  });

  FavoriteState copyWith({
    List<Favorite>? favorites,
    bool? isLoading,
    String? error,
  }) {
    return FavoriteState(
      favorites: favorites ?? this.favorites,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 【Notifier定義】: お気に入り状態管理Notifier
/// 【実装内容】: お気に入りのCRUD操作、並び替えを提供
/// 🔵 信頼性レベル: 青信号 - REQ-701〜704に基づく
class FavoriteNotifier extends Notifier<FavoriteState> {
  @override
  FavoriteState build() {
    // 【永続化配線】: Repositoryが利用可能（Boxオープン済み）の場合はHiveから初期化
    // 【フォールバック】: repo==nilの場合は従来どおりインメモリ空状態
    final repo = ref.read(favoriteRepositoryProvider);
    if (repo == null) return const FavoriteState();
    return FavoriteState(
      favorites: repo.loadAllSortedSync().map(_toDomain).toList(),
    );
  }

  /// UUID生成用インスタンス
  static const _uuid = Uuid();

  /// 【Undo用】: 直近に個別削除したお気に入りを一時保持する
  ///
  /// 【改善】: 個別削除は確認ダイアログを廃止し即削除としたため、
  /// 誤タップからの復元手段として「元に戻す」操作を提供する。
  Favorite? _lastDeletedFavorite;

  /// 【Undo用】: 直近に全削除する前のお気に入り一覧を一時保持する
  List<Favorite>? _lastClearedFavorites;

  /// 【変換ヘルパー】: Hiveモデル FavoriteItem → ドメイン Favorite
  Favorite _toDomain(FavoriteItem item) => Favorite(
        id: item.id,
        content: item.content,
        createdAt: item.createdAt,
        displayOrder: item.displayOrder,
        sourceType: item.sourceType,
        sourceId: item.sourceId,
      );

  /// 【変換ヘルパー】: ドメイン Favorite → Hiveモデル FavoriteItem
  FavoriteItem _toItem(Favorite f) => FavoriteItem(
        id: f.id,
        content: f.content,
        createdAt: f.createdAt,
        displayOrder: f.displayOrder,
        sourceType: f.sourceType,
        sourceId: f.sourceId,
      );

  /// 【メソッド定義】: お気に入りを追加する
  /// 【実装内容】: テキストを受け取り、新しいお気に入りを追加
  /// 🔵 信頼性レベル: 青信号 - REQ-701（お気に入り登録）
  Future<void> addFavorite(String content) async {
    // 空文字は追加しない
    if (content.isEmpty) return;

    // 重複チェック
    final exists = state.favorites.any((f) => f.content == content);
    if (exists) return;

    final now = DateTime.now();
    final newFavorite = Favorite(
      id: _uuid.v4(),
      content: content,
      createdAt: now,
      displayOrder: state.favorites.length,
    );

    final updatedFavorites = [...state.favorites, newFavorite];
    state = state.copyWith(favorites: updatedFavorites);

    // 【永続化】: repoがあればHiveに保存
    final repo = ref.read(favoriteRepositoryProvider);
    if (repo != null) {
      await repo.save(_toItem(newFavorite));
    }
  }

  /// 【メソッド定義】: お気に入りを削除する
  /// 【実装内容】: 指定IDのお気に入りを削除
  /// 🔵 信頼性レベル: 青信号 - REQ-703（お気に入り削除）
  Future<void> deleteFavorite(String id) async {
    final index = state.favorites.indexWhere((f) => f.id == id);
    if (index == -1) return;

    // 【Undo用】: 復元できるよう削除対象を退避しておく
    _lastDeletedFavorite = state.favorites[index];

    final updatedFavorites = List<Favorite>.from(state.favorites);
    updatedFavorites.removeAt(index);
    state = state.copyWith(favorites: updatedFavorites);

    // 【永続化】: repoがあればHiveから削除
    final repo = ref.read(favoriteRepositoryProvider);
    if (repo != null) {
      await repo.delete(id);
    }
  }

  /// 【メソッド定義】: 直近に削除したお気に入りを復元する（Undo）
  /// 🟡 信頼性レベル: 黄信号 - 誤操作防止のための改善（削除確認ダイアログ廃止に伴う代替手段）
  Future<void> restoreLastDeletedFavorite() async {
    final target = _lastDeletedFavorite;
    if (target == null) return;
    _lastDeletedFavorite = null;

    final updatedFavorites = [...state.favorites, target]
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    state = state.copyWith(favorites: updatedFavorites);

    final repo = ref.read(favoriteRepositoryProvider);
    if (repo != null) {
      await repo.save(_toItem(target));
    }
  }

  /// 【メソッド定義】: お気に入りの並び順を変更する
  /// 【実装内容】: 指定IDのお気に入りを新しい位置に移動
  /// 🔵 信頼性レベル: 青信号 - REQ-704（お気に入りの並び替え）
  Future<void> reorderFavorite(String id, int newOrder) async {
    final index = state.favorites.indexWhere((f) => f.id == id);
    if (index == -1) return;

    // 範囲チェック
    if (newOrder < 0 || newOrder >= state.favorites.length) {
      newOrder = newOrder.clamp(0, state.favorites.length - 1);
    }

    final updatedFavorites = List<Favorite>.from(state.favorites);
    final item = updatedFavorites.removeAt(index);
    updatedFavorites.insert(newOrder, item);

    // displayOrderを再計算
    final reorderedFavorites = updatedFavorites.asMap().entries.map((entry) {
      return entry.value.copyWith(displayOrder: entry.key);
    }).toList();

    state = state.copyWith(favorites: reorderedFavorites);

    // 【永続化】: repoがあれば並び順を一括保存
    final repo = ref.read(favoriteRepositoryProvider);
    if (repo != null) {
      for (final fav in reorderedFavorites) {
        await repo.save(_toItem(fav));
      }
    }
  }

  /// 【メソッド定義】: お気に入りを読み込む
  /// 【実装内容】: ローカルストレージからお気に入りを読み込み
  /// 🟡 信頼性レベル: 黄信号 - 将来的にHiveから読み込み
  Future<void> loadFavorites() async {
    final repo = ref.read(favoriteRepositoryProvider);
    if (repo != null) {
      // 【永続化】: Hiveからお気に入りを読み込み
      state = state.copyWith(
        favorites: repo.loadAllSortedSync().map(_toDomain).toList(),
        isLoading: false,
      );
      return;
    }
    // 【フォールバック】: インメモリ管理のみ
    state = state.copyWith(isLoading: false);
  }

  /// 【メソッド定義】: 全お気に入りをクリアする
  /// 【実装内容】: 全てのお気に入りを削除
  /// 🔵 信頼性レベル: 青信号 - REQ-703（お気に入り削除）
  Future<void> clearAllFavorites() async {
    // 【Undo用】: 復元できるよう削除前の一覧を退避しておく
    _lastClearedFavorites = List<Favorite>.from(state.favorites);

    final repo = ref.read(favoriteRepositoryProvider);
    if (repo != null) {
      // 【永続化】: Hiveの全お気に入りを削除
      await repo.deleteAll();
    }
    state = state.copyWith(favorites: []);
  }

  /// 【メソッド定義】: 直近の全削除を取り消し、お気に入りを復元する（Undo）
  /// 🟡 信頼性レベル: 黄信号 - 誤操作防止のための改善
  Future<void> restoreClearedFavorites() async {
    final cleared = _lastClearedFavorites;
    if (cleared == null || cleared.isEmpty) return;
    _lastClearedFavorites = null;

    state = state.copyWith(favorites: cleared);

    final repo = ref.read(favoriteRepositoryProvider);
    if (repo != null) {
      for (final favorite in cleared) {
        await repo.save(_toItem(favorite));
      }
    }
  }

  /// 【メソッド定義】: 定型文由来のお気に入りを追加する
  /// 【機能概要】: 定型文からお気に入りを追加する際、元データ情報を保持
  /// 【実装方針】: sourceType='preset_phrase', sourceId=定型文IDを設定
  /// 【テスト対応】: TC-SYNC-001, TC-SYNC-003, TC-SYNC-301
  /// 🟡 信頼性レベル: 黄信号 - TDD-FAVORITE-SYNC要件定義に基づく
  Future<void> addFavoriteFromPresetPhrase(
      String content, String sourceId) async {
    // 【入力値検証】: 空文字は追加しない
    if (content.isEmpty) return;

    // 【重複チェック】: 同じsourceIdの定型文由来お気に入りが既に存在する場合は追加しない
    // 【処理方針】: sourceIdで重複を判定（contentではなく）
    final existsBySourceId = state.favorites.any((f) => f.sourceId == sourceId);
    if (existsBySourceId) return;

    // 【Favorite作成】: 定型文由来のお気に入りを作成
    final now = DateTime.now();
    final newFavorite = Favorite(
      id: _uuid.v4(),
      content: content,
      createdAt: now,
      displayOrder: state.favorites.length,
      sourceType: 'preset_phrase', // 【元データ種類】: 定型文由来を示す
      sourceId: sourceId, // 【元データID】: 定型文のIDを保持
    );

    // 【状態更新】: Favoriteリストに追加
    final updatedFavorites = [...state.favorites, newFavorite];
    state = state.copyWith(favorites: updatedFavorites);

    // 【永続化】: repoがあればHiveに保存（sourceType/sourceId含む）
    final repo = ref.read(favoriteRepositoryProvider);
    if (repo != null) {
      await repo.save(_toItem(newFavorite));
    }
  }

  /// 【メソッド定義】: sourceIdに一致するお気に入りを削除する
  /// 【機能概要】: 定型文のお気に入り解除時に対応するFavoriteを削除
  /// 【実装方針】: sourceIdで検索して削除
  /// 【テスト対応】: TC-SYNC-002, TC-SYNC-202, TC-SYNC-302, TC-SYNC-303
  /// 🟡 信頼性レベル: 黄信号 - TDD-FAVORITE-SYNC要件定義に基づく
  Future<void> deleteFavoriteBySourceId(String sourceId) async {
    // 【検索】: sourceIdに一致するFavoriteを検索
    final index = state.favorites.indexWhere((f) => f.sourceId == sourceId);

    // 【該当なし処理】: 一致するものがなければ何もしない（TC-SYNC-303）
    if (index == -1) return;

    // 【削除処理】: 一致するFavoriteを削除
    final removed = state.favorites[index];
    final updatedFavorites = List<Favorite>.from(state.favorites);
    updatedFavorites.removeAt(index);
    state = state.copyWith(favorites: updatedFavorites);

    // 【永続化】: repoがあればHiveから削除
    final repo = ref.read(favoriteRepositoryProvider);
    if (repo != null) {
      await repo.delete(removed.id);
    }
  }
}

/// 【Provider定義】: FavoriteNotifierのProvider
/// 🔵 信頼性レベル: 青信号 - Riverpodパターンに基づく
final favoriteProvider = NotifierProvider<FavoriteNotifier, FavoriteState>(
  FavoriteNotifier.new,
);
