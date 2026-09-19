/// initHive が開く 3 つの box と「作り直した領域」の対応を実 box で確かめる（ADR-005、L-90）
///
/// initHive 全体は Hive.initFlutter（path_provider）を通るのでテストから呼べない。
/// 箱を開く部分だけを openPersistedBoxes に切り出し、破損ファイルを注入して
/// 戻り値の領域と結果が正しいことを見る。名前と領域の食い違い（history の箱を
/// 作り直して presetPhrases と告げる等）はここで赤になる。
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:kotonoha_app/core/persistence/persistence_state.dart';
import 'package:kotonoha_app/core/utils/hive_init.dart';
import 'package:kotonoha_app/shared/models/history_item.dart';
import 'package:kotonoha_app/shared/models/favorite_item.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';

import 'hive_open_leak_guard.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    await Hive.close();
    tempDir = await Directory.systemTemp.createTemp('hive_init_areas_');
    Hive.init(tempDir.path);
    registerPersistedTypeAdapters();
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<void> corrupt(PersistedArea area) async {
    final file = File('${tempDir.path}/${area.boxName.toLowerCase()}.hive');
    await file.writeAsString('CORRUPTED_FOR_TEST');
  }

  test('どの box も壊れていなければ、作り直した領域は空', () async {
    final recreated = await runGuardingHiveOpenLeak(
      () => openPersistedBoxes(hivePath: tempDir.path),
    );
    expect(recreated, isEmpty);
    for (final area in PersistedArea.values) {
      expect(Hive.isBoxOpen(area.boxName), isTrue,
          reason: '${area.boxName} が開いていること');
    }
  });

  test('history の box が壊れていれば、作り直した領域は {history} だけ', () async {
    // Given: history だけを壊す（一度作ってから中身を潰す）
    await (await Hive.openBox<HistoryItem>(PersistedArea.history.boxName))
        .close();
    await corrupt(PersistedArea.history);

    // When
    final recreated = await runGuardingHiveOpenLeak(
      () => openPersistedBoxes(hivePath: tempDir.path),
    );

    // Then: 領域の対応が正しく、退避ファイルが残り、3 つとも開いている
    expect(recreated, {PersistedArea.history: CorruptionOutcome.recreated});
    expect(
        File('${tempDir.path}/history.hive.corrupt.bak').existsSync(), isTrue);
    for (final area in PersistedArea.values) {
      expect(Hive.isBoxOpen(area.boxName), isTrue);
    }
  });

  test('history の末尾だけが壊れていれば、結果は {history: 救った} で、読める分が残る', () async {
    // Given: 1 件書いて閉じ、保存の途中で電源が落ちた形にする（末尾に半端なバイト列）
    final box = await Hive.openBox<HistoryItem>(PersistedArea.history.boxName);
    await box.put(
      'h1',
      HistoryItem(
        id: 'h1',
        content: 'こんにちは',
        createdAt: DateTime(2026, 9, 1),
        type: 'manualInput',
      ),
    );
    await box.close();
    await File('${tempDir.path}/history.hive')
        .writeAsBytes([0xFF, 0x00, 0x13, 0x37, 0x42], mode: FileMode.append);

    // When
    final outcomes = await runGuardingHiveOpenLeak(
      () => openPersistedBoxes(hivePath: tempDir.path),
    );

    // Then: 作り直しではなく救出として、領域つきで返る（ここが落ちると告知が出ない）
    expect(outcomes, {PersistedArea.history: CorruptionOutcome.salvaged});
    expect(Hive.box<HistoryItem>(PersistedArea.history.boxName).keys, ['h1']);
  });

  test('presetPhrases の box が壊れていれば、作り直した領域は {presetPhrases} だけ', () async {
    await (await Hive.openBox<PresetPhrase>(
            PersistedArea.presetPhrases.boxName))
        .close();
    await corrupt(PersistedArea.presetPhrases);
    final recreated = await runGuardingHiveOpenLeak(
      () => openPersistedBoxes(hivePath: tempDir.path),
    );
    expect(
        recreated, {PersistedArea.presetPhrases: CorruptionOutcome.recreated});
  });

  test('favorites の box が壊れていれば、作り直した領域は {favorites} だけ', () async {
    await (await Hive.openBox<FavoriteItem>(PersistedArea.favorites.boxName))
        .close();
    await corrupt(PersistedArea.favorites);
    final recreated = await runGuardingHiveOpenLeak(
      () => openPersistedBoxes(hivePath: tempDir.path),
    );
    expect(recreated, {PersistedArea.favorites: CorruptionOutcome.recreated});
  });
}
