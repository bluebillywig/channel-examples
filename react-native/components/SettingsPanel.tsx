import React from 'react';
import {
  StyleSheet,
  View,
  Text,
  TouchableOpacity,
  TextInput,
  Switch,
  ScrollView,
} from 'react-native';
import { COLORS, SPACING, FONT, RADIUS } from '../theme';
import { EnvironmentPicker } from './EnvironmentPicker';
import type { ChannelSettings } from '../types';

interface Props {
  settings: ChannelSettings;
  onChange: (s: ChannelSettings) => void;
}

export function SettingsPanel({ settings, onChange }: Props) {
  const s = settings;
  const set = <K extends keyof ChannelSettings>(key: K, val: ChannelSettings[K]) =>
    onChange({ ...s, [key]: val });

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
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
              <Text style={[styles.segText, s.displayMode === m && styles.segTextActive]}>
                {m}
              </Text>
            </TouchableOpacity>
          ))}
        </View>
      </View>

      <EnvironmentPicker
        selected={s.environment}
        onSelect={(env) => set('environment', env)}
        customUrl={s.customBundleUrl}
        onCustomUrlChange={(url) => set('customBundleUrl', url)}
      />

      {/* JWT */}
      <Text style={styles.label}>JWT</Text>
      <TextInput
        style={styles.textInput}
        value={s.jwt}
        onChangeText={(t) => set('jwt', t)}
        placeholder="Optional JWT token..."
        placeholderTextColor={COLORS.textMuted}
        autoCapitalize="none"
        autoCorrect={false}
      />

      {/* Switches */}
      <View style={styles.switchRow}>
        <Text style={styles.label}>autoPlay</Text>
        <Switch
          value={s.autoPlay}
          onValueChange={(v) => set('autoPlay', v)}
          trackColor={{ false: COLORS.border, true: COLORS.accent }}
        />
      </View>
      <View style={styles.switchRow}>
        <Text style={styles.label}>noStats</Text>
        <Switch
          value={s.noStats}
          onValueChange={(v) => set('noStats', v)}
          trackColor={{ false: COLORS.border, true: COLORS.accent }}
        />
      </View>
      <View style={styles.switchRow}>
        <Text style={styles.label}>Cast mini controls</Text>
        <Switch
          value={s.showCastMiniControls}
          onValueChange={(v) => set('showCastMiniControls', v)}
          trackColor={{ false: COLORS.border, true: COLORS.accent }}
        />
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: COLORS.surface,
    borderBottomWidth: 1,
    borderBottomColor: COLORS.border,
    maxHeight: 320,
  },
  content: {
    padding: SPACING.lg,
  },
  row: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: SPACING.md,
  },
  label: {
    fontSize: FONT.sm,
    color: COLORS.textMuted,
    fontWeight: '600',
    marginBottom: SPACING.xs,
  },
  segmented: {
    flexDirection: 'row',
  },
  seg: {
    paddingHorizontal: SPACING.lg,
    paddingVertical: SPACING.sm,
    backgroundColor: COLORS.background,
    borderWidth: 1,
    borderColor: COLORS.border,
  },
  segActive: {
    backgroundColor: COLORS.accent,
    borderColor: COLORS.accent,
  },
  segText: {
    fontSize: FONT.sm,
    color: COLORS.textMuted,
  },
  segTextActive: {
    color: COLORS.textLight,
    fontWeight: '600',
  },
  heightBtns: {
    flexDirection: 'row',
    gap: SPACING.sm,
  },
  hBtn: {
    width: 36,
    height: 32,
    backgroundColor: COLORS.dark,
    borderRadius: RADIUS.sm,
    alignItems: 'center',
    justifyContent: 'center',
  },
  hBtnText: {
    color: COLORS.textLight,
    fontSize: FONT.xl,
    fontWeight: '700',
  },
  textInput: {
    backgroundColor: COLORS.background,
    borderRadius: RADIUS.md,
    paddingHorizontal: SPACING.md,
    paddingVertical: SPACING.sm,
    fontSize: FONT.xs,
    color: COLORS.text,
    borderWidth: 1,
    borderColor: COLORS.border,
    marginBottom: SPACING.md,
  },
  switchRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: SPACING.sm,
  },
});
