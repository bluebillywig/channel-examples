import React, { useState, useCallback, useRef, useEffect } from 'react';
import { StyleSheet, View, Text, TouchableOpacity, Linking } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import Slider from '@react-native-community/slider';
import {
  BBChannelWithPlayer,
  type BBChannelWithPlayerRef,
  type BBMediaInfo,
  type BBErrorEvent,
  type BBNavigationEvent,
  type BBPlayerEvent,
  type BBTimeUpdateEvent,
  type BBClipLoadedEvent,
  type BBAdEvent,
  type BBSearchEvent,
  type BBAnalyticsEvent,
} from '@bluebillywig/react-native-channel';
import { BBCastButton, BBCastMiniControls } from '@bluebillywig/react-native-bb-player';
import { Header } from '../components/Header';
import { SettingsPanel } from '../components/SettingsPanel';
import { EventInspector } from '../components/EventInspector';
import { COLORS, SPACING, FONT, RADIUS } from '../theme';
import { getBundleUrl } from '../config';
import type { ChannelSettings, EventEntry } from '../types';
import { DEFAULT_SETTINGS } from '../types';
import { usePersistedState } from '../hooks/usePersistedState';

// Diagnostic: check native player availability at module level (same as BBChannelWithPlayer.tsx)
let _bbPlayerAvailable = false;
let _bbPlayerVersion = 'n/a';
try {
  // eslint-disable-next-line @typescript-eslint/no-require-imports
  const bbPlayer = require('@bluebillywig/react-native-bb-player');
  _bbPlayerAvailable = bbPlayer.BBPlayerView !== null && bbPlayer.BBPlayerView !== undefined;
  // eslint-disable-next-line @typescript-eslint/no-require-imports
  const pkg = require('@bluebillywig/react-native-bb-player/package.json');
  _bbPlayerVersion = pkg.version ?? 'unknown';
} catch {
  // package not installed
}

interface Props {
  channelUrl: string;
  channelName: string;
  onBack: () => void;
}

let eventIdCounter = 0;

function ts(): string {
  const d = new Date();
  return (
    d.getHours().toString().padStart(2, '0') +
    ':' +
    d.getMinutes().toString().padStart(2, '0') +
    ':' +
    d.getSeconds().toString().padStart(2, '0') +
    '.' +
    d.getMilliseconds().toString().padStart(3, '0')
  );
}

type Category = EventEntry['category'];

function categorize(type: string): Category {
  if (type === 'error' || type.includes('Error')) return 'error';
  if (type.startsWith('analytics')) return 'analytics';
  if (type.includes('nav') || type.includes('Nav') || type === 'canGoBack') return 'navigation';
  if (
    type.includes('player') ||
    type.includes('Player') ||
    type.includes('media') ||
    type.includes('Media') ||
    type.includes('clip') ||
    type.includes('Clip') ||
    type.includes('ad') ||
    type === 'timeUpdate'
  ) {
    return 'player';
  }
  return 'lifecycle';
}

