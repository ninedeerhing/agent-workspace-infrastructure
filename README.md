# agent-workspace-infrastructure

> 面向超大型长期项目的 AI 工程工作区底层架构。一键导入，即刻开工。

## 一句话定位

为 AI 编码代理提供完整的操作契约、状态管理、验证闭环和技能生态——让代理在一个工程化的工作区中高效协作，无需从零搭建项目基础设施。

---

## 快速开始

### 导入（3 步）

1. **克隆本仓库**到目标项目目录：
   ```powershell
   git clone <repo-url> my-project
   cd my-project
   ```

2. **运行初始化脚本**：
   ```powershell
   .\bootstrap.ps1 -ProjectName "MyProject"
   ```

3. **在目标目录中打开 AI 编码工具**（Trae / Claude Code / Codex CLI），然后对 AI 代理说：

   > "加载 workspace，告诉我当前状态"

   代理将自动执行上下文预加载序列（CONSTITUTION.md → AGENTS-lite.md → .omx/memory.md → workflow-state.json → session-handoff.md），然后报告当前工作流阶段和下一步任务。

### 导入后立即开工

用户可以在导入后直接对代理说：

| 场景 | 指令 |
|------|------|
| 启动新项目 | "我要开发一个电商平台，技术栈 React+Node.js+PostgreSQL" |
| 粘贴 PRD | "这是我的 PRD：[粘贴详细设计]" |
| 恢复上下文 | "继续上次的开发" |
| 审查代码 | "审查 src/ 目录的代码质量" |
| 安全审计 | "对本次变更做安全审查" |

---

## 架构概览

```
agent-workspace-infrastructure/
├── CONSTITUTION.md         # 宪法级系统提示（最高优先级，不可协商）
├── AGENTS.md               # 代理指令主入口（14 原则 + 45 技能路由 + 5 层代理）
├── AGENTS-lite.md          # 执行层精简版（~40 行，快速加载）
├── SOUL.md                 # 核心身份与跨项目愿景
├── RULES.md                # 规则契约文件
├── SECURITY.md             # 安全策略文件
├── SECURITY-ZONES.md       # 运行时安全区定义
├── README.md               # 本文件
├── bootstrap.ps1           # 一键初始化脚本
├── .gitignore              # Git 忽略规则
│
├── agents/                 # 19 个专业代理角色（5 层分层）
│   ├── orchestrator.md     #   编排层：主编排器
│   ├── planner.md          #   规划层：需求拆解、任务排序
│   ├── architect.md        #   规划层：系统边界、技术权衡
│   ├── critic.md           #   规划层：反方挑战
│   ├── executor.md         #   执行层：有边界实现与重构
│   ├── explore.md          #   执行层：代码库探索
│   ├── debugger.md         #   执行层：根因分析
│   ├── code-reviewer.md    #   质量层：代码审查
│   ├── test-engineer.md    #   质量层：测试设计
│   ├── verifier.md         #   质量层：验收确认
│   ├── security-reviewer.md#   质量层：安全审查
│   ├── designer.md         #   产品层：UI/UX 设计
│   ├── qa-tester.md        #   产品层：手动验证
│   ├── writer.md           #   产品层：文档撰写
│   ├── analyst.md          #   需求分析
│   ├── scientist.md        #   科学分析
│   ├── tracer.md           #   因果追踪
│   ├── git-master.md       #   Git 操作
│   └── growth-engineer.md  #   能力累积
│
├── skills/                 # 45 个可复用工作流技能
│   ├── deep-interview/     #   苏格拉底式深度访谈
│   ├── ralplan/            #   多角色协作共识规划
│   ├── ultragoal/          #   多目标持久化跟踪
│   ├── prometheus-strict/  #   严格三阶段计划
│   ├── team-pipeline/      #   5 阶段团队流水线
│   ├── test-driven-development/ # Red-Green-Refactor
│   ├── session-retro/      #   会话复盘与模式提取
│   ├── skillify/           #   经验沉淀为技能
│   ├── capability-accumulation/ # 六层能力累积
│   ├── security-review/    #   安全审查
│   ├── ...（共 45 个技能，完整列表见 AGENTS.md §6）
│
├── harness/                # 状态管理中枢
│   ├── init.ps1            #   33 项自动验证脚本
│   ├── feature_list.json   #   功能模块追踪
│   ├── progress.md         #   进度日志
│   ├── session-handoff.md  #   会话交接
│   ├── workflow-state.json #   工作流状态机
│   ├── workflow-gates.md   #   28 条阶段门禁
│   ├── grader-types.md     #   5 种评分器 + pass@k
│   ├── clean-state-checklist.md # 清洁状态检查
│   ├── ci-cd-template.yml  #   CI/CD 模板
│   ├── archive/            #   归档引擎
│   │   ├── store.ps1       #     归档存储脚本
│   │   └── index.json      #     归档索引
│   └── templates/          #   工作流模板（standard/complex/product/tdd）
│
├── .omx/                   # OMX 兼容层
│   ├── memory.md           #   持久记忆
│   ├── memory-index.md     #   语义搜索规范
│   ├── memory-search.ps1   #   语义搜索脚本
│   └── plans/              #   工作流模板（JSON）
│
├── docs/                   # 文档与决策
│   ├── adr/                #   架构决策记录（ADR-001~004）
│   ├── research/           #   外部项目调研
│   ├── scaling-guide.md    #   大型项目扩展指南
│   ├── project-init-checklist.md   # 项目启动检查清单
│   ├── context-preload.md  #   上下文预加载规范
│   └── PROJECT-STRUCTURE.md        # 项目结构说明
│
├── rules/common/           # 编码规范（7 个）
│   ├── coding-style.md     #   代码风格
│   ├── testing.md          #   测试规范
│   ├── security.md         #   安全规范
│   ├── api-design.md       #   API 设计规范
│   ├── database.md         #   数据库规范
│   ├── patterns.md         #   设计模式
│   └── agents.md           #   代理规范
│
├── cache/                  # Token 优化策略（5 个）
│   ├── caveman-prompt.md   #   极限压缩通信
│   ├── rtk-strategy.md     #   推理-令牌-知识框架
│   ├── headroom-strategy.md#   智能上下文压缩
│   ├── reasonix-cache.md   #   Prefix-Cache 稳定性
│   ├── token-budget.md     #   Token 预算综合管理
│   └── scripts/            #   辅助脚本
│
├── design-architecture/    # 前端设计六层架构（TypeScript）
│   ├── src/
│   │   ├── core/           #   核心类型 + 主题引擎
│   │   ├── design/         #   设计令牌 + 技能
│   │   ├── copilot/        #   Copilot 层
│   │   └── animation/      #   动画引擎
│   ├── package.json
│   ├── tsconfig.json
│   └── DESIGN.md
│
└── .trae/rules/            # Trae IDE 专用规则
    └── project_rules.md
```

