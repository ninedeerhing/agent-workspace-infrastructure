# raindeer 项目结构

> **版本**: 1.1.0
> **派生自**: ADR-003 工作区根目录结构、AGENTS.md、CONSTITUTION.md
> **适用范围**: raindeer — 融合 AWI 治理框架的 A 股量化研究平台

---

## 一、结构总览

```
e:\raindeer\
├── CONSTITUTION.md              ← 项目宪法（最高治理文件）
├── SOUL.md                      ← 核心身份与五大原则
├── AGENTS.md                    ← 代理操作指令主入口
├── AGENTS-lite.md               ← 精简版代理契约
├── RULES.md                     ← 规则契约（必须/禁止清单）
├── SECURITY.md                  ← 安全策略
├── SECURITY-ZONES.md            ← 运行时安全区定义
├── README.md                    ← 项目说明
├── bootstrap.ps1                ← 工作区初始化脚本
│
├── harness/                     ← 状态管理 + Runtime OS（Harness State + Control Plane）
├── agents/                      ← 22 个 AI 代理角色（含 raindeer 元治理层）
├── design-architecture/         ← 前端设计六层架构（TypeScript）
├── .cursor/agents/              ← Cursor IDE 代理适配层
├── .cursor/rules/               ← Cursor 规则（含 raindeer-awi-orchestrator/worker）
├── .cursor/hooks.json           ← Cursor 会话钩子（Compliance Kernel 接线）
├── .trae/skills/                ← Trae IDE 技能适配层（71 个技能）
├── .cursor/skills/              ← Cursor IDE 技能适配层
├── .omx/                        ← 持久化记忆与目标追踪
│
├── skills/                      ← 技能源文件（SOP 级别）
├── rules/common/                ← 通用编码规则（7 个领域）
├── cache/                       ← 缓存策略与 Token 预算
│
├── docs/                        ← 项目级文档
├── NINEDEER-WiKi/               ← 知识库（Obsidian 驱动）
│
├── apps/quant_assistant/        ← 主应用——量化研究助手
└── .mineru-cli/                 ← MinerU 文档解析 CLI
```

---

## 二、治理层（Governance Layer）

治理层定义了项目的不可变原则、核心身份、操作指令和安全边界。所有代理和技能的行为必须服从治理层的约束。

| 文件 | 职责 | 修改约束 |
|------|------|----------|
| `CONSTITUTION.md` | 项目宪法，最高权威；AWI 核心五原则不可变 | 仅架构团队可修改 |
| `SOUL.md` | 核心身份声明；五大原则 + 构建者哲学 | 与宪法同步更新 |
| `AGENTS.md` | 代理操作指令主入口；19 条核心操作原则；工作流/技能路由/代理分层 | 跟随项目演进更新 |
| `AGENTS-lite.md` | 精简版代理契约，用于快速上下文加载 | 从 AGENTS.md 精简生成 |
| `RULES.md` | 规则契约；必须/禁止清单；格式规范 | 跟随项目演进更新 |
| `SECURITY.md` | 安全策略；密钥管理、不可信输入、外部动作 | 安全边界变更时更新 |
| `SECURITY-ZONES.md` | 运行时安全区；区域定义、数据流转、执行边界 | 运行时环境变更时更新 |

### 治理层级（优先级从高到低）

```
CONSTITUTION.md → SOUL.md → AGENTS.md → RULES.md → SECURITY.md → SECURITY-ZONES.md
```

---

## 三、Harness 层（Harness Layer）

Harness 层是 Harness Engineering 方法论中 **State（状态）** 子系统的实现。它是工作区的"神经中枢"，持久化所有任务状态、流程编排和会话上下文。

