import 'package:hive_flutter/hive_flutter.dart';
import 'package:kotonoha_app/core/persistence/persisted_box.dart';
import 'package:kotonoha_app/shared/models/favorite_item.dart';

/// Repository定義: お気に入りのHive永続化を担当するRepository
/// 実装内容: FavoriteItem のCRUD操作をHive Boxに委譲
/// 設計根拠: Repositoryパターンによりデータアクセス層を抽象化
/// 主要機能
/// loadAll: 全お気に入りをdisplayOrder昇順で取得
/// save: お気に入りを保存
/// getById: IDでお気に入りを取得（存在しない場合はnull）
/// delete: お気に入りを削除（存在しないIDでも例外なし）
/// deleteAll: 全お気に入りを削除
/// updateDisplayOrder: 並び順を単一更新
/// reorderFavorites: 並び順を一括更新
class FavoriteRepository {
  static const _initialFavoritesMarkerId = '__initial_favorites_done__';
  static const _initialContents = [
    '痛い',
    'トイレ',
    '暑い',
    '寒い',
    '水',
    '眠い',
    '助けて',
    '待って',
  ];

  /// フィールド定義: Hive Box（お気に入り保存用）
  /// 実装内容: コンストラクタで注入されたBoxを保持
  final PersistedBox<FavoriteItem> _box;

  /// コンストラクタ: Repository生成
  /// 実装内容: Hive Boxを外部から注入し、書き込みの成否を必ず報告する
  /// [PersistedBox] で包む。生の Box は保持しないため、報告を経由しない
  /// 書き込みを書くことができない（台帳 L-13）。
  /// [onWriteResult] は書き込みのたびに呼ばれる。省略時は何もしない
  /// （Hive を使わない既存テスト向け）。
  FavoriteRepository({
    required Box<FavoriteItem> box,
    void Function(bool succeeded)? onWriteResult,
  }) : _box = PersistedBox(box, onWriteResult: onWriteResult ?? _ignore);

  /// メソッド定義: 全お気に入りを読み込み（displayOrder昇順）
  /// 実装内容: Hive Boxから全データを取得し、displayOrderの昇順でソート
  /// 戻り値: `Future<List<FavoriteItem>>`（displayOrder昇順）
  /// 二次ソート: displayOrder同値の場合、createdAtの降順（新しい順）
  Future<List<FavoriteItem>> loadAll() async {
    return _getSortedFavorites();
  }

  /// メソッド定義: 全お気に入りを同期的に読み込み（displayOrder昇順）
  /// 実装内容: build等の同期コンテキストから利用するためのバージョン
  /// 戻り値: `List<FavoriteItem>`（displayOrder昇順）
  List<FavoriteItem> loadAllSortedSync() => _getSortedFavorites();

  /// メソッド定義: お気に入りを保存
  /// 実装内容: IDをキーとしてHive Boxに保存
  /// 引数: favorite - 保存するお気に入り
  Future<bool> save(FavoriteItem favorite) => _box.put(favorite.id, favorite);

  Future<bool> saveAll(Iterable<FavoriteItem> favorites) => _box.putAll({
        for (final favorite in favorites) favorite.id: favorite,
      });

  /// 初回だけ必須のお気に入りを作る。印は同じ box に置き、全削除後も残す。
  /// 項目と印を同じ Hive 書き込みで保存し、項目だけが残る失敗を避ける。
  Future<bool> ensureInitialFavorites() async {
    if (_box.get(_initialFavoritesMarkerId) != null) return true;
    final now = DateTime.now();
    final initial = <String, FavoriteItem>{};
    for (var index = 0; index < _initialContents.length; index++) {
      final id = 'initial-favorite-$index';
      if (_box.get(id) != null) continue;
      final colorValue = switch (index) {
        0 || 2 || 3 || 5 => 0xFFFF9800,
        _ => 0xFF2196F3,
      };
      initial[id] = FavoriteItem(
        id: id,
        content: _initialContents[index],
        createdAt: now,
        displayOrder: index,
        colorValue: colorValue,
      );
    }
    initial[_initialFavoritesMarkerId] = FavoriteItem(
      id: _initialFavoritesMarkerId,
      content: '',
      createdAt: now,
      displayOrder: -1,
    );
    return _box.putAll(initial);
  }

  /// メソッド定義: IDでお気に入りを取得
  /// 実装内容: IDをキーとしてHive Boxから取得
  /// 引数: id - 取得するお気に入りのID
  /// 戻り値: FavoriteItem?（存在しない場合はnull）
  Future<FavoriteItem?> getById(String id) async {
    return _box.get(id);
  }

  /// メソッド定義: お気に入りを削除
  /// 実装内容: IDをキーとしてHive Boxから削除
  /// 引数: id - 削除するお気に入りのID
  /// エッジケース: 存在しないIDでも例外を投げない
  Future<bool> delete(String id) => _box.delete(id);

  /// メソッド定義: 全お気に入りを削除
  /// 初期化済みの印を残し、利用者のお気に入りだけを消す。
  Future<bool> deleteAll() => _box.deleteAll(
        _box.values
            .where((item) => item.id != _initialFavoritesMarkerId)
            .map((item) => item.id),
      );

  /// メソッド定義: 並び順を単一更新
  /// 実装内容: 特定のお気に入りのdisplayOrderを更新
  /// 引数
  /// id: 更新するお気に入りのID
  /// newOrder: 新しいdisplayOrder値
  Future<void> updateDisplayOrder(String id, int newOrder) async {
    final favorite = await getById(id);
    if (favorite != null) {
      final updated = favorite.copyWith(displayOrder: newOrder);
      await save(updated);
    }
  }

  /// メソッド定義: 並び順を一括更新
  /// 実装内容: 複数のお気に入りのdisplayOrderを一括更新
  /// 引数: orderedIds - 新しい順序でのIDリスト
  Future<void> reorderFavorites(List<String> orderedIds) async {
    for (int i = 0; i < orderedIds.length; i++) {
      final id = orderedIds[i];
      await updateDisplayOrder(id, i);
    }
  }

  /// プライベートメソッド: 全お気に入りをdisplayOrder昇順でソート
  /// 実装内容: Hive Boxから全データを取得し、displayOrderの昇順でソート
  /// 二次ソート: displayOrder同値の場合、createdAtの降順（新しい順）
  /// 戻り値: `List<FavoriteItem>`（displayOrder昇順）
  List<FavoriteItem> _getSortedFavorites() {
    final favorites = _box.values
        .where((item) => item.id != _initialFavoritesMarkerId)
        .toList();
    // displayOrderの昇順でソート、同値の場合はcreatedAtの降順（新しい順）
    favorites.sort((a, b) {
      final orderCompare = a.displayOrder.compareTo(b.displayOrder);
      if (orderCompare != 0) return orderCompare;
      return b.createdAt.compareTo(a.createdAt); // 降順（新しい方が先）
    });
    return favorites;
  }
}

/// 書き込み結果を無視する既定の報告先
void _ignore(bool _) {}
