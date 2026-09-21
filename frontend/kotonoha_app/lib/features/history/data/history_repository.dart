import 'package:hive_flutter/hive_flutter.dart';
import 'package:kotonoha_app/core/persistence/persisted_box.dart';
import 'package:kotonoha_app/shared/models/history_item.dart';

/// Repository定義: 履歴のHive永続化を担当するRepository
/// 実装内容: HistoryItem のCRUD操作をHive Boxに委譲
/// 設計根拠: Repositoryパターンによりデータアクセス層を抽象化
/// 主要機能
/// loadAll: 全履歴を最新順で取得
/// save: 履歴を保存（50件超過時は最古履歴を自動削除）
/// getById: IDで履歴を取得（存在しない場合はnull）
/// delete: 履歴を削除（存在しないIDでも例外なし）
/// deleteAll: 全履歴を削除
class HistoryRepository {
  /// 定数定義: 履歴の最大保存件数
  /// 実装内容: 50件を超えると最古の履歴を自動削除
  static const int maxHistoryCount = 50;

  /// フィールド定義: Hive Box（履歴保存用）
  /// 実装内容: コンストラクタで注入されたBoxを保持
  final PersistedBox<HistoryItem> _box;

  /// コンストラクタ: Repository生成
  /// 実装内容: Hive Boxを外部から注入し、書き込みの成否を必ず報告する
  /// [PersistedBox] で包む。生の Box は保持しないため、報告を経由しない
  /// 書き込みを書くことができない（台帳 L-13）。
  /// [onWriteResult] は書き込みのたびに呼ばれる。省略時は何もしない
  /// （Hive を使わない既存テスト向け）。
  HistoryRepository({
    required Box<HistoryItem> box,
    void Function(bool succeeded)? onWriteResult,
  }) : _box = PersistedBox(box, onWriteResult: onWriteResult ?? _ignore);

  /// メソッド定義: 全履歴を読み込み（最新順）
  /// 実装内容: Hive Boxから全データを取得し、createdAtの降順でソート
  /// 戻り値: `Future<List<HistoryItem>>`（最新順にソート）
  Future<List<HistoryItem>> loadAll() async {
    return _getSortedHistories();
  }

  /// メソッド定義: 全履歴を同期的に読み込み（最新順）
  /// 実装内容: build等の同期コンテキストから利用するためのバージョン
  /// 戻り値: `List<HistoryItem>`（最新順にソート）
  List<HistoryItem> loadAllSortedSync() => _getSortedHistories();

  /// メソッド定義: 履歴を保存（50件超過時は自動削除）
  /// 実装内容: IDをキーとしてHive Boxに保存、50件超過時は最古履歴を削除
  /// 引数: history - 保存する履歴
  Future<void> save(HistoryItem history) => _inOrder(() async {
        // 上限超過時は最古履歴を削除
        if (_box.length >= maxHistoryCount && _box.get(history.id) == null) {
          // 新規追加の場合のみ上限チェック（上書き更新時は削除不要）
          await _deleteOldestHistory();
        }

        // 履歴を保存（同一IDは上書き）
        await _box.put(history.id, history);
      });

  /// メソッド定義: 履歴を削除
  /// 実装内容: IDをキーとしてHive Boxから削除
  /// 引数: id - 削除する履歴のID
  /// エッジケース: 存在しないIDでも例外を投げない
  Future<void> delete(String id) => _inOrder(() => _box.delete(id));

  /// メソッド定義: 全履歴を削除
  /// 実装内容: Hive Boxの全データをクリア
  Future<void> deleteAll() => _inOrder(_box.clear);

  Future<void>? _lastWrite;

  // 上限判定・最古削除・保存を一つの操作として並べる。削除も同じ列に入れ、
  // 待機中の保存が全削除の後に復活することを防ぐ。
  Future<void> _inOrder(Future<void> Function() write) {
    final previous = _lastWrite;
    final result = previous == null ? write() : previous.then((_) => write());
    late final Future<void> settled;
    settled =
        result.then<void>((_) {}, onError: (Object _) {}).whenComplete(() {
      if (identical(_lastWrite, settled)) _lastWrite = null;
    });
    _lastWrite = settled;
    return result;
  }

  /// メソッド定義: IDで履歴を取得
  /// 実装内容: IDをキーとしてHive Boxから取得
  /// 引数: id - 取得する履歴のID
  /// 戻り値: HistoryItem?（存在しない場合はnull）
  Future<HistoryItem?> getById(String id) async {
    return _box.get(id);
  }

  /// プライベートメソッド: 全履歴を最新順でソート
  /// 実装内容: Hive Boxから全データを取得し、createdAtの降順でソート
  /// 戻り値: `List<HistoryItem>`（最新順）
  List<HistoryItem> _getSortedHistories() {
    final histories = _box.values.toList();
    // createdAtの降順でソート（最新が先頭）
    histories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return histories;
  }

  /// プライベートメソッド: 最古の履歴を削除
  /// 実装内容: createdAtが最も古い履歴を見つけて削除
  Future<void> _deleteOldestHistory() async {
    final histories = _box.values.toList();
    // createdAtの昇順でソート（最古が先頭）
    histories.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    if (histories.isNotEmpty) {
      final oldest = histories.first;
      await _box.delete(oldest.id);
    }
  }
}

/// 書き込み結果を無視する既定の報告先
void _ignore(bool _) {}
