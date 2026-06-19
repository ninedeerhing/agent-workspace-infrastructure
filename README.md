# Raindeer Skills

本项目包含从 Superpowers 框架提取的技能集合。

## 项目结构

```
e:\raindeer/
└── skills/              # 所有技能目录
    ├── brainstorming/   # 头脑风暴技能
    ├── test-driven-development/  # 测试驱动开发技能
    ├── systematic-debugging/     # 系统调试技能
    ├── writing-skills/  # 如何编写技能的技能
    └── ...              # 其他技能
```

## 技能列表

### 测试相关

- **test-driven-development** - RED-GREEN-REFACTOR 测试驱动开发流程

### 调试相关

- **systematic-debugging** - 系统调试方法
- **verification-before-completion** - 完成前验证

### 协作相关

- **brainstorming** - 苏格拉底式设计细化
- **writing-plans** - 详细实施计划
- **executing-plans** - 带检查点的批量执行
- **dispatching-parallel-agents** - 并发子代理工作流
- **requesting-code-review** - 预审核清单
- **receiving-code-review** - 响应反馈
- **using-git-worktrees** - 并行开发分支
- **finishing-a-development-branch** - 合并/PR 决策流程
- **subagent-driven-development** - 快速迭代与两阶段审核

### 元技能

- **writing-skills** - 按照最佳实践创建新技能
- **using-superpowers** - 技能系统介绍

## 如何添加新技能

1. 在 `skills/` 目录下创建新的文件夹（使用连字符命名，如 `your-skill-name`）
2. 创建 `SKILL.md` 文件，包含必要的 YAML 前置元数据和内容
3. 如需支持文件，放在同一文件夹内

## SKILL.md 格式示例

```markdown
---
name: your-skill-name
description: Use when [描述使用场景]
---

# Your Skill Name

## Overview

技能概述

## When to Use

何时使用

## Core Pattern

核心模式

## Implementation

实现细节
```

## 参考

原始项目: https://github.com/obra/superpowers
