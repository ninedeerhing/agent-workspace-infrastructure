# Raindeer-AWI 北极星规格

**版本**: 0.1.0  
**日期**: 2026-06-15  
**状态**: 目标态定义（驱动 `AWI-RUNTIME-IMPROVEMENT-PLAN.md`）  
**一句话**: 导入架构后，用户只与**中枢调度**对话；其余 Agent 在后台按 Raindeer-AWI 全约束自动协作，跨 Trae / Cursor / Codex / Claude Code 均可运行，无需用户提醒。

---

## 1. 用户可感知的目标态

### 1.1 导入后一次配置

```text
bootstrap.ps1 -TargetPath <项目> -Mode full -ProvisionTeam default
```

执行完成后，项目文件夹内应具备：

| 能力 | 用户感知 |
|------|----------|
| 多会话 Agent 团队 | 项目下已创建/登记 N 个工作会话（或平台等价物），各有名称、模型、职责边界 |
| 本地 Skills | `skills/` 已部署，各平台入口已注册（Cursor rules / Trae `.trae/` / AGENTS.md 路由） |
| 中枢会话 | **仅 `orchestrator`**（`agents/orchestrator.md`）供用户日常对话 |
| 工作会话 | `agents/` 下**除 orchestrator 外**的每一个角色各一会话，**不对用户搭话**，只响应中枢或 mailbox |
| 全约束生效 | Harness、心流、任务树、台账、Token 压缩、门禁、安全区——**全程自动**，不靠用户 `@` 提醒 |

### 1.2 日常使用（理想路径）

```text
用户 ──仅对话──► 中枢调度（orchestrator）
                      │
          ┌───────────┼───────────┬──────────────┐
          ▼           ▼           ▼              ▼
      planner    executor    verifier    … agents/ 下其余 worker
          │           │           │              │
          └───── harness/mailbox / 平台消息 API ─┘
                      │
          PROJECT_STATUS §5 / workflow-state / worklogs
```

用户说：「做这个功能 / 继续上次 / 为什么出这个 bug」——其余全部由中枢分解、投递、验收、追溯。

---

## 2. 设计公理（不可妥协）

以下公理优先级高于任何平台便利性或单次任务效率：

| # | 公理 | 含义 |
|---|------|------|
| A1 | **协议不架空** | CONSTITUTION → SOUL → AGENTS → RULES → SECURITY → 技能/角色；任何 Agent 不得声明例外 |
| A2 | **文件即真相** | 完成态以 `harness/` + `docs/PROJECT_STATUS.md` §5 为准，不以对话记忆为准 |
| A3 | **单前台主线** | `TASK_TREES.md` 规则对所有 Agent 生效；worker 不得私自开第二条主线 |
| A4 | **中枢对外** | 仅 **`orchestrator`** 会话接收用户意图；`agents/` 下其余角色均为 worker，`need_question` 必须经 orchestrator 转述用户 |
| A5 | **证据链强制** | 阶段切换过 gate；变更过 ledger；验证过命令留证据 |
| A6 | **平台可替换** | 项目内 `harness/` 协议层不变；平台差异仅落在 **Adapter** |
| A7 | **Token 预算内建** | 上下文超阈值自动走压缩技能链，不由用户说「太长了」才触发 |

---

## 3. 四层架构（Raindeer Control Plane）

```text
┌─────────────────────────────────────────────────────────────────┐
│ L4  Human Surface          用户 ↔ orchestrator（agents/orchestrator.md，唯一）│
├─────────────────────────────────────────────────────────────────┤
│ L3  Orchestration          中枢：路由、定档、投递、验收、追溯       │
│        team-pipeline + omo-agent-router + gate-runner            │
├─────────────────────────────────────────────────────────────────┤
│ L2  Compliance Kernel      每回合强制：boot / ledger / gate /    │
│        token-budget / FLOW-MODE 白名单 / SECURITY-ZONES          │
├─────────────────────────────────────────────────────────────────┤
│ L1  Protocol（已有）       AGENTS / FLOW-MODE / TASK_TREES /     │
│        pipeline-dag / workflow-gates / skills / agents           │
├─────────────────────────────────────────────────────────────────┤
│ L0  Platform Adapters      Cursor | Codex | Claude Code | Trae | … │
│        会话创建 / 跨会话消息 / Hooks / Skills 注册                  │
└─────────────────────────────────────────────────────────────────┘
```