```
harness/
├── feature_list.json           ← 功能清单：任务树注册、优先级、状态
├── progress.md                 ← 进度追踪：当前会话任务、决策记录
├── session-handoff.md          ← 会话交接：跨会话上下文恢复
├── pipeline-dag.json           ← 流水线 DAG：任务依赖拓扑图（raindeer 量化任务拓扑）
├── incremental-state.json      ← 增量状态：数据采集水位与幂等锚点
├── workflow-state.json         ← 工作流状态：当前流转阶段
├── workflow-gates.md           ← 工作流门禁：各阶段准入/准出条件
├── schedule.json               ← 调度配置：定时任务定义
├── schedule.ps1                ← 调度执行器：PowerShell 调度脚本
├── grader-types.md             ← 评分类型：任务复杂度分级规则
├── init.ps1                    ← 初始化脚本：工作区一键初始化
├── sandbox.ps1                 ← 沙箱脚本：安全隔离执行环境
├── audit.ps1                   ← 审计脚本：台账完整性校验
├── compliance-check.ps1        ← Compliance Kernel：post-bootstrap / 日常合规检查
├── gate-runner.ps1             ← 阶段门禁执行器（RESEARCH→EXECUTE 等）
├── agent-registry.json         ← 22 角色注册表（orchestrator-Only 模型）
├── team-manifest.default.json  ← 团队清单默认值
├── platform-binding.json       ← 当前 IDE 平台绑定（cursor/trae/generic）
├── token-budget.json           ← Token 预算配置
├── brain-workflows/            ← raindeer 量化 Brain 工作流（业务专属，AWI 不覆盖）
├── templates/                  ← orchestrator/worker 初始化提示词模板
├── hooks/                      ← 会话钩子脚本（session-start / post-edit-remind）
├── scripts/                    ← registry 构建、mailbox 读写、worker 边界注入
├── adapters/                   ← 跨平台 PAL（cursor / trae / codex / claude-code / generic）
├── mailbox/                    ← Agent 文件总线（orchestrator ↔ worker 消息）
├── worklogs/                   ← 各角色工作日志脚手架
├── clean-state-checklist.md    ← 状态清理清单：重置工作区检查项
└── archive/                    ← 归档区
    ├── index.json              ← 归档索引
    └── store.ps1               ← 归档存储脚本
```

### Runtime OS（Control Plane）

AWI v1.0.0-raindeer 在 Harness 层之上增加了 **Runtime OS**，实现 orchestrator-Only 团队协作：

| 组件 | 路径 | 职责 |
|------|------|------|
| Compliance Kernel | `harness/compliance-check.ps1` | 自动 enforcement：台账、registry、workflow-state |
| Gate Runner | `harness/gate-runner.ps1` | 阶段切换前门禁校验 |
| Agent Registry | `harness/agent-registry.json` | 22 角色 roster + mailbox 路由 |
| Platform Adapter Layer | `harness/adapters/` | Cursor/Trae/Codex 等平台适配安装 |
| Mailbox 文件总线 | `harness/mailbox/` + `harness/scripts/Send-MailboxMessage.ps1` | Worker 间异步协作 |
| Cursor Hooks | `.cursor/hooks.json` + `harness/hooks/` | 会话启动 / 编辑后提醒 |

**与 raindeer 业务隔离**：`apps/quant_assistant/` 及 `harness/brain-workflows/`、`harness/pipeline-dag.json`、`harness/incremental-state.json` 等业务状态在 AWI 同步时**保留不变**。

### 关键文件说明

#### pipeline-dag.json
任务依赖拓扑图（DAG），以 JSON 格式定义任务树的节点、边和执行顺序。支持并行节点识别和关键路径分析。任务调度器在启动前必须解析此文件以确保依赖满足。

**结构摘要**：
```json
{
  "nodes": [
    { "id": "ingest_daily_basic", "type": "ingest", "schedule": "daily" },
    { "id": "compute_factors", "type": "compute", "depends_on": ["ingest_daily_basic"] }
  ],
  "edges": [
    { "from": "ingest_daily_basic", "to": "compute_factors" }
  ]
}
```

#### incremental-state.json
增量状态文件，记录数据采集的水位标记（watermark）和幂等执行锚点。每次数据采集作业执行前后必须读取和更新此文件。`job_ingest_*` 系列脚本通过水位实现增量采集，确保：
- 不重复采集已处理范围的数据
- 断点续传（从上次水位恢复）
- 幂等保证（同水位范围内重复执行不产生重复数据）

