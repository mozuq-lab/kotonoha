import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kotonoha_app/core/persistence/settings_write_failure_provider.dart';
import 'package:kotonoha_app/features/preset_phrase/domain/phrase_constants.dart';

typedef PhraseDraft = ({String id, String content, String category});

/// 追加下書きと他の有効entryを単一mapで保持する。SDKのcacheは成功判定に使わない。
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
    _record(phraseDraftReadKey, valid);
    return true;
  }

  PhraseDraft? readAdd() => _entries['add'];

  void changeAdd(PhraseDraft draft) {
    if (!_loaded || _disposed || _removing != null) return;
    _entries = {..._entries, 'add': draft};
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 400), flush);
  }

  Future<bool> flush() {
    _timer?.cancel();
    if (_removing != null) return _removing!;
    if (!_loaded || _disposed) return Future.value(false);
    return _write({..._entries});
  }

  Future<bool> removeAdd() {
    _timer?.cancel();
    if (_removing != null) return _removing!;
    if (!_loaded || _disposed) return Future.value(false);
    final next = {..._entries}..remove('add');
    // paused中のflushもこの操作へ合流し、古いmapをclearの後へ載せない。
    return _removing = _write(next).then((succeeded) {
      if (succeeded) _entries = next;
      return succeeded;
    }).whenComplete(() => _removing = null);
  }

  Future<bool> _write(Map<String, PhraseDraft> snapshot) {
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
      _record(phraseDraftWriteKey, succeeded);
      return succeeded;
    });
  }

  void _record(String key, bool succeeded) {
    if (!_disposed) _report(key, succeeded);
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
