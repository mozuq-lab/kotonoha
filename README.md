# kotonoha（ことのは）

発話困難な方が「できるだけ少ない操作で、自分の言いたいことを、適切な丁寧さで、安全に伝えられる」ことを
目的としたタブレット向けコミュニケーション支援アプリケーションです。対象ユーザーは脳梗塞・ALS・筋疾患
などで発話が困難だが、タブレットのタップ操作がある程度可能な方々。基本機能（文字盤入力・定型文・履歴・
TTS読み上げ）はすべてオフラインで動作し、AI変換のみオンライン必須です。ユーザーデータは端末内にのみ
保存され、クラウド同期はありません。仕様は `docs/spec/kotonoha-requirements.md`、利用者向けの文書は
`docs/privacy-policy.md` と `docs/support.md`、エージェント（Claude Code / Codex 等）向けの核は
`AGENTS.md` を参照してください。

## 構成

| 場所 | 役割 |
| --- | --- |
| `frontend/kotonoha_app/` | Flutter アプリ。AI 変換以外はこれだけで動く |
| `backend/worker/` | **本番 API**（TypeScript Worker。DB・コンテナは使わない）。手元の開発もこれを使う |
| `backend/fastapi/` | 以前使っていた API（DB 無し）のバックアップ。本番でも普段の開発でも使わない（[FastAPI](#fastapi旧-api)） |
| `docker/` | FastAPI の開発用コンテナ設定 |
| `scripts/` | ビルド・棚卸し・ADR索引貼付などの補助スクリプト |
| `docs/` | 決定・仕様・計画・倉庫 |
| `.github/workflows/` | CI |

## ローカルで動かす

必要なのは **Flutter 3.38.1**（fvm で管理。`frontend/kotonoha_app/.fvmrc` にピン留め済み）と
**Node.js 24** だけ。Docker・Python・Cloudflare のアカウントは要らない。

```bash
git clone https://github.com/mozuq-lab/kotonoha.git
cd kotonoha
```

コミットするなら git フックも入れる。フックを動かす `pre-commit` は `backend/fastapi/requirements-dev.txt` で
入れるので、[FastAPI の準備](#準備)を行う（Python 3.12 が要る。FastAPI を起動する必要はない）。

### 1. frontend を起動する

AI 変換を使わないなら、ここまでで足りる。

```bash
cd frontend/kotonoha_app
fvm install         # .fvmrc の 3.38.1 を取得（未取得の場合のみ）
fvm flutter pub get
fvm flutter run -d chrome
```

AI変換ボタンは標準の起動・ビルドで表示されます（初回リリースから含める — ADR-007）。
隠したい場合は `--dart-define=ENABLE_AI_CONVERSION=false` を付けます。

### 2. Worker を起動する

```bash
cd backend/worker
npm ci
cp .dev.vars.example .dev.vars   # 初回だけ。ダミー値のまま起動できる
npx wrangler dev                 # http://localhost:8787
```

動作確認:

```bash
curl -s 127.0.0.1:8787/api/v1/health
```

### 3. frontend を Worker につなぐ

```bash
cd frontend/kotonoha_app
fvm flutter run -d chrome --web-port=5173 \
  --dart-define=API_BASE_URL=http://localhost:8787 \
  --dart-define=AI_API_KEY=local-dev-key
```

- `API_BASE_URL`: 既定値は FastAPI の `http://localhost:8000` なので、Worker には指定が要る。
- `AI_API_KEY`: Worker は常に端末キーを求める。`.dev.vars` の `API_KEYS` と同じ値にする
  （Flutter は `.dev.vars` を読まない）。
- `--web-port=5173`: Worker の CORS 許可元は `http://localhost:3000` と `http://localhost:5173` だけ。
  指定しないとポートが変わり、ブラウザが通信を止める。

**空の `--dart-define` を渡さないこと。** `String.fromEnvironment` は「値が定義されたか」で判定するため、
`--dart-define=API_BASE_URL=` のように空文字を渡すと `defaultValue` が無効になり、`baseUrl` が空文字の
まま組み立てられてAI変換が失敗します（Dart 3.10.0 で実測確認）。

ダミー値のままだと、AI 変換は `AI_API_ERROR`（500）で失敗する。ただし `はい`・`いいえ`・`うん`・`ううん` は
AI へ送らずに返すので、この 4 語なら画面の往復まで確かめられる。

### 本物の AI を使う

`.dev.vars` の値を本物に置き換えて Worker を起動し直す。入力した文は本番と同じく Cloudflare へ送られ、
指定した Gateway の回数と費用に数えられる。キーやトークンを git に入れないこと。`.dev.vars` は
無視される設定だが、リポジトリの中に置きたくなければ、外のファイルを
`npx wrangler dev --env-file <ファイル>` で渡す。

| 名前 | 用途 |
| --- | --- |
| `API_KEYS` | 端末キー。カンマ区切りで新旧のキーを併用できる |
| `WORKERS_AI_API_TOKEN` | Workers AI を呼べるトークン |
| `WORKERS_AI_ACCOUNT_ID` | 32 桁の 16 進数 |
| `WORKERS_AI_GATEWAY_ID` | 既存 Gateway の ID。省略すると変換も health も失敗する |

本番用の値（`wrangler secret put` で入れるもの）も、この 4 つです。

## 検査

Worker:

```bash
cd backend/worker
npm run typecheck
npm test
npx wrangler deploy --dry-run --outdir /tmp/kotonoha-worker-build
```

テストは本番の Wrangler 設定を読み、実 workerd・標準レート制限・HTTP で検証する。
AI のネットワーク境界だけを偽物にし、実サービスへ利用者の文を送らない。

frontend:

```bash
cd frontend/kotonoha_app
fvm flutter analyze --no-fatal-infos
fvm flutter test
fvm dart format --output=none --set-exit-if-changed .
```

全体:

```bash
scripts/inventory.sh                                                    # 監査の計測。数えるだけ
```

## 本番（Cloudflare Workers）

本番の接続先は `https://kotonoha.mozuq-lab.com`。

前提は Node.js 24、既存の Workers Paid 契約、AI Gateway（全体の回数制限・支出制限、ログ収集オフ）、
Workers AI の API トークン。Docker は不要。Paid の基本料と AI 推論等の従量料金は残る。

### 更新する

[検査](#検査)を通してからデプロイする。`secret put` で入れた秘密は Worker に残るので、入れ直さなくてよい。

```bash
cd backend/worker
npm ci
npx wrangler deploy
curl -fsS https://kotonoha.mozuq-lab.com/api/v1/health
```

端末キーはストア向けの手元の `~/.config/kotonoha/ios-release.json` の `AI_API_KEY` と一致させる。
CI の成果物には入れない。

### レート制限とログ

Cloudflare の `CF-Connecting-IP` だけを送信元に使う。受信した `X-Forwarded-For` は読まない。
IPv4 射影を IPv4 へそろえ、IPv6 は /64 ごとに数える。標準 Rate Limiting binding に渡すのは、
API・送信元・UTC の分から HMAC で作る識別子で、生の IP や入力文は渡さない。
識別子は 1 分ごとに切り替え、独自のログ・DB には IP・識別子・入力文・結果を保存しない。
Worker の observability はオフ。AI Gateway へは `cf-aig-collect-log: false` と
`cf-aig-skip-cache: true` を明示する。失敗時は `request_failed` の 1 行（エラーコードと、原因の型または
上流の HTTP ステータス）だけを出す。保存はされず、`npx wrangler tail --format pretty` を開いている間だけ
見られる。既定の JSON 形式は要求の情報まで出すので使わず、tail の出力はファイルへ残さない。

各 API ごとに 12 回/60 秒を設定するが、拠点ごと・概算の制限で、12 回を超える場合がある。接続を維持する
クライアントは 13 回目で止まる。毎回接続を張り直すと isolate ごとに数えられ、25 秒で約 70 回通る（2026-10-31 に本番で実測）。
手元の workerd は正確に数えるので、確かめるときは本番で接続を維持して測る。
制限時は 429 と `Retry-After: 60`（binding は残り時間を返さないため最大の待ち時間を案内）。
全体の回数と費用は AI Gateway 側でも制限する。支出制限も推計・結果整合で、厳密な請求上限ではない。
既存の支出制限が Workers AI で実際に遮断するかは未検証（人待ち）。

### 新しい環境を作る

**既存の環境を作り直すときは、端末キーを変えない。** `~/.config/kotonoha/ios-release.json` の `AI_API_KEY` と
同じ値を `API_KEYS` に入れる。公開済みアプリにはキーが埋め込まれているので、変えると全員の AI 変換が 401 で
止まり、旧キーを入れ直すかストア更新が済むまで直らない。新しいキーは、公開済みの版が無い環境でだけ作る。

`CF_`・`CLOUDFLARE_` で始まる環境変数はシェルに入れたまま使わない。wrangler が
ログインより優先して自分の認証に使うので、Workers AI 用の狭い権限で認証してデプロイや削除が失敗する。

```bash
openssl rand -hex 32    # 公開済みの版が無い環境でだけ。API_KEYS と ios-release.json の AI_API_KEY に使う
cd backend/worker
npm ci
npx wrangler login
# 秘密は wrangler.jsonc に書かない。1 つずつ入力する
npx wrangler secret put API_KEYS
npx wrangler secret put WORKERS_AI_API_TOKEN
npx wrangler secret put WORKERS_AI_ACCOUNT_ID
npx wrangler secret put WORKERS_AI_GATEWAY_ID
npx wrangler deploy
curl -fsS https://<Worker の URL>/api/v1/health
```

独自ドメイン `kotonoha.mozuq-lab.com`（Worker の Custom Domain。`mozuq-lab.com` の DNS は Cloudflare）は、
Worker を作り直すと外れる。Worker の Settings → Domains & Routes で付け直す。

### 旧構成（Containers）でデプロイする

Workers へ移す前の構成は `493e85b705e` にある（当時のパスは `deploy/cloudflare` と `backend`）。Workers 版を戻すときや、旧構成と比べるときに使う。
Docker と Workers Paid が要り、コンテナの待機費用がかかる（`sleepAfter` が 24 時間で、常時起動に近い）。

```bash
git worktree add ../kotonoha-containers 493e85b705e
cd ../kotonoha-containers/deploy/cloudflare
npm ci
npx wrangler deploy --dry-run --outdir /tmp/kotonoha-containers-build   # イメージを作るだけで送らない
npx wrangler deploy
npx wrangler containers list                # kotonoha-backend-backend があることを確かめる
curl -fsS https://kotonoha.mozuq-lab.com/api/v1/health
```

同じ `kotonoha-backend` を上書きするので、secret 4 つと URL はそのまま使える。実際に Workers 版から戻す操作は
未実施で、確かめたのは dry-run まで。戻した後は、変換・再生成と、キー無しの 401 も確かめる。

レート制限はプロセス内メモリなので、インスタンスは 1 つに固定する（`max_instances: 1`）。秘密はコンテナの
起動時にしか渡らない。`secret put` と `deploy` だけでは古い値のまま動き続けるので、秘密を差し替えたら
`npx wrangler containers list` で ID を確かめ、`npx wrangler containers delete <ID>` の後に `npx wrangler deploy` する。

公開文は Workers 版に合わせてあるので、旧構成で続けるなら `docs/privacy-policy.md` の IP の扱いと
第 28 条の記述も戻す。公開文の変更は人が承認する。

### Cloudflare の環境を消す

取り消せない操作なので、消す前に何が残り何が消えるかを確かめる。先に `unset` して、wrangler が自分の
ログイン（OAuth）で動くようにしておく。Worker の削除・請求設定の変更は人が決める。
`API_KEYS` は Worker と一緒に消え、読み出せない。消す前に `ios-release.json` の `AI_API_KEY` の控えを確かめる。

```bash
cd backend/worker
env | grep -E '^(CF_|CLOUDFLARE_)'          # 何も出ないことを確かめる。出たら unset する
npx wrangler whoami                          # 自分のアカウントに OAuth でログインしていること
npx wrangler delete                          # Worker（kotonoha-backend）・secret・Durable Object を消す
npx wrangler containers list                 # 旧コンテナのアプリが残っていれば
npx wrangler containers delete <ID>          # その ID で消す
npx wrangler containers images list          # 保存されたイメージ（任意）
npx wrangler containers images delete <イメージ名:タグ>
curl -s https://<Worker の URL>/api/v1/health   # 応答が無くなったことを確かめる
```

`wrangler delete` では、次のものは消えない。必要に応じてダッシュボードで片付ける。

| 残るもの | 場所 | メモ |
| --- | --- | --- |
| AI Gateway と、その支出上限・回数制限の設定 | AI → AI Gateway | 作り直すなら残しておく方が楽 |
| Workers AI の API トークン | My Profile → API Tokens | 当分使わないなら無効にする |
| 前払いのクレジット | Billing | 残る |
| Workers Paid の契約 | Workers & Pages → Plans | 月額が続く。止めるなら解約する |
| `API_BASE_URL`（Variables） | GitHub の Settings → Secrets and variables → Actions | 残したままだと、CI のビルドは消えた URL を指す |

作り直すときは「新しい環境を作る」の手順で、同じ端末キーを使って secret を 4 つとも登録し直す（Worker と
一緒に消えている）。`name` が同じなら URL も同じになり、GitHub の設定もそのまま使える。

## iOS の版を TestFlight へ送る

手元の Mac で `scripts/ios-testflight.sh` を動かす。接続先と端末キー、App Store Connect API キーは、
リポジトリの外のファイルから読む（置き場所と書き方はスクリプトの先頭）。送る前に、埋め込む接続先と
キーが本番の backend に受け入れられるかを確かめ、だめなら止まる。署名は自動署名で、Xcode へのログインは要らない。

```bash
scripts/ios-testflight.sh
```

## CI（`.github/workflows/`）

- `worker.yml` — 本番 Worker の型・実 workerd の HTTP テスト・deploy dry-run を PR/push で実行
- `python.yml` — 従来の backend の lint・型・層契約・ゲート・テストを `main` / `develop` への push・PR で実行
- `flutter.yml` — frontend の analyze・format・test・ビルドを `main` / `develop` への push・PR で実行
- `release.yml` — タグ push で Android AAB 等を作る。端末キーを入れないので、そのままでは AI 変換が使えない（ストアに出す iOS の版は `scripts/ios-testflight.sh` で作る。Android の版の作り方は Play に出す前に決める）

## FastAPI（旧 API）

以前使っていた API のバックアップ。本番でも普段の開発でも使わない。
Python 3.12（`uv` 推奨）が要る。DB は無い（ADR-001）。

### 準備

```bash
cp backend/fastapi/.env.example backend/fastapi/.env   # アプリ設定。キーの説明は .env.example に書いてある
cd backend/fastapi
uv venv --python 3.12 --seed .venv          # --seed が無いと pip が入らない
.venv/bin/pip install -r requirements-dev.txt
(cd ../.. && backend/fastapi/.venv/bin/pre-commit install)   # git フックの登録
```

### 起動

Application Factory なので `--factory` が必須（ADR-004）。Docker で動かすならリポジトリのルートで
`docker-compose up -d`（Docker が要る）。

```bash
(cd backend/fastapi && .venv/bin/uvicorn app.main:create_app --factory --no-proxy-headers --reload)
curl -s 127.0.0.1:8000/api/v1/health
```

Swagger UI は <http://localhost:8000/docs>（development / test でのみ公開 — ADR-004）。

frontend の `API_BASE_URL` の既定値は FastAPI の 8000 番を指し、`API_KEYS` が空なら認証を省略するので、
`--web-port` だけ指定すればよい。`backend/fastapi/.env` の `API_KEYS` で認証を有効にした場合は、その値の
いずれかを `AI_API_KEY` で渡す。

```bash
cd frontend/kotonoha_app
fvm flutter run -d chrome --web-port=5173
```

### FastAPI の検査

```bash
cd backend/fastapi
PATH="$PWD/.venv/bin:$PATH" pytest         # pytest-randomly が順序をシャッフルする
PATH="$PWD/.venv/bin:$PATH" make check     # ruff + black + mypy --strict + lint-imports + gates.sh
PATH="$PWD/.venv/bin:$PATH" make mutation  # kill rate は docs/ledger.md の計測へ。CI には入れない（ADR-008）
```

### FastAPI のトラブルシューティング

- **コンテナが起動しない** → `docker-compose logs -f` でログを確認し、
  `docker-compose down && docker-compose build --no-cache && docker-compose up -d` で再ビルド
- **ポート8000が使用中** → `lsof -i :8000` でプロセスを確認し `kill -9 <PID>`
- **`make check` が `ruff: No such file or directory` 等で失敗する** → この Makefile は venv を自動で
  有効化しない。`PATH="$PWD/.venv/bin:$PATH" make check` を使う
- **`pip install` が失敗する / pip が無い** → `uv venv --python 3.12 --seed .venv` の `--seed` を忘れると
  pip が入らない。venv を作り直す
- **venv を作り直した後、pre-commit が動かない** → `.git/hooks/pre-commit` は作成時の venv の python を
  指すため、`(cd ../.. && backend/fastapi/.venv/bin/pre-commit install)` で入れ直す

## 規約

### コーディング

- **Python**: 型ヒント必須、行長100文字以内、docstringはGoogle Style
- **Flutter**: Null Safety有効、`const` コンストラクタを可能な限り使用、ウィジェットは `key` パラメータ
  を持つ、`flutter_lints` 準拠

### コミット・ブランチ・PR

- コミットは既存に倣う: `docs` / `feat` / `fix` / `ci` / `chore` / `build` などの接頭辞 ＋ 日本語1行の
  件名。エージェントが書いた場合は末尾に `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`
- 同時に開くブランチは**2本まで**（セキュリティ対応は1本）。寿命は原則1営業日
- CIが緑の小さい独立差分は、大きな作業の完了を待たずに先へマージする
- `main` は日次で push して「正」を1つに保つ
- 変更は小さく分ける（目安 400 行）
- **マージの引き金は完了条件であって「レビュー指摘ゼロ」ではない**
- 等級・指摘の仕分け・人が決めることは `AGENTS.md`「判断の手順」が正。PR 本文は `.github/pull_request_template.md` の形

## 文書の地図

- 核: `AGENTS.md`
- 決定: `docs/adr/`（索引は `AGENTS.md`）
- 仕様: `docs/spec/kotonoha-requirements.md`
- 本番 API の契約検証: `backend/worker/test/api.test.mjs`（旧 FastAPI の OpenAPI は `backend/fastapi/tests/contract/openapi_baseline.json`）
- 利用者向け: `docs/privacy-policy.md`・`docs/support.md`
- 台帳: `docs/ledger.md`
- 倉庫: `docs/archive/`（更新しない。現在の仕様として読まない）

## トラブルシューティング

### Worker

- **AI 変換だけ失敗する（`AI_API_ERROR`）** → `.dev.vars` がダミー値のまま。[本物の AI を使う](#本物の-ai-を使う)
- **Web で AI 変換が通信エラーになる** → `--web-port=5173` を付けて起動する

### frontend（Flutter）

- **パッケージ取得エラー** → `fvm flutter clean && fvm flutter pub cache repair && fvm flutter pub get`
- **`.fvmrc` があるのに違うバージョンが動く** → `fvm use 3.38.1` を再実行する
  （非対話で通すなら `--force` または `--skip-pub-get`）

## ライセンス

MIT License

Copyright (c) 2025 kotonoha project

詳細は [LICENSE](LICENSE) ファイルを参照してください。
