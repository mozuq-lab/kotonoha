/// 永続化状態のプロバイダ（ADR-005 / Phase 3 WP-1）
///
/// 【1概念1真実】: 「保存できているか」の真実は Hive の box が開いているか
/// どうかであり、`repository_providers` が repository を返すかどうかも
/// 同じ述語で決まっている。初期化時のスナップショットなど別の出所から
/// 導くと、「バナーは出ないのに保存されていない」が起こりうる。
/// そのため、ここでも `Hive.isBoxOpen` を唯一の根拠にする。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kotonoha_app/core/persistence/persistence_state.dart';

/// 現在の永続化状態
///
/// 保存できない領域があれば、利用者に伝えるのは呼び出し側の責務
/// （`PersistenceBanner`）。
final persistenceStateProvider = Provider<PersistenceState>((ref) {
  final openedAreas = <PersistedArea>{
    for (final area in PersistedArea.values)
      if (Hive.isBoxOpen(area.boxName)) area,
  };
  return resolvePersistenceState(openedAreas: openedAreas);
});
