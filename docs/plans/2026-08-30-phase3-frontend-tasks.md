# Phase 3（frontend の正しさ）実装計画

> **エージェント向け:** 実行は `superpowers:subagent-driven-development` または
> `superpowers:executing-plans` を使う。手順はチェックボックス（`- [ ]`）で追跡する。
> **完了したら破棄する文書。** 恒久成果物は `openspec/specs/` と `docs/adr/` のみ。

**目的:** 発話支援アプリとして「保存できたように見えて消える」と「同じ概念が4箇所にある」を
無くし、リリース条件を満たす frontend にする。

**方針:** 状態を型で表す（`PersistenceState`）／真実を1つに寄せる（`favoriteProvider`）／
検証は最も外側の境界（描画されたウィジェット・実際の Hive box）で行う。

**技術:** Flutter 3.41.5（fvm 経由）／Riverpod 3.x（`flutter_riverpod ^3.1.0`）／Hive 2.2.3
（TypeAdapter は手書き。`hive_generator` は使っていない）／go_router

**入力仕様:** `docs/plans/2026-08-29-architecture-remediation.md` §Phase 3、`docs/adr/ADR-005-frontend-single-truth.md`

## 現況（2026-08-30 時点。**次のセッションはここから読むこと**）

| WP | 状態 |
|---|---|
| WP1 永続化の状態を明示する | **完了**（下記 §WP1） |
| **WP2 お気に入りを1つの真実にする** | **次はこれ。チェックリスト粒度なので着手時に task 分解が要る** |
| WP3 往復テスト | **ADR-007 のリリース条件に入っていない** |
| WP4 E2E | **完了**（4経路が CI 緑。Issue #84 / PR #87） |
| WP5 Hive 許可リスト＋analyzer ルール | 未着手。**1d はリリース条件** |
| WP6 OpenSpec baseline | **ADR-007 のリリース条件に入っていない** |

**リリース目標日は廃止した（2026-08-30）。** 歯止めは条件1〜4の閉包で、
条件を足すには ADR-007 の改訂が要る。作業中に見つかった問題は台帳（Issue #85）へ送る。

**WP2 に着手する前に読むこと**:

- `docs/verification-principles.md` のトリアージ節（**2026-08-30 に改訂**。
  P0 は「到達経路を示せる」かつ「実際に赤を見せた」の両方。
  P1 では自作の検出器を選択肢に入れない）
- 同 §3 の `testWidgets` × 実 Hive の制約（`tester.runAsync()` で脱出できる）
- ADR-005（お気に入りの正は `favoriteProvider`。キーは id）
- **収束 #3**: 実装前に「何を何から導くか」を1枚に決める。WP1 Task 1.2 は
  これを省いて3周のレビューを要し、L-13 の修正は先に決めて0周だった

---

## 【次セッションの最初の作業】文書を減らす — 呼び出し側/実装側の分離を試す

**この作業の第一目的は文書削減ではなく、「呼び出し側（計画・検証）と実装側（サブエージェント）
を分ける方法が機能するか」を確かめること。** 範囲が閉じていて失敗しても損失が小さいため、
WP2 の前の試行台として選んだ。

### 背景（2026-08-30 の観察）

私が従うべき文書は **3,508行**（AGENTS.md 364 / verification-principles 469 /
CONTRIBUTING 420 / 計画2本 1,453 / ADR 8本 802）。全てに注意を払いながら作業するのは
現実的でない。

さらに、`verification-principles.md` は冒頭で自ら
「**実行可能な検査に変換できたものから順に削る。全部消えるのが理想**」と定めているのに、
2026-08-30 に私が **325行 → 469行（+45%）** に増やした。しかも「収束」のための施策として。
**文書が発火しない問題に、文書を増やして対処した**——検出器がザルだったときに検出器へ
パッチを当てたのと同じ形である。

### 対象

`docs/verification-principles.md`（469行）**1本のみ**。

### 役割の分け方

