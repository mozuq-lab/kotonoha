# kotonoha（ことのは）

発話困難な方が「できるだけ少ない操作で、自分の言いたいことを、適切な丁寧さで、安全に伝えられる」ことを
目的としたタブレット向けコミュニケーション支援アプリケーションです。対象ユーザーは脳梗塞・ALS・筋疾患
などで発話が困難だが、タブレットのタップ操作がある程度可能な方々。基本機能（文字盤入力・定型文・履歴・
TTS読み上げ）はすべてオフラインで動作し、AI変換のみオンライン必須です。ユーザーデータは端末内にのみ
保存され、クラウド同期はありません。仕様は `docs/spec/kotonoha-requirements.md`、利用者向けの文書は
`docs/privacy-policy.md` と `docs/support.md`、エージェント（Claude Code / Codex 等）向けの核は
`AGENTS.md` を参照してください。

## 前提

- **Flutter 3.38.1**（fvm で管理。`frontend/kotonoha_app/.fvmrc` にピン留め済み。未取得なら `fvm install`）
- **Node.js 24**（本番 Worker の開発・検証・デプロイ）
- **Python 3.12**（`uv` 推奨。`uv venv --python 3.12 --seed` で取得できる）
- **Docker**（backend の開発用コンテナ。**DB は無い** — ADR-001）

## セットアップ

本番 Worker は `deploy/cloudflare` で `npm ci`。以下の backend 手順は従来の FastAPI 開発用。

```bash
git clone https://github.com/mozuq-lab/kotonoha.git
cd kotonoha
cp backend/.env.example backend/.env   # backend のアプリ設定。キーの説明は .env.example に書いてある
```

backend:

```bash
cd backend
uv venv --python 3.12 --seed .venv          # --seed が無いと pip が入らない
.venv/bin/pip install -r requirements-dev.txt
(cd .. && backend/.venv/bin/pre-commit install)   # git フックの登録
```

frontend:

```bash
cd frontend/kotonoha_app
fvm install         # .fvmrc の 3.38.1 を取得（未取得の場合のみ）
fvm flutter pub get
```

## 起動

backend（Application Factory なので `--factory` が必須 — ADR-004）:

```bash
(cd backend && .venv/bin/uvicorn app.main:create_app --factory --no-proxy-headers --reload)
```

frontend:

```bash
cd frontend/kotonoha_app
fvm flutter run -d chrome
```

AI変換ボタンは標準の起動・ビルドで表示されます（初回リリースから含める — ADR-007）。
隠したい場合は `--dart-define=ENABLE_AI_CONVERSION=false` を付けます。

ローカルの docker-compose 構成をそのまま使うなら、これだけで動きます（アプリ側のデフォルトが
`API_BASE_URL=http://localhost:8000`、`AI_API_KEY` は空文字）。接続先を変える場合や
`backend/.env` の `API_KEYS` でAPIキー認証を有効にした場合は、値を `--dart-define` で渡します
（Flutter は `.env` を読みません）:

```bash
fvm flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:8000 \
  --dart-define=AI_API_KEY=<backend/.env の API_KEYS に含まれる値のいずれか>
```

**空の `--dart-define` を渡さないこと。** `String.fromEnvironment` は「値が定義されたか」で判定するため、
`--dart-define=API_BASE_URL=` のように空文字を渡すと `defaultValue` が無効になり、`baseUrl` が空文字の
まま組み立てられてAI変換が失敗します（Dart 3.10.0 で実測確認）。

動作確認:

```bash
curl -s 127.0.0.1:8000/api/v1/health
```

Swagger UI は http://localhost:8000/docs （development / test でのみ公開 — ADR-004）。

## 検査

backend:

```bash
cd backend
PATH="$PWD/.venv/bin:$PATH" pytest         # pytest-randomly が順序をシャッフルする
PATH="$PWD/.venv/bin:$PATH" make check     # ruff + black + mypy --strict + lint-imports + gates.sh
PATH="$PWD/.venv/bin:$PATH" make mutation  # kill rate は docs/ledger.md の計測へ。CI には入れない（ADR-008）
```

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

## デプロイ（Cloudflare Workers）

本番 API は `deploy/cloudflare/src/` の TypeScript Worker。DB・コンテナは使わない。
`backend/` の FastAPI は従来のローカル開発・比較用として残している。
URL・`X-API-Key`・変換と再生成の入出力は維持するので、公開済みアプリの更新は要らない。

