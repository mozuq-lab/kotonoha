/// 起動時に、前のセッションが残した消した内容・古い内容をファイルから取り除く
/// （台帳 L-120・L-121）
///
/// Hive は追記型で、削除も上書きも元のフレームをファイルに残す。書き込みのたびの
/// 掃除（`PersistedBox`）は削除だけを対象にしているので、上書きで置き換えられた
/// 古い内容は次の削除まで残る（L-120）。compact が一度失敗した box は、その
/// セッションの間ずっと掃除されない（hive 2.2.3 の `_compactionScheduled` が
/// 成功時にしか戻らない。L-121）。この修正より前のバージョンが残した分も同じ。
/// 起動時は書き込みが重ならないので、ここで 1 回だけ掃除する。
/// testWidgets ではなく test を使う（FakeAsync の下では Hive のファイル I/O が終わらない）。
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:kotonoha_app/core/persistence/persistence_state.dart';
import 'package:kotonoha_app/core/utils/hive_init.dart';
import 'package:kotonoha_app/shared/models/favorite_item.dart';
import 'package:kotonoha_app/shared/models/history_item.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';

import '../../support/hive_file_bytes.dart';
import 'hive_open_leak_guard.dart';

HistoryItem _history(String id, String content) => HistoryItem(
      id: id,
      content: content,
      createdAt: DateTime(2026, 9, 1),
      type: 'manualInput',
    );

PresetPhrase _phrase(String id, String content) => PresetPhrase(
      id: id,
      content: content,
      category: 'daily',
      displayOrder: 0,
      createdAt: DateTime(2026, 9, 1),
      updatedAt: DateTime(2026, 9, 1),
    );

FavoriteItem _favorite(String id, String content) => FavoriteItem(
      id: id,
      content: content,
      createdAt: DateTime(2026, 9, 1),
      displayOrder: 0,
    );

void main() {
  late Directory tempDir;

  setUp(() async {
    await Hive.close();
    tempDir = await Directory.systemTemp.createTemp('hive_startup_compact_');
    Hive.init(tempDir.path);
    registerPersistedTypeAdapters();
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  File fileOf(PersistedArea area) =>
      File('${tempDir.path}/${area.boxName.toLowerCase()}.hive');

  /// 起動相当（`initHive` のうち、箱を開く部分だけ）
  Future<Map<PersistedArea, CorruptionOutcome>> start() =>
      runGuardingHiveOpenLeak(() => openPersistedBoxes(hivePath: tempDir.path));

  test('前のセッションで上書きした古い内容は、起動時にファイルから消える', () async {
    // Given: 定型文を書いて、内容を書き換える（Hive は上書きでも元のフレームを残す）
    const area = PersistedArea.presetPhrases;
    final box = await Hive.openBox<PresetPhrase>(area.boxName);
    await box.put('p1', _phrase('p1', 'なおす前の文-AAA'));
    await box.put('p1', _phrase('p1', 'なおした後の文-BBB'));
    await box.close();
    expect(await fileContains(fileOf(area), 'なおす前の文-AAA'), isTrue,
        reason: '前提: 書き換える前の内容がファイルに残っている');

    // When
    await start();

    // Then: 古い内容は消え、今の内容は読める
    expect(await fileContains(fileOf(area), 'なおす前の文-AAA'), isFalse);
    expect(
        Hive.box<PresetPhrase>(area.boxName).get('p1')!.content, 'なおした後の文-BBB');
  });

  test('前のセッションで消した内容がファイルに残っていても、起動時に消える', () async {
    // Given: 掃除の無かった頃のアプリが残したファイル（生の Box は compact しない）
    const area = PersistedArea.history;
    final box = await Hive.openBox<HistoryItem>(area.boxName);
    await box.put('h1', _history('h1', 'けした発話-CCC'));
    await box.put('h2', _history('h2', 'のこす発話-DDD'));
    await box.delete('h1');
    await box.close();
    expect(await fileContains(fileOf(area), 'けした発話-CCC'), isTrue,
        reason: '前提: 消した発話がファイルに残っている');

    // When
    await start();

    // Then
    expect(await fileContains(fileOf(area), 'けした発話-CCC'), isFalse);
    expect(await fileContains(fileOf(area), 'のこす発話-DDD'), isTrue);
    expect(Hive.box<HistoryItem>(area.boxName).keys, ['h2']);
  });

  test('3 つの box すべてが掃除され、生きているデータは失われない', () async {
    // Given: 3 つとも「消した 1 件 + 残す 1 件」にする
    final history = await Hive.openBox<HistoryItem>('history');
    await history.put('h1', _history('h1', 'けす-履歴'));
    await history.put('h2', _history('h2', 'のこす-履歴'));
    await history.delete('h1');
    await history.close();

    final phrases = await Hive.openBox<PresetPhrase>('presetPhrases');
    await phrases.put('p1', _phrase('p1', 'けす-定型文'));
    await phrases.put('p2', _phrase('p2', 'のこす-定型文'));
    await phrases.delete('p1');
    await phrases.close();

    final favorites = await Hive.openBox<FavoriteItem>('favorites');
    await favorites.put('f1', _favorite('f1', 'けす-お気に入り'));
    await favorites.put('f2', _favorite('f2', 'のこす-お気に入り'));
    await favorites.delete('f1');
    await favorites.close();

    // When
    final outcomes = await start();

    // Then: どれも壊れていないので報告は無く、3 つとも掃除されている
    expect(outcomes, isEmpty);
    for (final area in PersistedArea.values) {
      expect(await fileContains(fileOf(area), 'けす-'), isFalse,
          reason: '${area.boxName} が掃除されていない');
      expect(await fileContains(fileOf(area), 'のこす-'), isTrue,
          reason: '${area.boxName} の生きているデータが消えた');
    }
    expect(Hive.box<HistoryItem>('history').keys, ['h2']);
    expect(Hive.box<PresetPhrase>('presetPhrases').keys, ['p2']);
    expect(Hive.box<FavoriteItem>('favorites').keys, ['f2']);
  });

  test('救出した box も掃除されるが、報告は「救った」のまま', () async {
    // Given: 1 件消して 1 件残した後、保存の途中で電源が落ちた形にする
    const area = PersistedArea.history;
    final box = await Hive.openBox<HistoryItem>(area.boxName);
    await box.put('h1', _history('h1', 'けした発話-EEE'));
    await box.put('h2', _history('h2', 'のこす発話-FFF'));
    await box.delete('h1');
    await box.close();
    await fileOf(area)
        .writeAsBytes([0xFF, 0x00, 0x13, 0x37, 0x42], mode: FileMode.append);

    // When
    final outcomes = await start();

    // Then: 救出の報告は変わらず、消した発話はファイルからも消えている
    expect(outcomes, {area: CorruptionOutcome.salvaged});
    expect(Hive.box<HistoryItem>(area.boxName).keys, ['h2']);
    expect(await fileContains(fileOf(area), 'けした発話-EEE'), isFalse);
  });
}
