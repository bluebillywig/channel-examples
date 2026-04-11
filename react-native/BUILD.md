# Building the Blue Billywig Channel Android App

This document describes the stable build process for the Android version of the Blue Billywig Channel app.

## Architecture Overview

The app is a hybrid React Native application that combines:

1. **React Native App** (`native/App.tsx`) - The main app shell
2. **WebView** - Loads the channel UI from a JavaScript bundle
3. **Native Player** - Blue Billywig native video player for fullscreen playback

### Build Flow

```
Source Code (TypeScript/React)
  ↓
React Native JavaScript Bundle (Metro/Gradle)
  ↓
Android APK (Gradle)
  ↓
Installed App
```

## Prerequisites

### Required Software

- **Node.js** 18+ with npm
- **Java Development Kit (JDK)** 17
  - Location: `/Library/Java/JavaVirtualMachines/jdk-17.0.2.jdk/Contents/Home`
  - Set `JAVA_HOME` environment variable to this path
- **Android SDK** with:
  - Platform Tools (adb)
  - Build Tools 36.0.0
  - Android SDK Platform 36 (Android 14)
  - NDK 27.1.12297006
- **Android Emulator** or physical device

### Environment Variables

```bash
export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-17.0.2.jdk/Contents/Home
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/emulator
```

## Quick Start

### Option 1: Use the Build Script (Recommended)

The easiest way to build is using the provided build script:

```bash
cd /path/to/channel/native

# Build debug APK, install, and run
./build-android.sh debug install run

# Build release APK only
./build-android.sh release

# Build debug APK and install (don't launch)
./build-android.sh debug install
```

### Option 2: Manual Build Steps

If you need more control, follow these manual steps:

#### 1. Clean Build Artifacts

```bash
cd /path/to/channel/native
rm -rf android/app/.cxx
rm -rf android/app/build
rm -rf android/.gradle
rm -rf node_modules/.cache
```

#### 2. Build the APK

```bash
# Set Java home
export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-17.0.2.jdk/Contents/Home

# Build debug APK
./android/gradlew -p android assembleDebug

# OR build release APK
./android/gradlew -p android assembleRelease
```

#### 3. Install on Device/Emulator

```bash
# Uninstall existing app
adb uninstall com.bluebillywig.channel || true

# Install debug APK
adb install -r android/app/build/outputs/apk/debug/app-debug.apk

# OR install release APK
adb install -r android/app/build/outputs/apk/release/app-release.apk
```

#### 4. Launch the App

```bash
adb shell am force-stop com.bluebillywig.channel
adb shell am start -n com.bluebillywig.channel/.MainActivity
```

## Build Outputs

After a successful build, you'll find the APK at:

- **Debug**: `native/android/app/build/outputs/apk/debug/app-debug.apk`
- **Release**: `native/android/app/build/outputs/apk/release/app-release.apk`

Typical APK sizes:
- Debug: ~75-80 MB
- Release: ~70-75 MB

## Troubleshooting

### Common Issues

#### 1. CMake/Ninja Build Errors

**Symptom**: `CMake Error: add_subdirectory given source... which is not an existing directory`

**Solution**: Clean the `.cxx` directory
```bash
rm -rf android/app/.cxx
```

#### 2. Gradle Build Fails

**Symptom**: `FAILURE: Build failed with an exception`

**Solution**: Clean all build artifacts
```bash
rm -rf android/app/.cxx android/app/build android/.gradle
./android/gradlew -p android clean
```

#### 3. Wrong Channel Content Displayed

**Symptom**: App shows different channel than configured in `App.tsx`

**Cause**: Stale React Native JavaScript bundle

**Solution**: Do a clean rebuild
```bash
./build-android.sh debug install run
```

#### 4. "Unable to load script" Error

**Symptom**: Red screen with "Unable to load script" message

**Cause**: JavaScript bundle not packaged correctly

**Solution**: Ensure Gradle's `createBundleReleaseJsAndAssets` task runs
```bash
# Rebuild without skipping bundle creation
./android/gradlew -p android assembleRelease
```

### Checking Logs

View Android logs in real-time:

```bash
adb logcat | grep -E "(bluebillywig|ReactNative|channel-native|Error)"
```

## Configuration

### Changing the Channel

To change which Blue Billywig channel the app loads:

1. Edit `native/App.tsx` line 31:
   ```typescript
   const channelJsonUrl = 'https://demo.bbvms.com/ch/938.json';
   ```

2. Rebuild the app:
   ```bash
   ./build-android.sh debug install run
   ```

### Build Variants

The project supports two build variants:

- **Debug**: Includes debugging symbols, not optimized
- **Release**: Optimized, minified, ready for distribution

## Automated Build Tasks

Gradle automatically runs these tasks during the build:

1. **`createBundleReleaseJsAndAssets`** - Bundles React Native JavaScript using Metro
2. **`copyWebBundle`** - Copies web assets to Android assets directory
3. **`assembleRelease`/`assembleDebug`** - Compiles Android code and creates APK

These tasks are defined in `native/android/app/build.gradle`.

## Development Workflow

For active development:

1. Make code changes in `native/` directory
2. Run the build script:
   ```bash
   ./build-android.sh debug install run
   ```
3. Test on emulator/device
4. Repeat

For faster iteration, you can use Expo's development server (hot reload), but for production builds always use the build script.

## CI/CD Integration

To integrate this build process into CI/CD:

```yaml
# Example GitHub Actions workflow
- name: Build Android Release
  run: |
    cd native
    export JAVA_HOME=/path/to/jdk-17
    ./build-android.sh release

- name: Upload APK
  uses: actions/upload-artifact@v3
  with:
    name: app-release.apk
    path: native/android/app/build/outputs/apk/release/app-release.apk
```

## Additional Resources

- [React Native Documentation](https://reactnative.dev/)
- [Expo Documentation](https://docs.expo.dev/)
- [Android Gradle Plugin Documentation](https://developer.android.com/build)
- [Blue Billywig Player SDK](https://bluebillywig.com/docs/)
