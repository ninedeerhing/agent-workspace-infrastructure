# TRAE Workspace 项目结构与使用说明

## 项目概览

TRAE Workspace 是一个基于 **Harness Engineering** 方法论的 AI 工程工作区，专为高复杂度、多代理协作、技能驱动开发场景而设计。它将多个前沿 AI 编程方法论项目的最佳实践融合到一个统一的工程环境中，使开发者能够在同一工作区内使用最合适的流程和工具完成从创意到发布的全生命周期。

本工作区整合了以下 12 个来源项目的精华思想：

| 序号 | 来源项目 | 核心贡献 |
|------|----------|----------|
| 1 | superpowers | 技能优先方法论、TDD 强制流程、子代理开发、代码审查协议 |
| 2 | gstack | YC Office Hours 产品审查、CEO/Eng/Design/QA/Security 专家链路 |
| 3 | andrej-karpathy-skills | 少假设、少过度设计、手术式修改、目标驱动验证 |
| 4 | anthropics/skills | Claude 官方技能体系，提供技能设计参考范式 |
| 5 | oh-my-codex | 深度访谈、共识规划、持久目标、Ralph Loop 自引用循环、Autopilot 全自主流水线 |
| 6 | oh-my-openagent | 后台代理与分类路由、LSP/AST 工具化、Sisyphus 式持续推进 |
| 7 | ECC | 跨代理安全基线、提示注入防御、安全审查体系、多语言规则库 |
| 8 | learn-harness-engineering | Instructions / State / Verification / Scope / Lifecycle 五子系统理论 |
| 9 | caveman | Token 压缩通信协议，用最小 Token 传递最大信息密度 |
| 10 | rtk | 命令压缩与缓存策略，减少重复上下文开销 |
| 11 | headroom | 上下文窗口管理，智能裁剪保持关键信息 |
| 12 | DeepSeek-Reasonix | Prefix-Cache 稳定性增强，优化推理模型的缓存命中率 |

这些来源项目被吸收、重组、统一为 TRAE Workspace 的三个核心层次：**技能（Skills）**、**代理（Agents）**、**规则（Rules）**，并由 Harness 五子系统协调运行。

## 目录结构