**结构摘要**：
```json
{
  "watermarks": {
    "daily_bar": { "last_trade_date": "2026-06-10", "last_ingest_ts": "..." },
    "daily_basic": { "last_trade_date": "2026-06-10", "last_ingest_ts": "..." }
  },
  "checkpoints": {
    "factor_compute": { "last_date": "2026-06-10", "status": "complete" }
  }
}
```

---

## 四、代理层（Agent Layer）

代理层定义了 **22 个** AI 代理角色（AWI 18 + raindeer 元治理 2 + 合并 explore/researcher 等），对应 Harness 的 5 层体系。orchestrator 是**唯一用户接口**。

```
agents/                         ← 主代理定义（跨 IDE 通用）
├── constitution-guardian.md    ← 第 0 层 元治理：宪法守卫者（raindeer 专属）
├── governance-coordinator.md   ← 第 0 层 元治理：治理协调者（raindeer 专属）
├── orchestrator.md             ← 中枢：唯一对用户接口
├── planner.md                  ← 第 1 层 计划：需求拆解 + 里程碑
├── architect.md                ← 第 1 层 计划：系统边界 + ADR
├── critic.md                   ← 第 1 层 计划：对抗性挑战
├── executor.md                 ← 第 2 层 执行：有界实现
├── explore.md                  ← 第 2 层 执行：快速代码探索（AWI 合并 explorer）
├── explorer.md                 ← 第 2 层 执行：环境探索（raindeer 保留）
├── debugger.md                 ← 第 2 层 执行：根因分析
├── researcher.md               ← 第 2 层 执行：证据收集（raindeer 保留）
├── scientist.md                ← 第 2 层 执行：科学研究（AWI 新增）
├── git-master.md               ← 第 2 层 执行：Git 工作流（AWI 新增）
├── tracer.md                   ← 第 2 层 执行：链路追踪（AWI 新增）
├── code-reviewer.md            ← 第 3 层 质量：逻辑审查
├── security-reviewer.md        ← 第 3 层 质量：安全审计
├── test-engineer.md            ← 第 3 层 质量：TDD + 覆盖率
├── verifier.md                 ← 第 3 层 质量：完成验收
├── designer.md                 ← 第 4 层 产品：UI/UX
├── qa-tester.md                ← 第 4 层 产品：浏览器/CLI 复验
├── writer.md                   ← 第 4 层 运营：文档
├── growth-engineer.md          ← 第 4 层 成长：能力积累
└── contracts/
    └── agent-tool-contracts.json

.cursor/agents/                 ← Cursor IDE 适配（与 agents/ 同步 + raindeer 元治理）
.cursor/rules/
├── raindeer-awi-orchestrator.mdc  ← orchestrator 中枢会话规则
├── raindeer-awi-worker.mdc        ← worker 会话边界规则
├── raindeer-code.mdc              ← quant_assistant 编码规则（业务专属）
├── raindeer-operations.mdc        ← 操作协议（业务专属）
└── raindeer-security.mdc          ← 安全基线（业务专属）
```

### constitution-guardian.md 和 governance-coordinator.md

这两个代理属于**第 0 层元治理层**，是整个代理体系的"宪法法院"：

- **constitution-guardian.md**（宪法守卫者）：负责确保所有操作符合 CONSTITUTION.md。拥有最高的否决权，可以拒绝任何违反宪法原则的操作。在任何高风险操作执行前必须经过其审查。

- **governance-coordinator.md**（治理协调者）：负责协调治理文件（CONSTITUTION、SOUL、AGENTS、RULES、SECURITY）之间的交叉引用和版本一致性。当治理文件发生变更时，确保所有引用链完整且不矛盾。

---

## 五、技能层（Skill Layer）

技能层是可复用工作流的集合，遵循"技能优先"方法论。每个技能是一个独立的目录，包含 `SKILL.md` 入口文件。

