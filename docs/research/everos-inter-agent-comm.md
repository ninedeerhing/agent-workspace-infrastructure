# EverOS 代理间通信机制分析

> **来源**：EverOS GitHub 仓库 (`EverMind-AI/EverOS`)，官方文档 `docs/architecture.md`、`docs/how-memory-works.md`、`docs/api.md`、官方网站 `evermind.ai/everos`
> **分析日期**：2026-06-09
> **系统版本**：EverOS 1.0.0

---

## 1. 概述

EverOS 并非一个代理编排系统——它不直接管理代理之间的实时消息传递或任务委派。EverOS 的代理间通信模型是 **基于共享记忆的间接通信**（Shared Memory Communication）。代理之间通过共享的持久化记忆存储（Markdown 文件系统）交换信息，而非通过消息队列或 RPC。这种设计使得不同平台、不同编程语言的代理可以在不耦合通信协议的情况下共享知识。

---

## 2. 通信模型：共享记忆即通信信道

```
┌──────────────┐                    ┌──────────────┐
│   Agent A    │                    │   Agent B    │
│  (Claude)    │                    │  (Codex)     │
└──────┬───────┘                    └──────┬───────┘
       │ 写入 Cases/Skills                 │ 读取 Cases/Skills
       ▼                                   ▼
┌─────────────────────────────────────────────────────┐
│                  EverOS Memory Root                  │
│  ~/.everos/<app>/<project>/                          │
│  ├── agents/<agent_a>/.cases/    ← Agent A 轨迹      │
│  ├── agents/<agent_a>/skills/    ← Agent A 技能      │
│  ├── agents/<agent_b>/.cases/    ← Agent B 轨迹      │
│  └── agents/<agent_b>/skills/    ← Agent B 技能      │
└─────────────────────────────────────────────────────┘
```

**核心原则**：通信 = 一个代理写入记忆 + 另一个代理检索该记忆。没有实时消息通道——所有通信都是异步的、基于存储的。

---

## 3. 记忆分区与代理隔离

### 3.1 Scope 隔离体系

EverOS 的多级 scope 系统控制代理之间的数据可见性边界：

```
global → team → project → group → session
```

每个级别的语义：

| 层级 | 目录映射 | 可见性 |
|------|---------|--------|
| **app_id** | `~/.everos/<app>/` | 应用级隔离（不同 app 完全隔离） |
| **project_id** | `~/.everos/<app>/<project>/` | 项目级隔离 |
| **user_id** | `.../users/<user_id>/` | 用户专属记忆（episodes、facts、foresight、profile） |
| **agent_id** | `.../agents/<agent_id>/` | 代理专属记忆（cases、skills） |

### 3.2 跨 Scope 搜索规则

`/search` 和 `/get` 查询 **从不跨越 scope**——不同 `(app_id, project_id)` 对完全隔离。这确保了一个代理的记忆不会泄露到另一个不相关的应用上下文中，同时允许同一项目内的代理共享记忆。

---

## 4. 代理间通信的四种模式

### 4.1 Case 共享 — 经验轨迹传播

**通信方向**：代理 → 所有同 Scope 代理

每个代理完成的任务被记录为 **Case（案例/训练轨迹）**：

```
agents/<agent_id>/.cases/agent_case-2026-06-09.md
```

Case 包含：
- 任务描述和上下文
- 执行步骤和工具调用轨迹
- 成功/失败结果
- 经验教训

**跨代理读取**：当 Agent B 在执行类似任务时，通过 `/search` 检索 Agent A 的历史 Cases，获取前人的经验。这不依赖 Agent A 实时在线——Agent A 可能在几天前就已经写入了这些 Cases。

### 4.2 Skill 自进化 — 程序性知识跨代理传播

**通信方向**：代理轨迹 → 聚类蒸馏 → 所有代理

这是 EverOS 最具特色的代理间通信机制——**Skill Self-Evolution**（技能自进化）：

