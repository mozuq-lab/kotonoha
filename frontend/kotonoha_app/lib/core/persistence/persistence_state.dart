/// 永続化（Hive）が利用できているかを表す状態
///
/// ADR-005: 保存されない状態を型で表し、利用者に伝えて継続する。
/// 起動はブロックしない（NFR-301: ストレージ障害でも文字盤・TTS は使える）。
///
/// 「保存できたように見えて消える」は、発話で訂正できずデータが端末内にしか無い
/// この製品の利用者にとって、起動しないことより重い。
library;

/// 永続化の対象領域
///
/// Hive の box に1対1で対応する。box を増やすときはここにも追加すること
/// （AGENTS.md「負債を作る行為には理由が要る」— 永続化面の追加）。
enum PersistedArea {
  /// 発話履歴（box: history）
  history,

  /// 定型文（box: presetPhrases）
  presetPhrases,

  /// お気に入り（box: favorites）
  favorites,
}

/// [PersistedArea] を利用者向けの名前にする
extension PersistedAreaLabel on PersistedArea {
  /// バナー等に表示する日本語名
  String get label => switch (this) {
        PersistedArea.history => '履歴',
        PersistedArea.presetPhrases => '定型文',
        PersistedArea.favorites => 'お気に入り',
      };
}

/// 永続化の状態
///
/// 状態は3つしかない。sealed にしてあるので、利用側で switch を書けば
/// 分岐漏れはコンパイルエラーになる。
sealed class PersistenceState {
  /// 既定のコンストラクタ
  const PersistenceState();
}

/// すべての領域が保存できる
final class PersistenceReady extends PersistenceState {
  /// Ready 状態を作る
  const PersistenceReady();
}

/// 一部の領域だけ保存できない
///
/// 「復旧可能（Recoverable）」は**次回起動で直りうる**という意味。
/// `openBoxWithRecovery` は非破損エラー（ディスクフル・権限）では box を
/// 削除せず null を返すため、原因が解消すれば次回のオープンは成功する。
final class PersistenceRecoverableFailure extends PersistenceState {
  /// 保存できない領域。空にはならない
  final Set<PersistedArea> failedAreas;

  /// 失敗した領域を指定して作る
  const PersistenceRecoverableFailure(this.failedAreas);
}

/// 何も保存できない
final class PersistenceUnavailable extends PersistenceState {
  /// Unavailable 状態を作る
  const PersistenceUnavailable();
}

/// box のオープン結果から永続化の状態を導く
///
/// [openedAreas] はオープンに成功した領域。[hiveInitialized] は
/// `Hive.initFlutter()` 自体が成功したかどうか。
///
/// Hive の初期化自体が失敗している場合、box が開けたように見えても
/// 保存先が無いため [PersistenceUnavailable] とする。
PersistenceState resolvePersistenceState({
  required Set<PersistedArea> openedAreas,
  required bool hiveInitialized,
}) {
  if (!hiveInitialized) return const PersistenceUnavailable();

  final failedAreas = PersistedArea.values.toSet().difference(openedAreas);
  if (failedAreas.isEmpty) return const PersistenceReady();
  if (failedAreas.length == PersistedArea.values.length) {
    return const PersistenceUnavailable();
  }
  return PersistenceRecoverableFailure(failedAreas);
}
