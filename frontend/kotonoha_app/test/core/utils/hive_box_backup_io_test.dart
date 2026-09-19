// Hive Box破損バックアップ（dart:io実装）のパス構築・検証テスト
// HiveはBox名を内部で小文字化してからファイル名を組み立てる
// （hive 2.2.3 hive_impl.dart `_openBox`の`name.toLowerCase`）ため
// `backupCorruptBoxFile`が呼び出し元から渡された大小文字のまま
// パスを組み立てると、Android/Linux等の大小文字を区別する
// ファイルシステムでは実際のBoxファイルを発見できず
// 「元ファイル不存在→バックアップ不要（true）」と誤判定してしまう。
// この誤判定により、後続の`Hive.deleteBoxFromDisk`がバックアップなしで
// 実ファイルを削除してしまう不具合を防ぐため、Hiveと同じ小文字化規則で
// パスを構築する`resolveBoxFilePath`/`resolveBoxBackupFilePath`を検証する。
// 重要: resolveBoxFilePath/resolveBoxBackupFilePathの期待値は、本テストでは
// 実装を呼び出さずリテラル文字列で直接記述する。macOS等の大小文字を区別しない
// ファイルシステムでは、パス構築ロジックに大小文字関連のバグがあっても
// 偶然ファイルが見つかってテストが green になってしまうため
// ファイルシステムに依存しないユニットレベルでの検証が必須となる
// テストフレームワーク: flutter_test + dart:io
// 対象: lib/core/utils/hive_box_backup_io.dart

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/utils/hive_box_backup_io.dart';

