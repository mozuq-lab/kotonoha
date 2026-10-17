#!/usr/bin/env bash
# TestFlight / App Store に上げる iOS の版（.ipa）を、この Mac で作る。アップロードはしない。
#
# 使い方: scripts/build-ios.sh <ビルド番号>
#   ビルド番号は App Store Connect に上げた最後の番号より大きい整数（CFBundleVersion になる）。
#   表示上の版（1.0.0 など）は pubspec.yaml の version の「+」より前。
#
# AI 変換の接続先とキーは frontend/kotonoha_app/ios-release.json（git に入らない）から渡す。
# 見本は ios-release.example.json。キーをコマンドラインに書かないので、シェルの履歴に残らない
# （ビルド中だけ、Flutter が内部で起こす flutter assemble の引数に base64 で現れる）。
# 署名は Xcode の自動署名（Team は project.pbxproj に設定済み）。
set -euo pipefail

APP_DIR="$(cd "$(dirname "$0")/../frontend/kotonoha_app" && pwd)"
CONFIG="$APP_DIR/ios-release.json"

fail() {
  printf '止めました: %s\n' "$1" >&2
  exit 1
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'
  exit 0
fi

BUILD_NUMBER="${1:-}"
[[ "$BUILD_NUMBER" =~ ^[1-9][0-9]*$ ]] ||
  fail "ビルド番号を 1 以上の整数で渡してください（例: scripts/build-ios.sh 2）"

[ -f "$CONFIG" ] ||
  fail "$CONFIG が無い。ios-release.example.json を写して、AI_API_KEY に端末キーを入れてください"

# JSON の文字列の値を読む（macOS の plutil は JSON も読める）。無い・読めない・文字列でないときは空
json_value() {
  plutil -extract "$1" raw -expect string -o - "$CONFIG" 2>/dev/null || true
}

API_BASE_URL="$(json_value API_BASE_URL)"
AI_API_KEY="$(json_value AI_API_KEY)"
url_lower="$(printf '%s' "$API_BASE_URL" | tr '[:upper:]' '[:lower:]')"

[ -n "$API_BASE_URL" ] || fail "API_BASE_URL が空か文字列でない、または $CONFIG を JSON として読めない"
case "$url_lower" in
  https://*) ;;
  *) fail "API_BASE_URL は https:// で始めてください（今: ${API_BASE_URL}）" ;;
esac
case "$url_lower" in
  *localhost* | *127.0.0.1*) fail "API_BASE_URL が手元のサーバーを指している（今: ${API_BASE_URL}）" ;;
esac
[ -n "$(printf '%s' "$AI_API_KEY" | tr -d '[:space:]')" ] || fail "AI_API_KEY が空か文字列でない"
unset AI_API_KEY

command -v fvm >/dev/null 2>&1 || fail "fvm が無い（README の「前提」）"

VERSION_NAME="$(sed -n 's/^version: *\([^+ ]*\).*/\1/p' "$APP_DIR/pubspec.yaml")"
COMMIT="$(git -C "$APP_DIR" describe --always --dirty 2>/dev/null || echo '不明')"
printf '版 %s（ビルド %s）、コミット %s、AI 変換の接続先 %s、キーは設定済み\n' \
  "$VERSION_NAME" "$BUILD_NUMBER" "$COMMIT" "$API_BASE_URL"

cd "$APP_DIR"
IPA_DIR="$APP_DIR/build/ios/ipa"
started="$(mktemp)"
trap 'rm -f "$started"' EXIT

# 書き出しに失敗したとき、前回の .ipa を今回の版と取り違えないよう、始めた時刻より新しいものだけを見る
fvm flutter build ipa --release --export-method app-store \
  --build-number "$BUILD_NUMBER" --dart-define-from-file "$CONFIG"

IPA="$(find "$IPA_DIR" -maxdepth 1 -name '*.ipa' -newer "$started" 2>/dev/null | head -n 1 || true)"
[ -n "$IPA" ] || fail "ビルドは終わったが、新しい .ipa が $IPA_DIR に無い（上のエラーを見てください）"

cat <<EOF

出来た .ipa: $IPA
（版 ${VERSION_NAME}、ビルド ${BUILD_NUMBER}）

アップロード（どちらか 1 つ）:
  - Transporter（Mac App Store の無料アプリ）: Apple ID でサインイン → .ipa をドラッグ → 「配信」
  - Xcode: open "$APP_DIR/build/ios/archive/Runner.xcarchive" → Organizer で
    「Distribute App」→「App Store Connect」→「Upload」
処理が終わると App Store Connect の TestFlight にビルド $BUILD_NUMBER が出る（数分〜数十分）。
次に上げるときは、ビルド番号を $((BUILD_NUMBER + 1)) 以上にする。
EOF
