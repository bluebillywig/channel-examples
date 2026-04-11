#!/bin/bash
#
# Blue Billywig Channel - Android Build Script
# ===========================================
#
# This script provides a stable, reproducible build process for the Android app.
# It handles all the complexity of building the hybrid web/native app correctly.
#
# Usage:
#   ./build-android.sh [debug|release] [install] [run]
#
# Examples:
#   ./build-android.sh debug install run    # Build debug APK, install, and launch
#   ./build-android.sh release              # Build release APK only
#   ./build-android.sh debug install        # Build debug APK and install
#

set -e  # Exit on error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Always use JDK 17 (override any environment JAVA_HOME)
JAVA_HOME="/Library/Java/JavaVirtualMachines/jdk-17.0.2.jdk/Contents/Home"
BUILD_TYPE="${1:-debug}"  # debug or release
INSTALL="${2:-}"          # install
RUN="${3:-}"              # run

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check Java
    if [[ ! -d "$JAVA_HOME" ]]; then
        log_error "JAVA_HOME not found at $JAVA_HOME"
        log_error "Please install JDK 17 or set JAVA_HOME environment variable"
        exit 1
    fi

    # Check Android SDK
    if [[ -z "$ANDROID_HOME" ]] && [[ -z "$ANDROID_SDK_ROOT" ]]; then
        log_warn "ANDROID_HOME or ANDROID_SDK_ROOT not set"
        log_warn "Assuming Android SDK is available via PATH"
    fi

    log_info "Prerequisites OK"
}

clean_build_artifacts() {
    log_info "Cleaning build artifacts..."

    cd "$SCRIPT_DIR"

    # Remove Android build caches
    rm -rf android/app/.cxx
    rm -rf android/app/build
    rm -rf android/.gradle
    rm -rf node_modules/.cache

    log_info "Build artifacts cleaned"
}

build_web_bundle() {
    log_info "Building web bundle (channel-native.js)..."

    cd "$SCRIPT_DIR/.."

    # Build the web bundle first to avoid Gradle/npm architecture issues
    npm run build:native

    if [[ ! -f "dist/channel-native.js" ]]; then
        log_error "Web bundle not found at dist/channel-native.js"
        exit 1
    fi

    log_info "Web bundle built successfully"
}

copy_web_bundle() {
    log_info "Copying web bundle to Android assets..."

    cd "$SCRIPT_DIR"

    # Create assets directory if it doesn't exist
    mkdir -p android/app/src/main/assets

    # Copy the web bundle
    cp -f ../dist/channel-native.js android/app/src/main/assets/
    cp -f ../dist/assets/* android/app/src/main/assets/assets/ 2>/dev/null || true

    log_info "Web bundle copied to assets"
}

build_android_apk() {
    log_info "Building Android APK ($BUILD_TYPE)..."

    cd "$SCRIPT_DIR"

    # Set Java home
    export JAVA_HOME="$JAVA_HOME"

    # Build the APK
    # We skip only the web bundle tasks since we built it manually
    # React Native's bundle tasks will still run to create index.android.bundle
    if [[ "$BUILD_TYPE" == "release" ]]; then
        ./android/gradlew -p android assembleRelease -x buildWebBundle
        APK_PATH="android/app/build/outputs/apk/release/app-release.apk"
    else
        ./android/gradlew -p android assembleDebug -x buildWebBundle
        APK_PATH="android/app/build/outputs/apk/debug/app-debug.apk"
    fi

    # Verify APK was created
    if [[ ! -f "$APK_PATH" ]]; then
        log_error "APK not found at $APK_PATH"
        exit 1
    fi

    # Get APK size
    APK_SIZE=$(du -h "$APK_PATH" | cut -f1)

    log_info "APK built successfully: $APK_PATH ($APK_SIZE)"
}

install_apk() {
    log_info "Installing APK on device/emulator..."

    cd "$SCRIPT_DIR"

    # Check if ADB is available
    if ! command -v adb &> /dev/null; then
        log_error "adb command not found. Make sure Android SDK platform-tools are in PATH"
        exit 1
    fi

    # Check if device is connected
    if ! adb devices | grep -q "device$"; then
        log_error "No Android device/emulator found"
        log_error "Please start an emulator or connect a device"
        exit 1
    fi

    # Uninstall existing app (ignore errors if not installed)
    adb uninstall com.bluebillywig.channel 2>/dev/null || true

    # Install APK
    if [[ "$BUILD_TYPE" == "release" ]]; then
        adb install -r android/app/build/outputs/apk/release/app-release.apk
    else
        adb install -r android/app/build/outputs/apk/debug/app-debug.apk
    fi

    log_info "APK installed successfully"
}

launch_app() {
    log_info "Launching app..."

    # Force stop any existing instance
    adb shell am force-stop com.bluebillywig.channel

    # Launch the app
    adb shell am start -n com.bluebillywig.channel/.MainActivity

    log_info "App launched"
}

# Main execution
main() {
    log_info "Blue Billywig Channel - Android Build"
    log_info "======================================"
    log_info ""
    log_info "Build type: $BUILD_TYPE"
    log_info "Java home: $JAVA_HOME"
    log_info ""

    check_prerequisites
    clean_build_artifacts
    build_web_bundle
    copy_web_bundle
    build_android_apk

    if [[ "$INSTALL" == "install" ]]; then
        install_apk

        if [[ "$RUN" == "run" ]]; then
            launch_app
        fi
    fi

    log_info ""
    log_info "Build completed successfully!"

    if [[ "$BUILD_TYPE" == "release" ]]; then
        log_info "Release APK: android/app/build/outputs/apk/release/app-release.apk"
    else
        log_info "Debug APK: android/app/build/outputs/apk/debug/app-debug.apk"
    fi
}

# Run main
main