```
Agent A 执行任务 → Case (轨迹记录)
Agent B 执行类似任务 → Case (轨迹记录)
Agent C 执行类似任务 → Case (轨迹记录)
     │
     ▼
OME extract_agent_skill 策略检测到关联 Cases 聚类
     │
     ▼
自动蒸馏为 Skill (skills/skill_<name>/SKILL.md)
     │
     ▼
Agent D 检索到该 Skill → 直接复用成功模式
```

Skills 存储在 `agents/<agent_id>/skills/skill_<name>/SKILL.md` 中，是目录级命名单元，可选附带 `references/` 和 `scripts/` 子目录。

**通信隐喻**：这好比一个团队中，老员工的工作经验被自动整理成 SOP（标准操作流程），新员工可以直接查阅学习，而无需逐个请教老员工。整个过程由 OME 引擎离线自动完成，无需人工干预。

### 4.3 User Memory 共享 — 用户上下文作为全局上下文

**通信方向**：用户 → 所有代理

用户级记忆（Profile、Episodes、Atomic Facts、Foresight）对所有同 Scope 的代理可见：

```
users/<user_id>/
├── user.md              ← 用户画像（全局可见）
├── episodes/            ← 对话历史（全局可见）
├── .atomic_facts/       ← 原子事实（全局可见）
└── .foresights/         ← 预测记忆（全局可见）
```

**实际场景**：用户跟 Agent A（编码助手）提起过"我们的部署用的是 Docker Compose"，之后 Agent B（运维助手）在执行部署任务时自动检索到这个偏好，不需要用户重复说明。

### 4.4 Knowledge Base 共享 — 非对话知识的跨代理访问

**通信方向**：外部知识 → 所有代理

```
knowledge/
└── <文件导入的知识条目>
```

通过 multimodal ingestion（PDF、图片、Office 文档、URL 等）导入的知识，对所有代理可见。这是一种 **非对话来源的共享上下文**。

---

## 5. 外部代理系统集成（MCP 协议）

### 5.1 集成点

EverOS 通过 MCP（Model Context Protocol）与外部代理框架对接：

```
Claude Code ──→ MCP ──→ EverOS API
Codex CLI  ──→ MCP ──→ EverOS API
OpenClaw   ──→ MCP ──→ EverOS API
Hermes     ──→ MCP ──→ EverOS API
```

### 5.2 API 接入模式

外部代理使用标准 HTTP API 进行记忆存取：

```
POST /api/v1/memory/add     — 添加消息到缓冲
POST /api/v1/memory/flush   — 强制提取记忆
POST /api/v1/memory/search  — 检索记忆（hybrid: vector + BM25 + scalar filter）
POST /api/v1/memory/get     — 按 ID 精确获取记忆
```

### 5.3 跨平台代理共享记忆的约束

- **统一 memory root**：不同代理工具共享同一个 `~/.everos/` 目录
- **无锁冲突**：Markdown 文件由 daily-log 追加或单文件覆写，天然隔离
- **无协议耦合**：代理不需要知道对方的网络地址或进程 ID，只需读取相同的 markdown 文件

---

## 6. 实时案例：Golutra 多代理编排平台

Golutra 是 EverOS 生态中的一个生产级多代理编排平台，展现了代理间通信的实际模式：

```
Golutra Multi-Agent Workforce
├── 编码代理 (Claude Code)
│   └── 写入 Cases: 代码模式、项目约定、常见错误
├── 审查代理 (Codex)
│   ├── 读取编码代理的 Cases
│   └── 写入 Cases: 审查模式、常见问题
├── 测试代理 (Gemini)
│   ├── 读取编码代理和审查代理的 Cases
│   └── 写入 Cases: 测试策略、回归模式
└── 运维代理 (OpenCode)
    └── 读取所有代理的 Cases 和 Skills
```

**工作流示例**：
1. 编码代理提交 PR → 写入 Case（含代码变更和上下文）
2. 审查代理被触发 → 检索该 Case → 执行审查 → 写入审查结论 Case
3. 测试代理检索两个 Cases → 生成针对性测试 → 写入测试结果 Case
4. OME 检测到多个类似 PR 的审查模式 → 自动蒸馏出 "PR Review Checklist" Skill
5. 下次审查代理直接复用该 Skill，跳过重新学习

