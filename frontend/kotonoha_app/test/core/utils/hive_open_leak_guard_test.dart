/// `.lock` が消えた後の後片付けを吸収するガードの検査（台帳 L-124）
///
/// このガードは「テストの後片付けの失敗を握りつぶす」道具なので、握りつぶす範囲が
/// 広がると、後片付けの本当の失敗が見えなくなる。範囲をここで固定する。
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'hive_open_leak_guard.dart';

void main() {
  test('`.lock` が消えていても閉じ切る（実 box で再現する）', () async {
    await Hive.close();
    final dir = await Directory.systemTemp.createTemp('hive_close_guard_');
    addTearDown(() async {
      await Hive.close();
      if (dir.existsSync()) await dir.delete(recursive: true);
    });
    Hive.init(dir.path);
    await Hive.openBox<String>('probe');
    // 失敗したオープンの後始末が `.lock` を後から消した状態を作る
    await File('${dir.path}/probe.lock').delete();

    await closeHiveIgnoringMissingLock();

    expect(Hive.isBoxOpen('probe'), isFalse, reason: 'box は閉じ切っていること');
  });

  test('`.lock` 以外のパスが見つからない失敗は投げ直す', () async {
    await expectLater(
      closeHiveIgnoringMissingLock(
        close: () async => throw const PathNotFoundException(
          '/tmp/probe.hive',
          OSError('No such file or directory', 2),
        ),
      ),
      throwsA(isA<PathNotFoundException>()),
    );
  });

  test('パスが見つからない以外の失敗は投げ直す', () async {
    await expectLater(
      closeHiveIgnoringMissingLock(
        close: () async => throw const FileSystemException(
          'Cannot delete file',
          '/tmp/probe.lock',
          OSError('Permission denied', 13),
        ),
      ),
      throwsA(isA<FileSystemException>()),
    );
  });
}