**关键转变**：现有仓库主要是 L1；北极星要求 **L2 + L3 + L0** 可执行，而非仅文档。

---

## 4. Agent 团队 roster（= `agents/` 目录）

**不另造角色名**。团队 roster 与仓库 `agents/*.md` **一一对应**：

| 类型 | role_id | 源文件 | 与用户对话 |
|------|---------|--------|------------|
| **中枢** | `orchestrator` | `agents/orchestrator.md` | ✅ **唯一** |
| **Worker** | 见下表 | `agents/{role_id}.md` | ❌ 禁止 |

### 4.1 Worker 全表（`agents/` 除 orchestrator 外共 17 个）

| role_id | 分层（AGENTS.md §7） | 一句话职责 |
|---------|----------------------|------------|
| `planner` | 规划层 | 需求拆解、任务排序、风险 |
| `architect` | 规划层 | 系统边界、架构决策 |
| `critic` | 规划层 | 反方挑战、盲点发现 |
| `explore` | 执行层 | 快速代码库探索 |
| `executor` | 执行层 | 有界实现与重构 |
| `debugger` | 执行层 | 根因分析、回归隔离 |
| `test-engineer` | 质量层 | 测试设计、覆盖率 |
| `verifier` | 质量层 | 完成证据、验收 |
| `code-reviewer` | 质量层 | 逻辑缺陷、可维护性 |
| `security-reviewer` | 质量层 | 秘密、注入、授权 |
| `qa-tester` | 质量层 | 浏览器/CLI 手动验证 |
| `designer` | 产品层 | UI/UX、设计系统 |
| `writer` | 产品层 | 文档、发布说明 |
| `scientist` | 扩展 | 科学研究、多维度分析 |
| `tracer` | 扩展 | 追踪、链路调查 |
| `git-master` | 扩展 | Git 工作流、发布分支 |
| `growth-engineer` | 成长层 | 能力累积、技能化 |

> **bootstrap 默认行为**：为上表 **每一个 role_id** 登记 `agent-registry.json` 并生成 mailbox/worklog；平台适配器尽力为每个 worker **各建一会话**（无法全自动时输出清单，但 registry 仍完整）。

### 4.2 orchestrator 路由（不是固定三角）

用户只对 orchestrator 说话；orchestrator 按 `omo-agent-router` / `AGENTS.md` §7 将任务投递给**当前任务需要的 worker 子集**，而非永远 planner→executor→verifier。

典型链路示例（非唯一模板）：

```text
探索代码     → explore
定方案       → planner (+ 可选 architect, critic)
写实现       → executor (+ 可选 debugger)
写测试       → test-engineer
独立验收     → verifier / qa-tester
代码审查     → code-reviewer
安全审查     → security-reviewer
文档         → writer
UI           → designer
```

### 4.3 消息契约

统一使用 `agents/contracts/agent-tool-contracts.json` 中的类型：

- `dispatch_task`（orchestrator → 任意 worker）
- `report_changes`（worker → orchestrator 或上游 worker）
- `fix_request`（orchestrator / verifier / planner → executor 等）
- `acceptance_result`（verifier / planner → orchestrator）
- `blocked`（任意 worker → orchestrator，**不得直达用户**）

每条消息：

```json
{
  "msg_id": "MSG-2026-06-15-001",
  "correlation_id": "TASK-tree-rt-001",
  "from": "orchestrator",
  "to": "executor",
  "type": "dispatch_task",
  "tree_id": "TREE-RT",
  "payload": {},
  "created_at": "ISO8601",
  "requires_ack": true
}
```

存储路径：`harness/mailbox/{role}/inbox/` → 处理后移至 `processed/`。

---

## 5. 平台抽象层（PAL）

### 5.1 Adapter 接口（逻辑契约）

每个平台实现同一套能力；缺失能力由 **文件总线降级**，不得改协议。