```
.trae/skills/                   ← Trae IDE 运行时技能注册（71 个技能，与 AGENTS.md §6 路由表对应）
├── brainstorming/              ← 设计阶段：需求细化与方案探讨
├── writing-plans/              ← 设计阶段：多步骤实施计划编写
├── deep-interview/             ← 设计阶段：深入访谈式需求挖掘
├── ralplan/                    ← 设计阶段：RAL 结构化计划生成
├── ultragoal/                  ← 设计阶段：超目标设定与层级分解
├── prometheus-strict/          ← 设计阶段：普罗米修斯严格模式
├── frontend-design/            ← 设计阶段：UI 设计与视觉改造
│
├── best-practice-research/     ← 调研阶段：最佳实践与行业标准
├── autoresearch/               ← 调研阶段：自动化多轮研究调研
├── autoresearch-goal/          ← 调研阶段：目标驱动自主深度研究
├── github-research/            ← 调研阶段：GitHub 仓库调研
├── code-review/                ← 调研阶段：代码审查与调研分析
│
├── test-driven-development/    ← 开发阶段：TDD 先写测试
├── subagent-driven-dev/        ← 开发阶段：子代理驱动快速开发（简写）
├── subagent-driven-development/← 开发阶段：快速迭代与两阶段审核
├── executing-plans/            ← 开发阶段：书面计划执行
├── team-pipeline/              ← 开发阶段：团队流水线协作编排
├── dispatching-parallel-agents/← 开发阶段：并行代理分派
├── autopilot/                  ← 开发阶段：自动驾驶模式
│
├── plan-ceo-review/            ← 规划审查：CEO 视角商业审查
├── plan-design-review/         ← 规划审查：设计视角架构审查
├── plan-eng-review/            ← 规划审查：工程视角技术审查
├── office-hours/               ← 规划审查：办公时间答疑式审查
│
├── verification-before-completion/← 质量安全：完成前验证
├── systematic-debugging/       ← 质量安全：系统化调试
├── security-review/            ← 质量安全：安全审查
├── qa-testing/                 ← 质量安全：QA 测试流程
├── ralph-loop/                 ← 质量安全：Ralph 循环持续反馈
├── ship-release/               ← 质量安全：发布上线流程
├── release-omc/                ← 质量安全：OMC 发布管理
├── requesting-code-review/     ← 质量安全：请求代码审查
├── receiving-code-review/      ← 质量安全：处理审查反馈
├── karpathy-guidelines/        ← 质量安全：反过度设计约束
│
├── omc-conversation-continuity/← 会话管理：OMC 会话续接
├── conversation-continuity/    ← 会话管理：上下文恢复与交接
├── omo-agent-router/           ← 会话管理：OMO 代理路由
├── omo-health-monitor/         ← 会话管理：OMO 健康监控
├── session-retro/              ← 会话管理：会话回顾与经验沉淀
├── using-superpowers/          ← 会话管理：技能使用认知建立
├── sciomc/                     ← 会话管理：SCIOMC 科学方法协作
│
├── skillify/                   ← 知识管理：流程知识转化
├── capability-accumulation/    ← 知识管理：能力积累沉淀
├── skill-creator/              ← 知识管理：技能创建与修改
├── writing-skills/             ← 知识管理：技能内容编写
├── find-skills/                ← 知识管理：技能搜索发现
├── mcp-builder/                ← 知识管理：MCP 服务器构建
├── deepinit/                   ← 知识管理：项目深度初始化
│
├── caveman-token-compress/     ← Token 管理：Token 压缩
├── ai-slop-cleaner/            ← Token 管理：AI 冗余清理
├── ccg/                        ← Token 管理：缓存压缩与上下文优化
│
├── using-git-worktrees/        ← Git 管理：隔离功能开发
├── git-publish/                ← Git 管理：代码发布推送
├── finishing-dev-branch/       ← Git 管理：开发分支收尾（简写）
├── finishing-a-development-branch/← Git 管理：开发分支完成收尾
│
├── mineru-ai/                  ← 内容文档：AI 文档解析
├── pdf/                        ← 内容文档：PDF 操作
├── xlsx/                       ← 内容文档：Excel 操作
├── docx/                       ← 内容文档：Word 操作
├── pptx/                       ← 内容文档：PPT 操作
├── doc-coauthoring/            ← 内容文档：协作编写文档
│
├── canvas-design/              ← 设计视觉：视觉设计/海报
├── algorithmic-art/            ← 设计视觉：算法艺术
├── brand-guidelines/           ← 设计视觉：品牌设计指南
├── theme-factory/              ← 设计视觉：主题样式应用
├── web-artifacts-builder/      ← 设计视觉：Web 构件构建器
│
├── agent-browser/              ← 通信浏览器：浏览器自动化
├── webapp-testing/             ← 通信浏览器：Playwright UI 测试
├── gstack/                     ← 通信浏览器：gstack 工具
├── internal-comms/             ← 通信浏览器：内部通信文档
├── slack-gif-creator/          ← 通信浏览器：Slack GIF
└── claude-api/                 ← 通信浏览器：Claude API 参考
```

