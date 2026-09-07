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
  Future<void> save(FavoriteItem favorite) async {
    await _box.put(favorite.id, favorite);
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
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  /// メソッド定義: 全お気に入りを削除
  /// 実装内容: Hive Boxの全データをクリア
  Future<void> deleteAll() async {
    await _box.clear();
  }

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
    final favorites = _box.values.toList();
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
