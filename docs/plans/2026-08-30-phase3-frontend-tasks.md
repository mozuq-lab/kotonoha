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
| **WP2 お気に入りを1つの真実にする** | **完了**（5段。`feature/wp2-favorite-single-truth`。移行の段は撤回） |
| WP3 往復テスト | **ADR-007 のリリース条件に入っていない** |
| WP4 E2E | **完了**（4経路が CI 緑。Issue #84 / PR #87） |
| WP5 Hive 許可リスト＋analyzer ルール | 未着手。**1d はリリース条件** |
| WP6 OpenSpec baseline | **ADR-007 のリリース条件に入っていない** |
| 文書削減の試行（呼び出し側/実装側の分離） | **方法は検証できた。仮説（減らせば振る舞いが変わるか）は未検証**（下記） |

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
- **台帳 L-31（2026-08-30 追加）**: 永続化まわりのテストは
  **本番の `initHive()` を通っていない**（`hive_init_test.dart` は `initHive()` を呼ばず、
  中身を再現している）。本番の登録経路を通るのは E2E 1本だけ
- **L-32 は決定済み（2026-08-30）**: `persistence_truth_invariant_test.dart`（236行）は
  **削除した**。守っていたのは「実行中に Hive の open set が変わらない」で、
  変える経路は無い＝ P2。**P2 を守るために自作の検出器を持つのは規約違反**
  （「検出器の穴は守る対象の到達可能性を継承する」「自作の検出器は選択肢に入れない」）。
  受け入れたリスクは台帳 L-36

---

## 【完了】文書を減らす — 呼び出し側/実装側の分離の試行（2026-08-30）

**結果: 方法は機能した。ただし動機だった仮説は検証できていない。**

| 問い | 結果 |
|---|---|
| 呼び出し側/実装側を分ける方法は機能するか | **検証できた（成功）** |
| **文書を減らせば、私の振る舞いは変わるか** | **検証できていない** |

削減は `docs/verification-principles.md` 469 → 438行（−31）。従うべき文書の合計は
**3,552行**（`AGENTS.md` / `verification-principles.md` / `CONTRIBUTING.md` /
`docs/plans/*.md` / `docs/adr/*.md`。2026-08-30 実測）なので、**0.9% しか減っていない。**
出発点は「分量が大きすぎて全部に注意を払えない」だったから、この量では仮説を動かせない。
**しかも同じ作業で台帳（Issue #85）が5件増えた（L-31〜L-35）。減らす試行が別の場所に積んだ。**
「予想どおり小さい」で通してはいけない。

### 何をしたか

6節それぞれに「実行可能な検査に変換する権威は何か」を問い、**4件を削除、6件を保持**した。
役割は計画どおり分けた——仕分けと検証は呼び出し側、テストと文書編集はサブエージェント。
**検証は委譲していない。**

| 節 | 判定 | 権威 |
|---|---|---|
| 許可集合を書き下さない（8周の直接原因） | 削除 | `limits.storage.SCHEMES` |
| `SecretStr` の `==` が静かに False | 前半を削除 | pydantic `ValidationError` |
| `urlparse` は percent-decode しない | 削除 | `sqlalchemy.engine.make_url` |
| 正しい境界で検証する（上と内容が重複していた） | 削除 | 同上 |
| 観測面を増やしたら流す経路も用意する | 残す | 無し |
| 差分の面積を完了条件に入れる | 残す（機械化を**棄却**。台帳 L-33） | — |
| `testWidgets` × 実 Hive | 残す | 無し（不変条件ではなく技法） |
| `registerAdapter` の型引数 | 残す | 構造で解決済みだが**赤を実測できず** |
| 例外連鎖 / 漏えいシンク | 残す | 無し |

削除した4件は、破ったときに赤になるテストを先に用意し、**実装側とは違う壊し方で
mutation を当てて歯を確認**した（フェイルオープン化／検査の削除／復号後の再エンコード）。

### 判定基準に対する結果

| 観点 | 結果 |
|---|---|
| 呼び出し側が差分を保持せずに済んだか | **概ね成功。** テストの差分187行は読んでいない。ただし mutation を書くために本番コードと `conftest.py` の該当関数は読んだ |
| 問いが閉じていたか | **成功。** 調査1回・実装1回。どちらも2周目に入らなかった（廃棄条件に触れず） |
| **検証が効いたか（最重要）** | **成功。** 3件とも別の壊し方で赤を出せた。歯の無いテストは無かったが、`registerAdapter` は**赤を見せられないことを理由に削除を止めた**——基準が働いた |

