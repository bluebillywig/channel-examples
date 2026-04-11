# Channel SDK Example App

Demo React Native app showing how to integrate the Blue Billywig Channel SDK.

## Purpose

Demonstrates:
- Installing and configuring the SDK
- Different integration patterns (fullscreen, embedded)
- Handling video playback events
- Navigation control via refs

## Prerequisites

- Node.js 18+
- React Native development environment
- Android: Android Studio, JDK 17
- iOS: Xcode, CocoaPods

## Installation

```bash
npm install
```

iOS only:
```bash
cd ios && pod install
```

## Running

```bash
# Start Metro
npm start

# Run on device/emulator
npm run android   # or: npm run ios
```

## Development Mode

When developing the SDK alongside the example:

**Terminal 1 - Bundle Server:**
```bash
cd /path/to/channel
npm run dev:native
```

**Terminal 2 - App:**
```bash
cd /path/to/channel/example
npm start
npm run android
```

**Port Forwarding (Android):**
```bash
adb reverse tcp:3333 tcp:3333
adb reverse tcp:8081 tcp:8081
```

## Demo Screens

### Full Screen Demo
Channel fills the screen. Simplest integration pattern.

### Embedded Demo
Channel with custom header/footer, programmatic navigation, dynamic channel loading.

## Project Structure

```
example/
├── App.tsx                 # Demo selection screen
├── screens/
│   ├── FullScreenDemo.tsx  # Full screen integration
│   └── EmbeddedDemo.tsx    # Embedded with custom UI
├── config.ts               # Bundle URL configuration
├── android/                # Android project
├── ios/                    # iOS project
└── metro.config.js         # Metro config
```

## SDK Usage

```tsx
import { BBChannel } from '@bluebillywig/react-native-channel';
import type { BBChannelRef, BBMediaInfo } from '@bluebillywig/react-native-channel';

function App() {
  const channelRef = useRef<BBChannelRef>(null);

  return (
    <View style={{ flex: 1 }}>
      <BBChannel
        ref={channelRef}
        channelUrl="https://demo.bbvms.com/ch/123.json"
        options={{ autoPlay: true, searchBar: true }}
        onMediaPlay={(media: BBMediaInfo) => {
          console.log('Playing:', media.title);
        }}
      />
    </View>
  );
}
```

## Build Commands

```bash
npm run build:android           # Debug APK
npm run build:android-release   # Release APK
npm run install:android         # Install APK
```

## Troubleshooting

### "Unable to load script"
```bash
adb reverse tcp:8081 tcp:8081
```

### "Failed to load channel bundle"
```bash
cd .. && npm run dev:native
adb reverse tcp:3333 tcp:3333
```

### "SDK location not found"
Create `android/local.properties`:
```
sdk.dir=/path/to/Android/sdk
```

## Documentation

- [SDK README](../sdk/README.md)
- [Architecture](../docs/architecture.md)
- [Integration Guide](../sdk/docs/INTEGRATION.md)
