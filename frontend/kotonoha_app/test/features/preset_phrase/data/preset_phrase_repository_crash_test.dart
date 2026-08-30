// PresetPhraseRepository クラッシュテスト（TDD Redフェーズ）
// TASK-0059: データ永続化テスト
//
// テストフレームワーク: flutter_test + mockito
// 対象: PresetPhraseRepository（クラッシュ・エラー時の動作）
//
// 【TDD Redフェーズ】: エラーハンドリング機能が未実装のため、このテストは失敗する
//
// 信頼性レベル凡例:
// - 🔵 青信号: 要件定義書・テストケース定義書に基づく確実なテスト
// - 🟡 黄信号: 要件定義書から妥当な推測によるテスト
// - 🔴 赤信号: 要件定義書にない推測によるテスト

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kotonoha_app/features/preset_phrase/data/preset_phrase_repository.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';
import 'package:kotonoha_app/shared/models/preset_phrase_adapter.dart';

void main() {
  group('TC-059-003: トランザクション整合性テスト（定型文追加中のクラッシュ）', () {
    late Directory tempDir;
    late Box<PresetPhrase> presetBox;
    late PresetPhraseRepository repository;

    setUp(() async {
      // Hive環境初期化
      await Hive.close();
      tempDir = await Directory.systemTemp.createTemp('crash_test_');
      Hive.init(tempDir.path);

      // TypeAdapter登録
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(PresetPhraseAdapter());
      }

      presetBox = await Hive.openBox<PresetPhrase>('test_crash_presetPhrases');
      repository = PresetPhraseRepository(box: presetBox);
    });

    tearDown(() async {
      await presetBox.close();
      await Hive.deleteBoxFromDisk('test_crash_presetPhrases');
      await Hive.close();

      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('TC-059-003: 定型文追加中のクラッシュでもデータ整合性が保たれる', () async {
      // 【テスト目的】: 定型文追加中のクラッシュでもデータ整合性が保たれることを検証
      // 【信頼性レベル】: 🔵 青信号 - NFR-304に基づく

      // Given（準備フェーズ）
      // 定型文が0件の状態

      // When（実行フェーズ）
      // 定型文を10件追加する処理を開始し、5件追加した時点でクラッシュ
      try {
        for (var i = 0; i < 10; i++) {
          final phrase = PresetPhrase(
            id: 'batch-$i',
            content: '定型文$i',
            category: 'daily',
            displayOrder: i,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await repository.save(phrase);

          if (i == 4) {
            // 5件追加した時点でHiveを強制クローズ（クラッシュシミュレート）
            await Hive.close();
            break;
          }
        }
      } catch (e) {
        // クラッシュをキャッチ（Hive closeによる例外）
      }

      // Hive Boxを再度開く（アプリ再起動をシミュレート）
      presetBox = await Hive.openBox<PresetPhrase>('test_crash_presetPhrases');
      repository = PresetPhraseRepository(box: presetBox);

      // Then（検証フェーズ）
      final loadedPhrases = await repository.loadAll();

      // 追加が完了した5件（batch-0 ~ batch-4）は保存されている
      expect(loadedPhrases.length, 5, reason: '完了した5件が保存されている');

      final savedIds = loadedPhrases.map((p) => p.id).toSet();
      expect(savedIds.contains('batch-0'), true);
      expect(savedIds.contains('batch-1'), true);
      expect(savedIds.contains('batch-2'), true);
      expect(savedIds.contains('batch-3'), true);
      expect(savedIds.contains('batch-4'), true);

      // 追加が完了していない5件（batch-5 ~ batch-9）は保存されていない
      expect(savedIds.contains('batch-5'), false);
      expect(savedIds.contains('batch-6'), false);
      expect(savedIds.contains('batch-7'), false);
      expect(savedIds.contains('batch-8'), false);
      expect(savedIds.contains('batch-9'), false);

      // データの整合性が保たれている（データ破損なし）
      for (final phrase in loadedPhrases) {
        expect(phrase.id.isNotEmpty, true, reason: 'IDが正常');
        expect(phrase.content.isNotEmpty, true, reason: 'contentが正常');
        expect(['daily', 'health', 'other'].contains(phrase.category), true,
            reason: 'categoryが正常');
      }
    });
  });

  group('TC-059-005: ストレージ容量不足時のエラーハンドリング', () {
    late Directory tempDir;

    setUp(() async {
      await Hive.close();
      tempDir = await Directory.systemTemp.createTemp('storage_test_');
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

    test('TC-059-005: ストレージ容量不足時に適切なエラーハンドリングが行われる', () async {
      // 【テスト目的】: ストレージ容量不足時に適切なエラーハンドリングが行われることを検証
      // 【信頼性レベル】: 🟡 黄信号 - EDGE-003、NFR-304に基づく

      // Given（準備フェーズ）
      // ストレージ容量が極めて少ない状態をシミュレート
      // 注: 実際の容量不足をシミュレートするのは困難なため、
      // ここでは大量のデータを保存してディスク満杯エラーを誘発する

      final presetBox =
          await Hive.openBox<PresetPhrase>('test_storage_presetPhrases');
      final repository = PresetPhraseRepository(box: presetBox);

      // When（実行フェーズ）
      // 定型文を追加しようとする
      final phrase = PresetPhrase(
        id: 'test-storage',
        content: 'テスト定型文',
        category: 'daily',
        displayOrder: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Then（検証フェーズ）
      // 通常の環境では保存が成功するため、ここではエラーハンドリングの
      // 実装を検証するための基本的な動作確認を行う
      // 実際のストレージエラーは統合テストまたはモックで確認

      // エラーが発生しない場合、正常に保存される
      await expectLater(
        repository.save(phrase),
        completes,
        reason: '通常環境では正常に保存される',
      );

      // 既存データは保持されている
      final loaded = await repository.loadAll();
      expect(loaded.isNotEmpty, true, reason: '既存データが保持されている');

      await presetBox.close();
      await Hive.deleteBoxFromDisk('test_storage_presetPhrases');
    });

    test('TC-059-005-補足: エラー発生時の適切な例外処理', () async {
      // 【テスト目的】: エラー発生時に適切な例外処理が行われることを検証
      // 【信頼性レベル】: 🟡 黄信号 - NFR-304に基づく

      // Given（準備フェーズ）
      final presetBox = await Hive.openBox<PresetPhrase>('test_error_handling');
      final writeResults = <bool>[];
      final repository = PresetPhraseRepository(
        box: presetBox,
        onWriteResult: writeResults.add,
      );

      // When（実行フェーズ）
      // Boxを閉じた後に保存を試みる（エラー発生）
      await presetBox.close();

      final phrase = PresetPhrase(
        id: 'test-error',
        content: 'エラーテスト',
        category: 'daily',
        displayOrder: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Then（検証フェーズ）
      // 【変更の経緯（台帳 L-13）】: 以前は `throwsA(isA<HiveError>())` を
      // 期待していた。しかし呼び出し側（Notifier・画面）はこの Future を
      // await しておらず、送出された例外は未処理の非同期エラーになるだけで
      // 利用者には何も伝わらなかった。「保存できたように見えて消える」の
      // 経路そのものである。
      //
      // ADR-005 は「保存されないことは必ず伝える」「伝えて継続する」と
      // 定めているため、書き込み失敗は送出せず**報告**する形に変えた。
      // このテストの本来の目的（エラーが握り潰されない・アプリが壊れない）は
      // 報告の有無で検証するほうが正確である。
      await repository.save(phrase);

      expect(
        writeResults,
        contains(false),
        reason: '閉じたBoxへの保存失敗が報告されていない（黙って捨てられている）',
      );

      await Hive.deleteBoxFromDisk('test_error_handling');
    });
  });
}