### 技能源文件

```
skills/                         ← 技能源文件（SOP 级别，非运行时注册）
├── superpower-skills/          ← Superpowers 框架技能（10 个核心技能）
├── anthropics-skills/          ← Anthropic 官方技能（17 个）
├── andrej-karpathy-skills/     ← Karpathy 编码约束规则
├── mineru-ai-skills/           ← MinerU 文档解析
├── agent-broser-skills/        ← 浏览器自动化
└── find-skills/                ← 技能搜索
```

---

## 六、文档层（Document Layer）

```
docs/
├── adr/                        ← 架构决策记录
│   ├── README.md               ← ADR 索引与使用说明
│   ├── TEMPLATE.md             ← ADR 标准模板
│   ├── ADR-001-harness-engineering-methodology.md  ← Harness 方法论选型
│   ├── ADR-002-markdown-for-adr.md                 ← Markdown 格式决策
│   ├── ADR-003-workspace-structure.md              ← 工作区根目录结构
│   └── ADR-004-integration-priority.md             ← 集成来源优先级
│
├── ENGINEERING/                ← 工程模板与清单
│   ├── HARNESS_CHANGE_TEMPLATE.md      ← 高风险变更模板
│   ├── HARNESS_REVIEW_CHECKLIST.md     ← 审查检查清单
│   ├── DIRTY_WORKTREE_CLEANUP_LEDGER.md ← Worktree 清理台账
│   ├── AGENT-REGISTRY-SPEC.md          ← Agent Registry 规范
│   ├── WORKFLOW-STATE-GUIDE.md         ← 工作流状态指南
│   └── AWI-COMPLIANCE-BASELINE.md      ← Compliance Kernel 基线
│
├── SESSION_BOOT.md             ← 新会话自动加载序列
├── SESSION_SETUP.md            ← 多会话创建清单（bootstrap 生成）
├── USAGE.md                    ← AWI 一条命令导入与日常使用
├── TASK_TREES.md               ← 任务树定义（父子关系、依赖顺序）
├── FLOW-MODE.md                ← 心流模式协议（自主推进规则）
├── PROJECT_STATUS.md           ← 项目状态与执行台账
├── CONTINUATION_PROMPT.md      ← 跨会话续接提示词
├── context-preload.md          ← 上下文预加载配置
└── PROJECT-STRUCTURE.md        ← 本文件——项目结构说明
```

### 子项目文档（apps/quant_assistant/docs/）

| 文件 | 职责 |
|------|------|
| `PROJECT_STATUS.md` | 子项目执行台账与状态 |
| `TASK_TREES.md` | 子项目任务树 |
| `ARCHITECTURE.md` | 子项目架构设计 |
| `OPERATIONS.md` | 运行维护手册 |
| `SETUP.md` | 环境配置指南 |
| `SECURITY.md` | 子项目安全策略 |
| `WORKFLOWS.md` | 工作流定义（心流、任务流） |
| `TEST_STRATEGY.md` | 测试策略与目标 |
| `QUALITY_GATES.md` | 质量门禁定义 |
| `RELIABILITY.md` | 可靠性设计 |
| `HARNESS_ENGINEERING.md` | Harness 工程化实施 |
| `PLATFORM_MIGRATION_MAP.md` | 平台迁移映射 |
| `CONTINUATION_PROMPT.md` | 子项目续接提示词 |
| `README.md` | 子项目说明 |
| `financial_analysis.md` | 财务分析说明 |
| `ENGINEERING/` | 工程模板（Harness Gap Report 等） |
| `FACTOR_LIBRARY/` | 因子库规范 |
| `SOP/` | 标准操作程序（月回填、盘后补采等） |

