#!/usr/bin/env bash
# 変更ファイルを AGENTS.md 規律 8「負債を作る 8 行為」に当て、関わる ADR の索引行（核と docs/adr/README.md）を印字する。
# 保存・送信の経路に当たれば規律 9（独立監査）の行も印字する。止めない。例外を持たない。パターンを足さない（足すのは AGENTS.md の一覧が変わったときだけ）。
# 廃棄条件: 30 行を超えた／ADR の増減と無関係な変更 commit が 3 回／半年間、判断が変わった実例ゼロ。
# 使い方: git diff --name-only origin/<base>...HEAD | scripts/adr-touch.sh
set -euo pipefail
ROOT="$(dirname "$0")/.."
INDEX="${ADR_INDEX:-$ROOT/AGENTS.md $ROOT/docs/adr/README.md}"
acts=""
while IFS= read -r f; do
  case "$f" in
    */requirements*.txt|*/pubspec.yaml|*/pubspec.lock|*/pyproject.toml|*/Podfile|*/build.gradle.kts) acts="$acts 依存" ;;
    */lib/shared/models/*_adapter.dart|*/lib/core/utils/hive_init.dart|*/res/xml/backup_rules.xml|*/res/xml/data_extraction_rules.xml) acts="$acts 永続化" ;;
    .env.example|*/.env.example|backend/app/config.py) acts="$acts 設定キー" ;;
    backend/app/main.py|backend/app/routes.py) acts="$acts 公開ルート 可変グローバル" ;;
    backend/app/ai/providers.py|*/lib/features/ai_conversion/data/*) acts="$acts 外部送信先" ;;
    */AndroidManifest.xml|*/Info.plist) acts="$acts 権限" ;;
    .github/workflows/*) acts="$acts 依存 設定キー 自作" ;;
    .claude/hooks/*) acts="$acts 外部送信先 自作" ;;
    scripts/*|backend/scripts/*) acts="$acts 自作" ;;
  esac
done
[ -z "$acts" ] && exit 0
case " $acts " in *永続化*|*外部送信先*|*権限*) echo '| 規律 9 | 保存・送信の経路（永続化・外部送信先・権限）に当たる。独立監査の対象 | — | — | — | — |' ;; esac
for a in $(printf '%s\n' $acts | sort -u); do
  cat $INDEX | grep -E '^\| ADR-[0-9]+ \|' | awk -F'|' -v a="$a" '$5 ~ a { print (NF == 7 ? $0 " — |" : $0) }'
done | sort -u