| | 担当 | 内容 |
|---|---|---|
| 計画 | **呼び出し側** | 節の仕分け（下記の表。**済**） |
| 実装 | **サブエージェント** | テストを書く・文書を編集する |
| 検証 | **呼び出し側** | テストを走らせ、**mutation で歯があるか確認する** |

**検証は委譲しない。** 2026-08-30 に実物を動かして初めて分かったことが複数あった
（バナー文字の下線・`.last` の矩形 y=2016〜2040）。報告を信じるだけでは失われる。
同日、私自身がコミットメッセージに事実でないことを2度書いている
（「定数に切り出した」「3テーマ×2状態を測る」）。**報告は実物ではない。**

### 節の仕分け（呼び出し側が実施済み。サブエージェントへの入力）

| 節 | 扱い | 理由 |
|---|---|---|
| §1 経路ではなくクラスを数える | **残す** | 思考法。検査に変換できない |
| §1 修正の前にテストを書く | **残す** | 手順。機械では判定できない |
| §1 戻り値ではなくプロセスの外側で検証する | **残す** | 同上 |
| §1 観測面を増やしたら流す経路も用意する | **要調査** | 「観測面の追加」を検知する権威があるか |
| §1 有限な側を列挙し、無限な側を生成する | **残す** | 思考法 |
| §1 許可集合は書き下して有限であることを確認する | **要調査** | 8周の直接原因（`limits.SCHEMES`）。**権威の出力を消費する検査に変換できる可能性** |
| §1 正しい境界で検証する | **残す** | 思考法 |
| §1 検証環境の変数を確認する | **残す** | 手順 |
| §1 安い検証が高い検証を締め出す | **残す** | 思考法 |
| §1 自分が書いた文書を事実として扱わない | **残す** | 思考法。ただし**最重要**なので短縮しない |
| §1 「実測確認済み」に再現手段を添える | **残す** | 手順 |
| §1 レビュアーが AI なら盲点は相関する | **残す** | 2系統の根拠 |
| §2 「指摘ゼロ」を完了条件にしない | **残す** | 判断の規約 |
| §2 差分の面積を完了条件に入れる | **要調査** | `git diff --stat` は権威。CI で機械化できる |
| §2 トリアージ | **残す** | レビューの入力そのもの。**2026-08-30 に改訂済み** |
| §2 「却下」を状態として持つ | **残す** | 台帳の運用規約 |
| §2 テストは2系統で書く | **残す** | 思考法 |
| §2 レビューは必須／レビューの仕様 | **残す** | 運用規約 |
| §3 `testWidgets` × 実 Hive | **要調査（変換できない見込み）** | *技法*であって不変条件ではない |
| §3 Hive の `registerAdapter` 型引数 | **要調査（変換できない見込み）** | 検査するなら自作の grep になり、**新 P1 の処方箋が禁じている** |
| §3 backend 側4件（SecretStr・例外連鎖・漏えいシンク・urlparse） | **要調査** | Phase 2 で実装が消えるなら、**そのとき一緒に削れる** |

**「要調査」は6件。残りは変換できないので文書に残る。**

### サブエージェントへ渡す拘束（文脈が無いので書き写す）

1. 上の仕分け表
2. **新しい P1 の処方箋**: 「構造を変えて表現不可能にできないか → 既存の権威の出力を
   消費できないか → どちらも無ければ記録して受け入れる。**自作の検出器は選択肢に入れない**」
   （ADR-008 と 2026-08-30 の3周の失敗による）
3. テスト規律: モックは外部 SDK / ネットワーク境界のみ／完全一致アサーション禁止／
   検証は最も外側の境界で
4. **削除してよい条件**: その原則を破ったときに落ちるテストが実在すること。
   **テストが無いのに削除しない**

### 呼び出し側が投げる問い（閉じているもの）

- 実行前: **この節を検査に変換する権威は何か。無ければ変換しない**
- 実行後: **削除した原則を破ると、実際にテストが落ちるか**（mutation で確認）
- 実行後: **計画を変える発見はあったか**

投げてはいけないのは「**この実装は良いか**」。開いており、8周の形になる。

### 判定基準（文書が何行減ったかではない）

