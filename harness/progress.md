# Progress — AWI 会话连续性日志

> 本文件是人类可读的项目进度日志。每次会话结束后更新。记录完成内容、进行中内容、阻塞项和决策。

---

## Current State（项目当前状态）

**日期：** 2026-06-09

**项目阶段：** 基础建设完成，进入运营阶段。

AWI 的 Harness 工程系统已完整搭建。基于 learn-harness-engineering 的五子系统设计（Instructions、State、Verification、Scope、Lifecycle），所有核心基础设施已就绪：

- **Instructions 子系统**：AGENTS.md（代理指令主入口）、SOUL.md（核心身份）、RULES.md（规则契约）构成完整指令链。
- **State 子系统**：harness/ 目录承载 feature_list.json（功能状态真相来源）、progress.md（本文档）、session-handoff.md（会话交接）。
- **Verification 子系统**：init.ps1（启动验证脚本）、clean-state-checklist.md（状态检查清单）、包含 lint/typecheck/test 的多层验证体系。
- **Scope 子系统**：AGENTS.md 中的委派规则和代理分层控制任务边界；feature_list.json 中的依赖关系控制功能边界。
- **Lifecycle 子系统**：标准工作流（INTAKE → RESEARCH → PLAN → EXECUTE → REVIEW → VERIFY → HANDOFF）、复杂任务流、产品/创业流、TDD 流。

已完成的 8 个功能模块（feat-001 至 feat-008）覆盖了 harness 基础架构、技能库、代理角色体系、缓存策略、规则体系、安全防御体系、工作流状态与门禁系统和历史交接归档机制。

---

## What's Done（已完成）

### feat-001: Harness 基础架构 ✅

- 创建 `harness/` 目录及以下文件：
  - `feature_list.json` — JSON 格式的功能状态追踪器，项目功能的唯一真相来源
  - `progress.md` — 本文件，人类可读的进度日志
  - `session-handoff.md` — 会话交接模板，支持跨会话连续工作
  - `init.ps1` — Windows PowerShell 启动验证脚本
  - `clean-state-checklist.md` — 干净状态检查清单

- 顶层协议文件已创建：
  - `AGENTS.md` — 代理指令主入口，14 条核心操作原则
  - `SOUL.md` — 核心身份与跨工具可移植性声明
  - `RULES.md` — 规则契约，10 条必须遵守 + 10 条禁止事项
  - `SECURITY.md` — 安全策略，Prompt Defense Baseline

- 五子系统设计已落地：
  - Instructions: AGENTS.md + SOUL.md + RULES.md
  - State: feature_list.json + progress.md + session-handoff.md
  - Verification: init.ps1 + clean-state-checklist.md
  - Scope: 委派规则 + 代理分层 + 功能依赖控制
  - Lifecycle: 标准/复杂/产品/TDD 四种工作流

### feat-002: 技能底座 ✅

- 技能目录 `skills/` 已创建，包含 12+ 核心技能：
  - `brainstorming`、`tdd`、`review`、`security-review`、`debug`、`refactor`、`test`、`docs`、`explore`、`research`、`deploy`、`plan`
- 每个技能遵循标准格式：YAML frontmatter + 触发条件 + 操作流程 + 输入要求 + 输出规范 + 验证标准 + 使用样例
- 技能来源整合：superpowers（TDD 方法论）、gstack（产品判断）、andrej-karpathy-skills（手术式修改）、Anthropics（代理协议）

### feat-003: 代理角色体系 ✅

- 代理目录 `agents/` 已创建，包含四层代理角色：
  - 规划层：`orchestrator`、`planner`、`architect`、`critic`
  - 执行层：`explore`、`researcher`、`executor`、`debugger`
  - 质量层：`test-engineer`、`verifier`、`code-reviewer`、`security-reviewer`
  - 产品层：`designer`、`qa-tester`、`writer`
- 每个代理定义遵循标准格式：YAML frontmatter + 职责边界 + 触发条件 + 交互协议
- 子代理协议已定义：最多 6 个并行子代理；继承当前仓库/模型设置

### feat-004: 命中缓存与省 Token 底架 ✅

