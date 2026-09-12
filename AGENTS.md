# AGENTS.md

エージェント（Claude Code / Codex など）が毎回読む核。**120 行以内。超えたら足す前に降ろす。**
決定は `docs/adr/`（索引は下）、文書の規則は ADR-010、後回しは `docs/ledger.md`。開発者向けの前提と手順は README、`CLAUDE.md` はこの文書への参照だけ。

## 製品

**kotonoha（ことのは）** — 文字盤コミュニケーション支援アプリ（Flutter、タブレット向け）。脳梗塞・ALS・筋疾患などで発話が困難な人が、少ない操作で、適切な丁寧さで、安全に伝える。
**利用者は発話で訂正できず、データは端末内（Hive）にしか無い。** 文字盤・定型文・履歴・お気に入り・TTS・緊急ボタンはオフラインで動く。AI 変換だけがオンライン（backend は FastAPI のステートレスなプロキシ。DB 無し）。
数字: TTS 開始 1 秒以内、タップ反映 100ms 以内、AI 変換平均 3 秒以内、タップ目標 44px 以上（推奨 60px）、フォント 3 段階、テーマ 3 種（高コントラストは WCAG 2.1 AA の 4.5:1）。iOS 14 / Android 10 / Web 最新版。
MVP 外: クラウド同期・アカウント・視線入力やスイッチ・音声認識・画像やスタンプ・ビデオ通話・多言語ほか。仕様の正本は `docs/spec/kotonoha-requirements.md`（全 10 項目はその「MVP範囲外」節）。

## 規律（すべて実際に踏んだ穴から）

1. **完了と言う前に実物を動かす。** 8 周のレビュー往復・418 テスト緑・7 体のサブエージェント分析を通じて誰もアプリを起動せず、`%` を含むパスワードで接続できないバグが生き残った。起動・HTTP 応答・実 box・描画されたウィジェットで確かめる（`superpowers:verification-before-completion`）
2. **観測点を疑う。** `flutter drive … | tail` の終了コードを見て「E2E 緑」と言った。主張の直前に「この観測点は、壊れていたら赤くなるか」を問い、答えられなければ意図的に壊して赤を見る。パイプの終了コード・部分パスでの解析・自作の grep 集計は、いずれも観測点をすり替える
3. **自分（や前のセッション）が書いた文書・コメント・メモリを事実として扱わない。** メモリの「未マージ 6 本」は数日古いまま生きた。数字・パス・行番号は使う直前に現物で確かめる。「実測確認済み」と書くなら再現手段（コード片・出力）を添える
4. **着手前に触るファイルを列挙して数え、下の索引の未卒業 5 行ごとに「この変更はこの決定に触れるか」を yes/no で PR 本文に書く。** yes の行だけ本文を読む。どの行にも当たらなければ、実装ではなく決定から始めるかを問う（8 周はこの工程が無かった）
5. **修正の前にテストを書き、赤を見る。** 後に書くと、修正が効く観測点を無意識に選ぶ（`str(exc)` だけを見るテストで、生きている漏えいを「対処済み」と証明した）。完全一致アサーションを書かない。モックは外部 SDK とネットワーク境界にだけ置き、自分の関数を patch しない。検証は最も外側（stdout/stderr・実 box・HTTP ボディ・描画されたウィジェット）で行う
6. **テストは 2 系統。** A 仕様テストは受入基準から TDD（赤 → 緑 → リファクタ）で書く。B リスクテストは要件に無い所を当てる。源は 3 つ: 境界値・往復・失敗注入・べき等性・ライフサイクル・時間・設定の組み合わせ・リソース枯渇の固定リスト／「**この利用者にとって何が起きたら最悪か**」（黙って消える・誤発報・取り消せない誤操作）／過去に起きた欠陥の形。実効性は本数ではなく mutation kill rate で測る
7. **P0（到達経路を示せて、かつ実際に赤を見せた）は直す。** 片方だけなら P0 ではない。格下げ・繰り延べを実装者が単独で決めない（直すか、決定として人に出すか）。「指摘ゼロ」を完了条件にしない——十分な探索予算のレビューは必ず何かを見つける。レビューは種類の違う 2 系統を当てる（AI レビュアーの盲点は相関する）。残りは台帳へ
8. **負債を作る 8 行為には理由（ADR の引用）が要る**: 依存の追加（`requirements*.txt` `pubspec.yaml` `pubspec.lock` `pyproject.toml` `Podfile` `build.gradle.kts`）、永続化面（Hive の adapter・field・box、OS バックアップ規則、新しいファイル出力先）、秘密を持つ設定キー（`URI` / `URL` / `DSN` で終わる名前を含む。workflow の secrets も）、モジュールレベルの可変グローバル、公開ルート、外部送信先、モバイル権限、検査・フック・workflow・スクリプトの自作（`.github/workflows/` `.claude/hooks/` `scripts/`）。**機械は止めない**（`scripts/adr-touch.sh` が索引行を PR に貼るだけ。ADR-008）
   **レビュー指摘に応えて検査・ゲート・サニタイザを作る前に、① 構造を変えて危険を表現不可能にできないか ② 既存の権威（パーサ・型検査・リンタ・lock）の出力を消費できないか を問う。どちらも無ければ記録して受け入れる。自作の検出器は選択肢に入れない**（ADR-008 は 3 周・約 4,600 行で発火ゼロ、Phase 3 WP-1 の grep 検査は 3 周を費やした。同種の仕組みを作る前に `docs/archive/adr/` の ADR-008 を読む）
