/**
 * L5 · AI Design Intelligence 层 — 设计命令系统
 *
 * 定义 23 个设计命令，对应 Impeccable 的命令体系和 Taste Skill 的质量门禁。
 * 每个命令映射到一个设计维度，可被 AI 代理调用或通过程序化方式触发。
 */

import type { DesignCommand, DesignDimension } from '../../core/types';

/** 完整的 23 个设计命令定义 */
export const DESIGN_COMMANDS: DesignCommand[] = [
  {
    name: 'craft',
    description: '从设计规划到构建的完整流程 — 先塑形 UX，加载正确参考，构建并迭代到满意的结果。',
    aliases: ['create', 'build'],
    useCases: ['新建页面', '构建完整功能', '从零开始设计'],
    dimension: 'spatial',
  },
  {
    name: 'teach',
    description: '一次性设置命令 — 扫描代码库，访谈品牌和受众，保存设计上下文供所有后续命令使用。',
    aliases: ['init', 'setup', 'context'],
    useCases: ['项目初始化', '新成员加入', '设计系统梳理'],
    dimension: 'spatial',
  },
  {
    name: 'document',
    description: '生成规范兼容的 DESIGN.md，捕获视觉系统，确保所有 AI 代理保持在品牌调性内。',
    aliases: ['spec', 'doc'],
    useCases: ['生成设计文档', '设计交接', '团队对齐'],
    dimension: 'spatial',
  },
  {
    name: 'extract',
    description: '从现有代码中提取可复用组件、令牌和模式到设计系统中。',
    aliases: ['refactor', 'componentize'],
    useCases: ['设计系统建设', '重构', '组件提取'],
    dimension: 'spatial',
  },
  {
    name: 'live',
    description: '在浏览器中实时迭代 UI — 选择元素、添加评论、获取三个变体、接受一个并写入源码。',
    aliases: ['iterate', 'preview'],
    useCases: ['实时预览', 'A/B 测试', '快速迭代'],
    dimension: 'interaction',
  },
  {
    name: 'adapt',
    description: '使设计适配不同屏幕、设备和上下文，不做功能截肢。',
    aliases: ['responsive', 'mobile'],
    useCases: ['响应式设计', '移动端适配', '多端统一'],
    dimension: 'responsive',
  },
  {
    name: 'animate',
    description: '有目的的动效 — 传递状态变化，而非装饰性抖动。',
    aliases: ['motion', 'transition'],
    useCases: ['添加动效', '状态过渡', '页面转场'],
    dimension: 'motion',
  },
  {
    name: 'audit',
    description: '五维度技术质量检查（P0-P3 严重程度），导向 harden/optimize/adapt/clarify。',
    aliases: ['check', 'qa', 'review'],
    useCases: ['质量检查', '发布前审查', '可访问性审计'],
    dimension: 'interaction',
  },
  {
    name: 'bolder',
    description: '将安全保守的设计推向更有冲击力，但不超过混乱的边界。',
    aliases: ['intensify', 'amplify'],
    useCases: ['设计平淡', '需要视觉冲击', '品牌强化'],
    dimension: 'color',
  },
  {
    name: 'clarify',
    description: '重写令人困惑的 UX 文案，让界面自己会说话。',
    aliases: ['copy', 'writing', 'text'],
    useCases: ['UX 文案', '错误提示', '空状态文案'],
    dimension: 'ux-writing',
  },
  {
    name: 'colorize',
    description: '为单色界面添加战略性色彩，不过度鲜艳。',
    aliases: ['color', 'palette', 'hue'],
    useCases: ['色彩缺失', '品牌色应用', '视觉层次'],
    dimension: 'color',
  },
  {
    name: 'critique',
    description: '设计评审 — 评分、角色测试和自动检测，导向 polish/distill/bolder/quieter/typeset/layout。',
    aliases: ['review', 'feedback', 'eval'],
    useCases: ['设计评审', '同行审查', '上线前检查'],
    dimension: 'spatial',
  },
  {
    name: 'delight',
    description: '小而美的个性瞬间，将功能性转化为记忆点。',
    aliases: ['joy', 'charm', 'personality'],
    useCases: ['加载状态', '空状态', '成功反馈'],
    dimension: 'interaction',
  },
  {
    name: 'distill',
    description: '无情减法 — 将设计剥离到本质。',
    aliases: ['simplify', 'reduce', 'minimal'],
    useCases: ['设计过载', '简化界面', '信息架构'],
    dimension: 'spatial',
  },
  {
    name: 'harden',
    description: '使界面达到生产就绪 — 边界情况、国际化、错误状态、溢出处理。',
    aliases: ['production', 'edge-cases', 'robust'],
    useCases: ['上线准备', '边界情况', '错误处理'],
    dimension: 'interaction',
  },
  {
    name: 'onboard',
    description: '设计首次体验、空状态和通向价值的路径。',
    aliases: ['first-run', 'empty-state', 'welcome'],
    useCases: ['新手引导', '空状态设计', '激活流程'],
    dimension: 'ux-writing',
  },
  {
    name: 'layout',
    description: '修复布局、间距和视觉节奏。',
    aliases: ['arrange', 'spacing', 'grid'],
    useCases: ['布局混乱', '间距不均', '视觉节奏'],
    dimension: 'spatial',
  },
  {
    name: 'optimize',
    description: '诊断和修复 UI 性能 — 从 LCP 到 bundle 大小。',
    aliases: ['perf', 'speed', 'lighthouse'],
    useCases: ['性能优化', '加载速度', 'Core Web Vitals'],
    dimension: 'interaction',
  },
  {
    name: 'overdrive',
    description: '技术性强的效果 — shader、spring physics、scroll-driven reveals。',
    aliases: ['advanced', 'effects', 'impressive'],
    useCases: ['高级动效', 'WebGL', '创意表达'],
    dimension: 'motion',
  },
  {
    name: 'polish',
    description: '发布前的最终打磨 — 对齐、间距、细节。',
    aliases: ['finish', 'detail', 'final'],
    useCases: ['发布前打磨', '细节修正', '像素对齐'],
    dimension: 'spatial',
  },
  {
    name: 'quieter',
    description: '降低过于激进的设计，让界面更平静、更成熟。',
    aliases: ['calm', 'soften', 'subtle'],
    useCases: ['设计过于激进', '企业级调优', '降噪'],
    dimension: 'color',
  },
  {
    name: 'shape',
    description: '在编码前塑形 UX — 规划信息架构、用户流程和交互模式。',
    aliases: ['plan', 'wireframe', 'ux'],
    useCases: ['设计规划', 'UX 设计', '流程设计'],
    dimension: 'spatial',
  },
  {
    name: 'typeset',
    description: '修复字体选择、层次和字号，建立可读的排版系统。',
    aliases: ['font', 'typography', 'text-style'],
    useCases: ['字体混乱', '层次不清', '可读性'],
    dimension: 'typography',
  },
];

