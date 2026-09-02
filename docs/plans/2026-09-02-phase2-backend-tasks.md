# Phase 2 — backend 書き直し 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

作成: 2026-09-02 ／ 親計画: `docs/plans/2026-08-29-architecture-remediation.md` §5 Phase 2 ／ **完了したら破棄する**

**Goal:** 旧 backend（3,545行・DB あり・公開ルート5本）を、同じ URL・同じスキーマの
ステートレスな AI 変換プロキシ（約1,000行・公開ルート3本）へ差し替え、ADR-001〜004・006 を
検査可能な形で実行する。

**Architecture:** 書き直しの前に旧実装の外部契約を characterization テストとして固定し、
同じテスト一式を旧・新の両方に当てる。新 backend は Application Factory（`create_app`）、
不変設定（`RuntimeConfig`）、型付きエラー（`ErrorCode` + `SafeError`）、stdout への構造化ログ、
プロセス内メモリのレート制限（`limits`）で構成する。モックは HTTP 境界（`respx`）にだけ置く。

**Tech Stack:** Python 3.12 / FastAPI 0.124 / pydantic 2.12 / pydantic-settings 2.12 /
anthropic 0.39 / openai 2.9 / limits 5.8 / uvicorn 0.40 ／ 検証: pytest 9 + pytest-asyncio 1.3 +
pytest-randomly 5 + respx 0.23 + mypy 2.3 + import-linter 2.14

**Spec:** `docs/plans/2026-08-29-architecture-remediation.md`（§3 決定1・2、§5 Phase 2、§6 完了条件 Phase 2）
／ ADR-001・002・003・004・006 ／ Issue #86（拾うもの・テスト化するバグの形）

---

## Global Constraints

- **1タスクの差分は 400行 / 12ファイルまで**（親計画 §5。ADR-008 は3周ともこれを破って失敗した）。
  削除のみの差分はこの上限に数えない
- **モックは外部 SDK / ネットワーク境界にのみ置く。`patch("app.…")` は 0 件**（完了条件）
- **完全一致アサーションを書かない。** 診断メッセージ・ログ文字列・ライブラリ由来の文字列を
  期待値に固定しない（Issue #86 D）。例外は「外部契約として固定する利用者向け文言」で、
  そのときは契約テストに置く
- **`str(exc)` / `str(e)` / `format_exc` / `print(` / `print_exc` / `sys.stderr` は `app/` に 0 件**
  （`app/logging.py` の出力実装を除く）。stdlib `logging` の import は `app/logging.py` のみ
- **秘密の値をログ・例外・HTTP ボディに載せない。** キー名と種別だけ載せる
- **修正の前にテストを書き、赤を見てから直す**（B の観点テストは赤にならなくてよい）
- **`import-linter` / `mypy --strict` / `pytest-randomly` が緑**
- **検証は最も外側の境界で行う**（HTTP ボディ・プロセスの stdout / stderr）
- コミットメッセージは既存に倣う（`refactor:` / `test:` / `docs:` + 日本語）。末尾に
  `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`
- 作業は worktree（`superpowers:using-git-worktrees`）。ブランチ名 `phase2/backend-rewrite`

---

## 着手前の点検（層1）— 2026-09-02 実施済み

**触る範囲（実測）**: `backend/app/` 3,545行 / 32ファイル、`backend/tests/` 9,391行 / 33ファイル、
`backend/alembic/` 465行、`docker-compose.yml`、`docker/postgres/`、`.github/workflows/python.yml`、
`backend/Dockerfile`、`docker/backend/Dockerfile`、`backend/.env.example`、ルート `.env.example`、
`AGENTS.md`（API仕様・開発コマンド節）、`docs/tech-stack.md`（backend・DB 節）。
frontend は触らない（契約が同じであることを検査で担保する）。

**「負債を作る行為」への該当**（`AGENTS.md`）:

| 行為 | 該当 | 引用する ADR |
|---|---|---|
| 依存の追加 | `limits`（既存の間接依存を直接依存へ。`slowapi` を外す）、`respx` `mypy` `import-linter` `pytest-randomly`（開発依存） | ADR-002（カウンタはプロセス内）、ADR-003 / 004 / 006（検査） |
| 依存の削除 | `sqlalchemy` `alembic` `asyncpg` `psycopg2-binary` `redis` `slowapi` `python-jose` `bcrypt` `python-multipart` | ADR-001 / 002、Issue #86 A |
| 永続化面 | **無し**（DB を消す側） | ADR-001 |
| 秘密を持つ設定キー | 追加なし。`SECRET_KEY` `POSTGRES_PASSWORD` `RATE_LIMIT_STORAGE_URI` を削除 | ADR-001 / 002 |
| モジュールレベルの可変グローバル | 作らない（Factory） | ADR-004 |
| 公開ルート | `GET /` と `GET /health` を**削除**。追加なし | 親計画 §5 Phase 2（3本） |
| 外部送信先 | 追加なし（anthropic / openai のまま） | — |

**道具の生死**: `tsumiki` プラグインは **無効**（`~/.claude/settings.json` の
`"tsumiki@tsumiki": false`）。`tsumiki:dcs:impact-analysis` は上の表で目的を手作業で満たした。
`tsumiki:ipa-security-check`（Phase 2 の締め）は**プラグインを有効にしないと回せない**。
Task 9 で人に確認する。

**実機で確かめた前提（2026-09-02、Python 3.12.11 の検証 venv）**:

| 前提 | 結果 |
|---|---|
| `respx` が anthropic / openai SDK の HTTP を横取りできる | ✅ 200 応答の本文、記号入りキーが `x-api-key` / `Authorization` にそのまま載ることを確認 |
| SDK の例外型 | 429 → `RateLimitError`（**メッセージに応答本文を含む**）、`ReadTimeout` → `APITimeoutError`（`APIConnectionError` の子）、`ConnectError` → `APIConnectionError` |
| **非 ASCII の API キー**は SDK が送信時に `UnicodeEncodeError` | ✅ 両 SDK。→ 設定読み込み時に拒否する（B-1 境界値の発見） |
| `limits` の非同期固定窓（`FixedWindowRateLimiter` + `MemoryStorage`）で namespace × IP 別に数えられる | ✅ `get_window_stats().reset_time` も取れる |
| uvicorn `--workers 2` の子プロセスから `sys.argv` に `--workers 2` が見える／`WEB_CONCURRENCY` が見える | ✅ 両方 |
| `mypy --strict`（pydantic plugin）が SDK・limits・pydantic-settings 込みで緑 | ✅ |
| pydantic `ValidationError` の `str()` は失敗した入力値を含む | ✅ → `config.py` の外へ出さない |
| `SettingsConfigDict(frozen=True, extra="ignore")` | ✅ 代入は `ValidationError`、未知キーは無視 |
| 旧 venv（3.10）に `respx==0.23.1` を入れられる | ✅ dry-run 成功 |
| 旧テストが今も緑（DB コンテナ稼働中） | ✅ health + rate_limit 37 passed |

---

## 決定（この計画で決めたこと。親計画・ADR に無い判断）

| # | 決定 | 理由 | 却下した案 |
|---|---|---|---|
| D1 | **Python 3.12** にする | ADR-003 が `ErrorCode(StrEnum)` を指定（3.11+）。3.10 は 2026-10 に EOL。ローカルに 3.12.11 あり | 3.10 のまま `(str, Enum)`: EOL 直前の版に新規コードを書く理由が無い |
| D2 | **`slowapi` を外し `limits` を直接使う** | slowapi はデコレータとグローバル `app.state.limiter` 前提で Factory と相性が悪い。429 の本文・ヘッダー・IP 判定は元々自前 | slowapi 維持: 動くが、`limiter` をモジュール外で作れず ADR-004 の「import 時に資源を作らない」と衝突 |
| D3 | プロバイダ client は **lifespan で生成**、`ConversionService` を `app.state` に置く | ADR-004 の文言どおり。テストは `TestClient(app)` を `with` で使い lifespan を通す | Factory 内で即生成: テストが楽だが ADR の文言に反する |
| D4 | SDK 内蔵リトライを **0** にし、再試行と締切を `ConversionService` が一元管理 | 旧は SDK 2回 × 自前 1回で最大 6 試行が 10 秒の締切に詰まっていた。試行回数を1箇所で決める | SDK 任せ: 締切との整合を保証できない |
| D5 | **想定外例外は routes と provider の境界で型名だけ拾い `SafeError(INTERNAL_ERROR)` にする** | Starlette は未処理例外を必ず再送出し uvicorn が traceback（`str(exc)` 込み）を stderr に書く。秘密を持ちうる例外を生のまま上へ通さない | グローバルハンドラだけ: 再送出を止められない |
| D6 | **非 ASCII の `API_KEYS` / プロバイダキーを起動時に拒否** | 実機で SDK が送信時に落ちることを確認。起動時の `ConfigError`（キー名のみ）に変える | 旧どおり utf-8 で照合: 通っても送れない |
| D7 | **`ANTHROPIC_BASE_URL` / `OPENAI_BASE_URL`（SDK 標準の環境変数）を起動 smoke に使う** | 新しい設定キーを作らず、実プロセス起動 → SDK → HTTP → 偽プロバイダの往復を検証できる | 自前の `*_BASE_URL` 設定キー: 設定キーの追加になる |
| D8 | import-linter の層を **`config → errors`、`schemas → ai`（PolitenessLevel）** で引く | ADR-006 の草案（`config → 依存なし`）では、設定失敗の型が errors と別に要る。2語彙を持たない | ADR-006 の草案どおり: `ConfigError` を config 内に複製する |

D8 は ADR-006 の改訂（Task 9）。他は ADR の範囲内。

## 廃止リスト（明示的に外部契約から外すもの。契約テストはこれを除いて旧・新同結果）

| 項目 | 旧 | 新 | 理由 |
|---|---|---|---|
| `GET /`、`GET /health`（ルート直付け） | あり | **削除** | 親計画 §5: 公開ルートは3本。frontend は呼ばない |
| `GET /api/v1/health` の `database` フィールド・DB 失敗時の 500 | あり | **削除**（200 のみ） | ADR-001 |
| production / staging で `API_KEYS` 未設定 → リクエスト時 503 | あり | **起動失敗**（`ConfigError`） | Issue #86 B-3-6。到達不能な分岐を作らない |
| 非 ASCII の `API_KEYS` | utf-8 で照合 | **起動失敗** | D6 |
| グローバル 500 の本文 `{"error","detail","error_code"}` | あり | `{"success":false,"data":null,"error":{…}}` に統一 | 残す3本からは到達不能だった。frontend は両形式を読む |
| `X-RateLimit-*` を 200 に付けない | 付けない | 付けない | 変更なし（旧テスト TC002 の契約を維持） |
| ファイルログ（`LOG_FILE_PATH`） | あり | **削除**（stdout のみ） | ADR-001 |
| `RATE_LIMIT_STORAGE_URI` `SECRET_KEY` `POSTGRES_*` `SESSION_EXPIRE_MINUTES` `API_HOST` `API_PORT` `API_V1_STR` `ACCESS_TOKEN_EXPIRE_MINUTES` | 設定キー | **削除**（残っていれば警告のみ） | ADR-001 / 002、Issue #86 B-3-7 |
| health の `ai_provider` | 初期化済みの client 優先 | **実際に使う** `DEFAULT_AI_PROVIDER` | 値域 `anthropic/openai/none` は同じ |
| OpenAPI のスキーマ名（`AIConversionRequest`→`ConversionRequest` 等）と制約の表現 | 旧名 | 新名 | 生成クライアントは無く、frontend は手書き。契約テストはプロパティ名と必須項目を比べる |
| 422 の `detail[].msg` | pydantic の自由文（`Value error, …` 等） | `type` から引く有限語彙（`VALIDATION_MESSAGE`） | ADR-003。frontend は `detail` を読まない |

---

## レビュアーへの拘束ブロック（SDD 条件2。task reviewer の constraints に写す）

```
- ADR-001 backend はステートレス。DB・ファイル出力・サーバー側の利用者状態を作らない
- ADR-002 レート制限はプロセス内メモリ。URI も設定キーも作らない。守るのは単一送信元の burst
- ADR-003 エラーは ErrorCode + SafeError。str(exc) を受け取る引数を作らない。原因は型名のみ。
          except の外で raise する（__context__ を残さない）
- ADR-004 設定は不変（frozen）。Application Factory。import 時に資源を作らない。環境判定は config の1箇所
- ADR-006 import-linter の層: main > routes > schemas > (auth | ratelimit | ai) > config > logging > errors
- テスト規律: モックは HTTP 境界（respx）のみ。patch("app.…") 禁止。完全一致アサーション禁止
          （利用者向け文言の契約は tests/contract にだけ置く）
- 完了条件（親計画 §6 Phase 2）を満たさない指摘は P0 にしない。P0 = 到達経路 + 実際に赤を見せた
- Critical→P0 / Important→P1 / Minor→P2。P2 は台帳 #85 へ直行（ループに入れない）
- 1タスクの差分は 400行 / 12ファイルまで（削除は除く）
```

---

## File Structure（到達点）

```
backend/
  app/
    __init__.py
    errors.py        ErrorCode(StrEnum) / SafeError / RateLimitExceeded / ConfigError / HTTP_STATUS / USER_MESSAGE
    logging.py       stdout JSON Lines。型付きイベントだけを受け取る。stdlib logging を import できる唯一の場所
    config.py        RuntimeConfig(frozen) / load_config() / REMOVED_SETTINGS / 環境判定（唯一の場所）
    schemas.py       ConversionRequest / RegenerateRequest / ConversionResponse / HealthResponse
    auth.py          is_valid_api_key / build_require_api_key（hmac.compare_digest、全キー走査）
    ratelimit.py     client_identifier（XFF）/ RateLimiter（limits FixedWindow + MemoryStorage）
    ai/
      __init__.py
      prompts.py     PolitenessLevel / Prompt / conversion_prompt / regeneration_prompt
      providers.py   Provider(Protocol) / AnthropicProvider / OpenAIProvider / build_provider（SDK 境界）
      service.py     ConversionService（再試行・締切を一元管理）
    routes.py        build_router: GET /health, POST /ai/convert, POST /ai/regenerate
    main.py          create_app(config=None, *, provider_factory, environ, argv) / configured_worker_count
  tests/
    __init__.py
    conftest.py               新 backend 用: make_config() / make_client()
    contract/                 旧・新の両方に当てる characterization テスト（Task 1・2 で旧に当てて固定）
      __init__.py  conftest.py  openapi_baseline.json  dump_openapi.py
      test_ai.py  test_health_docs.py  test_auth.py  test_ratelimit.py  test_cors.py  test_openapi.py
    test_errors.py  test_logging.py  test_config.py  test_schemas.py  test_auth.py  test_ratelimit.py
    ai/test_prompts.py  ai/test_providers.py  ai/test_service.py
    test_routes.py  test_sinks.py  test_startup.py
  scripts/gates.sh            grep ゲート（完了条件の grep をそのまま実行する。枠組みは持たない）
  requirements.txt            本番依存のみ
  requirements-dev.txt        検証依存
  pyproject.toml              ruff / black / mypy strict / importlinter / pytest / coverage
  Dockerfile                  python:3.12-slim、`uvicorn app.main:create_app --factory`
```

削除するもの: `app/api/ app/core/ app/crud/ app/db/ app/models/ app/schemas/ app/utils/`、
`alembic/ alembic.ini`、旧 `tests/`（`tests/contract/` 以外）、`docker/postgres/`、
`backend/logs/`、`backend/Makefile` の `test-cov` 以外は残す。

---

## 実行順序と各タスクの検証コマンド

| Task | 内容 | 当てる実装 | venv |
|---|---|---|---|
| 1 | 契約テスト（AI・health・docs）を書き、旧に当てて緑 | 旧 | `backend/.venv`（3.10、respx を追加） |
| 2 | 契約テスト（認証・レート制限・CORS・OpenAPI baseline）を書き、旧に当てて緑 | 旧 | 同上 |
| 3 | `errors.py` + `logging.py`（新規ファイル。旧と共存） | 新 | 3.12 venv（このタスクで作る） |
| 4 | `config.py` | 新 | 3.12 |
| 5 | `ai/`（prompts / providers / service） | 新 | 3.12 |
| 6 | `schemas.py` + `auth.py` + `ratelimit.py` | 新 | 3.12 |
| 7 | `main.py` + `routes.py`、**旧の削除**、契約テストが新で緑 | 新 | 3.12 |
| 8 | canary（全シンク）・起動 smoke・起動ガード・CI・Docker・gates | 新 | 3.12 |
| 9 | 文書（AGENTS.md / tech-stack / ADR-006 改訂）・台帳・2系統レビュー・PR | — | — |

Task 1〜2 は worktree で旧を動かす。worktree には `backend/.env` が無いので
`cp /Volumes/external/dev/kotonoha/backend/.env <worktree>/backend/.env` してから実行する
（旧の `/health` は DB 接続を要求する。`kotonoha_postgres` コンテナが稼働中であること）。
旧 venv は main 側の `/Volumes/external/dev/kotonoha/backend/.venv/bin/pytest` を worktree の
`backend/` を cwd にして呼ぶ（`tests/__init__.py` があるので rootdir が sys.path に入り、
worktree 側の `app` が import される）。

---

### Task 1: 契約テスト（AI 変換・health・docs）を書き、旧実装に当てて固定する

**Files:**
- Create: `backend/tests/contract/__init__.py`（空）
- Create: `backend/tests/contract/conftest.py`
- Create: `backend/tests/contract/test_ai.py`
- Create: `backend/tests/contract/test_health_docs.py`

**Interfaces:**
- Produces: `contract_env`（session fixture。旧・新共通の環境変数）、`app`（session）、
  `client`（`TestClient`、lifespan 込み）、`provider_http`（respx mock）、`fresh_ip()`、
  `ANTHROPIC_OK` `anthropic_success(text)`（Task 2・7・8 が使う）
- Consumes: 旧実装 `app.main:app`。新実装は `app.main:create_app()`（Task 7）

**契約テストの決まり**: 旧・新のどちらを import しているかは `build_app()` だけが知る。
テスト本文に `if 旧:` を書かない（廃止リストは Task 2 の OpenAPI テストにだけ現れる）。
利用者向け文言の完全一致は**ここだけ**に置く（外部契約だから）。

- [ ] **Step 1: 旧 venv に respx を入れる**

```bash
/Volumes/external/dev/kotonoha/backend/.venv/bin/pip install "respx==0.23.1"
```

- [ ] **Step 2: conftest を書く**

`backend/tests/contract/conftest.py`:

```python
"""旧・新の両実装に同じ契約テストを当てるための土台。

どちらを試験しているかを知るのは build_app() だけ。旧実装は import 時に設定を読むため、
環境変数は import より前に（session fixture で）置く。
"""

from __future__ import annotations

import itertools
from collections.abc import Iterator

import httpx
import pytest
import respx
from fastapi import FastAPI
from fastapi.testclient import TestClient

CONTRACT_ENV: dict[str, str] = {
    "ENVIRONMENT": "test",
    "API_KEYS": "contract-key-A,contract-key-B",
    "ANTHROPIC_API_KEY": "sk-contract-anthropic",
    "OPENAI_API_KEY": "",
    "DEFAULT_AI_PROVIDER": "anthropic",
    "CORS_ORIGINS": "http://localhost:3000,http://localhost:5173",
    "RATE_LIMIT_TIMES": "1",
    "RATE_LIMIT_SECONDS": "1",
    "TRUSTED_PROXY_COUNT": "1",  # テストごとに X-Forwarded-For で送信元を分け、カウンタを独立させる
    "AI_MAX_RETRIES": "0",
    "AI_API_TIMEOUT": "10",
    "AI_CALL_DEADLINE_SECONDS": "4",
    "LOG_LEVEL": "WARNING",
}

ANTHROPIC_MESSAGES_URL = "https://api.anthropic.com/v1/messages"

ANTHROPIC_OK: dict[str, object] = {
    "id": "msg_contract",
    "type": "message",
    "role": "assistant",
    "model": "claude-contract",
    "content": [{"type": "text", "text": "お水をぬるめでお願いします"}],
    "stop_reason": "end_turn",
    "stop_sequence": None,
    "usage": {"input_tokens": 1, "output_tokens": 1},
}

_ip_counter = itertools.count(1)


def fresh_ip() -> str:
    """テストごとに別の送信元 IP。レート制限のカウンタを共有しないため。"""
    n = next(_ip_counter)
    return f"10.{(n >> 16) & 255}.{(n >> 8) & 255}.{n & 255}"


def anthropic_success(text: str) -> httpx.Response:
    body = dict(ANTHROPIC_OK)
    body["content"] = [{"type": "text", "text": text}]
    return httpx.Response(200, json=body)


def build_app() -> FastAPI:
    import app.main as main_module

    factory = getattr(main_module, "create_app", None)
    if factory is not None:
        return factory()  # 新: Application Factory（環境変数から設定を組む）
    return main_module.app  # 旧: モジュールレベルの app


@pytest.fixture(scope="session")
def contract_env() -> Iterator[None]:
    with pytest.MonkeyPatch.context() as mp:
        for key, value in CONTRACT_ENV.items():
            mp.setenv(key, value)
        yield


@pytest.fixture(scope="session")
def app(contract_env: None) -> FastAPI:
    return build_app()


@pytest.fixture
def client(app: FastAPI) -> Iterator[TestClient]:
    with TestClient(app, raise_server_exceptions=False) as test_client:
        yield test_client


@pytest.fixture
def provider_http() -> Iterator[respx.MockRouter]:
    """AI プロバイダの HTTP 境界。ここより内側（SDK・自分の関数）はモックしない。"""
    with respx.mock(assert_all_called=False, assert_all_mocked=True) as router:
        router.post(ANTHROPIC_MESSAGES_URL).mock(return_value=anthropic_success("お水をぬるめでお願いします"))
        yield router


@pytest.fixture
def headers() -> dict[str, str]:
    return {"X-API-Key": "contract-key-A", "X-Forwarded-For": fresh_ip()}
```

