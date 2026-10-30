# Workers 単体への AI API 移行 Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans to implement this plan task-by-task. User instructions in AGENTS.md govern decisions, review triage, and publishing.

**Goal:** Containers の待機費用をなくし、公開済みアプリの AI 変換を同じ URL・キー・HTTP 契約で継続できるようにする。

**Architecture:** `deploy/cloudflare` の前段 Worker を TypeScript の API 本体に置き換える。Workers 標準 Rate Limiting で送信元ごとの概算制限、既存 AI Gateway で全体の回数・支出制限を行う。AI 呼び出しはまず既存と同じ OpenAI 互換 REST API・モデル・Gateway を維持し、同時に呼び出し方法まで変えない。

**Tech Stack:** TypeScript、Workers Fetch/Web Crypto、Rate Limiting binding、ipaddr.js、Miniflare/workerd、Node test runner。

**Spec:** 本文の設計。人はコスト削減、TypeScript への移植、A 案（概算制限＋AI Gateway）を選択済み。事前承認を増やさず、エージェントの判断は PR にまとめる（AGENTS.md）。

## 設計

- 方式: A（Workers 標準制限）を採用。B（Durable Objects の永続カウンタ）は正確さと引き換えに保存と運用を増やすため採らない。Python Workers は可能だが今回は TypeScript へ集約する。
- 公開 API: `/api/v1/health`、`/api/v1/ai/convert`、`/api/v1/ai/regenerate`。URL・API_KEYS・レスポンスと利用者向けエラーを維持する。OpenAPI/Swagger は現行本番と同じ非公開。
- 認証 → 本文の 64 KiB 上限 → JSON/文字数検証 → レート制限 → 変換。無認証では本文を読まず、上流のエラー本文・例外文字列を外へ出さない。
- 送信元は Cloudflare の `CF-Connecting-IP` のみ。利用者が指定する XFF は読まない。IPv4 射影を正規化し、IPv6 は /64 ごと。API ごとに 12 回/60 秒、拠点ごと・結果整合であることを ADR と公開文に反映する。
- 標準制限へは生の IP ではなく、API_KEYS を HMAC 鍵として API・送信元・UTC の分を含めた識別子だけを渡す。1 分をまたいで関連付ける識別子を作らず、IP・識別子・入力・応答をログや DB に保存しない。識別子の物理的な削除時刻は保証しない。
- 制限時は旧契約の 429 と `Retry-After: 60`。binding が残り秒数を返さないので最大 60 秒を案内する。成功時にレート制限ヘッダーを付けない。
- モデル、プロンプト、丁寧さ、はい/いいえ等の非送信、出力 256 トークン、推論無効、途中切れ・空出力の拒否、8 秒/回・全体 10 秒、ネットワーク/429 の再試行 1 回を維持する。
- Gateway 必須、ログ収集無効・キャッシュ無効で送信。Worker の observability は無効。AI Gateway 支出制限は推計・結果整合であり、Workers AI での実際の遮断は本番切り替え前の確認事項。
- 既存 Python backend はこの PR で削除せず、従来の開発用・比較用として残す。本番の正本は TypeScript と README に明記する。
- 既存 Worker を削除せず更新する。旧 Container DO を消す migration は別途手動の最終片付けにする。旧クラスの export を残し、旧コンテナ停止と残存費用の確認を README に記す。merge・本番 deploy・請求設定・公開文の承認は人が決める。

## Global Constraints

- 等級 A。TDD の赤、レビュー 1 系統、文脈を持たないコード→公開文監査、実 HTTP と iOS/Android/Chromium の結合テスト。
- コードのモックは禁止。ネットワークの境界だけを偽物にする。レート制限は実 binding を動かす。
- 履歴・お気に入り等の端末データも frontend の動作も変えない。秘密をリポジトリへ書かない。
- 文書は README（開発者）、privacy/support（公開文）、ADR-002（決定）、now（現在地）へ。公開文の差分は PR で人の承認対象にする。

## Review Focus

- キー無し/不正キーと本文上限の順序。悪意ある本文・ヘッダーを応答やログに反射しない。
- IPv6 /64・IPv4 射影、偽造 XFF、共通キーでも送信元が別なら枠が独立する。
- 再生成の previous_result、絵文字の文字数、否定の非送信と途中切れの拒否。
- 429・ネットワーク切断・タイムアウト・不正な AI 応答でも既存アプリへ安全なエラーを返す。
- 旧コンテナが残り続ける費用、rollback、公開文の IP の扱いと変更後の実送信先の一致。

### Task 1: Worker の HTTP 契約と AI 変換

**Files:** `deploy/cloudflare/src/{index,api,ai,errors,prompts}.ts`、`deploy/cloudflare/test/api.test.mjs`、`deploy/cloudflare/package*.json`。

**Interfaces:** `api.fetch(request: Request, env: Env): Promise<Response>`。Env は既存の API_KEYS / WORKERS_AI_* と RATE_LIMITER を持つ。旧 Backend クラスは export を維持。

- [ ] Node test runner + Miniflare の HTTP 試験を先に書く。認証/64 KiB/検証/CORS/送信元・経路別の制限/プロンプト/否定/上流失敗/切れた出力を literal の期待値で検証。
- [ ] `npm test` を実行し、旧 Worker が新 API を提供しない赤を見る。
- [ ] 型と有限エラー、HTTP API、REST 境界を実装する。コードからの任意文字列のログを作らない。
- [ ] `npm test` と `npm run typecheck` が通ることを確認してコミット。

### Task 2: 本番構成と切り替え手順

**Files:** `deploy/cloudflare/wrangler.jsonc`、`.github/workflows/worker.yml`、`README.md`、`docs/adr/ADR-002-rate-limit-single-instance.md`、`docs/privacy-policy.md`、`docs/support.md`、`docs/now.md`。

**Interfaces:** Task 1 の Env の RATE_LIMITER を 12/60、既存 secret 4 つをそのまま供給。本番構成で実 API をテストする。

- [ ] 本番の Wrangler 設定をテストハーネスが読む形で、レート制限の赤を見る。
- [ ] containers の稼働設定を外し、標準 binding と Worker の CI を追加。旧 DO の破壊的 migration は含めない。
- [ ] README のローカル起動・検証・deploy/rollback・旧コンテナ停止、ADR、公開文の差分を更新。
- [ ] `npm test`、`npm run typecheck`、`npx wrangler deploy --dry-run` が通ることを確認してコミット。

### Task 3: 実物、レビュー、監査、PR

**Files:** 必要な場合のみ `frontend/kotonoha_app/integration_test/`、PR 本文。

**Interfaces:** Task 1/2 のローカル workerd HTTP と既存 Flutter API client / AI シナリオ。

- [ ] ローカル HTTP で正常系・401・413・429 を確認。Flutter の既存 AI 結合テストを iPad シミュレータ・Android エミュレータ・実 Chromium で実行する。使えない環境は理由と未検証を明記。
- [ ] backend の既存 pytest/check、frontend analyze/test/build（C の既存検証）を実行し、失敗を隠さない。
- [ ] 新しい文脈で whole-branch レビューと、別の文脈でコード→公開文の監査を依頼する。AGENTS.md の仕分けに従い、約束を破る証拠か数行の局所修正だけを採用する。
- [ ] 検証結果と未検証を PR template に記し、draft PR を作る。main merge・本番 deploy・請求設定変更は行わない。
