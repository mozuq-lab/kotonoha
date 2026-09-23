# AGENTS.md

エージェント（Claude Code / Codex など）が毎回読む核。規則を 1 つ足すなら 1 つ消す。
**今どこにいて次に何をするかは `docs/now.md`（上書きする 1 枚）を先に読む。** 文書と判断の枠組みは ADR-010。開発者向けの前提と手順は README。`CLAUDE.md` はこの文書への参照だけ。

## 目的と、最悪の結果

**kotonoha（ことのは）** — 発話が困難な人（脳梗塞・ALS・筋疾患など）が、少ない操作で、適切な丁寧さで、安全に伝える文字盤アプリ（Flutter、タブレット向け）。**利用者は発話で訂正できず、データは端末内（Hive）にしか無い。** 文字盤・定型文・履歴・お気に入り・読み上げ・緊急ボタンはオフラインで動き、AI 変換だけがオンライン（backend は FastAPI のステートレスなプロキシ。DB 無し）。仕様の正本は `docs/spec/kotonoha-requirements.md`。
目的はこのアプリを形にして届けること。「形」の定義と最短経路は `docs/now.md` にある。
**最悪の結果**（製品の約束。変えるのは人）: ① 緊急が届かない（鳴らない・画面に閉じ込められるを含む） ② データが黙って消える（消えるのに残ると告げるを含む） ③ 端末の外へ出る ④ 本人の意図と違うことを伝える（言っていないことを言う・読み上げが黙る・誤発報）。

## 判断の手順（エージェントが決める）

1. **何をするか**: `docs/now.md` の最短経路にある仕事と、人の依頼だけをする。レビュー指摘や思いついた改善は仕事の入口にしない。最短経路に動かせるものが無ければ、止まって待ってよい（仕事を作らない）。
2. **等級**: 差分（修正の差分も）が触るパスで最低等級が決まり、エージェントは上げるだけ。挙動を変えない差分（文書・コメント・テストだけ）は C。`lib/…` は `frontend/kotonoha_app/lib/`。
   - **A**（最悪の結果に届き得る）: 保存と消去（`lib/core/persistence/`・`lib/core/utils/hive_*`・`lib/shared/models/*_adapter.dart`・`lib/features/*/data/` とそれを呼んで保存・削除する provider（例: `preset_phrase_notifier.dart`）・SharedPreferences を読み書きするコード）、緊急と読み上げ（`lib/features/emergency/domain/`・`lib/features/emergency/presentation/providers/`・`lib/shared/widgets/emergency_button.dart`・`lib/features/tts/domain/`・`lib/features/tts/providers/`）、端末の外（`lib/features/ai_conversion/data/`・`backend/app/`・権限・依存・`.github/workflows/`）
   - **B**: それ以外のコード（画面・文言・配色・確認ダイアログを含む）
   - **C**: 文書・コメント・テストだけ・挙動を変えない整理
3. **検証の重さ**: A はテストを先に書いて赤を見る、レビュー 1 系統、実物での確認（iOS シミュレータ・Android エミュレータ・実 Chromium。物理実機はストア提出の前）。保存・送信の経路を変えるときは、文脈を持たない担当がコードから公開文（`docs/privacy-policy.md`・`docs/support.md`）へ読む独立監査も通す。B はテストとレビュー 1 系統（画面を変えたら実物で見る）。C はビルドと既存テストだけ。
4. **指摘の仕分け**: レビューは縛らない。指摘は既定で捨て、記録しない。直すのは、証拠（赤くなるテスト・スクリーンショット・実測値）で最悪の結果に届くと示せたものと、数行で局所的に直せるもの（再レビューしない）。修正の差分も、触るパスで最低等級を決める。最悪の結果に届かない指摘への修正には、再レビューを付けない。再現していない重大な経路は PR に 1 行だけ書き、持ち越さない。
5. **行き詰まったら**: 同じ関数を 2 回変えることになったら、次の一手の候補を「設計を変える」「削る」「閉じる」にし、履歴を渡さない新しい文脈で「この問題を消す設計は何か」を問う。判断が割れたら議論せず、2〜3 案を作ってスクリーンショットで見せる。
6. **人が決めること**: 外への影響（main への merge・ストア・支払い・秘密・リポジトリ設定・他人の PR）、製品の約束（最悪の結果・公開文のプライバシーと医療的な表現・データの扱い）、取り返しのつかないデータ移行。それ以外はエージェントが決め、PR 本文の「私が決めたこと」に書く（人は事後に覆す）。
7. **教訓**: コード（型・網羅する switch・本番構成のテストヘルパー）にするか、捨てる。文書やメモリに規則を足さない。自作の検出器（grep の検査・ゲート）は作らない（倉庫の ADR-008）。決定を変える・A に着手するときは、下の索引の「却下した案」と照らす。

## 変えない原則

