/// 起動時に破損を見つけて退避した領域とその結果、その告知を閉じたかどうか
///
/// `initHive()` が領域ごとの結果（空で作り直した／読める分だけ救った）を返し、
/// `main.dart` が `ProviderScope` の override で [corruptionOutcomesProvider] に
/// 渡す（既定は空）。
/// 告知はセッション内で閉じられる（次回起動では破損は起きていないので再表示しない）。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kotonoha_app/core/persistence/persistence_state.dart';

/// 起動時に破損を見つけた領域とその結果（main.dart が override で渡す）
final corruptionOutcomesProvider =
    Provider<Map<PersistedArea, CorruptionOutcome>>(
  (ref) => const <PersistedArea, CorruptionOutcome>{},
);

/// 作り直しの告知を利用者が閉じたか
class RecreatedNoticeDismissedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  /// 告知を閉じる
  void dismiss() => state = true;
}

/// 作り直しの告知を閉じたか
final recreatedNoticeDismissedProvider =
    NotifierProvider<RecreatedNoticeDismissedNotifier, bool>(
  RecreatedNoticeDismissedNotifier.new,
);
