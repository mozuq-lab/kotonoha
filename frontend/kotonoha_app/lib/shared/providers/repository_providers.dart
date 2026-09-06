/// Provider定義: Hiveリポジトリの提供（永続化配線）
///
/// 設計判断: nullフォールバック方式
/// - 対応するHive Boxがオープン済みの場合のみRepositoryインスタンスを返す。
/// - Hive未初期化・Box未オープンの場合はnullを返す。
/// - これにより、Hiveを初期化しない素のProviderContainer()を使う既存テスト
///   （例: favorite_sync_test）は repo==null となり、Notifierが従来どおり
///   インメモリ動作にフォールバックできる。
/// - Hive.isBoxOpen() は Hive.init 未実行でも例外を投げずに false を返す。
///
/// box の provider を分けている理由: Hive の [Box] は外部 SDK の境界であり、
/// テストで差し替えてよい唯一の層。ここに seam を置くことで、
/// repository・notifier・provider・ウィジェットは実物のまま検証できる
/// （書き込み失敗の注入など）。
///
/// 信頼性レベル: 青信号 - architecture.mdのローカルストレージ設計に基づく
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
///
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
