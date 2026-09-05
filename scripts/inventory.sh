#!/usr/bin/env bash
# 棚卸しの計測。数字を出すだけで判断しない。廃棄条件: 100 行を超えたら直さず消す（検査を作り始めている）。
# 使い方: scripts/inventory.sh   （リポジトリルートで。gh が認証済みであること）
set -uo pipefail
cd "$(dirname "$0")/.."
h() { printf '\n== %s\n' "$1"; }

h "文書の行数（核 / 決定 / 正本）"
wc -l AGENTS.md docs/adr/*.md README.md docs/spec/kotonoha-requirements.md docs/privacy-policy.md docs/support.md 2>/dev/null | tail -1
printf 'AGENTS.md %s 行（上限 120）／未卒業 ADR %s 本（上限 5）\n' "$(wc -l < AGENTS.md)" "$(ls docs/adr/ADR-*.md 2>/dev/null | wc -l | tr -d ' ')"
for f in docs/adr/ADR-*.md; do n=$(wc -l < "$f"); [ "$n" -gt 60 ] && printf '  60 行超: %s (%s)\n' "$f" "$n"; done

h "台帳 docs/ledger.md（未対応 / 対応済み / 却下）"
if [ -f docs/ledger.md ]; then
  printf '%s / %s / %s\n' "$(grep -c '^- \[ \]' docs/ledger.md)" "$(grep -c '^- \[x\]' docs/ledger.md)" "$(grep -c '^- \[-\]' docs/ledger.md)"
else echo "docs/ledger.md が無い"; fi

h "出力ゼロの仕組み（90 日で実行 0 回の workflow、痕跡の無いフック）"
since=$(date -u -d '90 days ago' +%F 2>/dev/null || date -u -v-90d +%F)
for w in .github/workflows/*.yml; do
  n=$(gh run list --workflow="$(basename "$w")" --created ">=$since" --limit 1 --json databaseId --jq 'length' 2>/dev/null || echo '?')
  [ "$n" = "0" ] && printf '  実行 0: %s\n' "$w"
done
marker=$(grep -m1 -o 'MARKER=.*' .claude/hooks/activity-value-check.sh | cut -d= -f2- | tr -d '"')
REPO="$(git rev-parse --show-toplevel 2>/dev/null)"
[ -n "$marker" ] && { eval "m=$marker"; [ -e "$m" ] && echo "  Stop フック: 痕跡あり ($m)" || echo "  Stop フック: 痕跡なし（廃棄条件: 発火ゼロで 1 か月）"; }

h "道具の実在（AGENTS.md に載る plugin:skill）"
for t in $(grep -o '`[a-z-]*:[a-z:_-]*`' AGENTS.md | tr -d '`' | sort -u); do
  p=${t%%:*}; s=${t#*:}; s=${s//:/\/}
  en=$(python3 -c "import json,sys;d=json.load(open('$HOME/.claude/settings.json')).get('enabledPlugins',{});print(any(k.startswith('$p@') and v for k,v in d.items()))")
  ex=$(find "$HOME/.claude/plugins/cache" \( -type d -path "*/$p/*/skills/*$s" -o -type f -path "*/$p/*/commands/$s.md" \) 2>/dev/null | head -1)
  printf '  %-45s 有効=%-5s 定義=%s\n' "$t" "$en" "${ex:+あり}${ex:-なし}"
done

h "実在しないパス参照（核・決定・README・台帳）"
grep -ho '`[A-Za-z0-9_./-]*/[A-Za-z0-9_./-]*`' AGENTS.md docs/adr/*.md README.md docs/ledger.md 2>/dev/null | tr -d '`' | sort -u \
  | while read -r p; do case "$p" in *'*'*|http*) continue;; esac; [ -e "$p" ] || printf '  無い: %s\n' "$p"; done

h "生成時コメントの残量（【】 / 🔵🟡🔴）"
for d in frontend/kotonoha_app/lib frontend/kotonoha_app/test frontend/kotonoha_app/integration_test backend/app; do
  printf '  %-45s 【】=%-5s 記号=%s\n' "$d" "$(grep -r '【' "$d" --include='*.dart' --include='*.py' | wc -l | tr -d ' ')" "$(grep -r '🔵\|🟡\|🔴' "$d" --include='*.dart' --include='*.py' | wc -l | tr -d ' ')"
done

h "使い捨て文書（docs/plans）と破棄条件"
for f in docs/plans/*.md; do grep -q '破棄' "$f" && printf '  条件あり: %s\n' "$f" || printf '  条件なし: %s\n' "$f"; done
