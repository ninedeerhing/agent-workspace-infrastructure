# CodeX Zero-Config Handoff

本文定义 raindeer-AWI 的可泛化接手协议：一个刚安装、刚注册的 CodeX，只凭起始 Prompt，即可在任意软件项目中建立总调度身份、读取最小真源、派发跨聊天 subagents，并按 Harness Engineering 循环推进。

## 目标

- **零配置接手**：新 CodeX 不依赖历史聊天，只读取仓库内最小真源与起始 Prompt。
- **任意项目适配**：正在进行或刚初始化的软件项目可用单命令生成 AWI 最小核心。
- **不破坏原项目**：不复制秘密，不覆盖已有重要文件；冲突进入 `.awi-adapter/`。
- **跨聊天协作**：每个聊天窗口可作为 subagent，沿固定 report 合同回报总调度。
- **CodeX 原生编排**：定时任务通过 `automation_update`，跨会话 worker 通过 `create_thread` / `send_message_to_thread`；文件总线只作 fallback 与审计。
- **持续循环**：总调度读取 report、真源和计划后继续派工，直到收口或人工阻塞。

## 最小真源

CodeX 总调度启动后只需先读这些文件，缺失时由适配器生成模板：

1. `AGENTS.md`：项目级角色与操作规则。
2. `docs/PROJECT_STATUS.md`：事实台账，记录做了什么、验证了什么、运行态如何。
3. `docs/TASK_TREES.md`：任务归属、主线、parking_lot 与下一原子动作。
4. `docs/CONTINUATION_PROMPT.md`：跨聊天续接副本。
5. `harness/loop-state.json`：机器可读循环状态。
6. `harness/session-handoff.md`：压缩手交与恢复摘要。
7. `harness/templates/codex-zero-config-prompt.md`：总调度起始 Prompt。
8. `harness/templates/codex-subagent-prompt.md`：跨聊天 subagent 起始 Prompt。
9. `harness/reports/EMPLOYEE_ROSTER.md`：员工清单，记录 manager/worker 身份、职责边界、report 位置、负载、错误/教训计数与当前任务。
10. `harness/codex-automation-registry.json`：CodeX automation id 与 schedule 登记。
11. `docs/PLATFORM-CODEX.md`：当前项目的 CodeX 有效约束与验证命令。

如项目已有更强约束，例如 `CONSTITUTION.md`、`SECURITY.md`、`docs/ARCHITECTURE.md`、`docs/QUALITY_GATES.md`，总调度应在最小真源之后读取并遵守。

## 总调度常驻规则

总调度是唯一对用户说话的角色。它负责：

- 读取最小真源，确认当前主线、阻塞项、验证口径和不可碰范围。
- 读取 `harness/reports/EMPLOYEE_ROSTER.md`，派工前按职责边界、`workload`、`mistake_count`、`lesson_count` 与 `risk_notes` 选择 worker。
- 将任务拆给独立 CodeX worker 线程或 subagents，但不把用户直接暴露给 worker。
- 要求 subagent 使用 `codex-subagent-prompt.md` 的报告格式回传。
- 整合 report 后更新 `PROJECT_STATUS.md`、`CONTINUATION_PROMPT.md`、`loop-state.json`、`EMPLOYEE_ROSTER.md` 与必要 worker report。
- 每轮执行一个可验证原子动作，运行最小验证，再决定下一动作。
- 命中用户停止、真实阻塞、破坏性操作、关键事实不清或必须人工体验时才停。

## 员工清单

`harness/reports/EMPLOYEE_ROSTER.md` 是跨聊天 worker 的索引表，不替代详细 report。它至少维护：

- `role_id / identity_id`：稳定身份，贯通 prompt、report 与派工记录。
- `display_name / responsibility`：展示名与职责边界。
- `report_path`：详细工作报告位置。
- `status / workload / intensity / performance`：当前可用性、承担强度与业绩信号。
- `mistake_count / lesson_count`：已确认错误与吸取教训计数。
- `last_assigned_at / last_report_at / current_task`：派工与回报时间线。
- `handoff_notes / risk_notes`：交接说明与升级规则。

维护规则：

- 总调度启动时必须读取清单。
- 派工前优先选择职责匹配且 `workload` 较低的 worker；高 `mistake_count` 且无对应 `lesson_count` 的 worker 不承接高风险任务。
- subagent report 回来后，由总调度更新该 worker 的 `last_report_at`、`workload`、`performance`、`mistake_count`、`lesson_count`、`current_task` 和 `handoff_notes`。
- 新 worker / skill 仍必须通过 AskQuestion 或用户明确批准；不得因清单存在而自行扩容。

## 跨聊天 Subagent 合同

每个新聊天窗口可以被当作一个 subagent：

