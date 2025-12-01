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

  /// 【キャッシュフィールド】: メモリ内キャッシュ（TASK-0090: ローカルストレージ最適化）
  /// 【実装内容】: 読み込んだ定型文をメモリにキャッシュして2回目以降の読み込みを高速化
  /// 【無効化タイミング】: save/delete/saveAll実行時に自動で無効化
  /// 🔵 信頼性レベル: 青信号 - NFR-004パフォーマンス要件対応
  List<PresetPhrase>? _cache;

  /// 【コンストラクタ】: Repository生成
  /// 【実装内容】: Hive Boxを外部から注入（テスト容易性のため）
  /// 🔵 信頼性レベル: 青信号 - DI（依存性注入）パターン
  PresetPhraseRepository({required Box<PresetPhrase> box}) : _box = box;

  /// 【メソッド定義】: 全定型文を読み込み
  /// 【実装内容】: キャッシュがあればキャッシュを返し、なければHive Boxから読み込んでキャッシュ
  /// 【戻り値】: `List<PresetPhrase>`（0件の場合は空リスト）
  /// 【パフォーマンス】: 2回目以降の読み込みは10ms以内（TASK-0090）
  /// 🔵 信頼性レベル: 青信号 - REQ-104、EDGE-104対応、NFR-004パフォーマンス要件
  Future<List<PresetPhrase>> loadAll() async {
    // キャッシュがあればそれを返す（高速）
    if (_cache != null) {
      return _cache!;
    }

    // キャッシュがなければHiveから読み込んでキャッシュする
    _cache = _box.values.toList();
    return _cache!;
  }

  /// 【メソッド定義】: 定型文を保存（追加・更新）
  /// 【実装内容】: IDをキーとしてHive Boxに保存（同一IDは上書き）してキャッシュを無効化
  /// 【引数】: phrase - 保存する定型文
  /// 🔵 信頼性レベル: 青信号 - REQ-104（追加・編集機能）
  Future<void> save(PresetPhrase phrase) async {
    await _box.put(phrase.id, phrase);
    // データが更新されたのでキャッシュを無効化（TASK-0090）
    invalidateCache();
  }

  /// 【メソッド定義】: 定型文を削除
  /// 【実装内容】: IDをキーとしてHive Boxから削除してキャッシュを無効化
  /// 【引数】: id - 削除する定型文のID
  /// 【エッジケース】: 存在しないIDでも例外を投げない（EDGE-010）
  /// 🔵 信頼性レベル: 青信号 - REQ-104（削除機能）、EDGE-010対応
  Future<void> delete(String id) async {
    await _box.delete(id);
    // データが更新されたのでキャッシュを無効化（TASK-0090）
    invalidateCache();
  }

  /// 【メソッド定義】: 複数定型文を一括保存
  /// 【実装内容】: putAllで一括保存（効率的なバルク操作）してキャッシュを無効化
  /// 【引数】: phrases - 保存する定型文のリスト
  /// 🔵 信頼性レベル: 青信号 - REQ-107（初期データ投入）
  Future<void> saveAll(List<PresetPhrase> phrases) async {
    final map = {for (final p in phrases) p.id: p};
    await _box.putAll(map);
    // データが更新されたのでキャッシュを無効化（TASK-0090）
    invalidateCache();
  }

  /// 【メソッド定義】: IDで定型文を取得
  /// 【実装内容】: IDをキーとしてHive Boxから取得
  /// 【引数】: id - 取得する定型文のID
  /// 【戻り値】: PresetPhrase?（存在しない場合はnull）
  /// 🔵 信頼性レベル: 青信号 - EDGE-009対応
  Future<PresetPhrase?> getById(String id) async {
    return _box.get(id);
  }

  /// 【メソッド定義】: キャッシュを無効化（TASK-0090: ローカルストレージ最適化）
  /// 【実装内容】: メモリキャッシュをクリアして次回のloadAll()でHiveから再読み込み
  /// 【呼び出しタイミング】: save/delete/saveAll実行後に自動呼び出し
  /// 🔵 信頼性レベル: 青信号 - NFR-004パフォーマンス要件対応
  void invalidateCache() {
    _cache = null;
  }
}
