# 文書の枠組みと棚卸しの仕組み — 設計と Phase 4 の実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**破棄条件**: Phase 5（文書の作り直し）の完了 PR がマージされたら削除する。Part A の決定は
それまでに AGENTS.md（核）へ移し、Part B の作業記録は PR に残す。

作成: 2026-09-05 ／ 親計画: `docs/plans/2026-08-29-architecture-remediation.md` §5 Phase 4・5 ／
決定の経緯: 2026-09-05 のセッション（台帳 #85 のコメントに要点あり）

**Goal:** 文書を「読者ごとに正本 1 つ」へ作り直す枠組みを決め（Part A）、その枠組みが腐らないように
月 1 の棚卸しと、却下済みの案を差分で拾う仕組みを入れる（Part B = Phase 4）。

**Architecture:** 文書は 5 種類（核・決定・正本・使い捨て・倉庫）に分け、台帳はファイル 1 本にする。
却下済みの案の再提案は「読んで思い出す」のではなく、(1) 表現不可能にする、(2) 差分を索引に当てて
貼る、(3) 核の索引、の 3 層で拾う。棚卸しはプロジェクト固有スキル＋計測スクリプト＋月 1 の
Issue で回し、結果は台帳ファイルに 1 行ずつ書く。

**Tech Stack:** bash（スクリプト 2 本、上限 30 行と 100 行）／GitHub Actions（cron 1 本、PR コメント 1 本）／
mutmut 3.7.0（backend の mutation testing、CI には入れない）／`gh` CLI

**Spec:** Part A（この文書内）

## Global Constraints

- **新しい検査（止める仕組み）を作らない**（ADR-008）。作るのは「数える」「貼る」だけ。止めない
- **上限を先に決める**: `scripts/adr-touch.sh` は 30 行以内、`scripts/inventory.sh` は 100 行以内。
  超えたら直さず消す
- **例外・許可リストを持たない**。関係ない出力は無視する。除外規則を 1 つ足したらそれが ADR-008 の再演
- **照合するファイルは AGENTS.md「負債を作る行為」の一覧だけ**。新しい glob を発明しない
- **廃棄条件を先に書く**: 各仕組みの冒頭コメントに「これが起きたら消す」を置く
- **依存の追加は mutmut のみ**（開発依存）。根拠: 親計画 §5 Phase 4「テストの検証力そのもの」と
  `docs/verification-principles.md`「実効性は mutation kill rate で測る」
- **1 タスク 1 PR**。差分は 400 行 / 12 ファイルまで（削除は数えない）。作業は worktree
- コミットメッセージは既存に倣う（`docs:` / `build:` / `ci:` + 日本語）。末尾に
  `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`
- **完了と言う前に実物で確かめる**: スクリプトは実行して出力を見る、workflow は `workflow_dispatch` か
  PR で実際に発火させる

---

## Part A — 文書の枠組み（決定）

決定日 2026-09-05。異論が出たら**この節を書き直す**（追記しない）。

### A1. 文書は 5 種類

| 種類 | 読者 | 置き場所 | 寿命・上限 |
|---|---|---|---|
| **核** | エージェント（毎回読む） | `AGENTS.md`（`CLAUDE.md` は参照のみ） | 常設。**120 行**。製品の性質・実例つき規律・コマンド・ADR 索引・残作業・道具表 |
| **決定** | エージェント・開発者（触る領域のときだけ） | `docs/adr/ADR-00N-名前.md` | 常設。**未卒業 5 本以下、各 60 行以内** |
| **正本（読者ごとに 1 つ）** | 開発者／利用者・審査者／仕様／API | `README.md`／`docs/privacy-policy.md`・`docs/support.md`／`docs/spec/kotonoha-requirements.md` と実行可能なテスト／OpenAPI（`backend/tests/contract/openapi_baseline.json`） | 常設。**同じ内容を 2 箇所に書かない** |
| **使い捨て** | その作業の当事者 | `docs/plans/日付-名前.md`、`openspec/changes/`（CI が tracked を禁止済み）、PR 本文 | **冒頭に破棄条件を 1 行**。完了 PR のマージで削除。残っていたら棚卸しが拾う |
| **倉庫** | 履歴を調べる人だけ | `docs/archive/` | 無制限。現在の仕様として読まない（既存規則） |

- **OpenSpec は使い捨て。** `openspec/specs/` は恒久にしない（OpenSpec を通さない変更で乖離するため）。
  使うときは change 一式を使い捨てとして作り、残す仕様はテストか `kotonoha-requirements.md` へ移してから捨てる。
  既存の 2 capability は倉庫へ
- **台帳は `docs/ledger.md` 1 本。** GitHub Issue にしない（参照コストが利点を上回る。1 人＋エージェントの体制）
- **GitHub Issue の用途は 2 つだけ**: 月 1 の棚卸しの引き金（cron が立て、結果を台帳へ書いた PR が閉じる）と、
  外部の人とのやり取り。**作業の記録は PR**。Issue にタスクを書かない
- **一時的なまとめ**: エージェントに読ませるなら `docs/plans/`（破棄条件つき）、着手済みなら PR 本文、
  作業の入力にしないなら**リポジトリの外**（tracked にしない）

### A2. 台帳 `docs/ledger.md` の規則

- 1 問題 = 1 行 ＋ 出所（`ファイル:行` か PR/ADR 番号）。**経緯は書かない**
- 状態は行頭で表す: `- [ ]` 未対応 ／ `- [x]` 対応済み ／ `- [-]` 却下
- **フェーズ境界で見直す。** 残す理由を書けない `[ ]` は `[-]` にし、`[x]` と `[-]` は次のフェーズ境界で行ごと消す（履歴は git）
- レビューに渡す入力は `[ ]` の行だけ
- 入口／出口は `grep -c` で数える（棚卸しの計測項目）
- 末尾に「計測」節を置き、棚卸しの数字は**最新の 1 回だけ**残す（履歴は git）

### A3. ADR の規則

1. **作る条件**: 「この PR の外を縛る」「却下した案がある」「検査か再訪条件を書ける」の 3 つを**全部**満たすときだけ。
   満たさない決定は PR 本文に書く