- 完了と言う前に実物を動かす（起動・描画されたウィジェット・実 box・HTTP 応答）。
- 観測点を疑う。主張の前に「壊れていたら赤くなるか」を問い、答えられなければ壊して赤を見る。パイプの終了コードや自作の集計は観測点をすり替える。
- 自分や前のセッションが書いた文書・コメント・メモリを事実として扱わない。数字・パス・行番号は現物で確かめる。
- モックは外部 SDK とネットワークの境界だけ。自分の関数を patch しない。検証は最も外側で行う。
- 危険は構造（型・設計）で表現できなくする。レビュー指摘に応えて検査を足さない。

## 決定の索引（未卒業。卒業済みと赤の見方は `docs/adr/README.md`。列は両方同じ）

| ADR | 決めたこと | 却下した案 | 関わる行為 | 検査 |
|---|---|---|---|---|
| ADR-002 | 【構造】レート制限は単一インスタンス前提・プロセス内メモリ（`limits` の `MemoryStorage`）。XFF は `backend/app/ratelimit.py` の 1 箇所、`TRUSTED_PROXY_COUNT` は実段数。総費用の上限はプロバイダの支出上限 | Redis 等の共有ストレージ（URI が秘密を運ぶ。8 周の原因） | 依存, 設定キー, 外部送信先 | 起動ガード（worker>1 で失敗）。デプロイ側契約は未検査 |
| ADR-005 | 【約束】frontend は 1 概念 1 真実（お気に入りの正は `favoriteProvider`。履歴・定型文のモデルに `isFavorite` を持たせない）。お気に入りは定型文の削除で消えない。永続化の失敗（作り直し・一部の喪失・設定を含む）は利用者に伝える | 各モデルに isFavorite フィールド、定型文削除でお気に入りも消す | 永続化 | Hive スキーマ許可リスト検査（一部）、TC-SYNC-202 |
| ADR-007 | 【約束】リリース基準: 公式ストアで本公開、初回は AI 変換抜き可、クラッシュ報告はストア標準に依拠（ADR-009）。条件は 4 つで閉じる。iOS 先行、Android は Play のクローズドテスト（12 人 × 14 日）通過後。開発者登録はアプリが形になってから | 日付を置く、自発的な β 配布、組織アカウント（D-U-N-S）で Play の要件を外す | 権限, 外部送信先 | 無し（リリースまで生きる） |
| ADR-009 | 【約束】クラッシュ報告はストア標準に依拠し、アプリからは何も送らない | Crashlytics、Sentry、自前送信先、オプトイン | 依存, 外部送信先, 権限 | 無し（送信経路が存在しないこと自体が担保） |
| ADR-010 | 【構造】文書と判断の枠組み: 核は AGENTS.md、現在地は `docs/now.md`（上書き）、ADR は約束と却下案だけ（60 行・未卒業 5 本）、等級・指摘の仕分け・人が決めること、監査はストア提出前・人の依頼・保存送信の経路を変えるとき | 固定の予算、人の事前承認、レビューを縛る、引き金型の規則、止める機械、全部を記録する台帳、月 1 の定期棚卸し | （行為に現れない） | 無し（監査で総量と不要になった仕事を見る） |

## 文書

**正本は読者ごとに 1 つで、同じ内容を 2 箇所に書かない**: 開発者は README、利用者・審査者は `docs/privacy-policy.md` と `docs/support.md`、仕様は `docs/spec/kotonoha-requirements.md`。使い捨ては `docs/plans/` と PR 本文、倉庫 `docs/archive/` は更新しない。台帳 `docs/ledger.md` は決めた予定と、利用者に見える受け入れた限界だけ。**コードと文書が食い違ったらコードが正。**

## コマンド（リポジトリルートから。セットアップ・前提・トラブルシューティングは README）

```bash
(cd backend && .venv/bin/uvicorn app.main:create_app --factory --no-proxy-headers --reload)   # 起動。--factory 必須。DB は無い
(cd backend && export PATH="$PWD/.venv/bin:$PATH" && pytest && make check)   # テスト（pytest-randomly）＋ ruff / black / mypy --strict / lint-imports / gates.sh
(cd frontend/kotonoha_app && fvm flutter run -d chrome)                      # 接続先は --dart-define=API_BASE_URL=…（空文字は defaultValue を打ち消す）
(cd frontend/kotonoha_app && fvm flutter analyze --no-fatal-infos && fvm flutter test && fvm dart format --output=none --set-exit-if-changed .)
scripts/inventory.sh                                                         # 監査の計測。数えるだけ
```

## 規約

Python: 型ヒント必須、行長 100 文字、docstring は Google Style。Flutter: null safety、`const` コンストラクタ、ウィジェットに `key`、flutter_lints 準拠。
コミットは既存に倣う（docs / feat / fix / ci / chore などの接頭辞 ＋ 日本語 1 行。エージェントが書いたら末尾に Co-Authored-By）。変更は小さく分ける（目安 400 行）。PR 本文は `.github/pull_request_template.md` の形（人向けは 1 画面、記録は `<details>`）。**マージの引き金は完了条件であって指摘ゼロではない。**