- Token 优化技能已创建，覆盖以下策略：
  - `skills/caveman-token-compress` — 极限 Token 压缩通信协议（减少约 75% token 消耗）
  - 系统技能：`rtk-strategy`（推理-令牌-知识三阶段优化）、`headroom-strategy`（上下文压缩策略）、`reasonix-cache`（Prefix-Cache 稳定性策略）、`token-budget`（Token 预算综合管理）
  - 会话恢复：`session-handoff.md` 集成压缩与恢复流程
- 核心机制：上下文压缩（会话结束时压缩历史为摘要）、重复计算缓存（代码探索结果、测试结果）、路由决策缓存（代理选择策略）、agent-as-tool 复用

### feat-005: 规则与约束体系 ✅

- `RULES.md` 已创建，包含：
  - 10 条必须始终遵守的规则
  - 10 条绝对不能做的事（禁止事项）
  - 代理格式规范（YAML frontmatter + 内容规范）
  - 技能格式规范（目录结构 + YAML frontmatter + 内容规范）
  - 提交风格规范（Conventional Commits）
  - PR / 变更规范

- `AGENTS.md` 已创建，包含：
  - 14 条核心操作原则
  - 委派规则与子代理协议
  - 验证协议
  - 标准工作流（默认 / 复杂 / 产品 / TDD）
  - Prompt Defense Baseline（6 条不可协商规则）
  - 反过度设计规则（7 条）

### feat-006: 安全防御体系 ✅

- `SECURITY.md` 已创建，包含：
  - Prompt Defense Baseline（6 条规则）
  - 漏洞报告流程
  - 密钥处理指南（含 PowerShell 审计脚本）
  - 凭证泄露应急响应（5 步流程）
  - 外部内容安全护栏
  - 三不原则（不信任、不泄露、不越权）
  - 安全开发检查清单（提交前 + PR 前）
- 安全规则已集成到 RULES.md 和 AGENTS.md 中
- `.trae/rules/project_rules.md` 包含 Trae IDE 专用安全规则

### feat-007: 工作流状态与门禁系统 ✅

- `harness/workflow-state.json` 已创建，包含：
  - 活跃工作流追踪（类型、阶段、任务上下文）
  - 4 种工作流定义（标准、复杂、产品、TDD）及其阶段序列
  - 阶段门禁状态记录结构（gate_id、result、timestamp、verifier、details）
  - 验证日志数组
  - 使用说明（启动、更新、交接规则）

- `harness/workflow-gates.md` 已创建，包含：
  - 门禁系统概述（进入/退出门禁、检查点、判定结果类型）
  - 标准工作流门禁 7 条（G-STD-01 至 G-STD-07）
  - 复杂任务流门禁 5 条（G-CPX-01 至 G-CPX-05）
  - 产品/创业流门禁 8 条（G-PRD-01 至 G-PRD-08）
  - TDD 实现流门禁 8 条（G-TDD-01 至 G-TDD-08）
  - 门禁失败处理协议（失败分类、回退规则、记录格式）
  - 快速参考速查表
  - 与现有文件的配合说明

### feat-008: 历史交接归档机制 ✅

- `harness/archive/` 目录已创建，包含：
  - `store.ps1` — 归档引擎核心脚本，支持 8 种操作：
    - **new** — 创建时间点快照，捕获全部 harness/ 状态文件 + 生成 archive-meta.json 元数据
    - **list** — 列出所有归档，按时间倒序，显示 ID、时间、文件数、原因
    - **info** — 查看指定归档的详细信息（元数据、文件清单及大小）
    - **restore** — 从归档还原状态文件，支持 `-DryRun` 试运行和 `-BackupFirst` 安全备份
    - **remove** — 删除归档（需 `-ConfirmRemove` 确认），同时清理索引
    - **compare** — 比较两个归档之间的文件差异（基于 MD5 哈希）
    - **verify** — 验证所有（或指定）归档的完整性（目录存在、文件非空）
    - **cleanup** — 清理过期归档，保留最近 N 个
  - `index.json` — 归档索引，追踪所有归档记录（ID、时间戳、目录、原因、文件列表）

- `harness/init.ps1` 已更新：
  - Harness 目录完整性检查中新增 `archive\store.ps1` 和 `archive\index.json` 两项

- `harness/session-handoff.md` 已更新：
  - 新增 Archive History 章节，包含归档创建、查看、还原、比较命令参考
  - 启动序列增加步骤 8（查看归档历史）
  - 快速恢复检查清单增加归档历史项

---

## What's In Progress（进行中）

暂无进行中的功能。基础建设阶段已完成。

