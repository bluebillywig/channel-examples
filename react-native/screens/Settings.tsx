import React from 'react';
import { StyleSheet, View, Text, StatusBar, ScrollView, TouchableOpacity, Switch } from 'react-native';
import { Header } from '../components/Header';
import { EnvironmentPicker } from '../components/EnvironmentPicker';
import { COLORS, SPACING, FONT, RADIUS } from '../theme';
import type { ChannelSettings } from '../types';
import { DEFAULT_SETTINGS } from '../types';
import { usePersistedState } from '../hooks/usePersistedState';

interface Props {
  onBack: () => void;
}

export function Settings({ onBack }: Props) {
  const [settings, setSettings] = usePersistedState<ChannelSettings>('viewer_settings', DEFAULT_SETTINGS);
  const s = settings;
  const set = <K extends keyof ChannelSettings>(key: K, val: ChannelSettings[K]) =>
    setSettings({ ...s, [key]: val });

  const reset = () => setSettings(DEFAULT_SETTINGS);

  return (
    <View style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor={COLORS.dark} />
      <Header title="Settings" subtitle="Global defaults" onBack={onBack} />

      <ScrollView style={styles.scroll} contentContainerStyle={styles.content}>
        <EnvironmentPicker
          selected={s.environment}
          onSelect={(env) => set('environment', env)}
          customUrl={s.customBundleUrl}
          onCustomUrlChange={(url) => set('customBundleUrl', url)}
        />

        {/* Display mode */}
        <View style={styles.row}>
          <Text style={styles.label}>Display mode</Text>
          <View style={styles.segmented}>
            {(['full', 'embed'] as const).map((m) => (
              <TouchableOpacity
                key={m}
                style={[styles.seg, s.displayMode === m && styles.segActive]}
                onPress={() => set('displayMode', m)}
              >
                <Text style={[styles.segText, s.displayMode === m && styles.segTextActive]}>{m}</Text>
              </TouchableOpacity>
            ))}
          </View>
        </View>

        <View style={styles.switchRow}>
          <Text style={styles.label}>autoPlay</Text>
          <Switch value={s.autoPlay} onValueChange={(v) => set('autoPlay', v)} trackColor={{ false: COLORS.border, true: COLORS.accent }} />
        </View>

        <View style={styles.switchRow}>
          <Text style={styles.label}>noStats</Text>
          <Switch value={s.noStats} onValueChange={(v) => set('noStats', v)} trackColor={{ false: COLORS.border, true: COLORS.accent }} />
        </View>

        <TouchableOpacity style={styles.resetBtn} onPress={reset}>
          <Text style={styles.resetText}>Reset to Defaults</Text>
        </TouchableOpacity>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: COLORS.background },
  scroll: { flex: 1 },
  content: { padding: SPACING.xl },
  row: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: SPACING.lg,
  },
  label: { fontSize: FONT.md, color: COLORS.text, fontWeight: '500' },
  segmented: { flexDirection: 'row' },
  seg: {
    paddingHorizontal: SPACING.lg,
    paddingVertical: SPACING.sm,
    backgroundColor: COLORS.surface,
    borderWidth: 1,
    borderColor: COLORS.border,
  },
  segActive: { backgroundColor: COLORS.accent, borderColor: COLORS.accent },
  segText: { fontSize: FONT.sm, color: COLORS.textMuted },
  segTextActive: { color: COLORS.textLight, fontWeight: '600' },
  heightBtns: { flexDirection: 'row', gap: SPACING.sm },
  hBtn: {
    width: 36,
    height: 32,
    backgroundColor: COLORS.dark,
    borderRadius: RADIUS.sm,
    alignItems: 'center',
    justifyContent: 'center',
  },
  hBtnText: { color: COLORS.textLight, fontSize: FONT.xl, fontWeight: '700' },
  switchRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: SPACING.md,
  },
  resetBtn: {
    marginTop: SPACING.xxl,
    alignSelf: 'center',
    paddingHorizontal: SPACING.xl,
    paddingVertical: SPACING.md,
    backgroundColor: COLORS.error,
    borderRadius: RADIUS.pill,
  },
  resetText: { color: COLORS.textLight, fontSize: FONT.md, fontWeight: '600' },
});
