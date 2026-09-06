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
- **Python 3.12**（`uv` 推奨。`uv venv --python 3.12 --seed` で取得できる）
- **Docker**（backend の開発用コンテナ。**DB は無い** — ADR-001）

## セットアップ

```bash
git clone https://github.com/mozuq-lab/kotonoha.git
cd kotonoha
cp .env.example .env                   # Flutter ビルド用。キーの説明は .env.example に書いてある
cp backend/.env.example backend/.env   # backend のアプリ設定。同上
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

ローカルの docker-compose 構成をそのまま使うなら、これだけで動きます（アプリ側のデフォルトが
`API_BASE_URL=http://localhost:8000`、`AI_API_KEY` は空文字）。接続先を変える場合や
`backend/.env` の `API_KEYS` でAPIキー認証を有効にした場合は、ルート `.env` の値を `--dart-define`
で埋め込みます（Flutterは `.env` を直接読まないため）:

```bash
# ルート .env が未作成だと source が失敗する（set -e 環境では中断する）
set -a; source ../../.env; set +a

# 未設定のキーはフォールバックで補う
DEFINES=(--dart-define=API_BASE_URL="${API_BASE_URL:-http://localhost:8000}")
if [ -n "${AI_API_KEY:-}" ]; then
  DEFINES+=(--dart-define=AI_API_KEY="$AI_API_KEY")
fi
fvm flutter run -d chrome "${DEFINES[@]}"
```

**空の `--dart-define` を渡さないこと。** `String.fromEnvironment` は「値が定義されたか」で判定するため、
`--dart-define=API_BASE_URL=` のように空文字を渡すと `defaultValue` が無効になり、`baseUrl` が空文字の
まま組み立てられてAI変換が失敗します（Dart 3.10.0 で実測確認）。

動作確認:

```bash
curl -s localhost:8000/api/v1/health
```

Swagger UI は http://localhost:8000/docs （development / test でのみ公開 — ADR-004）。

## 検査

backend:

```bash
cd backend
pytest                                     # pytest-randomly が順序をシャッフルする
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
scripts/inventory.sh                                                    # 月 1 の棚卸し。数えるだけ
git diff --name-only origin/main...HEAD | scripts/adr-touch.sh          # 層 2 を手元で
```

## CI（`.github/workflows/`）

- `python.yml` — backend の lint・型・層契約・ゲート・テストを `main` / `develop` への push・PR で実行
- `flutter.yml` — frontend の analyze・format・test・ビルドを `main` / `develop` への push・PR で実行
- `adr-touch.yml` — PR の変更ファイルを AGENTS.md「負債を作る行為」に当て、関わる ADR の索引行を
  コメントで貼る（止めない）
- `openspec-guard.yml` — `openspec/changes/` 配下にファイルを追跡させない（恒久成果物は `openspec/specs/` のみ）
- `inventory-reminder.yml` — 毎月 1 日に棚卸しの Issue を立てる
- `release.yml` — タグ push でストア配布物（Android AAB 等）を作る

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
- 1つの変更の上限は**400行 / 12ファイル**（`git diff --stat` で判定。超えるなら分割）
- **マージの引き金は完了条件であって「レビュー指摘ゼロ」ではない**
- 指摘のトリアージ（定義の正は `docs/verification-principles.md`「トリアージ」節）:
  P0（到達経路を示せる、かつ実際に赤を見せた）はその場で直す。P1 / P2 は台帳（`docs/ledger.md`）へ
- PR本文には、着手前の索引チェック（未卒業ADRの各行に対する yes/no）と完了条件を書く

## ディレクトリ

- `backend/` — FastAPI バックエンド（ステートレス。DB 無し）
- `frontend/kotonoha_app/` — Flutter アプリ
- `docker/` — backend の開発用コンテナ設定
- `scripts/` — ビルド・棚卸し・ADR索引貼付などの補助スクリプト
- `docs/` — 決定・仕様・計画・倉庫
- `.github/workflows/` — CI

## 文書の地図

- 核: `AGENTS.md`
- 決定: `docs/adr/`（索引は `AGENTS.md`）
- 仕様: `docs/spec/kotonoha-requirements.md`
- API: `backend/tests/contract/openapi_baseline.json`
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
