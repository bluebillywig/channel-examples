import { useState, useEffect, useCallback, useRef } from 'react';
import type { ChannelItem, Publication } from '../types';

type ChannelMap = Map<string, ChannelItem[]>;

interface UseChannelListResult {
  channels: ChannelMap;
  loading: boolean;
  error: string | null;
  refresh: () => void;
}

async function fetchChannels(host: string): Promise<ChannelItem[]> {
  const res = await fetch(
    `https://${host}/papi/search?className=Channel&limit=1000&sort=createddate+desc`,
  );
  if (!res.ok) throw new Error(`${res.status} ${res.statusText}`);
  const data = await res.json();
  return (data.items || []).map(
    (item: { id: number; name: string; status: string; publicationid: number }) => ({
      id: item.id,
      name: item.name,
      status: item.status,
      publicationid: item.publicationid,
    }),
  );
}

export function useChannelList(publications: Publication[]): UseChannelListResult {
  const [channels, setChannels] = useState<ChannelMap>(new Map());
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const pubsRef = useRef(publications);
  pubsRef.current = publications;

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    const pubs = pubsRef.current;
    const results = await Promise.allSettled(
      pubs.map(async (pub) => {
        const items = await fetchChannels(pub.host);
        return { key: pub.key, items };
      }),
    );

    const map = new Map<string, ChannelItem[]>();
    const errors: string[] = [];
    for (let i = 0; i < results.length; i++) {
      const r = results[i];
      const pub = pubs[i];
      if (r.status === 'fulfilled') {
        map.set(r.value.key, r.value.items);
      } else {
        errors.push(`${pub.key}: ${String(r.reason)}`);
      }
    }

    setChannels(map);
    if (errors.length > 0 && map.size === 0) {
      setError(errors.join('; '));
    }
    setLoading(false);
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  return { channels, loading, error, refresh: load };
}
