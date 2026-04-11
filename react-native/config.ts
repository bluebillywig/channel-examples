// Channel bundle URL — uses the production CDN by default.
// The SDK loads this automatically; only override if needed.
export const BUNDLE_URL =
  'https://cdn.bluebillywig.com/apps/channel/latest/channel-native.js';

export function getChannelUrl(host: string, id: number): string {
  return `https://${host}/ch/${id}.json`;
}
