#!/bin/bash
#
# TASK-0095: 実機テスト実行スクリプト
#
# Usage: ./scripts/run_device_tests.sh [OPTIONS]
#
# Options:
#   -d, --device DEVICE_ID   Target device ID (required)
#   -t, --test TEST_FILE     Specific test file to run (optional)
#   -a, --all                Run all device tests
#   -h, --help               Show this help message
#
# Examples:
#   ./scripts/run_device_tests.sh -d 00008110-XXXX -a
#   ./scripts/run_device_tests.sh -d ABCD1234 -t device_basic_test.dart
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(dirname "$SCRIPT_DIR")"
DEVICE_TEST_DIR="$APP_DIR/integration_test/device_test"

# Default values
DEVICE_ID=""
TEST_FILE=""
RUN_ALL=false

# Print usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -d, --device DEVICE_ID   Target device ID (required)"
    echo "  -t, --test TEST_FILE     Specific test file to run (optional)"
    echo "  -a, --all                Run all device tests"
    echo "  -h, --help               Show this help message"
    echo ""
    echo "Available test files:"
    echo "  device_basic_test.dart   - Basic functionality tests (RT-001~RT-016)"
    echo "  orientation_test.dart    - Screen orientation tests (RT-101~RT-103)"
    echo "  tablet_layout_test.dart  - Tablet layout tests (RT-104~RT-107)"
    echo "  tts_device_test.dart     - TTS device tests (RT-201~RT-206, RT-301~RT-307)"
    echo ""
    echo "Examples:"
    echo "  $0 -d 00008110-XXXX -a"
    echo "  $0 -d ABCD1234 -t device_basic_test.dart"
    exit 1
}

# Print colored message
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--device)
            DEVICE_ID="$2"
            shift 2
            ;;
        -t|--test)
            TEST_FILE="$2"
            shift 2
            ;;
        -a|--all)
            RUN_ALL=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Check if device ID is provided
if [ -z "$DEVICE_ID" ]; then
    print_error "Device ID is required. Use -d or --device to specify."
    echo ""
    echo "Available devices:"
    flutter devices
    echo ""
    usage
fi

# Change to app directory
cd "$APP_DIR"

# Print header
echo "========================================"
echo "  TASK-0095: Device Test Runner"
echo "========================================"
echo ""
print_info "Device ID: $DEVICE_ID"
print_info "Test directory: $DEVICE_TEST_DIR"
echo ""

# Check if device is connected
print_info "Checking device connection..."
if ! flutter devices | grep -q "$DEVICE_ID"; then
    print_error "Device $DEVICE_ID not found."
    echo ""
    echo "Available devices:"
    flutter devices
    exit 1
fi

print_success "Device found!"
echo ""

# Run tests
run_test() {
    local test_file=$1
    local test_name=$(basename "$test_file" .dart)

    echo "----------------------------------------"
    print_info "Running: $test_name"
    echo "----------------------------------------"

    if flutter test "integration_test/device_test/$test_file" -d "$DEVICE_ID"; then
        print_success "$test_name completed successfully!"
    else
        print_error "$test_name failed!"
        return 1
    fi

    echo ""
}

# Run all tests or specific test
if [ "$RUN_ALL" = true ]; then
    print_info "Running all device tests..."
    echo ""

    FAILED=0

    for test_file in device_basic_test.dart orientation_test.dart tablet_layout_test.dart tts_device_test.dart; do
        if ! run_test "$test_file"; then
            ((FAILED++))
        fi
    done

    echo "========================================"
    if [ $FAILED -eq 0 ]; then
        print_success "All tests completed successfully!"
    else
        print_error "$FAILED test file(s) failed."
        exit 1
    fi

elif [ -n "$TEST_FILE" ]; then
    if [ ! -f "$DEVICE_TEST_DIR/$TEST_FILE" ]; then
        print_error "Test file not found: $TEST_FILE"
        echo ""
        echo "Available test files:"
        ls -1 "$DEVICE_TEST_DIR"/*.dart 2>/dev/null | xargs -n1 basename
        exit 1
    fi

    run_test "$TEST_FILE"

else
    print_error "Please specify -a (all) or -t (specific test file)"
    usage
fi

echo ""
print_info "Test report template: docs/implements/kotonoha/TASK-0095/test-report-template.md"
print_info "Screenshots: build/app/outputs/integration_test_screenshots/"
echo ""
