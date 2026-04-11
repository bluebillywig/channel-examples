import React, { useState, useCallback } from 'react';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { ChannelBrowser } from './screens/ChannelBrowser';
import { ChannelViewer } from './screens/ChannelViewer';
import { Settings } from './screens/Settings';
import type { Screen } from './types';

export default function App() {
  const [screen, setScreen] = useState<Screen>({ type: 'browser' });

  const openChannel = useCallback(
    (channelUrl: string, channelName: string, publicationHost: string) =>
      setScreen({ type: 'viewer', channelUrl, channelName, publicationHost }),
    [],
  );

  const openSettings = useCallback(() => setScreen({ type: 'settings' }), []);
  const goHome = useCallback(() => setScreen({ type: 'browser' }), []);

  return (
    <SafeAreaProvider>
      {screen.type === 'viewer' ? (
        <ChannelViewer
          channelUrl={screen.channelUrl}
          channelName={screen.channelName}
          onBack={goHome}
        />
      ) : screen.type === 'settings' ? (
        <Settings onBack={goHome} />
      ) : (
        <ChannelBrowser onSelectChannel={openChannel} onOpenSettings={openSettings} />
      )}
    </SafeAreaProvider>
  );
}
