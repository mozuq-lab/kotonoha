#!/usr/bin/env bash
# 変更ファイルを AGENTS.md「負債を作る行為」7 項目に当て、関わる ADR の索引行を印字する。
# 止めない。例外を持たない。パターンを足さない（足すのは AGENTS.md の一覧が変わったときだけ）。
# 廃棄条件: 30 行を超えた／ADR の増減と無関係な変更 commit が 3 回／半年間、判断が変わった実例ゼロ。
# 使い方: git diff --name-only origin/<base>...HEAD | scripts/adr-touch.sh
set -euo pipefail
INDEX="${ADR_INDEX:-$(dirname "$0")/../AGENTS.md}"
acts=""
while IFS= read -r f; do
  case "$f" in
    */requirements*.txt|*/pubspec.yaml|*/pyproject.toml|*/Podfile|*/build.gradle.kts) acts="$acts 依存" ;;
    */lib/shared/models/*_adapter.dart|*/lib/core/utils/hive_init.dart) acts="$acts 永続化" ;;
    .env.example|*/.env.example|backend/app/config.py) acts="$acts 設定キー" ;;
    backend/app/main.py|backend/app/routes.py) acts="$acts 公開ルート 可変グローバル" ;;
    backend/app/ai/providers.py|*/lib/features/ai_conversion/data/*) acts="$acts 外部送信先" ;;
    */AndroidManifest.xml|*/Info.plist) acts="$acts 権限" ;;
  esac
done
[ -z "$acts" ] && exit 0
for a in $(printf '%s\n' $acts | sort -u); do
  grep -E '^\| ADR-[0-9]+ \|' "$INDEX" | awk -F'|' -v a="$a" '$5 ~ a { print }'
done | sort -u