| 能力 | 说明 | 降级方案 |
|------|------|----------|
| `detect()` | 检测当前是否在该平台环境 | 无 |
| `provision_sessions(team_manifest)` | 创建/登记多会话 | 输出「手动创建清单」+ 写 registry |
| `send_message(from, to, payload)` | 跨会话投递 | 写 mailbox JSON |
| `read_inbox(role)` | 读待处理消息 | 读 mailbox 目录 |
| `register_skills(skills_dir)` | 注册本地 skills | 复制到平台约定路径 |
| `install_hooks(compliance_kernel)` | 安装回合级强制 | 文档化手动步骤 + CI 补偿 |
| `bind_model(role, model_id)` | 绑定模型 | registry 记录，人工在 UI 设置 |

### 5.2 平台矩阵（当前能力与目标）

| 平台 | 规则入口 | 跨会话消息 | 自动建会话 | Hooks | 目标适配器路径 |
|------|----------|------------|------------|-------|----------------|
| **Cursor** | `.cursor/rules/` | SDK `Agent.send` / mailbox | SDK / 半自动 | `.cursor/hooks.json` | `harness/adapters/cursor/` |
| **Codex** | `AGENTS.md` | 原生 `send_message` | API | 待调研 | `harness/adapters/codex/` |
| **Claude Code** | `AGENTS.md` / `CLAUDE.md` | 子代理 / mailbox | CLI 待调研 | 待调研 | `harness/adapters/claude-code/` |
| **Trae** | `.trae/rules/` | mailbox + IDE API | bootstrap 生成 | Trae hooks 待调研 | `harness/adapters/trae/` |
| **通用** | `AGENTS.md` | **mailbox（必选基线）** | registry 模板 | `compliance-check.ps1` | `harness/adapters/generic/` |

**原则**：`generic` 适配器必须 100% 可用；其他适配器是增强，不是前提。

---

## 6. Compliance Kernel（合规内核）

合规内核是 L2，确保 **任何 Agent、任何平台** 不能绕过 Raindeer-AWI。

### 6.1 触发点

| 时机 | 动作 | 失败策略 |
|------|------|----------|
| 会话启动 | 读 `SESSION_BOOT.md` + 当前 TREE + workflow-state | 禁止执行工具直至确认已读 |
| 每回合开始（worker） | 扫 inbox；更新 worklog 头 | 有未 ack 消息则优先处理 |
| 工具写文件后 | 检查 §5 台账是否需要条目 | soft → hard（Phase 2+） |
| 阶段切换 | `gate-runner.ps1` | FAIL 则不得标称下一阶段 |
| 上下文 >70% | 触发 `$caveman-token-compress` / `$omc-conversation-continuity` | 自动 handoff，不经用户 |
| 任务闭环 | `$verification-before-completion` + ledger | 无证据不得 DONE |
| 定时 | `compliance-check.ps1` via schedule | 报告写入 harness |

### 6.2 orchestrator 与 Worker 的差异

| 项 | orchestrator | Worker（agents/ 下其余 17 个） |
|----|--------------|--------------------------------|
| 与用户对话 | ✅ 唯一 | ❌ 禁止（BLOCKED 仅 → orchestrator） |
| 角色定义来源 | `agents/orchestrator.md` | 同名 `agents/{role_id}.md` |
| FLOW-MODE 心流 | 对用户短播报 | 内部全速处理 inbox 直至清空或 BLOCKED |
| 停止白名单 | 可触发交付给用户 | 不可直接触发；须上报 orchestrator |

---

## 7. Bootstrap 扩展规格

在现有 `bootstrap.ps1` 上增加 **Team Provisioning** 阶段：

```powershell
.\bootstrap.ps1 -TargetPath . -Mode full -ProvisionTeam default `
  -Platform auto `                    # auto | cursor | codex | claude-code | trae | generic
  -HubModel "opus" `                       # orchestrator 模型，写入 registry
  -WorkerModels @{ } `                     # 可选：按 role_id 覆盖；默认用 manifest 建议值
```

### 7.1 Provision 步骤

1. **Deploy L1** — 现有 full/minimum 逻辑  
2. **Init L2** — `compliance-check.ps1`、`gate-runner.ps1`、`SESSION_BOOT.md`、hooks 模板  
3. **Init L3** — 扫描 `agents/*.md` 生成完整 `agent-registry.json`（orchestrator + 全部 worker）、`mailbox/`、`worklogs/`
4. **Run PAL** — 检测平台 → 调用 adapter → 写 `harness/platform-binding.json`  
5. **Emit Hub First Message** — 生成中枢初始化 prompt（职责、团队目录、禁止事项）  
6. **Verify** — `compliance-check.ps1 -Mode post-bootstrap`  

