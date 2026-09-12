/// initHive が開く 3 つの box と「作り直した領域」の対応を実 box で確かめる（ADR-005、L-90）
///
/// initHive 全体は Hive.initFlutter（path_provider）を通るのでテストから呼べない。
/// 箱を開く部分だけを openPersistedBoxes に切り出し、破損ファイルを注入して
/// 戻り値の領域が正しいことを見る。crashRecovery: false で自前の復旧経路を通す
/// （本番既定の true では Hive 自身が黙って切り捨てるので経路に入らない。L-101）。名前と領域の食い違い（history の箱を作り直して
/// presetPhrases と告げる等）はここで赤になる。
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:kotonoha_app/core/persistence/persistence_state.dart';
import 'package:kotonoha_app/core/utils/hive_init.dart';
import 'package:kotonoha_app/shared/models/history_item.dart';
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
      () => openPersistedBoxes(hivePath: tempDir.path, crashRecovery: false),
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
      () => openPersistedBoxes(hivePath: tempDir.path, crashRecovery: false),
    );

    // Then: 領域の対応が正しく、退避ファイルが残り、3 つとも開いている
    expect(recreated, {PersistedArea.history});
    expect(
        File('${tempDir.path}/history.hive.corrupt.bak').existsSync(), isTrue);
    for (final area in PersistedArea.values) {
      expect(Hive.isBoxOpen(area.boxName), isTrue);
    }
  });

  test('presetPhrases の box が壊れていれば、作り直した領域は {presetPhrases} だけ', () async {
    await (await Hive.openBox<PresetPhrase>(
            PersistedArea.presetPhrases.boxName))
        .close();
    await corrupt(PersistedArea.presetPhrases);
    final recreated = await runGuardingHiveOpenLeak(
      () => openPersistedBoxes(hivePath: tempDir.path, crashRecovery: false),
    );
    expect(recreated, {PersistedArea.presetPhrases});
  });
}
