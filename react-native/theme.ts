export const COLORS = {
  background: '#ffffff',
  surface: '#f8f9fa',
  dark: '#32373c',
  accent: '#0693e3',
  accentSecondary: '#9b51e0',
  text: '#1a1a1a',
  textMuted: '#666666',
  textLight: '#ffffff',
  border: '#e0e0e0',
  error: '#e74c3c',
  success: '#27ae60',
};

export const PUBLICATION_COLORS: Record<string, string> = {
  demo: '#00b894',
};

const AD_HOC_COLORS = ['#74b9ff', '#a29bfe', '#55efc4', '#fab1a0', '#dfe6e9'];
let adHocIdx = 0;
export function getAdHocColor(): string {
  return AD_HOC_COLORS[adHocIdx++ % AD_HOC_COLORS.length];
}

export const SPACING = {
  xs: 4,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 24,
  xxl: 32,
};

export const FONT = {
  xs: 10,
  sm: 12,
  md: 14,
  lg: 16,
  xl: 20,
  xxl: 24,
  title: 36,
};

export const RADIUS = {
  sm: 4,
  md: 8,
  lg: 12,
  xl: 16,
  pill: 9999,
};
