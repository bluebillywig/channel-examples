import React from 'react';
import { StyleSheet, View, Text, TouchableOpacity } from 'react-native';
import { COLORS, SPACING, FONT, RADIUS } from '../theme';
import type { ChannelItem } from '../types';

interface Props {
  channel: ChannelItem;
  accentColor: string;
  onPress: () => void;
}

export function ChannelCard({ channel, accentColor, onPress }: Props) {
  return (
    <TouchableOpacity style={styles.card} onPress={onPress} activeOpacity={0.7}>
      <View style={[styles.accent, { backgroundColor: accentColor }]} />
      <View style={styles.body}>
        <Text style={styles.name} numberOfLines={1}>{channel.name}</Text>
        <Text style={styles.meta}>ID: {channel.id} | {channel.status}</Text>
      </View>
      <Text style={styles.arrow}>{'>'}</Text>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  card: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: COLORS.surface,
    marginHorizontal: SPACING.lg,
    marginBottom: SPACING.sm,
    borderRadius: RADIUS.lg,
    borderWidth: 1,
    borderColor: COLORS.border,
    overflow: 'hidden',
  },
  accent: {
    width: 4,
    alignSelf: 'stretch',
  },
  body: {
    flex: 1,
    paddingVertical: SPACING.md,
    paddingHorizontal: SPACING.lg,
  },
  name: {
    fontSize: FONT.md,
    fontWeight: '600',
    color: COLORS.text,
  },
  meta: {
    fontSize: FONT.xs,
    color: COLORS.textMuted,
    marginTop: 2,
  },
  arrow: {
    fontSize: FONT.lg,
    color: COLORS.textMuted,
    paddingRight: SPACING.lg,
  },
});
