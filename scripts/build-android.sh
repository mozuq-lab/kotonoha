#!/bin/bash
# kotonoha Android build script
# NFR-401: Android 10+ support

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
FLUTTER_APP_DIR="$PROJECT_ROOT/frontend/kotonoha_app"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

echo_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check Flutter installation
check_flutter() {
    if ! command -v flutter &> /dev/null; then
        echo_error "Flutter is not installed or not in PATH"
        exit 1
    fi
    echo_info "Flutter version: $(flutter --version | head -n 1)"
}

# Check Java/JDK installation
check_java() {
    if ! command -v java &> /dev/null; then
        echo_error "Java is not installed or not in PATH"
        exit 1
    fi
    echo_info "Java version: $(java -version 2>&1 | head -n 1)"
}

# Clean build
clean_build() {
    echo_info "Cleaning previous build..."
    cd "$FLUTTER_APP_DIR"
    flutter clean
    cd android && ./gradlew clean 2>/dev/null || true
    cd "$FLUTTER_APP_DIR"
}

# Get dependencies
get_dependencies() {
    echo_info "Getting Flutter dependencies..."
    cd "$FLUTTER_APP_DIR"
    flutter pub get
}

# Build APK (debug)
build_apk_debug() {
    echo_info "Building debug APK..."
    cd "$FLUTTER_APP_DIR"
    flutter build apk --debug --flavor production
    echo_info "Debug APK built: build/app/outputs/flutter-apk/app-production-debug.apk"
}

# Build APK (release)
build_apk_release() {
    echo_info "Building release APK..."
    cd "$FLUTTER_APP_DIR"
    flutter build apk --release --flavor production --obfuscate --split-debug-info=build/debug-info
    echo_info "Release APK built: build/app/outputs/flutter-apk/app-production-release.apk"
}

# Build App Bundle (for Google Play)
build_bundle() {
    echo_info "Building App Bundle for Google Play..."
    cd "$FLUTTER_APP_DIR"
    flutter build appbundle --release --flavor production --obfuscate --split-debug-info=build/debug-info
    echo_info "App Bundle built: build/app/outputs/bundle/productionRelease/app-production-release.aab"
}

# Build internal test APK
build_internal() {
    echo_info "Building internal test APK..."
    cd "$FLUTTER_APP_DIR"
    flutter build apk --release --flavor internal
    echo_info "Internal APK built: build/app/outputs/flutter-apk/app-internal-release.apk"
}

# Show help
show_help() {
    echo "kotonoha Android Build Script"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  debug         Build debug APK"
    echo "  release       Build release APK"
    echo "  bundle        Build App Bundle for Google Play"
    echo "  internal      Build internal test APK"
    echo "  clean         Clean build artifacts"
    echo "  --help, -h    Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 debug              # Build debug APK"
    echo "  $0 release            # Build release APK with obfuscation"
    echo "  $0 bundle             # Build AAB for Google Play submission"
    echo "  $0 internal           # Build internal testing APK"
    echo ""
    echo "Prerequisites:"
    echo "  - Flutter SDK installed and in PATH"
    echo "  - Java JDK 11+ installed"
    echo "  - Android SDK installed"
    echo "  - For release builds: key.properties configured with signing info"
}

# Main
main() {
    echo "========================================"
    echo "kotonoha Android Build"
    echo "========================================"
    echo ""

    check_flutter
    check_java

    case "${1:-debug}" in
        debug)
            get_dependencies
            build_apk_debug
            ;;
        release)
            get_dependencies
            build_apk_release
            ;;
        bundle)
            get_dependencies
            build_bundle
            ;;
        internal)
            get_dependencies
            build_internal
            ;;
        clean)
            clean_build
            ;;
        --help|-h)
            show_help
            ;;
        *)
            echo_error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac

    echo ""
    echo_info "Build completed successfully!"
}

main "$@"