### この方法について分かったこと

- **委譲できるのは「権威を探す」ところまで。**「権威が無い」は正しい成果であり、
  サブエージェントに出させてよい。今回6節中4節がそれだった
- **検証を手元に置いたことで、自分の検証手順の欠陥を見つけた。**
  `flutter drive ... | tail` と書いてパイプラインの終了コード（＝`tail` のもの）を読み、
  「E2E が緑」と誤読した。この文書自身が「プロセスの外側で検証する」と書いている、
  その外側の観測点を私が壊していた。**報告を読むだけなら気づけない**
- **サブエージェントの報告に不正確な記述が1件あった**（「`ruff check` 緑」→ 実際は
  `alembic/` に既存4件）。変更ファイルに限れば緑で差し戻しは不要だったが、
  **報告の粒度は実測と一致しない**

**今後この形を使う条件**: 仕分け（何を何から導くか）が**先に1枚で決まっていること**。
決まっていない作業に適用すると、閉じた問いを投げられない。

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
`lib/features/input_candidates/domain/input_candidate_scorer.dart`
（**`favorite_migration.dart` は作らない。移行の段は撤回した。下記 §WP2**）

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
最悪の事象（B-2）。保存の成否を観測できる形にしておく必要がある。
（当初は「WP2 の移行が保存されている前提で動くため」とも書いていたが、
その移行は撤回した。)

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

### 実測でわかったこと（2026-08-30。着手前の分解をこれで書き換えた）

**1. 死蔵が5点ある。ADR-005 が「限界（正直な穴）」と書いた形が実在した。**

| 死蔵 | 場所 | 根拠 |
|---|---|---|
| `FavoriteRepository.saveFromHistory` | `favorite_repository.dart:127` | lib からの呼び出し元ゼロ |
| `FavoriteRepository.saveFromPreset` | `:144` | 同上 |
| `FavoriteRepository.isDuplicate` | `:161` | 同上（`history_screen.dart:222` の `isDuplicate` は同名のローカル変数） |
| `Favorite.fromJson` | `favorite.dart:49` | 消費者ゼロ。同期は MVP 範囲外 |
| `Favorite.toJson` | `:63` | 同上 |

**2. お気に入りを実際に作る経路は2つだけ**——`FavoriteNotifier.addFavorite`（`favorite_provider.dart:99`。
**source を設定しない**）と `addFavoriteFromPresetPhrase`（`:249`。設定する）。
したがって `sourceType == 'history'` の `FavoriteItem` は**どの経路からも生成されない**。

**3. `Favorite`（domain）と `FavoriteItem`（Hive）は重複ではない。**
`favorite_provider.dart:77,87` が変換する意図した seam で、`repository_providers.dart:11-14`
が「Box は外部 SDK の境界」と明示している。統合対象ではない。

### 決定（2026-08-30、人の判断）

**UI の射影は content でよい。真実が `favoriteProvider` に1つであることが ADR-005 の要点で、
その真実をどう射影するかは用途ごとに決めてよい。**（フェーズ末に ADR-005 へ昇格する）

- **履歴画面の星は content 照合のまま残す。** sourceId 照合にすると、定型文由来の同文に
  星が付かない／同じ文言を再発話すると付かない／履歴50件上限でアンカーが消えると
  二度と付かない。ADR-005 が名指しした衝突は「同文の**定型文どうし**」で、
  それは `addFavoriteFromPresetPhrase` の sourceId 重複判定で既に解決済み
- **`input_candidate_scorer` は触らない。**`computeCandidates` は `List<String>` しか受けず、
  集計は候補テキストがキー、出力は `InputCandidate(text:, score:)` で、**id を持てる場所が
  型の上に無い**。呼び出し元は `favoriteProvider` を watch した射影であり並行真実ではない

### 分解（6段。各段が単独でマージ可能で、途中でもアプリは壊れない）

**移行（旧 Stage 2）は捨てた（2026-08-30、人の判断）。** 守る価値のあるデータが検証端末に
無いため。実装してレビューまで通したが revert した（`f761afcf`）。理由は2つ。

1. **移行を残すと、お気に入り画面から削除したものが再起動で復活する。**
   `favorites_screen.dart:277`/`:301` → `deleteFavorite`/`clearAllFavorites` は
   `FavoriteItem` を消すだけで `PresetPhrase.isFavorite` を落とさない。移行はそれを見て
   作り直す。「すべて削除」の直後の再起動では全件戻る。**UI から到達可能**