9. **保存・送信の経路を変える PR と、ストア提出の前には、文脈を持たないレビュアーがコードから文書へ読む独立監査を通す。** 四半期に 1 回も同じ（棚卸し観点 6）。行を貼るのではなくデータの流れを追う（何を、どこに保存し、どこから端末の外へ出るか）。手順は `.claude/skills/inventory/SKILL.md` の付録。守るのは人で、守られたかは観点 6 で月 1 に振り返る（前身の Stop フックは発火ゼロで 2026-09-12 に廃棄。2026-09-12 の監査は常設の仕組みが見逃した事故 4 件を見つけた）

ADR が引く層番号: 層 1 前段（着手前。規律 4。**「存在すべきか」はここでしか問えない**）／層 2 機械（`scripts/adr-touch.sh`・import-linter・mypy --strict。**差分の外を見るのはこれだけ**）／層 3 差分レビュー（PR ごと。規律 7）／層 4 反証可能な検査（未割当）／層 5 全体（月 1 の棚卸し）。

## 決定の索引（未卒業 5 本。卒業済み 5 本の索引と赤の見方は `docs/adr/README.md`。列順は `scripts/adr-touch.sh` が読むので変えない）

| ADR | 決めたこと | 却下した案 | 関わる行為 | 検査 |
|---|---|---|---|---|
| ADR-002 | レート制限は単一インスタンス前提・プロセス内メモリ（`limits` の `MemoryStorage`）。XFF は `backend/app/ratelimit.py` の 1 箇所、`TRUSTED_PROXY_COUNT` は実段数。総費用の上限はプロバイダの支出上限 | Redis 等の共有ストレージ（URI が秘密を運ぶ。8 周の原因） | 依存, 設定キー, 外部送信先 | 起動ガード（worker>1 で失敗）。デプロイ側契約は未検査 |
| ADR-005 | frontend は 1 概念 1 真実（お気に入りの正は `favoriteProvider`。履歴・定型文のモデルに `isFavorite` を持たせない）。永続化の失敗は利用者に伝える | 各モデルに isFavorite フィールド | 永続化 | Hive スキーマ許可リスト検査（一部） |
| ADR-007 | リリース基準: 公式ストアで本公開、初回は AI 変換抜き可、クラッシュ報告はストア標準に依拠（ADR-009）。条件は 4 つで閉じ、足すには本 ADR の改訂が要る | 日付を置く、β 配布 | 権限, 外部送信先 | 無し（リリースまで生きる） |
| ADR-009 | クラッシュ報告はストア標準に依拠し、アプリからは何も送らない | Crashlytics、Sentry、自前送信先、オプトイン | 依存, 外部送信先, 権限 | 無し（送信経路が存在しないこと自体が担保） |
| ADR-010 | 文書は 5 種類。核 `AGENTS.md` は 120 行、ADR は 60 行・未卒業 5 本（検査を書ける決定は卒業済みとして生まれる）、台帳は `docs/ledger.md` 1 本 | GitHub Issue 台帳、引き金型の降格規則、OpenSpec の恒久化、1 ADR 1 ディレクトリの照合、卒業済みを核に残す | （行為に現れない。層 3 と棚卸し） | `scripts/inventory.sh` の数字（層 5） |

