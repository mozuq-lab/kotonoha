/// 永続化状態プロバイダのテスト（ADR-005 / Phase 3 WP-1）
///
/// 【なぜ実 Hive を使うか】: 「保存できているか」の真実は Hive の box が
/// 開いているかどうかであり、repository_providers も同じ述語を見ている。
/// モックを挟むと、検証しているのが「モックの設定」になり、
/// 両者が食い違ったこと自体を検出できない。
library;

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kotonoha_app/core/persistence/persistence_state.dart';
import 'package:kotonoha_app/core/persistence/persistence_state_provider.dart';
import 'package:kotonoha_app/shared/models/favorite_item.dart';
import 'package:kotonoha_app/shared/models/favorite_item_adapter.dart';
import 'package:kotonoha_app/shared/models/history_item.dart';
import 'package:kotonoha_app/shared/models/history_item_adapter.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';
import 'package:kotonoha_app/shared/models/preset_phrase_adapter.dart';
import 'package:kotonoha_app/shared/providers/repository_providers.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    await Hive.close();
    tempDir = await Directory.systemTemp.createTemp('persistence_state_test_');
    Hive.init(tempDir.path);
    for (final adapter in <TypeAdapter<dynamic>>[
      HistoryItemAdapter(),
      PresetPhraseAdapter(),
      FavoriteItemAdapter(),
    ]) {
      if (!Hive.isAdapterRegistered(adapter.typeId)) {
        Hive.registerAdapter(adapter);
      }
    }
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  group('persistenceStateProvider', () {
    test('全boxが開いていればReady', () async {
      await Hive.openBox<HistoryItem>(PersistedArea.history.boxName);
      await Hive.openBox<PresetPhrase>(PersistedArea.presetPhrases.boxName);
      await Hive.openBox<FavoriteItem>(PersistedArea.favorites.boxName);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(persistenceStateProvider), isA<PersistenceReady>());
    });

    test('一部のboxだけ開いていればRecoverableFailureで、閉じている領域を報告する', () async {
      await Hive.openBox<HistoryItem>(PersistedArea.history.boxName);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(persistenceStateProvider);
      expect(state, isA<PersistenceRecoverableFailure>());
      expect(
        (state as PersistenceRecoverableFailure).failedAreas,
        containsAll(<PersistedArea>[
          PersistedArea.presetPhrases,
          PersistedArea.favorites,
        ]),
      );
    });

    test('boxが1つも開いていなければUnavailable', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(persistenceStateProvider),
        isA<PersistenceUnavailable>(),
      );
    });

    test('repositoryを差し替えると永続化状態も追随する', () async {
      // 【なぜこれを固定するか】: 「保存できているか」の真実が2つあると、
      // 片方だけが古くなって「保存できていないのにバナーが出ない」が起きる。
      // 状態を repository provider から導いていれば、両者は Riverpod の
      // 依存関係で結ばれ、原理的に食い違えない。
      // Hive.isBoxOpen を独立に読む実装では、override しても追随しない。
      await Hive.openBox<HistoryItem>(PersistedArea.history.boxName);
      await Hive.openBox<PresetPhrase>(PersistedArea.presetPhrases.boxName);
      await Hive.openBox<FavoriteItem>(PersistedArea.favorites.boxName);

      final container = ProviderContainer(
        overrides: [favoriteRepositoryProvider.overrideWithValue(null)],
      );
      addTearDown(container.dispose);

      final state = container.read(persistenceStateProvider);
      expect(state, isA<PersistenceRecoverableFailure>());
      expect(
        (state as PersistenceRecoverableFailure).failedAreas,
        equals({PersistedArea.favorites}),
      );
    });

    test('nullを返すrepositoryの領域と、状態が報告する失敗領域が一致する', () async {
      // 【この製品にとっての意味】: 利用者に「保存できない」と伝える根拠と、
      // 実際に保存を担うrepositoryの有無は、同じ事実でなければならない。
      // 出所が分かれると「バナーは出ないのに保存されていない」が起きる。
      await Hive.openBox<HistoryItem>(PersistedArea.history.boxName);
      await Hive.openBox<FavoriteItem>(PersistedArea.favorites.boxName);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(historyRepositoryProvider), isNotNull);
      expect(container.read(favoriteRepositoryProvider), isNotNull);
      expect(container.read(presetPhraseRepositoryProvider), isNull);

      final state = container.read(persistenceStateProvider)
          as PersistenceRecoverableFailure;
      expect(state.failedAreas, equals({PersistedArea.presetPhrases}));
    });
  });
}