| 観点 | 成功 | 失敗 |
|---|---|---|
| 呼び出し側が差分を保持せずに済んだか | 報告と検証だけで判断できた | 差分を読まないと判断できなかった |
| 問いが閉じていたか | 各問いが1往復で終わった | 「もっと良くできる」の往復が始まった |
| 検証が効いたか | mutation で歯の無いテストを検出できた | 報告を信じるしかなかった |

**3つ目が最重要。**

### 廃棄条件（先に決めてある）

- **呼び出し側が差分を読まないと判断できなかったら、その時点で方法は失敗**と記録し、
  通常の進め方に戻す
- サブエージェントへの指示が2周目に入ったら中止する

### 予想される結果

**削減量は小さい可能性が高い。** §3 の2件（私が今日追加したもの）は変換できない見込みで、
「変換できないから残す」が正しい結論になりうる。**それも成果である。**
削減量と方法の成否は別なので、判定基準を分けてある。

---

## 着手時の実測（2026-08-30）

| 項目 | 値 | 出所 |
|---|---|---|
| frontend lib | 19,358 行 / 157 ファイル | `find lib -name '*.dart'` |
| frontend test | 177 ファイル | 同上 |
| テスト | **1,943 passed / 1 skipped**（exit 0） | `flutter test` |
| E2E | 7本中 CI 実行は 1本（`app_startup_test.dart`）のみ | `.github/workflows/flutter.yml` |

計画 §2 の数値（2026-08-29 実測）と一致。前提は生きている。

## 全体の拘束（全タスクの要件に暗黙に含まれる）

- **ADR-005**: お気に入りの正は `favoriteProvider`。キーは内容テキストではなく **id**。
  `HistoryItem.isFavorite`・`PresetPhrase.isFavorite` は両方削除する（片方だけだと並行真実が残る）。
  永続化の失敗は `sealed class PersistenceState { Ready / RecoverableFailure / Unavailable }`
  で表し、**利用者に伝えて継続する**（起動はブロックしない）
- **NFR-301（基本機能継続）**: ストレージ障害でも文字盤・TTS は使えること
- **通知 UI の形（2026-08-30 決定）**: **常設バナー**。`Ready` のときは高さ0で非表示、
  `RecoverableFailure` と `Unavailable` で色と文言を変える。`OfflineBanner` と同じ列に置く
- **テスト規律**（`docs/verification-principles.md`）:
  - 修正の前にテストを書き、**赤を確認してから**直す
  - モックは外部 SDK / ネットワーク境界にのみ置く。**自分の関数を patch しない**
  - **完全一致アサーションを書かない**。「実装を安全側に変えたときに落ちるか」を自問する
  - 検証は最も外側の境界（描画されたウィジェット・実際の Hive box）で行う
- **`flutter test` 実行時の既知の罠**（メモリ由来、着手前に確認済み）:
  `testWidgets()` 内で未モックの `FlutterTts` / `SharedPreferences` を呼ぶと無限ハングする。
  プロバイダ間の相互参照は `ref.exists()` + `ref.mounted` でガードする
- **コミット**: 1タスク完了ごと。メッセージは日本語で `種別: 内容 (Phase 3 / WP-N)`
- **マージ単位**: 完了条件7（400行 / 12ファイル）。超えるなら WP を割る

---

## ファイル構成（新規・変更）

### WP1 で作る／触る

| ファイル | 責務 |
|---|---|
| `lib/core/persistence/persistence_state.dart`（新規） | `sealed class PersistenceState` の定義のみ |
| `lib/core/persistence/persistence_state_provider.dart`（新規） | 状態の保持と box オープン結果からの導出 |
| `lib/core/utils/hive_init.dart`（変更） | `initHive()` が per-box の成否を返す |
| `lib/main.dart`（変更） | 結果を `ProviderScope` の override で注入 |
| `lib/core/widgets/persistence_banner.dart`（新規） | 常設バナーの描画 |
| `lib/core/widgets/app_shell.dart`（変更） | `OfflineBanner` と同じ列に配線 |

### WP2 で触る