---

## 七、应用层（Application Layer）

应用层是 raindeer 的核心业务实现——**A 股量化研究平台**。

```
apps/quant_assistant/
├── streamlit_app.py            ← Streamlit 主入口
├── pages/                      ← Streamlit 多页面
│   ├── Stock_Research.py       ← 个股研究
│   ├── Board_Research.py       ← 板块研究
│   ├── Factor_Evaluation.py    ← 因子评估
│   ├── Promoted_Assets.py      ← 推荐资产列表
│   ├── Promoted_Asset_Detail.py← 推荐资产详情
│   ├── Backtest_Workbench.py   ← 回测工作台
│   ├── Brain.py                ← AI 大脑编排
│   ├── Chat.py                 ← 对话助手
│   ├── History.py              ← 历史记录
│   └── Jobs.py                 ← 任务调度面板
│
├── src/qa/                     ← 核心业务代码
│   ├── __init__.py
│   ├── config.py               ← 配置加载
│   ├── env.py                  ← 环境变量（优先 .env.local > .env）
│   ├── models.py               ← 领域模型（frozen dataclass）
│   ├── logging.py              ← 日志系统
│   ├── paths.py                ← 路径管理
│   │
│   ├── db/                     ← 数据库层
│   │   ├── engine.py           ← PostgreSQL 连接引擎（psycopg2 + 参数化查询）
│   │   ├── queries.py          ← 查询函数库
│   │   ├── watermark.py        ← 数据水位管理
│   │   ├── schema.sql          ← 数据库 DDL
│   │   └── external_entity_cache.py ← 外部实体缓存
│   │
│   ├── datasources/            ← 数据源适配层
│   │   ├── tushare_client.py   ← Tushare 客户端封装
│   │   ├── cn_security_master.py   ← A 股证券主数据
│   │   ├── cn_daily_bar.py     ← 日线行情
│   │   ├── cn_daily_basic.py   ← 每日基本面
│   │   ├── cn_calendar.py      ← 交易日历
│   │   └── cn_boards.py        ← 板块数据
│   │
│   ├── factors/                ← 因子计算引擎
│   │   ├── registry.py         ← 因子注册表
│   │   └── compute.py          ← 因子计算核心
│   │
│   ├── backtest/               ← 回测引擎
│   │   ├── engine.py           ← 回测主引擎
│   │   ├── multifactor.py      ← 多因子回测
│   │   ├── metrics.py          ← 回测指标
│   │   └── cache.py            ← 回测缓存
│   │
│   ├── research/               ← 研究会话与产物管理
│   │   ├── models.py           ← 研究领域模型
│   │   ├── session_store.py    ← 会话持久化
│   │   ├── session_payloads.py ← 会话负载定义
│   │   ├── artifact_store.py   ← 产物持久化
│   │   ├── artifact_payloads.py← 产物负载定义
│   │   ├── fundamental_analysis.py  ← 基本面分析
│   │   ├── fundamental_refinement.py← 基本面精炼
│   │   └── services/           ← 研究服务（板块报告、个股报告等）
│   │
│   ├── jobs/                   ← 任务调度
│   │   ├── runner.py           ← 调度运行器
│   │   ├── job_ingest_daily_bar.py       ← 日线增量采集
│   │   ├── job_ingest_daily_bar_range.py ← 日线区间采集
│   │   ├── job_ingest_security_master.py ← 证券主数据采集
│   │   ├── job_ingest_boards_cn.py       ← 板块数据采集
│   │   ├── job_ingest_filings.py         ← 财报采集
│   │   ├── job_ingest_news_rss.py        ← 新闻 RSS 采集
│   │   ├── job_ingest_all_incremental.py ← 全量增量采集
│   │   ├── job_update_calendar_cn.py     ← 日历更新
│   │   ├── job_compute_factors.py        ← 因子计算
│   │   ├── job_generate_stock_report.py  ← 个股报告生成
│   │   └── job_asset_history_backfill.py ← 资产历史回填
│   │
│   ├── llm/                    ← LLM 集成
│   │   ├── deepseek.py         ← DeepSeek 适配
│   │   ├── ollama.py           ← Ollama 本地模型
│   │   └── intents.py          ← 意图识别
│   │
│   ├── brain/                  ← Brain 引擎（两阶段：TaskPlan → Dispatches）
│   │   ├── runtime.py          ← 运行时编排
│   │   ├── taskplan.py         ← 任务计划生成
│   │   ├── executors.py        ← 分发执行器
│   │   ├── router.py           ← 路由决策
│   │   ├── capabilities.py     ← 能力注册
│   │   └── provider_config.py  ← AI 供应商配置
│   │
│   ├── ai/tools/               ← AI 工具层（Fail-Closed 合同校验）
│   │   ├── contracts.py        ← 工具调用合同定义
│   │   └── research_tools.py   ← 研究工具实现
│   │
│   ├── filings/                ← 财报分析
│   │   ├── ingest.py           ← 财报采集
│   │   ├── metadata.py         ← 元数据管理
│   │   └── section_locator.py  ← 章节定位器
│   │
│   ├── news/                   ← 新闻处理
│   │   ├── ingest.py           ← 新闻采集
│   │   └── sources.py          ← 新闻源管理
│   │
│   ├── reports/                ← 报告生成
│   │   └── stock_report.py     ← 个股研究报告
│   │
│   ├── resolve/                ← 实体解析
│   │   ├── security_resolver.py ← 证券代码解析
│   │   └── trade_calendar.py   ← 交易日历
│   │
│   ├── external/               ← 外部服务集成
│   │   ├── eastmoney.py        ← 东方财富数据
│   │   ├── financial_reports.py← 财报外部数据
│   │   ├── baike.py            ← 百科数据
│   │   └── mineru.py           ← MinerU 文档解析
│   │
│   ├── a_share_history/        ← A 股历史数据子系统
│   │   ├── backfill_runner.py  ← 回填运行器
│   │   └── status.py           ← 回填状态
│   │
│   ├── ingest/                 ← 采集进度
│   │   └── progress.py         ← 进度追踪
│   │
│   └── ui/                     ← UI 组件
│       ├── router.py           ← 页面路由
│       ├── state.py            ← 状态管理
│       ├── auth.py             ← 认证组件
│       ├── backtest.py         ← 回测 UI
│       ├── board_research.py   ← 板块研究 UI
│       ├── brain_entry.py      ← Brain 入口
│       ├── brain_result_view.py← Brain 结果展示
│       ├── chat.py             ← 对话 UI
│       ├── chat_brain.py       ← Brain 对话
│       ├── equity_research_presenter.py ← 权益研究展示
│       ├── exporting.py        ← 导出功能
│       ├── factor_evaluation.py← 因子评估 UI
│       ├── history.py          ← 历史记录 UI
│       ├── jobs.py             ← 任务调度 UI
│       ├── job_chain.py        ← 任务链 UI
│       ├── pending.py          ← 待处理 UI
│       ├── promoted_assets.py  ← 推荐资产 UI
│       ├── promoted_asset_detail.py ← 推荐资产详情 UI
│       ├── report.py           ← 报告 UI
│       ├── stock_research.py   ← 个股研究 UI
│       └── artifact_consumption.py ← 产物消费 UI
│
├── tests/                      ← 测试套件（pytest）
│   ├── conftest.py             ← 全局 fixtures
│   └── test_*.py               ← 75+ 测试文件
│
├── tools/                      ← 工具脚本
│   ├── qa_env_check.py         ← 环境检查
│   └── _scratch/               ← 临时工具
│
├── scripts/ps/                 ← PowerShell 运维脚本
├── docs/                       ← 子项目文档（详见文档层）
├── tmp/                        ← 临时文件（日志、脚本）
├── pyproject.toml              ← 项目依赖与工具配置（uv + ruff + pytest）
├── uv.lock                     ← 依赖锁定
├── .python-version             ← Python 3.13
├── .env.example                ← 环境变量模板
├── Dockerfile                  ← Docker 构建
├── docker-compose.yml          ← 服务编排（PostgreSQL 16 + TimescaleDB）
└── streamlit_app.py            ← Streamlit 入口
```