- [ ] **Step 3: AI 変換の契約テストを書く**

`backend/tests/contract/test_ai.py`:

```python
"""POST /api/v1/ai/convert と /regenerate の外部契約。"""

from __future__ import annotations

import asyncio

import httpx
import pytest
import respx
from fastapi.testclient import TestClient

from tests.contract.conftest import ANTHROPIC_MESSAGES_URL, anthropic_success

CONVERT = "/api/v1/ai/convert"
REGENERATE = "/api/v1/ai/regenerate"
ERROR_SHAPE_KEYS = {"success", "data", "error"}


def _post_convert(client: TestClient, headers: dict[str, str], **body: object) -> httpx.Response:
    payload: dict[str, object] = {"input_text": "水 ぬるく", "politeness_level": "normal"}
    payload.update(body)
    return client.post(CONVERT, json=payload, headers=headers)


def test_convert_returns_flat_body(client: TestClient, headers: dict[str, str], provider_http: respx.MockRouter) -> None:
    response = _post_convert(client, headers, input_text="  水 ぬるく  ", politeness_level="polite")
    assert response.status_code == 200
    body = response.json()
    assert set(body) == {"converted_text", "original_text", "politeness_level", "processing_time_ms"}
    assert body["converted_text"] == "お水をぬるめでお願いします"
    assert body["original_text"] == "水 ぬるく"  # 前後の空白は落として返す
    assert body["politeness_level"] == "polite"
    assert isinstance(body["processing_time_ms"], int) and body["processing_time_ms"] >= 0
    for name in ("x-ratelimit-limit", "x-ratelimit-remaining", "x-ratelimit-reset"):
        assert name not in response.headers


def test_regenerate_returns_flat_body(client: TestClient, headers: dict[str, str], provider_http: respx.MockRouter) -> None:
    response = client.post(
        REGENERATE,
        json={"input_text": "水 ぬるく", "politeness_level": "normal", "previous_result": "お水をください"},
        headers=headers,
    )
    assert response.status_code == 200
    assert set(response.json()) == {"converted_text", "original_text", "politeness_level", "processing_time_ms"}


@pytest.mark.parametrize(
    "body",
    [
        {"input_text": "あ"},
        {"input_text": "あ" * 501},
        {"input_text": "   "},
        {"input_text": ""},
        {"politeness_level": "very_polite"},
        {"input_text": None},
        {"politeness_level": None},
    ],
)
def test_convert_validation_error_shape(client: TestClient, headers: dict[str, str], body: dict[str, object]) -> None:
    payload: dict[str, object] = {"input_text": "水 ぬるく", "politeness_level": "normal"}
    payload.update(body)
    payload = {k: v for k, v in payload.items() if v is not None}
    response = client.post(CONVERT, json=payload, headers=headers)
    assert response.status_code == 422
    data = response.json()
    assert data["error_code"] == "VALIDATION_ERROR"
    assert isinstance(data["error"], str)
    assert isinstance(data["detail"], list) and data["detail"]
    assert {"type", "loc", "msg"} <= set(data["detail"][0])


@pytest.mark.parametrize("previous_result", ["", "   ", "あ" * 1001])
def test_regenerate_previous_result_validation(client: TestClient, headers: dict[str, str], previous_result: str) -> None:
    response = client.post(
        REGENERATE,
        json={"input_text": "水 ぬるく", "politeness_level": "normal", "previous_result": previous_result},
        headers=headers,
    )
    assert response.status_code == 422
    assert response.json()["error_code"] == "VALIDATION_ERROR"


def test_invalid_json_is_validation_error(client: TestClient, headers: dict[str, str]) -> None:
    response = client.post(CONVERT, content=b"{not json", headers={**headers, "Content-Type": "application/json"})
    assert response.status_code == 422
    assert response.json()["error_code"] == "VALIDATION_ERROR"


def _assert_error_shape(response: httpx.Response, status: int, code: str) -> dict[str, object]:
    assert response.status_code == status
    data = response.json()
    assert set(data) == ERROR_SHAPE_KEYS
    assert data["success"] is False and data["data"] is None
    error = data["error"]
    assert error["code"] == code
    assert error["status_code"] == status
    assert isinstance(error["message"], str) and error["message"]
    return error


def test_provider_timeout_is_504(client: TestClient, headers: dict[str, str], provider_http: respx.MockRouter) -> None:
    provider_http.post(ANTHROPIC_MESSAGES_URL).mock(side_effect=httpx.ReadTimeout("read timed out"))
    _assert_error_shape(_post_convert(client, headers), 504, "AI_API_TIMEOUT")


def test_provider_rate_limit_is_429(client: TestClient, headers: dict[str, str], provider_http: respx.MockRouter) -> None:
    provider_http.post(ANTHROPIC_MESSAGES_URL).mock(
        return_value=httpx.Response(429, json={"type": "error", "error": {"type": "rate_limit_error", "message": "CANARY-PROVIDER-429"}})
    )
    response = _post_convert(client, headers)
    _assert_error_shape(response, 429, "AI_RATE_LIMIT")
    assert "CANARY-PROVIDER-429" not in response.text


def test_provider_server_error_is_500(client: TestClient, headers: dict[str, str], provider_http: respx.MockRouter) -> None:
    provider_http.post(ANTHROPIC_MESSAGES_URL).mock(
        return_value=httpx.Response(500, json={"type": "error", "error": {"type": "api_error", "message": "CANARY-PROVIDER-500"}})
    )
    response = _post_convert(client, headers)
    _assert_error_shape(response, 500, "AI_API_ERROR")
    assert "CANARY-PROVIDER-500" not in response.text


def test_provider_empty_content_is_500(client: TestClient, headers: dict[str, str], provider_http: respx.MockRouter) -> None:
    body = {**anthropic_success("x").json(), "content": []}
    provider_http.post(ANTHROPIC_MESSAGES_URL).mock(return_value=httpx.Response(200, json=body))
    _assert_error_shape(_post_convert(client, headers), 500, "AI_API_ERROR")


def test_deadline_exceeded_is_504(client: TestClient, headers: dict[str, str], provider_http: respx.MockRouter) -> None:
    async def slow(request: httpx.Request) -> httpx.Response:
        await asyncio.sleep(8)  # AI_CALL_DEADLINE_SECONDS=4 より長い
        return anthropic_success("遅い")

    provider_http.post(ANTHROPIC_MESSAGES_URL).mock(side_effect=slow)
    _assert_error_shape(_post_convert(client, headers), 504, "AI_API_TIMEOUT")
```

- [ ] **Step 4: health / docs の契約テストを書く**

`backend/tests/contract/test_health_docs.py`:

```python
"""GET /api/v1/health と、test 環境での /docs・/openapi.json 公開。"""

from __future__ import annotations

from datetime import datetime

from fastapi.testclient import TestClient

HEALTH = "/api/v1/health"


def test_health_is_ok_without_auth(client: TestClient) -> None:
    response = client.get(HEALTH)
    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "ok"
    assert body["ai_provider"] in {"anthropic", "openai", "none"}
    assert body["version"] == "1.0.0"
    assert body["timestamp"].endswith("Z")
    datetime.strptime(body["timestamp"], "%Y-%m-%dT%H:%M:%SZ")


def test_health_is_not_rate_limited(client: TestClient) -> None:
    for _ in range(3):
        assert client.get(HEALTH).status_code == 200


def test_docs_are_published_in_test_environment(client: TestClient) -> None:
    assert client.get("/docs").status_code == 200
    assert "text/html" in client.get("/docs").headers["content-type"]
    spec = client.get("/openapi.json")
    assert spec.status_code == 200
    assert {"openapi", "info", "paths"} <= set(spec.json())
```

- [ ] **Step 5: 旧実装に当てて緑を確認する**

```bash
cd <worktree>/backend
cp /Volumes/external/dev/kotonoha/backend/.env .env   # 旧の /health は DB を要求する
/Volumes/external/dev/kotonoha/backend/.venv/bin/pytest tests/contract -p no:cacheprovider -q
```

Expected: 全件 PASS（`test_deadline_exceeded_is_504` は約4秒かかる）。
赤が出たら**契約テスト側が旧実装を誤解している**ので、旧のコードを読んで直す（旧は触らない）。

- [ ] **Step 6: コミット**

```bash
git add backend/tests/contract/__init__.py backend/tests/contract/conftest.py backend/tests/contract/test_ai.py backend/tests/contract/test_health_docs.py
git commit -m "test: 旧 backend の外部契約を characterization テストとして固定する（AI変換・health・docs）(Phase 2 / Task 1)"
```

---

### Task 2: 契約テスト（認証・レート制限・CORS・OpenAPI baseline）を書き、旧実装に当てて固定する

**Files:**
- Create: `backend/tests/contract/test_auth.py`
- Create: `backend/tests/contract/test_ratelimit.py`
- Create: `backend/tests/contract/test_cors.py`
- Create: `backend/tests/contract/dump_openapi.py`
- Create: `backend/tests/contract/openapi_baseline.json`（旧から生成して**コミット**する）
- Create: `backend/tests/contract/test_openapi.py`

**Interfaces:**
- Consumes: Task 1 の `client` `headers` `provider_http` `fresh_ip` `app`
- Produces: `normalize_openapi(spec)`（Task 7 が新実装の diff に使う）、`DEPRECATIONS`（廃止リストの機械可読版）

- [ ] **Step 1: 認証の契約テスト**

`backend/tests/contract/test_auth.py`:

```python
"""X-API-Key 認証。Issue #86 B-3-3（非ASCII → 401）・B-3-4（全キー走査）。"""

from __future__ import annotations

import pytest
import respx
from fastapi.testclient import TestClient

from tests.contract.conftest import fresh_ip

CONVERT = "/api/v1/ai/convert"
BODY = {"input_text": "水 ぬるく", "politeness_level": "normal"}


def test_missing_key_is_401_with_www_authenticate(client: TestClient) -> None:
    response = client.post(CONVERT, json=BODY, headers={"X-Forwarded-For": fresh_ip()})
    assert response.status_code == 401
    assert response.headers["www-authenticate"] == "X-API-Key"
    assert isinstance(response.json()["detail"], str)


def test_wrong_key_is_401(client: TestClient) -> None:
    response = client.post(CONVERT, json=BODY, headers={"X-API-Key": "contract-key-Z", "X-Forwarded-For": fresh_ip()})
    assert response.status_code == 401


@pytest.mark.parametrize("key", ["contract-key-A", "contract-key-B"])
def test_every_configured_key_is_accepted(client: TestClient, provider_http: respx.MockRouter, key: str) -> None:
    response = client.post(CONVERT, json=BODY, headers={"X-API-Key": key, "X-Forwarded-For": fresh_ip()})
    assert response.status_code == 200


def test_non_ascii_key_is_401_not_500(client: TestClient) -> None:
    response = client.post(
        CONVERT, json=BODY, headers={"X-API-Key": "ｋｅｙ".encode("utf-8").decode("latin-1"), "X-Forwarded-For": fresh_ip()}
    )
    assert response.status_code == 401


def test_unauthenticated_burst_never_reaches_rate_limit(client: TestClient) -> None:
    """認証は制限より前。不正キーの連打は 401 のままで 429 に変わらない（プロバイダにも届かない）。"""
    ip = fresh_ip()
    for _ in range(3):
        response = client.post(CONVERT, json=BODY, headers={"X-API-Key": "bad", "X-Forwarded-For": ip})
        assert response.status_code == 401
```

- [ ] **Step 2: レート制限の契約テスト**

`backend/tests/contract/test_ratelimit.py`:

```python
"""IP ごとの burst 抑制（ADR-002）。B-3-8 / B-3-9（XFF の扱い）を含む。"""

from __future__ import annotations

import time

import respx
from fastapi.testclient import TestClient

from tests.contract.conftest import CONTRACT_ENV, fresh_ip

CONVERT = "/api/v1/ai/convert"
REGENERATE = "/api/v1/ai/regenerate"
BODY = {"input_text": "水 ぬるく", "politeness_level": "normal"}
REGEN_BODY = {**BODY, "previous_result": "お水をください"}
WINDOW = int(CONTRACT_ENV["RATE_LIMIT_SECONDS"])


def _headers(ip: str) -> dict[str, str]:
    return {"X-API-Key": "contract-key-A", "X-Forwarded-For": ip}


def test_second_request_in_window_is_429(client: TestClient, provider_http: respx.MockRouter) -> None:
    ip = fresh_ip()
    assert client.post(CONVERT, json=BODY, headers=_headers(ip)).status_code == 200
    response = client.post(CONVERT, json=BODY, headers=_headers(ip))
    assert response.status_code == 429
    data = response.json()
    assert data["success"] is False and data["data"] is None
    error = data["error"]
    assert error["code"] == "RATE_LIMIT_EXCEEDED"
    assert error["status_code"] == 429
    assert error["message"] == "リクエスト数が上限に達しました。しばらく待ってから再試行してください。"
    assert isinstance(error["retry_after"], int) and 1 <= error["retry_after"] <= WINDOW
    assert 1 <= int(response.headers["retry-after"]) <= WINDOW
    assert response.headers["x-ratelimit-limit"] == CONTRACT_ENV["RATE_LIMIT_TIMES"]
    assert response.headers["x-ratelimit-remaining"] == "0"
    assert 1 <= int(response.headers["x-ratelimit-reset"]) <= WINDOW


def test_limit_resets_after_window(client: TestClient, provider_http: respx.MockRouter) -> None:
    ip = fresh_ip()
    assert client.post(CONVERT, json=BODY, headers=_headers(ip)).status_code == 200
    time.sleep(WINDOW + 0.2)
    assert client.post(CONVERT, json=BODY, headers=_headers(ip)).status_code == 200


def test_convert_and_regenerate_have_independent_counters(client: TestClient, provider_http: respx.MockRouter) -> None:
    ip = fresh_ip()
    assert client.post(CONVERT, json=BODY, headers=_headers(ip)).status_code == 200
    assert client.post(REGENERATE, json=REGEN_BODY, headers=_headers(ip)).status_code == 200
    assert client.post(REGENERATE, json=REGEN_BODY, headers=_headers(ip)).status_code == 429


def test_different_sources_are_independent(client: TestClient, provider_http: respx.MockRouter) -> None:
    assert client.post(CONVERT, json=BODY, headers=_headers(fresh_ip())).status_code == 200
    assert client.post(CONVERT, json=BODY, headers=_headers(fresh_ip())).status_code == 200


def test_rightmost_trusted_hop_is_used_not_leftmost(client: TestClient, provider_http: respx.MockRouter) -> None:
    """B-3-9: 左端（クライアントが自由に書ける値）を信じない。TRUSTED_PROXY_COUNT=1 なら右端。"""
    trusted = fresh_ip()
    first = client.post(CONVERT, json=BODY, headers=_headers(f"{fresh_ip()}, {trusted}"))
    second = client.post(CONVERT, json=BODY, headers=_headers(f"{fresh_ip()}, {trusted}"))
    assert (first.status_code, second.status_code) == (200, 429)


def test_missing_forwarded_for_falls_back_to_peer_address(client: TestClient, provider_http: respx.MockRouter) -> None:
    """B-3-9: チェーンが段数に満たなければ XFF を採用せず接続元へ（フェイルクローズ）。"""
    no_xff = {"X-API-Key": "contract-key-A"}
    first = client.post(CONVERT, json=BODY, headers=no_xff)
    second = client.post(CONVERT, json=BODY, headers=no_xff)
    assert (first.status_code, second.status_code) == (200, 429)
```

- [ ] **Step 3: CORS の契約テスト**

`backend/tests/contract/test_cors.py`:

```python
from __future__ import annotations

from fastapi.testclient import TestClient

HEALTH = "/api/v1/health"


def test_allowed_origin_is_echoed(client: TestClient) -> None:
    response = client.get(HEALTH, headers={"Origin": "http://localhost:3000"})
    assert response.status_code == 200
    assert response.headers["access-control-allow-origin"] == "http://localhost:3000"
    assert response.headers["access-control-allow-credentials"] == "true"


def test_preflight_is_answered(client: TestClient) -> None:
    response = client.options(
        "/api/v1/ai/convert",
        headers={
            "Origin": "http://localhost:5173",
            "Access-Control-Request-Method": "POST",
            "Access-Control-Request-Headers": "content-type,x-api-key",
        },
    )
    assert response.status_code == 200
    assert response.headers["access-control-allow-origin"] == "http://localhost:5173"
    assert "POST" in response.headers["access-control-allow-methods"]
    assert "x-api-key" in response.headers["access-control-allow-headers"].lower()


def test_unknown_origin_gets_no_cors_header(client: TestClient) -> None:
    response = client.get(HEALTH, headers={"Origin": "http://malicious.example"})
    assert "access-control-allow-origin" not in response.headers
```

- [ ] **Step 4: OpenAPI の正規化と baseline 生成**

`backend/tests/contract/dump_openapi.py`:

```python
"""app.openapi() を (パス, メソッド) を identity に正規化する。権威（FastAPI）の出力を消費するだけで、独自パーサは持たない。

使い方: python -m tests.contract.dump_openapi > tests/contract/openapi_baseline.json
"""

from __future__ import annotations

import json
import sys
from typing import Any

Normalized = dict[str, dict[str, Any]]


def _resolve(spec: dict[str, Any], schema: dict[str, Any] | None) -> dict[str, Any] | None:
    if schema is None:
        return None
    ref = schema.get("$ref")
    if isinstance(ref, str) and ref.startswith("#/components/schemas/"):
        schema = spec["components"]["schemas"][ref.rsplit("/", 1)[1]]
    return {
        "required": sorted(schema.get("required", [])),
        "properties": sorted(schema.get("properties", {})),
    }


def _body_schema(spec: dict[str, Any], holder: dict[str, Any] | None) -> dict[str, Any] | None:
    if not holder:
        return None
    content = holder.get("content", {})
    media = content.get("application/json")
    return _resolve(spec, media.get("schema") if media else None)


def normalize_openapi(spec: dict[str, Any]) -> Normalized:
    out: Normalized = {}
    for path, methods in spec["paths"].items():
        for method, operation in methods.items():
            responses = operation.get("responses", {})
            out[f"{method.upper()} {path}"] = {
                "responses": sorted(responses),
                "security": sorted(sorted(s) for s in operation.get("security", [])),
                "request": _body_schema(spec, operation.get("requestBody")),
                "response_200": _body_schema(spec, responses.get("200")),
            }
    return out


if __name__ == "__main__":
    from tests.contract.conftest import CONTRACT_ENV, build_app
    import os

    os.environ.update(CONTRACT_ENV)
    json.dump(normalize_openapi(build_app().openapi()), sys.stdout, ensure_ascii=False, indent=2, sort_keys=True)
    sys.stdout.write("\n")
```

生成（旧に対して、worktree の `backend/` で）:

```bash
/Volumes/external/dev/kotonoha/backend/.venv/bin/python -m tests.contract.dump_openapi > tests/contract/openapi_baseline.json
cat tests/contract/openapi_baseline.json
```

Expected: キーが `GET /`, `GET /health`, `GET /api/v1/health`, `POST /api/v1/ai/convert`,
`POST /api/v1/ai/regenerate` の5つ。convert / regenerate の `security` に `APIKeyHeader`、
`responses` が `["200", "422"]`。`GET /api/v1/health` の `responses` が `["200", "500"]`、
`response_200.properties` が `ai_provider, database, status, timestamp, version`。

- [ ] **Step 5: OpenAPI diff テスト（廃止リスト入り）**

`backend/tests/contract/test_openapi.py`:

```python
"""旧・新の正規化 OpenAPI diff が、廃止リストを除いて空であること（完了条件）。identity は (パス, メソッド)。"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from fastapi import FastAPI

from tests.contract.dump_openapi import Normalized, normalize_openapi

BASELINE = Path(__file__).with_name("openapi_baseline.json")

# 廃止リスト（計画書「廃止リスト」と1対1）。新実装にだけ適用する。
REMOVED_OPERATIONS: frozenset[str] = frozenset({"GET /", "GET /health"})
CHANGED_OPERATIONS: dict[str, dict[str, Any]] = {
    "GET /api/v1/health": {
        "responses": ["200"],
        "security": [],
        "request": None,
        "response_200": {
            "required": ["ai_provider", "status", "timestamp", "version"],
            "properties": ["ai_provider", "status", "timestamp", "version"],
        },
    },
}


def _is_legacy(app: FastAPI) -> bool:
    import app.main as main_module

    return not hasattr(main_module, "create_app")


def _expected(baseline: Normalized, legacy: bool) -> Normalized:
    if legacy:
        return baseline
    kept = {k: v for k, v in baseline.items() if k not in REMOVED_OPERATIONS}
    kept.update(CHANGED_OPERATIONS)
    return kept


def test_normalized_openapi_matches_baseline(app: FastAPI) -> None:
    baseline: Normalized = json.loads(BASELINE.read_text(encoding="utf-8"))
    current = normalize_openapi(app.openapi())
    expected = _expected(baseline, _is_legacy(app))
    assert current == expected, {
        "missing": sorted(set(expected) - set(current)),
        "unexpected": sorted(set(current) - set(expected)),
        "different": sorted(k for k in expected if k in current and current[k] != expected[k]),
    }
```

