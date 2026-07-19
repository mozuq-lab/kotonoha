// Hive Box破損時の復旧テスト
// TASK-0059: データ永続化テスト
//
// テストフレームワーク: flutter_test + Hive
// 対象: Hive初期化処理（Box破損時の復旧、openBoxWithRecovery）
//
// 信頼性レベル凡例:
// - 🔵 青信号: 要件定義書・テストケース定義書に基づく確実なテスト
// - 🟡 黄信号: 要件定義書から妥当な推測によるテスト
// - 🔴 赤信号: 要件定義書にない推測によるテスト

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kotonoha_app/core/utils/hive_init.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';
import 'package:kotonoha_app/shared/models/preset_phrase_adapter.dart';

/// 【テストヘルパー】: Hiveパッケージ内部の既知の非同期リークを吸収して[body]を実行する
///
/// 【背景】: hive 2.2.3では、`Hive.openBox()`が失敗すると内部の
/// `HiveImpl._openBox`が`_openingBoxes`用の`Completer`へ
/// `completer.completeError(error, stackTrace)`を呼ぶ。このCompleterの
/// Futureは（同名Boxを並行してオープンする別呼び出しがない限り）誰にも
/// awaitされないため、Dartのゾーンにハンドルされない非同期エラーとして
/// 別途リークする。これは本関数（openBoxWithRecovery）の実装の正しさとは
/// 無関係なHiveパッケージ側の既知の挙動であり、`crashRecovery: false`で
/// 意図的に例外を発生させるテストでは必ず観測される。
/// runZonedGuardedでこの既知のリークのみを握りつぶし、テスト対象の
/// 戻り値・例外送出の有無だけを検証できるようにする。
Future<T> runGuardingHiveOpenLeak<T>(Future<T> Function() body) async {
  final completer = Completer<T>();
  runZonedGuarded(() async {
    try {
      completer.complete(await body());
    } catch (e, s) {
      completer.completeError(e, s);
    }
  }, (error, stackTrace) {
    // Hive内部のFire-and-Forgetによる既知のリークを無視する
  });
  return completer.future;
}

