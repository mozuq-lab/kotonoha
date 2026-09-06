# Phase 5 — 文書の作り直しとコード整理: 設計と実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**破棄条件**: Task 8（閉じる PR）のマージで削除する。Part A の決定は ADR-010 と核（`AGENTS.md`）に残し、
作業の記録は各 PR の本文に残す。

作成: 2026-09-06 ／ 親計画: `docs/plans/2026-08-29-architecture-remediation.md` §5 Phase 5 ／
設計の入力: `docs/plans/2026-09-05-docs-framework-and-inventory.md` Part A（A1〜A5）、PR #108 本文、`docs/ledger.md` ／
決定の経緯: 2026-09-06 のセッション（設計 5 節を利用者が順に承認。A1 の表が決定と却下案）／
レビュー: 2026-09-06 に 2 系統（設計・工程／現物精度）のサブエージェントで実施し、P0 5 件・P1 23 件を反映済み

**Goal:** 文書を「読者ごとに正本 1 つ」に作り直し（核 120 行・未卒業 ADR 5 本・正本・倉庫）、コードから生成時の記法と記号を剥がす。

**Architecture:** 決定 → 正本 → 核 → コード の順に PR を積む。核（`AGENTS.md`）は入力（ADR 索引と卒業判定）が固まってから白紙で書く。
コード整理（Task 7）は記法を剥がすだけで本文を残し、Task 1〜5 と並行するが、**Task 6 と同じテストファイルの隣接行を触るので Task 6 より先にマージする**。
完了の判定は `scripts/inventory.sh` と `find` の出力で機械的に行う。

**Tech Stack:** bash / git / gh CLI ／ perl（コード整理の使い捨てスクリプト）／ `dart format`・`flutter analyze`・`flutter test`（fvm 経由）／
`scripts/inventory.sh`・`scripts/adr-touch.sh`（既存。変更しない）

**Spec:** Part A（この文書内）

## Global Constraints

- **新しい検査（止める仕組み）を作らない**（ADR-008）。数える・貼る・移す・書き直すだけ。既存スクリプト 2 本も変更しない
- **上限**: 核 `AGENTS.md` 120 行以内／ADR 各 60 行以内／未卒業 ADR 5 本以下（ADR-010 を含む）。**行数は物理行で数える。核と ADR は 1 項目 1 行で書き、幅で折り返さない**（折り返すと同じ内容で 130〜150 行になる）
- **1 タスク 1 PR**。差分は 400 行 / 12 ファイルまで（削除と `git mv` は数えない）。**Task 0（計画書 1,000 行超）・Task 5（移動 25 本超）・Task 7（286 ファイル）は性質上超える。この計画で超過を承認済み**（2026-09-06、利用者。L-38 の前例と同じく人の判断）
- **作業は worktree**（`superpowers:using-git-worktrees`。`.claude/worktrees/phase5`）。**積み PR**（各 base は前の PR のブランチ。Task 7 だけ main を base）。マージは利用者
- **例外・許可リストを持たない**。除外規則を 1 つ足したら ADR-008 の再演
- **逆生成しない。tsumiki を有効に戻さない**（2026-09-06 決定）。仕様と実装の突き合わせは手作業
- **倉庫（`docs/archive/`）へ移す文書は内容を変えない**（`git mv` だけ。卒業 ADR の先頭 2 行だけが例外）。倉庫の README に移動一覧を足さない（履歴は git）。ただし倉庫の README は倉庫の入口なので、「現行の文書はどこか」の表は Task 8 で正本へ付け替える
- **書く数字・パス・行数は、書く直前に現物で確かめる**（規律 3）。この計画の数字は 2026-09-06 の実測であり、着手時に測り直す
- **ADR の書き直しで却下案を落とさない。** 却下案の無い決定は ADR ではない（A3 の作成条件）
- **PR 本文に、索引の未卒業行それぞれへの yes/no を書く**（層 3）。コードに触れない PR は全行 no でよいが、書くこと自体が工程
- コミットメッセージは既存に倣う（docs / refactor / chore などの接頭辞 ＋ 日本語 1 行）。末尾に `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`
- **完了と言う前に実物で確かめる**: `wc -l`、`scripts/inventory.sh`、`scripts/adr-touch.sh`、`find`、`flutter analyze` / `flutter test`、README に書いたコマンドは実行する
- **`grep -r` で除外するときは `git grep` の pathspec（`':!docs/archive'` など）を使う。** この環境の `grep` は関数で出力に `./` が付かず、`grep -v "^./docs/archive"` は効かない（2026-09-06 実測）
- **PR 本文のファイルはリポジトリ外に置く**（例: `/tmp/phase5-body.md`）。作業ツリーに置くと `git add -A` で混入する
- ローカルの Flutter は `fvm` 経由（`fvm flutter` / `fvm dart`）。CI は 3.38.1（`.github/workflows/flutter.yml` の `FLUTTER_VERSION`）。**2026-09-06 時点でローカルは `.fvmrc` が無く global の 3.41.5 が動く。Task 4 でピン留めする**
- 核に書く道具名は `plugin:skill` の形だけを backtick で囲む。コミット接頭辞（docs など）を backtick で囲まない（`scripts/inventory.sh` が backtick 内の `a:b` を道具名として数える）

---

## Part A — 設計（2026-09-06 に承認。レビュー反映済み）

### A1. 決めたこと（Phase 4 計画書 Part A に足す決定。異論が出たらこの表を書き直す）

| # | 決定 | 却下した案 |
|---|---|---|
| 1 | 完了条件「実在しないパス参照 0 件」は**観測値**にする（L-64）。棚卸しが毎月数字を書き、壊れた参照は目視で台帳へ。ADR-010 の検査は「核 120 行以内」「未卒業 5 本以下」の 2 つ | 核の中だけ 0 件（測る範囲を変える）／0 件を維持し文章を計測器に合わせる |
| 2 | user-guide は 4 本（faq・troubleshooting・ios-guided-access・android-screen-pinning）を残す。`docs/support.md` から既に到達できる。`index.md` は support.md と同じ一覧なので倉庫へ | 5 本とも倉庫へ（OS の固定設定の手順が利用者から失われる） |
| 3 | ADR-001・003・004・006・008 の 5 本を卒業させる。検査は CI に実在する（`.github/workflows/python.yml`: mypy・lint-imports・`backend/scripts/gates.sh`・pytest の `test_sinks.py`／`test_startup.py`／`test_config.py`）。008 は却下の記録として卒業し、守る規律を核に 1 行残す（ADR-010 の卒業条件の 3 つ目） | 008 を未卒業のまま残す（上限 5 本を超える） |
| 4 | 仕様と実装の突き合わせは手作業。入力は台帳の既知 5 件（L-04・08・43・53・72）と L-68 の 14 件。正本 1 本（要件定義）だけを突き合わせる | tsumiki を Phase 5 だけ有効に戻し `rev-*` を scratch へ出す（対象の design/ は倉庫行きで、逆生成する価値が無い） |
| 5 | `docs/verification-principles.md` は「実例 2 件」の規律 **3 本**（観測点を疑う／自分の文書を事実扱いしない／検査を自作する前に構造で表現不可能にできないかを問う）を核へ移し、本体は倉庫へ。§3 の技術的事実 5 件は、それを守るテストの近くに 1〜2 行のコメントとして残す | 現行のまま残す（A1 の 5 種類に無い 6 種類目になる）／規律 2 本だけ移す（3 本目は ADR-008 3 周と Phase 3 WP-1 3 周の実例 2 件を持ち、ADR-008 が倉庫へ行くと生きた文書から消える） |
| 6 | コード整理は行削除ではなく**記法だけ剥がす**。`【X】:`→`X:`、`【X】`→`X`、記号は消す。lib の 385 種のラベルには生きた設計メモ（`frontend/kotonoha_app/lib/core/constants/app_sizes.dart:19` など）が混ざる。「信頼性レベル: 青信号」のような語は残る（行削除は続く行の設計メモを巻き込む） | 【】を含む行を全部消す（設計メモが消える）／「青信号」等の語を含む行も消す（`hive_box_backup.dart:2` のように次行へ続く本文を孤立させる）／lib と test で 2 PR に分ける |
| 7 | 進め方は 決定 → 正本 → 核 → コード の順で積み PR。Task 7 は Task 1〜5 と並行し、Task 6 より先に main へマージする | 核を先に書いて残りを合わせる（索引の二度書き）／ADR と正本を各 1 PR にまとめる（400 行超）／Task 7 を完全に独立させる（Task 6 と同じテストファイルの隣接行を触り、後にマージする側が手で衝突を解く） |
| 8 | 設計と実装計画は 1 本（この文書）。`docs/superpowers/specs/` は使わない。計画書は #100 と同じく単独 PR（Task 0）で入れる | 設計と計画を 2 本に分ける（工程記録が増える）／Task 1 の PR に同梱（1,000 行超で 400 行の規則を超える） |

**A5（Phase 4 計画書）から外れる点（実行可能な手順は倉庫に入れない）**:
`frontend/kotonoha_app/integration_test/device_test/README.md`（L-25 の実機 QA 手順）と `docs/store-assets-guide.md`
（ストア申請アセットの要件）は、ADR-007 条件 4 の充足前に使う手順なので残す。条件 4 の充足で倉庫へ（Task 8 で台帳に 1 行）。

**Phase 5 の対象外と明記するもの**:
- L-67（`features/favorite/` と `features/favorites/` の統合。台帳の文言は「Phase 5 で統合」だが本計画は文書フェーズなので扱わない。Task 8 で文言を「Phase 5 の後」に直す）
- L-68（要件 ID の追跡性）、L-39（ADR-005 の矛盾）、L-70（未割当 4 目的の道具）、dependabot PR 10 本
- 親計画 §5 Phase 5 の「受入基準をプロダクト仕様として引き取る」「アクセシビリティ基準をテストとして実行可能にする」は、受入基準を倉庫へ送る A2 で差し替える。アクセシビリティ基準は要件定義（正本）と既存の widget テストが担う。新しいテストは書かない
- Stop フック（`.claude/hooks/activity-value-check.sh`）の廃棄条件「発火ゼロで 1 か月」は 2026-09-30 に到達する。削除は Phase 5 の対象外で、Task 8 で台帳に 1 行送る

### A2. 文書の行き先（到達点）

| 行き先 | 文書 | Task |
|---|---|---|
| 核（白紙から 120 行） | `AGENTS.md`。`CLAUDE.md` は参照のみで不変 | 6 |
| 決定（未卒業 5 本、各 60 行） | ADR-002・005・007・009・010 | 1・2・3 |
| 倉庫 `docs/archive/adr/` | ADR-001・003・004・006・008（ファイル名不変、先頭に卒業行） | 1 |
| 開発者の正本 | `README.md`（`docs/tech-stack.md`・`docs/SETUP.md`・`CONTRIBUTING.md` の生きている部分を統合）。`frontend/kotonoha_app/.fvmrc`（3.38.1 のピン留め。README の記述を真にするための新規ファイル） | 4 |
| 仕様の正本 | `docs/spec/kotonoha-requirements.md`（記号と凡例を消し、実装と突き合わせる）。API の形は `backend/tests/contract/openapi_baseline.json`（値域は持たない。enum はコード、例: `backend/app/ai/prompts.py` の `PolitenessLevel`） | 5 |
| 利用者・審査者の正本 | `docs/privacy-policy.md`、`docs/support.md`、`docs/user-guide/{faq,troubleshooting,ios-guided-access,android-screen-pinning}.md` | 不変 |
| 台帳 | `docs/ledger.md`（核に数えない。フェーズ境界で見直す） | 5・6・8 |
| 実行可能な手順（残す） | `frontend/kotonoha_app/integration_test/device_test/README.md`、`docs/store-assets-guide.md` | 不変 |
| 倉庫 `docs/archive/` | Task 4: `docs/tech-stack.md`・`docs/SETUP.md`・`CONTRIBUTING.md`。Task 5: `docs/design/kotonoha/` 7 本・`docs/spec/kotonoha-acceptance-criteria.md`・`docs/spec/kotonoha-user-stories.md`・`docs/spec/mvp-requirements-original.md`・`docs/articles/why-redaction-fixes-dont-converge.md`・`CHANGELOG.md`・`docs/user-guide/index.md`・`openspec/specs/{favorites,persistence-state}/spec.md`・`frontend/kotonoha_app/{README,lib/core/README,lib/features/README,lib/shared/README,integration_test/README}.md`。Task 6: `docs/verification-principles.md`。Task 8: `docs/plans/2026-08-29-architecture-remediation.md` | 4・5・6・8 |
| 倉庫の入口 | `docs/archive/README.md`（「現行の文書はどこか」の表を正本へ付け替える。移動一覧は足さない） | 8 |
| 使い捨て（削除） | `docs/plans/2026-09-05-docs-framework-and-inventory.md`、この文書 | 8 |
| 使い捨て（残す） | `docs/plans/2026-09-02-remaining-work.md`（破棄条件は ADR-007 条件 4 の充足。冒頭の正本の記述と §2 の Phase 5 行を更新） | 8 |
| リポジトリ外 | `docs/context-distillation.md`（未追跡のまま。移す先は利用者が決める） | 対象外 |