`lib/shared/models/{history_item,preset_phrase}.dart` と対応 adapter、
`lib/features/preset_phrase/providers/preset_phrase_notifier.dart`、
`lib/features/preset_phrase/presentation/widgets/{phrase_list_widget,phrase_list_item}.dart`、
`lib/features/history/presentation/history_screen.dart`、
`lib/features/favorite/{data/favorite_repository.dart,providers/favorite_provider.dart}`、
`lib/features/input_candidates/domain/input_candidate_scorer.dart`、
`lib/core/persistence/favorite_migration.dart`（新規）

---

## WP1 — 永続化の状態を明示する — **完了（2026-08-30）**

**実績**: 12ファイル / +755 −28 行（うち lib は約321行、test 約434行）。
テストは 1,943 → 1,974 passed（+31）。`flutter analyze lib` 警告0。

**着手時の計画から変えた点**:

1. **状態の出所**。当初は `initHive()` の戻り値をスナップショットして
   `ProviderScope` に注入する設計にしていたが、`repository_providers` が使う
   `Hive.isBoxOpen` と出所が2つになり ADR-005 が禁じる並行真実そのものになる。
   同じ述語から導く形に変え、`initHive()` と `main.dart` は変更していない
2. `resolvePersistenceState` の `hiveInitialized` 引数を削除。初期化失敗は
   「開いている box が無い」として表れるため冗長だった
3. box 名の文字列定義を `PersistedArea.boxName` に集約
4. `RecoverableFailure` の配色は `colorScheme.errorContainer` を諦め、既存の
   `AppColors.warningContainer` を使用。本アプリの3テーマは `ColorScheme` に
   `error` だけを渡しており `errorContainer` が `error` にフォールバックするため、
   2状態が同色になる（コントラストテストが検出した）

**この WP で見つけた既存不具合**:

| 内容 | 対応 |
|---|---|
| AppShell 上のバナー文字にデバッグ用の下線が出る（オフラインバナーも同じ。実測 `TextDecoration.underline`） | **直した**。両バナーを `Material` で包み、AppShell 経由の回帰テストを恒久化 |
| 警告バナー表示時、タブレット横持ち 1024x768 で文字盤にスクロールが発生（オフラインバナーは実測35px、永続化バナーは6px） | **直していない**。台帳 Issue #85 へ送った |

**残った懸念**: 変更ファイル数が 12 でちょうど上限。行数は test を含めると 400 を超える。


**なぜ最初か:** 「保存できたように見えて消える」は、この製品の利用者にとって
最悪の事象（B-2）。かつ WP2 のお気に入り移行が「保存されている前提」で動くため、
先に保存の成否を観測できる形にしておく必要がある。

### 状態の定義（このフェーズで決める設計）

ADR-005 は3状態の名前だけを決め、境界は Phase 3 に委ねている。box のオープン結果から
機械的に導ける形にする。

| 状態 | 条件 | 利用者に起きること |
|---|---|---|
| `Ready` | history / presetPhrases / favorites の**全 box** がオープン成功 | 何も表示しない（高さ0） |
| `RecoverableFailure` | **一部**の box だけ失敗 | 失敗した機能だけ保存されない。バナーで対象を伝える |
| `Unavailable` | **全 box** 失敗、または `Hive.initFlutter()` 自体が失敗 | 何も保存されない。バナーで伝える |

「復旧可能（Recoverable）」の語義は **次回起動で直りうる**という意味。`openBoxWithRecovery` は
非破損エラー（ディスクフル・権限）では box を削除せず null を返すため、原因が解消すれば
次回オープンは成功する。破損エラーでは削除・再オープンを試みるので、そこで成功すれば `Ready`。

### Task 1.1: `PersistenceState` の型と導出

**Files:**
- Create: `lib/core/persistence/persistence_state.dart`
- Test: `test/core/persistence/persistence_state_test.dart`

**Interfaces:**
- Produces:
  - `sealed class PersistenceState`
  - `final class PersistenceReady extends PersistenceState`
  - `final class PersistenceRecoverableFailure extends PersistenceState { final Set<PersistedArea> failedAreas; }`
  - `final class PersistenceUnavailable extends PersistenceState`
  - `enum PersistedArea { history, presetPhrases, favorites }`
  - `PersistenceState resolvePersistenceState({required Set<PersistedArea> openedAreas, required bool hiveInitialized})`

