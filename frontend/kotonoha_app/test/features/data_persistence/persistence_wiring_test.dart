/// 永続化配線テスト（履歴・お気に入り・定型文のHive結線）
///
/// fix/frontend-persistence-wiring:
/// - Notifierの各操作がHive Boxに永続化され、アプリ再起動相当（新しい
///   ProviderContainer）でデータが復元されることを検証する。
/// - リポジトリProviderがBox未オープン時にnullを返すことを検証する。
///
/// 設計判断（nullフォールバック方式）:
/// - Hiveを初期化しない素のProviderContainer()では repo==null となり、
///   Notifierはインメモリ動作にフォールバックする。
library;

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kotonoha_app/features/favorite/providers/favorite_provider.dart';
import 'package:kotonoha_app/features/history/domain/models/history_type.dart';
import 'package:kotonoha_app/features/history/providers/history_provider.dart';
import 'package:kotonoha_app/features/preset_phrase/providers/preset_phrase_notifier.dart';
import 'package:kotonoha_app/shared/models/favorite_item.dart';
import 'package:kotonoha_app/shared/models/favorite_item_adapter.dart';
import 'package:kotonoha_app/shared/models/history_item.dart';
import 'package:kotonoha_app/shared/models/history_item_adapter.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';
import 'package:kotonoha_app/shared/models/preset_phrase_adapter.dart';
import 'package:kotonoha_app/shared/providers/repository_providers.dart';

