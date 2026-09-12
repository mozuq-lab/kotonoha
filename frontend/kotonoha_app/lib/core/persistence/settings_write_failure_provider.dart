/// 設定（SharedPreferences）の直近の保存が失敗しているか
///
/// Hive の領域は [PersistedArea] ごとに `writeFailureProvider` が持つが、
/// 設定は Hive の box ではない（許可リスト検査の対象外）ので別に持つ。
/// バナーは両方を 1 つの告知に並べる（ADR-005、L-83）。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 設定の保存失敗の報告
class SettingsWriteFailureNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  /// 保存の結果を記録する（成功で解消、失敗で報告）
  void record({required bool succeeded}) => state = !succeeded;
}

/// 設定の直近の保存が失敗しているか
final settingsWriteFailureProvider =
    NotifierProvider<SettingsWriteFailureNotifier, bool>(
  SettingsWriteFailureNotifier.new,
);