- [x] **Step 1: 失敗するテストを書く**

```dart
// test/core/persistence/persistence_state_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/persistence/persistence_state.dart';

void main() {
  group('resolvePersistenceState', () {
    test('全areaがオープン済みならReady', () {
      final state = resolvePersistenceState(
        openedAreas: PersistedArea.values.toSet(),
        hiveInitialized: true,
      );
      expect(state, isA<PersistenceReady>());
    });

    test('一部areaだけ失敗ならRecoverableFailureで、失敗したareaを保持する', () {
      final state = resolvePersistenceState(
        openedAreas: {PersistedArea.history},
        hiveInitialized: true,
      );
      expect(state, isA<PersistenceRecoverableFailure>());
      expect(
        (state as PersistenceRecoverableFailure).failedAreas,
        containsAll(<PersistedArea>[
          PersistedArea.presetPhrases,
          PersistedArea.favorites,
        ]),
      );
    });

    test('全area失敗ならUnavailable', () {
      final state = resolvePersistenceState(
        openedAreas: const {},
        hiveInitialized: true,
      );
      expect(state, isA<PersistenceUnavailable>());
    });

    test('Hive初期化自体が失敗していればopenedAreasに関わらずUnavailable', () {
      final state = resolvePersistenceState(
        openedAreas: PersistedArea.values.toSet(),
        hiveInitialized: false,
      );
      expect(state, isA<PersistenceUnavailable>());
    });
  });
}
```

- [x] **Step 2: 赤を確認する**

Run: `flutter test test/core/persistence/persistence_state_test.dart`
Expected: FAIL（`persistence_state.dart` が存在しないというコンパイルエラー）

- [x] **Step 3: 最小実装を書く**

```dart
// lib/core/persistence/persistence_state.dart
/// 永続化（Hive）が利用できているかを表す状態。
///
/// ADR-005: 保存されない状態を型で表し、利用者に伝えて継続する。
/// 起動はブロックしない（NFR-301: ストレージ障害でも文字盤・TTS は使える）。
library;

/// 永続化の対象領域。Hive box に1対1で対応する。
enum PersistedArea {
  /// 発話履歴（box: history）
  history,

  /// 定型文（box: presetPhrases）
  presetPhrases,

  /// お気に入り（box: favorites）
  favorites,
}

/// 永続化の状態。
sealed class PersistenceState {
  const PersistenceState();
}

/// すべての領域が保存できる。
final class PersistenceReady extends PersistenceState {
  const PersistenceReady();
}

/// 一部の領域だけ保存できない。原因が解消すれば次回起動で復旧しうる。
final class PersistenceRecoverableFailure extends PersistenceState {
  /// 保存できない領域。空にはならない。
  final Set<PersistedArea> failedAreas;

  const PersistenceRecoverableFailure(this.failedAreas);
}

/// 何も保存できない。
final class PersistenceUnavailable extends PersistenceState {
  const PersistenceUnavailable();
}

/// box のオープン結果から状態を導く。
///
/// [openedAreas] はオープンに成功した領域。[hiveInitialized] は
/// `Hive.initFlutter()` 自体が成功したか。
PersistenceState resolvePersistenceState({
  required Set<PersistedArea> openedAreas,
  required bool hiveInitialized,
}) {
  if (!hiveInitialized) return const PersistenceUnavailable();

  final failed = PersistedArea.values.toSet().difference(openedAreas);
  if (failed.isEmpty) return const PersistenceReady();
  if (failed.length == PersistedArea.values.length) {
    return const PersistenceUnavailable();
  }
  return PersistenceRecoverableFailure(failed);
}
```

- [x] **Step 4: 緑を確認する**

Run: `flutter test test/core/persistence/persistence_state_test.dart`
Expected: PASS（4件）

- [x] **Step 5: コミット**