- [ ] **Step 6: 旧実装に当てて緑を確認する**

```bash
cd <worktree>/backend
/Volumes/external/dev/kotonoha/backend/.venv/bin/pytest tests/contract -p no:cacheprovider -q
```

Expected: 全件 PASS。件数を記録する（Task 7 で新実装に同じコマンドを当て、同じ件数が緑になることを示す）。

- [ ] **Step 7: コミット**

```bash
git add backend/tests/contract/
git commit -m "test: 旧 backend の外部契約を固定する（認証・レート制限・CORS・OpenAPI baseline）(Phase 2 / Task 2)"
```

---

### Task 3: 3.12 の venv と依存を整え、`errors.py` と `logging.py` を書く

旧と共存する新規ファイルだけを作る（旧 `app/core/…` は触らない）。

**Files:**
- Modify: `backend/requirements.txt`（本番依存のみに書き換え）
- Create: `backend/requirements-dev.txt`
- Modify: `backend/pyproject.toml`
- Create: `backend/app/errors.py`
- Create: `backend/app/logging.py`
- Create: `backend/tests/test_errors.py`
- Create: `backend/tests/test_logging.py`

**Interfaces:**
- Produces: `ErrorCode`, `SafeError(code, *, cause: type[BaseException] | None, retryable: bool)`,
  `RateLimitExceeded(*, retry_after_seconds: int, limit: int)`, `ConfigError(problems: tuple[tuple[str, str], ...])`,
  `HTTP_STATUS`, `USER_MESSAGE`；`configure_logging(level)`, `log_event(event, *, level="INFO")`,
  イベント dataclass `ConversionCompleted` `RequestFailed` `RemovedSettingIgnored` `AuthenticationSkipped` `ProviderConfigured`,
  `LogLevel`

- [ ] **Step 1: 依存ファイルを書き換える**

`backend/requirements.txt`（本番。ADR-001 / 002 により DB・Redis 系は無い）:

```
fastapi==0.124.0
uvicorn[standard]==0.40.0
pydantic==2.12.5
pydantic-settings==2.12.0
httpx==0.28.1
anthropic==0.39.0
openai==2.9.0
limits==5.8.0
```

`backend/requirements-dev.txt`:

```
-r requirements.txt
pytest==9.0.2
pytest-asyncio==1.3.0
pytest-cov==7.0.0
pytest-randomly==5.0.0
respx==0.23.1
ruff==0.14.7
black==26.1.0
mypy==2.3.1
import-linter==2.14
```

- [ ] **Step 2: pyproject.toml を書き換える**

`backend/pyproject.toml` 全文:

```toml
[tool.ruff]
line-length = 100
target-version = "py312"

[tool.ruff.lint]
select = ["E", "F", "I", "N", "W", "B", "ANN", "S", "C90"]
ignore = ["S101"]

[tool.ruff.lint.per-file-ignores]
"tests/*" = ["S101", "ANN", "E501", "N802", "S105", "S106"]
# FastAPI の Depends()/Security() を既定値に置く形は B008 の例外
"app/routes.py" = ["B008"]
"app/auth.py" = ["B008"]

[tool.black]
line-length = 100
target-version = ["py312"]

[tool.mypy]
strict = true
python_version = "3.12"
plugins = ["pydantic.mypy"]
files = ["app"]

[tool.importlinter]
root_package = "app"

# ADR-006。上の層は下の層を import してよい。逆は禁止。`|` は互いに import しない兄弟
[[tool.importlinter.contracts]]
name = "ADR-006 layers"
type = "layers"
layers = [
    "app.main",
    "app.routes",
    "app.schemas",
    "app.auth | app.ratelimit | app.ai",
    "app.config",
    "app.logging",
    "app.errors",
]

[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = "test_*.py"
asyncio_mode = "auto"
asyncio_default_fixture_loop_scope = "function"
asyncio_default_test_loop_scope = "function"

[tool.coverage.run]
source = ["app"]

[tool.coverage.report]
fail_under = 80
```

- [ ] **Step 3: 3.12 の venv を作る**

```bash
cd <worktree>/backend
rm -rf .venv
uv venv --python 3.12 .venv
uv pip install -p .venv/bin/python -r requirements-dev.txt
.venv/bin/python --version   # Python 3.12.x
```

- [ ] **Step 4: errors.py のテストを書く**

`backend/tests/test_errors.py`:

```python
"""ADR-003: SafeError は code と原因の型名しか持たない。"""

from __future__ import annotations

import pytest

from app.errors import HTTP_STATUS, USER_MESSAGE, ConfigError, ErrorCode, RateLimitExceeded, SafeError


def test_every_code_has_status_and_message() -> None:
    for code in ErrorCode:
        assert code in HTTP_STATUS
        assert code in USER_MESSAGE


def test_safe_error_str_is_the_code_only() -> None:
    err = SafeError(ErrorCode.AI_API_ERROR, cause=ValueError)
    assert str(err) == "AI_API_ERROR"
    assert err.cause_type == "ValueError"
    assert err.retryable is False


def test_safe_error_has_no_message_parameter() -> None:
    with pytest.raises(TypeError):
        SafeError(ErrorCode.AI_API_ERROR, "CANARY-free-text")  # type: ignore[misc]


def test_raising_outside_except_leaves_no_context() -> None:
    cause: type[BaseException] | None = None
    try:
        raise ValueError("CANARY-secret")
    except ValueError as exc:
        cause = type(exc)
    with pytest.raises(SafeError) as info:
        raise SafeError(ErrorCode.INTERNAL_ERROR, cause=cause)
    assert info.value.__context__ is None
    assert "CANARY-secret" not in repr(info.value)


def test_rate_limit_exceeded_carries_numbers() -> None:
    err = RateLimitExceeded(retry_after_seconds=7, limit=1)
    assert err.code is ErrorCode.RATE_LIMIT_EXCEEDED
    assert (err.retry_after_seconds, err.limit) == (7, 1)


def test_config_error_lists_keys_and_kinds_only() -> None:
    err = ConfigError((("API_KEYS", "missing"), ("RATE_LIMIT_TIMES", "int_parsing")))
    text = str(err)
    assert text.startswith("CONFIG_INVALID")
    assert "API_KEYS" in text and "int_parsing" in text
```

- [ ] **Step 5: 赤を確認する**

```bash
.venv/bin/pytest tests/test_errors.py -q
```

Expected: `ModuleNotFoundError: No module named 'app.errors'`

- [ ] **Step 6: errors.py を書く**

`backend/app/errors.py`:

```python
"""エラーは型で表現する（ADR-003）。

このモジュールは ``ErrorCode`` と ``SafeError`` の系統しか提供しない。例外メッセージ
例外のメッセージ文字列を受け取る引数はどこにも無い。原因例外は *型名* だけを保持する。
"""

from __future__ import annotations

from collections.abc import Mapping
from enum import StrEnum
from types import MappingProxyType
from typing import Final


class ErrorCode(StrEnum):
    """外へ出してよい語彙。足りなければここに足す（自由文字列に戻さない）。"""

    VALIDATION_ERROR = "VALIDATION_ERROR"
    AUTHENTICATION_ERROR = "AUTHENTICATION_ERROR"
    RATE_LIMIT_EXCEEDED = "RATE_LIMIT_EXCEEDED"
    AI_API_TIMEOUT = "AI_API_TIMEOUT"
    AI_PROVIDER_ERROR = "AI_PROVIDER_ERROR"
    AI_RATE_LIMIT = "AI_RATE_LIMIT"
    AI_API_ERROR = "AI_API_ERROR"
    INTERNAL_ERROR = "INTERNAL_ERROR"
    CONFIG_INVALID = "CONFIG_INVALID"
    STARTUP_MULTIPLE_WORKERS = "STARTUP_MULTIPLE_WORKERS"


HTTP_STATUS: Final[Mapping[ErrorCode, int]] = MappingProxyType(
    {
        ErrorCode.VALIDATION_ERROR: 422,
        ErrorCode.AUTHENTICATION_ERROR: 401,
        ErrorCode.RATE_LIMIT_EXCEEDED: 429,
        ErrorCode.AI_API_TIMEOUT: 504,
        ErrorCode.AI_PROVIDER_ERROR: 503,
        ErrorCode.AI_RATE_LIMIT: 429,
        ErrorCode.AI_API_ERROR: 500,
        ErrorCode.INTERNAL_ERROR: 500,
        ErrorCode.CONFIG_INVALID: 500,
        ErrorCode.STARTUP_MULTIPLE_WORKERS: 500,
    }
)

# 利用者向け文言。旧実装の外部契約なので変えない（変えるなら tests/contract と一緒に）。
USER_MESSAGE: Final[Mapping[ErrorCode, str]] = MappingProxyType(
    {
        ErrorCode.VALIDATION_ERROR: "入力データが不正です",
        ErrorCode.AUTHENTICATION_ERROR: "Invalid or missing API key.",
        ErrorCode.RATE_LIMIT_EXCEEDED: "リクエスト数が上限に達しました。しばらく待ってから再試行してください。",
        ErrorCode.AI_API_TIMEOUT: "AI変換APIがタイムアウトしました。しばらく待ってから再度お試しください。",
        ErrorCode.AI_PROVIDER_ERROR: "AI変換サービスが一時的に利用できません。しばらく待ってから再度お試しください。",
        ErrorCode.AI_RATE_LIMIT: "AI変換APIのレート制限に達しました。しばらく待ってから再度お試しください。",
        ErrorCode.AI_API_ERROR: "AI変換APIからのレスポンスに失敗しました。しばらく待ってから再度お試しください。",
        ErrorCode.INTERNAL_ERROR: "予期しないエラーが発生しました。",
        ErrorCode.CONFIG_INVALID: "設定が不正なため起動できません。",
        ErrorCode.STARTUP_MULTIPLE_WORKERS: (
            "レート制限がプロセス内メモリのため worker は1つでなければなりません（ADR-002）。"
        ),
    }
)


class SafeError(Exception):
    """外へ出せる情報だけを持つ例外。

    ``code`` と原因例外の *型名* だけを持つ。メッセージ文字列を受け取る引数は無い。
    ``except`` 節の外で raise すること（``__context__`` に原因例外を残さないため）。
    """

    def __init__(
        self,
        code: ErrorCode,
        *,
        cause: type[BaseException] | None = None,
        retryable: bool = False,
    ) -> None:
        super().__init__(code.value)
        self.code: ErrorCode = code
        self.cause_type: str | None = cause.__name__ if cause is not None else None
        self.retryable: bool = retryable

    def __str__(self) -> str:
        return self.code.value


class RateLimitExceeded(SafeError):
    """429 に載せる数値だけを持つ。"""

    def __init__(self, *, retry_after_seconds: int, limit: int) -> None:
        super().__init__(ErrorCode.RATE_LIMIT_EXCEEDED)
        self.retry_after_seconds: int = retry_after_seconds
        self.limit: int = limit


ConfigProblem = tuple[str, str]
"""(設定キー名, 種別)。値は決して含めない。種別は pydantic の error type か "missing"。"""


class ConfigError(SafeError):
    """設定の組み立てに失敗した。全違反を一度に持つ（1件目で止まらない。Issue #86 B-3-6）。"""

    def __init__(self, problems: tuple[ConfigProblem, ...]) -> None:
        super().__init__(ErrorCode.CONFIG_INVALID)
        self.problems: tuple[ConfigProblem, ...] = problems

    def __str__(self) -> str:
        listed = ", ".join(f"{key}({kind})" for key, kind in self.problems)
        return f"{self.code.value}: {listed}"
```

- [ ] **Step 7: 緑を確認する**

```bash
.venv/bin/pytest tests/test_errors.py -q && .venv/bin/mypy app/errors.py
```

Expected: PASS、`Success: no issues found`

- [ ] **Step 8: logging.py のテストを書く**

`backend/tests/test_logging.py`:

```python
"""stdout への JSON Lines。利用者由来の内容を載せる口が無いこと。"""

from __future__ import annotations

import json

import pytest

from app.logging import ConversionCompleted, RemovedSettingIgnored, configure_logging, log_event


def _lines(captured: str) -> list[dict[str, object]]:
    return [json.loads(line) for line in captured.splitlines() if line.strip()]


def test_event_is_one_json_line_on_stdout(capsys: pytest.CaptureFixture[str]) -> None:
    configure_logging("INFO")
    log_event(ConversionCompleted(route="convert", provider="anthropic", outcome="success", latency_ms=42))
    out, err = capsys.readouterr()
    assert err == ""
    records = _lines(out)
    assert len(records) == 1
    record = records[0]
    assert record["event"] == "ConversionCompleted"
    assert record["level"] == "INFO"
    assert record["latency_ms"] == 42 and record["provider"] == "anthropic" and record["outcome"] == "success"
    assert "ts" in record


def test_level_filter(capsys: pytest.CaptureFixture[str]) -> None:
    configure_logging("WARNING")
    log_event(ConversionCompleted(route="convert", provider="none", outcome="success", latency_ms=1))
    log_event(RemovedSettingIgnored(key="POSTGRES_PASSWORD"), level="WARNING")
    records = _lines(capsys.readouterr().out)
    assert [r["event"] for r in records] == ["RemovedSettingIgnored"]
    assert records[0]["key"] == "POSTGRES_PASSWORD"


def test_events_carry_no_user_content_fields() -> None:
    forbidden = {"input", "input_text", "text", "converted", "hash", "length", "session"}
    for event in (ConversionCompleted, RemovedSettingIgnored):
        names = set(event.__dataclass_fields__)
        assert not any(any(word in name for word in forbidden) for name in names), names


def test_log_event_rejects_free_strings() -> None:
    with pytest.raises((TypeError, AttributeError)):
        log_event("CANARY free text")  # type: ignore[arg-type]
```

- [ ] **Step 9: 赤を確認する**

```bash
.venv/bin/pytest tests/test_logging.py -q
```

Expected: `ModuleNotFoundError: No module named 'app.logging'`

- [ ] **Step 10: logging.py を書く**

`backend/app/logging.py`:

```python
"""stdout への構造化ログ（ADR-001 / ADR-003）。

stdlib ``logging`` を import してよいのはこのモジュールだけ。受け口は型付きイベントで、
自由文字列を受け取る関数は無い。利用者由来の内容（入力・変換結果・長さ・ハッシュ）は
どのイベントにも載らない。``exc_info`` は決して渡さない。
"""

from __future__ import annotations

import json
import logging
import sys
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from typing import Literal

LOGGER_NAME = "kotonoha"
LogLevel = Literal["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"]


@dataclass(frozen=True, slots=True)
class ConversionCompleted:
    route: Literal["convert", "regenerate"]
    provider: str
    outcome: Literal["success", "error"]
    latency_ms: int
    error_code: str | None = None
    cause_type: str | None = None


@dataclass(frozen=True, slots=True)
class RequestFailed:
    route: str
    error_code: str
    cause_type: str | None = None


@dataclass(frozen=True, slots=True)
class RemovedSettingIgnored:
    key: str


@dataclass(frozen=True, slots=True)
class AuthenticationSkipped:
    environment: str


@dataclass(frozen=True, slots=True)
class ProviderConfigured:
    provider: str


LogEvent = (
    ConversionCompleted | RequestFailed | RemovedSettingIgnored | AuthenticationSkipped | ProviderConfigured
)


class _JsonLineFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        payload: dict[str, object] = {
            "ts": datetime.fromtimestamp(record.created, tz=timezone.utc).isoformat(timespec="milliseconds"),
            "level": record.levelname,
            "event": getattr(record, "event", record.name),
        }
        fields = getattr(record, "fields", None)
        if isinstance(fields, dict):
            payload.update(fields)
        return json.dumps(payload, ensure_ascii=False)


def configure_logging(level: LogLevel) -> None:
    """stdout に JSON Lines を出す。ファイル出力は持たない（ADR-001）。"""
    logger = logging.getLogger(LOGGER_NAME)
    for handler in list(logger.handlers):
        logger.removeHandler(handler)
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(_JsonLineFormatter())
    logger.addHandler(handler)
    logger.setLevel(level)
    logger.propagate = False


def log_event(event: LogEvent, *, level: LogLevel = "INFO") -> None:
    """型付きイベントを1行の JSON として stdout へ書く。"""
    fields = asdict(event)  # dataclass 以外（自由文字列）は TypeError で落ちる
    logging.getLogger(LOGGER_NAME).log(
        logging.getLevelNamesMapping()[level],
        "",
        extra={"event": type(event).__name__, "fields": fields},
    )
```

- [ ] **Step 11: 緑と型・整形を確認する**

```bash
.venv/bin/pytest tests/test_errors.py tests/test_logging.py -q
.venv/bin/mypy app/errors.py app/logging.py
.venv/bin/ruff check app/errors.py app/logging.py tests/test_errors.py tests/test_logging.py
.venv/bin/black --check app/errors.py app/logging.py tests/test_errors.py tests/test_logging.py
```

Expected: すべて緑。

- [ ] **Step 12: コミット**

```bash
git add backend/requirements.txt backend/requirements-dev.txt backend/pyproject.toml backend/app/errors.py backend/app/logging.py backend/tests/test_errors.py backend/tests/test_logging.py
git commit -m "refactor: 新 backend の型付きエラーと構造化ログを足す（ADR-003、Python 3.12）(Phase 2 / Task 3)"
```

---

### Task 4: `config.py` — 不変設定、環境判定の一本化、本番ゲート、削除済みキーの警告

**Files:**
- Create: `backend/app/config.py`
- Create: `backend/tests/conftest.py`（新 backend 用。契約用とは別）
- Create: `backend/tests/test_config.py`

**Interfaces:**
- Consumes: `ConfigError`, `ConfigProblem`（Task 3）、`log_event`, `RemovedSettingIgnored`（Task 3）
- Produces: `RuntimeConfig`（frozen。`ENVIRONMENT` `VERSION` `PROJECT_NAME` `LOG_LEVEL` `API_KEYS: SecretStr`
  `CORS_ORIGINS` `RATE_LIMIT_TIMES` `RATE_LIMIT_SECONDS` `TRUSTED_PROXY_COUNT` `DEFAULT_AI_PROVIDER`
  `ANTHROPIC_API_KEY: SecretStr | None` `ANTHROPIC_MODEL` `OPENAI_API_KEY: SecretStr | None` `OPENAI_MODEL`
  `AI_API_TIMEOUT: float` `AI_MAX_RETRIES` `AI_CALL_DEADLINE_SECONDS: float`）、
  メソッド `is_local` `docs_enabled` `auth_optional`（property）、`api_keys() -> tuple[bytes, ...]`、
  `cors_origins() -> tuple[str, ...]`、`provider_api_key(name) -> SecretStr | None`、
  `startup_problems() -> tuple[ConfigProblem, ...]`；`load_config(env_file=".env") -> RuntimeConfig`；
  定数 `API_PREFIX = "/api/v1"`、`REMOVED_SETTINGS`、型 `Environment` `ProviderName`

- [ ] **Step 1: 新 backend 用の conftest を書く**

`backend/tests/conftest.py`:

```python
"""新 backend のテスト土台。設定は必ず明示して組む（環境や .env に依存しない）。"""

from __future__ import annotations

from typing import Any

from app.config import RuntimeConfig


def make_config(**overrides: Any) -> RuntimeConfig:
    """テスト用の RuntimeConfig。.env を読まず、環境変数より overrides を優先する。"""
    values: dict[str, Any] = {
        "ENVIRONMENT": "test",
        "API_KEYS": "test-key-A,test-key-B",
        "ANTHROPIC_API_KEY": "sk-test-anthropic",
        "DEFAULT_AI_PROVIDER": "anthropic",
        "RATE_LIMIT_TIMES": 1,
        "RATE_LIMIT_SECONDS": 1,
        "TRUSTED_PROXY_COUNT": 1,
        "AI_MAX_RETRIES": 0,
        "AI_API_TIMEOUT": 1.0,
        "AI_CALL_DEADLINE_SECONDS": 2.0,
        "LOG_LEVEL": "INFO",
    }
    values.update(overrides)
    return RuntimeConfig(_env_file=None, **values)
```

- [ ] **Step 2: config のテストを書く**

`backend/tests/test_config.py`:

```python
"""ADR-004。B-3-2（記号入りキー）・B-3-6（全違反を一度に）・B-3-7（削除済みキー）・環境ガード両分岐。"""

from __future__ import annotations

import json
from pathlib import Path

import pytest
from pydantic import ValidationError

from app.config import REMOVED_SETTINGS, RuntimeConfig, load_config
from app.errors import ConfigError
from tests.conftest import make_config

SYMBOL_KEY = "k%40@#=/+!?"


@pytest.fixture(autouse=True)
def clean_environment(monkeypatch: pytest.MonkeyPatch) -> None:
    for name in list(RuntimeConfig.model_fields) + sorted(REMOVED_SETTINGS):
        monkeypatch.delenv(name, raising=False)


def test_config_is_frozen() -> None:
    config = make_config()
    with pytest.raises(ValidationError):
        config.RATE_LIMIT_TIMES = 5  # type: ignore[misc]


def test_secrets_are_hidden_in_repr() -> None:
    config = make_config(API_KEYS=SYMBOL_KEY, ANTHROPIC_API_KEY="sk-CANARY")
    assert SYMBOL_KEY not in repr(config) and "sk-CANARY" not in repr(config)
    assert config.api_keys() == (SYMBOL_KEY.encode("ascii"),)


def test_api_keys_are_split_and_stripped() -> None:
    assert make_config(API_KEYS=" a , ,b,").api_keys() == (b"a", b"b")


def test_empty_provider_key_means_none() -> None:
    config = make_config(ANTHROPIC_API_KEY="", OPENAI_API_KEY="")
    assert config.provider_api_key("anthropic") is None and config.provider_api_key("openai") is None


@pytest.mark.parametrize("field", ["API_KEYS", "ANTHROPIC_API_KEY", "OPENAI_API_KEY"])
def test_non_ascii_key_is_rejected_at_load_without_echoing_value(monkeypatch: pytest.MonkeyPatch, field: str) -> None:
    monkeypatch.setenv(field, "kéy-CANARY")
    with pytest.raises(ConfigError) as info:
        load_config(env_file=None)
    assert (field, "value_error") in info.value.problems
    assert "CANARY" not in str(info.value) and info.value.__context__ is None


def test_validation_error_never_escapes(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("RATE_LIMIT_TIMES", "CANARY-not-int")
    with pytest.raises(ConfigError) as info:
        load_config(env_file=None)
    assert info.value.problems == (("RATE_LIMIT_TIMES", "int_parsing"),)
    assert "CANARY" not in str(info.value)


@pytest.mark.parametrize("environment", ["development", "test"])
def test_local_environments_relax_auth_and_publish_docs(environment: str) -> None:
    config = make_config(ENVIRONMENT=environment, API_KEYS="")
    assert config.is_local and config.auth_optional and config.docs_enabled
    assert config.startup_problems() == ()


@pytest.mark.parametrize("environment", ["staging", "production"])
def test_non_local_environments_report_all_problems_at_once(environment: str) -> None:
    config = make_config(ENVIRONMENT=environment, API_KEYS="", ANTHROPIC_API_KEY="")
    assert not config.is_local and not config.auth_optional and not config.docs_enabled
    assert set(config.startup_problems()) == {("API_KEYS", "missing"), ("ANTHROPIC_API_KEY", "missing")}


def test_non_local_load_fails_with_every_problem(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("ENVIRONMENT", "production")
    monkeypatch.setenv("DEFAULT_AI_PROVIDER", "openai")
    with pytest.raises(ConfigError) as info:
        load_config(env_file=None)
    assert set(info.value.problems) == {("API_KEYS", "missing"), ("OPENAI_API_KEY", "missing")}


def test_production_with_symbol_keys_loads(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("ENVIRONMENT", "production")
    monkeypatch.setenv("API_KEYS", SYMBOL_KEY)
    monkeypatch.setenv("ANTHROPIC_API_KEY", "sk-" + SYMBOL_KEY)
    config = load_config(env_file=None)
    assert config.api_keys() == (SYMBOL_KEY.encode("ascii"),)


def test_unknown_environment_is_rejected(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("ENVIRONMENT", "prod")
    with pytest.raises(ConfigError) as info:
        load_config(env_file=None)
    assert info.value.problems[0][0] == "ENVIRONMENT"


def test_removed_keys_in_dotenv_warn_but_do_not_fail(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    env_file = tmp_path / ".env"
    env_file.write_text("POSTGRES_PASSWORD=p%40ss-CANARY\nRATE_LIMIT_STORAGE_URI=redis://x\nRATE_LIMIT_TIMES=3\n", encoding="utf-8")
    from app.logging import configure_logging

    configure_logging("WARNING")
    config = load_config(env_file=env_file)
    assert config.RATE_LIMIT_TIMES == 3
    out = capsys.readouterr().out
    events = [json.loads(line) for line in out.splitlines() if line.strip()]
    assert {e["key"] for e in events if e["event"] == "RemovedSettingIgnored"} == {"POSTGRES_PASSWORD", "RATE_LIMIT_STORAGE_URI"}
    assert "CANARY" not in out


def test_removed_keys_in_environment_warn(monkeypatch: pytest.MonkeyPatch, capsys: pytest.CaptureFixture[str]) -> None:
    from app.logging import configure_logging

    configure_logging("WARNING")
    monkeypatch.setenv("SECRET_KEY", "CANARY")
    load_config(env_file=None)
    out = capsys.readouterr().out
    assert '"key": "SECRET_KEY"' in out and "CANARY" not in out


def test_cors_origins_are_split() -> None:
    assert make_config(CORS_ORIGINS=" http://a , http://b ").cors_origins() == ("http://a", "http://b")
```

- [ ] **Step 3: 赤を確認する**

```bash
.venv/bin/pytest tests/test_config.py -q
```

Expected: `ModuleNotFoundError: No module named 'app.config'`（旧 `app/core/config.py` とは別モジュール）

- [ ] **Step 4: config.py を書く**

`backend/app/config.py`:

```python
"""設定は不変（ADR-004）。環境判定はこのモジュールの1箇所だけ。

秘密は ``SecretStr``。DSN は存在しない（ADR-001）。``RATE_LIMIT_STORAGE_URI`` は
作らない（ADR-002）。pydantic の ``ValidationError`` は失敗した入力値を ``str()`` に含むため、
このモジュールの外へ出さない——キー名と種別だけを ``ConfigError`` に載せ替える。
"""

from __future__ import annotations

import os
from collections.abc import Mapping
from pathlib import Path
from typing import Final, Literal

from dotenv import dotenv_values
from pydantic import Field, SecretStr, ValidationError, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

from app.errors import ConfigError, ConfigProblem
from app.logging import LogLevel, RemovedSettingIgnored, log_event

Environment = Literal["development", "test", "staging", "production"]
ProviderName = Literal["anthropic", "openai"]

API_PREFIX: Final = "/api/v1"

# 旧 backend にあり、決定1・2で消えたキー。.env に残っていても起動を止めず警告だけ出す（Issue #86 B-3-7）。
REMOVED_SETTINGS: Final[frozenset[str]] = frozenset(
    {
        "POSTGRES_USER",
        "POSTGRES_PASSWORD",
        "POSTGRES_DB",
        "POSTGRES_HOST",
        "POSTGRES_PORT",
        "DATABASE_URL",
        "TEST_DATABASE_URL",
        "SECRET_KEY",
        "API_HOST",
        "API_PORT",
        "API_V1_STR",
        "ACCESS_TOKEN_EXPIRE_MINUTES",
        "SESSION_EXPIRE_MINUTES",
        "RATE_LIMIT_STORAGE_URI",
        "LOG_FILE_PATH",
    }
)


def _is_header_safe(value: str) -> bool:
    """HTTP ヘッダーに載せられる値か（印字可能 ASCII のみ）。非 ASCII は SDK が送信時に落とす（実測）。"""
    return all(0x20 <= ord(ch) <= 0x7E for ch in value)


class RuntimeConfig(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore",
        frozen=True,
    )

    ENVIRONMENT: Environment = "development"
    PROJECT_NAME: str = "kotonoha API"
    VERSION: str = "1.0.0"
    LOG_LEVEL: LogLevel = "INFO"

    # 端末 API キー（カンマ区切り）。空なら development / test に限り認証を省略する
    API_KEYS: SecretStr = SecretStr("")
    CORS_ORIGINS: str = "http://localhost:3000,http://localhost:5173"

    # レート制限（ADR-002: 単一送信元の burst 抑制。カウンタはプロセス内メモリ）
    RATE_LIMIT_TIMES: int = Field(default=1, ge=1)
    RATE_LIMIT_SECONDS: int = Field(default=10, ge=1)
    TRUSTED_PROXY_COUNT: int = Field(default=0, ge=0)

    # AI プロバイダ（サーバーが存在する唯一の理由）
    DEFAULT_AI_PROVIDER: ProviderName = "anthropic"
    ANTHROPIC_API_KEY: SecretStr | None = None
    ANTHROPIC_MODEL: str = "claude-sonnet-4-6"
    OPENAI_API_KEY: SecretStr | None = None
    OPENAI_MODEL: str = "gpt-4o-mini"
    AI_API_TIMEOUT: float = Field(default=8.0, gt=0)
    AI_MAX_RETRIES: int = Field(default=1, ge=0)
    AI_CALL_DEADLINE_SECONDS: float = Field(default=10.0, gt=0)

    @field_validator("ANTHROPIC_API_KEY", "OPENAI_API_KEY", mode="after")
    @classmethod
    def _provider_key(cls, value: SecretStr | None) -> SecretStr | None:
        if value is None or value.get_secret_value() == "":
            return None
        if not _is_header_safe(value.get_secret_value()):
            raise ValueError("must be printable ASCII")  # 値は書かない
        return value

    @field_validator("API_KEYS", mode="after")
    @classmethod
    def _api_keys(cls, value: SecretStr) -> SecretStr:
        if not _is_header_safe(value.get_secret_value()):
            raise ValueError("must be printable ASCII")
        return value

    # ---- 環境判定はここだけ（台帳 P2: 3ファイルに散っていた split-brain の解消） ----
    @property
    def is_local(self) -> bool:
        return self.ENVIRONMENT in ("development", "test")

    @property
    def docs_enabled(self) -> bool:
        return self.is_local

    @property
    def auth_optional(self) -> bool:
        return self.is_local

    # ---- 派生値 ----
    def api_keys(self) -> tuple[bytes, ...]:
        raw = self.API_KEYS.get_secret_value()
        return tuple(key.strip().encode("ascii") for key in raw.split(",") if key.strip())

    def cors_origins(self) -> tuple[str, ...]:
        return tuple(origin.strip() for origin in self.CORS_ORIGINS.split(",") if origin.strip())

    def provider_api_key(self, name: ProviderName) -> SecretStr | None:
        return self.ANTHROPIC_API_KEY if name == "anthropic" else self.OPENAI_API_KEY

    def startup_problems(self) -> tuple[ConfigProblem, ...]:
        """本番ゲート。全違反を一度に返す（1件目で止まらない）。"""
        if self.is_local:
            return ()
        problems: list[ConfigProblem] = []
        if not self.api_keys():
            problems.append(("API_KEYS", "missing"))
        if self.provider_api_key(self.DEFAULT_AI_PROVIDER) is None:
            problems.append((f"{self.DEFAULT_AI_PROVIDER.upper()}_API_KEY", "missing"))
        return tuple(problems)


def _warn_removed_settings(env_file: Path | None, environ: Mapping[str, str]) -> None:
    present: set[str] = set(environ)
    if env_file is not None and env_file.is_file():
        present |= set(dotenv_values(env_file))  # 権威（python-dotenv）の出力を消費する。文法は書かない
    for key in sorted(present & REMOVED_SETTINGS):
        log_event(RemovedSettingIgnored(key=key), level="WARNING")


def load_config(env_file: str | Path | None = ".env") -> RuntimeConfig:
    """環境変数と .env から不変の設定を組み立てる。失敗は ``ConfigError``（キー名と種別のみ）。"""
    problems: tuple[ConfigProblem, ...] = ()
    config: RuntimeConfig | None = None
    try:
        config = RuntimeConfig(_env_file=env_file)
    except ValidationError as exc:
        problems = tuple(
            (".".join(str(part) for part in err["loc"]), err["type"])
            for err in exc.errors(include_input=False, include_url=False)
        )
    if config is None:
        raise ConfigError(problems)  # except の外で raise → __context__ を残さない
    _warn_removed_settings(Path(env_file) if env_file is not None else None, os.environ)
    startup = config.startup_problems()
    if startup:
        raise ConfigError(startup)
    return config
```

- [ ] **Step 5: 緑・型・整形・層契約を確認する**

```bash
.venv/bin/pytest tests/test_config.py tests/test_errors.py tests/test_logging.py -q
.venv/bin/mypy app/errors.py app/logging.py app/config.py
.venv/bin/ruff check app/config.py tests/conftest.py tests/test_config.py && .venv/bin/black --check app tests/conftest.py tests/test_config.py
```

Expected: すべて緑（`lint-imports` は旧 `app/core` が残る Task 7 まで走らせない）。

- [ ] **Step 6: コミット**

```bash
git add backend/app/config.py backend/tests/conftest.py backend/tests/test_config.py
git commit -m "refactor: 新 backend の不変設定を足す（ADR-004、環境判定の一本化、本番ゲート、削除済みキー警告）(Phase 2 / Task 4)"
```

---

### Task 5: `app/ai/` — プロンプト、プロバイダ境界、再試行と締切

**Files:**
- Create: `backend/app/ai/__init__.py`（空）
- Create: `backend/app/ai/prompts.py`
- Create: `backend/app/ai/providers.py`
- Create: `backend/app/ai/service.py`
- Create: `backend/tests/ai/__init__.py`（空）
- Create: `backend/tests/ai/test_prompts.py`
- Create: `backend/tests/ai/test_providers.py`
- Create: `backend/tests/ai/test_service.py`

**Interfaces:**
- Consumes: `SafeError` `ErrorCode`（Task 3）、`RuntimeConfig` `ProviderName`（Task 4）
- Produces: `PolitenessLevel(StrEnum)`, `Prompt`, `conversion_prompt(text, level)`, `regeneration_prompt(text, level, previous)`；
  `Provider`（Protocol: `name: ProviderName`, `complete(prompt) -> str`, `aclose()`）,
  `AnthropicProvider(api_key, model, timeout_seconds)`, `OpenAIProvider(...)`, `build_provider(config) -> Provider | None`；
  `ConversionService(provider, *, max_retries, deadline_seconds, backoff_seconds=0.5)` with
  `provider_name`, `convert(text, level) -> str`, `regenerate(text, level, previous) -> str`

- [ ] **Step 1: prompts のテスト**

`backend/tests/ai/test_prompts.py`:

```python
from __future__ import annotations

import pytest

from app.ai.prompts import PolitenessLevel, conversion_prompt, regeneration_prompt


@pytest.mark.parametrize("level", list(PolitenessLevel))
def test_conversion_prompt_embeds_input_once(level: PolitenessLevel) -> None:
    prompt = conversion_prompt("水 ぬるく", level)
    assert prompt.user.count("水 ぬるく") == 1
    assert prompt.system
    assert 0 < prompt.temperature < 1


def test_regeneration_prompt_asks_for_a_different_wording() -> None:
    prompt = regeneration_prompt("水 ぬるく", PolitenessLevel.POLITE, "お水をください")
    assert "お水をください" in prompt.user and "水 ぬるく" in prompt.user
    assert prompt.temperature > conversion_prompt("水 ぬるく", PolitenessLevel.POLITE).temperature


def test_levels_produce_distinct_instructions() -> None:
    users = {conversion_prompt("あ", level).user for level in PolitenessLevel}
    assert len(users) == 3
```

- [ ] **Step 2: prompts.py を書く**

`backend/app/ai/prompts.py`:

```python
"""丁寧さレベルとプロンプト。旧実装の文言をそのまま引き継ぐ。"""

from __future__ import annotations

from dataclasses import dataclass
from enum import StrEnum
from typing import Final


class PolitenessLevel(StrEnum):
    CASUAL = "casual"
    NORMAL = "normal"
    POLITE = "polite"


SYSTEM_PROMPT: Final = "あなたは日本語の文章を適切な丁寧さレベルに変換する専門家です。"

_INSTRUCTIONS: Final[dict[PolitenessLevel, str]] = {
    PolitenessLevel.CASUAL: (
        "カジュアルで親しみやすい表現に変換してください。タメ口や砕けた言い回しを使用します。"
    ),
    PolitenessLevel.NORMAL: "標準的な丁寧さの「です・ます」調の表現に変換してください。",
    PolitenessLevel.POLITE: (
        "非常に丁寧で敬意を込めた敬語表現に変換してください。尊敬語・謙譲語を適切に使用します。"
    ),
}

_TAIL: Final = "変換後の文のみを出力してください。説明や追加情報は不要です。"


@dataclass(frozen=True, slots=True)
class Prompt:
    system: str
    user: str
    temperature: float
    max_tokens: int = 1024


def conversion_prompt(input_text: str, level: PolitenessLevel) -> Prompt:
    user = f"以下の日本語文を{_INSTRUCTIONS[level]}\n\n入力文: {input_text}\n\n{_TAIL}"
    return Prompt(system=SYSTEM_PROMPT, user=user, temperature=0.7)


def regeneration_prompt(input_text: str, level: PolitenessLevel, previous_result: str) -> Prompt:
    user = (
        f"以下の日本語文を{_INSTRUCTIONS[level]}\n\n"
        f"元の入力文: {input_text}\n前回の変換結果: {previous_result}\n\n"
        "前回と**異なる表現**で変換してください。意味は同じでも、言い回しを変えてください。\n"
        f"{_TAIL}"
    )
    return Prompt(system=SYSTEM_PROMPT, user=user, temperature=0.9)
```

- [ ] **Step 3: providers のテスト（HTTP 境界を respx で差し替える）**

`backend/tests/ai/test_providers.py`:

```python
"""SDK 境界。B-1 失敗注入（落ちる／遅い／不正応答）と B-3-5（例外連鎖に秘密を残さない）。"""

from __future__ import annotations

from collections.abc import Iterator

import httpx
import pytest
import respx
from pydantic import SecretStr

from app.ai.prompts import PolitenessLevel, conversion_prompt
from app.ai.providers import AnthropicProvider, OpenAIProvider, build_provider
from app.errors import ErrorCode, SafeError
from tests.conftest import make_config

ANTHROPIC_URL = "https://api.anthropic.com/v1/messages"
OPENAI_URL = "https://api.openai.com/v1/chat/completions"
SYMBOL_KEY = "sk-k%40@#=/+!?"
PROMPT = conversion_prompt("水 ぬるく", PolitenessLevel.NORMAL)


def anthropic_body(text: str) -> dict[str, object]:
    return {
        "id": "msg_1", "type": "message", "role": "assistant", "model": "m",
        "content": [{"type": "text", "text": text}],
        "stop_reason": "end_turn", "stop_sequence": None,
        "usage": {"input_tokens": 1, "output_tokens": 1},
    }


def openai_body(text: str | None) -> dict[str, object]:
    return {
        "id": "c1", "object": "chat.completion", "created": 1, "model": "m",
        "choices": [{"index": 0, "message": {"role": "assistant", "content": text}, "finish_reason": "stop"}],
        "usage": {"prompt_tokens": 1, "completion_tokens": 1, "total_tokens": 2},
    }


@pytest.fixture
def http() -> Iterator[respx.MockRouter]:
    with respx.mock(assert_all_mocked=True, assert_all_called=False) as router:
        yield router


async def test_anthropic_sends_symbol_key_verbatim_and_returns_text(http: respx.MockRouter) -> None:
    route = http.post(ANTHROPIC_URL).mock(return_value=httpx.Response(200, json=anthropic_body("  お水をください  ")))
    provider = AnthropicProvider(SecretStr(SYMBOL_KEY), model="m", timeout_seconds=1.0)
    try:
        assert await provider.complete(PROMPT) == "お水をください"
    finally:
        await provider.aclose()
    assert route.calls[0].request.headers["x-api-key"] == SYMBOL_KEY
    assert route.calls.call_count == 1  # SDK 内蔵リトライは 0


async def test_openai_sends_symbol_key_verbatim(http: respx.MockRouter) -> None:
    route = http.post(OPENAI_URL).mock(return_value=httpx.Response(200, json=openai_body("お水をください")))
    provider = OpenAIProvider(SecretStr(SYMBOL_KEY), model="m", timeout_seconds=1.0)
    try:
        assert await provider.complete(PROMPT) == "お水をください"
    finally:
        await provider.aclose()
    assert route.calls[0].request.headers["authorization"] == f"Bearer {SYMBOL_KEY}"


@pytest.mark.parametrize(
    ("mock_kwargs", "code", "retryable"),
    [
        ({"side_effect": httpx.ReadTimeout("t")}, ErrorCode.AI_API_TIMEOUT, False),
        ({"side_effect": httpx.ConnectError("c")}, ErrorCode.AI_API_ERROR, True),
        ({"return_value": httpx.Response(429, json={"type": "error", "error": {"type": "rate_limit_error", "message": "CANARY-429"}})}, ErrorCode.AI_RATE_LIMIT, True),
        ({"return_value": httpx.Response(500, json={"type": "error", "error": {"type": "api_error", "message": "CANARY-500"}})}, ErrorCode.AI_API_ERROR, False),
        ({"return_value": httpx.Response(401, json={"type": "error", "error": {"type": "authentication_error", "message": "CANARY-401"}})}, ErrorCode.AI_API_ERROR, False),
        ({"return_value": httpx.Response(200, json={**anthropic_body("x"), "content": []})}, ErrorCode.AI_API_ERROR, False),
        ({"return_value": httpx.Response(200, content=b"not json")}, ErrorCode.INTERNAL_ERROR, False),
    ],
)
async def test_anthropic_failures_become_safe_errors(
    http: respx.MockRouter, mock_kwargs: dict[str, object], code: ErrorCode, retryable: bool
) -> None:
    http.post(ANTHROPIC_URL).mock(**mock_kwargs)
    provider = AnthropicProvider(SecretStr("sk"), model="m", timeout_seconds=1.0)
    try:
        with pytest.raises(SafeError) as info:
            await provider.complete(PROMPT)
    finally:
        await provider.aclose()
    err = info.value
    assert err.code is code and err.retryable is retryable
    assert err.__context__ is None and err.__cause__ is None
    assert "CANARY" not in repr(err) and "CANARY" not in (err.cause_type or "")
    assert err.cause_type  # 型名は残す（診断用）


@pytest.mark.parametrize(
    ("response", "code"),
    [
        (httpx.Response(429, json={"error": {"message": "CANARY", "type": "x"}}), ErrorCode.AI_RATE_LIMIT),
        (httpx.Response(200, json=openai_body(None)), ErrorCode.AI_API_ERROR),
        (httpx.Response(200, json=openai_body("   ")), ErrorCode.AI_API_ERROR),
    ],
)
async def test_openai_failures_become_safe_errors(http: respx.MockRouter, response: httpx.Response, code: ErrorCode) -> None:
    http.post(OPENAI_URL).mock(return_value=response)
    provider = OpenAIProvider(SecretStr("sk"), model="m", timeout_seconds=1.0)
    try:
        with pytest.raises(SafeError) as info:
            await provider.complete(PROMPT)
    finally:
        await provider.aclose()
    assert info.value.code is code and info.value.__context__ is None


def test_build_provider_follows_default_provider_and_key_presence() -> None:
    assert build_provider(make_config(ANTHROPIC_API_KEY="", DEFAULT_AI_PROVIDER="anthropic")) is None
    assert build_provider(make_config(DEFAULT_AI_PROVIDER="anthropic")).name == "anthropic"
    assert build_provider(make_config(DEFAULT_AI_PROVIDER="openai", OPENAI_API_KEY="sk-o")).name == "openai"
    assert build_provider(make_config(DEFAULT_AI_PROVIDER="openai", OPENAI_API_KEY="")) is None
```

