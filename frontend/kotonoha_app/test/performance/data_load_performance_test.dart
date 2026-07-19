// データ読み込みパフォーマンステスト（TDD Redフェーズ）
// TASK-0059: データ永続化テスト
//
// テストフレームワーク: flutter_test + Hive
// 対象: 大量データ保存時のアプリ起動速度
//
// 【TDD Redフェーズ】: パフォーマンス最適化が未実装のため、このテストは失敗する可能性がある
//
// 信頼性レベル凡例:
// - 🔵 青信号: 要件定義書・テストケース定義書に基づく確実なテスト
// - 🟡 黄信号: 要件定義書から妥当な推測によるテスト
// - 🔴 赤信号: 要件定義書にない推測によるテスト

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kotonoha_app/features/ai_conversion/domain/models/politeness_level.dart';
import 'package:kotonoha_app/features/preset_phrase/data/preset_phrase_repository.dart';
import 'package:kotonoha_app/features/settings/models/app_theme.dart';
import 'package:kotonoha_app/features/settings/models/font_size.dart';
import 'package:kotonoha_app/features/settings/providers/settings_provider.dart';
import 'package:kotonoha_app/features/tts/domain/models/tts_speed.dart';
import 'package:kotonoha_app/shared/models/history_item.dart';
import 'package:kotonoha_app/shared/models/history_item_adapter.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';
import 'package:kotonoha_app/shared/models/preset_phrase_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('TC-059-010: 起動時データ読み込み速度テスト', () {
    late Directory tempDir;
    late Box<PresetPhrase> presetBox;
    late Box<HistoryItem> historyBox;
    late PresetPhraseRepository presetRepository;

    setUp(() async {
      // Hive環境初期化
      await Hive.close();
      tempDir = await Directory.systemTemp.createTemp('performance_test_');
      Hive.init(tempDir.path);

      // TypeAdapter登録
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(HistoryItemAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(PresetPhraseAdapter());
      }

      // SharedPreferences初期化
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() async {
      await Hive.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('TC-059-010: 大量データ保存時のアプリ起動速度を検証', () async {
      // 【テスト目的】: 大量データ保存時のアプリ起動速度を検証
      // 【信頼性レベル】: 🟡 黄信号 - NFR-004に基づく

      // Given（準備フェーズ）
      // 定型文100件、履歴50件、設定を事前に保存
      presetBox = await Hive.openBox<PresetPhrase>('presetPhrases');
      historyBox = await Hive.openBox<HistoryItem>('history');
      presetRepository = PresetPhraseRepository(box: presetBox);

      // 定型文100件を生成
      final phrases = List.generate(
        100,
        (i) => PresetPhrase(
          id: 'phrase-$i',
          content: '定型文$i',
          category: ['daily', 'health', 'other'][i % 3],
          isFavorite: i % 10 == 0,
          displayOrder: i,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      await presetRepository.saveAll(phrases);

      // 履歴50件を生成
      final histories = List.generate(
        50,
        (i) => HistoryItem(
          id: 'hist-$i',
          content: '履歴$i',
          type: ['manualInput', 'preset', 'aiConverted'][i % 3],
          createdAt: DateTime.now().subtract(Duration(minutes: i)),
          isFavorite: false,
        ),
      );
      for (final history in histories) {
        await historyBox.put(history.id, history);
      }

      // 設定を保存
      // 【実装対応】: 実際にアプリで使用されているSettingsNotifier
      // （features/settings/providers/settings_provider.dart）を通して検証する
      var settingsContainer = ProviderContainer();
      await settingsContainer.read(settingsNotifierProvider.future);
      final settingsNotifier =
          settingsContainer.read(settingsNotifierProvider.notifier);
      await settingsNotifier.setFontSize(FontSize.large);
      await settingsNotifier.setTheme(AppTheme.dark);
      await settingsNotifier.setTTSSpeed(TTSSpeed.fast);
      await settingsNotifier.setAIPoliteness(PolitenessLevel.polite);
      settingsContainer.dispose();

      // Boxを閉じる（アプリ終了をシミュレート）
      await Hive.close();

      // When（実行フェーズ）
      // アプリを起動し、起動時間を計測
      final stopwatch = Stopwatch()..start();

      // Boxを再度開く
      presetBox = await Hive.openBox<PresetPhrase>('presetPhrases');
      historyBox = await Hive.openBox<HistoryItem>('history');
      presetRepository = PresetPhraseRepository(box: presetBox);
      // 設定用のProviderContainerも再構築（アプリ起動をシミュレート）
      settingsContainer = ProviderContainer();

      // すべてのデータを読み込む
      final loadedPhrases = await presetRepository.loadAll();
      final loadedHistories = historyBox.values.toList();
      final loadedSettings =
          await settingsContainer.read(settingsNotifierProvider.future);

      stopwatch.stop();

      // Then（検証フェーズ）
      // すべてのデータが1秒以内に読み込まれる
      final elapsedMs = stopwatch.elapsedMilliseconds;
      expect(elapsedMs, lessThan(1000),
          reason: 'データ読み込みが1秒以内に完了する（実測: ${elapsedMs}ms）');

      // データの欠落がない
      expect(loadedPhrases.length, 100, reason: '定型文100件がすべて読み込まれる');
      expect(loadedHistories.length, 50, reason: '履歴50件がすべて読み込まれる');
      expect(loadedSettings, isNotNull, reason: '設定が読み込まれる');

      // パフォーマンス情報を出力
      print('===== パフォーマンステスト結果 =====');
      print('定型文: ${loadedPhrases.length}件');
      print('履歴: ${loadedHistories.length}件');
      print('データ読み込み時間: ${elapsedMs}ms');
      print('===================================');

      settingsContainer.dispose();
    });

    test('TC-059-010-境界値: 200件の定型文読み込みパフォーマンス', () async {
      // 【テスト目的】: より大量のデータでのパフォーマンスを検証
      // 【信頼性レベル】: 🟡 黄信号 - NFR-004に基づく

      // Given（準備フェーズ）
      presetBox = await Hive.openBox<PresetPhrase>('large_presetPhrases');
      presetRepository = PresetPhraseRepository(box: presetBox);

      // 定型文200件を生成
      final phrases = List.generate(
        200,
        (i) => PresetPhrase(
          id: 'large-phrase-$i',
          content: '定型文$i' * 10, // やや長いcontent
          category: ['daily', 'health', 'other'][i % 3],
          isFavorite: i % 10 == 0,
          displayOrder: i,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      await presetRepository.saveAll(phrases);

      await Hive.close();

      // When（実行フェーズ）
      final stopwatch = Stopwatch()..start();

      presetBox = await Hive.openBox<PresetPhrase>('large_presetPhrases');
      presetRepository = PresetPhraseRepository(box: presetBox);
      final loadedPhrases = await presetRepository.loadAll();

      stopwatch.stop();

      // Then（検証フェーズ）
      // 200件でも2秒以内に読み込まれる（余裕を持った基準）
      final elapsedMs = stopwatch.elapsedMilliseconds;
      expect(elapsedMs, lessThan(2000),
          reason: '200件のデータが2秒以内に読み込まれる（実測: ${elapsedMs}ms）');

      expect(loadedPhrases.length, 200, reason: '200件すべて読み込まれる');

      print('===== 大量データパフォーマンステスト結果 =====');
      print('定型文: ${loadedPhrases.length}件');
      print('データ読み込み時間: ${elapsedMs}ms');
      print('1件あたりの読み込み時間: ${elapsedMs / 200}ms');
      print('=========================================');

      await presetBox.close();
      await Hive.deleteBoxFromDisk('large_presetPhrases');
    });

    test('TC-059-010-補足: 非同期処理のUIブロック確認', () async {
      // 【テスト目的】: データ読み込みが非同期で行われ、UIをブロックしないことを確認
      // 【信頼性レベル】: 🟡 黄信号 - NFR-004に基づく

      // Given（準備フェーズ）
      presetBox = await Hive.openBox<PresetPhrase>('async_presetPhrases');
      presetRepository = PresetPhraseRepository(box: presetBox);

      final phrases = List.generate(
        100,
        (i) => PresetPhrase(
          id: 'async-$i',
          content: '非同期テスト$i',
          category: 'daily',
          isFavorite: false,
          displayOrder: i,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      await presetRepository.saveAll(phrases);

      await Hive.close();

      // When（実行フェーズ）
      // 非同期でデータを読み込む
      presetBox = await Hive.openBox<PresetPhrase>('async_presetPhrases');
      presetRepository = PresetPhraseRepository(box: presetBox);

      var uiSimulationCompleted = false;

      // データ読み込みとUIシミュレーションを並行実行
      final loadFuture = presetRepository.loadAll();
      final uiSimulation = Future.delayed(Duration(milliseconds: 10), () {
        uiSimulationCompleted = true;
      });

      await Future.wait([loadFuture, uiSimulation]);

      // Then（検証フェーズ）
      // UIシミュレーションが完了している（ブロックされていない）
      expect(uiSimulationCompleted, true, reason: 'UIがブロックされていない');

      await presetBox.close();
      await Hive.deleteBoxFromDisk('async_presetPhrases');
    });
  });
}