```
E:\trae_workspace\
├── AGENTS.md                    # 代理指令主入口，所有 AI 代理启动时首先读取
├── SOUL.md                      # 核心身份与愿景定义，描述工作区的设计哲学
├── SECURITY.md                  # 安全策略文档，定义安全边界与防护规则
├── RULES.md                     # 规则契约，汇总所有规则的索引与优先级
├── .trae/rules/project_rules.md # Trae IDE 项目级规则，IDE 启动时自动加载
│
├── harnes\                      # 五子系统 Harness — 任务的神经中枢
│   ├── feature_list.json        # 功能状态追踪器，记录当前功能、状态、证据、下一步
│   ├── progress.md              # 会话连续性日志，人类可读的进度记录
│   ├── session-handoff.md       # 会话交接模板，确保跨会话上下文不丢失
│   ├── init.ps1                 # 启动验证脚本，检查环境完整性和依赖状态
│   └── clean-state-checklist.md # 干净状态检查清单，确保无遗留干扰
│
├── skills/                      # 28个可复用技能 — 工作区的执行单元
│   ├── brainstorming/           # 头脑风暴 — 创意探索与需求澄清 (来源: superpowers)
│   ├── writing-plans/           # 编写计划 — 任务拆解与里程碑规划 (来源: superpowers)
│   ├── subagent-driven-dev/     # 子代理驱动开发 — 复杂任务的多代理协调 (来源: superpowers)
│   ├── test-driven-development/ # TDD — RED→GREEN→REFACTOR 强制流程 (来源: superpowers)
│   ├── systematic-debugging/    # 系统化调试 — 根因分析与回归隔离 (来源: superpowers)
│   ├── verification-before-completion/ # 完成前验证 — 确保交付物满足验收标准 (来源: superpowers)
│   ├── requesting-code-review/  # 代码审查请求 — 标准化审查发起流程 (来源: superpowers)
│   ├── receiving-code-review/   # 代码审查接收 — 审查意见的处理与响应 (来源: superpowers)
│   ├── using-git-worktrees/     # Git Worktree — 并行分支与工作区隔离 (来源: superpowers)
│   ├── finishing-dev-branch/    # 完成开发分支 — PR 提交与分支清理 (来源: superpowers)
│   ├── dispatching-parallel-agents/ # 并行代理分派 — 多代理并发执行 (来源: superpowers)
│   ├── executing-plans/         # 计划执行 — 小步修改与可回滚差异 (来源: superpowers)
│   ├── writing-skills/          # 编写技能 — 元技能，用于创建和优化技能 (来源: superpowers)
│   ├── karpathy-guidelines/     # Karpathy 编程准则 — 手术式修改与少过度设计
│   ├── caveman-token-compress/  # Token 压缩通信 — 最小 Token 传递最大信息 (来源: caveman)
│   ├── deep-interview/          # 深度访谈 — 多层次需求挖掘 (来源: oh-my-codex)
│   ├── ralplan/                 # 共识规划 — 多轮校准形成执行共识 (来源: oh-my-codex)
│   ├── ultragol/               # 持久目标 — 长期任务的持续推进 (来源: oh-my-codex)
│   ├── ralph-loop/              # 自引用循环 — 自主纠错与迭代优化 (来源: oh-my-codex)
│   ├── autopilot/               # 全自主流水线 — 端到端无人值守执行 (来源: oh-my-codex)
│   ├── office-hours/            # YC Office Hours — 产品方向与 MVP 判断 (来源: gstack)
│   ├── plan-ceo-review/         # CEO 审查 — 商业可行性与战略对齐 (来源: gstack)
│   ├── plan-eng-review/         # 工程审查 — 技术架构与实现风险评估 (来源: gstack)
│   ├── plan-design-review/      # 设计审查 — UI/UX 与设计系统一致性 (来源: gstack)
│   ├── code-review/             # PR 审查 — 逻辑缺陷、可维护性、性能评估 (来源: gstack)
│   ├── security-review/         # 安全审查 — 秘密、注入、授权、供应链风险 (来源: ECC)
│   ├── ship-release/            # 发布工程 — 版本管理与发布流水线 (来源: gstack)
│   └── qa-testing/              # QA 测试 — 端到端手动与自动化验证 (来源: gstack)
│
├── agents/                      # 10个专业代理角色 — 工作区的智能执行者
│   ├── orchestrator.md          # 主编排器 — 流程选择、状态同步、任务拆分、最终验收
│   ├── planner.md               # 规划者 — 需求拆解、任务排序、风险识别、里程碑规划
│   ├── architect.md             # 架构师 — 系统边界、依赖方向、技术权衡、ADR 决策记录
│   ├── explorer.md              # 代码库探索者 — 快速定位文件、符号和模式
│   ├── executor.md              # 执行者 — 有边界的实现与重构，手术式修改
│   ├── code-reviewer.md         # 代码审查者 — 逻辑缺陷、可维护性、性能、风格审查
│   ├── security-reviewer.md     # 安全审查者 — 秘密泄露、注入攻击、授权缺陷、供应链风险
│   ├── test-engineer.md         # 测试工程师 — TDD、测试设计、覆盖率与稳定性保障
│   ├── debugger.md              # 调试者 — 根因分析、复现构建、回归隔离
│   └── verifier.md              # 验证者 — 完成证据收集、验收标准检查、风险报告
│
├── rules/common/                # 5个通用规则 — 工作区的行为约束
│   ├── security.md              # 安全规则 — 秘密、凭证、注入防护、供应链安全
│   ├── coding-style.md          # 编码风格规则 — 命名、格式、注释、项目结构约定
│   ├── testing.md               # 测试规则 — TDD 强制流程、覆盖率目标、测试分类
│   ├── agents.md                # 代理编排规则 — 代理分派、协作、交接协议
│   └── patterns.md              # 设计模式规则 — 分层架构、API 格式、命名约定
│
├── cache/                       # 命中缓存与省 Token 底架
│   ├── caveman-prompt.md        # Caveman 提示压缩策略 — 用最简字符传递完整意图
│   ├── rtk-strategy.md          # RTK 命令压缩策略 — 指令缓存与复用机制
│   ├── headroom-strategy.md     # Headroom 上下文压缩 — 窗口管理与关键信息保留
│   ├── reasonix-cache.md        # Prefix-Cache 稳定性 — 推理模型缓存命中率优化
│   └── token-budget.md          # Token 预算综合管理 — 成本控制与分配策略
│
└── docs/
    └── PROJECT-STRUCTURE.md     # 本文件 — 项目结构与使用说明
```