---

## 八、记忆层（Memory Layer，.omx/）

`.omx/` 是 raindeer 的持久化记忆与目标追踪层，实现跨会话的状态保存与上下文恢复。

```
.omx/
├── memory.md                   ← 主记忆文件：项目知识图谱
├── memory-index.md             ← 记忆索引：快速检索入口
├── memory-search.ps1           ← 记忆搜索脚本
└── plans/                      ← 目标计划
    ├── README.md               ← 计划目录说明
    ├── omx-goal.json           ← 目标定义（ULTRA Goal 格式）
    ├── omx-research.json       ← 研究计划
    └── omx-standard.json       ← 标准计划模板
```

---

## 九、规则层（Rules Layer）

通用编码规则，跨项目、跨 IDE 复用。

```
rules/common/
├── agents.md                   ← 代理行为规则
├── api-design.md               ← API 设计规范
├── coding-style.md             ← 代码风格指南
├── database.md                 ← 数据库操作规范
├── patterns.md                 ← 设计模式约定
├── security.md                 ← 安全编码规则
└── testing.md                  ← 测试规范
```

---

## 十、缓存层（Cache Layer）

缓存策略与 Token 预算管理，服务于大规模上下文压缩和多方来源的缓存策略。

```
cache/
├── token-budget.md             ← Token 预算分配方案
├── caveman-prompt.md           ← Caveman 压缩策略
├── headroom-strategy.md        ← Headroom 策略
├── reasonix-cache.md           ← Reasonix 缓存策略
└── rtk-strategy.md             ← RTK 策略
```