2. **形**: 60 行以内。節は固定（背景と課題・制約・検討した選択肢・決定・決定理由と却下案・限界・検査・再訪条件）
3. **上限**: 未卒業 5 本。6 本目を書くときは先に 1 本を卒業させるか撤回する
4. **卒業**: 決定を守る検査が CI にある、または後続の決定に置き換えられた。索引に「検査: ○○」を残して
   本文を `docs/archive/adr/`（ファイル名は変えない）へ
5. **改訂は追記しない**。本文を書き直し、旧版は git 履歴に任せる
6. **索引は核に 1 決定 1 行**、卒業済みも含める。列は「決めたこと」「却下した案」「関わる行為」「検査」

卒業の初回判定（Phase 5 で実施）:

| ADR | 判定 | 根拠 |
|---|---|---|
| 001 ステートレス | 卒業 | `scripts/gates.sh`（DB ディレクトリ・依存の不在）と契約テスト |
| 003 エラーは型 | 卒業 | gates の grep、canary 全シンク検査、mypy strict |
| 004 設定は不変 | 卒業 | frozen 設定、起動 smoke、import 副作用検査 |
| 006 レイヤ依存 | 卒業 | import-linter（CI） |
| 008 負債ゲートを作らない | 卒業（却下の記録） | 「同種の仕組みを作る前に必読」は核の規律 1 行に残す |
| 002 レート制限 | 未卒業 | デプロイ側の契約（proxy 段数・上流での XFF 上書き）が未検査 |
| 005 frontend の 1 真実 | 未卒業 | 許可リスト検査は一部。今後の実装を縛る |
| 007 リリース基準 | 未卒業 | リリースまで生きる |
| 009 クラッシュ報告 | 未卒業 | リリースまで生きる |

### A4. 却下済みの案を拾う 3 層

「読んで思い出す」に精度は無い（ADR-008 を読んだうえで再演した実績がある）。引き金を差分に置く。

| 層 | 仕組み | 拾える範囲 |
|---|---|---|
| **1 表現不可能** | 却下案を実装すると必ず目立つファイルに手が入る状態を保つ（依存を消す、設定キーを消す、送信経路を持たない） | 「負債を作る行為」7 項目に現れる再提案すべて |
| **2 差分に索引を当てる** | PR の変更ファイルを 7 項目の既知のパスに当て、関わる ADR の索引行を PR コメントとして貼る。**止めない** | 同上。読む前に見せる |
| **3 核の索引** | AGENTS.md の索引（未卒業 5 本以下＋卒業済み 1 行）。着手前の影響範囲出しで変更予定パスを当てる | 差分になる前の会話段階。未卒業の決定だけ |

**層 2 の 4 規則**（ADR-008 の坂道を登れなくする）:

1. パターンを発明しない。照合するファイルは AGENTS.md「負債を作る行為」の一覧そのもの。索引側は「関わる行為」を書くだけ
2. 例外を一切持たない。関係ないコメントは無視する
3. 上限と廃棄条件を先に決める。照合表 15 行・スクリプト 30 行。ADR の増減と無関係に照合表を変える commit が 3 回になったら仕組みごと消す。半年間、貼られた行を見て判断が変わった実例がゼロなら消す
4. 止めない

**正直な穴**: パスに現れない再提案（同じ概念を UI ロジックだけで 2 つ目に実装する等）は 3 層のどれにも当たらない。
月 1 の棚卸し（人とエージェントの目視）が受け皿。索引にこの穴を書いておく。

### A5. 既存文書の行き先（Phase 5 で実施）

| 行き先 | 文書 |
|---|---|
| 核に書き直す | AGENTS.md（383 → 120 行。**白紙から書く**。入力は決定記録だけ） |
| 決定として残す | ADR-002・005・007・009（60 行の型に書き直し、「改訂」節は本文に吸収） |
| 倉庫（`docs/archive/adr/`） | ADR-001・003・004・006・008 |
| 開発者の正本に統合 | README.md ← tech-stack.md・SETUP.md・CONTRIBUTING.md の生きている部分。統合後の 3 本は倉庫へ |
| 仕様の正本 | `docs/spec/kotonoha-requirements.md`。API は OpenAPI baseline。`openspec/specs/` 2 本は倉庫へ、`openspec/config.yaml` の context は現状（DB 無し・`limits`）に直す |
| 利用者・審査者 | privacy-policy.md、support.md。**user-guide 5 本は判断待ち**（残すならヘルプ画面か support.md から到達させる、残さないなら倉庫） |
| 倉庫 | design/ 5 本、spec/acceptance-criteria・user-stories・mvp-requirements-original、articles、CHANGELOG、store-assets-guide、frontend の README 6 本 |
| 使い捨て | plans/ 2 本（親計画は Phase 5 完了で倉庫へ、残作業索引は条件 4 充足で削除）、この文書 |
| 判断待ち | verification-principles.md（実例 2 件を通った規律だけ核へ、残りは倉庫）、context-distillation.md（リポジトリ外に置く前提。tracked にしない） |

コードの整理（親計画 Phase 5）: `【】` 記法コメントは lib 1,253 行・test 4,879 行・integration_test 918 行、
🔵🟡🔴 記号は 2,503 行（2026-09-05 実測）。別 PR で機械的に除去し、`flutter analyze` と全テストで確かめる。

**Phase 5 の完了条件（親計画 §6 を差し替える）**: 核が 120 行以内／未卒業 ADR が 5 本以下で各 60 行以内／
`docs/` 直下と `docs/spec/` に残る現行文書が A1 の正本と使い捨てだけ／`docs/ledger.md` が存在し #85 が閉じている／
`scripts/inventory.sh` の「実在しないパス参照」が 0 件。

---

## Part B — Phase 4 の実装計画

### File Structure（到達点）

```
AGENTS.md                              ADR 索引を 5 列の表に（Task 1）。道具表の偽の行を直す（Task 4）
scripts/adr-touch.sh                   層 2 の照合。30 行以内（Task 1）
scripts/inventory.sh                   棚卸しの計測。100 行以内（Task 4）
.github/workflows/adr-touch.yml        PR の変更ファイルを照合してコメント（Task 1）
.github/workflows/inventory-reminder.yml  毎月 1 日に「棚卸し YYYY-MM」Issue を立てる（Task 2）
docs/ledger.md                         台帳。#85 を仕分けて作る（Task 3）
.claude/skills/inventory/SKILL.md      棚卸しの手順と観点（Task 4）
backend/requirements-dev.txt           mutmut==3.7.0（Task 5）
backend/pyproject.toml                 [tool.mutmut]（Task 5）
backend/Makefile                       mutation ターゲット（Task 5）
.gitignore                             backend/mutants/ ほか（Task 5）
```