void main() {
  group('永続化配線 - Hive初期化済み環境', () {
    late Directory tempDir;

    setUp(() async {
      // 【テスト前準備】: 一時ディレクトリでHiveを初期化し、本番と同じ名前の
      // ボックスをオープンする（Providerが 'history'/'favorites'/'presetPhrases'
      // を参照するため）。
      await Hive.close();
      tempDir = await Directory.systemTemp.createTemp('hive_wiring_test_');
      Hive.init(tempDir.path);

      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(HistoryItemAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(PresetPhraseAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(FavoriteItemAdapter());
      }

      await Hive.openBox<HistoryItem>('history');
      await Hive.openBox<PresetPhrase>('presetPhrases');
      await Hive.openBox<FavoriteItem>('favorites');
    });

    tearDown(() async {
      // 【テスト後処理】: 全ボックスをクローズし、ディスクから削除
      await Hive.deleteBoxFromDisk('history');
      await Hive.deleteBoxFromDisk('presetPhrases');
      await Hive.deleteBoxFromDisk('favorites');
      await Hive.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('履歴を追加すると新しいコンテナで復元される', () async {
      final container1 = ProviderContainer();
      await container1
          .read(historyProvider.notifier)
          .addHistory('こんにちは', HistoryType.manualInput);
      // 念のためもう1件（種類が異なる）
      await container1
          .read(historyProvider.notifier)
          .addHistory('ありがとう', HistoryType.aiConverted);
      container1.dispose();

      // 【再起動相当】: 同じBoxを使う新しいコンテナで初期化
      final container2 = ProviderContainer();
      final state = container2.read(historyProvider);
      container2.dispose();

      expect(state.histories.length, 2);
      final contents = state.histories.map((h) => h.content).toSet();
      expect(contents, containsAll(<String>['こんにちは', 'ありがとう']));
      // typeが正しく復元されること
      final greeting = state.histories.firstWhere((h) => h.content == 'こんにちは');
      expect(greeting.type, HistoryType.manualInput);
      final ai = state.histories.firstWhere((h) => h.content == 'ありがとう');
      expect(ai.type, HistoryType.aiConverted);
    });

    test('履歴削除が永続化される', () async {
      final container1 = ProviderContainer();
      await container1
          .read(historyProvider.notifier)
          .addHistory('削除対象', HistoryType.manualInput);
      final id = container1.read(historyProvider).histories.first.id;
      await container1.read(historyProvider.notifier).deleteHistory(id);
      container1.dispose();

      final container2 = ProviderContainer();
      final state = container2.read(historyProvider);
      container2.dispose();

      expect(state.histories, isEmpty);
    });

    test('お気に入りを追加すると新しいコンテナで復元される', () async {
      final container1 = ProviderContainer();
      await container1.read(favoriteProvider.notifier).addFavorite('お気に入り1');
      await container1.read(favoriteProvider.notifier).addFavorite('お気に入り2');
      container1.dispose();

      final container2 = ProviderContainer();
      final state = container2.read(favoriteProvider);
      container2.dispose();

      expect(state.favorites.length, 2);
      expect(
        state.favorites.map((f) => f.content).toList(),
        ['お気に入り1', 'お気に入り2'],
      );
    });

    test('定型文を追加すると新しいコンテナで復元される', () async {
      final container1 = ProviderContainer();
      await container1
          .read(presetPhraseNotifierProvider.notifier)
          .addPhrase('テスト定型文', 'daily');
      container1.dispose();

      final container2 = ProviderContainer();
      final state = container2.read(presetPhraseNotifierProvider);
      container2.dispose();

      expect(state.phrases.length, 1);
      expect(state.phrases.first.content, 'テスト定型文');
      expect(state.phrases.first.category, 'daily');
    });

    test('定型文のお気に入り連動でsourceId付きFavoriteが永続化・復元される', () async {
      final container1 = ProviderContainer();
      final presetNotifier =
          container1.read(presetPhraseNotifierProvider.notifier);
      await presetNotifier.addPhrase('連動定型文', 'daily');
      final phraseId =
          container1.read(presetPhraseNotifierProvider).phrases.first.id;
      // お気に入りON → FavoriteNotifierへ連動 → 永続化
      await presetNotifier.toggleFavorite(phraseId);
      container1.dispose();

      // 【再起動相当】: 新しいコンテナでFavoriteを確認
      final container2 = ProviderContainer();
      final favState = container2.read(favoriteProvider);
      container2.dispose();

      expect(favState.favorites.length, 1);
      final fav = favState.favorites.first;
      expect(fav.content, '連動定型文');
      expect(fav.sourceType, 'preset_phrase');
      expect(fav.sourceId, phraseId);
    });

    test('initializeDefaultPhrasesが永続化され新しいコンテナで復元される', () async {
      final container1 = ProviderContainer();
      await container1
          .read(presetPhraseNotifierProvider.notifier)
          .initializeDefaultPhrases();
      final count1 = container1.read(presetPhraseNotifierProvider).phrases.length;
      container1.dispose();

      expect(count1, greaterThan(0));

      final container2 = ProviderContainer();
      final state = container2.read(presetPhraseNotifierProvider);
      container2.dispose();

      expect(state.phrases.length, count1);
    });

    test('loadPhrasesがHiveから定型文をstateに再読込する', () async {
      // 別経路でBoxに直接保存（Notifier未経由の保存をシミュレート）
      final box = Hive.box<PresetPhrase>('presetPhrases');
      final now = DateTime.now();
      await box.put(
        'p1',
        PresetPhrase(
          id: 'p1',
          content: '保存済み定型文',
          category: 'daily',
          isFavorite: false,
          displayOrder: 0,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(presetPhraseNotifierProvider.notifier);

      // loadPhrases() でHiveから再読込され、stateに反映される
      await notifier.loadPhrases();
      final state = container.read(presetPhraseNotifierProvider);

      expect(state.isLoading, isFalse);
      expect(state.phrases.map((p) => p.content), contains('保存済み定型文'));
    });

    test('clearAllHistoriesがHiveの履歴を全削除する', () async {
      final container1 = ProviderContainer();
      await container1
          .read(historyProvider.notifier)
          .addHistory('a', HistoryType.manualInput);
      await container1.read(historyProvider.notifier).clearAllHistories();
      container1.dispose();

      final container2 = ProviderContainer();
      final state = container2.read(historyProvider);
      container2.dispose();

      expect(state.histories, isEmpty);
    });

    test('リポジトリProviderはBoxオープン時に非nullを返す', () {
      final container = ProviderContainer();
      expect(container.read(historyRepositoryProvider), isNotNull);
      expect(container.read(favoriteRepositoryProvider), isNotNull);
      expect(container.read(presetPhraseRepositoryProvider), isNotNull);
      container.dispose();
    });
  });

  group('永続化配線 - Hive未初期化環境（nullフォールバック）', () {
    setUp(() async {
      // 【前提】: 全ボックスを閉じてオープンされていない状態にする
      await Hive.close();
    });

    test('リポジトリProviderはBox未オープン時にnullを返す', () {
      final container = ProviderContainer();
      expect(container.read(historyRepositoryProvider), isNull);
      expect(container.read(favoriteRepositoryProvider), isNull);
      expect(container.read(presetPhraseRepositoryProvider), isNull);
      container.dispose();
    });

    test('repo==nullでもインメモリで履歴追加が動作する', () async {
      final container = ProviderContainer();
      await container
          .read(historyProvider.notifier)
          .addHistory('インメモリ', HistoryType.manualInput);
      final state = container.read(historyProvider);
      container.dispose();

      expect(state.histories.length, 1);
      expect(state.histories.first.content, 'インメモリ');
    });
  });
}
