/**
 * L5 · AI Design Intelligence 层 — 反模式库
 *
 * 定义 AI 生成代码中应避免的模式，对应 Impeccable 的 curated anti-patterns
 * 和 Taste Skill 的 Anti-Slop 禁令。通过编程化检测 + AI 提示两种方式工作。
 */

import type { AntiPattern } from '../../core/types';

/**
 * 反模式注册表 — 包含 12 条核心反模式规则
 *
 * 每条规则包含：
 * - detectionPattern: 正则表达式，用于编程化检测代码中是否出现此模式
 * - severity: P0=必须修复, P1=强烈建议, P2=一般, P3=可选
 * - remediation: 修复建议
 */
export const ANTI_PATTERNS: AntiPattern[] = [
  {
    id: 'AP-001',
    name: 'Inter 字体依赖',
    description: 'AI 生成代码默认使用 Inter 字体，导致所有输出看起来雷同。应使用 Geist、Satoshi、Outfit 等更具辨识度的字体。',
    severity: 'P1',
    detectionPattern: /font-family:\s*['"]?Inter['"]?|fontFamily:\s*['"]Inter['"]|['"]Inter['"]/gi,
    remediation: '替换为 Geist 或 Satoshi 等品牌字体，搭配 Geist Mono 或 JetBrains Mono 作为等宽字体。',
  },
  {
    id: 'AP-002',
    name: '紫色到蓝色渐变',
    description: 'from-purple-* to-blue-* 渐变是 AI 生成的标志性模板，缺乏品牌辨识度。',
    severity: 'P1',
    detectionPattern: /from-purple-\d+|to-blue-\d+|bg-gradient-to-r.*purple|#8B5CF6.*#[0-9A-Fa-f]+/gi,
    remediation: '使用品牌色系的渐变，或使用纯色 + 微妙的阴影和边框来替代渐变。',
  },
  {
    id: 'AP-003',
    name: '三列居中图标卡片',
    description: 'grid grid-cols-3 + 居中图标 + 标题 + 描述的 Hero 布局是 AI 模板的经典模式。',
    severity: 'P2',
    detectionPattern: /grid-cols-3.*justify-center|text-center.*grid-cols-3|md:grid-cols-3.*mx-auto/gi,
    remediation: '考虑非对称布局、交错排列、或使用 Bento Grid 风格的卡片布局取而代之。',
  },
  {
    id: 'AP-004',
    name: '灰色文字在彩色背景上',
    description: 'text-gray-* 叠加在有色背景上违反 WCAG 对比度要求且视觉效果差。',
    severity: 'P0',
    detectionPattern: /text-gray-\d+.*bg-\w+-\d+|bg-\w+-\d+.*text-gray-\d+/gi,
    remediation: '在彩色背景上使用白色（dark backgrounds）或深色文字（light backgrounds），确保对比度 >= 4.5:1。',
  },
  {
    id: 'AP-005',
    name: '纯黑或纯白色',
    description: '#000000 和 #FFFFFF 在屏幕上过于刺眼，应使用 off-black/off-white 替代。',
    severity: 'P1',
    detectionPattern: /#[0]{6}|#[F]{6}|bg-black(?!\/)|text-white(?!\/)|bg-white(?!\/)|text-black(?!\/)/gi,
    remediation: '使用 off-black (#0A0A0B) 和 off-white (#F8F9FA)，提升视觉舒适度。',
  },
  {
    id: 'AP-006',
    name: 'Emoji 作为图标',
    description: '使用 Emoji 作为 UI 图标在不同平台上渲染不一致，显得不专业。',
    severity: 'P2',
    detectionPattern: /[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{27BF}]|[\u{1F600}-\u{1F64F}]/gu,
    remediation: '使用 Phosphor Icons 或 Radix Icons 等专业图标库，确保渲染一致性。',
  },
  {
    id: 'AP-007',
    name: 'h-screen 全屏高度',
    description: 'h-screen 在 iOS Safari 上由于地址栏折叠导致布局跳动。',
    severity: 'P0',
    detectionPattern: /h-screen(?!\s*\/\/.*ok)|className=.*['"]h-screen['"]/gi,
    remediation: '使用 min-h-[100dvh] 或 min-h-svh 替代 h-screen，避免移动端视口问题。',
  },
  {
    id: 'AP-008',
    name: '复杂 Flexbox 百分比计算',
    description: 'w-[calc(33%-1rem)] 等复杂的 flexbox 数学计算脆弱且难以维护。',
    severity: 'P2',
    detectionPattern: /w-\[calc\(|flex.*w-\[calc\(/gi,
    remediation: '使用 CSS Grid（grid grid-cols-1 md:grid-cols-3 gap-6）替代 flexbox 百分比计算。',
  },
  {
    id: 'AP-009',
    name: '超过 60ch 的正文宽度',
    description: '超过 60 个字符宽度的文本行会降低阅读速度和理解力。',
    severity: 'P2',
    detectionPattern: /max-w-\w+.*prose|max-w-[67-9]\d|max-w-[7-9]\d\d/gi,
    remediation: '正文容器限制为 max-w-prose（约 65ch），或显式设置 max-w-[65ch]。',
  },
  {
    id: 'AP-010',
    name: 'Lorem Ipsum 占位文本',
    description: 'Lorem Ipsum 占位文本使设计评审无法判断真实内容的适配情况。',
    severity: 'P1',
    detectionPattern: /lorem\s*ipsum/gi,
    remediation: '使用与领域相关的真实或模拟内容。对于国际化场景，使用更长的占位文本（德语等）。',
  },
  {
    id: 'AP-011',
    name: '过度玻璃态效果',
    description: 'backdrop-blur + bg-opacity 的玻璃态效果被过度使用，且在高对比度场景下可读性差。',
    severity: 'P2',
    detectionPattern: /backdrop-blur-\w+.*bg-opacity-\d+|glass/gi,
    remediation: '仅在导航栏等少量场景使用玻璃态，大多数场景使用纯色背景 + 微妙阴影。',
  },
  {
    id: 'AP-012',
    name: '无 Focus 样式',
    description: '缺少 :focus-visible 样式会严重损害键盘导航的可访问性。',
    severity: 'P0',
    detectionPattern: /outline-none(?!.*focus)/gi,
    remediation: '始终为交互元素添加 focus-visible:ring-2 focus-visible:ring-brand focus-visible:ring-offset-2 样式。',
  },
];

/**
 * 对代码字符串进行反模式检测
 *
 * @param code - 要检测的代码字符串
 * @returns 命中的反模式列表及匹配位置
 */
export interface AntiPatternHit {
  pattern: AntiPattern;
  matches: string[];
}

export function detectAntiPatterns(code: string): AntiPatternHit[] {
  const hits: AntiPatternHit[] = [];

  for (const pattern of ANTI_PATTERNS) {
    // Emoji 检测使用 unicode 正则，需要重置 lastIndex
    pattern.detectionPattern.lastIndex = 0;
    const matches = code.match(pattern.detectionPattern);

    if (matches && matches.length > 0) {
      hits.push({
        pattern,
        matches: [...new Set(matches)], // 去重
      });
    }
  }

  return hits;
}

/**
 * 生成反模式检测报告
 *
 * @param hits - detectAntiPatterns 的返回结果
 * @returns 格式化的报告字符串，可直接作为 AI 提示的一部分
 */
export function generateAntiPatternReport(hits: AntiPatternHit[]): string {
  if (hits.length === 0) {
    return '✅ 未检测到反模式。代码符合设计规范。';
  }

  const lines: string[] = ['## 反模式检测报告', ''];
  const severityLabels: Record<string, string> = {
    P0: '🔴 阻塞',
    P1: '🟠 严重',
    P2: '🟡 一般',
    P3: '🔵 建议',
  };

  for (const hit of hits) {
    lines.push(`### ${severityLabels[hit.pattern.severity]} ${hit.pattern.name} (${hit.pattern.id})`);
    lines.push(`- **问题**: ${hit.pattern.description}`);
    lines.push(`- **匹配内容**: \`${hit.matches.join('`, `')}\``);
    lines.push(`- **修复**: ${hit.pattern.remediation}`);
    lines.push('');
  }

  return lines.join('\n');
}

/**
 * 获取反模式提示文本 — 用于注入到 AI prompt 中
 */
export function getAntiPatternPrompt(): string {
  const criticalPatterns = ANTI_PATTERNS.filter(p => p.severity === 'P0' || p.severity === 'P1');
  const lines: string[] = [
    '## ⚠️ 设计反模式 — 必须避免',
    '',
    '以下模式在生成 UI 代码时**必须避免**：',
    '',
  ];

  for (const pattern of criticalPatterns) {
    lines.push(`- **${pattern.name}**: ${pattern.description} → ${pattern.remediation}`);
  }

  return lines.join('\n');
}