### 実行順序

| Task | 内容 | 検証の実物 |
|---|---|---|
| 1 | ADR 索引の表 ＋ `adr-touch.sh` ＋ PR コメントの workflow | 手元で 3 入力を照合。PR で workflow が走ること |
| 2 | 棚卸しリマインダーの workflow ＋ `inventory` ラベル | `workflow_dispatch` で Issue が立つこと |
| 3 | `docs/ledger.md` を #85 から仕分けて作る。#85 を閉じる | `grep -c` の数字。#85 が closed |
| 4 | 棚卸しスキル ＋ `inventory.sh`。道具表の偽の行を直す | スクリプトの出力。スキルの構成 |
| 5 | mutmut を入れて 1 回回す | kill rate の数字。**Task 1 の workflow がこの PR にコメントを付ける**（層 2 の実証） |
| 6 | 棚卸しを 1 回回す（Phase 4 の完了条件） | 台帳に結果、棚卸し Issue が PR で閉じる。親計画の状態欄 |

---

### Task 1: ADR 索引を 5 列の表にし、差分を索引に当てる仕組みを入れる

**Files:**
- Modify: `AGENTS.md`（「決定（ADR）」の箇条書き 9 行を表に置き換える）
- Create: `scripts/adr-touch.sh`
- Create: `.github/workflows/adr-touch.yml`

**Interfaces:**
- Produces: AGENTS.md の表の行形式 `| ADR-00N | 決めたこと | 却下した案 | 関わる行為 | 検査 |`（Task 4 の `inventory.sh` と
  Task 6 が読む）。`scripts/adr-touch.sh`（stdin にファイルパス、stdout に該当行）
- 「関わる行為」の語彙は AGENTS.md「負債を作る行為」の 7 語に固定: `依存` `永続化` `設定キー` `可変グローバル` `公開ルート` `外部送信先` `権限`

- [ ] **Step 1: AGENTS.md の ADR 箇条書きを表に置き換える**

「### 決定（ADR — 実装前に、触る領域の ADR を必ず読むこと）」の下の `- **ADR-001** …` から `- **ADR-008** …` までを次に置き換える。
**却下した案の列は各 ADR 本文の「却下」「検討した選択肢」節から転記し、推測で書かない。** 下の値は 2026-09-05 時点の読み取りで、
転記時に本文と食い違えば本文に合わせる。

```markdown
| ADR | 決めたこと | 却下した案 | 関わる行為 | 検査 |
|---|---|---|---|---|
| ADR-001 | backend はステートレス。サーバー側にユーザー状態を持たない | DB で履歴・ログを保存 | 依存, 永続化, 公開ルート | scripts/gates.sh（DB ディレクトリと依存の不在） |
| ADR-002 | レート制限は単一インスタンス前提・プロセス内メモリ。総費用の上限はプロバイダの支出上限 | Redis 等の共有ストレージ（URI が秘密を運ぶ。8 周の原因） | 依存, 設定キー, 外部送信先 | 起動ガード（worker>1 で失敗）。デプロイ側契約は未検査 |
| ADR-003 | エラーは型（ErrorCode + SafeError）。自由文字列をログ・応答に載せない | 例外メッセージの秘匿関数 | 公開ルート, 外部送信先 | scripts/gates.sh（str(exc) 等 0 件）、canary 全シンク検査、mypy |
| ADR-004 | 設定は不変。Application Factory。import 時に資源を作らない | モジュールレベルの app / client | 設定キー, 可変グローバル | 起動 smoke（import 副作用ゼロ）、frozen 設定 |
| ADR-005 | frontend は 1 概念 1 真実。永続化の失敗は利用者に伝える | 各モデルに isFavorite フィールド | 永続化 | Hive スキーマ許可リスト検査（一部） |
| ADR-006 | レイヤ依存は import-linter で強制 | 規約だけで守る | 依存 | lint-imports（CI） |
| ADR-007 | リリース基準: ストア本公開、初回は AI 変換抜き可、クラッシュ報告のみ。条件を足すには改訂が要る | 日付を置く、β 配布 | 権限, 外部送信先 | 無し（リリースまで生きる） |
| ADR-008 | 負債ゲートを機械では作らない。**同種の仕組みを作る前に必読** | 許可リスト方式のゲート（3 周・4,600 行で収束せず） | 依存, 永続化, 設定キー, 可変グローバル, 公開ルート, 外部送信先, 権限 | 無し（却下の記録） |
| ADR-009 | クラッシュ報告はストア標準に依拠し、アプリからは何も送らない | Crashlytics、Sentry、自前送信先、オプトイン | 依存, 外部送信先, 権限 | 無し（送信経路が存在しないこと自体が担保） |

**パスに現れない再提案（同じ概念を UI ロジックだけで 2 つ目に実装する等）は、この表でも `scripts/adr-touch.sh` でも拾えない。**
月 1 の棚卸し（`inventory` スキル）が受け皿。
```

表の直後の「詳細と却下案は `docs/adr/` を参照。」は残す。

- [ ] **Step 2: `scripts/adr-touch.sh` を書く（30 行以内）**

```bash
#!/usr/bin/env bash
# 変更ファイルを AGENTS.md「負債を作る行為」7 項目に当て、関わる ADR の索引行を印字する。
# 止めない。例外を持たない。パターンを足さない（足すのは AGENTS.md の一覧が変わったときだけ）。
# 廃棄条件: 30 行を超えた／ADR の増減と無関係な変更 commit が 3 回／半年間、判断が変わった実例ゼロ。
# 使い方: git diff --name-only origin/main...HEAD | scripts/adr-touch.sh
set -euo pipefail
INDEX="${ADR_INDEX:-$(dirname "$0")/../AGENTS.md}"
acts=""
while IFS= read -r f; do
  case "$f" in
    */requirements*.txt|*/pubspec.yaml|*/pyproject.toml|*/Podfile|*/build.gradle.kts) acts="$acts 依存" ;;
    */lib/shared/models/*_adapter.dart|*/lib/core/utils/hive_init.dart) acts="$acts 永続化" ;;
    .env.example|*/.env.example|*/backend/app/config.py) acts="$acts 設定キー" ;;
    */backend/app/main.py|*/backend/app/routes.py) acts="$acts 公開ルート 可変グローバル" ;;
    */backend/app/ai/providers.py|*/lib/features/ai_conversion/data/*) acts="$acts 外部送信先" ;;
    */AndroidManifest.xml|*/Info.plist) acts="$acts 権限" ;;
  esac
done
[ -z "$acts" ] && exit 0
for a in $(printf '%s\n' $acts | sort -u); do
  grep -E '^\| ADR-[0-9]+ \|' "$INDEX" | awk -F'|' -v a="$a" '$5 ~ a { print }'
done | sort -u
```

