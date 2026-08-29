/// 【Provider定義】: Hiveリポジトリの提供（永続化配線）
///
/// 【設計判断】: nullフォールバック方式
/// - 対応するHive Boxがオープン済みの場合のみRepositoryインスタンスを返す。
/// - Hive未初期化・Box未オープンの場合はnullを返す。
/// - これにより、Hiveを初期化しない素のProviderContainer()を使う既存テスト
///   （例: favorite_sync_test）は repo==null となり、Notifierが従来どおり
///   インメモリ動作にフォールバックできる。
/// - Hive.isBoxOpen() は Hive.init 未実行でも例外を投げずに false を返す。
///
/// 🔵 信頼性レベル: 青信号 - architecture.mdのローカルストレージ設計に基づく
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kotonoha_app/core/persistence/persistence_state.dart';
import 'package:kotonoha_app/features/favorite/data/favorite_repository.dart';
import 'package:kotonoha_app/features/history/data/history_repository.dart';
import 'package:kotonoha_app/features/preset_phrase/data/preset_phrase_repository.dart';
import 'package:kotonoha_app/shared/models/favorite_item.dart';
import 'package:kotonoha_app/shared/models/history_item.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';

/// 【Provider定義】: 履歴Repository（Box未オープン時はnull）
final historyRepositoryProvider = Provider<HistoryRepository?>(
  (ref) => Hive.isBoxOpen(PersistedArea.history.boxName)
      ? HistoryRepository(
          box: Hive.box<HistoryItem>(PersistedArea.history.boxName))
      : null,
);

/// 【Provider定義】: お気に入りRepository（Box未オープン時はnull）
final favoriteRepositoryProvider = Provider<FavoriteRepository?>(
  (ref) => Hive.isBoxOpen(PersistedArea.favorites.boxName)
      ? FavoriteRepository(
          box: Hive.box<FavoriteItem>(PersistedArea.favorites.boxName))
      : null,
);

/// 【Provider定義】: 定型文Repository（Box未オープン時はnull）
final presetPhraseRepositoryProvider = Provider<PresetPhraseRepository?>(
  (ref) => Hive.isBoxOpen(PersistedArea.presetPhrases.boxName)
      ? PresetPhraseRepository(
          box: Hive.box<PresetPhrase>(PersistedArea.presetPhrases.boxName))
      : null,
);