パスに現れない再提案（同じ概念を UI ロジックだけで 2 つ目に実装する等）と、規律 8 の「新しいファイル出力先」「`URI`/`URL`/`DSN` で終わる名前」は、この索引でも `scripts/adr-touch.sh` でも拾えない。月 1 の棚卸し（観点 6）が受け皿。

## 文書（ADR-010）

核はこの 1 本。決定は `docs/adr/`（各 60 行、未卒業 5 本）。**正本は読者ごとに 1 つで、同じ内容を 2 箇所に書かない**: 開発者は README、利用者・審査者は `docs/privacy-policy.md` と `docs/support.md`、仕様は `docs/spec/kotonoha-requirements.md`、API は `backend/tests/contract/openapi_baseline.json`。
使い捨ては `docs/plans/`（冒頭に破棄条件 1 行）と PR 本文。倉庫 `docs/archive/` は更新しない・現在の仕様として読まない。台帳 `docs/ledger.md` は 1 問題 1 行＋出所。**コードと文書が食い違ったらコードが正。** OpenSpec は使い捨て（openspec/ は追跡しない）。

## コマンド（リポジトリルートから。セットアップ・前提・トラブルシューティングは README）

```bash
(cd backend && .venv/bin/uvicorn app.main:create_app --factory --no-proxy-headers --reload)   # 起動。--factory 必須。DB は無い
(cd backend && export PATH="$PWD/.venv/bin:$PATH" && pytest && make check)   # テスト（pytest-randomly）＋ ruff / black / mypy --strict / lint-imports / gates.sh
(cd backend && export PATH="$PWD/.venv/bin:$PATH" && make mutation)          # mutmut。kill rate は台帳の計測へ。CI に入れない（ADR-008）
(cd frontend/kotonoha_app && fvm flutter run -d chrome)                      # 接続先は --dart-define=API_BASE_URL=…（空文字は defaultValue を打ち消す）
(cd frontend/kotonoha_app && fvm flutter analyze --no-fatal-infos && fvm flutter test && fvm dart format --output=none --set-exit-if-changed .)
scripts/inventory.sh                                                         # 月 1 の棚卸しの計測。数えるだけ
git diff --name-only origin/main...HEAD | scripts/adr-touch.sh               # 層 2 を手元で（PR では adr-touch.yml が貼る）
```

## 道具（目的は固定、道具は差し替え可能。実在は月 1 の棚卸しで点検する）

| 目的 | いま使う道具 |
|---|---|
| 完了前に実物を動かす | `superpowers:verification-before-completion` / `run` |
| 決定を叩いて弱いものを落とす | `mattpocock-skills:grilling` / `openspec-explore` |
| 境界（seam）とモックの置き場を決める | `mattpocock-skills:codebase-design` |
| ドメイン語彙を整理する | `mattpocock-skills:domain-modeling` |
| フェーズ単位の大改修を task 分解して subagent で実行する | `superpowers:subagent-driven-development`。5 条件: task 分解の入力は計画書／拘束（上限・規約）を subagent へ渡す／2 系統レビューはマージ境界で／記録は PR 本文と台帳へ／OpenSpec change の実装は `openspec-apply-change` が担い併用しない |
| 全体を見て重複・乖離・道具の陳腐化を数える | `inventory`（`.claude/skills/inventory/SKILL.md`。毎月 1 日の Issue から） |
| 影響範囲の列挙／決定の引き出し／状態遷移の洗い出し／仕様と実装の乖離／反証可能なセキュリティ検査 | **未割当**。手で行う（台帳 L-70） |

## 規約

Python: 型ヒント必須、行長 100 文字、docstring は Google Style。Flutter: null safety、`const` コンストラクタ、ウィジェットに `key`、flutter_lints 準拠。
コミットは既存に倣う（docs / feat / fix / ci / chore などの接頭辞 ＋ 日本語 1 行。エージェントが書いたら末尾に Co-Authored-By）。1 変更は 400 行 / 12 ファイルまで。PR 本文に索引の yes/no と完了条件を書く。**マージの引き金は完了条件であって指摘ゼロではない。**

## 残作業

台帳 `docs/ledger.md` の「判断待ち」を読む。リリースに残るのは ADR-007 条件 4 だけ（開発者登録と審査、サポート連絡先 L-51、Android のアップロード鍵 L-52）。是正計画（Phase 0〜5）は Phase 5 の完了で終わり、`docs/plans/` から破棄される。