### A3. 核 `AGENTS.md` の骨格（各節の上限。1 項目 1 行で折り返さない。合計 120 行以内）

| 節 | 上限 | 中身 |
|---|---|---|
| 冒頭 | 3 | 上限 120 行、超えたら足す前に降ろす。決定は `docs/adr/`、規則は ADR-010、後回しは `docs/ledger.md` |
| 製品 | 8 | 目的、利用者は訂正できずデータは端末内だけ、オフラインで全機能、数字（TTS 1 秒・タップ 100ms・AI 3 秒・44/60px・フォント 3 段階・テーマ 3 種）、MVP 外 |
| 規律（実例つき） | 30 | 9 本（本文は Task 6 の草稿） |
| 決定の索引 | 14 | 5 列表。未卒業 5 本＋卒業 5 本。列順は `scripts/adr-touch.sh` が読むので不変 |
| 文書の規則 | 7 | ADR-010 の要約。正本の一覧、使い捨ての破棄条件、台帳、倉庫は更新しない・読まない、コードが正 |
| コマンド | 16 | 起動・検査・mutmut・棚卸しの実行行だけ。説明は README |
| 道具 | 10 | 目的→道具の表。SDD の 5 条件を 1 行で。未割当 4 目的は 1 行にまとめ L-70 は開いたまま |
| 規約 | 5 | Python・Flutter の規約、コミットは既存に倣う、PR の規則 |
| 残作業 | 4 | 台帳の判断待ち、ADR-007 条件 4、是正計画は完了 |

核から出る内容の行き先: API とレート制限の説明は OpenAPI baseline と ADR-002（`TRUSTED_PROXY_COUNT` の過大設定の危険は ADR-002 の限界）。
ディレクトリ構造・技術スタック・環境変数の説明は README。5 層レビューの表とテスト 2 系統の詳細は規律 4・6・7 に圧縮。
【】と記号の注意書きは Task 7 で記法が消えるので書かない（語は残るが、それは死蔵コメントとして棚卸しの観点 1 が拾う）。

### A4. コード整理の変換規則（Task 7）

対象は `frontend/kotonoha_app/{lib,test,integration_test,test_driver}` の dart ファイルの行コメント（`//` と `///`）。
ブロックコメントに【】は 0 件、記号だけの行も 0 件、`//` より前に【や記号が現れる行（文字列リテラル）も 0 件（2026-09-06 実測）。
`analysis_options.yaml` の【】3 行（`#` コメント）は Task 6 が同ファイルを触るときに同じ規則で剥がす。

1. `【X】:` と `【X】：` は `X: ` に、残った `【X】` は `X` に置き換える（ラベル語は残す）
2. `🔵🟡🔴` はコメントから消す（前の空白ごと）
3. 1・2 の結果コメントが空になった行（`//` や `///` だけ）は消す。コードの末尾に空コメントが残った場合はコメントだけ消す（2026-09-06 の全 286 本の dry run では 1 度も発火しない。規則として置くだけ）
4. 変換後に `dart format` をかける（CI が整形を強制しており、2026-09-06 時点で 369 ファイル差分ゼロ。3.38.1 と 3.41.5 の両方で同じ）

「信頼性レベル: 青信号 - …」「凡例: - 青信号: …」の語は残る（1,469 行）。行ごと消すと `hive_box_backup.dart:2` のように次行へ続く本文を孤立させるため、剥がすだけに留める。

### A5. 完了条件（親計画 §6 Phase 5 と Phase 4 計画書 A5 を差し替える）

| 条件 | 判定手段 |
|---|---|
| 核が 120 行以内 | `wc -l AGENTS.md` |
| 未卒業 ADR が 5 本以下で各 60 行以内 | `scripts/inventory.sh` の「未卒業 ADR」と「60 行超」 |
| `docs/` 直下と `docs/spec/` に残る現行文書が A2 の正本・台帳・実行可能な手順・使い捨てだけ | `find docs -maxdepth 1 -type f` と `find docs/spec -type f` を A2 と突き合わせる |
| `docs/ledger.md` が存在し #85 が閉じている | 充足済み（2026-09-05） |
| 「実在しないパス参照」は観測値を「計測」節に記録する（0 件を要求しない） | `scripts/inventory.sh` |
| `lib`・`test`・`integration_test`・`test_driver` の dart ファイルに【と 🔵🟡🔴 が 0 件 | `git grep -lE '【|🔵|🟡|🔴' -- 'frontend/kotonoha_app/*.dart' \| wc -l` |

### A6. 進め方

worktree で作業し、1 Task 1 PR の積み PR。`superpowers:subagent-driven-development` の 5 条件（task 分解入力はこの文書・
拘束は Global Constraints・2 系統レビューはマージ境界・記録は PR 本文と台帳・OpenSpec change は使わない）。
各 PR 本文に、索引の未卒業行への yes/no と、その Task の検証コマンドの実出力を貼る。

---

## Part B — 実装計画

### File Structure（到達点）

```
docs/plans/2026-09-06-phase5-docs-rewrite.md   この文書。Task 0 で入れ、Task 8 で消す
AGENTS.md                                   白紙から 120 行（Task 6）。Task 1・2・4・5 では索引と参照だけ更新
docs/adr/ADR-010-document-framework.md      新設。60 行以内（Task 1）
docs/adr/ADR-002-*.md, ADR-005-*.md         60 行に書き直し（Task 2）
docs/adr/ADR-007-*.md, ADR-009-*.md         60 行に書き直し（Task 3）
docs/archive/adr/ADR-00{1,3,4,6,8}-*.md     卒業した本文（Task 1）
README.md                                   開発者の正本に書き直し（Task 4）
frontend/kotonoha_app/.fvmrc                3.38.1 のピン留め。.gitignore に .fvm/（Task 4）
docs/archive/{tech-stack.md,SETUP.md,CONTRIBUTING.md}            倉庫（Task 4）
docs/spec/kotonoha-requirements.md          記号除去・関連文書の付け替え・実装との突き合わせ（Task 5）
openspec/config.yaml                        context を現状に（Task 5）
.github/workflows/openspec-guard.yml        コメント文言だけ（Task 5）
docs/archive/{design,spec,articles,user-guide,openspec,frontend}/…  倉庫（Task 5）
docs/archive/verification-principles.md     倉庫（Task 6）
frontend/kotonoha_app/analysis_options.yaml 参照の付け替えと【】3 行（Task 6）
frontend/kotonoha_app/{lib,test,integration_test,test_driver}/**/*.dart   記法と記号を剥がす（Task 7）
docs/ledger.md                              [x] の付け替え（Task 5・6）、境界の見直しと計測（Task 8）
docs/archive/README.md                      「現行の文書はどこか」の表を正本へ（Task 8）
docs/plans/                                 2 本削除、親計画は docs/archive/plans/ へ、残作業索引を更新（Task 8）
```

### 実行順序

| Task | 内容 | ブランチ（base） | 検証の実物 |
|---|---|---|---|
| 0 | この計画書を PR で入れる | `docs/phase5-plan`（main） | `scripts/inventory.sh` の「破棄条件あり」に出る |
| 1 | ADR-010 新設＋5 本卒業＋索引更新 | `docs/adr-010-graduate`（Task 0） | `inventory.sh` が未卒業 5 本。`adr-touch.sh` が索引行を出す |
| 2 | ADR-002・005 を 60 行に | `docs/adr-002-005`（Task 1） | `wc -l` ≤ 60、`## ` 見出し 8 本 |
| 3 | ADR-007・009 を 60 行に | `docs/adr-007-009`（Task 2） | 同上。`inventory.sh` の「60 行超」が 0 |
| 4 | README を開発者の正本に。fvm ピン留め。3 本を倉庫へ | `docs/readme-source`（Task 3） | README のコマンドを実行して通す |
| 5 | 要件定義の突き合わせ。倉庫移動 25 本超。`config.yaml` | `docs/spec-and-archive`（Task 4） | `find` の一覧が期待と一致。記号 0 件 |
| 7 | 記法と記号を剥がす。**Task 1〜5 と並行。Task 6 の前に main へマージ** | `refactor/strip-generation-markers`（main） | grep 0 件、analyze 同数、test 全緑、非コメント差分 0 |
| 6 | `AGENTS.md` 白紙 120 行。verification-principles を倉庫へ。**Task 7 のマージ後に着手** | `docs/agents-core`（Task 5 ＋ main を merge） | `wc -l` ≤ 120。`adr-touch.sh`・`inventory.sh` の道具の実在。核だけ読んで起動できる |
| 8 | 閉じる。計画書の破棄、台帳の境界見直し、計測。**Task 0〜7 が全部 main にマージ済みで着手** | `docs/phase5-close`（main） | A5 の判定手段すべての実出力 |

---

### Task 0: 計画書を PR で入れる

**Files:**
- Create（追跡開始）: `docs/plans/2026-09-06-phase5-docs-rewrite.md`

- [ ] **Step 1: worktree とブランチを作り、計画書だけをコミットする**

`superpowers:using-git-worktrees` に従う。手動なら:

```bash
git worktree add .claude/worktrees/phase5 -b docs/phase5-plan main
cp docs/plans/2026-09-06-phase5-docs-rewrite.md .claude/worktrees/phase5/docs/plans/
cd .claude/worktrees/phase5
git add docs/plans/2026-09-06-phase5-docs-rewrite.md
git commit -m "docs: Phase 5（文書の作り直しとコード整理）の設計と実装計画を置く"
git push -u origin docs/phase5-plan
gh pr create --base main --title "docs: Phase 5 の設計と実装計画を置く" --body-file /tmp/phase5-body.md
```

- [ ] **Step 2: 検証する**

```bash
bash scripts/inventory.sh 2>/dev/null | sed -n '/使い捨て文書/,$p'   # 「条件あり: docs/plans/2026-09-06-phase5-docs-rewrite.md」
```

PR 本文: 計画書の行数超過は本計画で承認済み（#100 と同じ扱い）。yes/no は全行 no（何にも触れない）。

---

### Task 1: ADR-010 を書き、検査が CI にある ADR 5 本を卒業させる

**Files:**
- Create: `docs/adr/ADR-010-document-framework.md`（60 行以内）
- Move: `docs/adr/ADR-001-backend-stateless.md` → `docs/archive/adr/ADR-001-backend-stateless.md`。003・004・006・008 も同様（ファイル名不変）
- Modify: 移動した 5 本の先頭に卒業行 1 行＋空行
- Modify: `AGENTS.md` の索引（2026-09-06 時点で 81〜91 行目。93 行目は注記の段落）。5 行の「検査」列と ADR-010 の行の追加
- Modify: `AGENTS.md` の「改修に着手する前に」1 項（同 270〜272 行目）の「索引 9 行すべて未卒業。卒業判定は Phase 5」

- [ ] **Step 1: ブランチを切る**

```bash
cd .claude/worktrees/phase5
git checkout -b docs/adr-010-graduate docs/phase5-plan
```

- [ ] **Step 2: ADR-010 を書く**

草稿（58 行。数字は書く直前に `scripts/inventory.sh` と `wc -l` で測り直す。1 項目 1 行で折り返さない）:

