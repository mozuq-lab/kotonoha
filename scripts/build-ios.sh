#!/bin/bash
# kotonoha iOS Build Script
# TASK-0091: iOSビルド設定
#
# Usage:
#   ./scripts/build-ios.sh [debug|release|profile] [--archive] [--testflight]
#
# Examples:
#   ./scripts/build-ios.sh debug           # デバッグビルド
#   ./scripts/build-ios.sh release         # リリースビルド（IPA生成）
#   ./scripts/build-ios.sh --archive       # アーカイブ生成（App Store用）
#   ./scripts/build-ios.sh --testflight    # TestFlight配布用

set -e

# プロジェクトルートに移動
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT/frontend/kotonoha_app"

# デフォルト設定
BUILD_MODE="release"
ARCHIVE=false
TESTFLIGHT=false

# 引数解析
for arg in "$@"; do
    case $arg in
        debug|release|profile)
            BUILD_MODE=$arg
            ;;
        --archive)
            ARCHIVE=true
            ;;
        --testflight)
            TESTFLIGHT=true
            ARCHIVE=true
            ;;
        --help|-h)
            echo "Usage: $0 [debug|release|profile] [--archive] [--testflight]"
            echo ""
            echo "Options:"
            echo "  debug       デバッグビルド"
            echo "  release     リリースビルド（デフォルト）"
            echo "  profile     プロファイルビルド"
            echo "  --archive   Xcodeアーカイブを生成"
            echo "  --testflight TestFlight配布用ビルド"
            exit 0
            ;;
    esac
done

echo "================================================"
echo "kotonoha iOS Build"
echo "================================================"
echo "Mode: $BUILD_MODE"
echo "Archive: $ARCHIVE"
echo "TestFlight: $TESTFLIGHT"
echo "================================================"

# Flutter依存関係の更新
echo ">>> Updating Flutter dependencies..."
flutter pub get

# iOSプロジェクトのクリーン（オプション）
if [ "$BUILD_MODE" = "release" ]; then
    echo ">>> Cleaning iOS build..."
    flutter clean
    flutter pub get
fi

# CocoaPodsの更新
echo ">>> Installing CocoaPods dependencies..."
cd ios
pod install --repo-update
cd ..

if [ "$ARCHIVE" = true ]; then
    echo ">>> Building iOS Archive..."

    # Xcodeアーカイブのビルド
    flutter build ipa --release \
        --export-options-plist=ios/ExportOptions.plist \
        --obfuscate \
        --split-debug-info=build/ios/symbols

    # ビルド成果物の確認
    IPA_PATH="build/ios/ipa/*.ipa"
    if ls $IPA_PATH 1> /dev/null 2>&1; then
        echo "================================================"
        echo "SUCCESS: IPA file created!"
        echo "Location: $IPA_PATH"
        echo "================================================"

        if [ "$TESTFLIGHT" = true ]; then
            echo ""
            echo "To upload to TestFlight, run:"
            echo "  xcrun altool --upload-app -f $IPA_PATH -t ios -u \$APPLE_ID -p \$APP_SPECIFIC_PASSWORD"
            echo ""
            echo "Or use Transporter app from Mac App Store."
        fi
    else
        echo "ERROR: IPA file not found!"
        exit 1
    fi
else
    echo ">>> Building iOS app for $BUILD_MODE..."

    case $BUILD_MODE in
        debug)
            flutter build ios --debug --no-codesign
            ;;
        release)
            flutter build ios --release
            ;;
        profile)
            flutter build ios --profile
            ;;
    esac

    echo "================================================"
    echo "SUCCESS: iOS build completed!"
    echo "================================================"
fi

echo ""
echo "Build completed at: $(date)"
