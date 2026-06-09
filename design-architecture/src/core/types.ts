/**
 * 前端设计底层架构 — 核心类型定义
 *
 * 定义了整个设计系统中使用的所有基础类型，
 * 覆盖 Design Tokens、Themes、Animations、AI Skills 等领域。
 */

// ==================== 基础设计令牌类型 ====================

/** 颜色令牌 — 遵循 OKLCH 色彩空间的最佳实践 */
export interface ColorTokens {
  brand: string;
  brandMuted: string;
  brandSubtle: string;
  background: string;
  backgroundSecondary: string;
  surface: string;
  border: string;
  borderHover: string;
  textPrimary: string;
  textSecondary: string;
  textTertiary: string;
  success: string;
  warning: string;
  error: string;
  info: string;
}

/** 排版令牌 */
export interface TypographyTokens {
  fontDisplay: string;
  fontHeading: string;
  fontBody: string;
  fontCode: string;
  scale: Record<TypeScale, TypeScaleToken>;
}

export type TypeScale = 'xs' | 'sm' | 'base' | 'lg' | 'xl' | '2xl' | '3xl' | '4xl' | '5xl' | '6xl';

export interface TypeScaleToken {
  fontSize: string;
  lineHeight: number;
  letterSpacing: string;
  fontWeight: number;
}

/** 间距令牌 — 基于 8px 网格系统 */
export interface SpacingTokens {
  /** 基础单位 = 4px */
  unit: number;
  scale: Record<SpacingScale, string>;
}

export type SpacingScale = '0' | '1' | '2' | '3' | '4' | '5' | '6' | '8' | '10' | '12' | '16' | '20' | '24';

/** 阴影令牌 */
export interface ShadowTokens {
  none: string;
  xs: string;
  sm: string;
  md: string;
  lg: string;
  xl: string;
}

/** 圆角令牌 */
export interface RadiusTokens {
  none: string;
  sm: string;
  md: string;
  lg: string;
  xl: string;
  '2xl': string;
  full: string;
}

/** 断点令牌 */
export interface BreakpointTokens {
  sm: string;
  md: string;
  lg: string;
  xl: string;
  '2xl': string;
}

/** 动效令牌 */
export interface MotionTokens {
  duration: {
    instant: string;
    fast: string;
    normal: string;
    slow: string;
    deliberate: string;
  };
  easing: {
    default: string;
    spring: string;
    out: string;
    in: string;
  };
}

// ==================== 主题定义类型 ====================

/** 完整的主题定义 */
export interface Theme {
  id: string;
  name: string;
  /** 'light' | 'dark' | 'system' */
  mode: ThemeMode;
  colors: ColorTokens;
  typography: TypographyTokens;
  spacing: SpacingTokens;
  shadows: ShadowTokens;
  radii: RadiusTokens;
  breakpoints: BreakpointTokens;
  motion: MotionTokens;
}

export type ThemeMode = 'light' | 'dark' | 'system';

/** 主题变体 — 支持自定义主题扩展 */
export interface ThemeVariant extends Partial<Theme> {
  id: string;
  name: string;
  /** 继承自哪个基础主题 */
  extends?: string;
}

// ==================== 组件基元类型 ====================

/** 组件属性基础接口 — 所有组件继承自此 */
export interface BaseComponentProps {
  /** 语义化 class 覆盖 */
  className?: string;
  /** 内联样式 */
  style?: Record<string, string>;
  /** 数据测试标识 */
  'data-testid'?: string;
}

/** 组件变体约束 */
export type ComponentVariant = string;

/** 组件尺寸约束 */
export type ComponentSize = 'xs' | 'sm' | 'md' | 'lg' | 'xl';

// ==================== 动画系统类型 ====================

/** 动画配置结构 */
export interface AnimationConfig {
  /** 目标选择器或元素 */
  targets: string | HTMLElement | HTMLElement[] | object;
  /** 动画属性映射 */
  properties: Record<string, AnimationPropertyValue>;
  /** 持续时间（毫秒） */
  duration?: number;
  /** 延迟（毫秒） */
  delay?: number;
  /** 缓动函数 */
  easing?: string;
  /** 循环次数（true = 无限） */
  loop?: boolean | number;
  /** 是否交替反向 */
  alternate?: boolean;
  /** 是否自动播放 */
  autoplay?: boolean;
  /** 交错延迟函数或值 */
  stagger?: number | StaggerFunction;
}

/** 动画属性值 — 支持多种值类型 */
export type AnimationPropertyValue =
  | number
  | string
  | [number, number]
  | [string, string]
  | PropertyValueFunction;