```markdown
# ADR-010: 文書は 5 種類。核は 120 行、決定は 60 行・未卒業 5 本、台帳は 1 ファイル

状態: 承認済み（2026-09-05 決定、2026-09-06 ADR 化。署名: mozuq）／ 出自: Phase 4 計画書 Part A（削除済み。経緯は PR #100・#108）

## 背景と課題

失敗のたびに規約・決定・台帳・道具表が増え、一度も減らなかった。2026-09-06 の棚卸しで AGENTS.md は 390 行、ADR は 9 本（60 行超 6 本）、台帳の未対応は 24 行。
読む量が増えると規約は守られず、道具表には中身を読まずに載せた行が残り（tsumiki の 4 目的が無効のまま）、台帳は入口だけで出口が無い。
追記は「今」できるが圧縮は「後で」にできる。この非対称は引き金（「2 周低優先なら却下」等）では埋まらず、数字の上限でしか埋まらない。
却下済みの案は「読んで思い出す」では防げない（ADR-008 を読んだうえで同じものを再演した実績がある）。

## 制約

- 止める機械を作らない（ADR-008）。数字は数えるだけで、判断は人が行う
- 1 人＋エージェントの体制。参照コストが利点を上回る仕組みは持たない

## 検討した選択肢

1. 現状維持（追記を続け、必要になったら整理する）
2. 引き金型の降格規則（「N 周触られなければ却下」「古くなったら倉庫へ」）
3. **数字の上限を置き、足すときにその場で降ろすものを選ばせる。却下案は差分を索引に当てて貼る**（採用）
4. GitHub Issue を台帳にし、ラベルで状態を持つ
5. 「1 ADR に 1 ディレクトリ」を索引に書き、パスで照合する

## 決定

文書は 5 種類。**核** `AGENTS.md`（毎回読む。120 行以内）／**決定** `docs/adr/`（触る領域のときだけ読む。未卒業 5 本以下、各 60 行以内）／
**正本**（読者ごとに 1 つ。開発者は `README.md`、利用者・審査者は `docs/privacy-policy.md` と `docs/support.md`、仕様は `docs/spec/kotonoha-requirements.md`、API は `backend/tests/contract/openapi_baseline.json`。同じ内容を 2 箇所に書かない）／
**使い捨て**（`docs/plans/` と PR 本文。冒頭に破棄条件 1 行。完了 PR のマージで削除）／**倉庫**（`docs/archive/`。更新しない。現在の仕様として読まない）。
卒業＝守る検査が CI にある、後続の決定に置き換えられた、または却下の記録で守る規律が核に 1 行入った。卒業した本文は `docs/archive/adr/` へ、索引の行は残す。
台帳は `docs/ledger.md` 1 本。1 問題 1 行＋出所。状態は `[ ]` `[x]` `[-]`。フェーズ境界で `[x]` と `[-]` を消す。
ADR を作る条件は「PR の外を縛る」「却下案がある」「検査か再訪条件を書ける」の 3 つ全部。節は 8 つに固定。改訂は追記せず書き直す。
索引は核に 1 決定 1 行（卒業済みも含む）で、列は 決めたこと・却下した案・関わる行為・検査。「決めたこと」にはコードの識別子かパスを 1〜2 個入れる。
「検査」節には守る層を書く: (i) 負債を作る 7 行為に現れる → 層 2（`scripts/adr-touch.sh`）が索引行を貼る／(ii) CI の検査がある → 卒業／(iii) どちらも無い → 核の索引と月 1 の棚卸しだけ。
層 2 はパターンを発明しない（照合は AGENTS.md の 7 行為そのもの。8 つ目が要るなら先に一覧を変える）、例外を持たない、止めない。
OpenSpec は使い捨て（`openspec/specs/` を恒久にしない）。GitHub Issue は月 1 の棚卸しの引き金と外部とのやり取りだけ。

## 決定理由と却下案

- 案 1 却下: 2026-08 までの実績そのもの（AGENTS.md 390 行、Tsumiki の工程記録 299 ファイル）
- 案 2 却下: 引き金は「後で判定する」約束で、非対称の後半に置かれる。「2 周連続で低優先なら却下」は 35 項目・5 周で発火 0 だった。引き金自体が新しい文書になる
- 案 4 却下: 参照コストが利点を上回る（1 人体制）。状態を持たない場所に判断を置くと次周の入力になる
- 案 5 却下: 広いと壁紙、狭いと漏れで、正規表現の許可リストと同じ坂道（ADR-008）。見逃しの実例が 2 件出るまで採らない

## 限界

上限は「何を降ろすか」を決めない。降ろす判断は人が行い、数字は月 1 の棚卸しでしか見ない。
「実在しないパス参照」は相対表記・意図的不在・URL が混ざり 0 件に到達しないため観測値に留める（L-64、2026-09-06）。
(iii) の決定は核の索引と棚卸しでしか守れず、未卒業 5 本の枠を使い続ける。パスに現れない再提案（UI ロジックだけの 2 つ目の実装）は 3 層のどれにも当たらない。

## 検査

層 5（棚卸し）。`scripts/inventory.sh` が核の行数・未卒業 ADR の本数・60 行超・台帳の入口と出口・破棄条件の無い計画書を数える。
核 120 行と未卒業 5 本を棚卸し 2 回連続で守れたら卒業。

## 再訪条件

6 本目の ADR を書くとき、卒業・統合・撤回のどれもできない状態が 2 回続いたら上限の数字を見直す（本 ADR を書き直す）。
核が 120 行で書けない実例が 2 回出たとき。層 2 の見逃しの実例が 2 件出たとき（案 5 を再評価）。
```

- [ ] **Step 3: 5 本を倉庫へ移し、先頭に卒業行を足す**

```bash
mkdir -p docs/archive/adr
git mv docs/adr/ADR-001-backend-stateless.md          docs/archive/adr/
git mv docs/adr/ADR-003-errors-are-typed.md           docs/archive/adr/
git mv docs/adr/ADR-004-config-immutable.md           docs/archive/adr/
git mv docs/adr/ADR-006-layer-dependency-enforced.md  docs/archive/adr/
git mv docs/adr/ADR-008-debt-gate-state-comparison.md docs/archive/adr/
```

卒業行（各ファイルの先頭に引用 1 行＋空行を挿入。`printf` と `cat` で作り直す。macOS の `sed -i` は使わない）:

| ファイル | 守る検査（卒業行に書く文） |
|---|---|
| ADR-001 | `backend/scripts/gates.sh`（DB ディレクトリと依存の不在）と `backend/tests/contract/` |
| ADR-003 | `backend/scripts/gates.sh` の grep（`str(exc)` 等 0 件）、`backend/tests/test_sinks.py`（canary 全シンク）、`mypy --strict` |
| ADR-004 | `backend/tests/test_startup.py`（起動 smoke・import 副作用）、`backend/tests/test_config.py`（frozen 設定） |
| ADR-006 | `lint-imports`（`backend/pyproject.toml` の `[tool.importlinter]`、CI は `.github/workflows/python.yml`） |
| ADR-008 | 却下の記録。守るものは核の規律「検査を自作する前に構造で表現不可能にできないかを問う。同種の止める仕組みを作る前に ADR-008 を読む」 |

```bash
add_line() {  # $1 = ファイル, $2 = 検査の文
  { printf '> 卒業済み（%s）。守る検査: %s。索引は AGENTS.md。この本文は更新しない。\n\n' "$(date +%F)" "$2"; cat "$1"; } > "$1.tmp" && mv "$1.tmp" "$1"
}
add_line docs/archive/adr/ADR-001-backend-stateless.md          'backend/scripts/gates.sh（DB ディレクトリと依存の不在）と backend/tests/contract/'
add_line docs/archive/adr/ADR-003-errors-are-typed.md           'backend/scripts/gates.sh の grep、backend/tests/test_sinks.py（canary 全シンク）、mypy --strict'
add_line docs/archive/adr/ADR-004-config-immutable.md           'backend/tests/test_startup.py（起動 smoke・import 副作用）、backend/tests/test_config.py（frozen 設定）'
add_line docs/archive/adr/ADR-006-layer-dependency-enforced.md  'lint-imports（backend/pyproject.toml [tool.importlinter]、CI python.yml）'
add_line docs/archive/adr/ADR-008-debt-gate-state-comparison.md '却下の記録。守るものは核の規律「検査を自作する前に構造で表現不可能にできないかを問う。同種の止める仕組みを作る前に ADR-008 を読む」'
```

- [ ] **Step 4: `AGENTS.md` の索引を更新する**

5 行の「検査」列の先頭に `卒業（YYYY-MM-DD）: ` を付け、ADR-009 の行の下に次の行を足す（列順は変えない。`scripts/adr-touch.sh` が 4 列目を読む。並べ替えは Task 6 で行う）:

```
| ADR-010 | 文書は 5 種類。核 `AGENTS.md` は 120 行、ADR は 60 行・未卒業 5 本、台帳は `docs/ledger.md` 1 本 | GitHub Issue 台帳、引き金型の降格規則、OpenSpec の恒久化、1 ADR 1 ディレクトリの照合 | （行為に現れない。層 3 と棚卸し） | `scripts/inventory.sh` の数字（層 5） |
```

「改修に着手する前に」1 項の「2026-09 時点は索引 9 行すべて未卒業。卒業判定は Phase 5」を
「未卒業は 002・005・007・009・010 の 5 行。卒業済みの本文は `docs/archive/adr/`」に置き換える。

- [ ] **Step 5: 検証する**

```bash
wc -l docs/adr/ADR-010-document-framework.md      # 60 以下
grep -c '^## ' docs/adr/ADR-010-document-framework.md   # 8
ls docs/adr/ADR-*.md | wc -l                       # 5
ls docs/archive/adr/ | wc -l                       # 5
head -1 docs/archive/adr/ADR-001-backend-stateless.md   # 「> 卒業済み（…）」
bash scripts/inventory.sh 2>/dev/null | sed -n '1,9p'   # 「未卒業 ADR 5 本（上限 5）」。60 行超は 002・005・007・009 の 4 本（Task 2・3 で解消）
printf 'backend/app/config.py\n' | scripts/adr-touch.sh # ADR-002・004・008 の行が出る。卒業しても索引行は残るので 004・008 も出ること。010 は出ない（行為語が無い）
```

- [ ] **Step 6: コミットして PR を作る**

```bash
git add -A docs/adr docs/archive/adr AGENTS.md
git commit -m "docs: ADR-010（文書の枠組み）を置き、検査が CI にある ADR 5 本を卒業させる (Phase 5 / Task 1)"
git push -u origin docs/adr-010-graduate
gh pr create --base docs/phase5-plan --title "docs: ADR-010（文書の枠組み）を置き、ADR 5 本を卒業させる (Phase 5 / Task 1)" --body-file /tmp/phase5-body.md
```

PR 本文（`/tmp/phase5-body.md`）の型。以降の Task も同じ型:

```markdown
Phase 5 Task 1（計画: docs/plans/2026-09-06-phase5-docs-rewrite.md）。

## 索引の未卒業行への yes/no
| ADR | 触れるか | 理由 |
|---|---|---|
| 002 | no | 索引の行を写しただけ |
| 005 | no | 同上 |
| 007 | no | 同上 |
| 009 | no | 同上 |
| 010 | yes | 本 PR が新設する決定そのもの |

## 検証の実出力
（Step 5 の出力を貼る）
```

---

### Task 2: ADR-002・005 を 60 行の型に書き直す

**Files:**
- Modify: `docs/adr/ADR-002-rate-limit-single-instance.md`（81 行 → 60 行以内）
- Modify: `docs/adr/ADR-005-frontend-single-truth.md`（147 行 → 60 行以内）
- Modify: `AGENTS.md` の索引 ADR-002 の行（`memory://` が実態と違う。`limits` の `MemoryStorage`）

節は 8 つに固定: 背景と課題 ／ 制約 ／ 検討した選択肢 ／ 決定 ／ 決定理由と却下案 ／ 限界 ／ 検査 ／ 再訪条件。
旧版の文は git 履歴に任せ、「改訂」「実装後の補足」の節は作らない（A3 規則 5）。**却下案は 1 つも落とさない。** 1 項目 1 行で折り返さない。

- [ ] **Step 1: ブランチを切る**

```bash
git checkout -b docs/adr-002-005 docs/adr-010-graduate
```

- [ ] **Step 2: ADR-002 を書き直す**

節ごとに残す内容（現行 ADR-002 から。文は短く言い換えてよいが事実は変えない）:

- 背景と課題: `RATE_LIMIT_STORAGE_URI` が 7 周の秘匿機構（約 184 行）の存在理由だった。レート制限の要件はどの要件書にも無く、NFR-101（端末内保存）を誤引用していた
- 制約: 守るものは **単一送信元（IP）の burst 抑制**（主）と粗い DoS 緩和（副）。総費用の上限はレート制限では作れず、**プロバイダの支出上限**が真の上限で backend 公開の必須条件。非目標は利用者間の公平性。既定 1 リクエスト/10 秒/IP（`RATE_LIMIT_TIMES` / `RATE_LIMIT_SECONDS`）
- 検討した選択肢: 1 共有ストア（Redis）／2 プロセス内メモリ（採用）／3 インフラ層（WAF・API Gateway）＋支出上限に任せる／4 レート制限なし
- 決定: 案 2。slowapi を外し `limits` の `MemoryStorage` を直接使う（2026-09-02 の改訂を本文に吸収）。`RATE_LIMIT_STORAGE_URI` は作らない。uvicorn は `--no-proxy-headers`、XFF の解釈は `backend/app/ratelimit.py` の 1 箇所。`TRUSTED_PROXY_COUNT` は実段数と一致させる（0 なら XFF を信頼しない。チェーンが段数に満たなければ接続元 IP へフォールバック）
- 決定理由と却下案: 案 1 は秘密入り URI が再生産源（復帰条件: 実測でマルチインスタンスが必要、かつ資格情報を URI に埋めない方式）／案 3 は却下ではなく保留（デプロイ形態の ADR で第一候補として再評価。採用ならアプリ内カウンタを削除まで戻す）／案 4 は端末キー漏えい・誤動作クライアントに費用が無防備
- 限界: 同一コンテナの worker>1 は起動ガードで落ちるが **replica は検出できない**。`TRUSTED_PROXY_COUNT` の過大設定はフェイルクローズにならず、クライアントが識別子を選べる。守りはデプロイ側の契約（replicas=1 か上流レート制限、上流で受信 XFF を上書き）で、コードでは守れない
- 検査: (i) 層 2 — 依存・設定キー・外部送信先（`scripts/adr-touch.sh`）。(ii) 起動ガード `STARTUP_MULTIPLE_WORKERS`、契約テスト（429・`X-RateLimit-*`・`Retry-After`）。**未検査**: デプロイ側契約と支出上限（設定した日に確認日・上限額・確認手段を本 ADR に書き足してから端末キーを配布する。台帳 L-58）
- 再訪条件: デプロイ形態を決める日（案 3 を再評価）。マルチインスタンスが実測で必要になった日（復帰条件つきで案 1）

