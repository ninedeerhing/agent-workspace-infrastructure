---
name: using-git-worktrees
description: 在需要隔离的开发环境时使用。触发条件：开始一个新功能、需要并行处理多个任务、需要与当前工作区隔离。
---

# Using Git Worktrees — 使用 Git 工作树

## 定位

在开始实现前，确保代码修改在隔离的环境中执行。优先级：IDE原生隔离 → Git Worktree → 手动分支。

## 触发条件

- 开始一个新功能开发
- 需要并行处理多个任务
- 需要与当前工作区完全隔离
- `brainstorming` 或 `writing-plans` 完成后准备执行

## 环境检测与使用策略

### 第 1 步：检测现有隔离能力

先检查当前使用的编辑器/IDE 是否已经有工作区隔离能力：
- VS Code: 多窗口工作区
- Cursor: Agent 工作区
- Claude Code: Task 隔离
- JetBrains: 多项目窗口

**如果已有原生隔离**：优先使用原生隔离。

### 第 2 步：使用 Git Worktree

```bash
git worktree add ../project-feature-xxx feature/xxx
git worktree list
git worktree remove ../project-feature-xxx
```

**Worktree 隔离原则**：
- 每个功能一个 worktree
- worktree 目录命名为 `project-{feature-name}`
- 完成后立即清理

## 反模式 / 红牌

| 反模式 | 说明 |
|--------|------|
| 不隔离直接开发 | 黄牌。除非任务极其简单 |
| 忘记清理 worktree | 黄牌。完成后必须清理 |
| 多个功能共用 worktree | 红牌。一个 worktree 一个功能 |
| 在 worktree 中修改共享状态 | 红牌。worktree 应完全独立 |