---

## 核心方法论

TRAE Workspace 融合了 20+ 个开源项目的精华，形成五大工程支柱：

### 支柱 1：Harness Engineering（工程体系）

来源：learn-harness-engineering、superpowers

- **五子系统**：Instructions / State / Verification / Scope / Lifecycle
- **TDD 强制**：Red-Green-Refactor 循环，目标覆盖率 80%+
- **28 条阶段门禁**：覆盖 standard / complex / product / tdd 四种工作流
- **33 项自动验证**：`harness/init.ps1` 一键检查所有基础设施

### 支柱 2：OMX 工作流（任务编排）

来源：oh-my-codex、oh-my-openagent

| 路径 | 流程 | 适用场景 |
|------|------|----------|
| **默认路径** | deep-interview → ralplan → ultragoal | 常规功能开发 |
| **严格模式** | prometheus-strict（Interview→Critique→Synthesize） | 高风险架构决策 |
| **研究边界** | best-practice-research / autoresearch / autoresearch-goal | 不熟悉的技术栈 |
| **并行模式** | team-pipeline / sciomc | 多模块协同 |
| **持续模式** | ralph-loop | 长期迭代优化 |

### 支柱 3：ECC 质量体系（验证闭环）

来源：Enterprise Coding Conventions

- **5 种评分器**：G-CORRECT / G-COMPLETE / G-STYLE / G-SECURE / G-PERF
- **pass@k 质量指标**：多次采样通过率
- **六维度评估**：Token Optimization / Memory Persistence / Continuous Learning / Verification Loops / Parallelization / Subagent Orchestration
- **验证优先级**：目标测试 → 类型检查/Lint → 构建 → 冒烟/E2E → 手动审查

### 支柱 4：记忆与持久化（长期知识）

来源：mempalace、everos、hermes-agents

- **分层记忆**：核心记忆（.omx/memory.md）+ 全文搜索（memory-index）+ 归档（archive/）
- **语义搜索**：三阶段检索流水线 + 9 因子加权评分
- **闭环学习**：session-retro → skillify → capability-accumulation，自动触发
- **会话连续性**：session-handoff + context-preload + 上下文快照

### 支柱 5：安全体系（运行时防御）

来源：personal_AI_infrastructure、ECC

- **宪法级提示**：CONSTITUTION.md（不可协商规则，最高优先级）
- **三级安全区**：🟢 自由区 / 🟡 保护区 / 🔴 禁区
- **Prompt Defense Baseline**：6 条规则防注入和泄露
- **密钥审计**：init.ps1 自动检测硬编码凭证

---

## 代理分层

| 层级 | 角色 | 职责 |
|------|------|------|
| **编排层** | orchestrator | 选择流程、同步状态、拆分任务、整合结果 |
| **规划层** | planner、architect、critic | 需求拆解、系统边界、反方挑战 |
| **执行层** | executor、explore、debugger | 有边界实现、代码探索、根因分析 |
| **质量层** | code-reviewer、test-engineer、verifier、security-reviewer | 代码审查、测试设计、验收、安全 |
| **产品层** | designer、qa-tester、writer | UI/UX、手动验证、文档 |
| **专项层** | analyst、scientist、tracer、git-master、growth-engineer | 需求分析、数据分析、因果追踪、版本控制、能力累积 |

