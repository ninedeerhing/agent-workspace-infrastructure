# ADR-004: 集成来源优先级体系

**状态:** accepted  
**日期:** 2026-06-09  
**决策者:** AWI Harness 系统

---

## 背景

AWI 需要从 12 个来源项目中整合最佳实践。这些项目各自有独立的方法论、术语和约定，直接混合会导致冲突和混乱。需要一个明确的优先级框架来决策"当两个方法论冲突时，以谁为准"。

## 决策内容

**建立分层集成优先级体系，以 learn-harness-engineering 为核心框架，其他项目按领域填充。**

```
优先级 1 (核心框架): learn-harness-engineering
优先级 2 (技能方法): superpowers
优先级 3 (产品流程): gstack
优先级 4 (安全规则): ECC
优先级 5 (约束规则): andrej-karpathy-skills
优先级 6 (参考层): oh-my-codex, oh-my-openagent, caveman, rtk, headroom, reasonix
```

### 各层职责分工

| 优先级 | 来源 | 角色 | 贡献内容 |
|--------|------|------|----------|
| 1 | learn-harness-engineering | 核心框架 | 五子系统架构（Instructions / State / Verification / Scope / Lifecycle）、Harness 目录规范 |
| 2 | superpowers | 技能方法 | TDD 强制流程、代码审查协议、子代理开发、Git Worktree、技能优先方法论 |
| 3 | gstack | 产品流程 | YC Office Hours 产品审查、CEO/Eng/Design 专家审查链路、Ship Release 发布流程 |
| 4 | ECC | 安全规则 | 安全审查体系、Prompt Defense Baseline、多语言规则库 |
| 5 | andrej-karpathy-skills | 约束规则 | 少假设、少过度设计、手术式修改、目标驱动验证 |
| 6 | 其他 6 个来源 | 参考增益 | Token 压缩策略、自主代理工作流、持久目标追踪、跨代理安全基线 |

## 理由

1. **learn-harness-engineering 提供最完整的理论框架** — 五子系统覆盖操作契约、状态管理、验证、范围控制、生命周期，是唯一提供"如何搭建工程体系"的单元
2. **superpowers 的 TDD 方法论经过大量实战验证** — Red-Green-Refactor 循环是多个顶级代理工具的共同选择
3. **gstack 填补了"从需求到产品"的流程空白** — 商业判断（CEO Review）、技术判断（Eng Review）、设计判断（Design Review）三视角审查
4. **ECC 的安全体系不可替代** — OWASP Top 10 覆盖 + 代理特有安全问题 + Prompt Defense Baseline
5. **Karpathy 的约束规则作为最后一道过滤器** — 防止过度设计和盲目抽象
6. **余下 6 个来源作为"增益层"而非"基础层"** — 可在不破坏核心架构的前提下灵活采用或替换

## 冲突裁决规则

当不同来源的方法论冲突时，按以下规则裁决：

1. **高优先级 > 低优先级** — 显式冲突时取高层
2. **TDD 不可妥协** — 无论任何来源都不能推翻"先写测试再写实现"的铁律
3. **安全不可降级** — 安全规则只能加强不能减弱
4. **简单优先** — 当两个方案信息密度和正确性相当时，选择更简单的方案

## 后果

- **正面**：新从业者只需理解 5 层优先级即可知道"该听谁的"
- **正面**：新增外部来源时，只需确定其所属优先级即可吸收
- **正面**：冲突有明确的裁决依据，不会陷入"两种都好的好"的无尽讨论
- **负面**：6 个"增益层"来源的贡献度可能被低估
- **负面**：需要持续维护各来源的最新版本变更

## 备选方案

### 方案 A：平等混合
所有 12 个来源完全平等，遇冲突时人工裁决。
**不采纳原因**：实践中不可行——12 个来源的冲突规模是指数级的。

### 方案 B：仅用 learn-harness-engineering + superpowers
砍掉其他 10 个来源，极简主义。
**不采纳原因**：过于激进，gstack 的产品链路和 ECC 的安全体系是不可替代的。

### 方案 C：按 GitHub Stars 数量排序
谁更流行听谁的。
**不采纳原因**：Stars 反映流行度而非方法论适配性，且许多来源是刚发布的创新项目。

## 相关记录

- [ADR-001](ADR-001-harness-engineering-methodology.md) — 方法论选型（why Harness）
- [ADR-002](ADR-002-markdown-for-adr.md) — ADR 格式选型
- progress.md — 决策 2：集成来源优先级
