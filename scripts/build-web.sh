#!/bin/bash

# =============================================================================
# kotonoha Web Build Script
#
# This script builds Flutter Web application with various configurations.
# Supports multiple build modes and deployment targets.
#
# Usage:
#   ./scripts/build-web.sh [command] [options]
#
# Commands:
#   debug      - Build for local development
#   release    - Build optimized release version
#   profile    - Build for performance profiling
#   serve      - Build and serve locally
#   clean      - Clean build artifacts
#
# Options:
#   --renderer [html|canvaskit|auto]  - Select rendering engine (default: auto)
#   --base-href [path]                - Set base href for deployment
#   --pwa                             - Enable PWA features (default)
#   --no-pwa                          - Disable PWA features
#   --tree-shake-icons                - Remove unused icons (default)
#
# Examples:
#   ./scripts/build-web.sh debug
#   ./scripts/build-web.sh release --renderer canvaskit
#   ./scripts/build-web.sh serve
#   ./scripts/build-web.sh release --base-href /kotonoha/
# =============================================================================

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
COMMAND="${1:-debug}"
BASE_HREF="/"
PWA_ENABLED=true
TREE_SHAKE_ICONS=true
PORT=8080
WASM_BUILD=false

# Project paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
FLUTTER_APP_DIR="$PROJECT_ROOT/frontend/kotonoha_app"
BUILD_DIR="$FLUTTER_APP_DIR/build/web"

# Parse command line arguments
shift || true
while [[ $# -gt 0 ]]; do
    case $1 in
        --base-href)
            BASE_HREF="$2"
            shift 2
            ;;
        --pwa)
            PWA_ENABLED=true
            shift
            ;;
        --no-pwa)
            PWA_ENABLED=false
            shift
            ;;
        --tree-shake-icons)
            TREE_SHAKE_ICONS=true
            shift
            ;;
        --no-tree-shake-icons)
            TREE_SHAKE_ICONS=false
            shift
            ;;
        --port)
            PORT="$2"
            shift 2
            ;;
        --wasm)
            WASM_BUILD=true
            shift
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Helper functions
print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}\n"
}

print_success() {
    echo -e "${GREEN}$1${NC}"
}

print_warning() {
    echo -e "${YELLOW}$1${NC}"
}

print_error() {
    echo -e "${RED}$1${NC}"
}

check_flutter() {
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter is not installed or not in PATH"
        exit 1
    fi
}

build_common_flags() {
    local flags=""

    if [ "$TREE_SHAKE_ICONS" = true ]; then
        flags="$flags --tree-shake-icons"
    else
        flags="$flags --no-tree-shake-icons"
    fi

    if [ "$PWA_ENABLED" = true ]; then
        flags="$flags --pwa-strategy offline-first"
    else
        flags="$flags --pwa-strategy none"
    fi

    if [ "$BASE_HREF" != "/" ]; then
        flags="$flags --base-href $BASE_HREF"
    fi

    if [ "$WASM_BUILD" = true ]; then
        flags="$flags --wasm"
    fi

    echo "$flags"
}

# Build commands
build_debug() {
    print_header "Building Flutter Web (Debug)"

    cd "$FLUTTER_APP_DIR"

    local common_flags=$(build_common_flags)

    echo "Base Href: $BASE_HREF"
    echo "PWA: $PWA_ENABLED"
    echo "WASM: $WASM_BUILD"

    flutter build web \
        --debug \
        $common_flags \
        --source-maps \
        --dart-define=FLUTTER_WEB_DEBUG_MODE=true

    print_success "Debug build completed: $BUILD_DIR"
}

build_release() {
    print_header "Building Flutter Web (Release)"

    cd "$FLUTTER_APP_DIR"

    local common_flags=$(build_common_flags)

    echo "Base Href: $BASE_HREF"
    echo "PWA: $PWA_ENABLED"
    echo "WASM: $WASM_BUILD"

    flutter build web \
        --release \
        $common_flags \
        --dart-define=FLUTTER_WEB_DEBUG_MODE=false

    # Show build size
    if [ -d "$BUILD_DIR" ]; then
        local size=$(du -sh "$BUILD_DIR" | cut -f1)
        print_success "Release build completed: $BUILD_DIR ($size)"
    else
        print_success "Release build completed: $BUILD_DIR"
    fi
}

build_profile() {
    print_header "Building Flutter Web (Profile)"

    cd "$FLUTTER_APP_DIR"

    local common_flags=$(build_common_flags)

    flutter build web \
        --profile \
        $common_flags \
        --source-maps

    print_success "Profile build completed: $BUILD_DIR"
}

serve_web() {
    print_header "Building and Serving Flutter Web"

    # Build first if not exists or force rebuild
    if [ ! -d "$BUILD_DIR" ]; then
        build_debug
    fi

    cd "$FLUTTER_APP_DIR"

    print_success "Starting development server on http://localhost:$PORT"
    print_warning "Press Ctrl+C to stop"

    # Use Python's built-in HTTP server if available
    if command -v python3 &> /dev/null; then
        cd "$BUILD_DIR"
        python3 -m http.server $PORT
    elif command -v python &> /dev/null; then
        cd "$BUILD_DIR"
        python -m SimpleHTTPServer $PORT
    else
        # Fall back to Flutter's built-in server
        flutter run -d chrome --web-port $PORT
    fi
}

clean_build() {
    print_header "Cleaning Web Build"

    cd "$FLUTTER_APP_DIR"

    if [ -d "$BUILD_DIR" ]; then
        rm -rf "$BUILD_DIR"
        print_success "Removed: $BUILD_DIR"
    fi

    flutter clean

    print_success "Clean completed"
}

show_help() {
    cat << EOF
kotonoha Web Build Script

Usage:
  ./scripts/build-web.sh [command] [options]

Commands:
  debug      Build for local development (default)
  release    Build optimized release version
  profile    Build for performance profiling
  serve      Build and serve locally
  clean      Clean build artifacts
  help       Show this help message

Options:
  --base-href [path]                Set base href for deployment (default: /)
  --pwa                             Enable PWA features (default)
  --no-pwa                          Disable PWA features
  --tree-shake-icons                Remove unused icons (default)
  --no-tree-shake-icons             Keep all icons
  --port [number]                   Port for serve command (default: 8080)
  --wasm                            Build with WebAssembly (experimental)

Examples:
  ./scripts/build-web.sh debug
  ./scripts/build-web.sh release
  ./scripts/build-web.sh release --base-href /kotonoha/
  ./scripts/build-web.sh release --wasm
  ./scripts/build-web.sh serve --port 3000

Deployment:
  For Vercel:
    1. Build: ./scripts/build-web.sh release
    2. Deploy: vercel --prod (from frontend/kotonoha_app directory)

  For Netlify:
    1. Build: ./scripts/build-web.sh release
    2. Deploy: netlify deploy --prod --dir=build/web

EOF
}

# Main execution
check_flutter

case $COMMAND in
    debug)
        build_debug
        ;;
    release)
        build_release
        ;;
    profile)
        build_profile
        ;;
    serve)
        serve_web
        ;;
    clean)
        clean_build
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $COMMAND"
        echo "Use './scripts/build-web.sh help' for usage information"
        exit 1
        ;;
esac