---

## 十一、技术栈与约束

| 维度 | 选择 | 约束 |
|------|------|------|
| 语言 / 运行时 | Python 3.13 | Windows 优先 |
| 包管理 | uv | `uv sync --frozen --dev` |
| Web 框架 | Streamlit 1.45+ | 入口：`streamlit_app.py` |
| 数据库 | PostgreSQL 16 + TimescaleDB | psycopg2 参数化查询 |
| 测试框架 | pytest | markers: db, external；覆盖率 80%+ |
| Lint | ruff | E4, E7, E9, F |
| 领域模型 | `@dataclass(frozen=True, slots=True)` | `to_json()` / `from_json()` |
| 提交规范 | Conventional Commits | 英文 |

---

## 十二、目录创建顺序

当需要从零搭建 raindeer 工作区时，按以下顺序创建目录：

1. **根治理文件**：`CONSTITUTION.md` → `SOUL.md` → `AGENTS.md` → `RULES.md` → `SECURITY.md` → `SECURITY-ZONES.md`
2. **Harness 层**：`harness/` 全部文件（`init.ps1` 可自动创建）
3. **代理层**：`agents/` 全部 18 个代理
4. **技能层**：`.trae/skills/` 从 `skills/` 源文件同步
5. **文档层**：`docs/` → `docs/adr/` → `docs/ENGINEERING/`
6. **应用层**：`apps/quant_assistant/` 完整目录树
7. **规则层**：`rules/common/` 全部 7 个规则
8. **记忆层**：`.omx/` 目录结构与初始文件
9. **缓存层**：`cache/` 策略文件

---

## 十三、版本历史

| 版本 | 日期 | 变更说明 |
|------|------|----------|
| 1.0.0 | 2026-06-11 | 初始版本：完整描述 raindeer 九层项目结构 |