- [ ] **Step 3: ADR-005 を書き直す**

- 背景と課題: お気に入りが 4 箇所（`HistoryItem.isFavorite`／`features/favorite/`／`features/favorites/`／`PresetPhrase.isFavorite`）。`isFavorite` のバグは Hive アダプタのテストが緑のまま生き残った（欠陥は変換層、テストは層を飛ばしていた）。Hive が開けないと黙ってインメモリで動き続ける。発話支援では「保存できたように見えて消える」が最悪
- 制約: NFR-301（ストレージ障害でも文字盤・TTS は使える）。利用者は複雑なエラー表示を操作できない
- 検討した選択肢: お気に入り 1 現状維持／2 `HistoryItem.isFavorite` に一本化／3 `favoriteProvider` に一本化（採用）。永続化 a サイレント継続／b 起動をブロック／c 状態を型で明示し、利用者に伝えて継続（採用）
- 決定: `favoriteProvider` が真実、レコードの同一性と定型文連動の同期キーは id。`isFavorite` は両モデルから削除済み（migration は実装後に撤回 `f761afc`。検証端末に守るデータが無く、残すと削除したお気に入りが再起動で復活する）。**真実は 1 つ、射影は用途ごとに決めてよい**（履歴画面の星は content 照合、`input_candidate_scorer` はテキスト射影）。永続化は `sealed class PersistenceState { Ready / RecoverableFailure / Unavailable }` で利用者に通知。往復テスト（UI → provider → repository → 実 box → 再起動相当 → UI）を history・preset_phrase・favorite・settings に置く
- 決定理由と却下案: 案 1 は多重実装の温存（「タグを追加」の日に 5 つ目が生まれる）／案 2 はお気に入りが「項目に付くフラグ」ではなく「履歴・定型文をまたぐ独立のコレクション」で、項目の削除・保持上限と独立に生きるべきもの（所有者とライフサイクル）／a はデータ喪失を利用者が知る手段が無い／b は NFR-301 に反する
- 限界: UI ロジックだけの重複は許可リストで捕まえられない（`favorite/` と `favorites/` の分裂は現存、L-67）。許可リスト検査は起動時の共有登録経路 `registerPersistedTypeAdapters()` だけを守り、直接の `Hive.registerAdapter` / `openBox` は守れない（自作検出器は作らない）。「トップレベル可変変数の禁止」は analyzer に無い。**却下理由と実装の矛盾**: `deletePhrase()` が `deleteFavoriteBySourceId()` を呼び、`TC-SYNC-202` がそれを正解として固定している（L-39。未解決。解くには本 ADR か要件定義 3.2 の改訂。2026-08-30 の対応は削除確認ダイアログに「お気に入りからも削除されます」を出すだけ）
- 検査: (i) 層 2 — 永続化（`scripts/adr-touch.sh` が `*_adapter.dart`・`hive_init.dart` を拾う）。(ii) `frontend/kotonoha_app/test/core/persistence/hive_schema_allowlist_test.dart`（typeId・永続フィールド）、往復テスト 4 本（`test/features/*/*_round_trip_test.dart`）、名指しの lint 4 つを warning に昇格。(iii) UI 重複は層 3 と棚卸し
- 再訪条件: 実フィードバックで通知の形が使えないと分かったとき（判定は月 1 のストアレビューとサポート窓口の巡回）。L-39 を解くとき

- [ ] **Step 4: 索引の ADR-002 の行を実態に合わせる**

「決めたこと」列を「レート制限は単一インスタンス前提・プロセス内メモリ（`limits` の `MemoryStorage`）。XFF は `app/ratelimit.py` の 1 箇所、`TRUSTED_PROXY_COUNT` は実段数。総費用の上限はプロバイダの支出上限」に。他の列は変えない。

- [ ] **Step 5: 検証する**

```bash
for f in docs/adr/ADR-002-rate-limit-single-instance.md docs/adr/ADR-005-frontend-single-truth.md; do
  printf '%s: %s 行, 見出し %s 本\n' "$f" "$(wc -l < "$f")" "$(grep -c '^## ' "$f")"   # 60 以下、8 本
done
bash scripts/inventory.sh 2>/dev/null | grep '60 行超'   # 007・009 だけ
printf 'backend/app/config.py\n' | scripts/adr-touch.sh | grep -c 'ADR-002'   # 1
```

- [ ] **Step 6: コミットして PR を作る**

```bash
git add docs/adr/ADR-002-rate-limit-single-instance.md docs/adr/ADR-005-frontend-single-truth.md AGENTS.md
git commit -m "docs: ADR-002・005 を 60 行の型に書き直す（改訂節と実装後の補足を本文へ吸収） (Phase 5 / Task 2)"
git push -u origin docs/adr-002-005
gh pr create --base docs/adr-010-graduate --title "docs: ADR-002・005 を 60 行の型に書き直す (Phase 5 / Task 2)" --body-file /tmp/phase5-body.md
```

yes/no: 002 yes（書き直し）、005 yes（書き直し）、007 no、009 no、010 no。

---

### Task 3: ADR-007・009 を 60 行の型に書き直す

**Files:**
- Modify: `docs/adr/ADR-007-release-criteria.md`（312 行 → 60 行以内）
- Modify: `docs/adr/ADR-009-crash-reporting-store-native.md`（208 行 → 60 行以内）

- [ ] **Step 1: ブランチを切る**

```bash
git checkout -b docs/adr-007-009 docs/adr-002-005
```

- [ ] **Step 2: ADR-007 を書き直す**

現行の「ステータス・署名・日付・コンテキスト・結果影響・置き換える ADR・参考資料」は 8 節へ畳む。実測の記録
（テスト件数、充足日の詳細）は git 履歴に任せる。**却下した削減案は A・B・C の 3 つ**（現行 147〜152 行目の表。238〜244 行目に同じ表が重複しているので 1 つに畳む）。名前と理由を 1 行ずつ残す。

- 背景と課題: 是正計画に「利用者に届ける」工程が無く、内部品質工程が無限に続きうる。frontend はオフラインで動くので「何を満たしたら届けるか」「backend を待つか」が優先順位を決める。ヒアリング（2026-08-29）: 最初から一般公開、特定の初期利用者は想定しない、使い勝手は届けながら確かめる
- 制約: 利用者は壊れても声で助けを求められない。会話内容は端末内のみで送信しない。ストア配布には開発者登録・審査・プライバシーポリシー公開が要る。iPad を含むため App Store は必須経路
- 検討した選択肢: A リリース工程を定義しない／B 身近な利用者・支援者経由の限定配布／C オープンテスト段階を挟む／D 公式ストアでいきなり本公開（採用）。品質フィードバック経路は ADR-009 に委ねる
- 決定: D。初回は AI 変換抜き（backend 非依存）でよい。条件は 4 つで閉じ、日付は置かず、足すには本 ADR の改訂が要る。1 frontend 品質（永続化失敗の利用者通知・お気に入り 1 真実・E2E 4 経路が CI 緑・Hive 許可リスト）／2 緊急ボタンの両側テスト（発報できない・誤発報）／3 クラッシュ報告の方針＝ADR-009 で、プライバシーポリシーにアプリが送らないことと OS・ストアの診断機能で送られうる内容を明記／4 ストア要件（開発者登録・ポリシー公開・審査通過・医療や治療効果を謳わない・サポート連絡先を非クラッシュ不具合の受付として月 1 でストアレビューとあわせて巡回）。条件にしないもの: backend・formative usability test・オープンテスト（Play の段階的公開は緩和策として可）。充足状況: 1〜3 充足（PR #89・#90・#91）、4 は未（開発者登録・L-51・L-52）
- 決定理由と却下案: A は工程が無限に続く／B・C は接点が無く、待つ理由が無い／目標日は実際の制約でない日付が実態とずれる（2026-08-30 廃止）／削減案 A（お気に入りを初回から外す）・B（Android を初回から外す）・C（対面表示モードと入力候補を外す。効果が限定的）は、条件を足すときの交換材料として記録
- 限界: 初期不具合が本番利用者に直撃しうる。当事者による事前検証は行わない。緩和は条件 1〜3 の品質バーとストアのクラッシュ集計
- 検査: 索引の「関わる行為」は権限・外部送信先で、それに触れる変更は層 2 が索引行を貼る（(i)）。条件の充足そのものは (iii) で、層 3 と棚卸し。条件 1〜3 はテスト（緊急ボタン両側・往復 4 本・許可リスト）が固定する。条件 4 は台帳（L-51・L-52）
- 再訪条件: データ喪失・緊急ボタン誤動作・会話内容の意図しない送信が 1 件でも報告されたら配信を停止し原因特定まで再開しない／条件を増やしたくなったら本 ADR を改訂（削減案を交換材料に）／条件 1〜4 を満たしても出さない判断をしたら前提を見直す／伴走できる当事者との接点ができたら次リリースを B・C 経由にしてよい

- [ ] **Step 3: ADR-009 を書き直す**

- 背景と課題: ADR-007 条件 3 の「クラッシュ報告」をどう入れるか。Flutter の Dart 例外はプロセスを落とさず、ストアの集計に映らない。`firebase_crashlytics` は Flutter Web 未対応
- 制約: 声で助けを求められない。会話内容は送信しない。リリースは backend に依存しない（ADR-007）
- 検討した選択肢: A Firebase Crashlytics／B Sentry／C ストア標準に依拠し、アプリからは何も送らない（採用）／D 自前の送信先（backend に 1 エンドポイント）／E 端末内に貯めて利用者が任意で共有
- 決定: C。SDK を入れず送信経路を持たない。「会話内容・入力内容・ハッシュを一切含まない」は構造で担保し、型・検査・サニタイザを作らない。Web は初回リリースの対象外（開発・確認用）。プライバシーポリシーに「アプリ自身は送らない」「OS・ストアの診断機能で、利用者が許可した場合に限り Apple・Google へ送られうる」を明記
- 決定理由と却下案: A は Web 未対応に加え、依存追加＋外部送信先追加の価値が想定外の Dart 例外の可視化に見合わない／B は「一切含まない」を設定で守る形で、許可集合を手書きで守って 8 周費やした前例と同じ構造／D は backend 依存で ADR-007 に反する／E は ADR-007 で却下済み。共通: 最も重い事象（データ喪失）は Phase 3 で画面に出るようになり、外部送信先を増やす取引が割に合わない
- 限界: 想定外の Dart 例外は見えない。ストアのレポートが読めるためにはリリースビルドに mapping とシンボルが要る（AAB 化は #97 で済、アップロード鍵は L-52）
- 検査: (i) 層 2 — 依存・外部送信先（`scripts/adr-touch.sh` が `pubspec.yaml` を拾う）。`pubspec.yaml` に crashlytics・sentry・firebase 系の依存が無いことは棚卸しの目視
- 再訪条件: ストアの集計だけでは原因が分からない不具合が実際に報告されたとき（B を再検討。「一切含まない」を型で閉じる設計を先に決める）／Web を正式なリリース対象にするとき／`firebase_crashlytics` が Web 対応し、かつ前者が起きたとき

- [ ] **Step 4: 検証する**

```bash
for f in docs/adr/ADR-007-release-criteria.md docs/adr/ADR-009-crash-reporting-store-native.md; do
  printf '%s: %s 行, 見出し %s 本\n' "$f" "$(wc -l < "$f")" "$(grep -c '^## ' "$f")"   # 60 以下、8 本
done
bash scripts/inventory.sh 2>/dev/null | grep -c '60 行超'   # 0
grep -c "削減案" docs/adr/ADR-007-release-criteria.md      # 1 以上。A・B・C の 3 つが 1 行ずつ
```

- [ ] **Step 5: コミットして PR を作る**

```bash
git add docs/adr/ADR-007-release-criteria.md docs/adr/ADR-009-crash-reporting-store-native.md
git commit -m "docs: ADR-007・009 を 60 行の型に書き直す（充足状況と改訂節を本文へ吸収） (Phase 5 / Task 3)"
git push -u origin docs/adr-007-009
gh pr create --base docs/adr-002-005 --title "docs: ADR-007・009 を 60 行の型に書き直す (Phase 5 / Task 3)" --body-file /tmp/phase5-body.md
```

