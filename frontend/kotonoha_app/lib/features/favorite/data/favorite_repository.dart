import 'package:hive_flutter/hive_flutter.dart';
import 'package:kotonoha_app/shared/models/favorite_item.dart';
import 'package:kotonoha_app/shared/models/history_item.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';
import 'package:uuid/uuid.dart';

/// 【Repository定義】: お気に入りのHive永続化を担当するRepository
/// 【実装内容】: FavoriteItem のCRUD操作をHive Boxに委譲
/// 【設計根拠】: Repositoryパターンによりデータアクセス層を抽象化
/// 🔵 信頼性レベル: 青信号 - architecture.mdのローカルストレージ設計に基づく
///
/// 【TDD Greenフェーズ】: テストを通す実装
/// 【主要機能】:
/// - loadAll(): 全お気に入りをdisplayOrder昇順で取得
/// - save(): お気に入りを保存
/// - getById(): IDでお気に入りを取得（存在しない場合はnull）
/// - delete(): お気に入りを削除（存在しないIDでも例外なし）
/// - deleteAll(): 全お気に入りを削除
/// - updateDisplayOrder(): 並び順を単一更新
/// - reorderFavorites(): 並び順を一括更新
/// - saveFromHistory(): 履歴からお気に入り作成
/// - saveFromPreset(): 定型文からお気に入り作成
/// - isDuplicate(): 重複チェック
class FavoriteRepository {
  /// 【フィールド定義】: Hive Box（お気に入り保存用）
  /// 【実装内容】: コンストラクタで注入されたBoxを保持
  /// 🔵 信頼性レベル: 青信号 - TASK-0054で初期化済み
  final Box<FavoriteItem> _box;

  /// 【フィールド定義】: UUID生成器
  /// 【実装内容】: 履歴・定型文からお気に入り作成時に新しいUUIDを生成
  /// 🔵 信頼性レベル: 青信号 - FR-065-005, FR-065-006
  final Uuid _uuid;

  /// 【コンストラクタ】: Repository生成
  /// 【実装内容】: Hive Boxを外部から注入（テスト容易性のため）
  /// 🔵 信頼性レベル: 青信号 - DI（依存性注入）パターン
  FavoriteRepository({required Box<FavoriteItem> box, Uuid? uuid})
      : _box = box,
        _uuid = uuid ?? const Uuid();

  /// 【メソッド定義】: 全お気に入りを読み込み（displayOrder昇順）
  /// 【実装内容】: Hive Boxから全データを取得し、displayOrderの昇順でソート
  /// 【戻り値】: `Future<List<FavoriteItem>>`（displayOrder昇順）
  /// 【二次ソート】: displayOrder同値の場合、createdAtの降順（新しい順）
  /// 🔵 信頼性レベル: 青信号 - REQ-701, FR-065-002, AC-065-004
  Future<List<FavoriteItem>> loadAll() async {
    return _getSortedFavorites();
  }

  /// 【メソッド定義】: 全お気に入りを同期的に読み込み（displayOrder昇順）
  /// 【実装内容】: build()等の同期コンテキストから利用するためのバージョン
  /// 【戻り値】: `List<FavoriteItem>`（displayOrder昇順）
  /// 🔵 信頼性レベル: 青信号 - Notifier.build()での初期化に使用
  List<FavoriteItem> loadAllSortedSync() => _getSortedFavorites();

  /// 【メソッド定義】: お気に入りを保存
  /// 【実装内容】: IDをキーとしてHive Boxに保存
  /// 【引数】: favorite - 保存するお気に入り
  /// 🔵 信頼性レベル: 青信号 - REQ-701, FR-065-002
  Future<void> save(FavoriteItem favorite) async {
    await _box.put(favorite.id, favorite);
  }

  /// 【メソッド定義】: IDでお気に入りを取得
  /// 【実装内容】: IDをキーとしてHive Boxから取得
  /// 【引数】: id - 取得するお気に入りのID
  /// 【戻り値】: FavoriteItem?（存在しない場合はnull）
  /// 🔵 信頼性レベル: 青信号 - FR-065-002, AC-065-012
  Future<FavoriteItem?> getById(String id) async {
    return _box.get(id);
  }

  /// 【メソッド定義】: お気に入りを削除
  /// 【実装内容】: IDをキーとしてHive Boxから削除
  /// 【引数】: id - 削除するお気に入りのID
  /// 【エッジケース】: 存在しないIDでも例外を投げない（EDGE-065-002）
  /// 🔵 信頼性レベル: 青信号 - REQ-704, FR-065-002, AC-065-011
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  /// 【メソッド定義】: 全お気に入りを削除
  /// 【実装内容】: Hive Boxの全データをクリア
  /// 🔵 信頼性レベル: 青信号 - REQ-704, FR-065-002, AC-065-003
  Future<void> deleteAll() async {
    await _box.clear();
  }