前提は Node.js 24、既存の Workers Paid 契約、AI Gateway（全体の回数制限・支出制限、ログ収集オフ）、
Workers AI の API トークン。Docker は不要。Paid の基本料と AI 推論等の従量料金は残る。
Free への契約変更はこの移行に含めない。

```bash
cd deploy/cloudflare
npm ci
npm run typecheck
npm test
npx wrangler deploy --dry-run --outdir /tmp/kotonoha-worker-build
```

テストは本番の Wrangler 設定を読み、実 workerd・標準レート制限・HTTP で検証する。
AI のネットワーク境界だけを偽物にし、実サービスへ利用者の文を送らない。
手元の起動は `npx wrangler dev --env-file <リポジトリ外の設定ファイル>`。
設定ファイルには次の 4 つを置く（値を git に入れない）。

| 名前 | 用途 |
| --- | --- |
| `API_KEYS` | 端末キー。カンマ区切りで新旧のキーを併用できる |
| `WORKERS_AI_API_TOKEN` | Workers AI を呼べるトークン |
| `WORKERS_AI_ACCOUNT_ID` | 32 桁の 16 進数 |
| `WORKERS_AI_GATEWAY_ID` | 既存 Gateway の ID。省略すると変換も health も失敗する |

端末キーはストア向けの手元の `~/.config/kotonoha/ios-release.json` の `AI_API_KEY` と一致させる。
CI の成果物には入れない。Flutter Web の確認は `--web-port=5173` を使う（CORS 許可元は
`http://localhost:3000` と `http://localhost:5173`）。ローカルの Worker は既定で 8787 番。

### レート制限とログ

Cloudflare の `CF-Connecting-IP` だけを送信元に使う。受信した `X-Forwarded-For` は読まない。
IPv4 射影を IPv4 へそろえ、IPv6 は /64 ごとに数える。標準 Rate Limiting binding に渡すのは、
API・送信元・UTC の分から HMAC で作る識別子で、生の IP や入力文は渡さない。
識別子は 1 分ごとに切り替え、独自のログ・DB には IP・識別子・入力文・結果を保存しない。
Worker の observability はオフ。AI Gateway へは `cf-aig-collect-log: false` と
`cf-aig-skip-cache: true` を明示する。失敗時は `request_failed` の 1 行（エラーコードと、原因の型または
上流の HTTP ステータス）だけを出す。保存はされず、`npx wrangler tail` を開いている間だけ見られる。

各 API ごとに 12 回/60 秒を設定するが、拠点ごと・概算の制限で、12 回を超える場合がある。
制限時は 429 と `Retry-After: 60`（binding は残り時間を返さないため最大の待ち時間を案内）。
全体の回数と費用は AI Gateway 側でも制限する。支出制限も推計・結果整合で、厳密な請求上限ではない。
既存の支出制限が Workers AI で実際に遮断するかは未検証で、本番切り替え時の確認事項。

### 新しい環境を作る

端末キー（`API_KEYS`）は推測されにくい値を自分で作り、同じ値を `~/.config/kotonoha/ios-release.json` の
`AI_API_KEY` に入れる。`CF_`・`CLOUDFLARE_` で始まる環境変数はシェルに入れたまま使わない。wrangler が
ログインより優先して自分の認証に使うので、Workers AI 用の狭い権限で認証してデプロイや削除が失敗する。