yes/no: 007 yes、009 yes、002 no、005 no、010 no。

---

### Task 4: README を開発者の正本にし、fvm をピン留めし、tech-stack・SETUP・CONTRIBUTING を倉庫へ

**Files:**
- Modify: `README.md`（473 行を書き直す。行数の上限は無いが「同じ内容を 2 箇所に書かない」）
- Create: `frontend/kotonoha_app/.fvmrc`（`fvm use 3.38.1` が作る。CI の `FLUTTER_VERSION` と同じ）
- Modify: `.gitignore`（`frontend/kotonoha_app/.fvm/` を追加。`fvm use` が作る SDK のシンボリックリンク）
- Move: `docs/tech-stack.md` → `docs/archive/tech-stack.md`、`docs/SETUP.md` → `docs/archive/SETUP.md`、`CONTRIBUTING.md` → `docs/archive/CONTRIBUTING.md`
- Modify: `AGENTS.md`（`docs/tech-stack.md` への参照 5 箇所と、ディレクトリ図の `tech-stack.md` 1 箇所を `README.md` に。Task 6 で全面的に書き直すが、この PR の時点で壊れた参照を残さない）
- Modify: `.github/workflows/python.yml:20`（コメント「CLAUDE.md / docs/tech-stack.md の『全体80%以上』」→「AGENTS.md / README.md」）
- Modify: `docs/spec/kotonoha-requirements.md:15`（関連文書の `../tech-stack.md` → `../../README.md`。Task 5 で節ごと書き直すが、この PR で壊さない。**各要件行末尾の出典 `*tech-stack.md 3-2*` 等 9 行は来歴なので触らない**）

- [ ] **Step 1: ブランチを切る**

```bash
git checkout -b docs/readme-source docs/adr-007-009
```

- [ ] **Step 2: fvm をピン留めする**

```bash
cd frontend/kotonoha_app && fvm use 3.38.1 && cd -     # .fvmrc と .fvm/ ができる
cat frontend/kotonoha_app/.fvmrc                       # "flutter": "3.38.1"
printf '\n# fvm が作る SDK のシンボリックリンク（.fvmrc は追跡する）\nfrontend/kotonoha_app/.fvm/\n' >> .gitignore
git check-ignore frontend/kotonoha_app/.fvm && git status --short frontend/kotonoha_app   # .fvmrc だけが出る
(cd frontend/kotonoha_app && fvm flutter --version | head -1)   # Flutter 3.38.1
```

- [ ] **Step 3: 統合元の生きている部分を読んで印を付ける**

読む範囲と、取るもの:

| 統合元 | 取る | 捨てる（実態と違う、または工程記録） |
|---|---|---|
| `docs/tech-stack.md` | セットアップ手順（345〜492 行目。`uv venv --seed`・`pre-commit install`・fvm）、主要コマンド（493〜549）、品質基準（228〜249）、開発ワークフロー（550〜569）のうち現行の規約 | 生成情報、DB 節（廃止済み）、`infra/` `services/` `core/database.py` などの実在しない構成、学習リソース、更新履歴、次のステップ |
| `docs/SETUP.md` | 前提条件（17〜34）、Docker 環境（35〜131。backend のみ、DB 無し）、backend 環境（132〜138）、frontend 環境（139〜252）、動作確認（313〜358）、トラブルシューティング（359〜521）のうち現物で再現するもの | IDE 設定、サポート節 |
| `CONTRIBUTING.md` | コーディング規約（84〜205）、コミットメッセージ（206〜252。実態は docs: 形式）、ブランチ運用とマージの引き金（253〜281）、PR（282〜325）、テスト（344〜385） | 行動規範、Issue の使い方（ADR-010: Issue にタスクを書かない）、ドキュメント一覧 |

行番号は 2026-09-06 時点。着手時に `grep -n '^## '` で測り直す。

- [ ] **Step 4: README を書き直す**

節の構成（この順）:

```markdown
# kotonoha（ことのは）
（1 段落: 何のアプリか、利用者、オフラインファースト、端末内保存。仕様は docs/spec/kotonoha-requirements.md、
　利用者向けは docs/privacy-policy.md と docs/support.md。エージェント向けの核は AGENTS.md）

## 前提
- Flutter 3.38.1（fvm。frontend/kotonoha_app/.fvmrc でピン留め。`fvm install` で入る）、Python 3.12（uv）、Docker（backend の開発用。DB は無い）
## セットアップ
- clone、`cp .env.example .env`（キーの説明は .env.example に書いてある。ここに写さない）
- backend: `uv venv --seed`（`--seed` が無いと pip が入らない）、`pip install -r requirements-dev.txt`、`pre-commit install`
- frontend: `fvm install` → `fvm flutter pub get`
## 起動
- backend: `(cd backend && .venv/bin/uvicorn app.main:create_app --factory --no-proxy-headers --reload)`（Application Factory なので --factory 必須）
- frontend: `fvm flutter run -d chrome`。接続先を変えるときの --dart-define の渡し方と、空文字が defaultValue を消す罠（現行 AGENTS.md「開発コマンド」から移す）
- 動作確認: `curl -s localhost:8000/api/v1/health`、Swagger は http://localhost:8000/docs
## 検査
- backend: `pytest`（pytest-randomly）、`make check`（ruff・black・mypy --strict・lint-imports・gates.sh）、`make mutation`（kill rate は台帳の計測へ。CI に入れない）
- frontend: `fvm flutter analyze`、`fvm flutter test`、`fvm dart format --set-exit-if-changed .`
- 全体: `scripts/inventory.sh`（月 1 の棚卸し。数えるだけ）、`git diff --name-only origin/main...HEAD | scripts/adr-touch.sh`（層 2 を手元で）
## CI（.github/workflows/）
- python.yml / flutter.yml / adr-touch.yml / openspec-guard.yml / inventory-reminder.yml / release.yml を各 1 行
## 規約
- コーディング（Python: 型ヒント・100 文字・Google docstring。Flutter: null safety・const・key・flutter_lints）
- コミット（既存に倣う。docs / feat / fix / ci / chore / build などの接頭辞 ＋ 日本語 1 行。末尾に Co-Authored-By）、ブランチ（CONTRIBUTING 253〜281 の生きている部分）
- PR（差分 400 行 / 12 ファイル、本文に索引の yes/no と完了条件、マージの引き金は完了条件であって指摘ゼロではない）
## ディレクトリ
- backend/・frontend/kotonoha_app/・docker/・scripts/・docs/・.github/workflows/ を実在するものだけ 1 行ずつ（`ls` で確かめる。`infra/` は無い。IaC は未着手）
## 文書の地図
- 核 AGENTS.md／決定 docs/adr/（索引は AGENTS.md）／仕様 docs/spec/kotonoha-requirements.md／API backend/tests/contract/openapi_baseline.json／
  利用者向け docs/privacy-policy.md・docs/support.md／台帳 docs/ledger.md／倉庫 docs/archive/（読まない）
## トラブルシューティング
- SETUP.md 359〜521 のうち、いま再現するものだけ（venv・fvm・ChromeDriver など。再現しないものは捨てる）
## ライセンス
```

**書かないもの**: 「開発状況 Phase 1〜4」、「Tsumiki 開発フレームワーク」、環境変数の表（`.env.example` が正本）、API のエンドポイント一覧
（OpenAPI baseline が正本）、実在しないディレクトリ（`infra/` `services/` `core/database.py`）、「AWS CDK」（コードが無い）。

- [ ] **Step 5: 3 本を倉庫へ移し、参照を付け替える**

```bash
git mv docs/tech-stack.md docs/archive/tech-stack.md
git mv docs/SETUP.md      docs/archive/SETUP.md
git mv CONTRIBUTING.md    docs/archive/CONTRIBUTING.md
git grep -n "tech-stack.md\|SETUP.md\|CONTRIBUTING.md" -- AGENTS.md README.md .github docs/spec docs/support.md docs/privacy-policy.md   # 残る側の参照。要件定義の出典 9 行（*tech-stack.md …*）は残す
```

`AGENTS.md` 内の `docs/tech-stack.md`（5 箇所）とディレクトリ図の `tech-stack.md`（1 箇所）は `README.md` に置き換える。

- [ ] **Step 6: README のコマンドを実際に実行する**

```bash
(cd backend && .venv/bin/python -c "import app.main" && make check)            # 通る
(cd backend && exec .venv/bin/uvicorn app.main:create_app --factory --no-proxy-headers --port 8765) & pid=$!
sleep 3; curl -s localhost:8765/api/v1/health; echo; kill "$pid"               # status が返る。サブシェルの & は kill %1 で止まらない
(cd frontend/kotonoha_app && fvm flutter --version | head -1 && fvm flutter test test/core/utils/logger_test.dart)   # Flutter 3.38.1、緑
bash scripts/inventory.sh 2>/dev/null | sed -n '/実在しないパス参照/,/生成時コメント/p'   # README 由来の「無い:」が増えていない（観測値）
```

- [ ] **Step 7: コミットして PR を作る**

```bash
git add -A README.md AGENTS.md .gitignore frontend/kotonoha_app/.fvmrc .github/workflows/python.yml docs/spec/kotonoha-requirements.md docs/archive CONTRIBUTING.md docs/tech-stack.md docs/SETUP.md
git commit -m "docs: README を開発者の正本にし、fvm を 3.38.1 にピン留めし、tech-stack・SETUP・CONTRIBUTING を倉庫へ (Phase 5 / Task 4)"
git push -u origin docs/readme-source
gh pr create --base docs/adr-007-009 --title "docs: README を開発者の正本にする (Phase 5 / Task 4)" --body-file /tmp/phase5-body.md
```

yes/no: 全行 no（コードと設定に触れない。`.fvmrc` は SDK の版の宣言で、負債を作る 7 行為のどれでもない。PR 本文にその旨を書く）。

---

### Task 5: 要件定義を実装と突き合わせ、仕様以外を倉庫へ移す

**Files:**
- Modify: `docs/spec/kotonoha-requirements.md`（凡例 19〜22 行目の削除、記号の除去、関連文書節の書き換え、突き合わせで直す行）
- Modify: `openspec/config.yaml`（`context:` を現状に。L-72）
- Modify: `.github/workflows/openspec-guard.yml:3,34`（コメントとメッセージの「恒久成果物は openspec/specs/ のみ」を「恒久成果物は置かない（ADR-010: OpenSpec は使い捨て）」に。検査の内容は変えない）
- Modify: `AGENTS.md`（`docs/design/kotonoha/*.md` への参照 4 行（2026-09-06 時点で 264・361〜363 行目）を `README.md` か要件定義に付け替える。Task 6 で全面的に書き直すが、この PR の時点で壊れた参照を残さない）
- Move（`git mv`。内容は変えない）:
  - `docs/design/kotonoha/{README.md,api-endpoints.md,architecture.md,database-erd.md,database-schema.sql,dataflow.md,interfaces.dart}` → `docs/archive/design/kotonoha/`
  - `docs/spec/{kotonoha-acceptance-criteria.md,kotonoha-user-stories.md,mvp-requirements-original.md}` → `docs/archive/spec/`
  - `docs/articles/why-redaction-fixes-dont-converge.md` → `docs/archive/articles/`
  - `CHANGELOG.md` → `docs/archive/CHANGELOG.md`
  - `docs/user-guide/index.md` → `docs/archive/user-guide/index.md`
  - `openspec/specs/favorites/spec.md`・`openspec/specs/persistence-state/spec.md` → `docs/archive/openspec/specs/…`
  - `frontend/kotonoha_app/README.md`・`lib/core/README.md`・`lib/features/README.md`・`lib/shared/README.md`・`integration_test/README.md` → `docs/archive/frontend/kotonoha_app/…`（同じ相対パス）
- Modify: `docs/ledger.md`（L-04・L-08・L-43・L-53・L-72 を `[x]` にし、出所に本 PR 番号を足す。行文の `docs/design/…` は出所なので残す）

- [ ] **Step 1: ブランチを切る**

```bash
git checkout -b docs/spec-and-archive docs/readme-source
```

- [ ] **Step 2: 要件定義から記号と凡例を消す**

```bash
sed -n 19,22p docs/spec/kotonoha-requirements.md     # 「**【信頼性レベル凡例】**:」と 🔵🟡🔴 の 3 行であることを確認してから
perl -CSD -Mutf8 -i -ne 'print unless 19..22' docs/spec/kotonoha-requirements.md
perl -CSD -Mutf8 -i -pe 's/ ?[\x{1F535}\x{1F7E1}\x{1F534}]//g' docs/spec/kotonoha-requirements.md
cat -s docs/spec/kotonoha-requirements.md > /tmp/req.md && mv /tmp/req.md docs/spec/kotonoha-requirements.md   # 凡例の前後で空行が 2 つ並ぶのを 1 つに
grep -c "🔵\|🟡\|🔴" docs/spec/kotonoha-requirements.md   # 0
git diff --stat docs/spec/kotonoha-requirements.md       # 削除 4 行＋記号を含んでいた行だけ
```

