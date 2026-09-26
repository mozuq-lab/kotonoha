// Provider定義: お気に入り管理プロバイダー
// 実装内容: お気に入りのCRUD操作、並び替え機能を提供
// 設計根拠: , , , （お気に入り機能）

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kotonoha_app/shared/models/favorite_item.dart';
import 'package:kotonoha_app/shared/providers/repository_providers.dart';
import 'package:uuid/uuid.dart';
import '../domain/models/favorite.dart';

/// 状態クラス定義: お気に入り一覧の状態
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

  /// 状態コピー: 指定したフィールドのみを更新した新しい状態を返す
  /// エラーの扱い: `error` を省略した場合は現在のエラーを保持する。
  /// 明示的に消したい場合は `clearError: true` を指定すること。
  /// AIConversionState.copyWith と同じ「clearXxxフラグ方式」に統一している。
  FavoriteState copyWith({
    List<Favorite>? favorites,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return FavoriteState(
      favorites: favorites ?? this.favorites,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Notifier定義: お気に入り状態管理Notifier
/// 実装内容: お気に入りのCRUD操作、並び替えを提供
class FavoriteNotifier extends Notifier<FavoriteState> {
  Future<void>? _tail;

  /// IDと変更値を受け取り、最新の一覧から保存と表示までを1操作ずつ行う。
  Future<T> _inOrder<T>(Future<T> Function() operation) {
    final previous = _tail;
    final result =
        previous == null ? operation() : previous.then((_) => operation());
    late final Future<void> settled;
    settled = result
        .then<void>((_) {}, onError: (Object _, StackTrace __) {})
        .whenComplete(() {
      if (identical(_tail, settled)) _tail = null;
    });
    _tail = settled;
    return result;
  }

  Future<bool> updateFavoriteColor(String id, int colorValue) =>
      _inOrder(() => _updateFavoriteColor(id, colorValue));

  Future<bool> addFavorite(String content) =>
      _inOrder(() => _addFavorite(content));

  Future<bool> deleteFavorite(String id) => _inOrder(() => _deleteFavorite(id));

  Future<void> restoreLastDeletedFavorite() =>
      _inOrder(_restoreLastDeletedFavorite);

  Future<void> reorderFavorite(String id, int newOrder) =>
      _inOrder(() => _reorderFavorite(id, newOrder));

  Future<void> loadFavorites() => _inOrder(_loadFavorites);

  Future<bool> clearAllFavorites() => _inOrder(_clearAllFavorites);

  Future<void> restoreClearedFavorites() => _inOrder(_restoreClearedFavorites);

  Future<void> addFavoriteFromPresetPhrase(String content, String sourceId) =>
      _inOrder(() => _addFavoriteFromPresetPhrase(content, sourceId));

  Future<void> addFavoriteFromHistory(String content, String historyId) =>
      _inOrder(() => _addFavoriteFromHistory(content, historyId));

  Future<void> deleteFavoriteBySourceId(String sourceId) =>
      _inOrder(() => _deleteFavoriteBySourceId(sourceId));

  @override
  FavoriteState build() {
    // 永続化配線: Repositoryが利用可能（Boxオープン済み）の場合はHiveから初期化
    // フォールバック: repo==nilの場合は従来どおりインメモリ空状態
    final repo = ref.read(favoriteRepositoryProvider);
    if (repo == null) return const FavoriteState();
    return FavoriteState(
      favorites: repo.loadAllSortedSync().map(_toDomain).toList(),
    );
  }

  /// UUID生成用インスタンス
  static const _uuid = Uuid();

  /// Undo用: 直近に個別削除したお気に入りを一時保持する
  /// 改善: 個別削除は確認ダイアログを廃止し即削除としたため
  /// 誤タップからの復元手段として「元に戻す」操作を提供する。
  Favorite? _lastDeletedFavorite;

  /// Undo用: 直近に全削除する前のお気に入り一覧を一時保持する
  List<Favorite>? _lastClearedFavorites;

  /// 変換ヘルパー: Hiveモデル FavoriteItem → ドメイン Favorite
  Favorite _toDomain(FavoriteItem item) => Favorite(
        id: item.id,
        content: item.content,
        createdAt: item.createdAt,
        displayOrder: item.displayOrder,
        sourceType: item.sourceType,
        sourceId: item.sourceId,
        colorValue: item.colorValue,
      );

  /// 変換ヘルパー: ドメイン Favorite → Hiveモデル FavoriteItem
  FavoriteItem _toItem(Favorite f) => FavoriteItem(
        id: f.id,
        content: f.content,
        createdAt: f.createdAt,
        displayOrder: f.displayOrder,
        sourceType: f.sourceType,
        sourceId: f.sourceId,
        colorValue: f.colorValue,
      );

  /// お気に入りのボタン色を保存し、成功したときだけ表示へ反映する。
  Future<bool> _updateFavoriteColor(String id, int colorValue) async {
    final index = state.favorites.indexWhere((favorite) => favorite.id == id);
    if (index == -1) return false;
    final updated = state.favorites[index].copyWith(colorValue: colorValue);
    final repository = ref.read(favoriteRepositoryProvider);
    if (repository == null || !await repository.save(_toItem(updated))) {
      return false;
    }
    final favorites = List<Favorite>.from(state.favorites)..[index] = updated;
    state = state.copyWith(favorites: favorites);
    return true;
  }

  /// メソッド定義: お気に入りを追加する
  /// 実装内容: テキストを受け取り、新しいお気に入りを追加
  Future<bool> _addFavorite(String content) async {
    // 空文字は追加しない
    if (content.trim().isEmpty) return false;

    // 重複チェック
    final exists = state.favorites.any((f) => f.content == content);
    if (exists) return false;

    final now = DateTime.now();
    final newFavorite = Favorite(
      id: _uuid.v4(),
      content: content,
      createdAt: now,
      displayOrder: state.favorites.length,
    );

    // 永続化: repoがあればHiveに保存
    final repo = ref.read(favoriteRepositoryProvider);
    if (repo == null) {
      state = state.copyWith(favorites: [...state.favorites, newFavorite]);
      return false;
    }
    if (!await repo.save(_toItem(newFavorite))) return false;
    state = state.copyWith(favorites: [...state.favorites, newFavorite]);
    return true;
  }

  /// メソッド定義: お気に入りを削除する
  /// 実装内容: 指定IDのお気に入りを削除
  Future<bool> _deleteFavorite(String id) async {
    final index = state.favorites.indexWhere((f) => f.id == id);
    if (index == -1) return false;

    final removed = state.favorites[index];
    final updatedFavorites = List<Favorite>.from(state.favorites);
    updatedFavorites.removeAt(index);
    final repo = ref.read(favoriteRepositoryProvider);
    if (repo != null && !await repo.delete(id)) return false;
    _lastDeletedFavorite = removed;
    state = state.copyWith(favorites: updatedFavorites);
    return true;
  }

  /// メソッド定義: 直近に削除したお気に入りを復元する（Undo）
  Future<void> _restoreLastDeletedFavorite() async {
    final target = _lastDeletedFavorite;
    if (target == null) return;
    if (state.favorites.any((favorite) => favorite.id == target.id)) return;
    final updatedFavorites = [...state.favorites, target]
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    final repo = ref.read(favoriteRepositoryProvider);
    if (repo != null && !await repo.save(_toItem(target))) return;
    _lastDeletedFavorite = null;
    state = state.copyWith(favorites: updatedFavorites);
  }

  /// メソッド定義: お気に入りの並び順を変更する
  /// 実装内容: 指定IDのお気に入りを新しい位置に移動
  Future<void> _reorderFavorite(String id, int newOrder) async {
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

    final repo = ref.read(favoriteRepositoryProvider);
    if (repo != null && !await repo.saveAll(reorderedFavorites.map(_toItem))) {
      return;
    }
    state = state.copyWith(favorites: reorderedFavorites);
  }

  /// メソッド定義: お気に入りを読み込む
  /// 実装内容: ローカルストレージからお気に入りを読み込み
  Future<void> _loadFavorites() async {
    final repo = ref.read(favoriteRepositoryProvider);
    if (repo != null) {
      // 永続化: Hiveからお気に入りを読み込み
      state = state.copyWith(
        favorites: repo.loadAllSortedSync().map(_toDomain).toList(),
        isLoading: false,
      );
      return;
    }
    // フォールバック: インメモリ管理のみ
    state = state.copyWith(isLoading: false);
  }

  /// メソッド定義: 全お気に入りをクリアする
  /// 実装内容: 全てのお気に入りを削除
  Future<bool> _clearAllFavorites() async {
    final cleared = List<Favorite>.from(state.favorites);
    final repo = ref.read(favoriteRepositoryProvider);
    if (repo != null && !await repo.deleteAll()) return false;
    _lastClearedFavorites = cleared;
    state = state.copyWith(favorites: []);
    return true;
  }

  /// メソッド定義: 直近の全削除を取り消し、お気に入りを復元する（Undo）
  Future<void> _restoreClearedFavorites() async {
    final cleared = _lastClearedFavorites;
    if (cleared == null || cleared.isEmpty) return;
    final currentIds = state.favorites.map((favorite) => favorite.id).toSet();
    final restored = [
      ...cleared.where((favorite) => !currentIds.contains(favorite.id)),
      ...state.favorites,
    ].asMap().entries.map((entry) {
      return entry.value.copyWith(displayOrder: entry.key);
    }).toList();
    final repo = ref.read(favoriteRepositoryProvider);
    if (repo != null && !await repo.saveAll(restored.map(_toItem))) return;
    _lastClearedFavorites = null;
    state = state.copyWith(favorites: restored);
  }

  /// メソッド定義: 定型文由来のお気に入りを追加する
  /// 機能概要: 定型文からお気に入りを追加する際、元データ情報を保持
  /// 実装方針: sourceType='preset_phrase', sourceId=定型文IDを設定
  Future<void> _addFavoriteFromPresetPhrase(
      String content, String sourceId) async {
    // 入力値検証: 空文字は追加しない
    if (content.isEmpty) return;

    // 重複チェック: 同じsourceIdの定型文由来お気に入りが既に存在する場合は追加しない
    // 処理方針: sourceIdで重複を判定（contentではなく）
    final existsBySourceId = state.favorites.any((f) => f.sourceId == sourceId);
    if (existsBySourceId) return;

    // Favorite作成: 定型文由来のお気に入りを作成
    final now = DateTime.now();
    final newFavorite = Favorite(
      id: _uuid.v4(),
      content: content,
      createdAt: now,
      displayOrder: state.favorites.length,
      sourceType: 'preset_phrase', // 元データ種類: 定型文由来を示す
      sourceId: sourceId, // 元データID: 定型文のIDを保持
    );

    final repo = ref.read(favoriteRepositoryProvider);
    if (repo != null && !await repo.save(_toItem(newFavorite))) return;
    state = state.copyWith(favorites: [...state.favorites, newFavorite]);
  }

  /// メソッド定義: 履歴由来のお気に入りを追加する
  /// 機能概要: 履歴からお気に入りを追加する際、出所（履歴id）を記録する
  /// 重複判定: content一致（sourceId一致ではない）
  /// 理由: 履歴は同じ文言が何度でも生まれる（利用者が同じことを繰り返し発話する）。
  /// sourceIdで判定すると同じ文言を発話するたびにお気に入りが増え、一覧に同一文言が
  /// 並んでしまう。既存の addFavorite(String content) と同じcontent重複判定を使い
  /// sourceIdは出所の記録のためだけに持たせる（ADR-005 / Phase 3 WP-2 Stage 1）。
  Future<void> _addFavoriteFromHistory(String content, String historyId) async {
    // 入力値検証: 空文字は追加しない
    if (content.isEmpty) return;

    // 重複チェック: addFavoriteと同じcontent一致で判定する
    final exists = state.favorites.any((f) => f.content == content);
    if (exists) return;

    // Favorite作成: 履歴由来のお気に入りを作成
    final now = DateTime.now();
    final newFavorite = Favorite(
      id: _uuid.v4(),
      content: content,
      createdAt: now,
      displayOrder: state.favorites.length,
      sourceType: 'history', // 元データ種類: 履歴由来を示す
      sourceId: historyId, // 元データID: 履歴のIDを保持（重複判定には使わない）
    );

    final repo = ref.read(favoriteRepositoryProvider);
    if (repo != null && !await repo.save(_toItem(newFavorite))) return;
    state = state.copyWith(favorites: [...state.favorites, newFavorite]);
  }

  /// メソッド定義: sourceIdに一致するお気に入りを削除する
  /// 機能概要: 定型文のお気に入り解除時に対応するFavoriteを削除
  /// 実装方針: sourceIdで検索して削除
  Future<void> _deleteFavoriteBySourceId(String sourceId) async {
    // 検索: sourceIdに一致するFavoriteを検索
    final index = state.favorites.indexWhere((f) => f.sourceId == sourceId);

    // 該当なし処理: 一致するものがなければ何もしない
    if (index == -1) return;

    // 削除処理: 一致するFavoriteを削除
    final removed = state.favorites[index];
    final updatedFavorites = List<Favorite>.from(state.favorites);
    updatedFavorites.removeAt(index);
    final repo = ref.read(favoriteRepositoryProvider);
    if (repo != null && !await repo.delete(removed.id)) return;
    state = state.copyWith(favorites: updatedFavorites);
  }
}

/// Provider定義: FavoriteNotifierのProvider
final favoriteProvider = NotifierProvider<FavoriteNotifier, FavoriteState>(
  FavoriteNotifier.new,
);
