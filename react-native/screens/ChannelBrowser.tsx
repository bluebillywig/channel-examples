import React, { useState, useMemo, useCallback } from 'react';
import {
  StyleSheet,
  View,
  Text,
  TextInput,
  TouchableOpacity,
  FlatList,
  ActivityIndicator,
  StatusBar,
  ScrollView,
} from 'react-native';
import { COLORS, SPACING, FONT, RADIUS, PUBLICATION_COLORS, getAdHocColor } from '../theme';
import { PUBLICATIONS, publicationFromKey } from '../types';
import type { ChannelItem, Publication } from '../types';
import { useChannelList } from '../hooks/useChannelList';
import { usePersistedState } from '../hooks/usePersistedState';
import { SearchBar } from '../components/SearchBar';
import { ChannelCard } from '../components/ChannelCard';
import { Header } from '../components/Header';
import { getChannelUrl } from '../config';
import { SDK_VERSION } from '@bluebillywig/react-native-channel';

interface Props {
  onSelectChannel: (channelUrl: string, channelName: string, publicationHost: string) => void;
  onOpenSettings: () => void;
}

export function ChannelBrowser({ onSelectChannel, onOpenSettings }: Props) {
  const [customPubs, setCustomPubs] = useState<Publication[]>([]);
  const [showAddInput, setShowAddInput] = useState(false);
  const [addValue, setAddValue] = useState('');

  const allPubs = useMemo(() => [...PUBLICATIONS, ...customPubs], [customPubs]);
  const { channels, loading, refresh } = useChannelList(allPubs);
  const [activeTab, setActiveTab] = usePersistedState('active_publication', PUBLICATIONS[0].key);
  const [search, setSearch] = useState('');

  const tabChannels = channels.get(activeTab) || [];
  const filtered = useMemo(() => {
    if (!search) return tabChannels;
    const q = search.toLowerCase();
    return tabChannels.filter(
      (c) => c.name.toLowerCase().includes(q) || String(c.id).includes(q),
    );
  }, [tabChannels, search]);

  const activePub = allPubs.find((p) => p.key === activeTab) || allPubs[0];
  const accentColor = PUBLICATION_COLORS[activeTab] || COLORS.accent;

  const addCustomPub = useCallback(() => {
    const key = addValue.trim().toLowerCase();
    if (!key || allPubs.some((p) => p.key === key)) {
      setShowAddInput(false);
      setAddValue('');
      return;
    }
    const color = getAdHocColor();
    PUBLICATION_COLORS[key] = color;
    const pub = publicationFromKey(key);
    setCustomPubs((prev) => [...prev, pub]);
    setActiveTab(key);
    setShowAddInput(false);
    setAddValue('');
    // refresh will pick up the new pub via ref
    setTimeout(refresh, 0);
  }, [addValue, allPubs, refresh]);

  const renderItem = ({ item }: { item: ChannelItem }) => (
    <ChannelCard
      channel={item}
      accentColor={accentColor}
      onPress={() =>
        onSelectChannel(
          getChannelUrl(activePub.host, item.id),
          item.name,
          activePub.host,
        )
      }
    />
  );

  return (
    <View style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor={COLORS.dark} />
      <Header
        title="Channel SDK Example"
        subtitle={`Blue Billywig · v${SDK_VERSION}`}
        right={
          <TouchableOpacity onPress={onOpenSettings} hitSlop={8}>
            <Text style={styles.gearIcon}>{'*'}</Text>
          </TouchableOpacity>
        }
      />

      {/* Publication tabs */}
      <View style={styles.tabBar}>
        <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.tabScroll}>
          {allPubs.map((pub) => {
            const active = pub.key === activeTab;
            const color = PUBLICATION_COLORS[pub.key] || COLORS.accent;
            const count = channels.get(pub.key)?.length || 0;
            return (
              <TouchableOpacity
                key={pub.key}
                style={[styles.tab, active && { backgroundColor: color }]}
                onPress={() => {
                  setActiveTab(pub.key);
                  setSearch('');
                }}
              >
                <Text style={[styles.tabText, active && styles.tabTextActive]}>
                  {pub.key} ({count})
                </Text>
              </TouchableOpacity>
            );
          })}
          {showAddInput ? (
            <View style={styles.addInputRow}>
              <TextInput
                style={styles.addInput}
                placeholder="publication name"
                placeholderTextColor={COLORS.textMuted}
                value={addValue}
                onChangeText={setAddValue}
                onSubmitEditing={addCustomPub}
                autoFocus
                autoCapitalize="none"
                autoCorrect={false}
              />
              <TouchableOpacity style={styles.addConfirm} onPress={addCustomPub}>
                <Text style={styles.addConfirmText}>OK</Text>
              </TouchableOpacity>
              <TouchableOpacity onPress={() => { setShowAddInput(false); setAddValue(''); }}>
                <Text style={styles.addCancelText}>X</Text>
              </TouchableOpacity>
            </View>
          ) : (
            <TouchableOpacity style={styles.addTab} onPress={() => setShowAddInput(true)}>
              <Text style={styles.addTabText}>+</Text>
            </TouchableOpacity>
          )}
        </ScrollView>
      </View>

      <SearchBar value={search} onChangeText={setSearch} />

      {loading ? (
        <View style={styles.center}>
          <ActivityIndicator size="large" color={COLORS.accent} />
          <Text style={styles.loadingText}>Loading channels...</Text>
        </View>
      ) : (
        <FlatList
          data={filtered}
          keyExtractor={(c) => `${activeTab}-${c.id}`}
          renderItem={renderItem}
          contentContainerStyle={styles.listContent}
          refreshing={loading}
          onRefresh={refresh}
          ListEmptyComponent={
            <View style={styles.center}>
              <Text style={styles.emptyText}>
                {search ? 'No channels match your filter' : 'No channels found'}
              </Text>
            </View>
          }
        />
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: COLORS.background,
  },
  gearIcon: {
    color: COLORS.textLight,
    fontSize: FONT.xl,
    fontWeight: '700',
  },
  tabBar: {
    backgroundColor: COLORS.background,
    borderBottomWidth: 1,
    borderBottomColor: COLORS.border,
  },
  tabScroll: {
    paddingHorizontal: SPACING.md,
    paddingVertical: SPACING.sm,
    gap: SPACING.sm,
  },
  tab: {
    paddingHorizontal: SPACING.lg,
    paddingVertical: SPACING.sm,
    borderRadius: RADIUS.pill,
    backgroundColor: COLORS.surface,
    borderWidth: 1,
    borderColor: COLORS.border,
  },
  tabText: {
    fontSize: FONT.sm,
    color: COLORS.textMuted,
    fontWeight: '600',
  },
  tabTextActive: {
    color: COLORS.textLight,
  },
  center: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: SPACING.xxl,
  },
  loadingText: {
    marginTop: SPACING.md,
    color: COLORS.textMuted,
    fontSize: FONT.md,
  },
  emptyText: {
    color: COLORS.textMuted,
    fontSize: FONT.md,
    textAlign: 'center',
  },
  listContent: {
    paddingTop: SPACING.sm,
    paddingBottom: SPACING.xxl,
  },
  addTab: {
    paddingHorizontal: SPACING.lg,
    paddingVertical: SPACING.sm,
    borderRadius: RADIUS.pill,
    backgroundColor: COLORS.surface,
    borderWidth: 1,
    borderColor: COLORS.border,
    borderStyle: 'dashed',
  },
  addTabText: {
    fontSize: FONT.lg,
    color: COLORS.textMuted,
    fontWeight: '600',
  },
  addInputRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: SPACING.xs,
  },
  addInput: {
    backgroundColor: COLORS.surface,
    borderWidth: 1,
    borderColor: COLORS.accent,
    borderRadius: RADIUS.pill,
    paddingHorizontal: SPACING.md,
    paddingVertical: SPACING.xs,
    fontSize: FONT.sm,
    color: COLORS.text,
    minWidth: 140,
  },
  addConfirm: {
    backgroundColor: COLORS.accent,
    borderRadius: RADIUS.pill,
    paddingHorizontal: SPACING.md,
    paddingVertical: SPACING.xs,
  },
  addConfirmText: {
    color: COLORS.textLight,
    fontSize: FONT.sm,
    fontWeight: '600',
  },
  addCancelText: {
    color: COLORS.textMuted,
    fontSize: FONT.md,
    fontWeight: '600',
    paddingHorizontal: SPACING.sm,
  },
});