各要件行の末尾の出典（`*mvp-requirements-original.md 5-1-1*` など）は来歴なので残す。

- [ ] **Step 3: 関連文書の節を書き換える**

```markdown
## 関連文書

- 決定（ADR）の索引: `AGENTS.md`
- API の形: `backend/tests/contract/openapi_baseline.json`（起動中は http://localhost:8000/docs。値域は持たないので enum はコードを読む）
- 開発者向け: `README.md`
- 利用者・審査者向け: `docs/privacy-policy.md`、`docs/support.md`
```

- [ ] **Step 4: 要件を実装と突き合わせる（手作業。コードが正）**

要件 ID ごとに、対応する実装かテストを `git grep` で探し、PR 本文の表（ID／判定／根拠ファイル）に書く。判定は 3 つ:
一致／要件を直した（差分に現れる）／未実装だが「してもよい」（MAY のまま）。**「しなければならない」で未実装のものは、要件を消さず
台帳へ 1 行送る**（実装するかどうかは決定であって、この Task では決めない）。

先に確かめる既知の疑い:

| 対象 | 確かめ方 |
|---|---|
| DB・サーバー保存・Redis を前提にした記述 | `grep -n "DB\|データベース\|PostgreSQL\|Redis\|サーバー.*保存" docs/spec/kotonoha-requirements.md`。ADR-001 と矛盾する行は直す |
| 読み上げ速度の段階数 | `grep -n "速度" docs/spec/kotonoha-requirements.md` と `frontend/kotonoha_app/lib/features/tts/` の `TTSSpeed` enum の値数（2026-09-06 時点で 3。#98 でストア文言を直した経緯） |
| REQ-203 状態ボタン 8〜12 個 | `frontend/kotonoha_app/lib/features/status_buttons/domain/status_button_constants.dart`（2026-09-06 時点で既定 8＋任意 4） |
| テーマ 3 種・フォント 3 段階 | `frontend/kotonoha_app/lib/features/settings/` の `AppTheme`・`FontSize` enum |
| REQ-3002 履歴 50 件 | `frontend/kotonoha_app/test/features/history/data/history_repository_test.dart` の TC-062-008（一致の例） |
| AI 変換の丁寧さの段階 | `backend/app/ai/prompts.py` の `PolitenessLevel`（casual / normal / polite。baseline に enum は無い） |
| 3.2 孤立データ防止（定型文削除でお気に入りも消える） | **変えない**。L-39（ADR-005 の改訂と一緒に扱う） |
| MVP 範囲外の節 | 現行 `AGENTS.md`「MVP範囲外」と同じ 5 項目か |
| L-68 の 14 件（PR #108 本文の表） | 追跡性は対象外。要件の文が実装と食い違っていないかだけ見る |

- [ ] **Step 5: 倉庫へ移す**

```bash
mkdir -p docs/archive/design docs/archive/spec docs/archive/articles docs/archive/user-guide docs/archive/openspec/specs \
         docs/archive/frontend/kotonoha_app/lib/core docs/archive/frontend/kotonoha_app/lib/features docs/archive/frontend/kotonoha_app/lib/shared docs/archive/frontend/kotonoha_app/integration_test
git mv docs/design/kotonoha docs/archive/design/kotonoha
git mv docs/spec/kotonoha-acceptance-criteria.md docs/spec/kotonoha-user-stories.md docs/spec/mvp-requirements-original.md docs/archive/spec/
git mv docs/articles/why-redaction-fixes-dont-converge.md docs/archive/articles/
git mv CHANGELOG.md docs/archive/CHANGELOG.md
git mv docs/user-guide/index.md docs/archive/user-guide/index.md
git mv openspec/specs/favorites docs/archive/openspec/specs/favorites
git mv openspec/specs/persistence-state docs/archive/openspec/specs/persistence-state
git mv frontend/kotonoha_app/README.md docs/archive/frontend/kotonoha_app/README.md
git mv frontend/kotonoha_app/lib/core/README.md docs/archive/frontend/kotonoha_app/lib/core/README.md
git mv frontend/kotonoha_app/lib/features/README.md docs/archive/frontend/kotonoha_app/lib/features/README.md
git mv frontend/kotonoha_app/lib/shared/README.md docs/archive/frontend/kotonoha_app/lib/shared/README.md
git mv frontend/kotonoha_app/integration_test/README.md docs/archive/frontend/kotonoha_app/integration_test/README.md
rmdir docs/design docs/articles openspec/specs        # git mv は空になった親ディレクトリを残す。3 つとも消えること（エラーが出たら中身を確認）
ls -d docs/design docs/articles openspec/specs 2>&1   # 3 行とも No such file
```

- [ ] **Step 6: `openspec/config.yaml` の `context:` を書き換える**

```yaml
context: |
  kotonoha（ことのは） — 文字盤コミュニケーション支援アプリ。発話が困難な人が、少ない操作で、適切な丁寧さで、
  安全に伝える。利用者は発話で訂正できず、データは端末内（Hive）にしか無い。
  技術スタック: frontend Flutter 3.38.1（fvm）/ Riverpod 3.x / Hive 2.2.3（TypeAdapter は手書き）/ go_router。
  backend FastAPI 0.124 / Python 3.12。ステートレス（DB 無し）。レート制限は limits の MemoryStorage（単一インスタンス）。IaC は未着手。
  決定は AGENTS.md の ADR 索引を読む（ここに写さない。却下案と理由は docs/adr/ にしかない）。
  OpenSpec は使い捨て（ADR-010）。change 一式は openspec/changes/ に作り追跡しない。残す仕様はテストか
  docs/spec/kotonoha-requirements.md へ移してから捨てる。テストの規律は AGENTS.md の規律 5・6、検査を作る前の規律は規律 8。
```

`rules:` 以下のコメント例は残してよい。

- [ ] **Step 7: 検証する**

```bash
find docs -maxdepth 1 -type f | sort        # context-distillation.md（未追跡）, ledger.md, privacy-policy.md, store-assets-guide.md, support.md, verification-principles.md（Task 6 で倉庫へ）
find docs/spec -type f                       # kotonoha-requirements.md だけ
git ls-files openspec                        # config.yaml だけ
grep -c "🔵\|🟡\|🔴" docs/spec/kotonoha-requirements.md   # 0
for l in $(grep -oE '\]\(\./[^)]+\)' docs/support.md | sed -E 's/\]\(\.\/([^)]+)\)/\1/'); do [ -e "docs/$l" ] || echo "support.md の壊れたリンク: $l"; done   # 何も出ない
git grep -n "openspec/specs\|docs/design/\|acceptance-criteria\|user-stories" -- '*.md' '*.yml' '*.yaml' ':!docs/archive' ':!docs/plans' ':!.claude' ':!docs/ledger.md'   # openspec-guard.yml の直した文だけ。台帳の出所と .claude/ の道具定義は除外
bash scripts/inventory.sh 2>/dev/null | sed -n '/台帳/,/出力ゼロ/p'   # 台帳の [x] が 5 増えている
```

- [ ] **Step 8: 台帳を更新し、コミットして PR を作る**

L-04・L-08・L-43・L-53 は「正本でなくなった（倉庫へ移動、PR #NNN）」、L-72 は「直した（PR #NNN）」を末尾に足し `[x]` に。

```bash
git add -A
git commit -m "docs: 要件定義を実装と突き合わせ、仕様以外の設計文書・旧仕様・openspec を倉庫へ移す (Phase 5 / Task 5)"
git push -u origin docs/spec-and-archive
gh pr create --base docs/readme-source --title "docs: 要件定義の突き合わせと倉庫移動 (Phase 5 / Task 5)" --body-file /tmp/phase5-body.md
```

PR 本文に Step 4 の表（ID／判定／根拠）を全件載せる。yes/no: 005 は「3.2 孤立データ防止に触れるが変えていない」を明記して no、他は no。
ファイル数超過は本計画で承認済みと書く。

---

### Task 7: コードから【】記法と信頼性記号を剥がす（Task 1〜5 と並行。Task 6 の前に main へマージ）

**Files:**
- Modify: `frontend/kotonoha_app/{lib,test,integration_test,test_driver}/**/*.dart`（2026-09-06 時点で【か記号を含むファイル 286 本。【を含む行 7,053、記号 2,503 行）
- 変換スクリプトは scratch に置き、リポジトリに入れない

**Task 6 との関係**: Task 6 が編集するテストのコメント行（`favorite_round_trip_test.dart:17,69`、`settings_round_trip_test.dart:8`、
`persistence_failure_notification_test.dart:6`、`hive_init.dart:212` 付近）は、いずれも【】行の隣にある。本 Task を先にマージし、Task 6 は
`origin/main` を取り込んでから始める。

- [ ] **Step 1: ブランチを切り、基準値を取る**

```bash
git checkout -b refactor/strip-generation-markers main
cd frontend/kotonoha_app
fvm dart format --output=none --set-exit-if-changed . && echo "整形済み"            # 差分ゼロが前提（369 本）
fvm flutter analyze --no-fatal-infos 2>&1 | tail -1 | tee /tmp/analyze-before.txt   # 「No issues found!」か件数
git grep -lE '【|🔵|🟡|🔴' -- '*.dart' | wc -l                                       # 286 前後
```

- [ ] **Step 2: 変換する（使い捨てスクリプト。A4 の規則をそのまま実装）**

```bash
cat > /tmp/strip_markers.sh <<'EOF'
#!/usr/bin/env bash
# 使い捨て。【X】: → X: ／ 【X】 → X ／ 🔵🟡🔴 を消す。空になったコメント行は消す。行コメントだけが対象。
# perl は -Mutf8 が必須（無いとプログラム中の【がバイト列で照合され、記号だけ消えて【】が残る。2026-09-06 実測）
set -euo pipefail
cd "$(dirname "$0")"
git grep -lE '【|🔵|🟡|🔴' -- '*.dart' | while read -r f; do
  perl -CSD -Mutf8 -i -pe '
    if (/【|[\x{1F535}\x{1F7E1}\x{1F534}]/) {
      s/[ \t]*[\x{1F535}\x{1F7E1}\x{1F534}]//g;          # 記号を消す
      s/【([^】]*)】[ \t]*[:：][ \t]*/$1: /g;               # 【X】: → X:
      s/【([^】]*)】/$1/g;                                 # 【X】 → X
      s/[ \t]+$//;                                        # 行末の空白
      $_ = "" if m{^[ \t]*///?[ \t]*$};                   # コメントだけの行が空になった
      s{[ \t]+///?$}{};                                   # コードの末尾に空コメントが残った
    }
  ' "$f"
done
EOF
cp /tmp/strip_markers.sh ./strip_markers.sh && bash ./strip_markers.sh && rm ./strip_markers.sh
git grep -cE '【|🔵|🟡|🔴' -- '*.dart' | wc -l   # 0
```

- [ ] **Step 3: 非コメント差分が無いことを機械的に確かめる（整形前に）**

コメント（`//` 以降）を落とした上で新旧を比べる。空行だけの差は無視する（`-B`）。

```bash
cd "$(git rev-parse --show-toplevel)"
git diff --name-only -- frontend/kotonoha_app | while read -r f; do
  diff -B <(git show "HEAD:$f" | sed -E 's#[ \t]*//.*$##') <(sed -E 's#[ \t]*//.*$##' "$f") > /dev/null || echo "非コメント差分: $f"
done | tee /tmp/noncomment.txt; wc -l < /tmp/noncomment.txt   # 0
git diff --stat -- frontend/kotonoha_app | tail -1             # 挿入と削除が同数（2026-09-06 の dry run では行数は変わらない）
```

0 でなければ出たファイルを目視し、スクリプトの規則を直してやり直す（例外リストを作らない）。

- [ ] **Step 4: 1 つ目のコミット（コメントだけの変更）**

```bash
git add -A frontend/kotonoha_app
git commit -m "refactor: コードから【】記法と信頼性記号を剥がす（コメント本文は残す） (Phase 5 / Task 7)"
```

- [ ] **Step 5: 整形して 2 つ目のコミット**

```bash
cd frontend/kotonoha_app && fvm dart format . | tail -1 && cd -
git add -A frontend/kotonoha_app
git commit -m "refactor: 記法除去後に dart format を当てる (Phase 5 / Task 7)"   # 差分ゼロなら空コミットにせず省略
```

2 つ目のコミットは `dart format` の出力そのものなので、レビュアーは再実行して差分が出ないことで検証できる。

- [ ] **Step 6: analyze と test**

```bash
cd frontend/kotonoha_app
fvm flutter analyze --no-fatal-infos 2>&1 | tail -1 | diff - /tmp/analyze-before.txt && echo "analyze 同数"
fvm flutter test 2>&1 | tail -3        # All tests passed
fvm dart format --output=none --set-exit-if-changed . && echo "整形済み"
```

