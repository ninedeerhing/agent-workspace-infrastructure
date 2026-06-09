/**
 * L2 · Design Token 层 — 设计令牌
 * 将 DESIGN.md 的设计令牌转化为 TypeScript 值
 */

import type { ColorTokens, TypographyTokens, SpacingTokens, ShadowTokens, RadiusTokens, BreakpointTokens, MotionTokens } from '../core/types';

export const lightColors: ColorTokens = {
  brand: '#2563EB', brandMuted: '#DBEAFE', brandSubtle: '#EFF6FF',
  background: '#FFFFFF', backgroundSecondary: '#F8F9FA', surface: '#FFFFFF',
  border: '#E2E4E9', borderHover: '#C8CBD3',
  textPrimary: '#111214', textSecondary: '#5E6068', textTertiary: '#8B8D95',
  success: '#16A34A', warning: '#D97706', error: '#DC2626', info: '#2563EB',
};

export const darkColors: ColorTokens = {
  brand: '#3B82F6', brandMuted: '#1E3A5F', brandSubtle: '#0F1F3D',
  background: '#0A0A0B', backgroundSecondary: '#131415', surface: '#1A1B1D',
  border: '#2A2B2E', borderHover: '#3A3B3F',
  textPrimary: '#EDEDEF', textSecondary: '#9A9BA0', textTertiary: '#6B6C72',
  success: '#22C55E', warning: '#F59E0B', error: '#EF4444', info: '#3B82F6',
};

export const typographyTokens: TypographyTokens = {
  fontDisplay: "'Geist', system-ui, sans-serif",
  fontHeading: "'Geist', system-ui, sans-serif",
  fontBody: "'Geist', system-ui, sans-serif",
  fontCode: "'Geist Mono', 'JetBrains Mono', monospace",
  scale: {
    xs:  { fontSize: '0.75rem',  lineHeight: 1.5,  letterSpacing: '0.01em',  fontWeight: 400 },
    sm:  { fontSize: '0.875rem', lineHeight: 1.5,  letterSpacing: '0',       fontWeight: 400 },
    base:{ fontSize: '1rem',     lineHeight: 1.6,  letterSpacing: '-0.01em',  fontWeight: 400 },
    lg:  { fontSize: '1.125rem', lineHeight: 1.55, letterSpacing: '-0.01em',  fontWeight: 400 },
    xl:  { fontSize: '1.25rem',  lineHeight: 1.5,  letterSpacing: '-0.02em',  fontWeight: 600 },
    '2xl':{fontSize: '1.5rem',   lineHeight: 1.4,  letterSpacing: '-0.02em',  fontWeight: 600 },
    '3xl':{fontSize: '1.875rem', lineHeight: 1.3,  letterSpacing: '-0.03em',  fontWeight: 600 },
    '4xl':{fontSize: '2.25rem',  lineHeight: 1.2,  letterSpacing: '-0.03em',  fontWeight: 700 },
    '5xl':{fontSize: '3rem',     lineHeight: 1.1,  letterSpacing: '-0.04em',  fontWeight: 700 },
    '6xl':{fontSize: '3.75rem',  lineHeight: 1.05, letterSpacing: '-0.04em',  fontWeight: 700 },
  },
};

export const spacingTokens: SpacingTokens = {
  unit: 4,
  scale: {
    '0': '0', '1': '4px', '2': '8px', '3': '12px', '4': '16px',
    '5': '20px', '6': '24px', '8': '32px', '10': '40px',
    '12': '48px', '16': '64px', '20': '80px', '24': '96px',
  },
};

export const shadowTokens: ShadowTokens = {
  none: 'none',
  xs: '0 1px 2px rgba(0,0,0,0.04)',
  sm: '0 1px 3px rgba(0,0,0,0.06), 0 1px 2px rgba(0,0,0,0.04)',
  md: '0 4px 6px rgba(0,0,0,0.05), 0 2px 4px rgba(0,0,0,0.04)',
  lg: '0 10px 15px rgba(0,0,0,0.06), 0 4px 6px rgba(0,0,0,0.04)',
  xl: '0 20px 25px rgba(0,0,0,0.08), 0 8px 10px rgba(0,0,0,0.04)',
};

export const radiusTokens: RadiusTokens = {
  none: '0', sm: '4px', md: '6px', lg: '8px', xl: '12px', '2xl': '16px', full: '9999px',
};

export const breakpointTokens: BreakpointTokens = {
  sm: '640px', md: '768px', lg: '1024px', xl: '1280px', '2xl': '1536px',
};

export const motionTokens: MotionTokens = {
  duration: { instant: '100ms', fast: '200ms', normal: '300ms', slow: '500ms', deliberate: '700ms' },
  easing: {
    default: 'cubic-bezier(0.16, 1, 0.3, 1)',
    spring: 'cubic-bezier(0.34, 1.56, 0.64, 1)',
    out: 'cubic-bezier(0, 0, 0.2, 1)',
    in: 'cubic-bezier(0.4, 0, 1, 1)',
  },
};

/** 令牌转 CSS 变量 */
export function tokensToCSSVariables(theme: 'light' | 'dark'): Record<string, string> {
  const colors = theme === 'light' ? lightColors : darkColors;
  const vars: Record<string, string> = {};

  for (const [key, value] of Object.entries(colors)) {
    vars[`--color-${key.replace(/([A-Z])/g, '-$1').toLowerCase()}`] = value;
  }

  vars['--font-display'] = typographyTokens.fontDisplay;
  vars['--font-heading'] = typographyTokens.fontHeading;
  vars['--font-body'] = typographyTokens.fontBody;
  vars['--font-code'] = typographyTokens.fontCode;

  for (const [key, token] of Object.entries(typographyTokens.scale)) {
    vars[`--text-${key}-size`] = token.fontSize;
    vars[`--text-${key}-leading`] = String(token.lineHeight);
    vars[`--text-${key}-tracking`] = token.letterSpacing;
    vars[`--text-${key}-weight`] = String(token.fontWeight);
  }

  for (const [key, value] of Object.entries(spacingTokens.scale)) vars[`--space-${key}`] = value;
  for (const [key, value] of Object.entries(shadowTokens)) vars[`--shadow-${key}`] = value;
  for (const [key, value] of Object.entries(radiusTokens)) vars[`--radius-${key}`] = value;
  for (const [key, value] of Object.entries(motionTokens.duration)) vars[`--duration-${key}`] = value;
  for (const [key, value] of Object.entries(motionTokens.easing)) vars[`--ease-${key}`] = value;

  return vars;
}

/** Tailwind CSS 扩展配置 */
export function tailwindConfigExtension(theme: 'light' | 'dark' = 'light') {
  const colors = theme === 'light' ? lightColors : darkColors;
  return {
    colors: {
      brand: { DEFAULT: colors.brand, muted: colors.brandMuted, subtle: colors.brandSubtle },
      surface: { bg: colors.background, secondary: colors.backgroundSecondary, DEFAULT: colors.surface },
      border: { DEFAULT: colors.border, hover: colors.borderHover },
      text: { primary: colors.textPrimary, secondary: colors.textSecondary, tertiary: colors.textTertiary },
    },
    borderRadius: radiusTokens,
    boxShadow: shadowTokens,
  };
}
