/**
 * L1 · Foundation 层 — 主题引擎
 *
 * 负责主题注册、激活、切换和 CSS 变量注入。
 * 支持亮色/暗色/系统模式，以及自定义主题扩展。
 */

import type { Theme, ThemeMode, ThemeRegistry, ThemeVariant } from './types';

/** 默认亮色主题 — 所有令牌值对应 DESIGN.md 规范 */
const LIGHT_THEME: Omit<Theme, 'id' | 'name' | 'mode'> = {
  colors: {
    brand: '#2563EB',
    brandMuted: '#DBEAFE',
    brandSubtle: '#EFF6FF',
    background: '#FFFFFF',
    backgroundSecondary: '#F8F9FA',
    surface: '#FFFFFF',
    border: '#E2E4E9',
    borderHover: '#C8CBD3',
    textPrimary: '#111214',
    textSecondary: '#5E6068',
    textTertiary: '#8B8D95',
    success: '#16A34A',
    warning: '#D97706',
    error: '#DC2626',
    info: '#2563EB',
  },
  typography: {
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
  },
  spacing: {
    unit: 4,
    scale: {
      '0': '0', '1': '4px', '2': '8px', '3': '12px', '4': '16px',
      '5': '20px', '6': '24px', '8': '32px', '10': '40px',
      '12': '48px', '16': '64px', '20': '80px', '24': '96px',
    },
  },
  shadows: {
    none: 'none',
    xs:   '0 1px 2px rgba(0,0,0,0.04)',
    sm:   '0 1px 3px rgba(0,0,0,0.06), 0 1px 2px rgba(0,0,0,0.04)',
    md:   '0 4px 6px rgba(0,0,0,0.05), 0 2px 4px rgba(0,0,0,0.04)',
    lg:   '0 10px 15px rgba(0,0,0,0.06), 0 4px 6px rgba(0,0,0,0.04)',
    xl:   '0 20px 25px rgba(0,0,0,0.08), 0 8px 10px rgba(0,0,0,0.04)',
  },
  radii: {
    none: '0',
    sm:   '4px',
    md:   '6px',
    lg:   '8px',
    xl:   '12px',
    '2xl':'16px',
    full: '9999px',
  },
  breakpoints: {
    sm:   '640px',
    md:   '768px',
    lg:   '1024px',
    xl:   '1280px',
    '2xl':'1536px',
  },
  motion: {
    duration: {
      instant:    '100ms',
      fast:       '200ms',
      normal:     '300ms',
      slow:       '500ms',
      deliberate: '700ms',
    },
    easing: {
      default: 'cubic-bezier(0.16, 1, 0.3, 1)',
      spring:  'cubic-bezier(0.34, 1.56, 0.64, 1)',
      out:     'cubic-bezier(0, 0, 0.2, 1)',
      in:      'cubic-bezier(0.4, 0, 1, 1)',
    },
  },
};

/** 暗色主题 — 从亮色主题派生，覆盖颜色令牌 */
const DARK_THEME: Omit<Theme, 'id' | 'name' | 'mode'> = {
  ...LIGHT_THEME,
  colors: {
    brand: '#3B82F6',
    brandMuted: '#1E3A5F',
    brandSubtle: '#0F1F3D',
    background: '#0A0A0B',
    backgroundSecondary: '#131415',
    surface: '#1A1B1D',
    border: '#2A2B2E',
    borderHover: '#3A3B3F',
    textPrimary: '#EDEDEF',
    textSecondary: '#9A9BA0',
    textTertiary: '#6B6C72',
    success: '#22C55E',
    warning: '#F59E0B',
    error: '#EF4444',
    info: '#3B82F6',
  },
};

/** 将主题令牌转换为 CSS 自定义属性映射 */
function themeToCSSVariables(theme: Theme): Record<string, string> {
  const vars: Record<string, string> = {};

  // 颜色令牌
  for (const [key, value] of Object.entries(theme.colors)) {
    vars[`--color-${toKebabCase(key)}`] = value;
  }

  // 排版令牌
  vars['--font-display'] = theme.typography.fontDisplay;
  vars['--font-heading'] = theme.typography.fontHeading;
  vars['--font-body'] = theme.typography.fontBody;
  vars['--font-code'] = theme.typography.fontCode;
  for (const [key, token] of Object.entries(theme.typography.scale)) {
    vars[`--text-${key}-size`] = token.fontSize;
    vars[`--text-${key}-leading`] = String(token.lineHeight);
    vars[`--text-${key}-tracking`] = token.letterSpacing;
    vars[`--text-${key}-weight`] = String(token.fontWeight);
  }

  // 间距令牌
  for (const [key, value] of Object.entries(theme.spacing.scale)) {
    vars[`--space-${key}`] = value;
  }

  // 阴影令牌
  for (const [key, value] of Object.entries(theme.shadows)) {
    vars[`--shadow-${key}`] = value;
  }

  // 圆角令牌
  for (const [key, value] of Object.entries(theme.radii)) {
    vars[`--radius-${key}`] = value;
  }

  // 动效令牌
  for (const [key, value] of Object.entries(theme.motion.duration)) {
    vars[`--duration-${key}`] = value;
  }
  for (const [key, value] of Object.entries(theme.motion.easing)) {
    vars[`--ease-${key}`] = value;
  }

  return vars;
}

