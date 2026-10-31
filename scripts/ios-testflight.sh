#!/bin/bash
# iOS の版を作って TestFlight へ送る。手元の Mac で動かす。
#
# 使い方:
#   scripts/ios-testflight.sh
#
# 前もって、リポジトリの外に 2 つのファイルを置く（どちらも chmod 600）。秘密をコマンドラインに
# 書かないため、値はファイルで渡す。置き場所は環境変数で変えられる。
#
#   KOTONOHA_RELEASE_DEFINES（既定: ~/.config/kotonoha/ios-release.json）— アプリに埋め込む値
#     {"API_BASE_URL": "https://kotonoha.mozuq-lab.com", "AI_API_KEY": "<backend の API_KEYS の 1 つ>"}
#
#   KOTONOHA_ASC_ENV（既定: ~/.config/kotonoha/asc.env）— App Store Connect API キー（役割は Admin）
#     ASC_KEY_ID=XXXXXXXXXX
#     ASC_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
#     ASC_KEY_PATH=${HOME}/.appstoreconnect/AuthKey_XXXXXXXXXX.p8
#
# 署名は自動署名で、証明書とプロファイルは API キーで取る（Xcode へのログインは要らない）。手元に
# Apple Distribution の証明書が無ければ Apple が管理する証明書で署名する。これを使えるのは Admin の
# キーで、App Manager のキーでは書き出しで断られることがある。
# ビルド番号は、送るときに Xcode が App Store Connect の最新より大きい値にする（ios/ExportOptions.plist）。
set -euo pipefail

DEFINES="${KOTONOHA_RELEASE_DEFINES:-${HOME}/.config/kotonoha/ios-release.json}"
ASC_ENV="${KOTONOHA_ASC_ENV:-${HOME}/.config/kotonoha/asc.env}"

die() {
    echo "エラー: $*" >&2
    exit 1
}

[ -f "${DEFINES}" ] || die "${DEFINES} がありません（先頭の説明を参照）"
[ -f "${ASC_ENV}" ] || die "${ASC_ENV} がありません（先頭の説明を参照）"

# plutil は JSON も読める。-expect string が無いと、辞書ならキー名、配列なら要素数を返す
API_BASE_URL="$(plutil -extract API_BASE_URL raw -expect string -o - "${DEFINES}" 2>/dev/null)" ||
    die "${DEFINES} に API_BASE_URL（文字列）がありません"
AI_API_KEY="$(plutil -extract AI_API_KEY raw -expect string -o - "${DEFINES}" 2>/dev/null)" ||
    die "${DEFINES} に AI_API_KEY（文字列）がありません"
case "${API_BASE_URL}" in
    https://*) ;;
    *) die "API_BASE_URL は https:// で始めてください（今: ${API_BASE_URL}）" ;;
esac
[ -n "${AI_API_KEY}" ] || die "AI_API_KEY が空です"

# shellcheck source=/dev/null
source "${ASC_ENV}"
[ -n "${ASC_KEY_ID:-}" ] || die "${ASC_ENV} に ASC_KEY_ID がありません"
[ -n "${ASC_ISSUER_ID:-}" ] || die "${ASC_ENV} に ASC_ISSUER_ID がありません"
[ -f "${ASC_KEY_PATH:-}" ] || die "ASC_KEY_PATH の .p8 がありません（今: ${ASC_KEY_PATH:-未設定}）"

# 送ってから AI 変換が使えないと分かるのを避けるため、埋め込む値を本番の backend で先に試す。
# キーが通れば、空の本文は 422（変換はしない）。通らなければ 401。
echo ">>> 接続先とキーを確かめる: ${API_BASE_URL}"
health="$(curl -s -o /dev/null -w '%{http_code}' --max-time 15 "${API_BASE_URL}/api/v1/health")" || true
[ "${health}" = 200 ] || die "${API_BASE_URL}/api/v1/health が 200 を返しません（${health}）"
# キーはプロセスの引数に出さず、標準入力からヘッダーとして渡す
auth="$(printf 'X-API-Key: %s\n' "${AI_API_KEY}" |
    curl -s -o /dev/null -w '%{http_code}' --max-time 15 -X POST \
        -H @- -H 'Content-Type: application/json' -d '{}' \
        "${API_BASE_URL}/api/v1/ai/convert")" || true
[ "${auth}" = 422 ] || die "AI_API_KEY が backend に受け入れられません（POST /api/v1/ai/convert が ${auth}。422 なら正しい）"

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../frontend/kotonoha_app" && pwd)"
cd "${APP_DIR}"

OUT="build/ios/testflight"
rm -rf "${OUT}"
AUTH=(
    -allowProvisioningUpdates
    -authenticationKeyPath "${ASC_KEY_PATH}"
    -authenticationKeyID "${ASC_KEY_ID}"
    -authenticationKeyIssuerID "${ASC_ISSUER_ID}"
)

# --config-only は埋め込む値を ios/Flutter/Generated.xcconfig（git の対象外）に書く。
# 終わったら（失敗しても）値の無い設定に書き戻す。キーはアプリに埋め込まれるので、ビルドの途中の
# 引数（flutter assemble）、build/ios/testflight のアーカイブ、DerivedData には残る。
restore_config() {
    fvm flutter build ios --release --config-only >/dev/null 2>&1 ||
        echo "警告: ios/Flutter/Generated.xcconfig を書き戻せませんでした。キーが残っています" >&2
}
trap restore_config EXIT

echo ">>> Flutter の設定を作る"
fvm flutter build ios --release --config-only --dart-define-from-file="${DEFINES}"

echo ">>> アーカイブを作る"
xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release \
    -destination generic/platform=iOS -archivePath "${OUT}/Runner.xcarchive" \
    "${AUTH[@]}" archive

echo ">>> 署名して App Store Connect へ送る"
xcodebuild -exportArchive -archivePath "${OUT}/Runner.xcarchive" \
    -exportOptionsPlist ios/ExportOptions.plist -exportPath "${OUT}/export" \
    "${AUTH[@]}"

echo "送りました。App Store Connect の TestFlight で処理が終わると（数分〜数十分）、テスターに配れます"
