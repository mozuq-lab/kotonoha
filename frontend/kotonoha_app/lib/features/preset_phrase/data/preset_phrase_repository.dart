import 'package:hive_flutter/hive_flutter.dart';
import 'package:kotonoha_app/core/persistence/persisted_box.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';

/// Repository定義: 定型文のHive永続化を担当するRepository
/// 実装内容: PresetPhrase のCRUD操作をHive Boxに委譲
/// 設計根拠: Repositoryパターンによりデータアクセス層を抽象化
class PresetPhraseRepository {
  /// フィールド定義: Hive Box（定型文保存用）
  /// 実装内容: コンストラクタで注入されたBoxを保持
  final PersistedBox<PresetPhrase> _box;

  /// 実装内容: 読み込んだ定型文をメモリにキャッシュして2回目以降の読み込みを高速化
  /// 無効化タイミング: save/delete/saveAll実行時に自動で無効化
  List<PresetPhrase>? _cache;

  /// コンストラクタ: Repository生成
  /// 実装内容: Hive Boxを外部から注入し、書き込みの成否を必ず報告する
  /// [PersistedBox] で包む。生の Box は保持しないため、報告を経由しない
  /// 書き込みを書くことができない（台帳 L-13）。
  /// [onWriteResult] は書き込みのたびに呼ばれる。省略時は何もしない
  /// （Hive を使わない既存テスト向け）。
  PresetPhraseRepository({
    required Box<PresetPhrase> box,
    void Function(bool succeeded)? onWriteResult,
  }) : _box = PersistedBox(box, onWriteResult: onWriteResult ?? _ignore);

  /// メソッド定義: 全定型文を読み込み
  /// 実装内容: キャッシュがあればキャッシュを返し、なければHive Boxから読み込んでキャッシュ
  /// 戻り値: `List<PresetPhrase>`（0件の場合は空リスト）
  Future<List<PresetPhrase>> loadAll() async {
    // キャッシュがあればそれを返す（高速、防御的コピー）
    if (_cache != null) {
      return List<PresetPhrase>.from(_cache!);
    }

    // キャッシュがなければHiveから読み込んでキャッシュする
    _cache = _box.values.toList();
    // 内部キャッシュの参照を直接返さず、防御的コピーを返す
    return List<PresetPhrase>.from(_cache!);
  }

  /// メソッド定義: 全定型文を同期的に読み込み
  /// 実装内容: build等の同期コンテキストから利用するためのバージョン
  /// 戻り値: `List<PresetPhrase>`（防御的コピー、0件の場合は空リスト）
  List<PresetPhrase> loadAllSync() => List<PresetPhrase>.from(_box.values);

  /// メソッド定義: 全定型文を削除
  /// 実装内容: Hive Boxの全データをクリアしてキャッシュを無効化
  Future<void> deleteAll() async {
    await _box.clear();
    invalidateCache();
  }

  /// メソッド定義: 定型文を保存（追加・更新）
  /// 実装内容: IDをキーとしてHive Boxに保存（同一IDは上書き）してキャッシュを無効化
  /// 引数: phrase - 保存する定型文
  Future<void> save(PresetPhrase phrase) async {
    await _box.put(phrase.id, phrase);
    invalidateCache();
  }

  /// メソッド定義: 定型文を削除
  /// 実装内容: IDをキーとしてHive Boxから削除してキャッシュを無効化
  /// 引数: id - 削除する定型文のID
  /// エッジケース: 存在しないIDでも例外を投げない
  Future<void> delete(String id) async {
    await _box.delete(id);
    invalidateCache();
  }

  /// メソッド定義: 複数定型文を一括保存
  /// 実装内容: putAllで一括保存（効率的なバルク操作）してキャッシュを無効化
  /// 引数: phrases - 保存する定型文のリスト
  Future<void> saveAll(List<PresetPhrase> phrases) async {
    final map = {for (final p in phrases) p.id: p};
    await _box.putAll(map);
    invalidateCache();
  }

  /// メソッド定義: IDで定型文を取得
  /// 実装内容: IDをキーとしてHive Boxから取得
  /// 引数: id - 取得する定型文のID
  /// 戻り値: PresetPhrase?（存在しない場合はnull）
  Future<PresetPhrase?> getById(String id) async {
    return _box.get(id);
  }

  /// 実装内容: メモリキャッシュをクリアして次回のloadAllでHiveから再読み込み
  /// 呼び出しタイミング: save/delete/saveAll実行後に自動呼び出し
  void invalidateCache() {
    _cache = null;
  }
}

/// 書き込み結果を無視する既定の報告先
void _ignore(bool _) {}
