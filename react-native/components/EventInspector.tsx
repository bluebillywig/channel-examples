import React, { useState, useCallback } from 'react';
import {
  StyleSheet,
  View,
  Text,
  TouchableOpacity,
  FlatList,
  TextInput,
  Platform,
} from 'react-native';
import { COLORS, SPACING, FONT, RADIUS } from '../theme';
import type { EventEntry } from '../types';

type DisplayMode = 'hidden' | 'collapsed' | 'expanded';

const CATEGORY_COLORS: Record<string, string> = {
  lifecycle: COLORS.success,
  navigation: COLORS.accent,
  player: '#f1c40f',
  error: COLORS.error,
  analytics: COLORS.textMuted,
};

interface Props {
  events: EventEntry[];
  onClear: () => void;
}

export function EventInspector({ events, onClear }: Props) {
  const [mode, setMode] = useState<DisplayMode>('collapsed');
  const [filter, setFilter] = useState('');
  const [expandedId, setExpandedId] = useState<number | null>(null);

  const filtered = filter
    ? events.filter((e) => e.type.toLowerCase().includes(filter.toLowerCase()))
    : events;

  const cycle = useCallback(() => {
    setMode((m) => {
      if (m === 'hidden') return 'collapsed';
      if (m === 'collapsed') return 'expanded';
      return 'hidden';
    });
  }, []);

  // Hidden: just a floating pill badge
  if (mode === 'hidden') {
    return (
      <TouchableOpacity style={styles.pill} onPress={cycle}>
        <Text style={styles.pillText}>Events {events.length}</Text>
      </TouchableOpacity>
    );
  }

  const renderItem = ({ item }: { item: EventEntry }) => {
    const color = CATEGORY_COLORS[item.category] || COLORS.textMuted;
    const isExpanded = expandedId === item.id;
    return (
      <TouchableOpacity
        style={styles.eventRow}
        onPress={() => setExpandedId(isExpanded ? null : item.id)}
        activeOpacity={0.7}
      >
        <View style={styles.eventHeader}>
          <Text style={styles.eventTime}>{item.time}</Text>
          <Text style={[styles.eventType, { color }]}>{item.type}</Text>
          <Text style={styles.eventSummary} numberOfLines={isExpanded ? undefined : 1}>
            {item.summary}
          </Text>
        </View>
        {isExpanded && item.detail ? (
          <Text style={styles.eventDetail}>{item.detail}</Text>
        ) : null}
      </TouchableOpacity>
    );
  };

  return (
    <View style={[styles.container, mode === 'expanded' && styles.expanded]}>
      {/* Header bar */}
      <TouchableOpacity style={styles.headerBar} onPress={cycle}>
        <Text style={styles.headerTitle}>
          Events {filtered.length}/{events.length}
        </Text>
        <View style={styles.headerActions}>
          <TouchableOpacity onPress={onClear} hitSlop={8}>
            <Text style={styles.clearBtn}>Clear</Text>
          </TouchableOpacity>
          <Text style={styles.toggleIcon}>{mode === 'expanded' ? 'v' : '^'}</Text>
        </View>
      </TouchableOpacity>

      {/* Filter */}
      {mode === 'expanded' && (
        <TextInput
          style={styles.filterInput}
          value={filter}
          onChangeText={setFilter}
          placeholder="Filter by event type..."
          placeholderTextColor={COLORS.textMuted}
          autoCapitalize="none"
        />
      )}

      {/* Event list */}
      <FlatList
        data={filtered}
        keyExtractor={(e) => String(e.id)}
        renderItem={renderItem}
        style={styles.list}
        inverted={false}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  pill: {
    position: 'absolute',
    bottom: 12,
    right: 12,
    backgroundColor: COLORS.dark,
    paddingHorizontal: SPACING.md,
    paddingVertical: SPACING.sm,
    borderRadius: RADIUS.pill,
    zIndex: 100,
    elevation: 100,
  },
  pillText: {
    color: COLORS.textLight,
    fontSize: FONT.xs,
    fontWeight: '600',
  },
  container: {
    height: 140,
    backgroundColor: COLORS.dark,
    borderTopWidth: 1,
    borderTopColor: 'rgba(255,255,255,0.1)',
  },
  expanded: {
    height: '40%' as unknown as number,
  },
  headerBar: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: SPACING.md,
    paddingVertical: SPACING.sm,
    borderBottomWidth: 1,
    borderBottomColor: 'rgba(255,255,255,0.08)',
  },
  headerTitle: {
    color: COLORS.textLight,
    fontSize: FONT.sm,
    fontWeight: '600',
  },
  headerActions: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: SPACING.md,
  },
  clearBtn: {
    color: COLORS.error,
    fontSize: FONT.sm,
  },
  toggleIcon: {
    color: COLORS.textLight,
    fontSize: FONT.md,
    fontWeight: '700',
  },
  filterInput: {
    backgroundColor: 'rgba(255,255,255,0.08)',
    marginHorizontal: SPACING.sm,
    marginVertical: SPACING.xs,
    borderRadius: RADIUS.sm,
    paddingHorizontal: SPACING.sm,
    paddingVertical: SPACING.xs,
    color: COLORS.textLight,
    fontSize: FONT.xs,
  },
  list: {
    flex: 1,
    paddingHorizontal: SPACING.sm,
  },
  eventRow: {
    paddingVertical: SPACING.xs,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: 'rgba(255,255,255,0.06)',
  },
  eventHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: SPACING.sm,
  },
  eventTime: {
    color: 'rgba(255,255,255,0.4)',
    fontSize: 9,
    fontFamily: Platform.OS === 'ios' ? 'Menlo' : 'monospace',
  },
  eventType: {
    fontSize: FONT.xs,
    fontWeight: '600',
    minWidth: 60,
  },
  eventSummary: {
    flex: 1,
    color: 'rgba(255,255,255,0.6)',
    fontSize: FONT.xs,
    fontFamily: Platform.OS === 'ios' ? 'Menlo' : 'monospace',
  },
  eventDetail: {
    color: 'rgba(255,255,255,0.5)',
    fontSize: 9,
    fontFamily: Platform.OS === 'ios' ? 'Menlo' : 'monospace',
    marginTop: SPACING.xs,
    paddingLeft: SPACING.xl,
  },
});