---

## 各模块评分

| 模块 | 评分 | 说明 |
|------|------|------|
| 项目初始化 | 4/5 | 完整 checklist + CI 模板，缺一键脚手架 |
| 架构设计规范 | 5/5 | ADR 4 个 + patterns.md + 5 层代理分层 |
| 工作流管理 | 5/5 | 4 工作流 + 28 门禁 + 状态机 |
| 代理角色体系 | 5/5 | 19 个 5 层分层，无冗余 |
| 技能生态 | 5/5 | 45 技能 + 链式调用 + 路由表 |
| 测试体系 | 4/5 | TDD 强制 + 5 评分器 + pass@k |
| 代码质量 | 5/5 | G-CORRECT + G-STYLE 10 检查项 |
| 安全体系 | 5/5 | CONSTITUTION + ZONES + Prompt Defense + 密钥审计 |
| 长期记忆 | 4/5 | OMX + archive + 语义搜索，缺自动降维 |
| 语义搜索 | 4/5 | memory-index + memory-search.ps1，缺向量嵌入 |
| 会话连续性 | 5/5 | session-handoff + handoff prompt + context-preload |
| 健康监控 | 4/5 | 4 脚本（heartbeat + degradation + self-healing + monitor） |
| 闭环学习 | 4/5 | retro → skillify → capability 自动触发 |
| 个人成长追踪 | 4/5 | growth-engineer + 六维能力雷达 |
| 任务调度 | 3/5 | task-queue 规范，缺实现 |
| 代理间通信 | 3/5 | inter-agent-comm 规范，缺消息总线 |
| Token 优化 | 4/5 | 4 策略 + caveman + token-budget |
| 前端设计 | 4/5 | design-architecture/ 六层 + TypeScript 零错误 |
| 数据库规范 | 4/5 | database.md 覆盖迁移 + 索引 + 查询 |
| API 设计规范 | 4/5 | api-design.md 覆盖 RESTful + 版本 + 分页 |

**综合评分：4.3 / 5 — 可以开启大型长期项目**

---

## 参考项目矩阵

本工作区从以下 20+ 个开源项目中提炼方法论和最佳实践：

| 项目 | 学习要点 | 融入模块 |
|------|----------|----------|
| **learn-harness-engineering** | 五子系统工程方法论、TDD 循环 | CONSTITUTION、AGENTS.md、harness/ |
| **superpowers** | 代理角色定义、技能路由 | agents/、skills/ |
| **oh-my-codex** | OMX 工作流编排、状态管理 | .omx/、workflow-state.json |
| **oh-my-openagent** | 开放代理框架、门禁系统 | workflow-gates.md |
| **mempalace** | 分层记忆架构、持久化存储 | .omx/memory.md、archive/ |
| **everos** | 代理间通信协议、任务队列 | docs/research/everos-*.md |
| **hermes-agents** | 多代理协调、消息传递 | agents/orchestrator.md |
| **personal_AI_infrastructure** | 安全区划分、宪法级规则 | CONSTITUTION.md、SECURITY-ZONES.md |
| **Enterprise Coding Conventions** | 评分器体系、质量度量 | grader-types.md、rules/common/ |
| **claude-code-superpowers** | 子代理驱动开发、TDD 工作流 | subagent-driven-dev、test-driven-development |
| **deepseek-reasonix** | Prefix-Cache 稳定性策略 | cache/reasonix-cache.md |
| **YC Office Hours** | 产品可行性评估框架 | skills/office-hours/ |
| **Karpathy Guidelines** | LLM 编码反模式规避 | skills/karpathy-guidelines/ |
| **RALPH Loop** | 自引用持久循环执行 | skills/ralph-loop/ |
| **CCG（Claude-Codex-Gemini）** | 三模型协作审查 | skills/ccg/ |
| **Diataxis Framework** | 技术文档四象限体系 | skills/writer/ |
| **Conventional Commits** | 规范化提交信息 | agents/git-master.md |
| **Git Worktrees** | 并行隔离开发环境 | skills/using-git-worktrees/ |

---

## 工作流选择指南

```
你要做什么？
├── 启动新项目
│   └── 运行 bootstrap.ps1 → 说"加载 workspace"
├── 开发新功能
│   └── deep-interview → brainstorming → ralplan → TDD → code-review
├── 修复 Bug
│   └── systematic-debugging → TDD → verification-before-completion
├── 重构代码
│   └── code-review（评估） → TDD → code-review（审查）
├── 安全审计
│   └── security-review
├── 技术调研
│   └── best-practice-research / autoresearch
├── 发布上线
│   └── finishing-dev-branch → qa-testing → ship-release
├── 会话结束
│   └── session-retro → handoff
└── 能力成长
    └── capability-accumulation → skillify
```

---

## 许可证

MIT

## 作者

TRAE Workspace Harness System
