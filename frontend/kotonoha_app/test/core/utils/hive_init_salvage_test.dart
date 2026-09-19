// 破損した box から読める分を救う（ADR-005、台帳 L-101）
// Hive 自身の自動復旧（crashRecovery: true）は、最初の壊れたフレーム以降を
// 黙ってファイルから切り捨てて開く。最も起きやすい破損（書き込み途中の電源断で
// 末尾が壊れる）で、退避も告知も無いまま一部が消える。切り捨てる前に退避し、
// 救った・失ったを呼び出し元へ伝えることを、実 box で確かめる。
// testWidgets ではなく test を使う（FakeAsync の下では Hive のファイル I/O が終わらない）。

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kotonoha_app/core/utils/hive_init.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';
import 'package:kotonoha_app/shared/models/preset_phrase_adapter.dart';

import 'hive_open_leak_guard.dart';

const _boxName = 'presetPhrases';

PresetPhrase _phrase(int n) => PresetPhrase(
      id: 'id-$n',
      content: '定型文 $n',
      category: 'daily',
      displayOrder: n,
      createdAt: DateTime(2026, 9, 1),
      updatedAt: DateTime(2026, 9, 1),
    );

/// 読み出しで必ず RangeError を投げる値（チェックサムは正しいのに中身を読めない
/// フレームを作るため）。Hive 自身の自動復旧でも開けない破損になる
class _Unreadable {}

class _UnreadableAdapter extends TypeAdapter<_Unreadable> {
  @override
  int get typeId => 60;

  @override
  _Unreadable read(BinaryReader reader) => throw RangeError('unreadable');

  @override
  void write(BinaryWriter writer, _Unreadable obj) => writer.writeByte(0);
}

/// 開いた結果と、呼び出し元へ伝わった内容
typedef _Opened = ({Box<PresetPhrase>? box, bool salvaged, bool recreated});