## 如何使用

### 1. 启动一个会话

开始任何工作时，首先告诉 AI 代理阅读入口文件：

```
请阅读 AGENTS.md，然后运行 harness/init.ps1 检查环境状态。
```

`harness/init.ps1` 会执行以下检查：
- 确认关键文件和目录是否存在且完整
- 验证 `feature_list.json` 状态一致性
- 检查 `progress.md` 是否有未完成的阻塞项
- 输出当前工作区健康状态摘要

### 2. 执行任务 — 默认工作流

TRAE Workspace 的标准工作流是一个 7 步循环：

```
INTAKE → RESEARCH → PLAN → EXECUTE → REVIEW → VERIFY → HANDOFF
```

**各步骤说明：**

| 步骤 | 名称 | 活动 | 输出 |
|------|------|------|------|
| 1 | INTAKE | 确认目标、范围、风险、验收标准 | 任务描述与边界 |
| 2 | RESEARCH | 读取本地代码、参考项目、官方文档 | 事实和证据记录 |
| 3 | PLAN | 把目标拆成可执行任务，明确非目标 | 任务列表与验证命令 |
| 4 | EXECUTE | 小步修改，保留可回滚差异 | 代码变更 |
| 5 | REVIEW | 作者和审查分离，安全/质量/设计审查 | 审查意见与问题列表 |
| 6 | VERIFY | 运行最小充分验证，失败则回到 EXECUTE | 验证结果和证据 |
| 7 | HANDOFF | 更新 progress.md 和 session-handoff.md | 状态交接文档 |

### 3. 调用技能

技能是工作区最基本的执行单元。你可以通过以下方式触发：

- **直接说技能名称**：`"使用 brainstorming 技能"` 或 `"执行 TDD 流程"`
- **简短语法**：`"$brainstorming"` `"$security-review"`
- **自然语言**：`"帮我做一次代码审查"` 自动匹配 `code-review` 技能

**常用技能组合：**

| 场景 | 技能序列 |
|------|----------|
| 新功能开发 | brainstorming → writing-plans → test-driven-development → code-review → verification-before-completion |
| Bug 修复 | systematic-debugging → test-driven-development → code-review |
| 架构重构 | deep-interview → ralplan → plan-eng-review → subagent-driven-dev |
| 快速原型 | brainstorming → executing-plans → qa-testing |
| 产品决策 | office-hours → plan-ceo-review → plan-eng-review → plan-design-review |
| 发布上线 | security-review → ship-release → verification-before-completion |

### 4. 分派代理

对于复杂任务，可以通过代理角色分担工作：

**自动分派规则：**

- `orchestrator` — 检测到多步骤、跨文件任务时自动激活
- `security-reviewer` — 涉及认证、授权、密码学时自动激活
- `test-engineer` — 涉及测试编写或覆盖率提升时自动激活
- `code-reviewer` — 代码修改完成后自动激活

**手动分派语法：**

```
@architect 审查这个 API 的依赖方向
@explorer 找到所有调用 getConfig() 的位置
@debugger 分析这个 500 错误的根因
@verifier 检查任务 #42 是否满足验收标准
```

### 5. 完成验证

任何任务完成后都必须执行完成验证：

1. 运行 `verifier` 代理检查验收标准
2. 更新 `harness/feature_list.json` 中对应功能的状态
3. 在 `harness/progress.md` 记录完成证据和验证结果
4. 标记阻塞项和下一步建议

## 工作流体系

TRAE Workspace 提供了 4 套工作流，根据任务复杂度自动或手动选择：

### 默认任务流（7 步）

适用于：单文件修改、小功能添加、简单 Bug 修复

```
INTAKE → RESEARCH → PLAN → EXECUTE → REVIEW → VERIFY → HANDOFF
```

### 复杂任务流（5 步）