`chmod +x scripts/adr-touch.sh`。`wc -l` が 30 以下であることを確認する。

- [ ] **Step 3: 手元で 3 入力を照合する（赤→緑の代わりに期待出力を先に書く）**

期待: `backend/requirements.txt` → ADR-001・002・006・008 の 4 行。`frontend/kotonoha_app/android/app/src/main/AndroidManifest.xml` → ADR-007・008・009 の 3 行。
`frontend/kotonoha_app/lib/features/character_board/presentation/home_screen.dart` → 出力なし。

```bash
printf 'backend/requirements.txt\n' | scripts/adr-touch.sh | cut -d'|' -f2
printf 'frontend/kotonoha_app/android/app/src/main/AndroidManifest.xml\n' | scripts/adr-touch.sh | cut -d'|' -f2
printf 'frontend/kotonoha_app/lib/features/character_board/presentation/home_screen.dart\n' | scripts/adr-touch.sh; echo "exit=$?"
```

期待どおりでなければ表の「関わる行為」列を直す（スクリプト側に例外を足さない）。

- [ ] **Step 4: `.github/workflows/adr-touch.yml` を書く**

```yaml
name: ADR touch

# PR の変更ファイルを AGENTS.md「負債を作る行為」に当て、関わる ADR の索引行をコメントで貼る。止めない。
# 廃棄条件は scripts/adr-touch.sh の冒頭と同じ。
on:
  pull_request:
    types: [opened, synchronize, reopened]

permissions:
  contents: read
  pull-requests: write

jobs:
  adr-touch:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
        with:
          fetch-depth: 0

      - name: Match changed files against the ADR index
        id: match
        run: |
          git diff --name-only "origin/${{ github.base_ref }}...HEAD" | scripts/adr-touch.sh > touched.txt
          echo "n=$(wc -l < touched.txt | tr -d ' ')" >> "$GITHUB_OUTPUT"

      - name: Create or update the comment
        if: steps.match.outputs.n != '0'
        env:
          GH_TOKEN: ${{ github.token }}
          REPO: ${{ github.repository }}
          PR: ${{ github.event.pull_request.number }}
        run: |
          {
            echo '<!-- adr-touch -->'
            echo 'この差分は次の決定に触れています（AGENTS.md の ADR 索引。止めません。改訂するなら本文を読んで書き直すこと）:'
            echo
            echo '| ADR | 決めたこと | 却下した案 | 関わる行為 | 検査 |'
            echo '|---|---|---|---|---|'
            cat touched.txt
          } > body.md
          id=$(gh api "repos/$REPO/issues/$PR/comments" --jq '[.[] | select(.body | startswith("<!-- adr-touch -->"))][0].id // empty')
          if [ -n "$id" ]; then
            gh api -X PATCH "repos/$REPO/issues/comments/$id" -F body=@body.md > /dev/null
          else
            gh pr comment "$PR" --repo "$REPO" --body-file body.md
          fi
```

- [ ] **Step 5: コミットして PR を作る。PR の CI で workflow が走ること（この PR 自身は 7 項目に触れないのでコメントは付かない）を確認する**

```bash
git checkout -b ci/adr-touch
git add AGENTS.md scripts/adr-touch.sh .github/workflows/adr-touch.yml
git commit -m "ci: ADR 索引を 5 列の表にし、PR の差分を索引に当ててコメントする（止めない）(Phase 4 / Task 1)"
git push -u origin ci/adr-touch
gh pr create --title "ci: PR の差分を ADR 索引に当ててコメントする（止めない）" --body-file <(cat <<'PR'
## 何を
- AGENTS.md の ADR 一覧を 5 列の表（決めたこと・却下した案・関わる行為・検査）にした
- `scripts/adr-touch.sh`（30 行以内）: 変更ファイルを「負債を作る行為」7 項目に当て、関わる ADR の行を印字
- `.github/workflows/adr-touch.yml`: PR ごとに照合し、該当があればコメントを 1 本（作成または更新）

## 4 規則（ADR-008 の再演を防ぐ）
パターンを発明しない／例外を持たない／上限と廃棄条件を先に書く／止めない。詳細は `docs/plans/2026-09-05-docs-framework-and-inventory.md` A4。

## 検証
手元で 3 入力（requirements.txt / AndroidManifest.xml / home_screen.dart）を照合し期待どおり。
この PR 自身は 7 項目に触れないためコメントは付かない。付くことの実証は mutmut を入れる PR（Task 5）で行う。

🤖 Generated with [Claude Code](https://claude.com/claude-code)
PR
)
```

`gh pr checks` で `ADR touch` ジョブが pass することを確認する。

---

### Task 2: 月 1 の棚卸しリマインダー

**Files:**
- Create: `.github/workflows/inventory-reminder.yml`

**Interfaces:**
- Produces: 毎月 1 日 09:00 JST に `inventory` ラベルの Issue「棚卸し YYYY-MM」。Task 6 の PR が `Closes #N` で閉じる

- [ ] **Step 1: ラベルを作る**

```bash
gh label create inventory --color 0E8A16 --description "月1の棚卸し。結果は docs/ledger.md へ PR で書き、その PR がこの Issue を閉じる"
```

- [ ] **Step 2: workflow を書く**

