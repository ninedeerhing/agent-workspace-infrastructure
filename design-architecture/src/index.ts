/**
 * 前端设计底层架构 — 主入口
 *
 * 六层架构统一导出点：
 *   L1 · Foundation    → theme-engine.ts
 *   L2 · Design Tokens  → tokens.ts
 *   L3 · Component      → (类型接口)
 *   L4 · Animation      → animation/engine
 *   L5 · AI Intelligence → skills/*
 *   L6 · AI Copilot     → copilot/copilot-layer
 */

// L1 · Foundation
export { createThemeEngine, getThemeEngine } from './core/theme-engine';

// L2 · Design Tokens
export {
  lightColors, darkColors, typographyTokens, spacingTokens,
  shadowTokens, radiusTokens, breakpointTokens, motionTokens,
  tokensToCSSVariables, tailwindConfigExtension,
} from './design/tokens';

// L3 · Component (类型)
export type { BaseComponentProps, ComponentSize, ComponentVariant } from './core/types';

// L4 · Animation
export {
  createAnimationEngine, ENTRANCE_PRESETS, HOVER_PRESETS, PAGE_TRANSITIONS,
} from './animation/engine';

// L5 · AI Design Intelligence
export {
  ANTI_PATTERNS, detectAntiPatterns, generateAntiPatternReport, getAntiPatternPrompt,
} from './design/skills/anti-patterns';

export {
  DESIGN_COMMANDS, COMMANDS_BY_DIMENSION, WORKFLOW_SEQUENCES, getDesignCommand,
} from './design/skills/design-commands';

export {
  DEFAULT_DESIGN_CONTEXT, createDesignContext, generateDesignContextPrompt,
  inferTypography, inferColorScheme,
} from './design/skills/design-context';

// L6 · AI Copilot
export {
  createAgentRuntime, createGenerativeUIRegistry, createFrontendTools, createSharedState,
} from './copilot/copilot-layer';

// Types
export type {
  ColorTokens, TypographyTokens, SpacingTokens, ShadowTokens,
  RadiusTokens, BreakpointTokens, MotionTokens,
  Theme, ThemeMode, ThemeVariant,
  AnimationConfig, TimelineConfig, ScrollAnimationConfig,
  DesignContext, AntiPattern, DesignCommand, DesignDimension,
  AgentMessage, GenerativeUIComponent, FrontendTool,
} from './core/types';
