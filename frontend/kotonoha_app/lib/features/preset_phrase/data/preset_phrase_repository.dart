import 'package:hive_flutter/hive_flutter.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';

/// 【Repository定義】: 定型文のHive永続化を担当するRepository
/// 【実装内容】: PresetPhrase のCRUD操作をHive Boxに委譲
/// 【設計根拠】: Repositoryパターンによりデータアクセス層を抽象化
/// 🔵 信頼性レベル: 青信号 - architecture.mdのローカルストレージ設計に基づく
class PresetPhraseRepository {
  /// 【フィールド定義】: Hive Box（定型文保存用）
  /// 【実装内容】: コンストラクタで注入されたBoxを保持
  /// 🔵 信頼性レベル: 青信号 - TASK-0054で初期化済み
  final Box<PresetPhrase> _box;

  /// 【コンストラクタ】: Repository生成
  /// 【実装内容】: Hive Boxを外部から注入（テスト容易性のため）
  /// 🔵 信頼性レベル: 青信号 - DI（依存性注入）パターン
  PresetPhraseRepository({required Box<PresetPhrase> box}) : _box = box;

  /// 【メソッド定義】: 全定型文を読み込み
  /// 【実装内容】: Hive Boxから全データを取得してListで返す
  /// 【戻り値】: `List<PresetPhrase>`（0件の場合は空リスト）
  /// 🔵 信頼性レベル: 青信号 - REQ-104、EDGE-104対応
  Future<List<PresetPhrase>> loadAll() async {
    return _box.values.toList();
  }

  /// 【メソッド定義】: 定型文を保存（追加・更新）
  /// 【実装内容】: IDをキーとしてHive Boxに保存（同一IDは上書き）
  /// 【引数】: phrase - 保存する定型文
  /// 🔵 信頼性レベル: 青信号 - REQ-104（追加・編集機能）
  Future<void> save(PresetPhrase phrase) async {
    await _box.put(phrase.id, phrase);
  }

  /// 【メソッド定義】: 定型文を削除
  /// 【実装内容】: IDをキーとしてHive Boxから削除
  /// 【引数】: id - 削除する定型文のID
  /// 【エッジケース】: 存在しないIDでも例外を投げない（EDGE-010）
  /// 🔵 信頼性レベル: 青信号 - REQ-104（削除機能）、EDGE-010対応
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  /// 【メソッド定義】: 複数定型文を一括保存
  /// 【実装内容】: putAllで一括保存（効率的なバルク操作）
  /// 【引数】: phrases - 保存する定型文のリスト
  /// 🔵 信頼性レベル: 青信号 - REQ-107（初期データ投入）
  Future<void> saveAll(List<PresetPhrase> phrases) async {
    final map = {for (final p in phrases) p.id: p};
    await _box.putAll(map);
  }

  /// 【メソッド定義】: IDで定型文を取得
  /// 【実装内容】: IDをキーとしてHive Boxから取得
  /// 【引数】: id - 取得する定型文のID
  /// 【戻り値】: PresetPhrase?（存在しない場合はnull）
  /// 🔵 信頼性レベル: 青信号 - EDGE-009対応
  Future<PresetPhrase?> getById(String id) async {
    return _box.get(id);
  }
}
