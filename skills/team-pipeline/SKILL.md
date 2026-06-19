---
name: team-pipeline
description: 当需要多代理结构化团队协作的 5 阶段流水线时使用。触发条件：team、team pipeline、staged execution、多代理协同、需要团队并行执行复杂任务。
---

# Team Pipeline — 团队流水线

## Raindeer-AWI 中枢模式（默认）

当项目已执行 `bootstrap -ProvisionTeam` 时：

1. **用户只与 orchestrator 对话**；本流水线由 orchestrator 驱动，不向用户暴露 worker 会话。
2. 阶段分派通过 `harness/scripts/Send-MailboxMessage.ps1`（或平台原生消息 API）。
3. worker 完成后写 worklog + mailbox 回报 orchestrator。
4. 阶段切换前运行 `harness/gate-runner.ps1`（见 `$workflow-phase-advance`）。

## 定位

通过 5 阶段结构化流水线协调多个代理协同工作：规划 → 需求 → 并行执行 → 验证 → 修复循环。每个阶段使用专门的代理角色，阶段间通过 handoff 文档交接上下文。

## 触发条件

- 用户提到 `team`、`team pipeline`、`staged execution`
- 需要多代理并行协同完成复杂任务
- 任务可分解为多个独立子任务
- 需要结构化验证和修复循环

## 五阶段流水线

```
team-plan → team-prd → team-exec(parallel) → team-verify → team-fix(loop)
```

### 阶段 1：team-plan（规划）

| 项目 | 说明 |
|------|------|
| **入口条件** | 团队调用已解析 |
| **代理** | `explore` 扫描代码库，`planner` 创建任务图 |
| **出口条件** | 分解完成，可运行的任务图已准备就绪 |

### 阶段 2：team-prd（需求明确）

| 项目 | 说明 |
|------|------|
| **入口条件** | 范围模糊或验收标准缺失 |
| **代理** | `planner` 提取需求，可选 `critic` 挑战范围 |
| **出口条件** | 验收标准和边界明确 |

### 阶段 3：team-exec（并行执行）

| 项目 | 说明 |
|------|------|
| **入口条件** | 团队已创建，任务已分配，worker 已启动 |
| **代理** | 根据子任务类型分配合适的代理 |
| **出口条件** | 当前轮次所有执行任务达到终态 |

### 阶段 4：team-verify（验证）

| 项目 | 说明 |
|------|------|
| **入口条件** | 执行轮次完成 |
| **代理** | `verifier` + 任务相关的审查者 |
| **出口（通过）** | 验证门控通过，无需后续修复 |
| **出口（失败）** | 生成修复任务，控制流转到 team-fix |

### 阶段 5：team-fix（修复循环）

| 项目 | 说明 |
|------|------|
| **入口条件** | 验证发现缺陷/回归/不完整 |
| **代理** | `executor` / `debugger` 根据缺陷类型 |
| **出口条件** | 修复完成，流回到 team-exec 再 team-verify |

### 验证/修复循环停止条件

继续 `team-exec → team-verify → team-fix` 循环直到：
1. 验证通过且无必需的修复任务残留，或
2. 达到明确的中断/阻塞/失败终态并附证据

修复循环有最大次数限制，超出后转入终态 `failed`。

## 代理路由

每个流水线阶段使用专门的代理角色：

| 阶段 | 必需代理 | 可选代理 |
|------|---------|---------|
| **team-plan** | `explore`、`planner` | `architect`、`critic` |
| **team-prd** | `planner` | `critic` |
| **team-exec** | `executor` | `debugger`、`designer`、`writer`、`test-engineer` |
| **team-verify** | `verifier` | `test-engineer`、`security-reviewer`、`code-reviewer` |
| **team-fix** | `executor` | `debugger` |

### 路由规则

1. 领队（lead）为每个阶段选择代理，而非用户
2. 安全敏感或超过 20 文件变更必须在 team-verify 中包含 `security-reviewer` + `code-reviewer`
3. 成本模式影响模型层级

## 阶段交接（Handoff）

每个完成的阶段在转换前必须产出交接文档。

### Handoff 格式

```markdown
## Handoff: <当前阶段> → <下一阶段>

- **已决定**: [本阶段做出的关键决策]
- **已拒绝**: [被考虑的替代方案及拒绝理由]
- **风险**: [为下一阶段识别出的风险]
- **文件**: [创建或修改的关键文件]
- **待处理**: [留给下一阶段的待办项]
```

### Handoff 规则

1. 领队在启动下一阶段代理之前必须读取上一阶段的 handoff
2. Handoff 累积传递——验证阶段可读取所有之前的 handoff
3. 团队取消时 handoff 保留在 `.omc/handoffs/` 目录中
4. Handoff 轻量化——10-20 行，只捕获决策和理由

## Git Trailer 提交规范

团队流水线产出的提交应包含标准化的 Git trailer：

```
Co-authored-by: team-plan <plan@team>
Co-authored-by: team-exec <exec@team>
Reviewed-by: team-verify <verify@team>
```

## 执行流程概要

### Phase 1：解析输入

- 提取代理数量和类型
- 提取任务描述
- 验证参数有效性

### Phase 2：分析与分解

- 使用 `explore` 扫描代码库
- 使用 `planner` 将任务分解为 N 个子任务
- 每个子任务应文件级别或模块级别隔离以避免冲突
- 识别子任务间的依赖关系

### Phase 3：团队创建

- 创建团队（从任务衍生 slug 作为团队名）
- 持久化团队状态
- 预分配任务所有者以避免竞态条件

### Phase 4：Worker 启动

- 并行启动所有 worker 代理
- 每个 worker 获得独立的工作协议
- worker 通过任务列表和消息系统协调

### Phase 5：监控

- 通过入站消息和任务列表轮询监控进度
- 处理阻塞、失败和重分配
- 在每个阶段转换时更新状态

### Phase 6：完成

- 验证所有任务完成
- 向所有 worker 发送关闭请求
- 等待关闭响应
- 删除团队并清理状态

## Worker 协议

每个 worker 遵循以下协议：

1. **CLAIM**：查看分配给自己的待处理任务，标记为 in_progress
2. **WORK**：执行任务，使用文件操作工具直接工作
3. **COMPLETE**：标记任务为 completed
4. **REPORT**：通过消息通知领队任务完成
5. **NEXT**：检查更多分配任务，如有则回到步骤 1
6. **SHUTDOWN**：收到关闭请求后确认关闭

Worker 核心规则：
- 不创建子代理
- 不执行编排命令
- 始终使用绝对文件路径
- 始终向领队报告进度

## 反模式 / 红牌

| 反模式 | 说明 |
|--------|------|
| 跳过 team-verify | 红牌。必须通过验证门控 |
| 跳过 handoff 文档 | 红牌。阶段间必须传递上下文 |
| 无限修复循环 | 红牌。必须有最大修复次数限制 |
| 有依赖的任务并行化 | 红牌。有依赖必须串行 |
| 修改相同文件不隔离 | 黄牌。应使用 worktree 隔离 |
| worker 充当编排者 | 红牌。worker 只能执行，不能编排 |
| 阶段角色混用 | 黄牌。每个阶段应用专门代理 |

## 成功标准

- 所有 5 阶段按序完成
- 每个阶段产生有效的 handoff 文档
- 验证门控全部通过
- 所有子任务完成或明确标记失败
- 团队资源已清理
- 最终结果已汇报
