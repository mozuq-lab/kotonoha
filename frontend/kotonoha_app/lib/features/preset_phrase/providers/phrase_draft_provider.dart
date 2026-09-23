import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kotonoha_app/core/persistence/programming_error_report.dart';
import 'package:kotonoha_app/core/persistence/settings_write_failure_provider.dart';
import 'package:kotonoha_app/features/preset_phrase/domain/phrase_constants.dart';

typedef PhraseDraft = ({String id, String content, String category});

/// 追加（`add`）と編集（`edit:<id>`）の下書きを単一mapで保持する（台帳 L-158）。
/// SDKのcacheは成功判定に使わない。
class PhraseDrafts {
  PhraseDrafts(this._report);
  final void Function(String key, bool succeeded) _report;
  Map<String, PhraseDraft> _entries = {};
  Future<bool>? _initializing;
  Future<bool> _tail = Future.value(true);
  Future<bool>? _removing;
  Timer? _timer;
  bool _loaded = false;
  bool _disposed = false;

  /// 変更の通し番号。`_change`・`_remove` のたびに増える。
  int _changes = 0;

  /// storeが確かに持っていると分かっている通し番号。**書込を始めた時点**の
  /// 番号で更新する。「書込が完了したらdirtyを降ろす」にすると、書込中に
  /// 打ち直した分まで保存済みに見え、次のflushが黙ってskipする＝打ち直した
  /// 文が書かれないまま背景へ回る（台帳 L-159）。
  int _written = 0;

  /// 最後にstoreへ届いた内容から変わっているか。
  bool get _dirty => _changes != _written;

  Future<bool> initialize() {
    if (_loaded) return Future.value(true);
    return _initializing ??= _load().whenComplete(() => _initializing = null);
  }