---

## What's Next（待开始）

以下为候选的下一阶段工作：

1. **feat-009: 项目模板与脚手架** — 创建项目初始化和模板系统，使新项目可快速应用 Harness 体系。
2. **feat-010: CI/CD 集成** — 将 init.ps1 验证脚本集成到 CI 流水线，添加自动化质量门禁。
3. **feat-011: 度量与监控** — 建立代理效率、Token 消耗、技能使用频率等度量仪表板。
4. **feat-012: 跨平台适配** — 验证核心协议文件在 Claude Code、Codex CLI 等平台的可用性，补充平台适配文档。

优先级判断：feat-009（CI/CD 集成）是最有价值的下一步，因为它能自动执行验证并防止回归。

---

## Blockers / Risks（阻塞项和风险）

| 类型 | 描述 | 严重程度 | 缓解措施 |
|------|------|----------|----------|
| 风险 | 技能文件尚未经过实战验证，可能存在流程缺陷 | 低 | 在实际项目中逐步验证和迭代 |
| 风险 | 代理角色定义目前仅为提示词模板，缺乏可执行的 agent-as-tool 实现 | 中 | 需要平台支持（Trae IDE agent-as-tool 能力） |
| 风险 | 多代理模式（Team execution）在当前单代理环境下无法完全发挥 | 中 | 在当前单代理限制下使用简化流程；等待平台演进 |
| 注意 | Windows 环境下 PowerShell 执行策略可能阻止 init.ps1 | 低 | 文档化 `Set-ExecutionPolicy` 配置步骤 |

---

## Decisions Made（决策记录）

### 决策 1：工作区根目录结构

**决策内容：** 将 AGENTS.md、SOUL.md、RULES.md、SECURITY.md 放在根目录，harness/ 作为状态管理子目录。

**决策理由：** 遵循 Claude Code / Codex CLI 的 AGENTS.md 根目录约定；使得协议文件在文件树中一目了然；harness/ 保持聚焦于状态和交接。

**日期：** 2026-06-09

### 决策 2：集成来源优先级

**决策内容：** 以 learn-harness-engineering 为核心方法论框架，superpowers 为技能和 TDD 流程来源，gstack 为产品流程来源，ECC 为安全规则来源，andrej-karpathy-skills 为反过度设计约束来源。

**决策理由：** learn-harness-engineering 提供了最完整的五子系统理论框架；superpowers 的 TDD 方法论是经过验证的最佳实践；gstack 的产品判断链路填补了从需求到交付的空白。

**日期：** 2026-06-09

### 决策 3：单代理 vs 多代理模式

**决策内容：** 在当前环境下以单代理模式运行，保留多代理协议的接口，待平台能力到位后激活。

**决策理由：** 当前 Trae IDE 的 agent-as-tool 能力有限；单代理模式已能满足大部分任务需求；保留协议接口可无痛升级。

**日期：** 2026-06-09

### 决策 4：Windows 优先

**决策内容：** 所有脚本和路径使用 Windows 风格（PowerShell、反斜杠路径）。

**决策理由：** 用户系统为 Windows；`.trae/rules/project_rules.md` 已明确此偏好。

**日期：** 2026-06-09

### 决策 5：中文为主要文档语言

**决策内容：** 对话、注释、文档使用中文（简体）；代码标识符和 Commit Message 使用英文。

**决策理由：** 用户偏好中文；`.trae/rules/project_rules.md` 已明确此规范。

**日期：** 2026-06-09

---

## Files Modified This Session（本次会话修改的文件）

### 创建的文件

| 文件路径 | 用途 |
|----------|------|
| `harness/feature_list.json` | 功能状态追踪器（六子系统真相来源） |
| `harness/progress.md` | 本文件：会话连续性日志 |
| `harness/session-handoff.md` | 会话交接模板 |
| `harness/init.ps1` | Windows PowerShell 启动验证脚本 |
| `harness/clean-state-checklist.md` | 干净状态检查清单 |
| `harness/workflow-state.json` | 工作流状态追踪器（活跃工作流、阶段、门禁状态） |
| `harness/workflow-gates.md` | 工作流质量门禁定义（4 种工作流 28 条门禁） |
| `harness/archive/store.ps1` | 历史交接归档引擎（8 种操作：new/list/info/restore/remove/compare/verify/cleanup） |
| `harness/archive/index.json` | 归档索引追踪器 |