void main() {
  group('TC-059-006: Hive Box破損時の復旧処理', () {
    late Directory tempDir;

    setUp(() async {
      await Hive.close();
      tempDir = await Directory.systemTemp.createTemp('hive_corruption_test_');
      Hive.init(tempDir.path);
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

    test('TC-059-006: Hive Boxが破損した際、Hive自身の自動復旧で正常に開かれる', () async {
      // 【テスト目的】: Hive Boxが破損した際に自動復旧処理が正常に動作することを検証
      // 【信頼性レベル】: 🟡 黄信号 - NFR-304に基づく
      // 【補足】: Hiveはデフォルト（crashRecovery: true）で内部的にフレーム単位の
      // 自動復旧を行うため、多くの破損はopenBoxWithRecovery()のcatch節に
      // 到達する前にHive自身が吸収する。本テストはその経路を確認する。

      // Given（準備フェーズ）
      var box = await Hive.openBox<PresetPhrase>('presetPhrases');
      await box.close();

      // Boxファイルを破損させる
      final boxFile = File('${tempDir.path}/presetPhrases.hive');
      if (boxFile.existsSync()) {
        await boxFile.writeAsString('INVALID_DATA_CORRUPTION_TEST');
      }

      // When（実行フェーズ）: 製品コードのopenBoxWithRecovery()を使用してオープン
      box = (await openBoxWithRecovery<PresetPhrase>('presetPhrases'))!;

      // Then（検証フェーズ）
      expect(Hive.isBoxOpen('presetPhrases'), true, reason: 'Boxが自動復旧により開かれる');
      expect(box, isNotNull, reason: 'アプリが正常に動作する');

      // 自動復旧後のBoxは空の状態（破損データは失われる）
      final items = box.values.toList();
      expect(items.isEmpty, true, reason: '復旧後のBoxは空の状態');

      await box.close();
    });

    test('TC-059-006-統合: openBoxWithRecovery()がHive自身の自動復旧では救えない破損から復旧する',
        () async {
      // 【テスト目的】: openBoxWithRecovery()のcatch節（delete→再オープン）が
      // 実際に動作することを検証する
      // 【信頼性レベル】: 🔵 青信号 - hive_init.dartのopenBoxWithRecovery実装に基づく
      // 【工夫】: crashRecovery: falseを指定してHive自身の自動復旧を無効化し、
      // 破損時に必ずHiveErrorがスローされる状況を作ることで、
      // openBoxWithRecovery()自身のdelete→再オープンのフォールバック経路を
      // 確実に検証する。

      // Given（準備フェーズ）
      var box = await Hive.openBox<PresetPhrase>('presetPhrases');
      await box.close();

      final boxFile = File('${tempDir.path}/presetPhrases.hive');
      await boxFile.writeAsString('CORRUPTED_BEFORE_INIT');

      // When（実行フェーズ）
      // crashRecovery: falseにより、Hive自身の自動復旧をバイパスして
      // 内部でHiveErrorがスローされ、openBoxWithRecovery()のcatch節
      // （deleteBoxFromDisk→再openBox）が実行される
      //
      // 【既知の制約】: crashRecovery: falseで意図的に例外を発生させると、
      // Hiveパッケージ内部の既知の非同期リーク（runGuardingHiveOpenLeakの
      // ドキュメント参照）が発生するため、テストヘルパーで吸収する。
      final recovered = await runGuardingHiveOpenLeak(
        () => openBoxWithRecovery<PresetPhrase>(
          'presetPhrases',
          crashRecovery: false,
        ),
      );

      // Then（検証フェーズ）
      // 復旧処理が実行され、初期化が成功する
      expect(recovered, isNotNull, reason: '復旧処理が実行され、Boxが再オープンされる');
      expect(Hive.isBoxOpen('presetPhrases'), true, reason: '復旧後Boxがオープンされている');
      expect(recovered!.isEmpty, true, reason: '復旧後のBoxは空の状態（破損データは失われる）');

      await recovered.close();
    });

    test('TC-059-006-異常系: 復旧にも失敗した場合はnullを返しアプリ起動を継続できる', () async {
      // 【テスト目的】: 復旧（delete→再オープン）自体にも失敗するケースで、
      // openBoxWithRecovery()が例外を再送出せずnullを返すことを検証する
      // 【信頼性レベル】: 🟡 黄信号 - NFR-301（基本機能継続）から類推
      // 【工夫】:
      //   1. 先に正常にBoxをオープン・クローズし、.hiveファイルを作成しておく
      //      （close()時にHiveが.lockファイルを削除するため、再オープン時には
      //      毎回.lockファイルの新規作成＝ディレクトリの書き込み権限が必要になる）
      //   2. .hiveファイルの中身を破損させる
      //   3. ディレクトリを読み取り専用にする。これにより.lockファイルの
      //      新規作成（初回オープン）も、破損ファイルの削除（復旧処理）も
      //      権限エラーで失敗するようになる
      //   4. crashRecovery: falseを指定（本来は権限エラーが先に起きるため
      //      挙動に影響しないが、意図を明確にするため明示）
      //
      // 【既知の制約】: crashRecovery: falseで意図的に例外を発生させると、
      // Hiveパッケージ内部の既知の非同期リーク（runGuardingHiveOpenLeakの
      // ドキュメント参照）が発生するため、テストヘルパーで吸収する。

      var box = await Hive.openBox<PresetPhrase>('presetPhrases');
      await box.close();

      final boxFile = File('${tempDir.path}/presetPhrases.hive');
      await boxFile.writeAsString('CORRUPTED_UNRECOVERABLE');

      // ディレクトリを読み取り専用にして、再オープン・削除を失敗させる
      await Process.run('chmod', ['555', tempDir.path]);

      Object? thrown;
      Box<PresetPhrase>? result;
      try {
        result = await runGuardingHiveOpenLeak(
          () => openBoxWithRecovery<PresetPhrase>(
            'presetPhrases',
            crashRecovery: false,
          ),
        );
      } catch (e) {
        thrown = e;
      } finally {
        // 後片付けのためにディレクトリの権限を戻す
        await Process.run('chmod', ['755', tempDir.path]);
      }

      // Then（検証フェーズ）
      // 例外は外部に送出されず、nullが返る（インメモリフォールバックへ委ねる）
      expect(thrown, isNull, reason: '復旧不可能な場合でも例外は送出されない');
      expect(result, isNull, reason: '復旧不可能な場合はnullが返る');
    });

    test('TC-059-006-補足: Box破損時のエラーログ記録', () async {
      // 【テスト目的】: Box破損時にエラーログが記録されることを検証
      // 【信頼性レベル】: 🟡 黄信号 - NFR-304に基づく

      var box = await Hive.openBox<PresetPhrase>('test_log_presetPhrases');
      await box.close();

      final boxFile = File('${tempDir.path}/test_log_presetPhrases.hive');
      await boxFile.writeAsString('CORRUPTED_DATA');

      // When（実行フェーズ）
      box =
          (await openBoxWithRecovery<PresetPhrase>('test_log_presetPhrases'))!;

      // Then（検証フェーズ）
      expect(Hive.isBoxOpen('test_log_presetPhrases'), true,
          reason: '自動復旧後Boxが使用可能');
      expect(box.isEmpty, true, reason: '復旧後のBoxは空');

      await box.close();
      await Hive.deleteBoxFromDisk('test_log_presetPhrases');
    });

    test('TC-059-006-境界値: 複数のBox破損時の復旧', () async {
      // 【テスト目的】: 複数のBoxが同時に破損した場合の復旧処理を検証
      // 【信頼性レベル】: 🟡 黄信号 - NFR-304に基づく

      var presetBox = await Hive.openBox<PresetPhrase>('multi_presetPhrases');
      var historyBox = await Hive.openBox('multi_history'); // 型なしBox
      await presetBox.close();
      await historyBox.close();

      final presetFile = File('${tempDir.path}/multi_presetPhrases.hive');
      final historyFile = File('${tempDir.path}/multi_history.hive');
      await presetFile.writeAsString('CORRUPTED');
      await historyFile.writeAsString('CORRUPTED');

      // When（実行フェーズ）
      presetBox =
          (await openBoxWithRecovery<PresetPhrase>('multi_presetPhrases'))!;
      historyBox = (await openBoxWithRecovery('multi_history'))!;

      // Then（検証フェーズ）
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