---

## 7. 通信保证与限制

### 7.1 保证

| 维度 | 机制 |
|------|------|
| **持久性** | Markdown 文件 fsync 写入，崩溃不丢失 |
| **最终可达性** | Cascade daemon 将变更索引到 LanceDB，检索可见 |
| **隔离性** | Scope (app_id/project_id) 控制可见性边界 |
| **无锁并发** | Daily-log 追加 + 单文件覆写避免跨代理写冲突 |

### 7.2 限制

| 维度 | 说明 |
|------|------|
| **非实时** | OME 策略执行和 cascade 索引存在延迟（秒级） |
| **无推送** | 代理必须主动检索才能获取其他代理的记忆——没有事件通知 |
| **无事务** | 跨代理的原子操作需要上层编排系统自行实现 |
| **单进程** | 所有代理操作同一 memory root，不支持分布式跨机器共享（可通过网络文件系统解决） |

### 7.3 冲突处理

由于 markdown 是真相来源，**如果两个代理同时修改同一个文件**（如都在追加同一个 agent case），依赖文件系统的原子性保证：
- Daily-log 追加：每个条目有唯一 `entry_id`，追加本身是原子的（单行写入）
- 单文件覆写：最后一个写入者胜出（last-writer-wins），但有 SQLite 审计追踪

---

## 8. 与常见代理通信模型的对比

| 模型 | 代表系统 | 通信方式 | 实时性 | 持久性 |
|------|---------|---------|--------|--------|
| **共享记忆** | **EverOS** | Markdown 读写 | 最终一致（秒级） | 强（fsync） |
| 消息队列 | Celery + Redis | 消息推送 | 实时 | 弱（需配置持久化） |
| 邮箱模式 | OMC Team Runtime | 邮箱投递 | 实时 | 取决于实现 |
| RPC/API | LangChain Multi-Agent | HTTP/gRPC | 实时 | 无内置 |
| 黑板模式 | 传统 AI 系统 | 共享数据结构 | 实时 | 取决于实现 |
| 事件总线 | AutoGen | Pub/Sub | 实时 | 取决于实现 |

**EverOS 共享记忆模式的独特优势**：
- 不需要代理同时在线——Agent A 昨天的工作成果，Agent B 今天可检索利用
- 跨平台零耦合——Claude Code 和 Codex CLI 不需要直接对话，通过 markdown 文件间接交换
- 自动知识蒸馏——Skill Self-Evolution 将原始轨迹转化为可复用的结构化知识
- Git 友好——Markdown 文件可版本控制，代理间的知识传递有完整历史

---

## 9. 与 TRAE Workspace 的对照

| 维度 | EverOS (共享记忆) | TRAE Workspace (Harness) |
|------|-------------------|--------------------------|
| 通信模型 | Markdown 文件系统 | 文件系统（harness/ 目录） |
| 代理寻址 | 无寻址（通过文件路径） | 无寻址（通过状态文件） |
| 记忆分区 | app_id / project_id 多级 scope | goal / feature / todo 功能分区 |
| 知识共享 | Cases → Skills 自动蒸馏 | 技能文件（skills/）手动维护 |
| 跨平台 | MCP + HTTP API | 文件系统（平台无关） |
| 崩溃恢复 | LSN + cascade 重放 | archive 快照机制 |

**可借鉴模式**：
1. **Case → Skill 蒸馏管道**：TRAE Workspace 可以引入类似的"操作轨迹→技能模板"自动提取机制
2. **多级 Scope 隔离**：当前的 AGENTS.md / feature_list.json 可以引入项目级/工作组级分区
3. **Markdown 作为真相来源**：与 TRAE Workspace 的 Markdown-first 文档策略天然契合
4. **非实时通信的优势**：代理间通信不要求同时在线，降低编排复杂度