void main() {
  late Directory tempDir;
  late File boxFile;
  late File backupFile;

  setUp(() async {
    await closeHiveIgnoringMissingLock();
    tempDir = await Directory.systemTemp.createTemp('hive_salvage_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(PresetPhraseAdapter());
    }
    // Hive は box 名を小文字化してファイル名にする
    boxFile = File('${tempDir.path}/presetphrases.hive');
    backupFile = File('${tempDir.path}/presetphrases.hive.corrupt.bak');
  });

  tearDown(() async {
    await closeHiveIgnoringMissingLock();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  /// [count] 件を書いて閉じ、各フレームの終端のオフセットを返す
  Future<List<int>> writePhrases(int count) async {
    final box = await Hive.openBox<PresetPhrase>(_boxName);
    final frameEnds = <int>[];
    for (var n = 1; n <= count; n++) {
      await box.put('id-$n', _phrase(n));
      await box.flush();
      frameEnds.add(await boxFile.length());
    }
    await box.close();
    return frameEnds;
  }

  Future<_Opened> open({String? hivePath = ''}) async {
    var salvaged = false;
    var recreated = false;
    final box = await runGuardingHiveOpenLeak(
      () => openBoxWithRecovery<PresetPhrase>(
        _boxName,
        hivePath: hivePath == '' ? tempDir.path : hivePath,
        onSalvaged: () => salvaged = true,
        onRecreated: () => recreated = true,
      ),
    );
    return (box: box, salvaged: salvaged, recreated: recreated);
  }

  test('末尾が壊れた box は、切り捨てる前に退避してから読める分を残して開き、救ったと伝える', () async {
    // Given: 3 件書いた後、書き込み途中で電源が落ちた形（末尾に半端なバイト列）
    await writePhrases(3);
    await boxFile
        .writeAsBytes([0xFF, 0x00, 0x13, 0x37, 0x42], mode: FileMode.append);
    final corruptedBytes = await boxFile.readAsBytes();

    // When
    final opened = await open();

    // Then: 読める 3 件は残る
    expect(opened.box, isNotNull);
    expect(opened.box!.keys, ['id-1', 'id-2', 'id-3']);
    // 切り捨てる前の姿が退避されている
    expect(backupFile.existsSync(), isTrue, reason: '黙って切り捨てず、先に退避する');
    expect(await backupFile.readAsBytes(), equals(corruptedBytes));
    // 失った分があることを呼び出し元へ伝える（空で作り直したとは言わない）
    expect(opened.salvaged, isTrue);
    expect(opened.recreated, isFalse);
  });

  test('途中のフレームが壊れた box は、壊れた所より前だけを残し、救ったと伝える', () async {
    // Given: 3 件のうち 2 件目のフレームの中身を 1 バイト壊す
    final frameEnds = await writePhrases(3);
    final bytes = Uint8List.fromList(await boxFile.readAsBytes());
    bytes[frameEnds[0] + 6] ^= 0xFF;
    await boxFile.writeAsBytes(bytes);

    // When
    final opened = await open();

    // Then: 1 件目だけが残る（3 件目は無傷でも、Hive は壊れた所から後ろを読めない）
    expect(opened.box!.keys, ['id-1']);
    expect(await backupFile.readAsBytes(), equals(bytes),
        reason: '3 件目は退避ファイルの中にだけ残る');
    expect(opened.salvaged, isTrue);
    expect(opened.recreated, isFalse);
  });

  test('先頭から壊れていて何も救えない box は、退避して空で開き、作り直したと伝える', () async {
    await writePhrases(2);
    await boxFile.writeAsString('CORRUPTED_FROM_THE_FIRST_BYTE');
    final corruptedBytes = await boxFile.readAsBytes();

    final opened = await open();

    expect(opened.box!.isEmpty, isTrue);
    expect(await backupFile.readAsBytes(), equals(corruptedBytes));
    expect(opened.recreated, isTrue, reason: '何も残っていないのに「一部」とは言わない');
    expect(opened.salvaged, isFalse);
  });

  test('退避できないときは切り捨てもしない（元のファイルに手を付けず、開かない）', () async {
    await writePhrases(3);
    await boxFile
        .writeAsBytes([0xFF, 0x00, 0x13, 0x37, 0x42], mode: FileMode.append);
    final corruptedBytes = await boxFile.readAsBytes();

    // When: 退避先が分からない（hivePath が null）
    final opened = await open(hivePath: null);

    // Then: 開かず、末尾の壊れたバイト列ごと元のまま残っている
    expect(opened.box, isNull);
    expect(await boxFile.readAsBytes(), equals(corruptedBytes));
    expect(opened.salvaged, isFalse);
    expect(opened.recreated, isFalse);
  });

  test('救った box には書き込めて、次に開いたときは何も伝えない', () async {
    await writePhrases(3);
    await boxFile
        .writeAsBytes([0xFF, 0x00, 0x13, 0x37, 0x42], mode: FileMode.append);
    final first = await open();
    await first.box!.put('id-4', _phrase(4));
    await first.box!.close();

    // When: 再起動相当
    final second = await open();

    // Then: 救った 3 件と新しい 1 件が読め、告知は繰り返さない
    expect(second.box!.keys, ['id-1', 'id-2', 'id-3', 'id-4']);
    expect(second.salvaged, isFalse);
    expect(second.recreated, isFalse);
  });

  test('自動復旧でも開けない破損は、退避してから削除し、空で作り直したと伝える', () async {
    // Given: チェックサムは正しいが、中身を読むと RangeError になるフレーム
    if (!Hive.isAdapterRegistered(60)) {
      Hive.registerAdapter(_UnreadableAdapter());
    }
    const name = 'unreadable';
    final file = File('${tempDir.path}/$name.hive');
    final raw = await Hive.openBox<dynamic>(name);
    await raw.put('k', _Unreadable());
    await raw.close();
    final originalBytes = await file.readAsBytes();

    // When
    var salvaged = false;
    var recreated = false;
    final box = await runGuardingHiveOpenLeak(
      () => openBoxWithRecovery<dynamic>(
        name,
        hivePath: tempDir.path,
        onSalvaged: () => salvaged = true,
        onRecreated: () => recreated = true,
      ),
    );

    // Then: 救出は諦め、退避を残して空で開き直す
    expect(box, isNotNull);
    expect(box!.isEmpty, isTrue);
    expect(
      await File('${tempDir.path}/$name.hive.corrupt.bak').readAsBytes(),
      equals(originalBytes),
    );
    expect(await file.length(), 0, reason: '読めないフレームは元のファイルから消えている');
    expect(recreated, isTrue);
    expect(salvaged, isFalse);
  });

  test('削除した時点で伝えるので、その後の開き直しに失敗しても伝わる', () async {
    // 台帳 L-102 後半: 退避して削除した後、開き直しに失敗すると null を返す。
    // 「消した」ことを開き直しの成否に結びつけていると、そのとき利用者には
    // 「保存できません」しか伝わらず、履歴が消えたことは黙って進む。
    // 開き直しの失敗はテストから注入できないので、**伝える時点**を観測する。
    if (!Hive.isAdapterRegistered(60)) {
      Hive.registerAdapter(_UnreadableAdapter());
    }
    const name = 'unreadable_order';
    final raw = await Hive.openBox<dynamic>(name);
    await raw.put('k', _Unreadable());
    await raw.close();

    bool? openWhenNotified;
    await runGuardingHiveOpenLeak(
      () => openBoxWithRecovery<dynamic>(
        name,
        hivePath: tempDir.path,
        onRecreated: () => openWhenNotified = Hive.isBoxOpen(name),
      ),
    );

    expect(openWhenNotified, isFalse, reason: '開き直しの成否に関わらず伝わるよう、削除した直後に伝えること');
  });

  test('壊れていない box は退避も告知もしない', () async {
    await writePhrases(2);

    final opened = await open();

    expect(opened.box!.keys, ['id-1', 'id-2']);
    expect(backupFile.existsSync(), isFalse);
    expect(opened.salvaged, isFalse);
    expect(opened.recreated, isFalse);
  });
}