  Future<bool> _load() async {
    Object? raw;
    try {
      raw = (await SharedPreferences.getInstance()).get(phraseDraftWriteKey);
    } catch (_) {
      _record(phraseDraftReadKey, false);
      return false; // 未読mapには一切書き込まない。
    }
    var valid = true;
    final entries = <String, PhraseDraft>{};
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw as String) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          final value = entry.value;
          if (value is Map &&
              value['id'] is String &&
              (value['id'] as String).isNotEmpty &&
              value['content'] is String &&
              PhraseConstants.validCategories.contains(value['category']) &&
              (entry.key == 'add' || entry.key == 'edit:${value['id']}')) {
            entries[entry.key] = (
              id: value['id'] as String,
              content: value['content'] as String,
              category: value['category'] as String
            );
          } else {
            valid = false;
          }
        }
      } catch (_) {
        valid = false;
      }
    }
    _entries = entries;
    _loaded = true;
    // 落とした不正entryは store との差＝「変更」。次のflushで掃除済みmapを
    // 書く。dirtyにしないとL-159以降は書き戻されず、読込エラーの告知が起動の
    // たびに出続ける（台帳 L-159 の副作用。監査 P1-1）。健全なstoreでは
    // 増えないので「変わっていなければ書かない」は保たれる。
    if (!valid) _changes++;
    _record(phraseDraftReadKey, valid);
    return true;
  }

  PhraseDraft? readAdd() => _entries['add'];

  PhraseDraft? readEdit(String id) => _entries['edit:$id'];

  /// 編集entry。元の定型文が消えたもの（孤立）も含む。
  Iterable<PhraseDraft> get edits => [
        for (final e in _entries.entries)
          if (e.key.startsWith('edit:')) e.value,
      ];

  void changeAdd(PhraseDraft draft) => _change('add', draft);

  void changeEdit(PhraseDraft draft) => _change('edit:${draft.id}', draft);

  void _change(String key, PhraseDraft draft) {
    if (!_loaded || _disposed || _removing != null) return;
    _entries = {..._entries, key: draft};
    _changes++;
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 400), flush);
  }

  Future<bool> flush() {
    _timer?.cancel();
    if (_removing != null) return _removing!;
    if (!_loaded || _disposed) return Future.value(false);
    // 変わっていないなら書かない。書くと、下書きを1度も打っていない利用者が
    // 背景へ回るたびに、存在しないものについての保存失敗を見る（台帳 L-159）。
    if (!_dirty) return Future.value(true);
    return _write({..._entries});
  }

  Future<bool> removeAdd() => _remove('add');

  Future<bool> removeEdit(String id) => _remove('edit:$id');

  /// 対象entryだけを消す。他のentryはそのまま書き戻す。
  Future<bool> _remove(String key) {
    if (_removing != null) return _removing!;
    if (!_loaded || _disposed) return Future.value(false);
    // 消すものが無ければ書かない。書くと、下書きを1度も打っていない利用者が
    // 「キャンセル」しただけで、書込が失敗したとき「下書きを消せませんでした。
    // 閉じると次回も残ります」＝事実と逆の告知を見る（L-159と同じ誤発報。
    // 監査 P1-4）。dirty は map 全体の数なので、他のentryの未書込も理由に
    // しない（Task 2 監査 A-4）。その未書込は自分のtimerとpausedのflushが書く
    // ので、ここでtimerも止めない。
    if (!_entries.containsKey(key)) return Future.value(true);
    _timer?.cancel();
    final next = {..._entries}..remove(key);
    // 消すものがあれば、消去は明示操作なので変わっていなくても必ず書く。
    _changes++;
    // paused中のflushもこの操作へ合流し、古いmapをclearの後へ載せない。
    return _removing = _write(next, clearing: true).then((succeeded) {
      if (succeeded) _entries = next;
      return succeeded;
    }).whenComplete(() => _removing = null);
  }

  Future<bool> _write(Map<String, PhraseDraft> snapshot,
      {bool clearing = false}) {
    // このsnapshotが表す通し番号。これ以降の変更は次のflushで書く。
    final writing = _changes;
    return _tail = _tail.then((_) async {
      var succeeded = false;
      try {
        final prefs = await SharedPreferences.getInstance();
        succeeded = await prefs.setString(
            phraseDraftWriteKey,
            jsonEncode({
              for (final entry in snapshot.entries)
                entry.key: {
                  'id': entry.value.id,
                  'content': entry.value.content,
                  'category': entry.value.category,
                },
            }));
      } catch (_) {
        // 例外でもqueueを完了させ、次の明示再試行へ進める。
      }
      // 消去の失敗では下書きが残るので、保存の失敗（閉じると消える）と分けて
      // 報告する（L-182）。消去より前の未書込があれば、保存の失敗も事実。
      final unsaved = !succeeded && (!clearing || _written != writing - 1);
      if (succeeded) _written = writing;
      _record(phraseDraftWriteKey, !unsaved);
      if (succeeded || clearing) _record(phraseDraftClearKey, succeeded);
      return succeeded;
    });
  }

  /// 報告は下書きの読み書きの成否と別物なので、ここで閉じる。
  /// 外へ投げると、`_write` では `_tail` が rejected になって以後の
  /// flush/removeAdd が全部 error になり（書込は成功しているのに
  /// 「消せませんでした」＝事実と逆）、`_load` では `initialize()` が
  /// reject してフォームが `_loading` のまま固まる（台帳 L-162、監査 P1-5）。
  /// 飲むだけにせず、`Error` は端末内のログへ出す。
  void _record(String key, bool succeeded) {
    if (_disposed) return;
    try {
      _report(key, succeeded);
    } catch (e, s) {
      reportDraftProgrammingError(e, s);
    }
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
  }
}

final phraseDraftProvider = Provider<PhraseDrafts>((ref) {
  final drafts = PhraseDrafts((key, succeeded) => ref
      .read(settingsWriteFailureProvider.notifier)
      .record(key: key, succeeded: succeeded));
  ref.onDispose(drafts.dispose);
  return drafts;
});
