/// 書き込みに失敗した領域の記録（ADR-005 / 台帳 L-13）
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kotonoha_app/core/persistence/persistence_state.dart';

/// 直近の書き込みが失敗している領域を保持する
///
/// 【自己回復する理由】: ディスクフルは解消しうる。一度の失敗で恒久的に
/// 警告を出し続けると、直っても利用者には分からない。
/// 次の書き込みが成功した時点でその領域を外す。
class WriteFailureNotifier extends Notifier<Set<PersistedArea>> {
  @override
  Set<PersistedArea> build() => const <PersistedArea>{};

  /// [area] への書き込み結果を記録する
  void record({required PersistedArea area, required bool succeeded}) {
    final isRecorded = state.contains(area);
    if (succeeded == !isRecorded) return;

    state = succeeded
        ? (Set<PersistedArea>.from(state)..remove(area))
        : {...state, area};
  }
}

/// 直近の書き込みが失敗している領域
final writeFailureProvider =
    NotifierProvider<WriteFailureNotifier, Set<PersistedArea>>(
  WriteFailureNotifier.new,
);
