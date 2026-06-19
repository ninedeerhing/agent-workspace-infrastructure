# Worker 工作汇报 · designer

更新时间：2026-06-19T08:15:00Z

## Tick designer-ui-a-2-spec

- **任务 ID**：PL-C-UI-A · UI-A-2 侧栏 accent / spacing / 响应式 / CJK 行高
- **任务树**：PL-C-UI-A（foreground · loop24）
- **动作**：设计 + executor 落地最小 UI-A-2 增量
- **设计规范**：
  - 侧栏激活：`--rd-sidebar-accent-width: 2px` + `.rd-sidebar-item--active` / `.rd-sidebar-thread-row--active` 左侧 accent 线
  - 间距语义：`--rd-space-message-inner: 20px` · `--rd-space-message-outer: 32px`
  - 响应式：`<768px` overlay + auto-collapse · `768–1023` 可收起 · `≥1024` 常驻
  - CJK：`.rd-prose` 默认 1.7 · `.rd-prose--cjk` / `:lang(zh*)` → 1.85
- **涉及文件**：
  - `web/src/styles/{tokens,shell,prose}.css`
  - `web/src/components/layout/{AppShell,SidebarNav}.tsx`
  - `web/src/components/chat/{ChatThreadPanel,MessageRow,MessageList}.tsx`
  - `web/src/context/ShellLayoutContext.tsx`
  - `web/tailwind.config.ts`
  - `docs/ENGINEERING/design-tokens-rd.md` §9
- **验证**：`npm run lint && npm run build` **pass** · §5.322
- **状态**：**done**
- **下一动作**：Git 按树 commit

## Tick designer-mine6-lab-ia

- **任务 ID**：MINE-6 /lab 实验台 IA
- **任务树**：PL-C-MINE（遵循 PL-C-UI-A token）
- **动作**：四 Tab IA 对齐 master-plan §改造6 — 挖矿 / 因子库 / 回测 / 设置；只读 snapshot 驱动
- **涉及文件**：`web/src/pages/LabPage.tsx`（executor 落地）
- **验证**：npm build pass · Tab 切换 + stage badge + settings grid
- **状态**：done（MVP v1 · OOS 曲线/Bandit 写操作留 MINE-7+）
- **更新时间**：2026-06-19T18:00:00Z

## Tick designer-ui-a1-motion-spec

- **任务 ID**：PL-C-UI-A · UI-A-1 动画模块 ①–⑦
- **任务树**：PL-C-UI-A（并行 · 不阻塞 PL-C-GEN R1-M5）
- **动作**：调研 `web/src` 现有 motion.css / MessageRow / ToolCallCard / SidebarNav；输出 executor 可执行的动效设计规范
- **涉及文件**：
  - `docs/ENGINEERING/design-tokens-rd.md` §6（扩展 ①–⑦ + FSM + follow-up）
  - `docs/UI-STYLE-FOR-AI.md` §6.2（同步场景表）
  - executor 落地：`motion.css` · `MessageList.tsx` · `MessageRow.tsx` · `ToolCallCard.tsx` · `ConfirmationCard.tsx` · `ClarifyCard.tsx` · `SidebarNav.tsx` · `ShellLayoutContext.tsx` · `StreamingStateIndicator.tsx` · `lib/streamingVisualState.ts`
- **验证**（executor §5.304）：`npm run lint && npm run build` **pass** · 浏览器 `:5273` 对照 → qa-tester
- **状态**：**design + impl done**
- **更新时间**：2026-06-19T16:45:00Z

## 现状 gap 摘要（已全部关闭）

| 模块 | 原状 | 目标 | 状态 |
|------|------|------|------|
| ① | 无 stagger | `data-stagger` 0.05/0.18/0.32s | ✅ |
| ② | footer 固定 orbit；与 cursor 可能重叠 | FSM 互斥 JS | ✅ |
| ③ | `{open && …}` 条件挂载；文字「展开」 | max-height 0→400px + chevron 180° | ✅ |
| ④ | 复用 message-enter 180ms | 独立 confirm-enter 150ms scale | ✅ |
| ⑤ | width 200ms 并行 | opacity 100ms → width 200ms 串行 | ✅ |
| ⑥ | color-mix + ease-in-out fade | solid `--rd-accent` + step-end | ✅ |
| ⑦ | 部分 class 未覆盖 | 扩展 reduce 块 | ✅ |

## ⑧⑨ follow-up

任务树 **无** 用户 spec 编号 ⑧⑨ 动画模块。PL-C-UI-A Phase UI-A-1/2 相关后续：

- ChatThreadPanel sequenced collapse（同 ⑤）
- ToolCallCard 折叠摘要（improvement-guide §5.2）
- 附件 upload pulse · hover 分层（§5.3 · §6.1）

## 浏览器验证清单（:5273）

1. **`/story`** — MessageList thinking：发送 mock 后仅见 **三点**（waiting），非 orbit
2. **`/chat`** — 流式回复：assistant 正文见 **陶土橙 step-end 光标**；tool running 时 footer **orbit**、无光标+orbit 同屏
3. **`/story` ToolCallCard** — 展开/收起 **平滑 max-height**；chevron 旋转 180°
4. **`/story` ConfirmationCard** — 进入 **快于消息** 的 scale pop（150ms）
5. **主导航收起** — 文字先淡出再变窄（非同时）
6. **DevTools → Rendering → Emulate prefers-reduced-motion** — 全部动画静止

## loop-state

UI-A-2 **done** · `next_atomic_action` → Git 按树 commit（§5.322）
