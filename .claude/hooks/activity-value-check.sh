#!/usr/bin/env bash
# 同じ活動を反復しているときに、文脈を共有しない Claude へ価値判断を求める
#
# 【なぜ機械的な引き金か】: 「そろそろ枠を疑うべきだ」と気づけないことが問題の中身
# なので、引き金が作業中の Claude の判断に依存してはいけない（2026-08-30 の決定）。
#
# 【なぜ停止させないか】: 文脈を持たない評価者は価値を見落としうる。出力は
# **推奨**であって決定ではない。宛先は人間である。
#
# 【廃棄条件（先に決めてある）】
#   - 修正が2周目に入ったら削除する
#   - 発火実績ゼロのまま1ヶ月経ったら削除する
#   ADR-008 の失敗は「収束しないのに作り続けた」ことだった。
set -uo pipefail

# 【再帰の防止】: 評価用に起動する claude も同じフックを読むため、
# 環境変数で自分自身を止める。
[ -n "${KOTONOHA_ACTIVITY_CHECK:-}" ] && exit 0

THRESHOLD=3
REPO="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
MARKER="$REPO/.git/kotonoha-activity-check"

cd "$REPO" || exit 0
git rev-parse HEAD >/dev/null 2>&1 || exit 0

# 【bash 3.2 で動かす】: macOS 標準の bash には mapfile が無い。
# 直近 THRESHOLD 件の件名から Issue 番号を1つずつ取り出す。
# 「件名が Issue を参照している」ことを条件にする（本文まで見ると
# Co-Authored-By 等の無関係な # を拾う）。
target=""
count=0
while IFS= read -r subject; do
  issue="$(printf '%s' "$subject" | grep -oE '#[0-9]+' | head -1)"
  [ -z "$issue" ] && exit 0            # Issue を参照しない件名が混ざったら対象外
  if [ -z "$target" ]; then
    target="$issue"
  elif [ "$issue" != "$target" ]; then
    exit 0                             # 別の Issue が混ざったら対象外
  fi
  count=$((count + 1))
done < <(git log -n "$THRESHOLD" --format='%s' 2>/dev/null)

[ "$count" -lt "$THRESHOLD" ] && exit 0

# 同じ状態で繰り返し発火しない
head_sha="$(git rev-parse HEAD)"
[ -f "$MARKER" ] && [ "$(cat "$MARKER")" = "$head_sha" ] && exit 0
echo "$head_sha" > "$MARKER"

subjects="$(git log -n "$THRESHOLD" --format='- %s')"
files="$(git log -n "$THRESHOLD" --name-only --format='' | sort -u | grep -v '^$' | head -20)"

command -v claude >/dev/null 2>&1 || {
  cat <<MSG
[活動チェック] 直近 $THRESHOLD 件のコミットがすべて $target を参照しています。
この活動が完全に成功したら、利用者に何が変わりますか。
MSG
  exit 0
}

prompt="あなたはこの作業の文脈を共有していない評価者です。作業中の Claude が同じ活動を反復
しているため、価値判断を求められています。**続けるか止めるかを決める権限はありません。
推奨だけを述べてください。**

直近 ${THRESHOLD} 件のコミット（すべて ${target} を参照）:
${subjects}

変更されたファイル:
${files}

問い: **この活動が完全に成功したら、利用者に何が変わりますか。**
このリポジトリの利用者は発話困難な方で、目的は「できるだけ少ない操作で、自分の言いたいことを
伝えられる」ことです。

次の形式で、合計5行以内で答えてください。ファイルを読みに行かず、上の情報だけで答えること。

利用者への変化: （具体的に。「何も変わらない」ならそう書く）
推奨: 続ける / やり方を変える / 止めて別のことをする
理由: （1行）

判断材料が足りない場合は、推奨を書かずに「判断材料が足りない: 何が要るか」と書いてください。"

# 【timeout を使わない理由】: macOS には coreutils の timeout が無い
# （gtimeout も未導入）。perl の alarm で代替する。
# ターン終了をいつまでも塞がないよう、上限は 90 秒。
result="$(KOTONOHA_ACTIVITY_CHECK=1 perl -e 'alarm 90; exec @ARGV' \
  claude -p "$prompt" 2>/dev/null)" || result=""

if [ -z "$result" ]; then
  echo "[活動チェック] 直近 $THRESHOLD 件が $target を参照。評価者を起動できませんでした。"
  echo "この活動が完全に成功したら、利用者に何が変わりますか。"
  exit 0
fi

cat <<MSG
──────────── 活動チェック（自動） ────────────
直近 $THRESHOLD 件のコミットがすべて $target を参照しています。
文脈を共有しない評価者の見立て:

$result

※ これは推奨であって決定ではありません。判断は人が行ってください。
──────────────────────────────────────────
MSG