- 总调度优先用 CodeX `create_thread` 创建 worker 线程；后续用 `send_message_to_thread` 续派或纠偏。
- 总调度复制 `codex-subagent-prompt.md`，填入 `ROLE_ID`、任务、目标文件、约束和回报路径。
- subagent 不直接对最终用户做产品承诺，只返回结构化 report。
- report 保持稳定字段：`status`、`changes`、`verification`、`blockers`、`next`，并包含可回写员工清单的 `workload_delta`、`mistakes`、`lessons`。
- 总调度只采纳可验证事实；若 report 与真源冲突，以 `PROJECT_STATUS.md` 和仓库事实为准。

## 自动循环

每轮遵循：

1. Read：读取 `loop-state.json`、`TASK_TREES.md`、`CONTINUATION_PROMPT.md`、`PROJECT_STATUS.md` 最新台账、`METHODOLOGY_MEMORY.md` 或项目等价长期记忆。
2. Plan：选择一条未完成的下一原子动作；若是多文件或高风险任务，先写计划或拆给 subagents。
3. Execute：小步实现，优先测试驱动，避免顺手重构。
4. Verify：运行与变更匹配的最小验证；无法运行时说明原因和替代证据。
5. Sync：更新事实台账、续接副本、loop-state、handoff/report。
6. Continue：未命中停止白名单时继续下一轮，不问“是否继续”。

## Token 压缩与会话连续性

常驻生效规则：

- 状态事实写入文件，不依赖聊天记忆。
- `PROJECT_STATUS.md` 是事实源，`CONTINUATION_PROMPT.md` 是可复制续接视图，`session-handoff.md` 是压缩恢复视图。
- 进度报告采用短标签：`[DONE]`、`[BLOCKED]`、`[VERIFY]`、`[NEXT]`。
- 跨聊天 handoff 优先保留：目标、当前主线、改动文件、验证证据、阻塞、下一原子动作、禁止重复事项。
- 压缩不得丢失安全边界、密钥保护、验证失败、人工阻塞和不可逆操作需求。

## Git 双仓库边界

raindeer 工作区含两个独立 Git 远程，日末 `daily-git-push` 分别处理：

- **AWI 根** → `agent-workspace-infrastructure`（upstream 常为 `raindeer-AWI`）：Harness、治理、架构文档。
- **`apps/quant_assistant`** → `raindeer-quant-assistant`：Quant 产品代码；**不属于** AWI 架构 publish。

CodeX Automation 配置以 `harness/codex-automation-registry.json` 为准，创建/更新通过 CodeX `automation_update`；`harness/schedule.json` 保留为 portable schedule spec。日末 push 模板见 `harness/templates/daily-git-push-prompt.md`。

## CodeX 自检

每次声明“CodeX 已配置完毕”前运行：

```powershell
.\harness\scripts\codex-self-check.ps1 -Format markdown
.\harness\compliance-check.ps1 -Mode post-bootstrap -Format markdown
```

自检至少覆盖：platform binding、automation registry、worker roster、subagent prompt、关键 skills、agent registry、loop-state 与 base compliance。

## 单命令导入

在 raindeer-AWI 仓库中执行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\harness\scripts\prepare-codex-adapter.ps1 -TargetPath "D:\path\to\project" -ProjectName "my-project"
```

先做非破坏性预览：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\harness\scripts\prepare-codex-adapter.ps1 -TargetPath "D:\path\to\project" -ProjectName "my-project" -WhatIf
```

脚本会生成：

- `AGENTS.md`
- `docs/PROJECT_STATUS.md`
- `docs/TASK_TREES.md`
- `docs/CONTINUATION_PROMPT.md`
- `docs/CODEX_ZERO_CONFIG_HANDOFF.md`
- `harness/loop-state.json`
- `harness/session-handoff.md`
- `harness/reports/EMPLOYEE_ROSTER.md`
- `harness/templates/codex-zero-config-prompt.md`
- `harness/templates/codex-subagent-prompt.md`
- `.awi-adapter/adapter-report.json`

若目标路径已有同名文件，脚本不会覆盖；候选内容写入 `.awi-adapter/proposed/` 并在 report 中列出冲突。

## 新 CodeX 使用方式

1. 在目标项目打开一个新 CodeX 聊天。
2. 粘贴 `harness/templates/codex-zero-config-prompt.md` 的内容。
3. 若要开 worker 聊天，优先用 CodeX `create_thread`，并以 `harness/templates/codex-subagent-prompt.md` 填入角色和任务。
4. worker 完成后把 report 交回总调度聊天；总调度用 repo 命令复核后再采纳。
5. 总调度更新 worker report、`EMPLOYEE_ROSTER.md`、真源并继续下一原子动作。
