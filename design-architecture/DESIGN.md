# DESIGN.md — 前端设计底层架构 · 设计令牌文档

> 遵循 [Google Stitch DESIGN.md](https://stitch.withgoogle.com/docs/design-md/overview/) 规范
> 兼容 [awesome-design-md](https://github.com/VoltAgent/awesome-design-md) 生态
> AI 代理直接读取此文件以生成一致的 UI

## Design Identity

- **设计风格**: 现代极简 · 功能优先 · 精确克制
- **目标受众**: 开发者工具 / SaaS 产品 / 技术品牌
- **情感调性**: 专业、可信赖、高效、冷静中带有温度
- **反参考**: 避免 AI Slop（Inter 字体 / 紫色渐变 / 居中卡片堆叠）

---

## Color System

### Brand Colors

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `--color-brand` | `#2563EB` | `#3B82F6` | 主品牌色 · CTA · 链接 |
| `--color-brand-muted` | `#DBEAFE` | `#1E3A5F` | 品牌色背景 · 选中态 |
| `--color-brand-subtle` | `#EFF6FF` | `#0F1F3D` | 品牌色淡底 |

### Neutral Colors (OKLCH Tinted)

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `--color-bg` | `#FFFFFF` | `#0A0A0B` | 页面背景 |
| `--color-bg-secondary` | `#F8F9FA` | `#131415` | 次级背景 |
| `--color-surface` | `#FFFFFF` | `#1A1B1D` | 卡片/面板 |
| `--color-border` | `#E2E4E9` | `#2A2B2E` | 边框 |
| `--color-border-hover` | `#C8CBD3` | `#3A3B3F` | 悬停边框 |
| `--color-text-primary` | `#111214` | `#EDEDEF` | 主文字 |
| `--color-text-secondary` | `#5E6068` | `#9A9BA0` | 次级文字 |
| `--color-text-tertiary` | `#8B8D95` | `#6B6C72` | 辅助文字 |

### Semantic Colors

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `--color-success` | `#16A34A` | `#22C55E` | 成功 |
| `--color-warning` | `#D97706` | `#F59E0B` | 警告 |
| `--color-error` | `#DC2626` | `#EF4444` | 错误 |
| `--color-info` | `#2563EB` | `#3B82F6` | 信息 |

---

## Typography

### Font Stack

| Role | Font | Weight | Usage |
|------|------|--------|-------|
| Display | `'Geist', system-ui, sans-serif` | 500-700 | 大标题 · Hero |
| Heading | `'Geist', system-ui, sans-serif` | 600 | H1-H6 |
| Body | `'Geist', system-ui, sans-serif` | 400 | 正文 |
| Code | `'Geist Mono', 'JetBrains Mono', monospace` | 400 | 代码 |

### Type Scale (Major Third · 1.25)

| Step | Size | Line Height | Letter Spacing | Usage |
|------|------|-------------|----------------|-------|
| `xs` | 0.75rem (12px) | 1.5 | 0.01em | 辅助信息 · 标签 |
| `sm` | 0.875rem (14px) | 1.5 | 0 | 次级正文 |
| `base` | 1rem (16px) | 1.6 | -0.01em | 正文默认 |
| `lg` | 1.125rem (18px) | 1.55 | -0.01em | 强调正文 |
| `xl` | 1.25rem (20px) | 1.5 | -0.02em | H4 |
| `2xl` | 1.5rem (24px) | 1.4 | -0.02em | H3 |
| `3xl` | 1.875rem (30px) | 1.3 | -0.03em | H2 |
| `4xl` | 2.25rem (36px) | 1.2 | -0.03em | H1 |
| `5xl` | 3rem (48px) | 1.1 | -0.04em | Hero Title |
| `6xl` | 3.75rem (60px) | 1.05 | -0.04em | Landing Hero |

---

## Spacing (8px Base Grid)

| Token | Value | Usage |
|-------|-------|-------|
| `--space-0` | 0 | 无间距 |
| `--space-1` | 4px | 极小间距 · Icon-Text |
| `--space-2` | 8px | 紧凑间距 |
| `--space-3` | 12px | 元素内间距 |
| `--space-4` | 16px | 默认间距 |
| `--space-5` | 20px | 中等间距 |
| `--space-6` | 24px | 段落间距 |
| `--space-8` | 32px | Section 内间距 |
| `--space-10` | 40px | 大间距 |
| `--space-12` | 48px | Section 间距 |
| `--space-16` | 64px | 页面级间距 |
| `--space-20` | 80px | Hero 间距 |
| `--space-24` | 96px | 超大间距 |

---

## Shadows

| Token | Value | Usage |
|-------|-------|-------|
| `--shadow-none` | `none` | 无阴影 |
| `--shadow-xs` | `0 1px 2px rgba(0,0,0,0.04)` | 微妙提升 |
| `--shadow-sm` | `0 1px 3px rgba(0,0,0,0.06), 0 1px 2px rgba(0,0,0,0.04)` | 卡片 |
| `--shadow-md` | `0 4px 6px rgba(0,0,0,0.05), 0 2px 4px rgba(0,0,0,0.04)` | 下拉菜单 |
| `--shadow-lg` | `0 10px 15px rgba(0,0,0,0.06), 0 4px 6px rgba(0,0,0,0.04)` | 模态框 |
| `--shadow-xl` | `0 20px 25px rgba(0,0,0,0.08), 0 8px 10px rgba(0,0,0,0.04)` | 弹出层 |

---

## Border Radius

| Token | Value | Usage |
|-------|-------|-------|
| `--radius-none` | 0 | 无圆角 |
| `--radius-sm` | 4px | 小元素 · Tag |
| `--radius-md` | 6px | 按钮 · Input |
| `--radius-lg` | 8px | 卡片 · 模态框 |
| `--radius-xl` | 12px | 大卡片 |
| `--radius-2xl` | 16px | 面板 |
| `--radius-full` | 9999px | 圆形 · Pill |

---

## Breakpoints

| Token | Value | Target |
|-------|-------|--------|
| `--bp-sm` | 640px | 手机横屏 |
| `--bp-md` | 768px | 平板 |
| `--bp-lg` | 1024px | 小桌面 |
| `--bp-xl` | 1280px | 桌面 |
| `--bp-2xl` | 1536px | 大桌面 |

---

## Motion Tokens

| Token | Value | Usage |
|-------|-------|-------|
| `--duration-instant` | 100ms | 即时反馈 |
| `--duration-fast` | 200ms | Hover · Focus |
| `--duration-normal` | 300ms | 过渡 · 切换 |
| `--duration-slow` | 500ms | 页面转场 |
| `--duration-deliberate` | 700ms | 强调动画 |
| `--ease-default` | `cubic-bezier(0.16, 1, 0.3, 1)` | 默认缓动 |
| `--ease-spring` | `cubic-bezier(0.34, 1.56, 0.64, 1)` | 弹性效果 |
| `--ease-out` | `cubic-bezier(0, 0, 0.2, 1)` | 出场 |
| `--ease-in` | `cubic-bezier(0.4, 0, 1, 1)` | 入场 |

---

## Component Patterns

### Button
- 最小高度 40px（触控友好）
- 内边距 12px-20px（水平）
- `--radius-md` 圆角
- Focus ring: 2px offset, brand color
- 3 变体: Primary · Secondary · Ghost

### Input
- 高度 40px
- 内边距 8px-12px
- 边框 1px `--color-border`
- Focus: border → `--color-brand`, ring 2px `--color-brand-muted`

### Card
- `--radius-lg` 圆角
- `--shadow-sm` 阴影
- `--color-surface` 背景
- 内边距 `--space-6`（24px）

---

## Anti-Slop Rules

以下模式在生成 UI 时**必须避免**：

1. ❌ 不使用 **Inter 字体**（默认 AI Slop 字体）→ 使用 Geist
2. ❌ 不使用 **紫色到蓝色渐变**（AI 模板标志）→ 使用品牌色系
3. ❌ 不使用 **居中排列的三列图标卡片**（模板 Hero 模式）
4. ❌ 不使用 **灰色文字叠在彩色背景上**
5. ❌ 不使用 **纯黑色（#000）或纯白色（#FFF）**→ 使用 off-black/off-white
6. ❌ 不使用 **Emoji 作为图标**→ 使用 Phosphor 或 Radix 图标
7. ❌ 不使用 **h-screen** → 使用 `min-h-[100dvh]`
8. ❌ 不使用 **复杂 flexbox 百分比数学** → 使用 CSS Grid
9. ❌ 不使用 **超过 60ch 的正文宽度**（阅读性差）
10. ❌ 不出现 **Lorem Ipsum** 占位文本
