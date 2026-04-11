import React from 'react';
import { StyleSheet, View, Text, TouchableOpacity, TextInput } from 'react-native';
import { COLORS, SPACING, FONT, RADIUS } from '../theme';
import type { Environment } from '../types';

const ENVS: Environment[] = ['dev', 'test', 'acc', 'prod'];

interface Props {
  selected: Environment;
  onSelect: (env: Environment) => void;
  customUrl: string | null;
  onCustomUrlChange: (url: string | null) => void;
}

export function EnvironmentPicker({ selected, onSelect, customUrl, onCustomUrlChange }: Props) {
  return (
    <View style={styles.container}>
      <Text style={styles.label}>Environment</Text>
      <View style={styles.pills}>
        {ENVS.map((env) => (
          <TouchableOpacity
            key={env}
            style={[styles.pill, selected === env && !customUrl && styles.pillActive]}
            onPress={() => {
              onSelect(env);
              onCustomUrlChange(null);
            }}
          >
            <Text style={[styles.pillText, selected === env && !customUrl && styles.pillTextActive]}>
              {env}
            </Text>
          </TouchableOpacity>
        ))}
      </View>
      <TextInput
        style={[styles.urlInput, customUrl ? styles.urlInputActive : null]}
        value={customUrl || ''}
        onChangeText={(t) => onCustomUrlChange(t || null)}
        placeholder="Custom bundle URL..."
        placeholderTextColor={COLORS.textMuted}
        autoCapitalize="none"
        autoCorrect={false}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { marginBottom: SPACING.md },
  label: {
    fontSize: FONT.sm,
    color: COLORS.textMuted,
    marginBottom: SPACING.xs,
    fontWeight: '600',
  },
  pills: {
    flexDirection: 'row',
    gap: SPACING.sm,
    marginBottom: SPACING.sm,
  },
  pill: {
    paddingHorizontal: SPACING.lg,
    paddingVertical: SPACING.sm,
    borderRadius: RADIUS.pill,
    backgroundColor: COLORS.surface,
    borderWidth: 1,
    borderColor: COLORS.border,
  },
  pillActive: {
    backgroundColor: COLORS.accent,
    borderColor: COLORS.accent,
  },
  pillText: {
    fontSize: FONT.sm,
    color: COLORS.textMuted,
    fontWeight: '600',
  },
  pillTextActive: {
    color: COLORS.textLight,
  },
  urlInput: {
    backgroundColor: COLORS.surface,
    borderRadius: RADIUS.md,
    paddingHorizontal: SPACING.md,
    paddingVertical: SPACING.sm,
    fontSize: FONT.xs,
    color: COLORS.text,
    borderWidth: 1,
    borderColor: COLORS.border,
  },
  urlInputActive: {
    borderColor: COLORS.accent,
  },
});