2. **移行は `p.isFavorite` を読むので、そのフィールドを消す Stage 3b と同じビルドに
   存在できない。** つまり移行が価値を持つのは「3b を含まないビルド」で走ったときだけで、
   その期間こそ 1 の回帰が生きる期間だった。残すなら2ビルドに分け、その間に検証端末で
   1回起動する工程が要る

**したがって順序の拘束は無くなり、残る4段は順序自由・同一ビルドでよい。**
`PresetPhrase.isFavorite` だけが真実だったお気に入りは Stage 3b で失われるが、
`addFavoriteFromPresetPhrase` 経由で `FavoriteItem` になっているものは残る。

- [x] **Stage 0**: 死蔵5点を削除。あわせて test の `isFavorite: false` 62箇所を落とす
      （名前付き引数のデフォルトと同値なので挙動不変。6ファイルがこれで対象外になる）。
      **fixture 編集は別コミットに割る**
- [x] **Stage 1**: `addFavoriteFromHistory(content, historyId)` を新設し、`history_screen` から
      id を通す。**星と重複判定は content のまま**。ADR-005 要件3をここで満たす
- [x] **Stage 3a**: 定型文 UI を `favoriteProvider` から描く。`phrase_list_widget` /
      `phrase_list_item` / `phrase_category_section` に `Set<String> favoritePresetIds` を渡す
      （3つとも `StatelessWidget`）。**モデルはまだ触らない**
- [x] **Stage 3b**: `PresetPhrase.isFavorite` を削除。**14ファイルで完了条件の12を超える。
      超過は承認済み**（fixture 修正はフラグ削除と同時でないとコンパイルが通らず、分割できない。
      台帳 L-38）。**`toggleFavorite` の `favoriteProvider` への委譲と `_sortPhrases` の
      移設もここ**（実行前 ruling）
- [x] **Stage 4**: `HistoryItem.isFavorite` を削除。**移行不要**——`history_provider.dart:91` が
      常に `false` を書き、UI は読まない（`history_item_card` の `isFavorited` は別名の
      ウィジェット引数）。**保存値が全て false なので失われる情報がゼロ。順序自由**。
      **`FavoriteNotifier.addFavorite` の削除は撤回し、台帳へ送った**——UI から到達
      できない（＝P2）ので「P2 は一切触らない」の規約に従う。削除にはテスト34箇所の
      書き換えが要ると実測した

### adapter の後方互換（実測で確認済み）

read 側は**位置固定ではなく、フィールド番号をキーにした map 方式**——先頭の
`readByte()` した数だけ `reader.readByte(): reader.read()` を読む。`reader.read()` は
引数なしなので hive が値の型を先頭バイトから自己記述的に決める。したがって
**削除したフィールドの値も正しくバイト数分だけ消費され、ストリームはずれない。**
`writeByte(N)` の N を減らすだけでよい（`preset_phrase_adapter.dart:44` 7→6、
`history_item_adapter.dart:40` 5→4）。

> **最も危険な一手: 残るフィールドの番号を詰め直してはいけない。**
> `PresetPhrase` の `isFavorite` は**中間の field 3** で、後ろに displayOrder(4)・
> createdAt(5)・updatedAt(6) が続く。4,5,6 → 3,4,5 と詰めると旧バイト列で
> `fields[3] as int` が `TypeError` を投げる。`hive_init.dart:48` の `_isCorruptionError` は
> `FormatException` と `RangeError` しか破損とみなさないため、`:108-119` の「環境起因」に
> 落ちて **box を開けないまま null を返す**——**定型文が全消えしたように見え、
> 無言でインメモリ動作を続ける。**

### 追加が要るテスト

- **旧7フィールドのバイト列を新アダプタで読む**テスト（Stage 3b）。map 方式の後方互換は
  現状どのテストも守っていない
- 往復テスト（`Favorite` domain → `FavoriteItem` storage → domain が恒等）

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
      （**確定分: WP2 の「UI の射影は content でよい。真実が favoriteProvider に1つで
      あることが要点」を ADR-005 へ**）
- [ ] マージ前の最終 whole-branch レビューを **2系統**（Claude ＋ Codex）で行う（§5 条件3）
- [ ] この計画文書を破棄し、`docs/plans/2026-08-29-architecture-remediation.md` の
      状態行を更新する