/** 基于当前值的函数式动画值 */
export type PropertyValueFunction = (target: HTMLElement, index: number, targetsLength: number) => number | string;

/** 交错延迟函数 */
export type StaggerFunction = (target: HTMLElement, index: number, length: number) => number;

/** 时间线配置 */
export interface TimelineConfig {
  /** 时间线名称 */
  name?: string;
  /** 默认持续时间 */
  defaults?: Partial<AnimationConfig>;
  /** 是否自动播放 */
  autoplay?: boolean;
  /** 是否循环 */
  loop?: boolean | number;
}

/** 时间线中的动画条目 */
export interface TimelineEntry {
  config: AnimationConfig;
  /** 时间位置偏移（毫秒） */
  positionOffset?: number | string;
}

/** 滚动动画配置 */
export interface ScrollAnimationConfig {
  /** 滚动容器 */
  container?: HTMLElement | string;
  /** 触发元素 */
  trigger?: HTMLElement | string;
  /** 动画配置 */
  animation: AnimationConfig;
  /** 同步模式 */
  syncMode?: 'onscroll' | 'onenter' | 'onleave';
}

// ==================== AI 设计技能类型 ====================

/** 设计上下文 — 用于 AI 代理理解项目设计意图 */
export interface DesignContext {
  /** 项目名称 */
  projectName: string;
  /** 设计风格标签 */
  styleKeywords: string[];
  /** 目标受众 */
  audience: string[];
  /** 品牌个性 */
  brandPersonality: string[];
  /** 参考设计系统 */
  referenceSystems: string[];
  /** 反参考（要避免的风格） */
  antiReferences: string[];
  /** 色彩基调 */
  colorMood: string;
  /** 排版基调 */
  typographyMood: string;
}

/** 反模式定义 — 告诉 AI 不要生成什么 */
export interface AntiPattern {
  /** 唯一标识 */
  id: string;
  /** 模式名称 */
  name: string;
  /** 描述 */
  description: string;
  /** 严重程度 (P0=阻塞, P1=严重, P2=一般, P3=建议) */
  severity: 'P0' | 'P1' | 'P2' | 'P3';
  /** 匹配正则 — 检测代码中是否出现此模式 */
  detectionPattern: RegExp;
  /** 修复建议 */
  remediation: string;
}

/** 设计命令定义 */
export interface DesignCommand {
  /** 命令名称 */
  name: string;
  /** 命令描述 */
  description: string;
  /** 命令别名 */
  aliases: string[];
  /** 适用场景 */
  useCases: string[];
  /** 设计维度 */
  dimension: DesignDimension;
}

/** 设计维度 — 对应 Impeccable 的 7 维度 */
export type DesignDimension =
  | 'typography'
  | 'color'
  | 'spatial'
  | 'responsive'
  | 'interaction'
  | 'motion'
  | 'ux-writing';

// ==================== Copilot 集成类型 ====================

/** AI 代理消息 */
export interface AgentMessage {
  id: string;
  role: 'user' | 'assistant' | 'system' | 'tool';
  content: string;
  timestamp: number;
}

/** 生成式 UI 组件注册 */
export interface GenerativeUIComponent {
  /** 组件名称 — AI 通过此名称调用 */
  name: string;
  /** 描述 — AI 理解何时使用 */
  description: string;
  /** 参数 schema */
  parameters: Record<string, {
    type: 'string' | 'number' | 'boolean' | 'object' | 'array';
    description: string;
    required: boolean;
  }>;
}

/** 前端工具定义 — AI 可调用的前端操作 */
export interface FrontendTool {
  name: string;
  description: string;
  parameters: Record<string, unknown>;
  /** 工具执行函数 */
  handler: (params: Record<string, unknown>) => Promise<unknown> | unknown;
}

// ==================== 注册表类型 ====================

/** 主题注册表 */
export interface ThemeRegistry {
  themes: Map<string, Theme>;
  activeThemeId: string;
  register(theme: Theme): void;
  activate(id: string): Theme;
  getActive(): Theme;
  getAll(): Theme[];
}

/** 组件注册表 */
export interface ComponentRegistry {
  register(name: string, component: unknown): void;
  get(name: string): unknown | undefined;
  getAll(): Map<string, unknown>;
}

/** 动画预设注册表 */
export interface AnimationPresetRegistry {
  register(name: string, config: AnimationConfig): void;
  get(name: string): AnimationConfig | undefined;
  apply(name: string, targets: AnimationConfig['targets'], overrides?: Partial<AnimationConfig>): AnimationConfig;
}
