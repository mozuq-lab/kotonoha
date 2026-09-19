/// 書き込みの成否を必ず報告する Hive box のラッパー（ADR-005 / 台帳 L-13）
/// なぜラッパーにするか: box が**開いていても**書き込みは失敗しうる
/// （ディスクフル・権限・Web の quota 超過）。hive 2.2.3 の `_writeFrames` は
/// 失敗時にトランザクションを取り消して再送出するだけで box を閉じないため
/// `Hive.isBoxOpen` は true のままになる。
/// 「書き込み箇所ごとに try/catch を置いて報告する」形にすると
/// 書き忘れを検出する仕組みが別に要る。**生の [Box] を持たせず
/// 報告を通る書き込みしか書けないようにする**ことで、書き忘れ自体を
/// 表現できなくする（ADR-008 の教訓: 危険は検出可能にするのではなく
/// 表現不可能にする）。
library;

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// 書き込みの成否を報告しながら Hive box を読み書きする
/// 読み取りは素通し、書き込みは [_guard] を通る。
class PersistedBox<T> {
  final Box<T> _box;

  /// 書き込みのたびに呼ばれる。`true` が成功、`false` が失敗
  final void Function(bool succeeded) _onWriteResult;

  /// [box] を包む。[onWriteResult] は書き込みのたびに呼ばれる
  PersistedBox(
    Box<T> box, {
    required void Function(bool succeeded) onWriteResult,
  })  : _box = box,
        _onWriteResult = onWriteResult;

  /// 保存されている全要素
  Iterable<T> get values => _box.values;

  /// [key] に対応する要素（無ければ null）
  T? get(dynamic key) => _box.get(key);

  /// 保存されている要素数
  int get length => _box.length;

  /// [key] に [value] を書く
  Future<void> put(dynamic key, T value) => _guard(() => _box.put(key, value));

  /// [entries] をまとめて書く
  Future<void> putAll(Map<dynamic, T> entries) =>
      _guard(() => _box.putAll(entries));

  /// [key] を削除し、消した内容をファイルからも取り除く（台帳 L-119）
  /// Hive は追記型で、delete は「消した」という印のフレームを足すだけ。元の
  /// フレームは Hive 自身の compaction（削除 60 件超かつ 15% 超）まで残り、
  /// OS のバックアップにも乗る。保存しているのは利用者の発話そのものなので、
  /// 1 件ごとに compact して実際に取り除く（履歴の上限あふれもここを通る）。
  /// compact は別名に書いて rename する方式で、Hive は新しいファイルを
  /// fsync しない。直後の flush（fsync）で、電源断で中身が欠けうる時間を縮める。
  /// 欠けた場合は、次回起動時に退避と告知の経路に入る（`hive_init.dart`）。
  /// Web（IndexedDB）ではどちらも何もしない。
  Future<void> delete(dynamic key) => _guard(() async {
        await _box.delete(key);
        await _box.compact();
        await _box.flush();
      });

  /// すべて削除する
  /// clear はファイルを 0 に切り詰める。切り詰めを flush（fsync）で確定させ、
  /// 直後の電源断で消したはずの内容が戻らないようにする（台帳 L-119）。
  Future<void> clear() => _guard(() async {
        await _box.clear();
        await _box.flush();
      });

  /// 書き込みを実行し、成否を報告する
  /// 例外を飲む理由: ADR-005 は「保存されないことは伝えて**継続する**」と
  /// 定めている（: ストレージ障害でも文字盤・TTS は使えるべき）。
  /// 再送出すると、await していない呼び出し元では未処理の非同期エラーになり
  /// 利用者には何も伝わらないまま操作だけが壊れる。
  Future<void> _guard(Future<void> Function() write) async {
    try {
      await write();
      _onWriteResult(true);
    } catch (error, stackTrace) {
      debugPrint('[PersistedBox] 書き込みに失敗しました: $error');
      debugPrintStack(stackTrace: stackTrace);
      _onWriteResult(false);
    }
  }
}