```yaml
name: Inventory reminder

# 毎月 1 日に棚卸しの Issue を立てる。数えるのは機械、判断は人。
# 廃棄条件: 立てた Issue が 3 か月連続で閉じられなかったら、棚卸しが回っていないので仕組みごと見直す。
on:
  schedule:
    - cron: '0 0 1 * *'   # 09:00 JST
  workflow_dispatch:

permissions:
  issues: write

jobs:
  remind:
    runs-on: ubuntu-latest
    steps:
      - name: Open this month's inventory issue (idempotent)
        env:
          GH_TOKEN: ${{ github.token }}
          REPO: ${{ github.repository }}
        run: |
          title="棚卸し $(date -u +%Y-%m)"
          n=$(gh issue list --repo "$REPO" --label inventory --state open --search "\"$title\" in:title" --json number --jq 'length')
          [ "$n" != "0" ] && { echo "already open"; exit 0; }
          gh issue create --repo "$REPO" --title "$title" --label inventory --body "$(cat <<'EOF'
月 1 の棚卸し。手順は `.claude/skills/inventory/SKILL.md`、計測は `scripts/inventory.sh`。

- 結果は `docs/ledger.md` に 1 問題 1 行で書き、「計測」節の数字を更新する
- その PR の本文に `Closes #<この Issue 番号>` を書く。ここには結果を書かない（作業の記録は PR）
- 直すのは棚卸しの外。ここでは問題を数えるだけ
EOF
)"
```

- [ ] **Step 3: コミット・PR・マージ後に `workflow_dispatch` で発火させる**

```bash
git checkout -b ci/inventory-reminder
git add .github/workflows/inventory-reminder.yml
git commit -m "ci: 毎月 1 日に棚卸しの Issue を立てる (Phase 4 / Task 2)"
git push -u origin ci/inventory-reminder
gh pr create --title "ci: 毎月 1 日に棚卸しの Issue を立てる" --body "月 1 の棚卸しの引き金。cron が \`inventory\` ラベルの Issue を立て、結果を \`docs/ledger.md\` へ書いた PR が閉じる。同月に open のものがあれば立てない。廃棄条件は workflow 冒頭。