- [ ] **Step 7: PR を作る**

```bash
git push -u origin refactor/strip-generation-markers
gh pr create --base main --title "refactor: コードから【】記法と信頼性記号を剥がす (Phase 5 / Task 7)" --body-file /tmp/phase5-body.md
```

PR 本文: ファイル数超過は本計画で承認済み／Step 3 の「0」と Step 6 の出力／コミット 1 は非コメント差分ゼロ、コミット 2 は `dart format` の出力のみ／
**Task 6 より先にマージすること**。yes/no: 005 no（永続化のコードに触れるがコメントのみ。`adr-touch.yml` が `hive_init.dart` を拾って索引行を貼るのは正常）、他 no。

---

### Task 6: `AGENTS.md` を白紙から 120 行で書き、verification-principles を倉庫へ

**前提**: Task 7 が main にマージ済み（同じテストファイルの隣接行を触るため）。

**Files:**
- Modify: `AGENTS.md`（全置換。草稿は Step 4）
- Move: `docs/verification-principles.md` → `docs/archive/verification-principles.md`
- Modify（参照の付け替えと、§3 の事実をその場に 1〜2 行で残す。行番号は Task 7 のマージ後に測り直す）:
  - `frontend/kotonoha_app/test/core/persistence/hive_schema_allowlist_test.dart`（2 箇所）
  - `frontend/kotonoha_app/test/features/favorite/favorite_round_trip_test.dart`（2 箇所）
  - `frontend/kotonoha_app/test/features/settings/settings_round_trip_test.dart`（1 箇所）
  - `frontend/kotonoha_app/test/core/persistence/persistence_failure_notification_test.dart`（1 箇所）
  - `frontend/kotonoha_app/analysis_options.yaml`（参照 2 箇所。あわせて【】3 行を A4 の規則で剥がす）
  - `backend/tests/test_sinks.py`（docstring 1 箇所）
- Modify: `docs/ledger.md`（L-71 を `[x]` に。出所の `AGENTS.md:52` が本 PR で消える。L-30 の `[-]` 行にも参照があるが Task 8 で行ごと消えるので触らない）
- 不変: `CLAUDE.md`（7 行。AGENTS.md への参照だけ）

- [ ] **Step 1: ブランチを切り、Task 7 を取り込む**

```bash
git checkout -b docs/agents-core docs/spec-and-archive
git fetch origin && git merge --no-edit origin/main
git log --oneline origin/main -3 | grep -c "記法と信頼性記号"   # 1 以上（Task 7 が入っている）
git grep -cE '【|🔵|🟡|🔴' -- 'frontend/kotonoha_app/*.dart' | wc -l   # 0
```

- [ ] **Step 2: Task 5 終了時点の索引 10 行を控える**

```bash
grep -E '^\| ADR-[0-9]+ \|' AGENTS.md > /tmp/adr-index.txt; wc -l /tmp/adr-index.txt   # 10
```

- [ ] **Step 3: 索引を未卒業→卒業の順に並べ替える**

`/tmp/adr-index.txt` を 002・005・007・009・010・001・003・004・006・008 の順に並べ替える（`scripts/adr-touch.sh` は順序に依存しない）。

- [ ] **Step 4: `AGENTS.md` を白紙から書く**

草稿。索引の表は Step 3 の 10 行をそのまま貼る。コマンドは書く前に 1 つずつ実行する。数字は現物で確かめる。
**1 項目 1 行で折り返さない**（現行のように 100 文字で折ると 130〜150 行になる）。

```markdown
# AGENTS.md

エージェント（Claude Code / Codex など）が毎回読む核。**120 行以内。超えたら足す前に降ろす。**
決定は `docs/adr/`（索引は下）、文書の規則は ADR-010、後回しは `docs/ledger.md`。`CLAUDE.md` はこの文書への参照だけ。

## 製品

**kotonoha（ことのは）** — 文字盤コミュニケーション支援アプリ（Flutter、タブレット向け）。脳梗塞・ALS・筋疾患などで発話が困難な人が、少ない操作で、適切な丁寧さで、安全に伝える。
**利用者は発話で訂正できず、データは端末内（Hive）にしか無い。** 文字盤・定型文・履歴・お気に入り・TTS・緊急ボタンはオフラインで動く。AI 変換だけがオンライン（backend は FastAPI のステートレスなプロキシ。DB 無し）。
数字: TTS 開始 1 秒以内、タップ応答 100ms 以内、AI 変換平均 3 秒以内、タップ目標 44px 以上（推奨 60px）、フォント 3 段階、テーマ 3 種（高コントラストは WCAG 2.1 AA）。iOS 14 / Android 10 / Web 最新。
MVP 外: クラウド同期・アカウント・視線入力やスイッチ・音声認識・画像やスタンプ・ビデオ通話。仕様の正本は `docs/spec/kotonoha-requirements.md`。

## 規律（すべて実際に踏んだ穴から）

1. **完了と言う前に実物を動かす。** 8 周のレビュー往復で誰もアプリを起動せず、記号入りパスワードのバグが 418 テスト緑のまま生き残った。起動・HTTP 応答・描画されたウィジェットで確かめる（`superpowers:verification-before-completion`）
2. **観測点を疑う。** `flutter drive … | tail` の終了コードを見て「E2E 緑」と言った。主張の前に「この観測点は壊れていたら赤くなるか」を問い、答えられなければ意図的に壊して赤を見る。パイプの終了コード・部分パスの解析・自作の grep 集計は観測点をすり替える
3. **自分（前のセッション）が書いた文書・メモリを事実として扱わない。** メモリの「未マージ 6 本」は数日古いまま生きた。数字・パス・行番号は使う直前に現物で確かめる
4. **着手前に触るファイルを数え、下の索引の未卒業行ごとに「この変更はこの決定に触れるか」を yes/no で PR 本文に書く。** yes の行だけ本文を読む。どの行にも当たらなければ、実装ではなく決定から始めるかを問う（8 周はこの工程が無かった）
5. **修正の前にテストを書き、赤を見る。** 後に書くと修正が効く観測点を無意識に選ぶ（`str(exc)` だけを見て漏えいを「対処済み」にした）。完全一致アサーションを書かない。モックは外部 SDK とネットワーク境界だけ。検証は最も外側（stdout・実 box・HTTP・描画）で
6. **テストは 2 系統。** 仕様テストは受入基準から TDD で。リスクテストは要件に無い所を当てる。源は 3 つ: 境界値・往復・失敗注入・べき等性・ライフサイクル・時間・設定の組み合わせ・リソース枯渇の固定リスト／「**この利用者にとって最悪は何か**」（黙って消える・誤発報）／過去に起きた欠陥の形。実効性は本数ではなく mutation kill rate
7. **P0（到達経路を示せて、実際に赤を見せた）は直す。** 格下げや繰り延べを実装者が単独で決めない。「指摘ゼロ」を完了条件にしない。レビューは種類の違う 2 系統を当てる（AI レビュアーの盲点は相関する）。残りは台帳へ
8. **負債を作る 7 行為には ADR を引用する**: 依存の追加（`requirements*.txt` `pubspec.yaml` `pyproject.toml` `Podfile` `build.gradle.kts`）、永続化面（Hive の adapter・field・box）、秘密を持つ設定キー（`URI`/`URL`/`DSN` で終わる名前を含む）、モジュールレベルの可変グローバル、公開ルート、外部送信先、モバイル権限。**機械は止めない**（`scripts/adr-touch.sh` が索引行を PR に貼るだけ）。
   **レビュー指摘に応えて検査・ゲート・サニタイザを作る前に、①構造を変えて危険を表現不可能にできないか ②既存の権威（パーサ・型検査・リンタ・lock）の出力を消費できないか を問う。どちらも無ければ記録して受け入れる。自作の検出器は選択肢に入れない**（ADR-008 は 3 周・4,600 行で発火ゼロ、Phase 3 WP-1 の grep 検査は 3 周。同種の仕組みを作る前に `docs/archive/adr/` の ADR-008 を読む）
9. **同じ活動が 3 周したら外から価値を問う。** Stop フック（`.claude/hooks/activity-value-check.sh`）が直近 3 コミット同一 Issue で発火する。廃棄条件: 修正が 2 周目に入る／発火ゼロで 1 か月

## 決定の索引（未卒業 5 本。卒業済みの本文は `docs/archive/adr/`。列順は `scripts/adr-touch.sh` が読むので変えない）

| ADR | 決めたこと | 却下した案 | 関わる行為 | 検査 |
|---|---|---|---|---|
（Step 3 の 10 行）

パスに現れない再提案（同じ概念を UI ロジックで 2 つ目に実装する等）はこの索引でも層 2 でも拾えない。月 1 の棚卸しが受け皿。

## 文書（ADR-010）

核はこの 1 本。決定は `docs/adr/`（60 行、未卒業 5 本）。正本は読者ごとに 1 つ: 開発者 `README.md`／利用者・審査者 `docs/privacy-policy.md` `docs/support.md`／仕様 `docs/spec/kotonoha-requirements.md`／API `backend/tests/contract/openapi_baseline.json`。
使い捨ては `docs/plans/`（冒頭に破棄条件）と PR 本文。倉庫 `docs/archive/` は更新しない・現在の仕様として読まない。台帳 `docs/ledger.md` は 1 問題 1 行。**コードと文書が食い違ったらコードが正。** OpenSpec は使い捨て（openspec/changes は追跡しない）。

## コマンド（リポジトリルートから。前提と詳細は README）

```bash
(cd backend && .venv/bin/uvicorn app.main:create_app --factory --no-proxy-headers --reload)   # 起動。--factory 必須。DB は無い
(cd backend && pytest && make check)     # テスト（pytest-randomly）＋ ruff / black / mypy --strict / lint-imports / gates.sh
(cd backend && make mutation)            # mutmut。kill rate は台帳の計測へ。CI に入れない
(cd frontend/kotonoha_app && fvm flutter run -d chrome)   # 接続先は --dart-define=API_BASE_URL=…（空文字は defaultValue を消す）
(cd frontend/kotonoha_app && fvm flutter analyze && fvm flutter test && fvm dart format --set-exit-if-changed .)
scripts/inventory.sh                     # 月 1 の棚卸しの計測。数えるだけ
git diff --name-only origin/main...HEAD | scripts/adr-touch.sh   # 層 2 を手元で（PR では adr-touch.yml が貼る）
```

## 道具（目的は固定、道具は差し替え可能。実在は月 1 の棚卸しで点検）

| 目的 | いま使う道具 |
|---|---|
| 完了前に実物を動かす | `superpowers:verification-before-completion` / `run` |
| 決定を叩いて弱いものを落とす | `mattpocock-skills:grilling` / `openspec-explore` |
| 境界（seam）とモックの置き場を決める | `mattpocock-skills:codebase-design` |
| ドメイン語彙を整理する | `mattpocock-skills:domain-modeling` |
| フェーズ単位の大改修を task 分解して subagent で実行する | `superpowers:subagent-driven-development`。5 条件: task 分解の入力は計画書／拘束（上限・規約）を subagent へ渡す／2 系統レビューはマージ境界で／記録は PR 本文と台帳へ／OpenSpec change は `openspec-apply-change` が担い併用しない |
| 全体を見て重複・乖離・道具の陳腐化を数える | `inventory`（`.claude/skills/inventory/SKILL.md`。毎月 1 日の Issue から） |
| 影響範囲の列挙／決定の引き出し／状態遷移の洗い出し／仕様と実装の乖離／反証可能なセキュリティ検査 | **未割当**。手で行う（台帳 L-70） |

## 規約

Python: 型ヒント必須、行長 100、docstring は Google Style。Flutter: null safety、const、ウィジェットに key、flutter_lints。
コミット: 既存に倣う（接頭辞 ＋ 日本語 1 行、末尾に Co-Authored-By）。PR: 差分 400 行 / 12 ファイルまで（削除は数えない）、本文に索引の yes/no と完了条件。マージの引き金は完了条件であって指摘ゼロではない。

## 残作業

台帳 `docs/ledger.md` の「判断待ち」を読む。リリースは ADR-007 条件 4 のみ（開発者登録・サポート連絡先 L-51・アップロード鍵 L-52）。是正計画（2026-08〜09）は Phase 5 で完了。
```

- [ ] **Step 5: verification-principles を倉庫へ移し、参照を付け替える**

```bash
git mv docs/verification-principles.md docs/archive/verification-principles.md
git grep -n "verification-principles" -- ':!docs/archive' ':!docs/plans'   # 出る行を全部直す（台帳 L-30 の [-] 行は Task 8 で消えるので触らない）
```

出た各行で、パスを `docs/archive/verification-principles.md` に変え（履歴の指し先として残す）、そのコメントが引いている事実を
その場に 1〜2 行で書く。§3 の 5 事実と置き場:

| 事実 | 置き場（既存コメントに足す） |
|---|---|
| `testWidgets` の中では実 Hive の I/O が完了しない（FakeAsync）。`tester.runAsync()` で脱出する | `favorite_round_trip_test.dart`（既に書いてある。パスだけ変える）、`hive_schema_allowlist_test.dart` |
| `Hive.registerAdapter` の型引数を省くと全書き込みが壊れる | `frontend/kotonoha_app/lib/core/utils/hive_init.dart` の「型引数を明示している理由」（既に書いてある。無ければ 1 行足す） |
| `SecretStr` は `repr` と `str` を隠すだけで、`.get_secret_value()`・例外メッセージ・ログの `%r` は守らない（pydantic 2.12.5） | `backend/tests/test_sinks.py` の docstring に 1 行 |
| 例外連鎖（`raise … from exc`）は `__cause__` に元の例外を運び、`traceback` 出力で本文が出る | 同上 |
| 漏えいシンクは stdout・stderr・HTTP ボディ・ログの 4 種類 | 同上（表を埋めるテストなので既にある。無ければ 1 行） |

「P1 の処方箋」を引く 3 箇所（`analysis_options.yaml` 2 箇所、`hive_schema_allowlist_test.dart` 1 箇所）は「AGENTS.md 規律 8」に付け替える。

- [ ] **Step 6: 検証する**

```bash
wc -l AGENTS.md                                                  # 120 以下
grep -c '^| ADR-' AGENTS.md                                      # 10
printf 'backend/app/config.py\nfrontend/kotonoha_app/pubspec.yaml\n' | scripts/adr-touch.sh   # 001・002・004・006・008・009 の行が出る
bash scripts/inventory.sh 2>/dev/null | sed -n '/道具の実在/,/実在しないパス参照/p'   # 5 種すべて 有効=True・定義=あり（`run`・`inventory`・`openspec-*` は plugin:skill 形でないので出ない）
bash scripts/inventory.sh 2>/dev/null | sed -n '/実在しないパス参照/,/生成時コメント/p'   # 観測値。壊れた参照は無いこと（意図的不在と URL だけ）
git grep -cE '【' -- frontend/kotonoha_app/analysis_options.yaml   # 出力なし（0）
```

**核だけを読んで動かせるか**: 新しいシェルで `AGENTS.md` のコマンド節の 1〜2 行目と 5 行目を実行し、起動・テスト・整形検査が通る。

- [ ] **Step 7: 台帳を更新し、コミットして PR を作る**

L-71 を `[x]` にし「AGENTS.md の書き直しで解消（PR #NNN）。親計画の該当行は Task 8 で倉庫へ」を足す。

```bash
git add -A
git commit -m "docs: AGENTS.md を白紙から 120 行で書き直し、検証原則の規律 3 本を核へ移して本体を倉庫へ (Phase 5 / Task 6)"
git push -u origin docs/agents-core
gh pr create --base docs/spec-and-archive --title "docs: AGENTS.md を白紙から 120 行で書く (Phase 5 / Task 6)" --body-file /tmp/phase5-body.md
```

yes/no: 010 yes（核の上限を守る側）、005 no（テストのコメントのみ）、他 no。PR 本文に `wc -l` と道具の実在の出力を貼る。
2 系統レビューの観点: 「現行 AGENTS.md にあって草稿に無い規律のうち、実例 2 件を持つものが落ちていないか」「コマンドが実際に通るか」。

---

### Task 8: Phase 5 を閉じる（計画書の破棄、台帳の境界見直し、計測）

**前提**: Task 0〜7 がすべて main にマージ済み。main から切る。

**Files:**
- Delete: `docs/plans/2026-09-05-docs-framework-and-inventory.md`、`docs/plans/2026-09-06-phase5-docs-rewrite.md`（この文書）
- Move: `docs/plans/2026-08-29-architecture-remediation.md` → `docs/archive/plans/2026-08-29-architecture-remediation.md`（内容は変えない）
- Modify: `docs/plans/2026-09-02-remaining-work.md`（冒頭 3〜9 行目の「正本は ADR・台帳 Issue #85・是正計画」と「是正計画の残り（Phase 4・5）は…引き継いで消す」を「正本は ADR・`docs/ledger.md`・`AGENTS.md`」に。§2 の Phase 5 行を「完了（2026-09-xx、PR #…）」に）
- Modify: `docs/archive/README.md`（「現行の文書はどこか」の表 6 行を正本へ付け替える: 要件 → `docs/spec/kotonoha-requirements.md`／設計 → 決定は `docs/adr/`（索引は `AGENTS.md`）／環境構築 → `README.md`／これから → `docs/ledger.md` と `docs/plans/`／検証の原則 → `AGENTS.md` 規律／利用者向け → 不変）
- Modify: `docs/ledger.md`（下記）

- [ ] **Step 1: ブランチを切る**

```bash
git fetch origin && git checkout -b docs/phase5-close origin/main
git log --oneline -12 | grep -c "Phase 5 / Task"   # 7 以上（Task 1〜7 が入っている。Task 0 は題に Task 番号が無い）
```

- [ ] **Step 2: 計画書を破棄し、親計画を倉庫へ**

```bash
git rm docs/plans/2026-09-05-docs-framework-and-inventory.md docs/plans/2026-09-06-phase5-docs-rewrite.md
mkdir -p docs/archive/plans && git mv docs/plans/2026-08-29-architecture-remediation.md docs/archive/plans/
ls docs/plans/        # 2026-09-02-remaining-work.md だけ
```

- [ ] **Step 3: 台帳をフェーズ境界で見直す**

規則（ADR-010）: Phase 5 の前から `[x]` `[-]` だった行は消す。Phase 5 で `[x]` にした行（L-04・08・43・53・64・71・72）は残す（次の境界で消す）。

- 消す: L-56（`[x]`）と「却下」節の 39 行すべて（L-30 の verification-principles 参照もこれで消える）
- `[x]` にする: L-64（「観測値にすると決定（2026-09-06、ADR-010 の限界）」）
- 文言を直す: L-67 の「Phase 5 で統合」→「Phase 5（文書）の後」
- 足す（未対応。番号は台帳の次の番号）: `docs/store-assets-guide.md` と `frontend/kotonoha_app/integration_test/device_test/README.md` は ADR-007 条件 4 の充足で倉庫へ — Phase 5 A1
- 足す（判断待ち。次の番号）: Stop フック `.claude/hooks/activity-value-check.sh` は廃棄条件「発火ゼロで 1 か月」に 2026-09-30 で到達する。到達していれば削除するか、条件を書き直すか — AGENTS.md 規律 9
- 「判断待ち」の L-70 は残す

- [ ] **Step 4: 計測して「計測」節を書く**

```bash
bash scripts/inventory.sh 2>&1 | tee /tmp/inventory.txt
wc -l AGENTS.md
find docs -maxdepth 1 -type f | sort; find docs/spec -type f
git grep -lE '【|🔵|🟡|🔴' -- 'frontend/kotonoha_app/*.dart' | wc -l
```

「計測」節の行（最新 1 回だけ残す）: 日付／核の行数（上限 120）／未卒業 ADR 5 本・60 行超 0／台帳 未対応・対応済・却下の数／
出力ゼロの仕組み／実在しないパス参照（観測値。壊れた参照の数を併記）／kill rate（対象コード無変更なら前回値を再利用と明記）。

- [ ] **Step 5: 残作業索引と倉庫の入口を更新する**

`docs/plans/2026-09-02-remaining-work.md`: 冒頭の正本の記述を「ADR・`docs/ledger.md`・`AGENTS.md`」に、破棄条件の段落から「是正計画の残り（Phase 4・5）は … 引き継いで消す」の 2 行を削り、
§2 の表の Phase 5 行を「**完了**（2026-09-xx、PR #…〜#…）。核 120 行、未卒業 ADR 5 本、正本は README・要件定義・privacy-policy・support・OpenAPI」に。
`docs/archive/README.md`: 「現行の文書はどこか」の表を Files に書いた 6 行に付け替える（移動一覧は足さない）。

- [ ] **Step 6: 完了条件（A5）をすべて実行して PR 本文に貼る**

```bash
wc -l AGENTS.md                                            # 120 以下
bash scripts/inventory.sh 2>/dev/null | sed -n '1,9p'      # 未卒業 5 本、60 行超なし
find docs -maxdepth 1 -type f | sort                       # context-distillation.md（未追跡）, ledger.md, privacy-policy.md, store-assets-guide.md, support.md
find docs/spec -type f                                     # kotonoha-requirements.md
gh issue view 85 --json state --jq .state                  # CLOSED
git grep -lE '【|🔵|🟡|🔴' -- 'frontend/kotonoha_app/*.dart' | wc -l   # 0
for l in $(grep -oE '`[a-z/.-]+\.md`' docs/archive/README.md | tr -d '`'); do [ -e "$l" ] || echo "倉庫の入口の壊れた参照: $l"; done   # 何も出ない
```

- [ ] **Step 7: コミットして PR を作る**

```bash
git add -A
git commit -m "docs: Phase 5 を閉じる（計画書の破棄、台帳の境界見直し、計測） (Phase 5 / Task 8)"
git push -u origin docs/phase5-close
gh pr create --base main --title "docs: Phase 5 を閉じる (Phase 5 / Task 8)" --body-file /tmp/phase5-body.md
```

yes/no: 010 yes（数字を計測して守った）、他 no。マージ後に worktree を消し（`git worktree remove .claude/worktrees/phase5`）、
セッション側のメモリ（`architecture-remediation-review-2026-08`）を「Phase 5 完了。是正計画は全フェーズ完了」に更新する。

---

### Self-review（計画作成時に実施。2026-09-06 の 2 系統レビュー後に更新）

- **Spec coverage**: A1-1（観測値）→ Task 1 の ADR-010「限界」と Task 8 の L-64。A1-2（user-guide）→ Task 5（index.md だけ移動、4 本は不変）。
  A1-3（卒業 5 本）→ Task 1（卒業条件の 3 つ目は ADR-010 草稿の決定節）。A1-4（手作業）→ Task 5 Step 4。A1-5（verification-principles、規律 3 本）→ Task 6 草稿の規律 2・3・8 と Step 5。
  A1-6（記法を剥がす）→ Task 7。A1-7（順序。Task 7 は Task 6 の前）→ 実行順序の表と Task 6 Step 1。A1-8（1 本、Task 0）→ Task 0。
  A2 の行き先はすべて Task 1・4・5・6・8 のいずれかに現れる（台帳・倉庫の入口・`.fvmrc` を含む）。A3 の骨格 → Task 6 の草稿。A4 → Task 7 Step 2 のスクリプト（`test_driver` を含む）。
  A5 → Task 8 Step 6。A6 → Global Constraints。対象外 4 項目（L-67・親計画の 2 項目・Stop フック）→ A1 と Task 8 Step 3
- **Placeholder scan**: 「PR #NNN」「2026-09-xx」は実行時の番号と日付を入れる箇所。Task 6 の索引 10 行は Step 3 で並べ替えた `/tmp/adr-index.txt` から貼る。他に TBD 無し
- **Type consistency**: ブランチ名は実行順序の表と各 Task の `git checkout -b` で一致（`docs/phase5-plan` → `docs/adr-010-graduate` → `docs/adr-002-005` →
  `docs/adr-007-009` → `docs/readme-source` → `docs/spec-and-archive` → `docs/agents-core`、`refactor/strip-generation-markers`（main）、`docs/phase5-close`（main））。
  索引の列順（決めたこと・却下した案・関わる行為・検査）は Task 1・2・6 と `scripts/adr-touch.sh` の `$5` で同じ。
  倉庫の置き場は A2 と Task 1・4・5・6・8 で同じパス。ADR の 8 節名は Task 1〜3 で同じ。`git grep` の pathspec 除外は Task 4・5・6 で同じ形
- **レビューで直したもの（2026-09-06）**: Task 6/7 の隣接行衝突（順序を入れ替え）／「検査を自作する前に構造で」の規律の脱落（規律 8 と A1-5）／ADR-010 の卒業条件 3 つ目・(i)(ii)(iii) の定義・層 2 の規則・案 5 の却下／計画書の 400 行超過（Task 0）／`test_driver` と `analysis_options.yaml` の【】／Task 8 の base（main）／索引の順序／ADR-007 の削減案 C／履歴テストのパス／倉庫の入口の表／L-71／折り返し／fvm の版（`.fvmrc`）／`grep -v "^./"` が効かない環境／Task 5 の `find` 期待値／`kill %1`／`rmdir docs/design`／`infra/` の不在／baseline に enum が無い／`body.md` の置き場／数字の修正（tech-stack 参照 5＋1、ファイル数 286、整形 369）
- **計画由来の危険**: Task 6 の草稿はこの時点の推測を含む（Task 1〜5 の結果で索引と数字が変わる）。実装者は草稿を写すのではなく、
  各行の事実を現物で確かめてから書くこと（規律 3 を核に書く PR が規律 3 を破らないように）