void main() {
  group('resolveBoxFilePath / resolveBoxBackupFilePath: パス構築の純粋関数テスト', () {
    // パスが構築されることを、ファイルシステムに依存せず検証する

    test('camelCaseのBox名は小文字化された.hiveファイルパスに解決される', () {
      final path = resolveBoxFilePath('/tmp/hive_home', 'presetPhrases');

      // 期待値はリテラルで直接記述する（実装を経由した自己参照的な
      // アサーションにしないため）
      expect(path, '/tmp/hive_home/presetphrases.hive');
      expect(path, isNot(contains('presetPhrases')),
          reason: '大文字を含む元の表記が残っていない');
    });

    test('すべて小文字のBox名はそのまま(小文字)の.hiveファイルパスに解決される', () {
      final path = resolveBoxFilePath('/tmp/hive_home', 'history');

      expect(path, '/tmp/hive_home/history.hive');
    });

    test('大文字を含むBox名は.hive.corrupt.bakパスも小文字化される', () {
      final path = resolveBoxBackupFilePath('/tmp/hive_home', 'presetPhrases');

      expect(path, '/tmp/hive_home/presetphrases.hive.corrupt.bak');
      expect(path, isNot(contains('presetPhrases')));
    });

    test('複数の大文字・アンダースコアを含むBox名も一貫して小文字化される', () {
      final path = resolveBoxFilePath('/tmp/hive_home', 'MultiPresetPhrases');

      expect(path, '/tmp/hive_home/multipresetphrases.hive');
    });
  });

  group('backupCorruptBoxFile: 大小文字を区別するファイルシステムを想定した実ファイル検証', () {
    // 相当する呼び出しを行った際、実際にHiveが読み書きする小文字ファイル名
    // （presetphrases.hive）が正しく発見・バックアップされ、かつバックアップの
    // 内容が元の破損データと一致することを検証する

    late Directory tempDir;

    setUp(() async {
      tempDir =
          await Directory.systemTemp.createTemp('hive_box_backup_io_test_');
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('小文字名で配置された破損ファイルがcamelCaseのBox名指定で発見・バックアップされる', () async {
      // Given: Hiveが実際に書き込む小文字ファイル名で破損データを配置する
      const boxName = 'presetPhrases'; // 呼び出し元はcamelCaseで指定
      final sourceFile =
          File('${tempDir.path}/presetphrases.hive'); // 実ファイルは小文字
      final corruptedBytes = 'CORRUPTED_BINARY_DATA_FOR_TEST'.codeUnits;
      await sourceFile.writeAsBytes(corruptedBytes);

      // When: camelCaseのBox名でバックアップ処理を呼び出す
      final result = await backupCorruptBoxFile(tempDir.path, boxName);

      // Then: (a) 破損ファイルが正しく発見されバックアップされる
      expect(result, isTrue, reason: '小文字化して実ファイルを発見できるため成功する');

      final backupFile = File('${tempDir.path}/presetphrases.hive.corrupt.bak');
      expect(backupFile.existsSync(), isTrue, reason: '小文字名のバックアップファイルが作成される');

      // (b) バックアップファイルの内容が元の破損データと一致する
      final backupBytes = await backupFile.readAsBytes();
      expect(backupBytes, equals(corruptedBytes),
          reason: 'バックアップ内容が破損データと一致する');

      // 元ファイルは削除されていない（バックアップはコピーであり移動ではない）
      expect(sourceFile.existsSync(), isTrue);
    });

    test('大文字混在のパスのまま実ファイルが存在しない場合と異なり、正規化後は本当にファイルがない場合のみtrueになる', () async {
      // Given: 実ファイルが一切存在しない（小文字化しても見つからない）
      const boxName = 'neverExisted';

      // When
      final result = await backupCorruptBoxFile(tempDir.path, boxName);

      // Then: 削除対象自体が存在しないため、バックアップ不要としてtrueを返す
      expect(result, isTrue);
      final backupFile = File('${tempDir.path}/neverexisted.hive.corrupt.bak');
      expect(backupFile.existsSync(), isFalse,
          reason: 'バックアップ元が無いためバックアップも作られない');
    });

    test('hivePathがnullの場合はfalseを返す', () async {
      final result = await backupCorruptBoxFile(null, 'presetPhrases');
      expect(result, isFalse);
    });

    test('写しに失敗しても、前回の退避は残る（台帳 L-114）', () async {
      // 古い退避を先に消してから写すと、写しに失敗したとき新旧どちらも残らない。
      // 元のファイルには手を付けないので box の中身は無事だが、前回の破損で
      // 退避した分（もう元のファイルには無いデータ）は永久に失われる。
      // 一時名へ書き切ってから入れ替えれば、失敗しても前回の退避が残る。
      const boxName = 'presetPhrases';
      final sourceFile = File('${tempDir.path}/presetphrases.hive');
      final backupFile = File('${tempDir.path}/presetphrases.hive.corrupt.bak');
      final previousBytes = 'PREVIOUS_BACKUP'.codeUnits;
      await backupFile.writeAsBytes(previousBytes);
      await sourceFile.writeAsBytes('CORRUPTED'.codeUnits);
      // 元ファイルを読めなくして、写しだけを失敗させる（元ファイルは消さない）
      await Process.run('chmod', ['000', sourceFile.path]);
      addTearDown(() => Process.run('chmod', ['644', sourceFile.path]));

      final result = await backupCorruptBoxFile(tempDir.path, boxName);

      expect(result, isFalse, reason: '写しに失敗したら呼び出し元に削除を中止させる');
      expect(backupFile.existsSync(), isTrue, reason: '写しに失敗したら前回の退避を消してはいけない');
      expect(await backupFile.readAsBytes(), equals(previousBytes));
    });

    /// `.tmp` に残るのは利用者の発話を含む写しなので、成功でも失敗でも残さない
    List<String> stagingLeftovers() => tempDir
        .listSync()
        .map((e) => e.path.split('/').last)
        .where((name) => name.endsWith('.tmp'))
        .toList();

    test('退避に成功したら一時ファイルは残さない', () async {
      const boxName = 'presetPhrases';
      await File('${tempDir.path}/presetphrases.hive')
          .writeAsBytes('CORRUPTED'.codeUnits);

      final result = await backupCorruptBoxFile(tempDir.path, boxName);

      expect(result, isTrue);
      expect(stagingLeftovers(), isEmpty);
    });

    test('入れ替えに失敗しても一時ファイルは残さない', () async {
      const boxName = 'presetPhrases';
      await File('${tempDir.path}/presetphrases.hive')
          .writeAsBytes('CORRUPTED'.codeUnits);
      // 退避先をディレクトリにして、入れ替えだけを失敗させる
      await Directory('${tempDir.path}/presetphrases.hive.corrupt.bak')
          .create();

      final result = await backupCorruptBoxFile(tempDir.path, boxName);

      expect(result, isFalse);
      expect(stagingLeftovers(), isEmpty, reason: '書きかけの写し（利用者の発話を含む）を端末に残さない');
    });

    test('前回の中断で残った一時ファイルは、box が正常に開けたときに片付ける', () async {
      const boxName = 'presetPhrases';
      final staging =
          File('${tempDir.path}/presetphrases.hive.corrupt.bak.tmp');
      await staging.writeAsBytes('INTERRUPTED_COPY'.codeUnits);

      await removeStaleBackupStaging(tempDir.path, boxName);

      expect(staging.existsSync(), isFalse);
    });

    test('片付けは、退避そのものや box のファイルには手を付けない', () async {
      const boxName = 'presetPhrases';
      final boxFile = File('${tempDir.path}/presetphrases.hive');
      final backupFile = File('${tempDir.path}/presetphrases.hive.corrupt.bak');
      await boxFile.writeAsBytes('LIVE'.codeUnits);
      await backupFile.writeAsBytes('PREVIOUS_BACKUP'.codeUnits);

      await removeStaleBackupStaging(tempDir.path, boxName);

      expect(boxFile.existsSync(), isTrue);
      expect(await backupFile.readAsBytes(), 'PREVIOUS_BACKUP'.codeUnits);
    });

    test('既存の.bakファイルは上書きされ、最新の破損データが反映される', () async {
      const boxName = 'presetPhrases';
      final sourceFile = File('${tempDir.path}/presetphrases.hive');
      final backupFile = File('${tempDir.path}/presetphrases.hive.corrupt.bak');

      await backupFile.writeAsBytes('OLD_STALE_BACKUP'.codeUnits);
      final newBytes = 'NEW_CORRUPTED_DATA'.codeUnits;
      await sourceFile.writeAsBytes(newBytes);

      final result = await backupCorruptBoxFile(tempDir.path, boxName);

      expect(result, isTrue);
      final backupBytes = await backupFile.readAsBytes();
      expect(backupBytes, equals(newBytes), reason: '古いバックアップは新しい破損データで上書きされる');
    });
  });
}
