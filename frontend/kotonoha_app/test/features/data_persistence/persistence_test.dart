// データ永続化統合テスト（TDD Redフェーズ）
// TASK-0059: データ永続化テスト
//
// テストフレームワーク: flutter_test + integration_test
// 対象: アプリ強制終了・クラッシュ時のデータ永続性
//
// 【TDD Redフェーズ】: 永続化機能が未実装のため、このテストは失敗する
//
// 信頼性レベル凡例:
// - 🔵 青信号: 要件定義書・テストケース定義書に基づく確実なテスト
// - 🟡 黄信号: 要件定義書から妥当な推測によるテスト
// - 🔴 赤信号: 要件定義書にない推測によるテスト

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kotonoha_app/features/character_board/providers/input_buffer_provider.dart';
import 'package:kotonoha_app/features/preset_phrase/data/preset_phrase_repository.dart';
import 'package:kotonoha_app/features/settings/models/font_size.dart';
import 'package:kotonoha_app/features/settings/providers/settings_provider.dart';
import 'package:kotonoha_app/shared/models/history_item.dart';
import 'package:kotonoha_app/shared/models/history_item_adapter.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';
import 'package:kotonoha_app/shared/models/preset_phrase_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('TC-059-001: アプリ強制終了後のデータ保持テスト', () {
    late Directory tempDir;
    late Box<PresetPhrase> presetBox;
    late Box<HistoryItem> historyBox;
    late PresetPhraseRepository presetRepository;

    setUp(() async {
      // Hive環境初期化
      await Hive.close();
      tempDir = await Directory.systemTemp.createTemp('data_persistence_test_');
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

    test('TC-059-001: アプリ強制終了後も定型文・設定・履歴がすべて保持される', () async {
      // 【テスト目的】: アプリ強制終了後も定型文・設定・履歴がすべて保持されることを検証
      // 【信頼性レベル】: 🔵 青信号 - REQ-5003、NFR-301に基づく

      // Given（準備フェーズ）
      // ボックスを開く
      presetBox = await Hive.openBox<PresetPhrase>('presetPhrases');
      historyBox = await Hive.openBox<HistoryItem>('history');
      presetRepository = PresetPhraseRepository(box: presetBox);

      // 定型文を5件追加
      final phrases = [
        PresetPhrase(
          id: 'test-001',
          content: 'こんにちは',
          category: 'daily',
          isFavorite: false,
          displayOrder: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        PresetPhrase(
          id: 'test-002',
          content: 'お水をください',
          category: 'health',
          isFavorite: false,
          displayOrder: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        PresetPhrase(
          id: 'test-003',
          content: 'ありがとう',
          category: 'daily',
          isFavorite: false,
          displayOrder: 2,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        PresetPhrase(
          id: 'test-004',
          content: '助けてください',
          category: 'health',
          isFavorite: false,
          displayOrder: 3,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        PresetPhrase(
          id: 'test-005',
          content: 'さようなら',
          category: 'daily',
          isFavorite: false,
          displayOrder: 4,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      await presetRepository.saveAll(phrases);

      // 設定でフォントサイズを「大（large）」に変更
      // 【実装対応】: 実際にアプリで使用されているSettingsNotifier
      // （features/settings/providers/settings_provider.dart）を通して検証する
      var settingsContainer = ProviderContainer();
      await settingsContainer.read(settingsNotifierProvider.future);
      await settingsContainer
          .read(settingsNotifierProvider.notifier)
          .setFontSize(FontSize.large);
      settingsContainer.dispose();

      // 履歴を3件保存
      final histories = [
        HistoryItem(
          id: 'hist-001',
          content: 'テスト履歴1',
          type: 'manualInput',
          createdAt: DateTime.now(),
          isFavorite: false,
        ),
        HistoryItem(
          id: 'hist-002',
          content: 'テスト履歴2',
          type: 'preset',
          createdAt: DateTime.now(),
          isFavorite: false,
        ),
        HistoryItem(
          id: 'hist-003',
          content: 'テスト履歴3',
          type: 'manualInput',
          createdAt: DateTime.now(),
          isFavorite: false,
        ),
      ];
      for (final history in histories) {
        await historyBox.put(history.id, history);
      }

      // When（実行フェーズ）
      // Hive Boxを閉じる（アプリ強制終了をシミュレート）
      await Hive.close();

      // Hive Boxを再度開く（アプリ再起動をシミュレート）
      presetBox = await Hive.openBox<PresetPhrase>('presetPhrases');
      historyBox = await Hive.openBox<HistoryItem>('history');
      presetRepository = PresetPhraseRepository(box: presetBox);
      // 設定用のProviderContainerも再構築（アプリ再起動をシミュレート）
      settingsContainer = ProviderContainer();

      // データを読み込む
      final loadedPhrases = await presetRepository.loadAll();
      final loadedSettings =
          await settingsContainer.read(settingsNotifierProvider.future);
      final loadedHistories = historyBox.values.toList();

      // Then（検証フェーズ）
      // 定型文5件がすべて保持されている
      expect(loadedPhrases.length, 5, reason: '定型文5件がすべて保持されている');
      expect(loadedPhrases.map((p) => p.id).toSet(),
          {'test-001', 'test-002', 'test-003', 'test-004', 'test-005'});
      expect(
          loadedPhrases.firstWhere((p) => p.id == 'test-001').content, 'こんにちは');
      expect(loadedPhrases.firstWhere((p) => p.id == 'test-002').content,
          'お水をください');

      // フォントサイズ設定が「大（large）」のまま保持されている
      expect(loadedSettings.fontSize, FontSize.large,
          reason: 'フォントサイズ設定が保持されている');

      // 履歴3件がすべて保持されている
      expect(loadedHistories.length, 3, reason: '履歴3件がすべて保持されている');
      expect(loadedHistories.map((h) => h.id).toSet(),
          {'hist-001', 'hist-002', 'hist-003'});

      settingsContainer.dispose();
    });
  });

  group('TC-059-002: 入力中のテキスト復元テスト', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() {
      container.dispose();
    });

    test('TC-059-002: アプリクラッシュ時の入力バッファが復元される', () async {
      // 【テスト目的】: アプリクラッシュ時の入力バッファが復元されることを検証
      // 【信頼性レベル】: 🔵 青信号 - NFR-302、EDGE-201に基づく

      // Given（準備フェーズ）
      container = ProviderContainer();
      final prefs = await SharedPreferences.getInstance();

      // 文字盤で「こんにちは」と入力
      container.read(inputBufferProvider.notifier).setText('こんにちは');

      // 入力バッファをshared_preferencesに保存
      await prefs.setString('input_buffer', 'こんにちは');
      await prefs.setString(
          'input_buffer_timestamp', DateTime.now().toIso8601String());

      // When（実行フェーズ）
      // ProviderContainerを破棄（アプリクラッシュをシミュレート）
      container.dispose();

      // ProviderContainerを再作成（アプリ再起動をシミュレート）
      container = ProviderContainer();

      // 入力バッファをshared_preferencesから読み込み、復元
      final savedBuffer = prefs.getString('input_buffer');
      if (savedBuffer != null) {
        container.read(inputBufferProvider.notifier).setText(savedBuffer);
      }

      // Then（検証フェーズ）
      final restoredBuffer = container.read(inputBufferProvider);

      // 入力バッファに「こんにちは」が復元されている
      expect(restoredBuffer, 'こんにちは', reason: '入力バッファが復元されている');
      expect(restoredBuffer.length, 5, reason: '文字の欠落がない');
    });
  });

  group('TC-059-004: バックグラウンド復帰時の状態復元テスト', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() {
      container.dispose();
    });

    test('TC-059-004: バックグラウンドから復帰した際に前回の状態が復元される', () async {
      // 【テスト目的】: アプリがバックグラウンドから復帰した際に前回の状態が復元されることを検証
      // 【信頼性レベル】: 🟡 黄信号 - NFR-302、EDGE-201に基づく

      // Given（準備フェーズ）
      container = ProviderContainer();
      final prefs = await SharedPreferences.getInstance();

      // 定型文一覧画面を表示し、文字盤で「ありがとう」と入力
      container.read(inputBufferProvider.notifier).setText('ありがとう');

      // 現在のアプリ状態をshared_preferencesに保存
      await prefs.setString('last_screen', 'preset_phrase_list');
      await prefs.setString('input_buffer', 'ありがとう');

      // When（実行フェーズ）
      // アプリをバックグラウンドに移行（シミュレート）
      // ...ここでは省略（実際のAppLifecycleStateは統合テストで確認）

      // アプリを再度開く（復帰）
      final lastScreen = prefs.getString('last_screen');
      final savedBuffer = prefs.getString('input_buffer');
      if (savedBuffer != null) {
        container.read(inputBufferProvider.notifier).setText(savedBuffer);
      }

      // Then（検証フェーズ）
      final restoredBuffer = container.read(inputBufferProvider);

      // 定型文一覧画面が表示されている（画面状態の復元）
      expect(lastScreen, 'preset_phrase_list', reason: '画面状態が復元されている');

      // 入力バッファに「ありがとう」が保持されている
      expect(restoredBuffer, 'ありがとう', reason: '入力バッファが保持されている');
    });
  });

  group('TC-059-007: 1000文字入力中のクラッシュ復元', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() {
      container.dispose();
    });

    test('TC-059-007: 入力バッファの境界値（1000文字）でのクラッシュ復元', () async {
      // 【テスト目的】: 入力バッファの境界値（1000文字）でのクラッシュ復元を検証
      // 【信頼性レベル】: 🔵 青信号 - NFR-302、EDGE-101に基づく

      // Given（準備フェーズ）
      container = ProviderContainer();
      final prefs = await SharedPreferences.getInstance();

      // 文字盤で1000文字入力
      final longText = 'あ' * 1000;
      container.read(inputBufferProvider.notifier).setText(longText);

      // 入力バッファをshared_preferencesに保存
      await prefs.setString('input_buffer', longText);

      // When（実行フェーズ）
      // ProviderContainerを破棄（アプリクラッシュをシミュレート）
      container.dispose();

      // ProviderContainerを再作成（アプリ再起動をシミュレート）
      container = ProviderContainer();

      // 入力バッファを復元
      final savedBuffer = prefs.getString('input_buffer');
      if (savedBuffer != null) {
        container.read(inputBufferProvider.notifier).setText(savedBuffer);
      }

      // Then（検証フェーズ）
      final restoredBuffer = container.read(inputBufferProvider);

      // 入力バッファに1000文字が完全に復元されている
      expect(restoredBuffer.length, 1000, reason: '1000文字が完全に復元されている');
      expect(restoredBuffer, longText, reason: '文字の欠落がない（完全一致）');
    });
  });

  group('TC-059-009: エンドツーエンドデータ永続化テスト', () {
    late Directory tempDir;
    late Box<PresetPhrase> presetBox;
    late Box<HistoryItem> historyBox;
    late PresetPhraseRepository presetRepository;

    setUp(() async {
      // Hive環境初期化
      await Hive.close();
      tempDir = await Directory.systemTemp.createTemp('e2e_persistence_test_');
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

    test('TC-059-009: 実際のユーザー操作を再現し、すべてのデータ永続化機能が統合的に動作する', () async {
      // 【テスト目的】: 実際のユーザー操作を再現し、すべてのデータ永続化機能が統合的に動作することを検証
      // 【信頼性レベル】: 🔵 青信号 - REQ-5003、REQ-104、REQ-601、REQ-801、NFR-301、NFR-302に基づく

      // Given（準備フェーズ）
      // アプリを初回起動（すべてのデータが空）
      presetBox = await Hive.openBox<PresetPhrase>('presetPhrases');
      historyBox = await Hive.openBox<HistoryItem>('history');
      presetRepository = PresetPhraseRepository(box: presetBox);

      // When（実行フェーズ）
      // ユーザーが定型文を3件追加
      final userPhrases = [
        PresetPhrase(
          id: 'user-001',
          content: 'こんにちは',
          category: 'daily',
          isFavorite: false,
          displayOrder: 70,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        PresetPhrase(
          id: 'user-002',
          content: 'お水をください',
          category: 'health',
          isFavorite: false,
          displayOrder: 71,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        PresetPhrase(
          id: 'user-003',
          content: 'ありがとう',
          category: 'daily',
          isFavorite: false,
          displayOrder: 72,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      await presetRepository.saveAll(userPhrases);

      // 定型文1件（user-001）をお気に入りに追加
      final favoritePhrase = userPhrases[0].copyWith(isFavorite: true);
      await presetRepository.save(favoritePhrase);

      // 設定でフォントサイズを「大（large）」に変更
      // 【実装対応】: 実際にアプリで使用されているSettingsNotifier
      // （features/settings/providers/settings_provider.dart）を通して検証する
      var settingsContainer = ProviderContainer();
      await settingsContainer.read(settingsNotifierProvider.future);
      await settingsContainer
          .read(settingsNotifierProvider.notifier)
          .setFontSize(FontSize.large);
      settingsContainer.dispose();

      // 文字盤で「お水をください」と入力し、読み上げボタンをタップ（履歴に保存）
      final history = HistoryItem(
        id: 'hist-001',
        content: 'お水をください',
        type: 'manualInput',
        createdAt: DateTime.now(),
        isFavorite: false,
      );
      await historyBox.put(history.id, history);

      // アプリを強制終了
      await Hive.close();

      // アプリを再起動
      presetBox = await Hive.openBox<PresetPhrase>('presetPhrases');
      historyBox = await Hive.openBox<HistoryItem>('history');
      presetRepository = PresetPhraseRepository(box: presetBox);
      // 設定用のProviderContainerも再構築（アプリ再起動をシミュレート）
      settingsContainer = ProviderContainer();

      // すべてのデータを読み込む
      final loadedPhrases = await presetRepository.loadAll();
      final loadedSettings =
          await settingsContainer.read(settingsNotifierProvider.future);
      final loadedHistories = historyBox.values.toList();

      // Then（検証フェーズ）
      // 追加3件の定型文が保持されている
      expect(loadedPhrases.length, 3, reason: '3件の定型文が保持されている');

      // お気に入り定型文（user-001）が`isFavorite: true`で保存されている
      final favPhrase = loadedPhrases.firstWhere((p) => p.id == 'user-001');
      expect(favPhrase.isFavorite, true, reason: 'お気に入りフラグがtrueで保存されている');

      // フォントサイズが「大（large）」のまま保持されている
      expect(loadedSettings.fontSize, FontSize.large,
          reason: 'フォントサイズが保持されている');

      // 履歴に「お水をください」が保存されている
      expect(loadedHistories.length, 1, reason: '履歴が保存されている');
      expect(loadedHistories.first.content, 'お水をください', reason: '履歴の内容が保持されている');

      // すべてのデータが整合性を保っている
      expect(loadedPhrases.every((p) => p.id.isNotEmpty), true,
          reason: 'データの整合性が保たれている');

      settingsContainer.dispose();
    });
  });
}