```bash
git add frontend/kotonoha_app/lib/core/persistence/persistence_state.dart \
        frontend/kotonoha_app/test/core/persistence/persistence_state_test.dart
git commit -m "feat: 永続化の状態を型で表す (Phase 3 / WP-1)"
```

### Task 1.2: `initHive()` が per-box の成否を返す

**Files:**
- Modify: `lib/core/utils/hive_init.dart`（`initHive` の戻り値）
- Modify: `lib/main.dart`
- Create: `lib/core/persistence/persistence_state_provider.dart`
- Test: `test/core/utils/hive_init_result_test.dart`

**Interfaces:**
- Consumes: Task 1.1 の `PersistedArea` / `PersistenceState` / `resolvePersistenceState`
- Produces:
  - `Future<Set<PersistedArea>> initHive()` — オープンに成功した領域を返す（従来は `void`）
  - `final persistenceStateProvider = Provider<PersistenceState>((ref) => throw UnimplementedError())`
    — `main.dart` が `overrideWithValue` で注入する。**テストは override して状態を注入する**

- [x] **Step 1: 失敗するテストを書く**

`initHive()` は Hive の実初期化を伴うため、検証は「戻り値の型と内容」ではなく
**実際に box を開けた状態での戻り値**で行う。`hive_test` は使わず、`Hive.init` に
一時ディレクトリを渡す既存テスト（`test/core/utils/hive_init_corruption_test.dart`）と
同じ形にする。

```dart
// test/core/utils/hive_init_result_test.dart
// 正常系: 3つのareaすべてが返る
// 破損系: 事前に壊したboxが除かれて返る
```

（実際のテスト本文は着手時に既存 `hive_init_corruption_test.dart` の初期化手順へ合わせる。
**このタスクの実装前に、その手順を読んでから書くこと。**）

- [x] **Step 2: 赤を確認する** — Run: `flutter test test/core/utils/hive_init_result_test.dart`
- [ ] **Step 3: `initHive()` を `Future<Set<PersistedArea>>` に変える**
- [ ] **Step 4: `main.dart` で結果を `persistenceStateProvider` に注入する**

```dart
// lib/main.dart（該当部のみ）
  Set<PersistedArea> openedAreas = const {};
  var hiveInitialized = false;
  try {
    openedAreas = await initHive();
    hiveInitialized = true;
  } catch (error, stackTrace) {
    debugPrint('[main] Hive初期化に失敗しました。インメモリ動作で起動を継続します: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  runApp(
    ProviderScope(
      overrides: [
        persistenceStateProvider.overrideWithValue(
          resolvePersistenceState(
            openedAreas: openedAreas,
            hiveInitialized: hiveInitialized,
          ),
        ),
      ],
      child: const KotonohaApp(),
    ),
  );
```

- [ ] **Step 5: 全テストを走らせる** — Run: `flutter test`。
      Expected: 1,943 passed のまま（既存テストは `persistenceStateProvider` を読まない）
- [ ] **Step 6: コミット** — `feat: Hive初期化の結果を永続化状態へ配線する (Phase 3 / WP-1)`

### Task 1.3: 常設バナーを描画して配線する

**Files:**
- Create: `lib/core/widgets/persistence_banner.dart`
- Modify: `lib/core/widgets/app_shell.dart:194-201`（`screenContent` の `Column`）
- Test: `test/core/widgets/persistence_banner_test.dart`

**Interfaces:**
- Consumes: `persistenceStateProvider`、`PersistenceState` の3サブクラス
- Produces: `class PersistenceBanner extends ConsumerWidget`

**文言（決定済み）:**

| 状態 | 文言 |
|---|---|
| `Ready` | （表示しない） |
| `RecoverableFailure` | 「一部の内容を保存できません。アプリを閉じると消えます」＋対象領域 |
| `Unavailable` | 「保存できません。アプリを閉じると入力内容は消えます」 |

`OfflineBanner` に合わせて `Semantics(label:)` を付ける。
コントラストは高コントラストテーマでも 4.5:1 以上（WCAG 2.1 AA）を満たす色にする。

- [x] **Step 1: 失敗するテストを書く**（描画されたウィジェットで検証する）