- [ ] **Step 4: providers.py を書く**

`backend/app/ai/providers.py`:

```python
"""AI プロバイダ SDK との境界。SDK 例外はここで *型だけ* 拾い、SafeError に変える（ADR-003）。

モックはこの境界の外側（HTTP、respx）にのみ置く。SDK 内蔵のリトライは 0 にする
（再試行と締切は service が一元管理する。計画 D4）。想定外の例外もここで型名だけ拾う（D5）。
"""

from __future__ import annotations

from typing import Protocol

import anthropic
import openai
from anthropic.types import TextBlock
from pydantic import SecretStr

from app.ai.prompts import Prompt
from app.config import ProviderName, RuntimeConfig
from app.errors import ErrorCode, SafeError


class Provider(Protocol):
    @property
    def name(self) -> ProviderName: ...

    async def complete(self, prompt: Prompt) -> str: ...

    async def aclose(self) -> None: ...


class AnthropicProvider:
    name: ProviderName = "anthropic"

    def __init__(self, api_key: SecretStr, *, model: str, timeout_seconds: float) -> None:
        self._model = model
        self._client = anthropic.AsyncAnthropic(
            api_key=api_key.get_secret_value(), max_retries=0, timeout=timeout_seconds
        )

    async def complete(self, prompt: Prompt) -> str:
        code: ErrorCode | None = None
        cause: type[BaseException] | None = None
        retryable = False
        text = ""
        try:
            message = await self._client.messages.create(
                model=self._model,
                max_tokens=prompt.max_tokens,
                temperature=prompt.temperature,
                system=prompt.system,
                messages=[{"role": "user", "content": prompt.user}],
            )
            text = _first_text(message)
        except anthropic.APITimeoutError as exc:  # APIConnectionError の子なので先に見る
            code, cause = ErrorCode.AI_API_TIMEOUT, type(exc)
        except anthropic.RateLimitError as exc:
            code, cause, retryable = ErrorCode.AI_RATE_LIMIT, type(exc), True
        except anthropic.APIConnectionError as exc:
            code, cause, retryable = ErrorCode.AI_API_ERROR, type(exc), True
        except anthropic.APIStatusError as exc:
            code, cause = ErrorCode.AI_API_ERROR, type(exc)
        except Exception as exc:  # SDK 内部の想定外。メッセージは持ち出さない
            code, cause = ErrorCode.INTERNAL_ERROR, type(exc)
        if code is not None:
            raise SafeError(code, cause=cause, retryable=retryable)  # except の外
        if not text:
            raise SafeError(ErrorCode.AI_API_ERROR)
        return text

    async def aclose(self) -> None:
        await self._client.close()


def _first_text(message: anthropic.types.Message) -> str:
    for block in message.content:
        if isinstance(block, TextBlock) and block.text.strip():
            return block.text.strip()
    return ""


class OpenAIProvider:
    name: ProviderName = "openai"

    def __init__(self, api_key: SecretStr, *, model: str, timeout_seconds: float) -> None:
        self._model = model
        self._client = openai.AsyncOpenAI(
            api_key=api_key.get_secret_value(), max_retries=0, timeout=timeout_seconds
        )

    async def complete(self, prompt: Prompt) -> str:
        code: ErrorCode | None = None
        cause: type[BaseException] | None = None
        retryable = False
        text = ""
        try:
            completion = await self._client.chat.completions.create(
                model=self._model,
                messages=[
                    {"role": "system", "content": prompt.system},
                    {"role": "user", "content": prompt.user},
                ],
                max_tokens=prompt.max_tokens,
                temperature=prompt.temperature,
            )
            content = completion.choices[0].message.content if completion.choices else None
            text = content.strip() if content else ""
        except openai.APITimeoutError as exc:
            code, cause = ErrorCode.AI_API_TIMEOUT, type(exc)
        except openai.RateLimitError as exc:
            code, cause, retryable = ErrorCode.AI_RATE_LIMIT, type(exc), True
        except openai.APIConnectionError as exc:
            code, cause, retryable = ErrorCode.AI_API_ERROR, type(exc), True
        except openai.APIStatusError as exc:
            code, cause = ErrorCode.AI_API_ERROR, type(exc)
        except Exception as exc:
            code, cause = ErrorCode.INTERNAL_ERROR, type(exc)
        if code is not None:
            raise SafeError(code, cause=cause, retryable=retryable)
        if not text:
            raise SafeError(ErrorCode.AI_API_ERROR)
        return text

    async def aclose(self) -> None:
        await self._client.close()


def build_provider(config: RuntimeConfig) -> Provider | None:
    """DEFAULT_AI_PROVIDER のキーがあればその client を作る。無ければ None（health は "none"）。"""
    key = config.provider_api_key(config.DEFAULT_AI_PROVIDER)
    if key is None:
        return None
    if config.DEFAULT_AI_PROVIDER == "anthropic":
        return AnthropicProvider(key, model=config.ANTHROPIC_MODEL, timeout_seconds=config.AI_API_TIMEOUT)
    return OpenAIProvider(key, model=config.OPENAI_MODEL, timeout_seconds=config.AI_API_TIMEOUT)
```

- [ ] **Step 5: service のテスト（Provider を偽物で差し替える＝Protocol の境界。自分の関数の patch ではない）**

`backend/tests/ai/test_service.py`:

```python
"""再試行と締切（B-1 べき等性・時間）。"""

from __future__ import annotations

import asyncio

import pytest

from app.ai.prompts import PolitenessLevel, Prompt
from app.ai.service import ConversionService
from app.config import ProviderName
from app.errors import ErrorCode, SafeError


class ScriptedProvider:
    name: ProviderName = "anthropic"

    def __init__(self, *outcomes: str | SafeError | float) -> None:
        self._outcomes = list(outcomes)
        self.calls = 0

    async def complete(self, prompt: Prompt) -> str:
        self.calls += 1
        outcome = self._outcomes.pop(0)
        if isinstance(outcome, float):
            await asyncio.sleep(outcome)
            return "遅い"
        if isinstance(outcome, SafeError):
            raise outcome
        return outcome

    async def aclose(self) -> None:
        return None


def service(provider: ScriptedProvider | None, *, max_retries: int = 1, deadline: float = 1.0) -> ConversionService:
    return ConversionService(provider, max_retries=max_retries, deadline_seconds=deadline, backoff_seconds=0.0)


async def test_success_returns_text() -> None:
    provider = ScriptedProvider("お水をください")
    assert await service(provider).convert("水", PolitenessLevel.NORMAL) == "お水をください"
    assert provider.calls == 1


async def test_retryable_error_is_retried_up_to_max() -> None:
    provider = ScriptedProvider(SafeError(ErrorCode.AI_RATE_LIMIT, retryable=True), "二回目")
    assert await service(provider, max_retries=1).regenerate("水", PolitenessLevel.POLITE, "前") == "二回目"
    assert provider.calls == 2


async def test_retries_exhausted_raises_last_error() -> None:
    provider = ScriptedProvider(*(SafeError(ErrorCode.AI_RATE_LIMIT, retryable=True) for _ in range(3)))
    with pytest.raises(SafeError) as info:
        await service(provider, max_retries=2).convert("水", PolitenessLevel.NORMAL)
    assert info.value.code is ErrorCode.AI_RATE_LIMIT and provider.calls == 3


async def test_non_retryable_error_is_not_retried() -> None:
    provider = ScriptedProvider(SafeError(ErrorCode.AI_API_TIMEOUT), "never")
    with pytest.raises(SafeError) as info:
        await service(provider, max_retries=3).convert("水", PolitenessLevel.NORMAL)
    assert info.value.code is ErrorCode.AI_API_TIMEOUT and provider.calls == 1


async def test_deadline_covers_all_attempts() -> None:
    provider = ScriptedProvider(5.0)
    with pytest.raises(SafeError) as info:
        await service(provider, deadline=0.2).convert("水", PolitenessLevel.NORMAL)
    assert info.value.code is ErrorCode.AI_API_TIMEOUT and info.value.__context__ is None


async def test_missing_provider_is_provider_error() -> None:
    svc = service(None)
    assert svc.provider_name == "none"
    with pytest.raises(SafeError) as info:
        await svc.convert("水", PolitenessLevel.NORMAL)
    assert info.value.code is ErrorCode.AI_PROVIDER_ERROR
```

- [ ] **Step 6: service.py を書く**

`backend/app/ai/service.py`:

```python
"""変換サービス。再試行と締切をここで一元管理する（計画 D4）。"""

from __future__ import annotations

import asyncio

from app.ai.prompts import PolitenessLevel, Prompt, conversion_prompt, regeneration_prompt
from app.ai.providers import Provider
from app.errors import ErrorCode, SafeError


class ConversionService:
    def __init__(
        self,
        provider: Provider | None,
        *,
        max_retries: int,
        deadline_seconds: float,
        backoff_seconds: float = 0.5,
    ) -> None:
        self._provider = provider
        self._max_retries = max_retries
        self._deadline = deadline_seconds
        self._backoff = backoff_seconds

    @property
    def provider_name(self) -> str:
        return self._provider.name if self._provider is not None else "none"

    async def convert(self, input_text: str, level: PolitenessLevel) -> str:
        return await self._run(conversion_prompt(input_text, level))

    async def regenerate(self, input_text: str, level: PolitenessLevel, previous_result: str) -> str:
        return await self._run(regeneration_prompt(input_text, level, previous_result))

    async def _run(self, prompt: Prompt) -> str:
        provider = self._provider
        if provider is None:
            raise SafeError(ErrorCode.AI_PROVIDER_ERROR)
        timed_out = False
        text = ""
        try:
            text = await asyncio.wait_for(self._with_retries(provider, prompt), timeout=self._deadline)
        except TimeoutError:
            timed_out = True
        if timed_out:
            raise SafeError(ErrorCode.AI_API_TIMEOUT, cause=TimeoutError)  # except の外
        return text

    async def _with_retries(self, provider: Provider, prompt: Prompt) -> str:
        attempts = 1 + self._max_retries
        last: SafeError | None = None
        for attempt in range(attempts):
            try:
                return await provider.complete(prompt)
            except SafeError as exc:
                if not exc.retryable:
                    raise
                last = exc
            if attempt < attempts - 1:
                await asyncio.sleep(self._backoff * (2**attempt))
        assert last is not None
        raise last
```

- [ ] **Step 7: 緑・型・整形を確認する**

```bash
.venv/bin/pytest tests/ai tests/test_config.py tests/test_errors.py tests/test_logging.py -q
.venv/bin/mypy app/errors.py app/logging.py app/config.py app/ai
.venv/bin/ruff check app/ai tests/ai && .venv/bin/black --check app/ai tests/ai
```

Expected: すべて緑。`test_deadline_covers_all_attempts` は 0.2 秒。

- [ ] **Step 8: コミット**

```bash
git add backend/app/ai backend/tests/ai
git commit -m "refactor: 新 backend の AI プロバイダ境界と変換サービスを足す（SDK 例外は型名のみ、再試行と締切を一元化）(Phase 2 / Task 5)"
```

---

### Task 6: `schemas.py` / `auth.py` / `ratelimit.py`

**Files:**
- Create: `backend/app/schemas.py`
- Create: `backend/app/auth.py`
- Create: `backend/app/ratelimit.py`
- Create: `backend/tests/test_schemas.py`
- Create: `backend/tests/test_auth.py`
- Create: `backend/tests/test_ratelimit.py`

**Interfaces:**
- Consumes: `PolitenessLevel`（Task 5）、`SafeError` `ErrorCode` `RateLimitExceeded`（Task 3）
- Produces: `ConversionRequest(input_text, politeness_level)`, `RegenerateRequest(+previous_result)`,
  `ConversionResponse(converted_text, original_text, politeness_level, processing_time_ms)`,
  `HealthResponse(status, ai_provider, version, timestamp)`；
  `API_KEY_HEADER_NAME`, `is_valid_api_key(candidate, allowed)`, `build_require_api_key(allowed) -> ApiKeyDependency`；
  `client_identifier(*, forwarded_for, client_host, trusted_proxy_count)`, `RateLimiter(*, times, seconds, trusted_proxy_count)`
  with `hit(namespace, request)` / `dependency(namespace)`

- [ ] **Step 1: schemas のテスト（B-1 境界値: 空・1・上限・絵文字・結合文字）**

`backend/tests/test_schemas.py`:

```python
from __future__ import annotations

import pytest
from pydantic import ValidationError

from app.ai.prompts import PolitenessLevel
from app.schemas import ConversionRequest, RegenerateRequest


def test_input_is_trimmed() -> None:
    request = ConversionRequest(input_text="  水 ぬるく  ", politeness_level=PolitenessLevel.NORMAL)
    assert request.input_text == "水 ぬるく"


@pytest.mark.parametrize("text", ["あい", "あ" * 500, "🙂🙂", "がき"])  # 結合文字も文字数で数える
def test_boundary_inputs_are_accepted(text: str) -> None:
    assert ConversionRequest(input_text=text, politeness_level="polite").input_text == text


@pytest.mark.parametrize("text", ["", "   ", "あ", "あ" * 501, "🙂"])
def test_out_of_range_inputs_are_rejected(text: str) -> None:
    with pytest.raises(ValidationError):
        ConversionRequest(input_text=text, politeness_level="normal")


def test_unknown_politeness_is_rejected() -> None:
    with pytest.raises(ValidationError):
        ConversionRequest(input_text="水 ぬるく", politeness_level="rude")


@pytest.mark.parametrize("previous", ["", "  ", "あ" * 1001])
def test_previous_result_bounds(previous: str) -> None:
    with pytest.raises(ValidationError):
        RegenerateRequest(input_text="水 ぬるく", politeness_level="normal", previous_result=previous)


def test_previous_result_is_trimmed() -> None:
    request = RegenerateRequest(input_text="水 ぬるく", politeness_level="normal", previous_result=" 前 ")
    assert request.previous_result == "前"
```

- [ ] **Step 2: schemas.py を書く**

`backend/app/schemas.py`:

```python
"""HTTP の入出力スキーマ。旧実装の外部契約（フィールド名・制約・検証文言）を維持する。"""

from __future__ import annotations

from pydantic import BaseModel, Field, field_validator

from app.ai.prompts import PolitenessLevel

INPUT_TEXT_MIN_LENGTH = 2
INPUT_TEXT_MAX_LENGTH = 500
PREVIOUS_RESULT_MAX_LENGTH = 1000


def _required_trimmed(value: object, *, required: str, empty: str) -> str:
    if value is None:
        raise ValueError(required)
    trimmed = str(value).strip()
    if not trimmed:
        raise ValueError(empty)
    return trimmed


class ConversionRequest(BaseModel):
    input_text: str = Field(
        ...,
        min_length=INPUT_TEXT_MIN_LENGTH,
        max_length=INPUT_TEXT_MAX_LENGTH,
        description=f"変換する入力文字列（{INPUT_TEXT_MIN_LENGTH}文字以上{INPUT_TEXT_MAX_LENGTH}文字以下）",
        examples=["ありがとう"],
    )
    politeness_level: PolitenessLevel = Field(..., description="丁寧さレベル（casual/normal/polite）", examples=["polite"])

    @field_validator("input_text", mode="before")
    @classmethod
    def _trim_input_text(cls, value: object) -> str:
        trimmed = _required_trimmed(value, required="入力文字列は必須です", empty="入力文字列が空です")
        if len(trimmed) < INPUT_TEXT_MIN_LENGTH:
            raise ValueError(f"入力文字列は{INPUT_TEXT_MIN_LENGTH}文字以上にしてください")
        if len(trimmed) > INPUT_TEXT_MAX_LENGTH:
            raise ValueError(f"入力文字列は{INPUT_TEXT_MAX_LENGTH}文字以下にしてください")
        return trimmed


class RegenerateRequest(ConversionRequest):
    previous_result: str = Field(
        ...,
        max_length=PREVIOUS_RESULT_MAX_LENGTH,
        description=f"前回の変換結果（重複回避用、{PREVIOUS_RESULT_MAX_LENGTH}文字以下）",
        examples=["ありがとうございます"],
    )

    @field_validator("previous_result", mode="before")
    @classmethod
    def _trim_previous_result(cls, value: object) -> str:
        trimmed = _required_trimmed(value, required="前回の変換結果は必須です", empty="前回の変換結果が空です")
        if len(trimmed) > PREVIOUS_RESULT_MAX_LENGTH:
            raise ValueError(f"前回の変換結果は{PREVIOUS_RESULT_MAX_LENGTH}文字以下にしてください")
        return trimmed


class ConversionResponse(BaseModel):
    converted_text: str = Field(..., description="変換後の文字列")
    original_text: str = Field(..., description="元の入力文字列（前後の空白を除く）")
    politeness_level: PolitenessLevel = Field(..., description="適用された丁寧さレベル")
    processing_time_ms: int = Field(..., description="変換処理時間（ミリ秒）")


class HealthResponse(BaseModel):
    status: str = Field(..., examples=["ok"])
    ai_provider: str = Field(..., description="実際に使う AI プロバイダ", examples=["anthropic", "openai", "none"])
    version: str = Field(..., examples=["1.0.0"])
    timestamp: str = Field(..., description="ISO 8601（UTC）", examples=["2026-09-02T12:34:56Z"])
```

- [ ] **Step 3: auth のテスト（B-3-3 / B-3-4）**

`backend/tests/test_auth.py`:

```python
from __future__ import annotations

import hmac

import pytest
from fastapi import Depends, FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.testclient import TestClient

from app.auth import build_require_api_key, is_valid_api_key
from app.errors import SafeError


def test_ascii_match_and_mismatch() -> None:
    allowed = (b"k%40@#=/+!?", b"second")
    assert is_valid_api_key("k%40@#=/+!?", allowed) is True
    assert is_valid_api_key("second", allowed) is True
    assert is_valid_api_key("third", allowed) is False
    assert is_valid_api_key("", allowed) is False and is_valid_api_key(None, allowed) is False


def test_non_ascii_candidate_is_false_not_error() -> None:
    assert is_valid_api_key("ｋｅｙ", (b"key",)) is False


def test_all_keys_are_compared_without_short_circuit(monkeypatch: pytest.MonkeyPatch) -> None:
    """一致しても走査を続ける（一致位置による時間差を作らない）。hmac.compare_digest（stdlib 境界）の呼び出し回数で見る。"""
    calls: list[bytes] = []
    real = hmac.compare_digest

    def counting(a: bytes, b: bytes) -> bool:
        calls.append(b)
        return real(a, b)

    monkeypatch.setattr(hmac, "compare_digest", counting)
    assert is_valid_api_key("first", (b"first", b"second", b"third")) is True
    assert calls == [b"first", b"second", b"third"]


def _app(allowed: tuple[bytes, ...]) -> TestClient:
    app = FastAPI()

    @app.exception_handler(SafeError)
    async def handler(_: Request, exc: SafeError) -> JSONResponse:
        return JSONResponse(status_code=401, content={"code": exc.code.value})

    @app.get("/p", dependencies=[Depends(build_require_api_key(allowed))])
    async def protected() -> dict[str, bool]:
        return {"ok": True}

    return TestClient(app)


def test_dependency_rejects_missing_and_wrong_key() -> None:
    client = _app((b"k",))
    assert client.get("/p").status_code == 401
    assert client.get("/p", headers={"X-API-Key": "x"}).json() == {"code": "AUTHENTICATION_ERROR"}
    assert client.get("/p", headers={"X-API-Key": "k"}).status_code == 200


def test_dependency_with_no_keys_lets_requests_through() -> None:
    assert _app(()).get("/p").status_code == 200


def test_openapi_declares_api_key_header() -> None:
    spec = _app((b"k",)).app.openapi()
    assert "APIKeyHeader" in spec["components"]["securitySchemes"]
```