  /// 【メソッド定義】: 並び順を単一更新
  /// 【実装内容】: 特定のお気に入りのdisplayOrderを更新
  /// 【引数】:
  ///   - id: 更新するお気に入りのID
  ///   - newOrder: 新しいdisplayOrder値
  /// 🔵 信頼性レベル: 青信号 - REQ-703, FR-065-003, AC-065-005
  Future<void> updateDisplayOrder(String id, int newOrder) async {
    final favorite = await getById(id);
    if (favorite != null) {
      final updated = favorite.copyWith(displayOrder: newOrder);
      await save(updated);
    }
  }

  /// 【メソッド定義】: 並び順を一括更新
  /// 【実装内容】: 複数のお気に入りのdisplayOrderを一括更新
  /// 【引数】: orderedIds - 新しい順序でのIDリスト
  /// 🔵 信頼性レベル: 青信号 - REQ-703, FR-065-003, AC-065-006
  Future<void> reorderFavorites(List<String> orderedIds) async {
    for (int i = 0; i < orderedIds.length; i++) {
      final id = orderedIds[i];
      await updateDisplayOrder(id, i);
    }
  }

  /// 【メソッド定義】: 履歴からお気に入り作成
  /// 【実装内容】: 履歴のcontentを使用し、新しいUUIDで保存
  /// 【引数】: history - 元となる履歴アイテム
  /// 【戻り値】: 作成されたFavoriteItem
  /// 🔵 信頼性レベル: 青信号 - REQ-701, FR-065-005, AC-065-007
  Future<FavoriteItem> saveFromHistory(HistoryItem history) async {
    final maxOrder = _getMaxDisplayOrder();
    final favorite = FavoriteItem(
      id: _uuid.v4(),
      content: history.content,
      createdAt: DateTime.now(),
      displayOrder: maxOrder + 1,
    );
    await save(favorite);
    return favorite;
  }

  /// 【メソッド定義】: 定型文からお気に入り作成
  /// 【実装内容】: 定型文のcontentを使用し、新しいUUIDで保存
  /// 【引数】: preset - 元となる定型文
  /// 【戻り値】: 作成されたFavoriteItem
  /// 🔵 信頼性レベル: 青信号 - REQ-701, FR-065-006, AC-065-008
  Future<FavoriteItem> saveFromPreset(PresetPhrase preset) async {
    final maxOrder = _getMaxDisplayOrder();
    final favorite = FavoriteItem(
      id: _uuid.v4(),
      content: preset.content,
      createdAt: DateTime.now(),
      displayOrder: maxOrder + 1,
    );
    await save(favorite);
    return favorite;
  }

  /// 【メソッド定義】: 重複チェック
  /// 【実装内容】: 同じcontentのお気に入りが既に存在するかチェック
  /// 【引数】: content - チェックするテキスト
  /// 【戻り値】: bool（既存の場合true）
  /// 🟡 黄信号: FR-065-004, AC-065-013
  Future<bool> isDuplicate(String content) async {
    final favorites = await loadAll();
    return favorites.any((fav) => fav.content == content);
  }

  /// 【プライベートメソッド】: 全お気に入りをdisplayOrder昇順でソート
  /// 【実装内容】: Hive Boxから全データを取得し、displayOrderの昇順でソート
  /// 【二次ソート】: displayOrder同値の場合、createdAtの降順（新しい順）
  /// 【戻り値】: `List<FavoriteItem>`（displayOrder昇順）
  /// 🔵 信頼性レベル: 青信号 - FR-065-003, EDGE-065-005
  List<FavoriteItem> _getSortedFavorites() {
    final favorites = _box.values.toList();
    // displayOrderの昇順でソート、同値の場合はcreatedAtの降順（新しい順）
    favorites.sort((a, b) {
      final orderCompare = a.displayOrder.compareTo(b.displayOrder);
      if (orderCompare != 0) return orderCompare;
      return b.createdAt.compareTo(a.createdAt); // 降順（新しい方が先）
    });
    return favorites;
  }

  /// 【プライベートメソッド】: 最大displayOrder値を取得
  /// 【実装内容】: 現在保存されているお気に入りの最大displayOrderを返す
  /// 【戻り値】: int（お気に入りが0件の場合は-1）
  /// 🔵 信頼性レベル: 青信号 - FR-065-003
  int _getMaxDisplayOrder() {
    final favorites = _box.values.toList();
    if (favorites.isEmpty) return -1;
    return favorites.map((f) => f.displayOrder).reduce((a, b) => a > b ? a : b);
  }
}
