---
name: autopilot
description: 全自主开发流水线，从需求到部署零人工干预。触发条件：需要端到端自动化实现一个完整功能。
---

# Autopilot — 全自主开发流水线

## 定位

完整的端到端自主开发流水线：deep-interview → ralplan → 执行 → QA → 验证 → 交付。适合明确需求的全功能开发。

## 触发条件

- 需要实现一个完整的、边界清晰的功能
- 需求已在高层面上明确
- 适合自动化端到端交付

## 流水线阶段

### 阶段 1：Deep Interview

- 如果需求不够清晰，先进行深度访谈
- 确认功能边界、成功标准、非目标

### 阶段 2：Ralplan 共识规划

- Planner → Architect → Critic 三角循环
- 产出 ADR 和技术方案

### 阶段 3：执行

- 使用 `subagent-driven-dev` 或 `executing-plans`
- 遵循 TDD 实现
- 代码审查

### 阶段 4：QA 测试

- 加载 `qa-testing` 技能
- 执行全量测试或差异感知测试

### 阶段 5：验证

- 加载 `verification-before-completion`
- 提供完整的验证证据

### 阶段 6：交付

- 加载 `finishing-dev-branch`
- 合并或创建 PR

## 中断条件

在以下情况自动暂停，等待人工决策：
- 架构验证失败
- Critical 安全问题
- 测试持续失败无法修复
- 需要人工判断的 tradeoff

## 反模式 / 红牌

| 反模式 | 说明 |
|--------|------|
| 跳过 deep-interview | 黄牌。需求不清晰时不能跳过 |
| 跳过 ralplan | 黄牌。复杂功能需要规划 |
| 不处理中断 | 红牌。中断条件触发时必须暂停 |
| 隐瞒问题继续 | 红牌。任何阶段失败必须上报 |
