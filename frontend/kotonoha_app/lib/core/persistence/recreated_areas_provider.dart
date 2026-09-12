/// 起動時に破損で退避して空で作り直した領域と、その告知を閉じたかどうか
///
/// `initHive()` が作り直した領域を返し、`main.dart` が `ProviderScope` の
/// override で [recreatedAreasProvider] に渡す（既定は空）。
/// 告知はセッション内で閉じられる（次回起動では作り直しは起きていないので再表示しない）。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kotonoha_app/core/persistence/persistence_state.dart';

/// 起動時に空で作り直した領域（main.dart が override で渡す）
final recreatedAreasProvider =
    Provider<Set<PersistedArea>>((ref) => const <PersistedArea>{});

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
