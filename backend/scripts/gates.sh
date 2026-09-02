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