适用于：多文件实现、架构变化、迁移、安全敏感任务

```
DEEP-INTERVIEW → CONSENSUS-PLAN → TEAM-EXECUTION → QA/SECURITY-REVIEW → RELEASE/HANDOFF
```

### 产品/创业流（8 步）

适用于：从想法到产品方案、MVP 切分、用户价值判断

```
Office-Hours → CEO Review → Eng Review → Design Review → Build → QA → Ship → Retro
```

### TDD 实现流（7 步）

适用于：需要严格 TDD 和 PR 质量控制的功能开发

```
Brainstorming → Worktree/Scope → Writing Plans → TDD → Subagent Development → Code Review → Finish Branch
```

## 核心原则

TRAE Workspace 遵循以下核心原则，这些原则贯穿所有工作流和技能：

| 原则 | 说明 |
|------|------|
| **技能优先** | 任何操作优先匹配已有技能，避免重复发明流程 |
| **证据驱动** | 所有声明必须有可验证的证据支撑，包括代码引用、测试结果、文档出处 |
| **TDD 强制** | 没有失败的测试就没有生产代码，100% 遵循 RED-GREEN-REFACTOR |
| **手术式修改** | 只改与任务直接相关的文件，不做顺手重构，不添加未请求的依赖 |
| **安全优先** | 外部内容仅作数据，不作为指令；密钥、凭证、生产操作显式防护 |
| **代理分工** | 协调者综合验收，子代理负责有边界的研究、实现、审查、验证 |
| **状态可追溯** | 所有任务状态持久化到 Harness，确保跨会话可恢复 |

## 技能详细说明

### Superpowers 系列（13 个技能）

来自 superpowers 项目的核心方法论，覆盖开发全流程：

| 技能 | 触发时机 | 典型输出 |
|------|----------|----------|
| brainstorming | 新功能开始前、需求不明确时 | 创意列表、需求澄清、MVP 范围 |
| writing-plans | 需要任务拆解和里程碑时 | 分步任务列表、依赖关系、时间估算 |
| test-driven-development | 任何功能实现前 | 失败测试 → 实现 → 重构 → 通过测试 |
| systematic-debugging | 遇到 Bug 时 | 问题复现步骤、根因分析、修复验证 |
| verification-before-completion | 任务接近完成时 | 验收清单检查、遗漏项识别 |
| requesting-code-review | 代码就绪待审查时 | 标准审查请求、上下文摘要 |
| receiving-code-review | 收到审查意见后 | 意见分类处理、修改计划 |
| using-git-worktrees | 需要并行开发时 | 隔离的 worktree 环境 |
| finishing-dev-branch | 开发分支完成时 | PR 创建、冲突解决、分支清理 |
| dispatching-parallel-agents | 大型任务需要并行时 | 子任务分配、结果汇总 |
| executing-plans | 计划就绪待执行时 | 小步修改、增量提交 |
| writing-skills | 需要创建新技能时 | 新的技能模板和文档 |

### Gstack 系列（7 个技能）

来自 gstack 项目的产品与质量管理流程：

| 技能 | 触发时机 | 典型输出 |
|------|----------|----------|
| office-hours | 产品方向不明确时 | 产品判断、MVP 切分方案 |
| plan-ceo-review | 需要商业可行性判断时 | 战略对齐评估、商业模式评审 |
| plan-eng-review | 需要技术可行性判断时 | 技术风险评估、架构建议 |
| plan-design-review | UI/UX 相关开发时 | 设计系统一致性检查、可用性评估 |
| code-review | PR 需要审查时 | 逻辑缺陷报告、可维护性评分 |
| ship-release | 准备发布时 | 发布检查清单、版本标签 |
| qa-testing | 功能开发完成后 | 手动测试检查列表、Bug 报告 |

### Oh-my-codex 系列（5 个技能）

来自 oh-my-codex 项目的高级自主工作流：

| 技能 | 触发时机 | 典型输出 |
|------|----------|----------|
| deep-interview | 需求复杂模糊时 | 多层次需求文档、歧义澄清 |
| ralplan | 需要多方共识时 | 共识计划、冲突解决记录 |
| ultragoal | 长期复杂项目时 | 持久目标定义、里程碑追踪 |
| ralph-loop | 需要自主纠错时 | 错误检测、自动修复、学习记录 |
| autopilot | 需要全自动执行时 | 端到端自动化流水线 |