### 修改的文件

| 文件路径 | 变更内容 |
|----------|----------|
| `harness/init.ps1` | 新增 archive\store.ps1 和 archive\index.json 的完整性检查 |
| `harness/session-handoff.md` | 新增 Archive History 章节 + 启动序列步骤 8 + 快速恢复清单扩展 |
| `harness/feature_list.json` | 新增 feat-008 历史交接归档机制条目 |
| `harness/progress.md` | 本文件：记录 feat-008 完成内容和证据 |

### 引用的已有文件（未修改）

| 文件路径 | 用途 |
|----------|------|
| `AGENTS.md` | 代理指令主入口 |
| `SOUL.md` | 核心身份声明 |
| `RULES.md` | 规则契约 |
| `SECURITY.md` | 安全策略 |
| `.trae/rules/project_rules.md` | Trae IDE 专用规则 |

---

## Evidence of Completion（完成证据）

### feat-001 验证证据

- `harness/` 目录已创建，包含全部 5 个文件
- 所有文件内容充实完整，无占位符
- JSON 格式有效（feature_list.json）
- Markdown 格式规范（progress.md、session-handoff.md、clean-state-checklist.md）
- PowerShell 脚本语法正确（init.ps1）

### feat-002 验证证据

- `skills/` 目录已创建，技能文件遵循标准格式
- 技能路由表已在 AGENTS.md 中定义

### feat-003 验证证据

- `agents/` 目录已创建，代理文件遵循标准格式
- 代理分层已在 AGENTS.md 中定义

### feat-004 验证证据

- `skills/caveman-token-compress` 技能文件已创建
- 系统级 Token 优化技能（rtk-strategy、headroom-strategy、reasonix-cache、token-budget、conversation-continuity）已就绪
- 会话压缩与恢复策略已整合到 session-handoff.md

### feat-005 验证证据

- RULES.md、SOUL.md、AGENTS.md 内容完整
- 所有规范格式正确

### feat-006 验证证据

- SECURITY.md 包含完整的安全策略
- Prompt Defense Baseline 已在 AGENTS.md 和 SECURITY.md 中双重备份
- 安全规则已集成到 RULES.md 的禁止事项中

### feat-007 验证证据

- `harness/workflow-state.json` 已创建：JSON 格式有效，包含 4 种工作流定义和门禁状态结构
- `harness/workflow-gates.md` 已创建：Markdown 格式规范，包含 28 条门禁定义
- 门禁覆盖所有 4 种工作流（标准 7 条 + 复杂 5 条 + 产品 8 条 + TDD 8 条）
- 门禁定义与 AGENTS.md 工作流阶段完全对齐
- `feature_list.json` 已补充 feat-007 条目
- `progress.md` 已更新完成内容和文件变更记录

### feat-008 验证证据

- `harness/archive/store.ps1` 已创建：PowerShell 语法正确，8 种操作逻辑完整
- `harness/archive/index.json` 已创建：JSON 格式有效，包含 version 和 archives 数组
- `harness/init.ps1` 已更新：新增 2 个归档文件完整性检查项
- `harness/session-handoff.md` 已更新：Archive History 章节 + 启动序列步骤 8
- `harness/feature_list.json` 已新增 feat-008 条目
- `harness/progress.md` 已记录 feat-008 完成内容和证据
- 归档机制与现有 7 个 harness 文件全兼容，无破坏性变更

---

## Notes for Next Session（下次会话注意事项）

1. **启动流程**：读取 AGENTS.md → 运行 `harness/init.ps1` → 读取 `harness/progress.md` → 读取 `harness/feature_list.json` → 读取 `harness/workflow-state.json` → 检查 git log。
2. **PowerShell 执行策略**：如遇脚本执行被阻止，运行 `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`。
3. **功能状态同步**：在开始新功能前，更新 `feature_list.json` 中对应功能的状态为 `in_progress`。
4. **工作流门禁**：阶段切换前检查 `workflow-gates.md` 中对应门禁，确保质量条件满足。
5. **交接更新**：每次会话结束后更新本文件、`session-handoff.md` 和 `workflow-state.json`，确保下次会话可无缝恢复。
6. **证据要求**：任何完成的声明必须有对应的验证证据记录。

---

**最后更新：** 2026-06-09
**更新者：** AWI Harness 系统初始化
