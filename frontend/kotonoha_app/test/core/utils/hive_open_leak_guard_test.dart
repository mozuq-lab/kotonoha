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

  test('未closeの保存ディレクトリ消去は後片付けの失敗として返す', () async {
    await Hive.close();
    final dir = await Directory.systemTemp.createTemp('hive_removed_dir_');
    addTearDown(Hive.close);
    Hive.init(dir.path);
    await Hive.openBox<String>('probe');
    await dir.delete(recursive: true);

    await expectLater(
      closeHiveIgnoringMissingLock(),
      throwsA(isA<PathNotFoundException>()),
    );
    expect(Hive.isBoxOpen('probe'), isFalse);
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

  test('`.lock` を含むだけのパスは吸収しない', () async {
    // `endsWith` を `contains` に緩めると、`probe.lock.bak` のような別のファイルの
    // 失敗まで吸収してしまう。吸収すると閉じ直しに入るので、**呼ばれた回数**で見る
    // （最後は投げ直すので、例外の型だけでは見分けられない）
    var calls = 0;
    await expectLater(
      closeHiveIgnoringMissingLock(
        close: () async {
          calls++;
          throw const PathNotFoundException(
            '/tmp/probe.lock.bak',
            OSError('No such file or directory', 2),
          );
        },
      ),
      throwsA(isA<PathNotFoundException>()),
    );
    expect(calls, 1, reason: '吸収せずその場で投げ直すこと（閉じ直しに入らない）');
  });

  test('消えた `.lock` を吸収した後、ほかの box の失敗は見逃さない', () async {
    // `Hive.close()` は `Future.wait` なので、複数の box が失敗しても最初の
    // エラーしか伝わらない。消えた `.lock` がその 1 つ目だと、後ろの本当の失敗が
    // 捨てられる。吸収したら閉じ直して確かめる
    var calls = 0;
    await expectLater(
      closeHiveIgnoringMissingLock(
        close: () async {
          calls++;
          if (calls == 1) {
            throw const PathNotFoundException(
              '/tmp/probe.lock',
              OSError('No such file or directory', 2),
            );
          }
          throw const FileSystemException(
            'Cannot close file',
            '/tmp/other.hive',
            OSError('Input/output error', 5),
          );
        },
      ),
      throwsA(isA<FileSystemException>()),
    );
    expect(calls, 2, reason: '吸収したら、残りの box をもう一度閉じて確かめる');
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
