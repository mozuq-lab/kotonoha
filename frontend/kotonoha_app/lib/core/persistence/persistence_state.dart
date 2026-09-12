/// 永続化（Hive）が利用できているかを表す状態
/// ADR-005: 保存されない状態を型で表し、利用者に伝えて継続する。
/// 起動はブロックしない（: ストレージ障害でも文字盤・TTS は使える）。
/// 「保存できたように見えて消える」は、発話で訂正できずデータが端末内にしか無い
/// この製品の利用者にとって、起動しないことより重い。
library;

/// 永続化の対象領域
/// Hive の box に1対1で対応する。box を増やすときはここにも追加すること
/// （AGENTS.md 規律 8 — 永続化面の追加）。
enum PersistedArea {
  /// 発話履歴（box: history）
  history,

  /// 定型文（box: presetPhrases）
  presetPhrases,

  /// お気に入り（box: favorites）
  favorites,
}

/// [PersistedArea] と、Hive box 名・利用者向けの名前との対応
extension PersistedAreaNames on PersistedArea {
  /// 対応する Hive box の名前
  /// box 名の定義はここだけに置く。`hive_init.dart`（開く側）と
  /// `repository_providers.dart`（読む側）はどちらもこの値を使う。
  /// 文字列を複数箇所に書くと、片方だけ直したときに
  /// 「保存できていないのにバナーが出ない」形で食い違う。
  /// 注意: Hive は box 名を小文字化して扱う（hive 2.2.3 `hive_impl.dart`)。
  /// 大小文字だけが違う名前を足すと、別領域のつもりで同一 box になる。
  String get boxName => switch (this) {
        PersistedArea.history => 'history',
        PersistedArea.presetPhrases => 'presetPhrases',
        PersistedArea.favorites => 'favorites',
      };

  /// バナー等に表示する日本語名
  String get label => switch (this) {
        PersistedArea.history => '履歴',
        PersistedArea.presetPhrases => '定型文',
        PersistedArea.favorites => 'お気に入り',
      };
}

/// 永続化の状態
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
/// 「復旧可能（Recoverable）」は**次回起動で直りうる**という意味。
/// `openBoxWithRecovery` は非破損エラー（ディスクフル・権限）では box を
/// 削除せず null を返すため、原因が解消すれば次回のオープンは成功する。
final class PersistenceRecoverableFailure extends PersistenceState {
  /// 保存できない領域
  /// `resolvePersistenceState` は空集合を作らないが、**型もコンストラクタも
  /// それを強制していない**（`const` コンストラクタでは要素数を assert できない）。
  /// 描画側は空集合でも無音にならないよう倒すこと——ADR-005 は
  /// 「保存されないことは必ず伝える」と定めている。
  final Set<PersistedArea> failedAreas;

  /// 失敗した領域を指定して作る
  const PersistenceRecoverableFailure(this.failedAreas);
}

/// 何も保存できない
final class PersistenceUnavailable extends PersistenceState {
  /// Unavailable 状態を作る
  const PersistenceUnavailable();
}

/// 破損した box を `<box>.hive.corrupt.bak` に退避して空で作り直した状態。
/// 保存はできるが、作り直した領域の以前のデータは無い。
/// 「黙って消える」を避けるため、領域名つきで利用者に伝える（ADR-005、L-90）。
final class PersistenceRecreated extends PersistenceState {
  /// 作り直した領域
  final Set<PersistedArea> recreatedAreas;

  /// Recreated 状態を作る
  const PersistenceRecreated(this.recreatedAreas);
}

/// 開いている box の集合から永続化の状態を導く
/// [openedAreas] は保存が効いている領域。`Hive.initFlutter` 自体が
/// 失敗した場合は box が1つも開かないため、空集合として渡ってきて
/// [PersistenceUnavailable] になる。初期化の成否を別引数で受け取ると
/// 同じ事実の出所が2つになるので受け取らない。
PersistenceState resolvePersistenceState({
  required Set<PersistedArea> openedAreas,
  Set<PersistedArea> recreatedAreas = const {},
}) {
  final failedAreas = PersistedArea.values.toSet().difference(openedAreas);
  if (failedAreas.isEmpty) {
    // 開けない領域が無くても、破損で作り直した領域があれば利用者に伝える（ADR-005）
    return recreatedAreas.isEmpty
        ? const PersistenceReady()
        : PersistenceRecreated(recreatedAreas);
  }
  if (failedAreas.length == PersistedArea.values.length) {
    return const PersistenceUnavailable();
  }
  return PersistenceRecoverableFailure(failedAreas);
}