/** 驼峰转短横线 */
function toKebabCase(str: string): string {
  return str.replace(/([A-Z])/g, '-$1').toLowerCase();
}

/**
 * 创建主题引擎实例
 *
 * 管理主题注册、激活、CSS 变量注入和系统主题监听。
 */
export function createThemeEngine(): ThemeRegistry & {
  /** 将当前主题的 CSS 变量注入到 document */
  injectCSSVariables: () => void;
  /** 监听系统主题变化并自动切换 */
  enableSystemThemeDetection: () => () => void;
  /** 应用主题变体 */
  applyVariant: (variant: ThemeVariant) => Theme;
  /** 获取 CSS 变量映射 */
  getCSSVariables: () => Record<string, string>;
} {
  const themes = new Map<string, Theme>();

  /** 构建完整主题对象 */
  function buildTheme(base: Omit<Theme, 'id' | 'name' | 'mode'>, id: string, name: string, mode: ThemeMode): Theme {
    return { id, name, mode, ...base };
  }

  // 注册内置主题
  themes.set('light', buildTheme(LIGHT_THEME, 'light', '亮色主题', 'light'));
  themes.set('dark', buildTheme(DARK_THEME, 'dark', '暗色主题', 'dark'));

  let activeThemeId = 'light';

  const engine = {
    themes,

    get activeThemeId() {
      return activeThemeId;
    },

    register(theme: Theme): void {
      themes.set(theme.id, theme);
    },

    activate(id: string): Theme {
      const theme = themes.get(id);
      if (!theme) {
        throw new Error(`主题 "${id}" 未注册`);
      }
      activeThemeId = id;
      return theme;
    },

    getActive(): Theme {
      return themes.get(activeThemeId)!;
    },

    getAll(): Theme[] {
      return Array.from(themes.values());
    },

    /** 将当前活动主题的 CSS 变量注入到 <html> 元素 */
    injectCSSVariables(): void {
      const theme = this.getActive();
      const vars = themeToCSSVariables(theme);

      const root = document.documentElement;
      // 先设置 data-theme 属性
      root.setAttribute('data-theme', theme.mode);

      for (const [prop, value] of Object.entries(vars)) {
        root.style.setProperty(prop, value);
      }
    },

    /** 监听系统 prefers-color-scheme 变化 */
    enableSystemThemeDetection(): () => void {
      const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');

      const handler = (e: MediaQueryListEvent) => {
        const systemTheme = themes.get('system');
        if (systemTheme) {
          this.activate(e.matches ? 'dark' : 'light');
          this.injectCSSVariables();
        }
      };

      mediaQuery.addEventListener('change', handler);
      return () => mediaQuery.removeEventListener('change', handler);
    },

    /** 应用主题变体 — 在基础主题上叠加变体的覆盖值 */
    applyVariant(variant: ThemeVariant): Theme {
      const baseId = variant.extends || activeThemeId;
      const base = themes.get(baseId);
      if (!base) {
        throw new Error(`基础主题 "${baseId}" 未注册`);
      }

      const merged: Theme = {
        id: variant.id,
        name: variant.name,
        mode: variant.mode || base.mode,
        colors: { ...base.colors, ...variant.colors },
        typography: { ...base.typography, ...variant.typography },
        spacing: { ...base.spacing, ...variant.spacing },
        shadows: { ...base.shadows, ...variant.shadows },
        radii: { ...base.radii, ...variant.radii },
        breakpoints: { ...base.breakpoints, ...variant.breakpoints },
        motion: { ...base.motion, ...variant.motion },
      };

      themes.set(merged.id, merged);
      return merged;
    },

    /** 获取当前 CSS 变量映射 */
    getCSSVariables(): Record<string, string> {
      return themeToCSSVariables(this.getActive());
    },
  };

  return engine;
}

/** 全局主题引擎单例 */
let globalEngine: ReturnType<typeof createThemeEngine> | null = null;

/** 获取或初始化全局主题引擎 */
export function getThemeEngine(): ReturnType<typeof createThemeEngine> {
  if (!globalEngine) {
    globalEngine = createThemeEngine();
  }
  return globalEngine;
}
