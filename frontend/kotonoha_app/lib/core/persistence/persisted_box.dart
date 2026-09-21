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
  Future<bool> put(dynamic key, T value) =>
      _inOrder(() => _box.put(key, value));

  /// [entries] をまとめて書く
  Future<void> putAll(Map<dynamic, T> entries) =>
      _inOrder(() => _box.putAll(entries));

  /// [key] を削除し、消した内容をファイルからも取り除く（台帳 L-119）
  /// Hive は追記型で、delete は「消した」という印のフレームを足すだけ。元の
  /// フレームは Hive 自身の compaction（削除 60 件超かつ 15% 超）まで残り、
  /// OS のバックアップにも乗る。保存しているのは利用者の発話そのものなので、
  /// 1 件ごとに実際に取り除く（履歴の上限あふれもここを通る）。
  Future<void> delete(dynamic key) => _inOrder(() async {
        await _box.delete(key);
        await _removeDeletedFromFile();
      });

  /// すべて削除する
  /// clear はファイルを 0 に切り詰める。切り詰めを flush（fsync）で確定させ、
  /// 直後の電源断で消したはずの内容が戻らないようにする（台帳 L-119）。
  Future<void> clear() => _inOrder(() async {
        await _box.clear();
        await _box.flush();
      });

  /// 実行中か待機中の最後の書き込み。無ければ null
  Future<void>? _lastWrite;

  /// このセッションで、前のセッションが残した分を取り除いたか
  bool _staleFramesRemoved = false;

  /// 書き込みを、呼ばれた順に 1 本ずつ実行する
  /// Hive の compact は、対象のフレームを集めるまでに await を挟む。その間に
  /// 既存キーへの上書き put が始まると、keystore 上の古いフレームが未書き込みの
  /// ものに置き換わり、書き直したファイルにその項目が入らない（その瞬間に
  /// 落ちると、その項目が消える）。compact の最中に始まった次の削除は、compact
  /// されずに残る。このアプリの書き込みはすべてここを通るので、1 本ずつにすれば
  /// どちらも起きない。
  /// 空いているときはその場で始める（後ろに並べるのは、走っている書き込みが
  /// あるときだけ）。待たずに書いて直後に読む呼び出し元から見た挙動を変えない。
  /// このセッションの最初の書き込みでは、前のセッションが残した分も取り除く
  /// （[_removeStaleFramesOnce]）。
  Future<bool> _inOrder(Future<void> Function() write) {
    Future<void> writeThenCleanUpOnce() async {
      await write();
      await _removeStaleFramesOnce();
    }

    final previous = _lastWrite;
    final result = previous == null
        ? _guard(writeThenCleanUpOnce)
        : previous.then((_) => _guard(writeThenCleanUpOnce));
    late final Future<void> settled;
    settled = result.then<void>((_) {}, onError: (Object _) {}).whenComplete(
      () {
        if (identical(_lastWrite, settled)) _lastWrite = null;
      },
    );
    _lastWrite = settled;
    return result;
  }

  /// 前のセッションが残した分を、このセッションで 1 回だけ取り除く（台帳 L-120・L-121）
  /// Hive は追記型で、上書きも元のフレームをファイルに残す。削除のたびの掃除
  /// （[_removeDeletedFromFile]）は削除だけを対象にしているので、上書きで
  /// 置き換えられた古い内容は次の削除まで残る（L-120）。掃除を持たない版が
  /// 書いたファイルも同じ（既存の端末）。compact が一度失敗した box は、その
  /// セッションの間ずっと掃除されない（L-121）。
  /// **上書きのたびには掃除しない**: compact は書き直して rename する操作で、
  /// Hive は rename の前に fsync しない。上書きは入力のたびに起きるので、毎回
  /// 挟むと電源断で失うものが「追記した 1 件」から「box 全体」に広がる。
  /// セッションに 1 回なら、その窓は 1 回で済む。
  /// 起動直後ではなく最初の書き込みに合わせる理由: 起動時に別枠で呼ぶと、box を
  /// 開くだけで何も書かないセッションでも compact を 1 回呼ぶことになる。
  /// **compact を呼ぶ機会は、それでも増える**: 直前の版では delete と clear だけが
  /// 呼んでいた。put しかしないセッションでも 1 回呼ぶので、そこで失敗すると、
  /// そのセッションの以後の削除は掃除されない（hive は一度失敗すると
  /// `_compactionScheduled` を true のままにし、以後の `compact()` は何もせずに
  /// 返る。`storage_backend_vm.dart:147-148`、台帳 L-125）。
  /// 受け入れた理由: 削除しない利用者のセッションは、これが無いと一度も掃除されず、
  /// 編集で置き換えた古い内容と、掃除を持たない版が残した分がいつまでも残る。
  /// 失敗するのは空き容量・権限が尽きた状況で、そこでは削除時の compact も同じく
  /// 失敗する。失っているのは「一度失敗した後に空きが戻ったセッション」だけ。
  /// 失敗しても書き込みは成功として報告する: 書き込み自体は済んでおり、
  /// 掃除は前のセッションの後始末なので、「保存できません」は誤報になる。
  Future<void> _removeStaleFramesOnce() async {
    if (_staleFramesRemoved) return;
    try {
      await _removeDeletedFromFile();
    } catch (error) {
      debugPrint('[PersistedBox] 前のセッションが残した分を取り除けませんでした: $error');
    }
  }

  /// 消した内容をファイルから取り除き、結果を fsync で確定させる
  /// compact は別名に書いて rename する方式で、Hive は新しいファイルを fsync
  /// しない。直後の flush で、電源断で中身が欠けうる時間を縮める（無くなりは
  /// しない。欠け方によっては次回起動時に告知されない。台帳 L-116）。
  /// compact の失敗は保存の失敗にしない: 削除そのものは済んでおり、保存できて
  /// いるのに「保存できません」と伝えるのは誤報になる。残った分は、次に compact
  /// が通ったときに取り除かれる（Hive は失敗後その box の compact を再開しない
  /// ので、実際には次回起動の後）。Web（IndexedDB）ではどちらも何もしない。
  Future<void> _removeDeletedFromFile() async {
    // 前のセッションの分も、この 1 回で一緒に取り除かれる
    _staleFramesRemoved = true;
    try {
      await _box.compact();
    } catch (error) {
      debugPrint('[PersistedBox] 消した内容をファイルから取り除けませんでした: $error');
    }
    await _box.flush();
  }

  /// 書き込みを実行し、成否を報告する
  /// 例外を飲む理由: ADR-005 は「保存されないことは伝えて**継続する**」と
  /// 定めている（: ストレージ障害でも文字盤・TTS は使えるべき）。
  /// 再送出すると、await していない呼び出し元では未処理の非同期エラーになり
  /// 利用者には何も伝わらないまま操作だけが壊れる。
  Future<bool> _guard(Future<void> Function() write) async {
    try {
      await write();
      _onWriteResult(true);
      return true;
    } catch (error, stackTrace) {
      debugPrint('[PersistedBox] 書き込みに失敗しました: $error');
      debugPrintStack(stackTrace: stackTrace);
      _onWriteResult(false);
      return false;
    }
  }
}