```dart
// test/core/widgets/persistence_banner_test.dart
// - Ready: バナーのテキストが1つも出ない（find.byType(PersistenceBanner) はあるが高さ0）
// - Unavailable: 「保存できません」を含むテキストが出る
// - RecoverableFailure: 失敗した領域の名前が出る
// アサーションは textContaining で行い、完全一致にしない
```

- [x] **Step 2: 赤を確認する** — Run: `flutter test test/core/widgets/persistence_banner_test.dart`
- [ ] **Step 3: `PersistenceBanner` を実装する**
- [x] **Step 4: 緑を確認する**
- [ ] **Step 5: `AppShell` の `screenContent` に配線する**

```dart
    final screenContent = OnlineRecoveryNotification(
      child: Column(
        children: [
          const PersistenceBanner(),
          const OfflineBanner(),
          Expanded(child: widget.child),
        ],
      ),
    );
```

- [ ] **Step 6: 全テストを走らせる** — Run: `flutter test`。
      **既存の AppShell テストが `persistenceStateProvider` 未 override で落ちるはず。**
      落ちたら、テスト側の `ProviderScope` に `PersistenceReady` の override を足す
      （プロダクションの既定値を追加してはならない——未注入は設定漏れとして落ちるべき）
- [ ] **Step 7: コミット** — `feat: 保存できない状態を常設バナーで伝える (Phase 3 / WP-1)`

### Task 1.4: 失敗を注入して「利用者に伝わるか」を検証する

**Files:**
- Test: `test/core/persistence/persistence_failure_notification_test.dart`

これは B-3（過去に起きた欠陥の形）の「永続化の失敗 → 利用者への通知」に当たる。
`AppShell` ごと描画し、`persistenceStateProvider` に `Unavailable` を注入して
**バナーが実際に描画されること**を検証する。層を飛ばして `PersistenceBanner` 単体だけを
叩くテストは、このタスクの合格条件にしない（配線が外れても緑のままになるため）。

- [ ] **Step 1〜5**: 赤 → 実装（配線のみ）→ 緑 → 全テスト → コミット

### WP1 の完了条件 — 判定結果

- [x] `flutter test` が緑（1,974 passed / 1 skipped、exit 0）
- [x] `flutter analyze lib` が警告0
- [x] **実物で確認した**: `flutter run -d web-server` を Playwright の Chromium で開き、
      正常起動でバナーが出ないこと・`initHive` が失敗する状態でバナーが出て
      文字盤は使えること（NFR-301）を目視した。**バナー文字の下線はこの目視でしか
      見つからなかった**——ウィジェットテストは Scaffold の中に置いて描いていたため
      Material 祖先ができ、不具合を再現していなかった
- [~] 差分は 12ファイル（上限ちょうど）／755行（test 434行を含む。lib のみなら321行）

---

## WP2 — お気に入りを1つの真実にする

**着手前に読むこと:** ADR-005 の「決定理由」節。案2（`HistoryItem.isFavorite` に一本化）を
却下した理由は「概念の所有者とライフサイクル」であって、現状の欠陥ではない。

### 現状（2026-08-30 実測）

| 箇所 | 実態 |
|---|---|
| `HistoryItem.isFavorite`（Hive field 4） | `history_provider.dart:91` が常に `false` で書く。UI は読まない |
| `PresetPhrase.isFavorite`（Hive field 3） | 永続化され、`phrase_list_widget.dart:71-77` と `phrase_list_item.dart:99` が読む。`preset_phrase_notifier.toggleFavorite` が `favoriteNotifier` と双方向同期 |
| `features/favorite/` | ロジック（`FavoriteNotifier`）。**これが正** |
| `features/favorites/` | UI（`favorites_screen.dart`） |
| `history_screen.dart:66-67,116,223` | **content 文字列**で照合している（ADR-005 は id と決めた） |
| `FavoriteItem.sourceType/sourceId`（field 4,5） | 型はあるが `saveFromHistory`/`saveFromPreset` が設定していない |
| `input_candidate_scorer.dart:85` | お気に入り判定を content で行っている |

