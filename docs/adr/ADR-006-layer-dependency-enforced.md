# ADR-006: レイヤ依存は import-linter で強制する

状態: **承認済み（2026-08-29、署名: mozuq。2系統レビュー反映済み）** ／ 日付: 2026-08-29

## 背景と課題

`core/exceptions.py` → `app.db.session` / `app.models` → `app.core.config` という
**core → db → core の循環**を、8周のレビュー・418テスト・7体のサブエージェント分析の
誰も検出しなかった。構造違反は個々の差分に映らないため、差分レビューでは
**原理的に**見つからない。人と AI のどちらのレビューにも期待できないことが実証された。

## 検討した選択肢

1. 規約文書（AGENTS.md 等）に依存方向を書く
2. レビュー観点チェックリストに加える
3. **import-linter の contract として書き、CI で強制する**（採用）

## 決定

案3。新 backend（Phase 2）の層を contract にする:

```
main    → routes
routes  → schemas / auth / ratelimit / ai / errors / config / logging
schemas → ai（PolitenessLevel の語彙を1つにするため）
auth | ratelimit | ai → config / errors / logging（互いには依存しない）
config  → errors / logging（設定失敗を ConfigError で表し、削除済みキーの警告を出すため）
logging → errors 以下
errors  → （依存なし）
```

CI で `import-linter` 緑を必須にする。frontend 側は Dart analyzer ルール
（トップレベル可変変数の禁止ほか、Phase 3）で対応する。

## 決定理由（却下した案と理由）

- **案1・2を却下**: 文書とレビュー観点が構造違反を見逃すことは、この循環が
  **約40週間**（2025-11-22 の導入以来。`git log -S` で実測）誰にも見つからなかったことで
  実証済み。構造は「差分の外を見る機械の層」
  （レビュー層2）でしか守れない

## 影響

- 「core から db を import」のような変更は CI で機械的に落ちる。議論にならない
- 層をまたぐ新しい依存が必要になったら、contract の変更が差分に現れ、
  そこが ADR を書く契機になる

## 改訂（2026-09-02、Phase 2 実装時）

草案は `config → 依存なし` としていたが、pydantic の ValidationError が入力値（秘密）を
文字列に含むため、config は失敗を型（`ConfigError`）に載せ替えて外へ出す必要があり、
errors への依存が要る。語彙を2つ持たないために `config → errors` を許した。
`schemas → ai` も同じ理由（丁寧さレベルの列挙を1つにする）。契約は `backend/pyproject.toml`
の `[tool.importlinter]` が正本で、CI の `lint-imports` が強制する。
