/// 設定（SharedPreferences）の保存失敗と、下書きの読込問題を表すキーの集合
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

/// 入力中の文（下書き）の SharedPreferences キー。`app_session_provider.dart` と共有する
const String draftTextWriteKey = 'draft_text';

/// 定型文専用下書き。read問題は別keyで保持し、write成功で消さない。
const String phraseDraftWriteKey = 'preset_phrase_drafts';

/// 復元不能の告知。書込不能の文へは合流させない。
const String phraseDraftReadKey = '$phraseDraftWriteKey.read';

/// 下書きの消去の失敗。下書きは残るので「閉じると消えます」へは合流させない（L-182）。
const String phraseDraftClearKey = '$phraseDraftWriteKey.clear';

/// 読めた下書きの壊れていた分を落とした。戻らないので、書込の成功や読み直しでは
/// 解消しない（読めなかった＝読み直せる [phraseDraftReadKey] と分ける。L-176）。
const String phraseDraftCorruptKey = '$phraseDraftWriteKey.corrupt';

/// 失敗しているキーを利用者向けの名前に写す（順序固定: 入力中の文 → 定型文の下書き → 設定）
/// 下書きの書込以外（read・clear・corrupt）はここへ合流させず、バナーが別の文で表示する。
List<String> prefFailureNames(Set<String> failedKeys) => [
      if (failedKeys.contains(draftTextWriteKey)) '入力中の文',
      if (failedKeys.contains(phraseDraftWriteKey)) '定型文の下書き',
      if (failedKeys.any((key) =>
          key != draftTextWriteKey && !key.startsWith(phraseDraftWriteKey)))
        '設定',
    ];