- [ ] **Step 4: auth.py を書く**

`backend/app/auth.py`:

```python
"""端末 API キー認証（Issue #86 A / B-3-3 / B-3-4）。"""

from __future__ import annotations

import hmac
from collections.abc import Awaitable, Callable, Sequence

from fastapi import Security
from fastapi.security import APIKeyHeader

from app.errors import ErrorCode, SafeError

API_KEY_HEADER_NAME = "X-API-Key"

# OpenAPI の securitySchemes に載せる宣言。資源は作らない
api_key_header = APIKeyHeader(name=API_KEY_HEADER_NAME, auto_error=False)

ApiKeyDependency = Callable[..., Awaitable[None]]


def is_valid_api_key(candidate: str | None, allowed: Sequence[bytes]) -> bool:
    """許可キーのいずれかと一致するか。全キーを走査し短絡しない。非 ASCII は不一致（例外にしない）。"""
    if not candidate:
        return False
    try:
        candidate_bytes = candidate.encode("ascii")
    except UnicodeEncodeError:
        return False
    matched = False
    for key in allowed:
        if hmac.compare_digest(candidate_bytes, key):
            matched = True
    return matched


def build_require_api_key(allowed: tuple[bytes, ...]) -> ApiKeyDependency:
    """空タプルなら認証を省略する。省略してよいかの判定（config.auth_optional）は main が行う。"""

    async def require_api_key(api_key: str | None = Security(api_key_header)) -> None:
        if not allowed:
            return
        if not is_valid_api_key(api_key, allowed):
            raise SafeError(ErrorCode.AUTHENTICATION_ERROR)

    return require_api_key
```

- [ ] **Step 5: ratelimit のテスト（B-3-8 / B-3-9、namespace 独立、窓のリセット）**

`backend/tests/test_ratelimit.py`:

```python
from __future__ import annotations

import time

import pytest
from fastapi import Depends, FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.testclient import TestClient

from app.errors import RateLimitExceeded
from app.ratelimit import RateLimiter, client_identifier


@pytest.mark.parametrize(
    ("xff", "host", "count", "expected"),
    [
        (None, "9.9.9.9", 0, "9.9.9.9"),
        ("1.1.1.1", "9.9.9.9", 0, "9.9.9.9"),  # 信頼段数 0 なら XFF を見ない
        ("1.1.1.1, 2.2.2.2", "9.9.9.9", 1, "2.2.2.2"),  # 右から1番目
        ("1.1.1.1, 2.2.2.2, 3.3.3.3", "9.9.9.9", 2, "2.2.2.2"),  # 右から2番目
        ("1.1.1.1", "9.9.9.9", 2, "9.9.9.9"),  # チェーンが短い → 接続元（フェイルクローズ）
        ("", "9.9.9.9", 1, "9.9.9.9"),
        (None, None, 1, "unknown"),
    ],
)
def test_client_identifier(xff: str | None, host: str | None, count: int, expected: str) -> None:
    assert client_identifier(forwarded_for=xff, client_host=host, trusted_proxy_count=count) == expected


def _client(limiter: RateLimiter) -> TestClient:
    app = FastAPI()

    @app.exception_handler(RateLimitExceeded)
    async def handler(_: Request, exc: RateLimitExceeded) -> JSONResponse:
        return JSONResponse(status_code=429, content={"retry_after": exc.retry_after_seconds, "limit": exc.limit})

    @app.get("/a", dependencies=[Depends(limiter.dependency("a"))])
    async def a() -> dict[str, bool]:
        return {"ok": True}

    @app.get("/b", dependencies=[Depends(limiter.dependency("b"))])
    async def b() -> dict[str, bool]:
        return {"ok": True}

    return TestClient(app)


def test_second_hit_in_window_is_rejected_with_numbers() -> None:
    client = _client(RateLimiter(times=1, seconds=1, trusted_proxy_count=1))
    headers = {"X-Forwarded-For": "5.5.5.5"}
    assert client.get("/a", headers=headers).status_code == 200
    response = client.get("/a", headers=headers)
    assert response.status_code == 429
    assert response.json() == {"retry_after": 1, "limit": 1}


def test_namespaces_and_sources_are_independent() -> None:
    client = _client(RateLimiter(times=1, seconds=1, trusted_proxy_count=1))
    assert client.get("/a", headers={"X-Forwarded-For": "5.5.5.5"}).status_code == 200
    assert client.get("/b", headers={"X-Forwarded-For": "5.5.5.5"}).status_code == 200
    assert client.get("/a", headers={"X-Forwarded-For": "6.6.6.6"}).status_code == 200


def test_window_resets() -> None:
    client = _client(RateLimiter(times=1, seconds=1, trusted_proxy_count=1))
    headers = {"X-Forwarded-For": "7.7.7.7"}
    assert client.get("/a", headers=headers).status_code == 200
    time.sleep(1.1)
    assert client.get("/a", headers=headers).status_code == 200


def test_times_greater_than_one() -> None:
    client = _client(RateLimiter(times=2, seconds=5, trusted_proxy_count=1))
    headers = {"X-Forwarded-For": "8.8.8.8"}
    assert [client.get("/a", headers=headers).status_code for _ in range(3)] == [200, 200, 429]
```

- [ ] **Step 6: ratelimit.py を書く**

`backend/app/ratelimit.py`:

```python
"""レート制限（ADR-002）。カウンタはプロセス内メモリ。URI も設定キーも無い。

限界: 検出できるのは同一プロセス内だけ。single-worker × 複数 replica は素通しする
（replica 上限はデプロイ側の契約。ADR-002）。
"""

from __future__ import annotations

import math
import time
from collections.abc import Awaitable, Callable

from fastapi import Request
from limits import RateLimitItemPerSecond
from limits.aio.storage import MemoryStorage
from limits.aio.strategies import FixedWindowRateLimiter

from app.errors import RateLimitExceeded


def client_identifier(*, forwarded_for: str | None, client_host: str | None, trusted_proxy_count: int) -> str:
    """B-3-8 / B-3-9: 信頼する段数分のチェーンが無ければ XFF を採用せず接続元へ（フェイルクローズ）。"""
    if trusted_proxy_count > 0 and forwarded_for:
        parts = [part.strip() for part in forwarded_for.split(",") if part.strip()]
        if len(parts) >= trusted_proxy_count:
            return parts[-trusted_proxy_count]
    return client_host or "unknown"


class RateLimiter:
    def __init__(self, *, times: int, seconds: int, trusted_proxy_count: int) -> None:
        self._item = RateLimitItemPerSecond(times, seconds)
        self._limiter = FixedWindowRateLimiter(MemoryStorage())
        self._times = times
        self._seconds = seconds
        self._trusted_proxy_count = trusted_proxy_count

    async def hit(self, namespace: str, request: Request) -> None:
        identifier = client_identifier(
            forwarded_for=request.headers.get("X-Forwarded-For"),
            client_host=request.client.host if request.client else None,
            trusted_proxy_count=self._trusted_proxy_count,
        )
        if await self._limiter.hit(self._item, namespace, identifier):
            return
        stats = await self._limiter.get_window_stats(self._item, namespace, identifier)
        retry_after = min(self._seconds, max(1, math.ceil(stats.reset_time - time.time())))
        raise RateLimitExceeded(retry_after_seconds=retry_after, limit=self._times)

    def dependency(self, namespace: str) -> Callable[[Request], Awaitable[None]]:
        async def check(request: Request) -> None:
            await self.hit(namespace, request)

        return check
```

- [ ] **Step 7: 緑・型・整形を確認する**

```bash
.venv/bin/pytest tests/test_schemas.py tests/test_auth.py tests/test_ratelimit.py -q
.venv/bin/mypy app/errors.py app/logging.py app/config.py app/ai app/schemas.py app/auth.py app/ratelimit.py
.venv/bin/ruff check app tests --exclude app/api,app/core,app/crud,app/db,app/models,app/schemas,app/utils
.venv/bin/black --check app/schemas.py app/auth.py app/ratelimit.py tests/test_schemas.py tests/test_auth.py tests/test_ratelimit.py
```

Expected: すべて緑。

- [ ] **Step 8: コミット**

```bash
git add backend/app/schemas.py backend/app/auth.py backend/app/ratelimit.py backend/tests/test_schemas.py backend/tests/test_auth.py backend/tests/test_ratelimit.py
git commit -m "refactor: 新 backend の入出力スキーマ・API キー認証・プロセス内レート制限を足す（ADR-002）(Phase 2 / Task 6)"
```

---

### Task 7: `routes.py` + `main.py` を書き、旧実装を削除し、契約テストを新実装で緑にする

**このタスクが「差し替え」の瞬間。** 新規コードは約 250 行。削除は上限に数えない。

**Files:**
- Create: `backend/app/routes.py`
- Create: `backend/app/main.py`（旧 `app/main.py` を**上書き**）
- Create: `backend/tests/test_routes.py`
- Delete: `backend/app/api/ backend/app/core/ backend/app/crud/ backend/app/db/ backend/app/models/ backend/app/schemas/ backend/app/utils/`
- Delete: `backend/alembic/ backend/alembic.ini backend/logs/ backend/.coverage backend/coverage.xml backend/htmlcov/`
- Delete: 旧 `backend/tests/`（`tests/__init__.py` `tests/conftest.py` `tests/contract/` `tests/ai/` と Task 3〜6 で作った `tests/test_*.py` 以外すべて）

**Interfaces:**
- Consumes: Task 3〜6 の全公開名
- Produces: `create_app(config=None, *, provider_factory=build_provider, environ=None, argv=None) -> FastAPI`、
  `configured_worker_count(environ, argv) -> int`、`build_router(*, version, require_api_key, limiter) -> APIRouter`、
  `get_service(request) -> ConversionService`。起動コマンドは `uvicorn app.main:create_app --factory`

- [ ] **Step 1: routes のテスト（契約テストが見ない分: プロバイダ無しの 503、ログの中身、想定外例外）**

`backend/tests/test_routes.py`:

```python
"""契約テスト（tests/contract）が固定しない挙動。ログの観測は stdout（最も外側）で行う。"""

from __future__ import annotations

import json
from collections.abc import Iterator
from contextlib import contextmanager

import httpx
import pytest
import respx
from fastapi.testclient import TestClient

from app.ai.prompts import Prompt
from app.ai.providers import Provider
from app.config import ProviderName, RuntimeConfig
from app.errors import ErrorCode, SafeError
from app.main import create_app
from tests.conftest import make_config

CONVERT = "/api/v1/ai/convert"
HEADERS = {"X-API-Key": "test-key-A", "X-Forwarded-For": "1.2.3.4"}
BODY = {"input_text": "水 ぬるく CANARY-INPUT", "politeness_level": "normal"}


class FixedProvider:
    name: ProviderName = "anthropic"

    def __init__(self, outcome: str | BaseException) -> None:
        self._outcome = outcome

    async def complete(self, prompt: Prompt) -> str:
        if isinstance(self._outcome, BaseException):
            raise self._outcome
        return self._outcome

    async def aclose(self) -> None:
        return None


@contextmanager
def client_with(provider: Provider | None, **config_overrides: object) -> Iterator[TestClient]:
    app = create_app(make_config(**config_overrides), provider_factory=lambda _cfg: provider, environ={}, argv=[])
    with TestClient(app, raise_server_exceptions=False) as client:
        yield client


def _events(out: str) -> list[dict[str, object]]:
    return [json.loads(line) for line in out.splitlines() if line.startswith("{")]


def test_no_provider_is_503_and_health_says_none() -> None:
    with client_with(None) as client:
        assert client.get("/api/v1/health").json()["ai_provider"] == "none"
        response = client.post(CONVERT, json=BODY, headers=HEADERS)
    assert response.status_code == 503
    assert response.json()["error"]["code"] == "AI_PROVIDER_ERROR"


def test_success_log_has_latency_and_no_user_content(capsys: pytest.CaptureFixture[str]) -> None:
    with client_with(FixedProvider("お水をください CANARY-OUTPUT")) as client:
        assert client.post(CONVERT, json=BODY, headers=HEADERS).status_code == 200
    out = capsys.readouterr().out
    done = [e for e in _events(out) if e["event"] == "ConversionCompleted"]
    assert len(done) == 1
    assert done[0]["outcome"] == "success" and done[0]["provider"] == "anthropic" and done[0]["route"] == "convert"
    assert isinstance(done[0]["latency_ms"], int)
    assert "CANARY-INPUT" not in out and "CANARY-OUTPUT" not in out


def test_error_log_has_code_and_cause_type_only(capsys: pytest.CaptureFixture[str]) -> None:
    with client_with(FixedProvider(SafeError(ErrorCode.AI_API_TIMEOUT, cause=TimeoutError))) as client:
        assert client.post(CONVERT, json=BODY, headers=HEADERS).status_code == 504
    done = [e for e in _events(capsys.readouterr().out) if e["event"] == "ConversionCompleted"]
    assert done[0]["outcome"] == "error" and done[0]["error_code"] == "AI_API_TIMEOUT"
    assert done[0]["cause_type"] == "TimeoutError"


def test_unexpected_exception_is_500_internal_error_without_message() -> None:
    with client_with(FixedProvider(RuntimeError("CANARY-unexpected"))) as client:
        response = client.post(CONVERT, json=BODY, headers=HEADERS)
    assert response.status_code == 500
    assert response.json()["error"]["code"] == "INTERNAL_ERROR"
    assert "CANARY" not in response.text


def test_openai_provider_round_trip_through_http_boundary() -> None:
    config = make_config(DEFAULT_AI_PROVIDER="openai", OPENAI_API_KEY="sk-o")
    body = {
        "id": "c1", "object": "chat.completion", "created": 1, "model": "m",
        "choices": [{"index": 0, "message": {"role": "assistant", "content": "お水をください"}, "finish_reason": "stop"}],
    }
    with respx.mock(assert_all_mocked=True) as http:
        http.post("https://api.openai.com/v1/chat/completions").mock(return_value=httpx.Response(200, json=body))
        with TestClient(create_app(config, environ={}, argv=[])) as client:
            assert client.get("/api/v1/health").json()["ai_provider"] == "openai"
            assert client.post(CONVERT, json=BODY, headers=HEADERS).json()["converted_text"] == "お水をください"


def test_docs_hidden_outside_local_environments() -> None:
    with client_with(FixedProvider("x"), ENVIRONMENT="production") as client:
        assert client.get("/docs").status_code == 404
        assert client.get("/openapi.json").status_code == 404


def test_auth_skipped_only_when_local(capsys: pytest.CaptureFixture[str]) -> None:
    with client_with(FixedProvider("x"), API_KEYS="") as client:
        assert client.post(CONVERT, json=BODY, headers={"X-Forwarded-For": "2.2.2.2"}).status_code == 200
    assert any(e["event"] == "AuthenticationSkipped" for e in _events(capsys.readouterr().out))
    with pytest.raises(SafeError):
        create_app(make_config(ENVIRONMENT="staging", API_KEYS=""), provider_factory=lambda _c: None, environ={}, argv=[])


@pytest.mark.parametrize(
    ("environ", "argv", "expected"),
    [
        ({}, [], 1),
        ({"WEB_CONCURRENCY": "2"}, [], 2),
        ({}, ["uvicorn", "app.main:create_app", "--workers", "3"], 3),
        ({}, ["uvicorn", "--workers=4"], 4),
        ({}, ["uvicorn", "-w", "2"], 2),
        ({"WEB_CONCURRENCY": "x"}, ["--workers", "y"], 1),
    ],
)
def test_configured_worker_count(environ: dict[str, str], argv: list[str], expected: int) -> None:
    from app.main import configured_worker_count

    assert configured_worker_count(environ, argv) == expected


def test_multiple_workers_refuse_to_start() -> None:
    with pytest.raises(SafeError) as info:
        create_app(make_config(), environ={"WEB_CONCURRENCY": "2"}, argv=[])
    assert info.value.code is ErrorCode.STARTUP_MULTIPLE_WORKERS


def test_import_side_effect_free() -> None:
    import app.main as main_module

    assert not hasattr(main_module, "app")
    assert isinstance(RuntimeConfig, type)
```

- [ ] **Step 2: routes.py を書く**

`backend/app/routes.py`:

```python
"""公開ルート3本。想定外の例外は型名だけ拾って SafeError にする（計画 D5）。"""

from __future__ import annotations

from collections.abc import Awaitable
from datetime import datetime, timezone
from time import perf_counter
from typing import Literal

from fastapi import APIRouter, Depends, Request

from app.ai.service import ConversionService
from app.auth import ApiKeyDependency
from app.errors import ErrorCode, SafeError
from app.logging import ConversionCompleted, log_event
from app.ratelimit import RateLimiter
from app.schemas import ConversionRequest, ConversionResponse, HealthResponse, RegenerateRequest

Route = Literal["convert", "regenerate"]


def get_service(request: Request) -> ConversionService:
    service: ConversionService = request.app.state.conversion_service
    return service


async def _guarded(route: Route, service: ConversionService, call: Awaitable[str]) -> str:
    """成功・失敗を1行のログにし、例外は SafeError だけを上へ通す。"""
    started = perf_counter()
    text = ""
    failure: SafeError | None = None
    unexpected: type[BaseException] | None = None
    try:
        text = await call
    except SafeError as exc:
        failure = exc
    except Exception as exc:
        unexpected = type(exc)
    latency_ms = int((perf_counter() - started) * 1000)
    if unexpected is not None:
        failure = SafeError(ErrorCode.INTERNAL_ERROR, cause=unexpected)
    if failure is not None:
        log_event(
            ConversionCompleted(
                route=route,
                provider=service.provider_name,
                outcome="error",
                latency_ms=latency_ms,
                error_code=failure.code.value,
                cause_type=failure.cause_type,
            ),
            level="ERROR",
        )
        raise failure  # except の外
    log_event(ConversionCompleted(route=route, provider=service.provider_name, outcome="success", latency_ms=latency_ms))
    return text


def build_router(*, version: str, require_api_key: ApiKeyDependency, limiter: RateLimiter) -> APIRouter:
    router = APIRouter()

    @router.get("/health", response_model=HealthResponse, tags=["health"])
    async def health(service: ConversionService = Depends(get_service)) -> HealthResponse:
        return HealthResponse(
            status="ok",
            ai_provider=service.provider_name,
            version=version,
            timestamp=datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        )

    @router.post(
        "/ai/convert",
        response_model=ConversionResponse,
        tags=["ai"],
        summary="AI変換API",
        dependencies=[Depends(require_api_key), Depends(limiter.dependency("convert"))],
    )
    async def convert(
        body: ConversionRequest, service: ConversionService = Depends(get_service)
    ) -> ConversionResponse:
        started = perf_counter()
        text = await _guarded("convert", service, service.convert(body.input_text, body.politeness_level))
        return ConversionResponse(
            converted_text=text,
            original_text=body.input_text,
            politeness_level=body.politeness_level,
            processing_time_ms=int((perf_counter() - started) * 1000),
        )

    @router.post(
        "/ai/regenerate",
        response_model=ConversionResponse,
        tags=["ai"],
        summary="AI再変換API",
        dependencies=[Depends(require_api_key), Depends(limiter.dependency("regenerate"))],
    )
    async def regenerate(
        body: RegenerateRequest, service: ConversionService = Depends(get_service)
    ) -> ConversionResponse:
        started = perf_counter()
        text = await _guarded(
            "regenerate",
            service,
            service.regenerate(body.input_text, body.politeness_level, body.previous_result),
        )
        return ConversionResponse(
            converted_text=text,
            original_text=body.input_text,
            politeness_level=body.politeness_level,
            processing_time_ms=int((perf_counter() - started) * 1000),
        )

    return router
```

- [ ] **Step 3: main.py を書く（旧を上書き）**

`backend/app/main.py`:

