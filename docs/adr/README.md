# 決定（ADR）の索引と扱い

`docs/adr/` にあるのは未卒業の ADR（検査を書けない決定と、書けていない決定。5 本まで）。索引は `AGENTS.md`、規則は ADR-010。
卒業した ADR の本文は `docs/archive/adr/` にあり、更新しない。書いた時点の記録なので実態とずれることがある。現在の姿はこの表の「検査」と「赤の見方」で見る。
本文を開く引き金は 4 つ: 却下案が再提案された／検査が落ちて理由が分からない／改訂・撤回する／同じ活動が 3 周した。
卒業の取り消し: 検査が決定を守っていなかった、または検査が消えたと分かったら、本文を `docs/adr/` へ `git mv` で戻し、先頭の卒業行を消す（枠が無ければ先に別の 1 本を卒業か撤回する）。
マージを止めるのはブランチ保護の必須チェック（python.yml・flutter.yml）。`scripts/adr-touch.sh`（着手前に手元で流す。CI には無い）はこの表も読む。

## 卒業済み（列順は `scripts/adr-touch.sh` が読むので変えない。6 列目は人向けで、卒業の PR が貼った赤の出力から写す）

| ADR | 決めたこと | 却下した案 | 関わる行為 | 検査 | 赤の見方（2026-09-12 実測） |
|---|---|---|---|---|---|
| ADR-001 | backend はステートレス。サーバー側にユーザー状態を持たない | DB で履歴・ログを保存 | 依存, 永続化, 公開ルート | 卒業（2026-09-06）: backend/scripts/gates.sh（DB ディレクトリと依存の不在） | `backend/requirements.txt` に `sqlalchemy` を足して `bash backend/scripts/gates.sh` → `::error::ADR-001/002`、exit 1 |
| ADR-003 | エラーは型（ErrorCode + SafeError）。自由文字列をログ・応答に載せない | 例外メッセージの秘匿関数 | 公開ルート, 外部送信先 | 卒業（2026-09-06）: backend/scripts/gates.sh（str(exc) 等 0 件）、canary 全シンク検査、mypy | `backend/app/errors.py` に `print("x")` を足して `bash backend/scripts/gates.sh` → `::error::ADR-003` |
| ADR-004 | 設定は不変。Application Factory。import 時に資源を作らない | モジュールレベルの app / client | 設定キー, 可変グローバル | 卒業（2026-09-06）: 起動 smoke（import 副作用ゼロ）、frozen 設定 | `backend/app/config.py` の `frozen=True` を `False` にして `pytest tests/test_config.py` → `test_config_is_frozen` FAILED |
| ADR-006 | レイヤ依存は import-linter で強制 | 規約だけで守る | 依存 | 卒業（2026-09-06）: lint-imports（CI） | `backend/app/errors.py` に `import app.main` を足して `lint-imports` → `Broken contracts: ADR-006 layers` |
| ADR-008 | 負債ゲートを機械では作らない。**同種の仕組みを作る前に必読** | 許可リスト方式のゲート（3 周・4,600 行で収束せず） | 依存, 永続化, 設定キー, 可変グローバル, 公開ルート, 外部送信先, 権限, 自作 | 卒業（2026-09-06）: 無し（却下の記録） | 無し（機械は持たない）。守るのは AGENTS.md 規律 8 の 1 行。workflow・フック・スクリプトの増減は棚卸しが数える |
