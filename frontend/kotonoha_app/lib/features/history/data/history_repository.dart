import 'package:hive_flutter/hive_flutter.dart';
import 'package:kotonoha_app/shared/models/history_item.dart';

/// 【Repository定義】: 履歴のHive永続化を担当するRepository
/// 【実装内容】: HistoryItem のCRUD操作をHive Boxに委譲
/// 【設計根拠】: Repositoryパターンによりデータアクセス層を抽象化
/// 🔵 信頼性レベル: 青信号 - architecture.mdのローカルストレージ設計に基づく
///
/// 【TDD Greenフェーズ】: テストを通す実装が完了しました
/// 【主要機能】:
/// - loadAll(): 全履歴を最新順で取得
/// - save(): 履歴を保存（50件超過時は最古履歴を自動削除）
/// - getById(): IDで履歴を取得（存在しない場合はnull）
/// - delete(): 履歴を削除（存在しないIDでも例外なし）
/// - deleteAll(): 全履歴を削除
class HistoryRepository {
  /// 【定数定義】: 履歴の最大保存件数
  /// 【実装内容】: 50件を超えると最古の履歴を自動削除
  /// 🔵 信頼性レベル: 青信号 - REQ-602（50件上限管理）
  static const int maxHistoryCount = 50;

  /// 【フィールド定義】: Hive Box（履歴保存用）
  /// 【実装内容】: コンストラクタで注入されたBoxを保持
  /// 🔵 信頼性レベル: 青信号 - TASK-0054で初期化済み
  final Box<HistoryItem> _box;

  /// 【コンストラクタ】: Repository生成
  /// 【実装内容】: Hive Boxを外部から注入（テスト容易性のため）
  /// 🔵 信頼性レベル: 青信号 - DI（依存性注入）パターン
  HistoryRepository({required Box<HistoryItem> box}) : _box = box;

  /// 【メソッド定義】: 全履歴を読み込み（最新順）
  /// 【実装内容】: Hive Boxから全データを取得し、createdAtの降順でソート
  /// 【戻り値】: `Future<List<HistoryItem>>`（最新順にソート）
  /// 🔵 信頼性レベル: 青信号 - REQ-601, FR-062-002
  Future<List<HistoryItem>> loadAll() async {
    return _getSortedHistories();
  }

  /// 【メソッド定義】: 履歴を保存（50件超過時は自動削除）
  /// 【実装内容】: IDをキーとしてHive Boxに保存、50件超過時は最古履歴を削除
  /// 【引数】: history - 保存する履歴
  /// 🔵 信頼性レベル: 青信号 - REQ-601, REQ-602, FR-062-001, FR-062-003
  Future<void> save(HistoryItem history) async {
    // 上限超過時は最古履歴を削除
    if (_box.length >= maxHistoryCount && _box.get(history.id) == null) {
      // 新規追加の場合のみ上限チェック（上書き更新時は削除不要）
      await _deleteOldestHistory();
    }

    // 履歴を保存（同一IDは上書き）
    await _box.put(history.id, history);
  }

  /// 【メソッド定義】: 履歴を削除
  /// 【実装内容】: IDをキーとしてHive Boxから削除
  /// 【引数】: id - 削除する履歴のID
  /// 【エッジケース】: 存在しないIDでも例外を投げない（EDGE-006）
  /// 🔵 信頼性レベル: 青信号 - REQ-604, FR-062-004
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  /// 【メソッド定義】: 全履歴を削除
  /// 【実装内容】: Hive Boxの全データをクリア
  /// 🔵 信頼性レベル: 青信号 - REQ-604, FR-062-005
  Future<void> deleteAll() async {
    await _box.clear();
  }

  /// 【メソッド定義】: IDで履歴を取得
  /// 【実装内容】: IDをキーとしてHive Boxから取得
  /// 【引数】: id - 取得する履歴のID
  /// 【戻り値】: HistoryItem?（存在しない場合はnull）
  /// 🔵 信頼性レベル: 青信号 - REQ-603, FR-062-007
  Future<HistoryItem?> getById(String id) async {
    return _box.get(id);
  }

  /// 【プライベートメソッド】: 全履歴を最新順でソート
  /// 【実装内容】: Hive Boxから全データを取得し、createdAtの降順でソート
  /// 【戻り値】: `List<HistoryItem>`（最新順）
  /// 🔵 信頼性レベル: 青信号 - 共通処理の抽出
  List<HistoryItem> _getSortedHistories() {
    final histories = _box.values.toList();
    // createdAtの降順でソート（最新が先頭）
    histories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return histories;
  }

  /// 【プライベートメソッド】: 最古の履歴を削除
  /// 【実装内容】: createdAtが最も古い履歴を見つけて削除
  /// 🔵 信頼性レベル: 青信号 - 50件上限管理のための共通処理
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