```python
"""Application Factory（ADR-004）。import しただけでは何も作らない。

起動: ``uvicorn app.main:create_app --factory``
"""

from __future__ import annotations

import os
import sys
from collections.abc import AsyncIterator, Callable, Mapping, Sequence
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.ai.providers import Provider, build_provider
from app.ai.service import ConversionService
from app.auth import API_KEY_HEADER_NAME, build_require_api_key
from app.config import API_PREFIX, RuntimeConfig, load_config
from app.errors import HTTP_STATUS, USER_MESSAGE, ConfigError, ErrorCode, RateLimitExceeded, SafeError
from app.logging import AuthenticationSkipped, ProviderConfigured, RequestFailed, configure_logging, log_event
from app.ratelimit import RateLimiter
from app.routes import build_router

ProviderFactory = Callable[[RuntimeConfig], Provider | None]


def configured_worker_count(environ: Mapping[str, str], argv: Sequence[str]) -> int:
    """uvicorn / gunicorn 系が使う指定（WEB_CONCURRENCY・--workers N・--workers=N・-w N）の最大値。"""
    counts = [1]
    web = environ.get("WEB_CONCURRENCY", "")
    if web.isdigit():
        counts.append(int(web))
    for index, arg in enumerate(argv):
        if arg in ("--workers", "-w") and index + 1 < len(argv) and argv[index + 1].isdigit():
            counts.append(int(argv[index + 1]))
        elif arg.startswith("--workers=") and arg.removeprefix("--workers=").isdigit():
            counts.append(int(arg.removeprefix("--workers=")))
    return max(counts)


def create_app(
    config: RuntimeConfig | None = None,
    *,
    provider_factory: ProviderFactory = build_provider,
    environ: Mapping[str, str] | None = None,
    argv: Sequence[str] | None = None,
) -> FastAPI:
    # 起動ガード（ADR-002）。同一コンテナ内の worker 数までしか見えない
    if configured_worker_count(os.environ if environ is None else environ, sys.argv if argv is None else argv) > 1:
        raise SafeError(ErrorCode.STARTUP_MULTIPLE_WORKERS)

    cfg = load_config() if config is None else config
    configure_logging(cfg.LOG_LEVEL)

    api_keys = cfg.api_keys()
    if not api_keys:
        if not cfg.auth_optional:  # load_config の本番ゲートで落ちるが、config を直接渡された場合の守り
            raise ConfigError((("API_KEYS", "missing"),))
        log_event(AuthenticationSkipped(environment=cfg.ENVIRONMENT), level="WARNING")

    @asynccontextmanager
    async def lifespan(app: FastAPI) -> AsyncIterator[None]:
        provider = provider_factory(cfg)  # 資源は lifespan で生成する（ADR-004）
        service = ConversionService(
            provider, max_retries=cfg.AI_MAX_RETRIES, deadline_seconds=cfg.AI_CALL_DEADLINE_SECONDS
        )
        app.state.conversion_service = service
        log_event(ProviderConfigured(provider=service.provider_name))
        try:
            yield
        finally:
            if provider is not None:
                await provider.aclose()

    app = FastAPI(
        title=cfg.PROJECT_NAME,
        version=cfg.VERSION,
        description="文字盤コミュニケーション支援アプリ バックエンドAPI",
        docs_url="/docs" if cfg.docs_enabled else None,
        redoc_url="/redoc" if cfg.docs_enabled else None,
        openapi_url="/openapi.json" if cfg.docs_enabled else None,
        lifespan=lifespan,
    )
    app.add_middleware(
        CORSMiddleware,
        allow_origins=list(cfg.cors_origins()),
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    app.add_exception_handler(SafeError, _safe_error_handler)
    app.add_exception_handler(RequestValidationError, _validation_handler)
    app.add_exception_handler(Exception, _unexpected_handler)

    limiter = RateLimiter(
        times=cfg.RATE_LIMIT_TIMES, seconds=cfg.RATE_LIMIT_SECONDS, trusted_proxy_count=cfg.TRUSTED_PROXY_COUNT
    )
    app.include_router(
        build_router(version=cfg.VERSION, require_api_key=build_require_api_key(api_keys), limiter=limiter),
        prefix=API_PREFIX,
    )
    return app


def _error_body(code: ErrorCode, **extra: int) -> dict[str, object]:
    return {
        "success": False,
        "data": None,
        "error": {"code": code.value, "message": USER_MESSAGE[code], "status_code": HTTP_STATUS[code], **extra},
    }


async def _safe_error_handler(request: Request, exc: Exception) -> JSONResponse:
    assert isinstance(exc, SafeError)
    if exc.code is ErrorCode.AUTHENTICATION_ERROR:  # 旧契約: {"detail": …} + WWW-Authenticate
        return JSONResponse(
            status_code=401,
            content={"detail": USER_MESSAGE[exc.code]},
            headers={"WWW-Authenticate": API_KEY_HEADER_NAME},
        )
    if isinstance(exc, RateLimitExceeded):
        return JSONResponse(
            status_code=429,
            content=_error_body(exc.code, retry_after=exc.retry_after_seconds),
            headers={
                "Retry-After": str(exc.retry_after_seconds),
                "X-RateLimit-Limit": str(exc.limit),
                "X-RateLimit-Remaining": "0",
                "X-RateLimit-Reset": str(exc.retry_after_seconds),
            },
        )
    return JSONResponse(status_code=HTTP_STATUS[exc.code], content=_error_body(exc.code))


async def _validation_handler(request: Request, exc: Exception) -> JSONResponse:
    assert isinstance(exc, RequestValidationError)
    detail = [
        {"type": err.get("type", "unknown"), "loc": list(err.get("loc", ())), "msg": err.get("msg", "")}
        for err in exc.errors()  # input / ctx / url は載せない
    ]
    return JSONResponse(
        status_code=422,
        content={
            "error": USER_MESSAGE[ErrorCode.VALIDATION_ERROR],
            "detail": detail,
            "error_code": ErrorCode.VALIDATION_ERROR.value,
        },
    )


async def _unexpected_handler(request: Request, exc: Exception) -> JSONResponse:
    """routes が拾えなかった層（ミドルウェア等）の最後の受け皿。型名だけ記録する。"""
    log_event(
        RequestFailed(route=request.url.path, error_code=ErrorCode.INTERNAL_ERROR.value, cause_type=type(exc).__name__),
        level="ERROR",
    )
    return JSONResponse(status_code=500, content=_error_body(ErrorCode.INTERNAL_ERROR))
```

- [ ] **Step 4: 旧実装を削除する**

```bash
cd <worktree>/backend
git rm -r -q app/api app/core app/crud app/db app/models app/schemas app/utils alembic alembic.ini
git rm -r -q tests/core tests/db tests/test_api tests/test_security tests/utils
git rm -q tests/test_ai_client.py tests/test_ai_client_robustness.py tests/test_db_connection.py tests/test_db_schema_consistency.py tests/test_error_handlers.py tests/test_error_handling.py tests/test_harness_dsn.py tests/test_hash_utils.py tests/test_migration_execution.py tests/test_models_logs.py tests/test_performance.py tests/test_schemas_ai_conversion.py
rm -rf logs htmlcov .coverage coverage.xml .pytest_cache .ruff_cache
ls app tests   # app: __init__.py ai auth.py config.py errors.py logging.py main.py ratelimit.py routes.py schemas.py
```

- [ ] **Step 5: 全テストと契約テストを新実装で緑にする**

```bash
.venv/bin/pytest -q                       # pytest-randomly が自動で順序をシャッフルする
.venv/bin/pytest tests/contract -q -p no:randomly   # Task 2 Step 6 と同じ件数が緑であること
.venv/bin/mypy
.venv/bin/lint-imports
.venv/bin/ruff check app tests && .venv/bin/black --check app tests
```

Expected: すべて緑。契約テストの件数は Task 2 で記録した件数と一致。
`test_openapi.py` は廃止リスト適用後の baseline と一致。
赤が出たら、契約テストではなく**新実装側を直す**（契約テストを書き換えてよいのは、
廃止リストに項目を足すときだけ。足すなら計画書の廃止リストも同時に更新する）。

- [ ] **Step 6: 実物を起動して確認する（`superpowers:verification-before-completion`）**

```bash
cd <worktree>/backend
ENVIRONMENT=development API_KEYS=dev-key .venv/bin/uvicorn app.main:create_app --factory --port 8010 &
sleep 2
curl -s localhost:8010/api/v1/health
curl -s -X POST localhost:8010/api/v1/ai/convert -H 'Content-Type: application/json' -H 'X-API-Key: dev-key' -d '{"input_text":"水 ぬるく","politeness_level":"normal"}'
curl -s -o /dev/null -w '%{http_code}\n' localhost:8010/health
kill %1
```

Expected: health は `{"status":"ok","ai_provider":"none",…}`。convert はプロバイダ未設定なので
`503` と `AI_PROVIDER_ERROR`。`/health`（直付け）は `404`。stdout に JSON 行が出る。

- [ ] **Step 7: コミット**

```bash
git add -A backend
git commit -m "refactor: backend を Application Factory に差し替え、DB・alembic・旧テストを削除する（ADR-001/002/004、契約テストは旧・新で同結果）(Phase 2 / Task 7)"
```

---

### Task 8: canary（全シンク）・起動 smoke・起動ガード・grep ゲート・CI・Docker

**Files:**
- Create: `backend/tests/test_sinks.py`
- Create: `backend/tests/test_startup.py`
- Create: `backend/scripts/gates.sh`
- Modify: `backend/Makefile`
- Modify: `.github/workflows/python.yml`
- Modify: `backend/Dockerfile`, `docker/backend/Dockerfile`, `docker-compose.yml`
- Delete: `docker/postgres/`
- Modify: `backend/.env.example`, `.env.example`

**Interfaces:**
- Consumes: `create_app`, `configured_worker_count`（Task 7）

- [ ] **Step 1: canary を全シンクで観測するテスト**

`backend/tests/test_sinks.py`:

```python
"""ADR-003 の完了条件: 例外境界ごとに canary を注入し、stdout / stderr / HTTP ボディに現れないことを観測する。

境界: (1) プロバイダ SDK の HTTP 応答、(2) 入力検証、(3) 想定外例外、(4) 設定の失敗。
観測面 × 発火経路の表を、テストで1セルずつ埋める（verification-principles）。
"""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

import httpx
import pytest
import respx
from fastapi.testclient import TestClient

from app.ai.prompts import Prompt
from app.config import ProviderName
from app.main import create_app
from tests.conftest import make_config

BACKEND = Path(__file__).resolve().parents[1]
CONVERT = "/api/v1/ai/convert"
HEADERS = {"X-API-Key": "test-key-A", "X-Forwarded-For": "3.3.3.3"}
CANARY = "CANARY-7f3a9c"


def _assert_absent(canary: str, *surfaces: str) -> None:
    for surface in surfaces:
        assert canary not in surface


@pytest.mark.parametrize(
    "response",
    [
        httpx.Response(500, json={"type": "error", "error": {"type": "api_error", "message": CANARY}}),
        httpx.Response(429, json={"type": "error", "error": {"type": "rate_limit_error", "message": CANARY}}),
        httpx.Response(400, json={"type": "error", "error": {"type": "invalid_request_error", "message": CANARY}}),
        httpx.Response(200, content=f"<html>{CANARY}</html>".encode()),
    ],
)
def test_provider_boundary(capsys: pytest.CaptureFixture[str], response: httpx.Response) -> None:
    with respx.mock(assert_all_mocked=True) as http:
        http.post("https://api.anthropic.com/v1/messages").mock(return_value=response)
        with TestClient(create_app(make_config(), environ={}, argv=[]), raise_server_exceptions=False) as client:
            reply = client.post(CONVERT, json={"input_text": "水 ぬるく", "politeness_level": "normal"}, headers=HEADERS)
    out, err = capsys.readouterr()
    assert reply.status_code in {429, 500}
    _assert_absent(CANARY, reply.text, out, err)
    assert '"outcome": "error"' in out  # 観測面に何かが流れたことを確かめる（空振り防止）


def test_validation_boundary(capsys: pytest.CaptureFixture[str]) -> None:
    with TestClient(create_app(make_config(), provider_factory=lambda _c: None, environ={}, argv=[])) as client:
        reply = client.post(CONVERT, json={"input_text": CANARY * 60, "politeness_level": CANARY}, headers=HEADERS)
    out, err = capsys.readouterr()
    assert reply.status_code == 422
    _assert_absent(CANARY, reply.text, out, err)


class ExplodingProvider:
    name: ProviderName = "anthropic"

    async def complete(self, prompt: Prompt) -> str:
        raise KeyError(CANARY)

    async def aclose(self) -> None:
        return None


def test_unexpected_exception_boundary(capsys: pytest.CaptureFixture[str]) -> None:
    app = create_app(make_config(), provider_factory=lambda _c: ExplodingProvider(), environ={}, argv=[])
    with TestClient(app, raise_server_exceptions=False) as client:
        reply = client.post(CONVERT, json={"input_text": "水 ぬるく", "politeness_level": "normal"}, headers=HEADERS)
    out, err = capsys.readouterr()
    assert reply.status_code == 500 and reply.json()["error"]["code"] == "INTERNAL_ERROR"
    _assert_absent(CANARY, reply.text, out, err)
    assert '"cause_type": "KeyError"' in out


def test_config_boundary_in_a_real_process(tmp_path: Path) -> None:
    """設定失敗はプロセスの stdout / stderr 全体で観測する（8周で唯一破られなかった検証法）。"""
    (tmp_path / ".env").write_text(f"ANTHROPIC_API_KEY=sk-{CANARY}-é\nRATE_LIMIT_TIMES={CANARY}\n", encoding="utf-8")
    proc = subprocess.run(
        [sys.executable, "-c", "from app.main import create_app; create_app()"],
        cwd=tmp_path,
        env={"PATH": "", "PYTHONPATH": str(BACKEND), "ENVIRONMENT": "production", "API_KEYS": "k"},
        capture_output=True,
        text=True,
        timeout=60,
    )
    assert proc.returncode != 0
    _assert_absent(CANARY, proc.stdout, proc.stderr)
    assert "CONFIG_INVALID" in proc.stderr and "ANTHROPIC_API_KEY" in proc.stderr and "RATE_LIMIT_TIMES" in proc.stderr
```

- [ ] **Step 2: 起動 smoke と起動ガードのテスト（実プロセス）**

`backend/tests/test_startup.py`:

```python
"""B-3-2（記号入りキーで起動し /health 200 ＋ AI 変換1往復）、ADR-004 の import smoke、ADR-002 の起動ガード。

AI 変換の往復は SDK 標準の ANTHROPIC_BASE_URL で偽プロバイダ（このテスト内の HTTP サーバー）へ向ける（計画 D7）。
"""

from __future__ import annotations

import json
import os
import socket
import subprocess
import sys
import threading
import time
from collections.abc import Iterator
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

import httpx
import pytest

BACKEND = Path(__file__).resolve().parents[1]
DEVICE_KEY = "k%40@#=/+!?"
PROVIDER_KEY = "sk-p%40@#=/+!?"
ANTHROPIC_OK = {
    "id": "msg_1", "type": "message", "role": "assistant", "model": "m",
    "content": [{"type": "text", "text": "お水をぬるめでお願いします"}],
    "stop_reason": "end_turn", "stop_sequence": None,
    "usage": {"input_tokens": 1, "output_tokens": 1},
}


def _free_port() -> int:
    with socket.socket() as sock:
        sock.bind(("127.0.0.1", 0))
        return int(sock.getsockname()[1])


class FakeAnthropic(ThreadingHTTPServer):
    seen_api_keys: list[str]


class _Handler(BaseHTTPRequestHandler):
    def do_POST(self) -> None:  # noqa: N802
        server: FakeAnthropic = self.server  # type: ignore[assignment]
        server.seen_api_keys.append(self.headers.get("x-api-key", ""))
        self.rfile.read(int(self.headers.get("content-length", "0")))
        body = json.dumps(ANTHROPIC_OK).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, format: str, *args: object) -> None:  # noqa: A002
        return None


@pytest.fixture
def fake_provider() -> Iterator[FakeAnthropic]:
    server = FakeAnthropic(("127.0.0.1", 0), _Handler)
    server.seen_api_keys = []
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    try:
        yield server
    finally:
        server.shutdown()


def _base_env(**extra: str) -> dict[str, str]:
    env = {"PATH": os.environ["PATH"], "PYTHONPATH": str(BACKEND), "PYTHONUNBUFFERED": "1"}
    env.update(extra)
    return env


def _spawn(port: int, env: dict[str, str], *args: str) -> subprocess.Popen[str]:
    return subprocess.Popen(
        [sys.executable, "-m", "uvicorn", "app.main:create_app", "--factory", "--port", str(port), *args],
        cwd=BACKEND,
        env=env,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )


def _wait_for(port: int, seconds: float = 15.0) -> bool:
    deadline = time.time() + seconds
    while time.time() < deadline:
        try:
            httpx.get(f"http://127.0.0.1:{port}/api/v1/health", timeout=0.5)
            return True
        except httpx.HTTPError:
            time.sleep(0.2)
    return False


def _stop(proc: subprocess.Popen[str]) -> tuple[str, str]:
    proc.terminate()
    try:
        return proc.communicate(timeout=10)
    except subprocess.TimeoutExpired:
        proc.kill()
        return proc.communicate()


def test_import_has_no_side_effects(tmp_path: Path) -> None:
    (tmp_path / "sitecustomize.py").write_text(
        "import socket\n"
        "def _blocked(*args, **kwargs):\n    raise RuntimeError('network blocked')\n"
        "socket.socket.connect = _blocked\n"
        "socket.socket.bind = _blocked\n",
        encoding="utf-8",
    )
    proc = subprocess.run(
        [sys.executable, "-c", "import app.main"],
        cwd=tmp_path,  # .env が無い場所
        env={"PATH": "", "PYTHONPATH": f"{tmp_path}{os.pathsep}{BACKEND}"},
        capture_output=True,
        text=True,
        timeout=60,
    )
    assert proc.returncode == 0
    assert proc.stdout == "" and proc.stderr == ""


def test_symbol_keys_health_and_conversion_round_trip(fake_provider: FakeAnthropic) -> None:
    port = _free_port()
    env = _base_env(
        ENVIRONMENT="production",
        API_KEYS=DEVICE_KEY,
        ANTHROPIC_API_KEY=PROVIDER_KEY,
        ANTHROPIC_BASE_URL=f"http://127.0.0.1:{fake_provider.server_address[1]}",
        CORS_ORIGINS="http://localhost:3000",
    )
    proc = _spawn(port, env)
    try:
        assert _wait_for(port)
        base = f"http://127.0.0.1:{port}"
        health = httpx.get(f"{base}/api/v1/health")
        assert health.status_code == 200 and health.json()["ai_provider"] == "anthropic"
        assert httpx.get(f"{base}/docs").status_code == 404  # production では非公開
        reply = httpx.post(
            f"{base}/api/v1/ai/convert",
            json={"input_text": "水 ぬるく", "politeness_level": "normal"},
            headers={"X-API-Key": DEVICE_KEY},
        )
        assert reply.status_code == 200
        assert reply.json()["converted_text"] == "お水をぬるめでお願いします"
        assert fake_provider.seen_api_keys == [PROVIDER_KEY]
    finally:
        out, err = _stop(proc)
    assert '"event": "ConversionCompleted"' in out
    assert PROVIDER_KEY not in out + err and DEVICE_KEY not in out + err


@pytest.mark.parametrize("variant", ["argv", "env"])
def test_multiple_workers_refuse_to_serve(variant: str) -> None:
    port = _free_port()
    env = _base_env(ENVIRONMENT="development")
    args: tuple[str, ...] = ()
    if variant == "argv":
        args = ("--workers", "2")
    else:
        env["WEB_CONCURRENCY"] = "2"
    proc = _spawn(port, env, *args)
    try:
        assert not _wait_for(port, seconds=6)
    finally:
        out, err = _stop(proc)
    assert "STARTUP_MULTIPLE_WORKERS" in err
    assert "Application startup complete" not in err


def test_single_worker_serves() -> None:
    port = _free_port()
    proc = _spawn(port, _base_env(ENVIRONMENT="development"))
    try:
        assert _wait_for(port)
    finally:
        _stop(proc)
```

- [ ] **Step 3: grep ゲート（完了条件の grep をそのまま実行する。枠組みは持たない）**

`backend/scripts/gates.sh`:

```bash
#!/usr/bin/env bash
# 親計画 §6 Phase 2 の完了条件のうち grep で判定するもの。ここに検出器を育てないこと（ADR-008）。
set -euo pipefail
cd "$(dirname "$0")/.."

fail=0
report() { echo "::error::$1"; fail=1; }

hits=$(grep -rnE 'str\(exc\)|str\(e\)|format_exc|print\(|print_exc|sys\.stderr' app --include='*.py' | grep -v '^app/logging.py' || true)
[ -z "$hits" ] || { echo "$hits"; report "ADR-003: 自由文字列のシンクが app/ にある"; }

hits=$(grep -rnE '^\s*(import logging|from logging)' app --include='*.py' | grep -v '^app/logging.py' || true)
[ -z "$hits" ] || { echo "$hits"; report "ADR-003: stdlib logging の import は app/logging.py だけ"; }

hits=$(grep -rnE "patch\(['\"]app\." tests --include='*.py' || true)
[ -z "$hits" ] || { echo "$hits"; report "テスト規律: 自分の関数を patch している"; }

hits=$(grep -inE '^(sqlalchemy|alembic|asyncpg|psycopg2-binary|redis|slowapi)\b' requirements*.txt || true)
[ -z "$hits" ] || { echo "$hits"; report "ADR-001/002: DB・Redis 系の依存がある"; }

for gone in app/models app/crud app/db alembic alembic.ini; do
  [ ! -e "$gone" ] || report "ADR-001: $gone が存在する"
done

[ "$fail" -eq 0 ] && echo "gates: ok"
exit "$fail"
```

`backend/Makefile` に足す:

```makefile
gate:  ## 完了条件の grep ゲート
	bash scripts/gates.sh

check: lint gate  ## lint + 型 + 層契約 + ゲート
	mypy
	lint-imports
```

`chmod +x backend/scripts/gates.sh` して `make gate` が `gates: ok` を出すこと。

- [ ] **Step 4: CI を書き換える**

`.github/workflows/python.yml` の `env.PYTHON_VERSION` を `'3.12'` にし、`test` ジョブを次に置き換える
（`services.postgres`・`Wait for PostgreSQL`・`Run database migrations` を削除。`lint` は
`pip install -r requirements-dev.txt` に変え、`Run Ruff` の後に型・層・ゲートを足す）:

```yaml
  lint:
    name: Lint / Types / Layers / Gates
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: backend
    steps:
      - uses: actions/checkout@v6
      - uses: actions/setup-python@v6
        with:
          python-version: ${{ env.PYTHON_VERSION }}
          cache: 'pip'
          cache-dependency-path: './backend/requirements-dev.txt'
      - run: python -m pip install --upgrade pip && pip install -r requirements-dev.txt
      - run: ruff check app tests
      - run: black --check app tests
      - run: mypy                      # ADR-003 / 004（strict、対象は pyproject の files）
      - run: lint-imports              # ADR-006
      - run: bash scripts/gates.sh     # 完了条件の grep

  test:
    name: Test & Coverage
    runs-on: ubuntu-latest
    needs: lint
    defaults:
      run:
        working-directory: backend
    steps:
      - uses: actions/checkout@v6
      - uses: actions/setup-python@v6
        with:
          python-version: ${{ env.PYTHON_VERSION }}
          cache: 'pip'
          cache-dependency-path: './backend/requirements-dev.txt'
      - run: python -m pip install --upgrade pip && pip install -r requirements-dev.txt
      - name: Run tests (pytest-randomly shuffles order; seed is printed in the log)
        run: pytest --cov=app --cov-report=xml --cov-report=term-missing -v
```

`Report coverage` 以降のステップ、`security`、`build-docker`、deploy のジョブはそのまま残す。

- [ ] **Step 5: Docker と compose**

`backend/Dockerfile`:

```dockerfile
FROM python:3.12-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip wheel --no-cache-dir --no-deps --wheel-dir /app/wheels -r requirements.txt

FROM python:3.12-slim
WORKDIR /app
RUN groupadd -r kotonoha && useradd -r -g kotonoha kotonoha
COPY --from=builder /app/wheels /wheels
RUN pip install --no-cache /wheels/* && rm -rf /wheels
COPY app ./app
RUN chown -R kotonoha:kotonoha /app
USER kotonoha
ENV PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/api/v1/health')" || exit 1
# worker は 1 つ（ADR-002）。--workers を足すと起動ガードで落ちる
CMD ["uvicorn", "app.main:create_app", "--factory", "--host", "0.0.0.0", "--port", "8000"]
```

`docker/backend/Dockerfile`（開発用）:

```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY backend/requirements-dev.txt backend/requirements.txt ./
RUN pip install --no-cache-dir -r requirements-dev.txt
COPY backend/ .
CMD ["uvicorn", "app.main:create_app", "--factory", "--host", "0.0.0.0", "--port", "8000", "--reload"]
```

`docker-compose.yml`:

```yaml
services:
  backend:
    # 開発用（--reload・ボリュームマウント前提）。本番イメージは backend/Dockerfile。
    build:
      context: .
      dockerfile: ./docker/backend/Dockerfile
    container_name: kotonoha_backend
    # アプリ設定は backend/.env（マウント経由で /app/.env）。ここには何も書かない——
    # compose の environment は OS 環境変数として .env より優先され、静かに上書きする。
    ports:
      - "8000:8000"
    volumes:
      - ./backend:/app
    restart: unless-stopped
```

`git rm -r docker/postgres`。

- [ ] **Step 6: .env.example を書き換える**

`backend/.env.example` 全文:

```
# kotonoha backend の設定。cp .env.example .env して値を入れる。
# ここに無いキー（POSTGRES_* / SECRET_KEY / RATE_LIMIT_STORAGE_URI など）は旧 backend の名残で、
# 残っていても起動は止まらず警告が出るだけ（ADR-001 / ADR-002）。

# development / test では API_KEYS が空なら認証を省略し /docs を公開する。
# staging / production では API_KEYS と既定プロバイダのキーが無いと起動しない（全違反を一度に報告する）。
ENVIRONMENT=development

# 端末 API キー（カンマ区切り、印字可能 ASCII のみ）。端末ごとに別のキーを発行することを推奨。
API_KEYS=

CORS_ORIGINS=http://localhost:3000,http://localhost:5173,http://localhost:8080

# レート制限: RATE_LIMIT_TIMES 回 / RATE_LIMIT_SECONDS 秒 / 送信元 IP（ADR-002）。
# カウンタはプロセス内メモリ。worker を 2 以上にすると起動時に落ちる。
RATE_LIMIT_TIMES=1
RATE_LIMIT_SECONDS=10
# 信頼するリバースプロキシの段数。0 なら X-Forwarded-For を見ない。ALB 等の背後では実段数（通常 1）を設定する。
# 実構成より大きい値にすると XFF が常に不採用になり、全利用者が同じ IP に収束して実質停止する。
TRUSTED_PROXY_COUNT=0

LOG_LEVEL=INFO

# AI プロバイダ。DEFAULT_AI_PROVIDER のキーだけが使われる。キーは印字可能 ASCII のみ。
DEFAULT_AI_PROVIDER=anthropic
# ANTHROPIC_API_KEY=sk-ant-...
ANTHROPIC_MODEL=claude-sonnet-4-6
# OPENAI_API_KEY=sk-...
OPENAI_MODEL=gpt-4o-mini

# 1 試行のタイムアウト（秒）／再試行回数（接続エラー・429 のみ）／リクエスト全体の締切（秒）。
# frontend（Dio）の connect / receive タイムアウト各 10 秒と整合させる。
AI_API_TIMEOUT=8
AI_MAX_RETRIES=1
AI_CALL_DEADLINE_SECONDS=10
```

ルート `.env.example` からは `POSTGRES_*` と `SECRET_KEY` の行とその説明を消し、
「docker-compose が参照する変数」の節を削除する（Flutter 向けの `API_BASE_URL` / `AI_API_KEY` は残す）。

- [ ] **Step 7: 全部を通す**

```bash
cd <worktree>/backend
.venv/bin/pytest -q && make check
docker build -f Dockerfile -t kotonoha-backend:phase2 . && docker run --rm -e ENVIRONMENT=development -p 8011:8000 -d --name k2 kotonoha-backend:phase2 && sleep 3 && curl -s localhost:8011/api/v1/health; docker rm -f k2
```

Expected: pytest 緑（`test_startup.py` は実プロセスを4回起動するので 20〜40 秒）、`make check` 緑、
コンテナの health が 200。

- [ ] **Step 8: コミット**

```bash
git add -A backend docker docker-compose.yml .env.example .github/workflows/python.yml
git commit -m "test: canary 全シンク観測・記号キー起動 smoke・起動ガードを足し、CI と Docker から DB を外す（ADR-002/003/004）(Phase 2 / Task 8)"
```

---

### Task 9: 文書・ADR-006 改訂・台帳・2系統レビュー・PR

**Files:**
- Modify: `AGENTS.md`（技術スタック／開発コマンド／API仕様／レート制限の各節）
- Modify: `docs/tech-stack.md`（backend・DB 節）
- Modify: `docs/adr/ADR-006-layer-dependency-enforced.md`（層の改訂: D8）
- Modify: `docs/plans/2026-08-29-architecture-remediation.md`（状態欄）
- Modify: `.pre-commit-config.yaml`（`ruff` の `files` はそのまま。mypy のコメントアウトを削除するだけ）

- [ ] **Step 1: AGENTS.md を新 backend の実態に合わせる**

「技術スタック」節:

```
- **バックエンド**: FastAPI 0.124 + Python 3.12。**ステートレス（DB 無し）**。AI プロバイダへのプロキシのみ
```

「開発コマンド」節の Docker / backend / DB の行を次に置き換える（Flutter の部分は触らない）:

```bash
# 開発用コンテナ（backend のみ。DB は無い）
docker-compose up -d

# バックエンドサーバー起動（リポジトリルートから。Application Factory なので --factory が要る）
(cd backend && .venv/bin/uvicorn app.main:create_app --factory --reload)

# テスト・型・層契約・ゲート（backend/）
pytest                    # pytest-randomly が順序をシャッフルする
make check                # ruff + black + mypy --strict + lint-imports + scripts/gates.sh
```

`alembic upgrade head` の行と「DBマイグレーション」の見出しを削除する。

「API仕様」節の主要エンドポイントを3本にし、レート制限の項を次に置き換える:

```
### 主要エンドポイント
- `POST /api/v1/ai/convert` - AI変換（平均3秒以内）。`X-API-Key` 必須（development / test で `API_KEYS` 未設定のときだけ省略）
- `POST /api/v1/ai/regenerate` - AI変換再生成
- `GET /api/v1/health` - ヘルスチェック（`status` / `ai_provider` / `version` / `timestamp`。DB 項目は無い）

### レート制限
- AI変換API: 1リクエスト/10秒/IP（`RATE_LIMIT_TIMES` / `RATE_LIMIT_SECONDS`）。守る対象の定義は **ADR-002**
  - カウンタは**プロセス内メモリ**。共有ストレージの設定キーは存在しない。worker を 2 以上にすると起動時に
    `STARTUP_MULTIPLE_WORKERS` で落ちる（同一コンテナ内のみ検出。replica 上限はデプロイ側の契約——ADR-002）
  - **`TRUSTED_PROXY_COUNT`（デフォルト0）**: 信頼する自前プロキシの段数。（以下、現在の3項目はそのまま）
```

「セキュリティ・プライバシー」節の「通信セキュリティ」は変えない。
「テスト実行」の `pytest # Backend` はそのまま。
「負債を作る行為には理由が要る」節は変えない（永続化面の項目は frontend 向けに残る）。

- [ ] **Step 2: tech-stack.md の backend・DB 節を実態に合わせる**

「⚙️ バックエンド」の「ORM・データベース接続」を削除し、代わりに:

```
### 永続化
- **無し。** backend はステートレス（ADR-001）。運用情報は stdout の構造化ログ（JSON Lines）で取る
```

「💾 データベース」節は見出しを「💾 データベース（廃止）」にし、本文を
「2026-09 の Phase 2 で削除した。経緯と再訪条件は ADR-001」の1段落にする。
「コンテナ化」の PostgreSQL / Redis の行、「インフラ」の RDS の行、「SQL Injection対策」の行を削除する。
Python のバージョン記述があれば 3.12 にする。

- [ ] **Step 3: ADR-006 を改訂する（D8）**

`docs/adr/ADR-006-layer-dependency-enforced.md` の「決定」の層を次に差し替え、
末尾に改訂の段落を足す:

```
main    → routes
routes  → schemas / auth / ratelimit / ai / errors / config / logging
schemas → ai（PolitenessLevel の語彙を1つにするため）
auth | ratelimit | ai → config / errors / logging（互いには依存しない）
config  → errors / logging（設定失敗を ConfigError で表し、削除済みキーの警告を出すため）
logging → errors 以下
errors  → （依存なし）
```

```
## 改訂（2026-09-xx、Phase 2 実装時）

草案は `config → 依存なし` としていたが、pydantic の ValidationError が入力値（秘密）を
文字列に含むため、config は失敗を型（`ConfigError`）に載せ替えて外へ出す必要があり、
errors への依存が要る。語彙を2つ持たないために `config → errors` を許した。
`schemas → ai` も同じ理由（丁寧さレベルの列挙を1つにする）。契約は `backend/pyproject.toml`
の `[tool.importlinter]` が正本で、CI の `lint-imports` が強制する。
```

- [ ] **Step 4: 親計画の状態欄を更新する**

`docs/plans/2026-08-29-architecture-remediation.md` の3行目を
「Phase 0・1・2・3 完了（2026-09-xx）。次は リリース準備 → Phase 4」に変え、
箇条書きに Phase 2 の1行（決定1・2の実施、契約テスト旧新同結果、到達行数の実測値）を足す。
`§2 現状` の数値は触らない（日付付きの実測値として残す）。

- [ ] **Step 5: 完了条件を1つずつ機械的に確かめる**

```bash
cd <worktree>/backend
test ! -e app/models && test ! -e app/crud && test ! -e app/db && test ! -e alembic && echo "1 ok"
! grep -iE '^(sqlalchemy|alembic|asyncpg|psycopg2-binary|redis)\b' requirements*.txt && echo "2 ok"
make gate                                  # 3: grep が 0 件、patch("app. が 0 件
.venv/bin/pytest tests/test_sinks.py -q    # 4: canary が全シンクに現れない
.venv/bin/lint-imports && .venv/bin/mypy && .venv/bin/pytest -q -p randomly   # 5
.venv/bin/pytest tests/test_startup.py -q  # 6: 記号キーで起動し /health 200 + AI 1往復
.venv/bin/pytest tests/contract -q         # 7: OpenAPI diff 空（廃止リスト除く）・契約が旧新同結果
.venv/bin/pytest tests/test_routes.py -q   # 8: ログに latency・成否・プロバイダ
grep -n "alembic\|Redis\|RATE_LIMIT_STORAGE_URI\|postgres" ../AGENTS.md   # 9: 0 件であること
find app -name '*.py' | xargs wc -l | tail -1   # 到達行数を記録する（目安 約1,000）
```

- [ ] **Step 6: 台帳と Issue #86 を更新する**

`gh issue comment 85` に Phase 2 の結果を書く（SDD の ledger にある ruling / parked / deferred を
転記する——ledger は完了時に消える。SDD 条件4）。内容:
実施した決定（D1〜D8）、廃止リスト、完了条件の確認結果（Step 5 の出力）、
台帳へ送るもの（`docs/design/kotonoha/api-endpoints.md` は成功応答の形が実装と食い違っている——
Phase 5 で OpenAPI を正本にして整理）、`tsumiki` プラグインが無効で
`ipa-security-check` を回せていないこと。

`gh issue comment 86` に B-3-1〜B-3-9 と新テスト名の対応表を書き、`gh issue close 86`。

| Issue #86 | テスト |
|---|---|
| B-3-1 起動失敗時に設定値が出ない | `test_sinks.py::test_config_boundary_in_a_real_process` |
| B-3-2 記号入りキーで起動＋往復 | `test_startup.py::test_symbol_keys_health_and_conversion_round_trip` |
| B-3-3 非ASCII キー | `test_auth.py::test_non_ascii_candidate_is_false_not_error`、`test_config.py::test_non_ascii_key_is_rejected_at_load_without_echoing_value` |
| B-3-4 短絡評価しない | `test_auth.py::test_all_keys_are_compared_without_short_circuit` |
| B-3-5 例外連鎖 | `ai/test_providers.py::test_anthropic_failures_become_safe_errors`（`__context__ is None`） |
| B-3-6 全違反を一度に | `test_config.py::test_non_local_load_fails_with_every_problem` |
| B-3-7 削除済みキー | `test_config.py::test_removed_keys_in_dotenv_warn_but_do_not_fail` |
| B-3-8 / B-3-9 XFF | `test_ratelimit.py::test_client_identifier`、`contract/test_ratelimit.py` の2本 |

- [ ] **Step 7: 2系統レビュー（マージ境界。SDD 条件3）**

1. SDD の final whole-branch review（拘束ブロックを渡す）
2. `codex:rescue` に同じ差分と拘束ブロックを渡し、独立にレビューさせる
3. 両系統の指摘を P0 / P1 / P2 に分ける。**P0 は直す。P0 の格下げは人に出す。** P2 は #85 へ
4. **ipa-security-check**: `tsumiki` プラグインが有効なら `tsumiki:ipa-security-check` を回し、
   出典付きの指摘を #85 に転記する。無効なら「未実施」と #85 に明記し、有効化を人に依頼する

- [ ] **Step 8: コミットと PR**

```bash
git add AGENTS.md docs/tech-stack.md docs/adr/ADR-006-layer-dependency-enforced.md docs/plans/2026-08-29-architecture-remediation.md .pre-commit-config.yaml
git commit -m "docs: AGENTS.md と tech-stack を新 backend に合わせ、ADR-006 の層を改訂する (Phase 2 / Task 9)"
git push -u origin phase2/backend-rewrite
gh pr create --title "Phase 2: backend を書き直す（ADR-001〜004・006）" --body-file <(cat <<'PR'
## 何を
旧 backend（DB あり・5ルート・3,545行）を、同じ URL・同じスキーマのステートレスな AI 変換プロキシ（3ルート）へ差し替えた。

## 契約
- `backend/tests/contract/` を旧に当てて固定（Task 1・2 のコミットで緑）→ 新に当てて同結果
- 正規化 OpenAPI diff は廃止リスト（計画書）を除いて空
- 廃止: `GET /` `GET /health`、health の `database`、production で API_KEYS 未設定時の 503 → 起動失敗

## 完了条件（親計画 §6 Phase 2）
（Task 9 Step 5 の出力を貼る）

## 台帳
- #85 に転記済み、#86 は close
- `tsumiki:ipa-security-check` は（実施済み／プラグイン無効のため未実施）

計画: docs/plans/2026-09-02-phase2-backend-tasks.md（マージ後に破棄）

🤖 Generated with [Claude Code](https://claude.com/claude-code)
PR
)
```

マージ後: `superpowers:finishing-a-development-branch`。計画書
`docs/plans/2026-09-02-phase2-backend-tasks.md` を削除する（決定は ADR と台帳へ移してある）。

---

## 完了条件（親計画 §6 Phase 2）とタスクの対応

| 完了条件 | 満たすタスク・検査 |
|---|---|
| `app/models` `app/crud` `app/db` `alembic` が存在しない | Task 7 Step 4、`scripts/gates.sh` |
| `requirements.txt` に DB・Redis 系が無い | Task 3 Step 1、`scripts/gates.sh` |
| `str(exc)` 等が `app/` に 0 件（`app/logging.py` を除く） | `scripts/gates.sh`（CI） |
| 例外境界ごとの canary が stdout / stderr / HTTP ボディに現れない | Task 8 `test_sinks.py`（4境界） |
| `import-linter` `mypy --strict` `pytest-randomly` が CI で緑 | Task 3（設定）、Task 8（CI） |
| 自分の関数を patch している箇所が 0 件 | `scripts/gates.sh`、テストは respx / Protocol の偽物のみ |
| 記号入りキーで起動し `/health` 200 ＋ AI 変換1往復 | Task 8 `test_startup.py`（実プロセス＋偽プロバイダ） |
| 旧・新の正規化 OpenAPI diff が空（廃止分を除く） | Task 2 baseline、Task 7 で新に適用 |
| 同じ characterization テストが旧・新で同結果 | Task 1・2（旧）→ Task 7（新）。件数を記録 |
| 構造化ログに latency・成否・プロバイダが載る | Task 7 `test_routes.py`（stdout を観測） |
| `AGENTS.md` が新 backend と一致（Redis 前提が無い） | Task 9 Step 1・5 |

## B の観点（親計画 §5 Phase 2 の表）とテストの対応

| 源 | 観点 | テスト |
|---|---|---|
| B-3 | 設定の組み立て → 実接続 | `test_startup.py::test_symbol_keys_…` |
| B-3 | 境界での例外変換（全シンク） | `test_sinks.py` |
| B-3 | 環境ガード（両方の環境） | `test_config.py::test_local_…` / `test_non_local_…`、`test_routes.py::test_docs_hidden_…` / `test_auth_skipped_only_when_local` |
| B-3 | 起動（import の出力全体） | `test_startup.py::test_import_has_no_side_effects` |
| B-1 | 境界値 | `test_schemas.py`（空・1・上限・絵文字・結合文字） |
| B-1 | 失敗注入 | `ai/test_providers.py`（落ちる／遅い／不正応答）、`test_sinks.py` |
| B-1 | べき等性・再試行 | `ai/test_service.py` |
| B-1 | 時間（締切） | `ai/test_service.py::test_deadline_…`、`contract/test_ai.py::test_deadline_exceeded_is_504` |
| B-1 | 設定の組み合わせ | `test_config.py`（環境 × キー有無 × プロバイダ） |
| B-2 | 応答時間 | 実プロバイダが無いので**未測定**。台帳へ（プロバイダ支出上限の設定と同じ日に実測する） |
| B-2 | オフライン遷移 | frontend 側の観点（Phase 3 で扱った）。backend では接続エラー→再試行→締切で代替 |

## Self-review（計画作成時に実施）

- **Spec coverage**: 親計画 Phase 2 の「順序: 決定1 → 決定2 → Factory → エラー型 → 設定の不変化」は、
  書き直しでは「契約固定 → 型（errors / logging）→ 設定 → AI 境界 → 入出力・認証・制限 → 差し替え」に
  写像した。決定1（DB 削除）と決定2（memory://）は Task 7 の削除と Task 6 の `RateLimiter` で実現する。
  「この Phase で入れる検査」6項目はすべて Task 3（設定）・Task 7（worker guard）・Task 8（CI・smoke・gates）にある。
  「誤った仕様を固定したテストを検出するスキル」は**この計画に含めない**——`skill-creator` で
  作るプロジェクト固有スキルで、Phase 4 の棚卸しスキルと同じ工程（別 PR）。台帳に送る
- **Placeholder scan**: `TBD` / `TODO` / 「適宜」無し。`2026-09-xx` は実施日を入れる箇所
- **Type consistency**: `SafeError(code, *, cause, retryable)` / `RateLimitExceeded(*, retry_after_seconds, limit)` /
  `ConfigError(problems)` / `log_event(event, *, level)` / `RuntimeConfig(_env_file=None, **values)` /
  `Provider.complete(prompt) -> str` / `ConversionService(provider, *, max_retries, deadline_seconds, backoff_seconds)` /
  `build_require_api_key(allowed: tuple[bytes, ...])` / `RateLimiter(*, times, seconds, trusted_proxy_count)` /
  `create_app(config=None, *, provider_factory, environ, argv)` を全タスクで同じ名前・同じ引数で使っている
