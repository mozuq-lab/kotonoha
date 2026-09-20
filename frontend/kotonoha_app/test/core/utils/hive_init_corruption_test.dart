// Hive Box破損時の復旧テスト
// 削除は破損を示す例外（HiveError/FormatException/RangeError）に限定し
// FileSystemException等の環境起因の失敗ではBoxを削除しないことを検証
// 削除前に破損Boxファイルをバックアップ（<boxName>.hive.corrupt.bak）することを検証
// Hiveは内部でBox名を小文字化してからファイル名を組み立てるため
// （hive 2.2.3 hive_impl.dart `_openBox`の`name.toLowerCase`）
// 本ファイルで破損データを直接書き込むテスト用ファイルパスも
// camelCaseのBox名（例: presetPhrases）に対して実際にHiveが読み書きする
// 小文字ファイル名（presetphrases.hive）を使用する。大文字混在のまま
// パスを組み立てると、macOS等の大小文字非区別ファイルシステムでは
// 偶然パスが一致してテストが通ってしまうが、Android/Linux等の
// 大小文字を区別する環境（CIのLinux含む）では実際のBoxファイルを
// 見つけられず、テストが本来検証すべき破損検知・バックアップ経路を
// 通過しなくなる（CIで実際に失敗していた原因）。
// テストフレームワーク: flutter_test + Hive
// 対象: Hive初期化処理（Box破損時の復旧、openBoxWithRecovery）

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kotonoha_app/core/utils/hive_init.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';
import 'package:kotonoha_app/shared/models/preset_phrase_adapter.dart';

import 'hive_open_leak_guard.dart';