export function ChannelViewer({ channelUrl, channelName, onBack }: Props) {
  const channelRef = useRef<BBChannelWithPlayerRef>(null);
  const [showSettings, setShowSettings] = useState(false);
  const [settings, setSettings] = usePersistedState<ChannelSettings>('viewer_settings', DEFAULT_SETTINGS);
  const [events, setEvents] = useState<EventEntry[]>([]);

  const bundleUrl = getBundleUrl(settings.environment, settings.customBundleUrl);

  // Embed sizing
  const [embedWidth, setEmbedWidth] = usePersistedState('embed_width', 100); // percentage
  const [embedHeight, setEmbedHeight] = usePersistedState('embed_height', 50); // percentage
  const [embedReloadKey, setEmbedReloadKey] = useState(0);
  const [embedAreaSize, setEmbedAreaSize] = useState({ w: 0, h: 0 });
  const reloadTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  const scheduleReload = useCallback(() => {
    if (reloadTimer.current) clearTimeout(reloadTimer.current);
    reloadTimer.current = setTimeout(() => setEmbedReloadKey((k) => k + 1), 400);
  }, []);

  // Cleanup reload timer on unmount
  useEffect(() => {
    return () => {
      if (reloadTimer.current) clearTimeout(reloadTimer.current);
    };
  }, []);

  const lastLoggedSecond = useRef(-1);

  const log = useCallback((type: string, summary: string, detail?: string) => {
    const entry: EventEntry = {
      id: ++eventIdCounter,
      time: ts(),
      type,
      category: categorize(type),
      summary,
      detail,
    };
    setEvents((prev) => [entry, ...prev].slice(0, 200));
  }, []);

  const clearEvents = useCallback(() => setEvents([]), []);

  // Event handlers
  const onReady = useCallback(() => log('ready', 'Channel loaded'), [log]);
  const onError = useCallback(
    (e: BBErrorEvent) => log('error', `[${e.code}] ${e.message}`, JSON.stringify(e)),
    [log],
  );
  const onMediaPlay = useCallback(
    (m: BBMediaInfo) => log('mediaPlay', m.title || m.jsonUrl, JSON.stringify(m)),
    [log],
  );
  const onMediaPause = useCallback(
    (m: BBMediaInfo) => log('mediaPause', m.title || m.jsonUrl),
    [log],
  );
  const onMediaEnd = useCallback(
    (m: BBMediaInfo) => log('mediaEnd', m.title || m.jsonUrl),
    [log],
  );
  const onNavigate = useCallback(
    (e: BBNavigationEvent) => log('navigate', e.pageType, JSON.stringify(e)),
    [log],
  );
  const onCanGoBackChange = useCallback(
    (v: boolean) => log('canGoBack', String(v)),
    [log],
  );
  const onSearch = useCallback(
    (e: BBSearchEvent) => log('search', JSON.stringify(e)),
    [log],
  );
  const onPlayerEvent = useCallback(
    (e: BBPlayerEvent) => {
      if (e.type === 'timeupdate') return; // too noisy
      log('playerEvent', e.type, JSON.stringify(e));
    },
    [log],
  );
  const onTimeUpdate = useCallback(
    (e: BBTimeUpdateEvent) => {
      const sec = Math.floor(e.currentTime);
      if (sec % 10 === 0 && sec !== lastLoggedSecond.current) {
        lastLoggedSecond.current = sec;
        log('timeUpdate', `${sec}s / ${Math.floor(e.duration)}s`);
      }
    },
    [log],
  );
  const onClipLoaded = useCallback(
    (e: BBClipLoadedEvent) => log('clipLoaded', JSON.stringify(e).slice(0, 80), JSON.stringify(e)),
    [log],
  );
  const onAdStart = useCallback(
    (e: BBAdEvent) => log('adStart', JSON.stringify(e)),
    [log],
  );
  const onAdEnd = useCallback(
    (e: BBAdEvent) => log('adEnd', JSON.stringify(e)),
    [log],
  );
  const onAnalyticsEvent = useCallback(
    (e: BBAnalyticsEvent) => {
      const importantCodes = ['st', 'fn', 'xst', 'xit', 'xcl', 'pa', 'rs', 'se', 'pg'];
      if (importantCodes.includes(e.eventCode)) {
        log(`analytics:${e.eventCode}`, JSON.stringify(e.properties).slice(0, 80), JSON.stringify(e));
      }
    },
    [log],
  );
  const onPlayersChange = useCallback(
    (p: { id: string; isActive: boolean }[]) => log('playersChange', `${p.length} players`),
    [log],
  );
  const onActivePlayerChange = useCallback(
    (id: string | null) => log('activePlayerChange', id || 'none'),
    [log],
  );
  const onNativePlayerStateChange = useCallback(
    (state: string) => log('nativePlayerState', state),
    [log],
  );
  const onNativePlayerError = useCallback(
    (error: string) => log('nativePlayerError', error),
    [log],
  );
  const onFirstPlayerMedia = useCallback(
    (m: BBMediaInfo) => log('firstPlayerMedia', m.title || m.jsonUrl, JSON.stringify(m)),
    [log],
  );

  return (
    <SafeAreaView style={styles.container} edges={[]}>
      <Header
        title={channelName}
        subtitle={`${_bbPlayerAvailable ? '✓NATIVE' : '✗NATIVE'} bb-player@${_bbPlayerVersion} | ${channelUrl}`}
        onBack={onBack}
        right={
          <>
            <TouchableOpacity
              onPress={() => Linking.openURL(channelUrl.replace(/\.json$/, '.html'))}
              hitSlop={8}
            >
              <Text style={styles.webLink}>WEB</Text>
            </TouchableOpacity>
            <BBCastButton style={styles.castButton} tintColor="#ffffff" />
            <SettingsToggle active={showSettings} onPress={() => setShowSettings(!showSettings)} />
          </>
        }
      />

      {showSettings && <SettingsPanel settings={settings} onChange={setSettings} />}

      {settings.displayMode === 'embed' ? (
        <View style={styles.embedOuter}>
          <View style={styles.embedControls}>
            <View style={styles.sliderRow}>
              <Text style={styles.sliderLabel}>W {Math.round(embedWidth)}%</Text>
              <Slider
                style={styles.slider}
                minimumValue={20}
                maximumValue={100}
                step={1}
                value={embedWidth}
                onValueChange={setEmbedWidth}
                onSlidingComplete={scheduleReload}
                minimumTrackTintColor={COLORS.accent}
                maximumTrackTintColor={COLORS.border}
                thumbTintColor={COLORS.accent}
              />
            </View>
            <View style={styles.sliderRow}>
              <Text style={styles.sliderLabel}>H {Math.round(embedHeight)}%</Text>
              <Slider
                style={styles.slider}
                minimumValue={10}
                maximumValue={100}
                step={1}
                value={embedHeight}
                onValueChange={setEmbedHeight}
                onSlidingComplete={scheduleReload}
                minimumTrackTintColor={COLORS.accent}
                maximumTrackTintColor={COLORS.border}
                thumbTintColor={COLORS.accent}
              />
            </View>
            <Text style={styles.sizeLabel}>
              {Math.round(embedAreaSize.w * embedWidth / 100)} x {Math.round(embedAreaSize.h * embedHeight / 100)} px
            </Text>
          </View>
          <View style={styles.embedCenter} onLayout={(e) => setEmbedAreaSize({ w: e.nativeEvent.layout.width, h: e.nativeEvent.layout.height })}>
            <View style={{ width: `${embedWidth}%` as any, height: `${embedHeight}%` as any }}>
              <BBChannelWithPlayer
                key={`${bundleUrl}-${embedReloadKey}`}
                ref={channelRef}
                channelUrl={channelUrl}
                options={{
                  bundleUrl,
                  autoPlay: settings.autoPlay,
                  noStats: settings.noStats,
                  ...(settings.jwt ? { jwt: settings.jwt } : {}),
                }}
                playerMode={settings.playerMode}
                playerHeight={settings.playerHeight}
                safeAreaEdges={[]}
                showBackArrow={true}
                handleBackButton={true}
                onReady={onReady}
                onError={onError}
                onMediaPlay={onMediaPlay}
                onMediaPause={onMediaPause}
                onMediaEnd={onMediaEnd}
                onNavigate={onNavigate}
                onCanGoBackChange={onCanGoBackChange}
                onSearch={onSearch}
                onPlayerEvent={onPlayerEvent}
                onTimeUpdate={onTimeUpdate}
                onClipLoaded={onClipLoaded}
                onAdStart={onAdStart}
                onAdEnd={onAdEnd}
                onAnalyticsEvent={onAnalyticsEvent}
                onPlayersChange={onPlayersChange}
                onActivePlayerChange={onActivePlayerChange}
                onNativePlayerStateChange={onNativePlayerStateChange}
                onNativePlayerError={onNativePlayerError}
                onFirstPlayerMedia={onFirstPlayerMedia}
              />
            </View>
          </View>
        </View>
      ) : (
        <>
          <View style={styles.channelContainer}>
            <BBChannelWithPlayer
              key={bundleUrl}
              ref={channelRef}
              channelUrl={channelUrl}
              options={{
                bundleUrl,
                autoPlay: settings.autoPlay,
                noStats: settings.noStats,
                ...(settings.jwt ? { jwt: settings.jwt } : {}),
              }}
              playerMode={settings.playerMode}
              playerHeight={settings.playerHeight}
              safeAreaEdges={[]}
              showBackArrow={true}
              handleBackButton={true}
              onReady={onReady}
              onError={onError}
              onMediaPlay={onMediaPlay}
              onMediaPause={onMediaPause}
              onMediaEnd={onMediaEnd}
              onNavigate={onNavigate}
              onCanGoBackChange={onCanGoBackChange}
              onSearch={onSearch}
              onPlayerEvent={onPlayerEvent}
              onTimeUpdate={onTimeUpdate}
              onClipLoaded={onClipLoaded}
              onAdStart={onAdStart}
              onAdEnd={onAdEnd}
              onAnalyticsEvent={onAnalyticsEvent}
              onPlayersChange={onPlayersChange}
              onActivePlayerChange={onActivePlayerChange}
              onNativePlayerStateChange={onNativePlayerStateChange}
              onNativePlayerError={onNativePlayerError}
              onFirstPlayerMedia={onFirstPlayerMedia}
            />
          </View>
          {settings.showCastMiniControls && (
            <BBCastMiniControls style={styles.castMiniControls} />
          )}
          <EventInspector events={events} onClear={clearEvents} />
        </>
      )}
    </SafeAreaView>
  );
}

