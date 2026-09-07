/// 開いているHive BoxからRepositoryを提供し、未初期化・未オープンならnullを返す。
/// Notifierはnull時にインメモリ動作へ切り替える。永続化の可否の通知は別の状態で扱う。
/// Boxのproviderを分離し、RepositoryやNotifierを実物のまま書き込み失敗を注入できるようにする。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kotonoha_app/core/persistence/persistence_state.dart';
import 'package:kotonoha_app/core/persistence/write_failure_provider.dart';
import 'package:kotonoha_app/features/favorite/data/favorite_repository.dart';
import 'package:kotonoha_app/features/history/data/history_repository.dart';
import 'package:kotonoha_app/features/preset_phrase/data/preset_phrase_repository.dart';
import 'package:kotonoha_app/shared/models/favorite_item.dart';
import 'package:kotonoha_app/shared/models/history_item.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';

/// 内部ヘルパ: オープン済みなら box を返す
Box<T>? _openedBox<T>(PersistedArea area) =>
    Hive.isBoxOpen(area.boxName) ? Hive.box<T>(area.boxName) : null;

/// 内部ヘルパ: 書き込み結果を [writeFailureProvider] へ報告する関数を作る
/// ガード: provider が破棄された後にコールバックが発火しても
/// 落ちないようにする（プロバイダ間の相互参照は ref の生存確認が要る）。
void Function(bool) _reporterFor(Ref ref, PersistedArea area) {
  return (succeeded) {
    if (!ref.mounted) return;
    ref
        .read(writeFailureProvider.notifier)
        .record(area: area, succeeded: succeeded);
  };
}

/// Provider定義: 履歴Box（未オープン時はnull）
final historyBoxProvider = Provider<Box<HistoryItem>?>(
  (ref) => _openedBox<HistoryItem>(PersistedArea.history),
);

/// Provider定義: お気に入りBox（未オープン時はnull）
final favoriteBoxProvider = Provider<Box<FavoriteItem>?>(
  (ref) => _openedBox<FavoriteItem>(PersistedArea.favorites),
);

/// Provider定義: 定型文Box（未オープン時はnull）
final presetPhraseBoxProvider = Provider<Box<PresetPhrase>?>(
  (ref) => _openedBox<PresetPhrase>(PersistedArea.presetPhrases),
);

/// Provider定義: 履歴Repository（Box未オープン時はnull）
final historyRepositoryProvider = Provider<HistoryRepository?>((ref) {
  final box = ref.watch(historyBoxProvider);
  if (box == null) return null;
  return HistoryRepository(
    box: box,
    onWriteResult: _reporterFor(ref, PersistedArea.history),
  );
});

/// Provider定義: お気に入りRepository（Box未オープン時はnull）
final favoriteRepositoryProvider = Provider<FavoriteRepository?>((ref) {
  final box = ref.watch(favoriteBoxProvider);
  if (box == null) return null;
  return FavoriteRepository(
    box: box,
    onWriteResult: _reporterFor(ref, PersistedArea.favorites),
  );
});

/// Provider定義: 定型文Repository（Box未オープン時はnull）
final presetPhraseRepositoryProvider = Provider<PresetPhraseRepository?>((ref) {
  final box = ref.watch(presetPhraseBoxProvider);
  if (box == null) return null;
  return PresetPhraseRepository(
    box: box,
    onWriteResult: _reporterFor(ref, PersistedArea.presetPhrases),
  );
});