- [ ] **Task 2.1**: `FavoriteItem` の `sourceType`/`sourceId` を生成時に必ず設定する（往復テストつき）
- [ ] **Task 2.2**: `history_screen` の content 照合を **sourceId 照合**に変える
- [ ] **Task 2.3**: `input_candidate_scorer` の content 照合を id 照合に変える
- [ ] **Task 2.4**: `PresetPhrase.isFavorite` を削除。UI は `favoriteProvider` を読む。
      `toggleFavorite` は `favoriteProvider` へ委譲し、双方向同期を消す
- [ ] **Task 2.5**: `HistoryItem.isFavorite` を削除
- [ ] **Task 2.6**: 一度きりの移行（`lib/core/persistence/favorite_migration.dart`）——
      既存 box に `isFavorite == true` の `PresetPhrase` があれば `FavoriteItem` を生成する。
      **未リリースだが開発・検証端末にデータがあるため、捨てずに移す**
- [ ] **Task 2.7**: 往復テスト（`Favorite` domain → `FavoriteItem` storage → domain が恒等）

**adapter の後方互換について（確認済み）:** 手書き TypeAdapter は
`readByte()` した field 番号を map に入れてから読むため、`fields[3]` を参照しなくなっても
既存バイト列は読める。書き込み側の `writeByte(N)` の N（フィールド数）を減らすこと。

---

## WP3 — 往復テストを feature ごとに1本

UI → provider → repository → storage → 戻り。層を飛ばして下だけを叩くテストは
単体では合格にしない。対象: history / preset_phrase / favorite / settings。

---

## WP4 — E2E を書き直す

**前提（Phase 0 で確定済み）**: 実ブラウザで入力バッファは埋まる。Issue #84 は
分岐2「環境／テストの問題」であり P0 のアプリ不具合ではない。

残す4本に絞る。

| 残す | 現況 |
|---|---|
| `app_startup_test.dart` | CI で緑 |
| `character_input_tts_test.dart` | CI 一時除外 → 直す |
| `preset_phrase_test.dart` | CI 一時除外 → 直す |
| `large_emergency_buttons_test.dart` | CI 一時除外 → 直す |

| 外す | 行き先 |
|---|---|
| `settings_accessibility_e2e_test.dart` | Widget テスト（`test/accessibility/` に9本ある）へ |
| `history_favorite_test.dart` | WP3 の往復テストへ吸収（E2E から外す） |
| `ai_conversion_e2e_test.dart` | Phase 2 後にモックプロバイダ相手で復活 |
| `performance_profiling_e2e_test.dart` | nightly の定期ジョブへ |

`.github/workflows/flutter.yml` の `EXCLUDED` を書き換え、Issue #84 を閉じる。

---

## WP5 — この Phase で入れる検査

- [ ] **Hive スキーマ許可リスト**: `typeId` と永続フィールドを許可リストに固定し、
      増えたら CI で落とす。**ADR-008 の教訓を守ること**——AST を自作せず、
      `flutter test` から走る Dart のテストとして書く（機械が権威の出力を消費する形）
- [ ] **Dart analyzer ルール**: トップレベル可変変数の禁止ほかを `analysis_options.yaml` へ

---

## WP6 — OpenSpec の baseline 書き取り

- [ ] `openspec/specs/` に「お気に入り」「永続化の状態」の2 capability を書く
      （**baseline の書き取りであり propose→apply の対象外**。§5 条件2）
- [ ] `openspec/config.yaml` の `context:` に ADR 8本の要約を書く

---

## フェーズ末にやること（§5 条件4）

- [ ] SDD の ledger の ruling / parked / deferred を **台帳 Issue #85 へ転記**する
      （ledger は完了時に消える。判断を状態を持たない場所に置かない）
- [ ] 決定に触れる ruling は ADR へ昇格する
- [ ] マージ前の最終 whole-branch レビューを **2系統**（Claude ＋ Codex）で行う（§5 条件3）
- [ ] この計画文書を破棄し、`docs/plans/2026-08-29-architecture-remediation.md` の
      状態行を更新する
