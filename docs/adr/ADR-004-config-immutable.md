# ADR-004: 設定は不変。Application Factory で組み立て、グローバルに置かない

状態: **Draft（レビュー待ち）** ／ 日付: 2026-08-29

## 背景と課題

現行はモジュールレベルの `settings` を各所が import し、`rate_limit.py` は
**import しただけで Limiter を構築**する（起動の欠陥形状 B-3「import しただけで
外部資源を作る」の実例）。この構造がもたらしたもの:

- テストが自分のモジュールを patch する強制（`patch("app.…")` が計100箇所。
  うち `ai_client.ai_client` 51 / `create_conversion_log` 36）
- 環境判定が3ファイルに独立して存在（`frozenset({"development","test"})` が
  `main.py:58` / `api/deps.py:41` の2箇所、`config.py:142` は `!= "production"` 判定——
  **集合の形が違うこと自体が split-brain** で、staging の扱いが場所によって変わる。台帳 P2）
- 設定の組み立てから実接続までの層が、単体テストで構造的に検証不能

## 検討した選択肢

1. 現状維持（モジュールレベルの可変 `settings`）
2. **`create_app(config)` の Application Factory + `RuntimeConfig(frozen=True)`**（採用）
3. DI コンテナの導入

## 決定

案2。import 時に資源を作らない。資源（AI プロバイダクライアント等）は lifespan で
生成する。secret は `SecretStr`、DSN は存在しない（ADR-001）。環境判定は
`RuntimeConfig` の1箇所に寄せる。

検査: `pytest-randomly`（グローバル状態への依存をテスト順序のシャッフルで露出）＋
`mypy --strict`＋負債ゲート「モジュールレベルの可変グローバル**・副作用**の追加」
（代入文だけでなく**モジュール直下の関数呼び出し**も対象——独立レビューの反例:
`register_provider()` のような呼び出しは、代入なしで import 時に資源を作れる）＋
**subprocess import smoke**: 外部境界を封じた環境で `python -c "import app.main"` が
外部アクセスゼロで完了することを完了条件にする。

## 決定理由（却下した案と理由）

- **案1を却下**: 自己 patch 51箇所のテスト構造と split-brain の根本原因。
  「モックは外部 SDK 境界にのみ置く」（verification-principles）が構造的に不可能になる
- **案3を却下**: 3ルートのサービスに依存追加は過剰。負債ゲートの思想
  （依存は負債の入口）にも反する

## 影響

- テストは `create_app(test_config)` で全設定を注入でき、自己 patch が不要になる
- 「記号入りパスワードで起動する」smoke が、設定組み立て〜起動の層を実際に通る
