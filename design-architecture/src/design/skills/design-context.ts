/**
 * L5 · AI Design Intelligence 层 — 设计上下文
 *
 * 管理 AI 代理所需的设计上下文信息，对应 Impeccable 的 teach 命令
 * 和 Taste Skill 的 Brief Inference 能力。
 */

import type { DesignContext } from '../../core/types';

/** 默认设计上下文 — 开发者工具/SaaS 方向 */
export const DEFAULT_DESIGN_CONTEXT: DesignContext = {
  projectName: '未命名项目',
  styleKeywords: ['现代极简', '功能优先', '精确克制', '技术感'],
  audience: ['开发者', '技术团队', '产品经理'],
  brandPersonality: ['专业', '可信赖', '高效', '冷静'],
  referenceSystems: ['Linear', 'Vercel', 'Stripe', 'Raycast'],
  antiReferences: ['Material Design', 'neumorphism', 'glass-heavy', 'AI-sloped templates'],
  colorMood: '冷静的蓝色系 + 克制的灰阶',
  typographyMood: '几何无衬线 + 精确的字重层次',
};

/**
 * 创建设计上下文
 *
 * 从用户提供的简要描述中构建结构化的设计上下文，
 * 供 AI 代理在生成 UI 代码时作为参考。
 */
export function createDesignContext(partial: Partial<DesignContext>): DesignContext {
  return {
    ...DEFAULT_DESIGN_CONTEXT,
    ...partial,
    styleKeywords: [
      ...new Set([...DEFAULT_DESIGN_CONTEXT.styleKeywords, ...(partial.styleKeywords || [])]),
    ],
    audience: [
      ...new Set([...DEFAULT_DESIGN_CONTEXT.audience, ...(partial.audience || [])]),
    ],
    brandPersonality: [
      ...new Set([...DEFAULT_DESIGN_CONTEXT.brandPersonality, ...(partial.brandPersonality || [])]),
    ],
    referenceSystems: [
      ...new Set([...DEFAULT_DESIGN_CONTEXT.referenceSystems, ...(partial.referenceSystems || [])]),
    ],
    antiReferences: [
      ...new Set([...DEFAULT_DESIGN_CONTEXT.antiReferences, ...(partial.antiReferences || [])]),
    ],
  };
}

/**
 * 生成 AI Prompt 使用的设计上下文描述
 *
 * 将结构化上下文转换为可注入 AI 提示的自然语言描述。
 */
export function generateDesignContextPrompt(context: DesignContext): string {
  return [
    '## 项目设计上下文',
    '',
    `**项目**: ${context.projectName}`,
    `**设计风格**: ${context.styleKeywords.join(' · ')}`,
    `**目标受众**: ${context.audience.join('、')}`,
    `**品牌个性**: ${context.brandPersonality.join('、')}`,
    `**色彩基调**: ${context.colorMood}`,
    `**排版基调**: ${context.typographyMood}`,
    '',
    `**参考设计系统**: ${context.referenceSystems.join('、')}`,
    `**避免风格**: ${context.antiReferences.join('、')}`,
  ].join('\n');
}

/**
 * 从设计风格关键词推断合适的排版方案
 */
export function inferTypography(styleKeywords: string[]): {
  font: string;
  fontMono: string;
  scale: string;
} {
  const keywords = styleKeywords.map(k => k.toLowerCase()).join(' ');

  if (keywords.includes('editorial') || keywords.includes('杂志')) {
    return { font: 'Instrument Serif', fontMono: 'JetBrains Mono', scale: 'perfect-fourth' };
  }
  if (keywords.includes('brutalist') || keywords.includes('粗野')) {
    return { font: 'Space Grotesk', fontMono: 'Space Mono', scale: 'major-second' };
  }
  if (keywords.includes('playful') || keywords.includes('活泼')) {
    return { font: 'Outfit', fontMono: 'Fira Code', scale: 'major-third' };
  }
  if (keywords.includes('luxury') || keywords.includes('奢侈')) {
    return { font: 'Cabinet Grotesk', fontMono: 'JetBrains Mono', scale: 'perfect-fifth' };
  }

  // 默认：现代技术风格
  return { font: 'Geist', fontMono: 'Geist Mono', scale: 'major-third' };
}

/**
 * 从设计风格关键词推断色彩方案
 */
export function inferColorScheme(styleKeywords: string[], colorMood: string): {
  primary: string;
  neutral: string;
  accent: string;
} {
  const keywords = styleKeywords.map(k => k.toLowerCase()).join(' ');

  if (keywords.includes('warm') || keywords.includes('温暖')) {
    return { primary: 'amber', neutral: 'warm-gray', accent: 'orange' };
  }
  if (keywords.includes('nature') || keywords.includes('自然')) {
    return { primary: 'emerald', neutral: 'stone', accent: 'teal' };
  }
  if (keywords.includes('bold') || keywords.includes('大胆')) {
    return { primary: 'rose', neutral: 'slate', accent: 'fuchsia' };
  }
  if (keywords.includes('dark') || keywords.includes('暗色') || keywords.includes('cinematic')) {
    return { primary: 'indigo', neutral: 'zinc', accent: 'violet' };
  }

  // 默认：技术蓝灰
  return { primary: 'blue', neutral: 'slate', accent: 'sky' };
}