🤖 Generated with [Claude Code](https://claude.com/claude-code)"
```

マージ後: `gh workflow run inventory-reminder.yml` → 1 分待って `gh issue list --label inventory` に「棚卸し 2026-09」が出ること。
**この Issue は Task 6 の PR で閉じる**（消さない）。

---

### Task 3: 台帳 `docs/ledger.md` を #85 から仕分けて作る

**Files:**
- Create: `docs/ledger.md`
- Modify: `AGENTS.md`（`Issue #85` への言及 1 箇所（ADR-007 の要約行）を `docs/ledger.md` に）

**Interfaces:**
- Produces: `docs/ledger.md` の行形式 `- [ ] L-NN 1 行の問題 — 出所`。Task 4 の `inventory.sh` が `grep -c '^- \[ \]'` 等で数える。
  末尾の「## 計測」節に表を置く（Task 6 が書く）

- [ ] **Step 1: #85 の未対応項目を全部取り出す**

```bash
gh issue view 85 --json body,comments --jq '[.body, (.comments[].body)] | join("\n")' > /tmp/issue85.md
grep -n '^- \[ \]' /tmp/issue85.md | wc -l    # 2026-09-05 時点で 55 行
grep -o 'L-[0-9][0-9]' /tmp/issue85.md | sort -u | wc -l
```

- [ ] **Step 2: 3 つに仕分ける（A1 の規則 §9.2）**

各 L 番号を次のどれかにする。判断に迷ったら「却下」（既定が却下。残すには理由が要る）。

| 分類 | 行き先 | 目安 |
|---|---|---|
| リリース（ADR-007 条件 4）に効く | `[ ]` で残す | L-51 サポート連絡先、L-52 アップロード鍵、L-57 実機でのバックアップ確認 |
| Phase 5 で消える | `[ ]` で残し、出所に「Phase 5」と書く | L-04・L-08・L-53（文書）、L-56（テストの検証力）、L-39（Phase 5 の後） |
| 記録して受け入れたもの（対応不要と書かれている） | `[-]` 却下 | L-47・L-48・L-50 など |
| 残り | `[-]` 却下。1 行の理由は書かない | 大半がここに来るのが正常 |

- [ ] **Step 3: `docs/ledger.md` を書く**

```markdown
# 台帳 — 後回しにした問題と判断待ち

規則: 1 問題 1 行＋出所。経緯は書かない。`[ ]` 未対応 ／ `[x]` 対応済み ／ `[-]` 却下。
フェーズ境界で見直し、`[x]` と `[-]` は次の境界で行ごと消す（履歴は git）。レビューに渡すのは `[ ]` だけ。
読むのは必要なときだけ（核には数えない）。#85（2026-09-05 に閉鎖）から仕分けて作った。

## 未対応
- [ ] L-51 サポート連絡先が `support@kotonoha-app.example.com` のまま（RFC 2606 の予約ドメイン） — docs/support.md, docs/privacy-policy.md。ADR-007 条件 4
- [ ] L-52 Android のアップロード鍵が無い（AAB・mapping・シンボルは #97 で解決済み） — .github/workflows/release.yml。開発者登録後
- [ ] L-57 Android 12 以上の実機で、自動バックアップにアプリデータが載らないことを確認 — #99
（…Step 2 の仕分け結果をここに並べる。Phase 5 行きは出所に「Phase 5」を付ける…）

## 判断待ち
- [ ] L-39 ADR-005 の却下理由と連鎖削除の矛盾 — docs/adr/ADR-005。Phase 5 の後に扱う
- [ ] L-58 の残り: backend 公開の 4 条件（支出上限・デプロイと proxy 段数・端末キー配布・実プロバイダでの往復） — ADR-002, AGENTS.md「レート制限」

## 却下（次のフェーズ境界で削除）
- [-] L-47 許可リスト検査は起動時の共有登録経路しか守らない — 記録して受け入れ済み
（…）

## 計測（棚卸しの記録。最新の 1 回だけ残す）
| 日付 | 核 | 未卒業 ADR | 台帳 未対応/対応済/却下 | 出力ゼロの仕組み | 実在しないパス参照 | kill rate |
|---|---|---|---|---|---|---|
| （Task 6 で記入） | | | | | | |
```

- [ ] **Step 4: 数える**

```bash
grep -c '^- \[ \]' docs/ledger.md; grep -c '^- \[x\]' docs/ledger.md; grep -c '^- \[-\]' docs/ledger.md
```

3 つの合計が Step 1 の未対応数と一致すること（取りこぼしなし）。

- [ ] **Step 5: AGENTS.md の `Issue #85` を差し替え、コミット・PR。マージ後に #85 を閉じる**

AGENTS.md で `Issue #85` を含む 1 行（ADR-007 の要約行）の `台帳（Issue #85）` を `台帳（docs/ledger.md）` にする（2026-09-05 に grep で 1 箇所と確認）。

```bash
git checkout -b docs/ledger-file
git add docs/ledger.md AGENTS.md
git commit -m "docs: 台帳を docs/ledger.md に移し、#85 を仕分ける (Phase 4 / Task 3)"
git push -u origin docs/ledger-file
gh pr create --title "docs: 台帳を docs/ledger.md に移し、#85 を仕分ける" --body "台帳を GitHub Issue からファイル 1 本にする（決定は docs/plans/2026-09-05-docs-framework-and-inventory.md A1・A2）。#85 の未対応 55 行を、リリースに効く／Phase 5 で消える／却下の 3 つに仕分けた。合計は #85 の未対応数と一致。マージ後に #85 を閉じる（削除はしない）。

🤖 Generated with [Claude Code](https://claude.com/claude-code)"
```

マージ後:

```bash
gh issue close 85 --comment "台帳を docs/ledger.md に移した（2026-09-xx、PR #xx）。未対応項目はすべて仕分け済み。以後の問題はファイルへ。この Issue は履歴として残す"
```

---

### Task 4: 棚卸しスキルと計測スクリプト

**Files:**
- Create: `.claude/skills/inventory/SKILL.md`
- Create: `scripts/inventory.sh`
- Modify: `AGENTS.md`（道具表の 3 行）

**Interfaces:**
- Consumes: Task 1 の索引の表、Task 3 の `docs/ledger.md`
- Produces: `scripts/inventory.sh`（引数なし、stdout に節ごとの数字）。スキル名 `inventory`

- [ ] **Step 1: `scripts/inventory.sh` を書く（100 行以内。数えるだけ。判断しない）**

```bash
#!/usr/bin/env bash
# 棚卸しの計測。数字を出すだけで判断しない。廃棄条件: 100 行を超えたら直さず消す（検査を作り始めている）。
# 使い方: scripts/inventory.sh   （リポジトリルートで。gh が認証済みであること）
set -uo pipefail
cd "$(dirname "$0")/.."
h() { printf '\n== %s\n' "$1"; }

h "文書の行数（核 / 決定 / 正本）"
wc -l AGENTS.md docs/adr/*.md README.md docs/spec/kotonoha-requirements.md docs/privacy-policy.md docs/support.md 2>/dev/null | tail -1
printf 'AGENTS.md %s 行（上限 120）／未卒業 ADR %s 本（上限 5）\n' "$(wc -l < AGENTS.md)" "$(ls docs/adr/ADR-*.md 2>/dev/null | wc -l | tr -d ' ')"
for f in docs/adr/ADR-*.md; do n=$(wc -l < "$f"); [ "$n" -gt 60 ] && printf '  60 行超: %s (%s)\n' "$f" "$n"; done

h "台帳 docs/ledger.md（未対応 / 対応済み / 却下）"
if [ -f docs/ledger.md ]; then
  printf '%s / %s / %s\n' "$(grep -c '^- \[ \]' docs/ledger.md)" "$(grep -c '^- \[x\]' docs/ledger.md)" "$(grep -c '^- \[-\]' docs/ledger.md)"
else echo "docs/ledger.md が無い"; fi

h "出力ゼロの仕組み（90 日で実行 0 回の workflow、痕跡の無いフック）"
since=$(date -u -d '90 days ago' +%F 2>/dev/null || date -u -v-90d +%F)
for w in .github/workflows/*.yml; do
  n=$(gh run list --workflow="$(basename "$w")" --created ">=$since" --limit 1 --json databaseId --jq 'length' 2>/dev/null || echo '?')
  [ "$n" = "0" ] && printf '  実行 0: %s\n' "$w"
done
marker=$(grep -m1 -o 'MARKER=.*' .claude/hooks/activity-value-check.sh | cut -d= -f2- | tr -d '"')
[ -n "$marker" ] && { eval "m=$marker"; [ -e "$m" ] && echo "  Stop フック: 痕跡あり ($m)" || echo "  Stop フック: 痕跡なし（廃棄条件: 発火ゼロで 1 か月）"; }

h "道具の実在（AGENTS.md に載る plugin:skill）"
for t in $(grep -o '`[a-z-]*:[a-z:_-]*`' AGENTS.md | tr -d '`' | sort -u); do
  p=${t%%:*}; s=${t#*:}; s=${s//:/\/}
  en=$(python3 -c "import json,sys;d=json.load(open('$HOME/.claude/settings.json')).get('enabledPlugins',{});print(any(k.startswith('$p@') and v for k,v in d.items()))")
  ex=$(ls -d "$HOME"/.claude/plugins/cache/*/"$p"/*/skills/"$s" "$HOME"/.claude/plugins/cache/*/"$p"/*/commands/"$s".md "$HOME"/.claude/plugins/cache/"$p"/"$p"/*/skills/"$s" 2>/dev/null | head -1)
  printf '  %-45s 有効=%-5s 定義=%s\n' "$t" "$en" "${ex:+あり}${ex:-なし}"
done

h "実在しないパス参照（核・決定・README・台帳）"
grep -ho '`[A-Za-z0-9_./-]*/[A-Za-z0-9_./-]*`' AGENTS.md docs/adr/*.md README.md docs/ledger.md 2>/dev/null | tr -d '`' | sort -u \
  | while read -r p; do case "$p" in *'*'*|http*) continue;; esac; [ -e "$p" ] || printf '  無い: %s\n' "$p"; done

h "生成時コメントの残量（【】 / 🔵🟡🔴）"
for d in frontend/kotonoha_app/lib frontend/kotonoha_app/test frontend/kotonoha_app/integration_test backend/app; do
  printf '  %-45s 【】=%-5s 記号=%s\n' "$d" "$(grep -r '【' "$d" --include='*.dart' --include='*.py' | wc -l | tr -d ' ')" "$(grep -r '🔵\|🟡\|🔴' "$d" --include='*.dart' --include='*.py' | wc -l | tr -d ' ')"
done

h "使い捨て文書（docs/plans）と破棄条件"
for f in docs/plans/*.md; do grep -q '破棄' "$f" && printf '  条件あり: %s\n' "$f" || printf '  条件なし: %s\n' "$f"; done
```

`chmod +x scripts/inventory.sh`。`wc -l` が 100 以下であることを確認する。

- [ ] **Step 2: 実行して全節に数字が出ることを確認する**

```bash
scripts/inventory.sh
```

期待: 「出力ゼロ」に `release.yml` は出ない（#97 以降 PR で走る `Build App Bundle` は flutter.yml。release.yml は tag 契機なので 0 のまま出るはず。これは正しい観測なので消さない）。「道具の実在」に tsumiki の 5 件が `有効=False` で出る。「実在しないパス参照」に `docs/design/kotonoha/api-endpoints.md` 等は出ない（存在する）。

- [ ] **Step 3: `.claude/skills/inventory/SKILL.md` を書く**

```markdown
---
name: inventory
description: 月 1 の棚卸し。同じ概念の 2 つ目の実装、仕様と実装の乖離、守りの仕組み（道具・検査・文書）の陳腐化、テストの検証力を全体から見て数え、docs/ledger.md に 1 行ずつ書く。毎月 1 日に立つ「棚卸し YYYY-MM」Issue から使う。差分レビューでは見つからないものを見つける工程。
---

# 棚卸し

**数えるのは機械、判断は人。ここでは直さない。** 見つけた問題は `docs/ledger.md` に 1 行で書き、直すのは別の作業。

## 手順

1. `scripts/inventory.sh` を実行し、出力を手元に置く（数字はすべてここから取る。推測で書かない）
2. 下の観点を順に当てる。各観点で「該当なし」も明示する
3. `docs/ledger.md` に追記する。新しい問題は `- [ ] L-NN 1 行 — 出所`。解消していた `[ ]` は `[x]` に。「計測」節の表を最新 1 回分に書き換える
4. PR を作り、本文に `Closes #<棚卸し Issue>` と、観点ごとの結論を 1 行ずつ書く（作業の記録は PR。Issue には書かない）

## 観点

### 1. コードの重複・死蔵
- 同じ概念を扱う provider・ディレクトリが 2 つ以上ないか（`grep -rn 'Provider<' lib | sort` で名前を並べて目視）
- 定義のみで参照ゼロの型・関数はないか（backend は `ruff` の未使用、frontend は名前で `grep -rn` して定義以外の出現が 0 のもの）

### 2. 仕様と実装の乖離
- privacy-policy.md・ADR の記述と実装が食い違っていないか（保存先、送信先、権限。manifest と `Info.plist` を現物で見る）
- `docs/spec/kotonoha-requirements.md` の各要件に対応するテストがあるか。無い要件は 1 行で挙げる
- 置き換えられた決定が未卒業のまま残っていないか（索引の「検査」列が埋まった ADR は卒業させる）

### 3. 守りの仕組みの陳腐化（★ 最重要）
- AGENTS.md の道具表: `inventory.sh` の「道具の実在」で 有効=False か 定義=なし の行を表から降ろす（消さない。降ろすだけ）
- 索引の「関わる行為」列と `scripts/adr-touch.sh` の case が、実在するパスを指しているか
- 完了条件の grep（`backend/scripts/gates.sh`）が、いまも意味のある対象を指しているか
- 「負債を作る行為」7 項目の受け皿（層 1・3・5）が動いているか。層 2 の PR コメントは直近 1 か月で何回付いたか、それで判断が変わった実例はあるか（半年ゼロなら仕組みを消す）
- `inventory.sh` の「実在しないパス参照」「出力ゼロの仕組み」「破棄条件なし」の各行
- `openspec/changes/` に tracked ファイルが無いか（CI で見ているが再確認）

### 4. テストの検証力
- 実装のスナップショットになっているテストの兆候: 外部ライブラリの定数を期待値にハードコード／診断文言の完全一致／例外クラス名の期待（`grep -rn "assert.*==.*'" backend/tests`、`expect(.*, '` の文言を目視）
- backend の mutation kill rate（`cd backend && PATH=.venv/bin:$PATH make mutation`。対象は config / errors / auth / ratelimit）。前回より下がっていたら原因を 1 行

### 5. 計測（context-distillation §2）
- 核の行数（上限 120）、未卒業 ADR の本数（上限 5）と各行数（上限 60）
- 台帳の 未対応 / 対応済み / 却下（入口・出口比）
- 出力ゼロの仕組み（90 日）

## 出力の型（docs/ledger.md「計測」節）

| 日付 | 核 | 未卒業 ADR | 台帳 未対応/対応済/却下 | 出力ゼロの仕組み | 実在しないパス参照 | kill rate |
|---|---|---|---|---|---|---|
```

- [ ] **Step 4: AGENTS.md の道具表を直す**

「いつでも守ること」の `負債を作る行為をその場で検出する | PostToolUse フック` の行を
`| 負債を作る行為に気づく | **層 2（`scripts/adr-touch.sh` が PR にコメント）**。機械は止めない（ADR-008） |` に。
「段階ごと」の棚卸し 2 行（`未整備。プロジェクト固有スキルとして作る` と `同上（月1）`）を `inventory`（`.claude/skills/inventory/SKILL.md`。毎月 1 日の Issue から） に。

- [ ] **Step 5: コミット・PR**

```bash
git checkout -b feat/inventory-skill
git add scripts/inventory.sh .claude/skills/inventory/SKILL.md AGENTS.md
git commit -m "feat: 月 1 の棚卸しスキルと計測スクリプトを足す (Phase 4 / Task 4)"
git push -u origin feat/inventory-skill
gh pr create --title "feat: 月 1 の棚卸しスキルと計測スクリプトを足す" --body "親計画 Phase 4「定期的な棚卸し」。観点は親計画の 3 群＋テストの検証力＋計測（context-distillation §2 の数字）。\`scripts/inventory.sh\` は数えるだけ（100 行以内、廃棄条件つき）。AGENTS.md の道具表で実在しない PostToolUse フックの行を直し、棚卸しの行をこのスキルにした。

実行結果（この PR 時点）:
（scripts/inventory.sh の出力を貼る）

🤖 Generated with [Claude Code](https://claude.com/claude-code)"
```

---

### Task 5: mutmut を入れて 1 回回す（層 2 の実証を兼ねる）

**Files:**
- Modify: `backend/requirements-dev.txt`（`mutmut==3.7.0` を追記）
- Modify: `backend/pyproject.toml`（`[tool.mutmut]`）
- Modify: `backend/Makefile`（`mutation` ターゲット）
- Modify: `.gitignore`（`backend/mutants/`、`backend/.mutmut-cache`）

**Interfaces:**
- Produces: `make mutation`（backend/ で、PATH に `.venv/bin`）。kill rate は `mutmut results` の出力から読む

- [ ] **Step 1: 依存と設定を足す**

```toml
# backend/pyproject.toml に追記
[tool.mutmut]
paths_to_mutate = ["app/config.py", "app/errors.py", "app/auth.py", "app/ratelimit.py"]
tests_dir = ["tests/"]
```

```make
mutation:  ## mutation testing（config / errors / auth / ratelimit）。kill rate は docs/ledger.md の計測へ。CI には入れない（ADR-008）
	mutmut run
	mutmut results
```

`.gitignore` に `backend/mutants/` と `backend/.mutmut-cache` を足す。`backend/Makefile` の `.PHONY` に `mutation` を足す。

- [ ] **Step 2: 入れて回す**

```bash
cd backend && .venv/bin/pip install -r requirements-dev.txt && PATH="$PWD/.venv/bin:$PATH" make mutation 2>&1 | tail -30
```

mutmut 3 は `mutants/` を作って対象をコピーし、mutant ごとに pytest を走らせる。**設定キーや実行方法が 3.7.0 の実物と違ったら、`mutmut --help` と `mutants/` の中身を見て直す**（推測で直さない）。
出力の `killed / survived / total` を控える。目安の所要時間は 10〜30 分。

- [ ] **Step 3: 生き残った mutant を 3 件だけ読み、テストが何を見ていないかを台帳に 1 行ずつ書く（直さない）**

`mutmut show <id>` で差分を見る。例: 「`ratelimit.py` の `>=` → `>` が生存 — 境界値のテストが無い」。

- [ ] **Step 4: コミット・PR。層 2 のコメントが付くことを確認する**

```bash
git checkout -b build/mutmut
git add backend/requirements-dev.txt backend/pyproject.toml backend/Makefile .gitignore docs/ledger.md
git commit -m "build: mutmut を入れて kill rate を測る（config / errors / auth / ratelimit）(Phase 4 / Task 5)

依存の追加（AGENTS.md「負債を作る行為」）。根拠: 親計画 §5 Phase 4「テストの検証力そのもの」、
docs/verification-principles.md「実効性は mutation kill rate で測る」。開発依存のみ。CI には入れない。"
git push -u origin build/mutmut
gh pr create --title "build: mutmut を入れて kill rate を測る" --body "…（kill rate と生存 3 件の要約）…"
```

**この PR は `backend/requirements-dev.txt` に触れるので、Task 1 の workflow が ADR-001・002・006・008 の行をコメントで貼るはず。**
貼られたら層 2 の実証として PR 本文に 1 行書く。貼られなければ Task 1 に戻る（これが赤）。

---

### Task 6: 棚卸しを 1 回回し、Phase 4 を閉じる

**Files:**
- Modify: `docs/ledger.md`（結果と計測）
- Modify: `AGENTS.md`（道具表で降ろす行）
- Modify: `docs/plans/2026-08-29-architecture-remediation.md`（状態欄: Phase 4 完了）
- Modify: `docs/plans/2026-09-02-remaining-work.md`（Phase 4 の行）

- [ ] **Step 1: Task 2 で立てた「棚卸し 2026-09」Issue を入力に、`inventory` スキルの手順を最初から最後まで実行する**

観点 1〜5 すべてに結論を出す。2026-09-05 時点で既に分かっている入力: `openspec/config.yaml` の context が DB 時代のまま／
AGENTS.md の道具表に無効な tsumiki 5 件／Stop フックの発火痕跡／release.yml の実行 0（tag 契機なので正常）／
`【】` 7,050 行と記号 2,503 行。

- [ ] **Step 2: 台帳に書き、計測の表を埋める**

- [ ] **Step 3: 親計画の状態欄を「Phase 0・1・2・3・4 完了（2026-09-xx）。次は Phase 5」に。残作業索引の Phase 4 行を「完了」に**

- [ ] **Step 4: PR を作る。本文に `Closes #<棚卸し Issue>`**

```bash
git checkout -b docs/inventory-2026-09
git add docs/ledger.md AGENTS.md docs/plans/2026-08-29-architecture-remediation.md docs/plans/2026-09-02-remaining-work.md
git commit -m "docs: 棚卸し 2026-09 の結果を台帳に書き、Phase 4 を閉じる (Phase 4 / Task 6)"
```

**Phase 4 の完了条件（親計画 §6）**: 棚卸しがスキルとして存在し 1 回実施して記録されている／AGENTS.md の道具リストが全件実在
（実在しないものは降ろした）／mutmut が対象領域で回り kill rate が記録されている。加えて A4 層 2 が PR で実際にコメントを付けた実績 1 件。

---

### Self-review（計画作成時に実施）

- **Spec coverage**: A1（5 種類）→ Task 3（台帳ファイル）と Phase 5 計画へ。A2 → Task 3。A3 → 表の形は Task 1、卒業は Phase 5。
  A4 → Task 1（層 2）、層 1 は Phase 2 で実施済み、層 3 は Task 1 の表。A5 → Phase 5 計画（本書の破棄条件に含める）。
  親計画 Phase 4 の 2 項目（棚卸し・mutmut）→ Task 4・5・6。「誤った仕様を固定したテストを検出する」は Task 4 観点 4 に吸収（別スキルは作らない）
- **Placeholder scan**: Task 5 の PR 本文「…（kill rate と生存 3 件の要約）…」は実測値を入れる箇所。Task 3 の「（…）」は
  Step 2 の仕分け結果を入れる箇所。他に TBD 無し
- **Type consistency**: 索引の行形式（5 列、`| ADR-00N |` 始まり）を Task 1 で定義し、`adr-touch.sh` の `$5`（関わる行為）と
  `inventory.sh` の `grep` が同じ形式を前提にしている。台帳の行頭 `- [ ]` / `- [x]` / `- [-]` を Task 3 で定義し、
  `inventory.sh` が同じ 3 種を数える。スキル名 `inventory`、ラベル名 `inventory`、Issue 題名「棚卸し YYYY-MM」を Task 2・4・6 で統一