```bash
openssl rand -hex 32    # 16 進数 64 文字。表示された値を API_KEYS と ios-release.json の AI_API_KEY に使う
cd deploy/cloudflare
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

`secret put` で入れた秘密は Worker に残るので、2 回目以降の更新は `npm ci` → 検証 → `npx wrangler deploy` だけでよい。
独自ドメイン `kotonoha.mozuq-lab.com`（Worker の Custom Domain。`mozuq-lab.com` の DNS は Cloudflare）は、
Worker を作り直すと外れる。Worker の Settings → Domains & Routes で付け直す。

### Containers からの初回切り替え（人が行う）

公開文の変更を承認してから行う。同じ `kotonoha-backend` を更新し、Worker 自体を消さない。
既存の secret 4 つ・Custom Domain・旧 `workers.dev` の URL を維持できる。
`CF_`・`CLOUDFLARE_` で始まる環境変数をシェルから外し、wrangler 自身の認証を確認してから進める。

```bash
cd deploy/cloudflare
npm ci
npx wrangler whoami
npx wrangler versions list                 # 戻す版の ID を控える
npx wrangler containers list               # 旧 kotonoha-backend-backend の ID を控える
npx wrangler deploy
curl -fsS https://kotonoha.mozuq-lab.com/api/v1/health
```

次に、既存の端末キーで変換と再生成を行い、Gateway のログが空のまま・回数制限と支出制限が効くか確かめる。
キー無しは 401、旧 `workers.dev` でも同じ API が応答することも確認する。
秘密を差し替える必要はなく、今後の secret 更新はコンテナの再作成を伴わない。

**Worker の更新だけで旧コンテナの料金が止まったと見なさない。** 新 API の確認後、旧アプリの名前と ID を
照合してから `npx wrangler containers delete <旧アプリのID>` で削除し、一覧と請求・使用量で稼働が止まったことを確かめる。
削除は人が行う。利用者データは無いが、旧コンテナでの即時 rollback はできなくなる。
既存 DO の `Backend` export と migration は互換用に残し、新 API では呼ばない。
イメージの削除・未使用 secret/DO の掃除・Paid の契約変更は別の判断にする。

旧コンテナを消す前に戻す場合は `npx wrangler rollback <控えた旧バージョンID>`。
削除後に戻す場合は、次の「旧構成（Containers）でデプロイする」の手順でコンテナを作り直す。

### 旧構成（Containers）でデプロイする

Workers へ移す前の構成は `493e85b705e` にある。Workers 版を戻すときや、旧構成と比べるときに使う。
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

```bash
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

作り直すときは「新しい環境を作る」の手順で secret を 4 つとも登録し直す（Worker と一緒に消えている）。
`name` が同じなら URL も同じになり、端末キーを変えなければ GitHub の設定はそのまま使える。

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

## ディレクトリ

- `backend/` — 従来の FastAPI（ローカル開発・比較用。DB 無し）
- `frontend/kotonoha_app/` — Flutter アプリ
- `docker/` — backend の開発用コンテナ設定
- `deploy/cloudflare/` — 本番 API（TypeScript Worker、Containers は使わない）
- `scripts/` — ビルド・棚卸し・ADR索引貼付などの補助スクリプト
- `docs/` — 決定・仕様・計画・倉庫
- `.github/workflows/` — CI

## 文書の地図

- 核: `AGENTS.md`
- 決定: `docs/adr/`（索引は `AGENTS.md`）
- 仕様: `docs/spec/kotonoha-requirements.md`
- 本番 API の契約検証: `deploy/cloudflare/test/api.test.mjs`（旧 FastAPI の OpenAPI は `backend/tests/contract/openapi_baseline.json`）
- 利用者向け: `docs/privacy-policy.md`・`docs/support.md`
- 台帳: `docs/ledger.md`
- 倉庫: `docs/archive/`（更新しない。現在の仕様として読まない）

## トラブルシューティング

### Docker

- **コンテナが起動しない** → `docker-compose logs -f` でログを確認し、
  `docker-compose down && docker-compose build --no-cache && docker-compose up -d` で再ビルド
- **ポート8000が使用中** → `lsof -i :8000` でプロセスを確認し `kill -9 <PID>`

### backend（Python）

- **`make check` が `ruff: No such file or directory` 等で失敗する** → この Makefile は venv を自動で
  有効化しない。`PATH="$PWD/.venv/bin:$PATH" make check` を使う
- **`pip install` が失敗する / pip が無い** → `uv venv --python 3.12 --seed .venv` の `--seed` を忘れると
  pip が入らない。venv を作り直す
- **venv を作り直した後、pre-commit が動かない** → `.git/hooks/pre-commit` は作成時の venv の python を
  指すため、`(cd .. && backend/.venv/bin/pre-commit install)` で入れ直す

### frontend（Flutter）

- **パッケージ取得エラー** → `fvm flutter clean && fvm flutter pub cache repair && fvm flutter pub get`
- **`.fvmrc` があるのに違うバージョンが動く** → `fvm use 3.38.1` を再実行する
  （非対話で通すなら `--force` または `--skip-pub-get`）

## ライセンス

MIT License

Copyright (c) 2025 kotonoha project

詳細は [LICENSE](LICENSE) ファイルを参照してください。