/** 按设计维度分组的命令映射 */
export const COMMANDS_BY_DIMENSION: Record<DesignDimension, DesignCommand[]> = {
  typography:   DESIGN_COMMANDS.filter(c => c.dimension === 'typography'),
  color:        DESIGN_COMMANDS.filter(c => c.dimension === 'color'),
  spatial:      DESIGN_COMMANDS.filter(c => c.dimension === 'spatial'),
  responsive:   DESIGN_COMMANDS.filter(c => c.dimension === 'responsive'),
  interaction:  DESIGN_COMMANDS.filter(c => c.dimension === 'interaction'),
  motion:       DESIGN_COMMANDS.filter(c => c.dimension === 'motion'),
  'ux-writing': DESIGN_COMMANDS.filter(c => c.dimension === 'ux-writing'),
};

/** 按名称查找设计命令 */
export function getDesignCommand(name: string): DesignCommand | undefined {
  return DESIGN_COMMANDS.find(
    c => c.name === name || c.aliases.includes(name),
  );
}

/** 核心工作流：推荐的命令执行顺序 */
export const WORKFLOW_SEQUENCES: Record<string, DesignCommand['name'][]> = {
  /** 全新项目流程 */
  newProject: ['teach', 'shape', 'craft', 'polish', 'audit'],
  /** 重构现有项目 */
  redesign: ['audit', 'critique', 'distill', 'typeset', 'layout', 'colorize', 'polish'],
  /** 添加新功能 */
  addFeature: ['shape', 'craft', 'animate', 'polish'],
  /** 发布前检查 */
  preRelease: ['audit', 'harden', 'optimize', 'polish', 'document'],
  /** 品牌升级 */
  rebrand: ['teach', 'extract', 'colorize', 'typeset', 'bolder', 'polish'],
};