### 7.2 产物目录（新增）

```text
harness/
  agent-registry.json          # 团队登记表
  platform-binding.json        # 当前平台与 adapter 版本
  team-manifest.default.json   # 与 agents/ roster 同步的默认清单
  mailbox/{role}/inbox|processed/
  worklogs/{role}.md
  adapters/{platform}/
  compliance-check.ps1
  gate-runner.ps1
  hooks/
docs/
  SESSION_BOOT.md              # 所有 Agent 统一启动契约
```

---

## 8. Skills 与 Token 压缩（全自动）

| 场景 | 自动触发技能 | 配置来源 |
|------|-------------|----------|
| 新会话 | context-preload 序列 | `SESSION_BOOT.md` |
| 路由不明 | `$omo-agent-router` | orchestrator 首回合或每次新任务 |
| 写代码前 | `$test-driven-development` | executor 契约 |
| 完成前 | `$verification-before-completion` | Compliance Kernel |
| 上下文 >70% | `$omc-conversation-continuity` | `harness/token-budget.json` |
| 高密度协作 | `$caveman-token-compress` | worker 间消息可选 lite 模式 |
| 闭环学习 | `$session-retro` / `$skillify` | ≥3 文件变更 |

`harness/token-budget.json`（待建）定义阈值与技能链，Compliance Kernel 读取执行，**用户不得记得调用 `$` 技能名**。

---

## 9. 「零提醒」如何技术上成立

用户不提醒的前提 = **提醒职责从人转移到内核**：

| 过去（失败模式） | 未来（北极星） |
|------------------|----------------|
| 用户 `@FLOW-MODE.md` | sessionStart Hook 注入 |
| 用户「记得写台账」 | post-edit + CI compliance |
| 用户复制规划给开发 | Hub 写 mailbox / adapter send_message |
| 用户新开对话贴 handoff | `$omc-conversation-continuity` 自动 + registry 绑定 |
| 用户选模型 | bootstrap 写入 registry，adapter 尽力自动绑定 |
| 用户盯会话百分比 | token-budget 自动压缩/交接 |

**诚实边界**：若某平台无任何 Hook/API，则该平台通过 **generic adapter + CI 硬门禁 + Hub 轮询 mailbox** 逼近目标，但「自动创建 UI 会话」可能需要一次性半自动（adapter 输出清单）。北极星不要求 100% 零点击，要求 **100% 零协议提醒**。

---

## 10. 成功标准（北极星验收）

导入 default team 后，下列场景无需用户提醒协议即可通过：

| # | 场景 | 通过条件 |
|---|------|----------|
| S1 | 用户只对 orchestrator 说「做功能 X」 | orchestrator 按路由投递若干 worker；§5 有完整链条 |
| S2 | executor 想跳过 RESEARCH | gate-runner FAIL，状态未前进 |
| S3 | 有 git diff 无 ledger | compliance-check FAIL（CI 或 hook） |
| S4 | 上下文过长 | 自动 compress 或 handoff，registry 会话仍连续 |
| S5 | 换 Cursor → Codex | 同一 `mailbox/` + registry 可继续，adapter 切换 |
| S6 | worker 直接向用户提问 | 契约拒绝；仅 `blocked` → orchestrator |
| S7 | 追问「谁引入的 bug」 | orchestrator 读 worklog + mailbox + §5 追溯责任 worker |

---

## 11. 与改善规划的关系

| 文档 | 关系 |
|------|------|
| `AWI-RUNTIME-IMPROVEMENT-PLAN.md` | 本北极星的**分阶段施工计划** |
| ADR-001 | Harness 方法论基础（不变） |
| ADR-002（待建） | 「Control Plane + PAL + Compliance Kernel」架构决策 |

**施工顺序**：L2 合规内核 → L3 中枢+mailbox → L0 generic adapter → L0 各平台 adapter → bootstrap `-ProvisionTeam`。

---

## 12. 修订记录

| 版本 | 日期 | 说明 |
|------|------|------|
| 0.1.1 | 2026-06-15 | 明确 roster = `agents/` 全量；仅 orchestrator 对用户；worker 为其余 17 角色 |