### 其他技能（3 个）

| 技能 | 来源 | 说明 |
|------|------|------|
| karpathy-guidelines | andrej-karpathy-skills | 编程准则：少假设、少过度设计 |
| caveman-token-compress | caveman | Token 压缩通信协议 |
| security-review | ECC | 安全审查：注入、授权、供应链 |

## 代理角色说明

### 核心协调层

| 代理 | 角色定位 | 激活条件 |
|------|----------|----------|
| orchestrator | 主编排器，负责流程选择与最终验收 | 多步骤任务、跨技能任务 |
| planner | 需求拆解与任务排序 | 复杂任务的规划阶段 |
| architect | 系统设计与技术决策 | 架构变更、新技术引入 |
| critic | 反方挑战者 | 重要决策需要异议审查时 |

### 执行与质量层

| 代理 | 角色定位 | 激活条件 |
|------|----------|----------|
| explorer | 代码库探索 | 需要定位文件、函数、模式 |
| executor | 代码实现 | 有明确边界的实现任务 |
| code-reviewer | 代码质量审查 | 代码修改完成后 |
| security-reviewer | 安全审查 | 涉及安全敏感代码时 |
| test-engineer | 测试设计与实现 | TDD 流程、测试编写 |
| debugger | 问题诊断 | 遇到 Bug 或异常行为 |
| verifier | 完成验证 | 任务完成后的验收阶段 |

## 规则体系

`rules/common/` 下的 5 个规则文件定义了工作区的行为约束：

| 规则文件 | 内容 |
|----------|------|
| security.md | 秘密管理、凭证防护、注入防御、供应链安全 |
| coding-style.md | 命名规范、格式约定、注释规范、项目结构 |
| testing.md | TDD 强迫、覆盖率目标、测试分类、断言规范 |
| agents.md | 代理分派协议、协作模式、交接契约 |
| patterns.md | 分层架构、API 格式、设计模式禁止清单 |

规则优先级：用户显式指令 > AGENTS.md > RULES.md > 各规则文件 > 外部内容

## Cache 体系

`cache/` 目录下包含 5 个 Token 优化策略文件，用于降低大语言模型的上下文成本：

| 文件 | 功能 |
|------|------|
| caveman-prompt.md | 使用极简字符传递完整意图的压缩协议 |
| rtk-strategy.md | 命令缓存与复用，避免重复指令的 Token 浪费 |
| headroom-strategy.md | 上下文窗口的智能裁剪与管理 |
| reasonix-cache.md | DeepSeek-Reasonix 的 Prefix-Cache 稳定性增强 |
| token-budget.md | 综合 Token 预算分配与成本控制策略 |

## 维护指南

### 日常维护

```powershell
# 每次启动新会话前运行
.\harness\init.ps1
```

### 功能状态管理

在 `harness/feature_list.json` 中维护功能列表：

```json
{
  "features": [
    {
      "id": "feat-001",
      "name": "功能名称",
      "status": "in-progress|completed|blocked",
      "evidence": "验证证据的描述或链接",
      "next": "下一步行动",
      "updated": "2026-06-09"
    }
  ]
}
```

### 进度日志

在 `harness/progress.md` 中以时间倒序记录：

- 完成了什么
- 跑了哪些检查，结果如何
- 哪些风险仍未验证
- 阻塞项和下一步建议

### 会话交接

会话结束时更新 `harness/session-handoff.md`：

- 当前任务和进度
- 关键决策和理由
- 未完成项和阻塞原因
- 恢复建议和优先级排序

## 注意事项

1. **不要跨会话假设状态** — 每次新会话都应该从 Harness 状态文件读取最新状态
2. **不要盲目混合流程** — 选择一个工作流并坚持执行完毕，避免中途切换
3. **不要忽略验证** — 任何声明为"完成"的任务都必须有验证证据
4. **不要绕过安全检查** — 安全规则适用于所有代码，包括原型和实验性代码
5. **保持 Harness 同步** — 任何状态变化都应及时写入对应的状态文件
