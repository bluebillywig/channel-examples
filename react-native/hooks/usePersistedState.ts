import { useState, useEffect, useCallback } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';

const STORAGE_PREFIX = 'channel_example_';

export function usePersistedState<T>(
  key: string,
  defaultValue: T,
): [T, (value: T | ((prev: T) => T)) => void] {
  const [state, setState] = useState<T>(defaultValue);

  useEffect(() => {
    AsyncStorage.getItem(STORAGE_PREFIX + key).then((raw) => {
      if (raw !== null) {
        try {
          setState(JSON.parse(raw));
        } catch { /* ignore parse errors */ }
      }
    });
  }, [key]);

  const setPersisted = useCallback(
    (value: T | ((prev: T) => T)) => {
      setState((prev) => {
        const next = typeof value === 'function' ? (value as (p: T) => T)(prev) : value;
        AsyncStorage.setItem(STORAGE_PREFIX + key, JSON.stringify(next)).catch(() => {});
        return next;
      });
    },
    [key],
  );

  return [state, setPersisted];
}
