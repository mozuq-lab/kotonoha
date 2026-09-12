/// 設定（SharedPreferences）の保存が失敗しているキーの集合
///
/// Hive の領域は [PersistedArea] ごとに `writeFailureProvider` が持つが、
/// 設定は Hive の box ではない（許可リスト検査の対象外）ので別に持つ。
/// キーごとに持つのは、別の設定の保存が成功しても未保存の設定が残っている間は
/// 告知を消さないため。バナーは Hive の領域と 1 つの告知に並べる（ADR-005、L-83）。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 設定の保存失敗の報告（キー単位）
class SettingsWriteFailureNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const <String>{};

  /// 保存の結果を記録する（成功でそのキーの失敗が解消、失敗で報告）
  void record({required String key, required bool succeeded}) {
    final failed = state.contains(key);
    if (succeeded == !failed) return;
    state =
        succeeded ? (Set<String>.from(state)..remove(key)) : {...state, key};
  }
}

/// 設定の保存が失敗しているキー（空なら失敗なし）
final settingsWriteFailureProvider =
    NotifierProvider<SettingsWriteFailureNotifier, Set<String>>(
  SettingsWriteFailureNotifier.new,
);
