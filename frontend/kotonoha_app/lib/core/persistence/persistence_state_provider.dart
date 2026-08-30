/// 永続化状態のプロバイダ（ADR-005 / Phase 3 WP-1）
///
/// 【1概念1真実 — 述語を揃えるだけでは足りない】: 「保存できているか」の
/// 真実は `repository_providers` が repository を返すかどうかである。
/// ここで `Hive.isBoxOpen` を**独立に読む**と、同じ述語を書いていても
/// Riverpod のキャッシュは別々なので、評価時点が違えば別の値になりうる。
/// 「バナーは出ないのに保存されていない」は、その形で起きる。
///
/// そこで状態を repository provider **そのもの**から導く。両者は
/// Riverpod の依存関係で結ばれるため、原理的に食い違えない。
/// repository が古くなるときはバナーも同じだけ古くなる——不一致が
/// 起きないことのほうが、両方が常に最新であることより重要である。
///
/// 【box が開いているだけでは足りない】: box が開いていても書き込みは
/// 失敗しうる（ディスクフル・権限・Web の quota）。hive は書き込み失敗で
/// box を閉じないため、`isBoxOpen` は true のままになる。
/// 直近の書き込みが失敗している領域（[writeFailureProvider]）も
/// 「保存できない領域」として合流させる（台帳 L-13）。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kotonoha_app/core/persistence/persistence_state.dart';
import 'package:kotonoha_app/core/persistence/write_failure_provider.dart';
import 'package:kotonoha_app/shared/providers/repository_providers.dart';

/// 現在の永続化状態
///
/// 保存できない領域があれば、利用者に伝えるのは呼び出し側の責務
/// （`PersistenceBanner`）。
final persistenceStateProvider = Provider<PersistenceState>((ref) {
  final failedWrites = ref.watch(writeFailureProvider);

  final usableAreas = <PersistedArea>{
    if (ref.watch(historyRepositoryProvider) != null) PersistedArea.history,
    if (ref.watch(presetPhraseRepositoryProvider) != null)
      PersistedArea.presetPhrases,
    if (ref.watch(favoriteRepositoryProvider) != null) PersistedArea.favorites,
  }..removeAll(failedWrites);

  return resolvePersistenceState(openedAreas: usableAreas);
});