void main() {
  group('TC-059-006: Hive Box破損時の復旧処理', () {
    late Directory tempDir;

    setUp(() async {
      await closeHiveIgnoringMissingLock();
      tempDir = await Directory.systemTemp.createTemp('hive_corruption_test_');
      Hive.init(tempDir.path);
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(PresetPhraseAdapter());
      }
    });

    tearDown(() async {
      await closeHiveIgnoringMissingLock();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('TC-059-006-破損系: openBoxWithRecovery()は破損データを削除前にバックアップしてから復旧する',
        () async {
      // 実際に動作することを検証する
      // openBoxWithRecoveryはHive自身の自動復旧に黙って任せない（台帳 L-101）。
      // 破損時はHiveErrorを受けてから、バックアップ→開き直しの経路を通る。
      // 読める分が残る場合は hive_init_salvage_test.dart が見る。

      var box = await Hive.openBox<PresetPhrase>('presetPhrases');
      await box.close();

      final boxFile = File('${tempDir.path}/presetphrases.hive');
      await boxFile.writeAsString('CORRUPTED_BEFORE_INIT');
      final corruptedBytes = await boxFile.readAsBytes();

      // 既知の制約: 最初のオープンが失敗すると、Hiveパッケージ内部の既知の
      // 非同期リーク（runGuardingHiveOpenLeakのドキュメント参照）が発生する
      // ため、テストヘルパーで吸収する。
      var recreated = false;
      final recovered = await runGuardingHiveOpenLeak(
        () => openBoxWithRecovery<PresetPhrase>(
          'presetPhrases',
          hivePath: tempDir.path,
          onRecreated: () => recreated = true,
        ),
      );

      // 復旧処理が実行され、初期化が成功する
      expect(recovered, isNotNull, reason: '復旧処理が実行され、Boxが再オープンされる');
      expect(recreated, isTrue, reason: '空で作り直したことを呼び出し元に伝える（ADR-005、L-90）');
      expect(Hive.isBoxOpen('presetPhrases'), true, reason: '復旧後Boxがオープンされている');
      expect(recovered!.isEmpty, true, reason: '復旧後のBoxは空の状態（破損データは失われる）');

      // バックアップ検証: 削除前に破損ファイルが<boxName>.hive.corrupt.bakとして
      // 退避されていること、かつその内容が削除前の（破損した）データと一致すること
      final backupFile = File('${tempDir.path}/presetphrases.hive.corrupt.bak');
      expect(backupFile.existsSync(), isTrue, reason: '削除前に破損ファイルがバックアップされる');
      final backupBytes = await backupFile.readAsBytes();
      expect(backupBytes, equals(corruptedBytes),
          reason: 'バックアップの内容が削除前の破損データと一致する');

      await recovered.close();
    });

    test('TC-059-006-環境エラー系: 権限エラー等の非破損エラーではBoxファイルを削除せずnullを返す', () async {
      // 環境起因の失敗では、openBoxWithRecoveryがBoxファイルを削除せず
      // 例外も再送出せずnullを返すことを検証する
      // 工夫
      // 1. 有効なデータを含むBoxを作成してクローズする
      // （close時にHiveが.lockファイルを削除するため、再オープン時には
      // 毎回.lockファイルの新規作成＝ディレクトリの書き込み権限が必要になる）
      // 2. ディレクトリを読み取り専用にする。これにより.lockファイルの
      // 新規作成（再オープン）が権限エラー（FileSystemException）で
      // 失敗するようになる。この時点でBoxファイル自体は破損していない。
      // 3. openBoxWithRecoveryを呼び出し、削除されないこと
      // データファイルの内容が変化しないことを確認する

      var box = await Hive.openBox<PresetPhrase>('presetPhrases');
      final now = DateTime.now();
      await box.put(
        'keep-me',
        PresetPhrase(
          id: 'keep-me',
          content: '消えてはいけない定型文',
          category: 'daily',
          displayOrder: 0,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await box.close();

      final boxFile = File('${tempDir.path}/presetphrases.hive');
      expect(boxFile.existsSync(), isTrue, reason: '前提: Boxファイルが存在する');
      final originalBytes = await boxFile.readAsBytes();

      // ディレクトリを読み取り専用にして、再オープン（.lock作成）を失敗させる
      await Process.run('chmod', ['555', tempDir.path]);

      Object? thrown;
      Box<PresetPhrase>? result;
      try {
        result = await runGuardingHiveOpenLeak(
          () => openBoxWithRecovery<PresetPhrase>(
            'presetPhrases',
            hivePath: tempDir.path,
          ),
        );
      } catch (e) {
        thrown = e;
      } finally {
        // 後片付けのためにディレクトリの権限を戻す
        await Process.run('chmod', ['755', tempDir.path]);
      }

      // 例外は外部に送出されず、nullが返る（インメモリフォールバックへ委ねる）
      expect(thrown, isNull, reason: '環境起因のエラーでも例外は送出されない');
      expect(result, isNull, reason: '再オープンできないため結果はnull（インメモリフォールバック）');

      // 最重要: 環境起因のエラーではBoxファイルが削除されず
      // 中身も変化しないこと（データが無言で失われないこと）
      expect(boxFile.existsSync(), isTrue,
          reason: '環境起因のエラーではBoxファイルを削除してはならない');
      final bytesAfter = await boxFile.readAsBytes();
      expect(bytesAfter, equals(originalBytes),
          reason: '環境起因のエラーではBoxファイルの中身も変化してはならない');
    });

    test('TC-059-006-補足: Box破損時のエラーログ記録', () async {
      var box = await Hive.openBox<PresetPhrase>('test_log_presetPhrases');
      await box.close();

      final boxFile = File('${tempDir.path}/test_log_presetphrases.hive');
      await boxFile.writeAsString('CORRUPTED_DATA');

      box = (await runGuardingHiveOpenLeak(
        () => openBoxWithRecovery<PresetPhrase>(
          'test_log_presetPhrases',
          hivePath: tempDir.path,
        ),
      ))!;

      expect(Hive.isBoxOpen('test_log_presetPhrases'), true,
          reason: '自動復旧後Boxが使用可能');
      expect(box.isEmpty, true, reason: '復旧後のBoxは空');

      await box.close();
      await Hive.deleteBoxFromDisk('test_log_presetPhrases');
    });

    test('TC-059-006-境界値: 複数のBox破損時の復旧', () async {
      var presetBox = await Hive.openBox<PresetPhrase>('multi_presetPhrases');
      var historyBox = await Hive.openBox('multi_history'); // 型なしBox
      await presetBox.close();
      await historyBox.close();

      final presetFile = File('${tempDir.path}/multi_presetphrases.hive');
      final historyFile = File('${tempDir.path}/multi_history.hive');
      await presetFile.writeAsString('CORRUPTED');
      await historyFile.writeAsString('CORRUPTED');

      presetBox = (await runGuardingHiveOpenLeak(
        () => openBoxWithRecovery<PresetPhrase>(
          'multi_presetPhrases',
          hivePath: tempDir.path,
        ),
      ))!;
      historyBox = (await runGuardingHiveOpenLeak(
        () => openBoxWithRecovery<dynamic>(
          'multi_history',
          hivePath: tempDir.path,
        ),
      ))!;

      expect(Hive.isBoxOpen('multi_presetPhrases'), true,
          reason: 'presetPhrasesが自動復旧');
      expect(Hive.isBoxOpen('multi_history'), true, reason: 'historyが自動復旧');

      expect(presetBox.isEmpty, true, reason: 'presetPhrasesは空');
      expect(historyBox.isEmpty, true, reason: 'historyは空');

      await presetBox.close();
      await historyBox.close();
      await Hive.deleteBoxFromDisk('multi_presetPhrases');
      await Hive.deleteBoxFromDisk('multi_history');
    });
  });
}