function SettingsToggle({ active, onPress }: { active: boolean; onPress: () => void }) {
  return (
    <TouchableOpacity onPress={onPress} hitSlop={8}>
      <Text style={{ color: active ? COLORS.accent : COLORS.textLight, fontSize: 18, fontWeight: '700' as const }}>
        {'*'}
      </Text>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: COLORS.dark,
  },
  channelContainer: {
    flex: 1,
  },
  webLink: {
    color: COLORS.accent,
    fontSize: FONT.xs,
    fontWeight: '700',
  },
  castButton: {
    width: 36,
    height: 36,
  },
  castMiniControls: {
    height: 64,
  },
  embedOuter: {
    flex: 1,
  },
  embedControls: {
    paddingHorizontal: SPACING.lg,
    paddingVertical: SPACING.sm,
    backgroundColor: COLORS.surface,
    borderBottomWidth: 1,
    borderBottomColor: COLORS.border,
  },
  sliderRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: SPACING.sm,
  },
  sliderLabel: {
    fontSize: FONT.xs,
    color: COLORS.textMuted,
    fontWeight: '600',
    width: 48,
  },
  slider: {
    flex: 1,
    height: 28,
  },
  sizeLabel: {
    fontSize: FONT.xs,
    color: COLORS.textMuted,
    textAlign: 'center',
    marginTop: SPACING.xs,
  },
  embedCenter: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: COLORS.dark,
  },
});
