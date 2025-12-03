// 【Provider定義】: お気に入り管理プロバイダー
// 【実装内容】: お気に入りのCRUD操作、並び替え機能を提供
// 【設計根拠】: REQ-701, REQ-702, REQ-703, REQ-704（お気に入り機能）
// 🔵 信頼性レベル: 青信号 - EARS要件定義書に基づく

import 'package:flutter_riverpod/flutter_riverpod.dart';
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
class FavoriteNotifier extends StateNotifier<FavoriteState> {
  FavoriteNotifier() : super(const FavoriteState());

  /// UUID生成用インスタンス
  static const _uuid = Uuid();

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
  }

  /// 【メソッド定義】: お気に入りを削除する
  /// 【実装内容】: 指定IDのお気に入りを削除
  /// 🔵 信頼性レベル: 青信号 - REQ-703（お気に入り削除）
  Future<void> deleteFavorite(String id) async {
    final index = state.favorites.indexWhere((f) => f.id == id);
    if (index == -1) return;

    final updatedFavorites = List<Favorite>.from(state.favorites);
    updatedFavorites.removeAt(index);
    state = state.copyWith(favorites: updatedFavorites);
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
  }

  /// 【メソッド定義】: お気に入りを読み込む
  /// 【実装内容】: ローカルストレージからお気に入りを読み込み
  /// 🟡 信頼性レベル: 黄信号 - 将来的にHiveから読み込み
  Future<void> loadFavorites() async {
    // 現在はメモリ内での管理のみ
    // 将来的にはHiveからの読み込みを実装（TASK-0059で対応）
    state = state.copyWith(isLoading: false);
  }

  /// 【メソッド定義】: 全お気に入りをクリアする
  /// 【実装内容】: 全てのお気に入りを削除
  /// 🔵 信頼性レベル: 青信号 - REQ-703（お気に入り削除）
  Future<void> clearAllFavorites() async {
    state = state.copyWith(favorites: []);
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
    final updatedFavorites = List<Favorite>.from(state.favorites);
    updatedFavorites.removeAt(index);
    state = state.copyWith(favorites: updatedFavorites);
  }
}

/// 【Provider定義】: FavoriteNotifierのProvider
/// 🔵 信頼性レベル: 青信号 - Riverpodパターンに基づく
final favoriteProvider =
    StateNotifierProvider<FavoriteNotifier, FavoriteState>((ref) {
  return FavoriteNotifier();
});
