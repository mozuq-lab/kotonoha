// 個別に消した項目が、端末のファイルにも残らない（台帳 L-119）
// Hive は追記型で、delete は「消した」という印のフレームを足すだけ。元のフレームは
// compaction（削除 60 件超かつ 15% 超）までファイルに残り、OS のバックアップにも乗る。
// 保存しているのは利用者の発話そのものなので、消したものはファイルからも消す。
// 観測点は実ファイルのバイト列（box の中身ではなく）。box を閉じずに読む
// （電源断を想定し、close 時の処理に頼らない）。
// testWidgets ではなく test を使う（FakeAsync の下では Hive のファイル I/O が終わらない）。

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kotonoha_app/core/persistence/persisted_box.dart';
import 'package:kotonoha_app/features/history/data/history_repository.dart';
import 'package:kotonoha_app/shared/models/history_item.dart';
import 'package:kotonoha_app/shared/models/history_item_adapter.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';
import 'package:kotonoha_app/shared/models/preset_phrase_adapter.dart';
import 'package:mocktail/mocktail.dart';

/// Hive の Box（外部 SDK の境界）。fsync の有無と compact の失敗は、実ファイルでは
/// 観測・注入できないので、ここだけモックで見る
class _MockBox extends Mock implements Box<PresetPhrase> {}

/// [file] のバイト列に [text]（UTF-8）が含まれるか
Future<bool> _fileContains(File file, String text) async {
  final haystack = await file.readAsBytes();
  final needle = utf8.encode(text);
  for (var i = 0; i + needle.length <= haystack.length; i++) {
    var matched = true;
    for (var j = 0; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) {
        matched = false;
        break;
      }
    }
    if (matched) return true;
  }
  return false;
}

PresetPhrase _phrase(String id, String content) => PresetPhrase(
      id: id,
      content: content,
      category: 'daily',
      displayOrder: 0,
      createdAt: DateTime(2026, 9, 1),
      updatedAt: DateTime(2026, 9, 1),
    );

void main() {
  late Directory tempDir;

  setUp(() async {
    await Hive.close();
    tempDir = await Directory.systemTemp.createTemp('persisted_box_delete_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(HistoryItemAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(PresetPhraseAdapter());
    }
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('個別に削除した項目の内容は、ファイルの中にも残らない', () async {
    final box = await Hive.openBox<PresetPhrase>('presetPhrases');
    final file = File('${tempDir.path}/presetphrases.hive');
    final results = <bool>[];
    final persisted = PersistedBox<PresetPhrase>(
      box,
      onWriteResult: results.add,
    );
    await persisted.put('keep', _phrase('keep', 'のこす文-AAA'));
    await persisted.put('gone', _phrase('gone', 'けす文-BBB'));
    await box.flush();
    expect(await _fileContains(file, 'けす文-BBB'), isTrue,
        reason: '前提: 消す前はファイルにある');

    // When
    await persisted.delete('gone');

    // Then: 消した内容はファイルに無く、残した内容はある
    expect(await _fileContains(file, 'けす文-BBB'), isFalse,
        reason: '消した発話が端末のファイルと OS のバックアップに残る');
    expect(await _fileContains(file, 'のこす文-AAA'), isTrue);
    expect(results, everyElement(isTrue));
  });

  test('全削除した内容は、ファイルの中にも残らない', () async {
    final box = await Hive.openBox<PresetPhrase>('presetPhrases');
    final file = File('${tempDir.path}/presetphrases.hive');
    final persisted = PersistedBox<PresetPhrase>(box, onWriteResult: (_) {});
    await persisted.put('a', _phrase('a', 'ぜんぶけす文-CCC'));
    await box.flush();
    expect(await _fileContains(file, 'ぜんぶけす文-CCC'), isTrue);

    await persisted.clear();

    expect(await _fileContains(file, 'ぜんぶけす文-CCC'), isFalse);
    expect(await file.length(), 0);
  });

  test('削除の後も、残した項目は再起動相当で読め、続けて保存できる', () async {
    var box = await Hive.openBox<PresetPhrase>('presetPhrases');
    var persisted = PersistedBox<PresetPhrase>(box, onWriteResult: (_) {});
    await persisted.put('a', _phrase('a', '文-A'));
    await persisted.put('b', _phrase('b', '文-B'));
    await persisted.delete('a');
    await persisted.put('c', _phrase('c', '文-C'));
    await box.close();

    // When: 再起動相当
    box = await Hive.openBox<PresetPhrase>('presetPhrases');
    persisted = PersistedBox<PresetPhrase>(box, onWriteResult: (_) {});

    // Then
    expect(box.keys, ['b', 'c']);
    expect(persisted.get('b')!.content, '文-B');
    expect(persisted.get('c')!.content, '文-C');
  });

  test('削除の後に compact し、その後で flush（fsync）する', () async {
    final box = _MockBox();
    when(() => box.delete(any<dynamic>())).thenAnswer((_) async {});
    when(box.compact).thenAnswer((_) async {});
    when(box.flush).thenAnswer((_) async {});
    final results = <bool>[];

    await PersistedBox<PresetPhrase>(box, onWriteResult: results.add)
        .delete('gone');

    // rename で入れ替わった新しいファイルを、すぐ fsync する
    verifyInOrder([
      () => box.delete('gone'),
      box.compact,
      box.flush,
    ]);
    expect(results, [true]);
  });

  test('全削除の後に flush（fsync）して、切り詰めを確定させる', () async {
    final box = _MockBox();
    when(box.clear).thenAnswer((_) async => 0);
    when(box.flush).thenAnswer((_) async {});
    final results = <bool>[];

    await PersistedBox<PresetPhrase>(box, onWriteResult: results.add).clear();

    verifyInOrder([box.clear, box.flush]);
    expect(results, [true]);
  });

  test('compact に失敗したら、保存の失敗として報告する（消した内容が残ったことを黙らない）', () async {
    final box = _MockBox();
    when(() => box.delete(any<dynamic>())).thenAnswer((_) async {});
    when(box.compact).thenThrow(const FileSystemException('disk full'));
    when(box.flush).thenAnswer((_) async {});
    final results = <bool>[];

    await PersistedBox<PresetPhrase>(box, onWriteResult: results.add)
        .delete('gone');

    expect(results, [false]);
  });

  test('履歴が上限を超えて押し出された発話も、ファイルの中に残らない', () async {
    final box = await Hive.openBox<HistoryItem>('history');
    final file = File('${tempDir.path}/history.hive');
    final repository = HistoryRepository(box: box);

    // When: 上限 + 1 件を保存する（最古の 1 件が押し出される）
    for (var n = 1; n <= HistoryRepository.maxHistoryCount + 1; n++) {
      final label = n.toString().padLeft(3, '0');
      await repository.save(
        HistoryItem(
          id: 'h-$label',
          content: '発話-$label',
          createdAt: DateTime(2026, 9, 1).add(Duration(minutes: n)),
          type: 'manualInput',
        ),
      );
    }

    // Then
    expect(box.length, HistoryRepository.maxHistoryCount);
    expect(await _fileContains(file, '発話-001'), isFalse,
        reason: '押し出された発話がファイルに残る');
    expect(await _fileContains(file, '発話-002'), isTrue);
    expect(await _fileContains(file, '発話-051'), isTrue);
  });
}
