# Loop Engineering — 自治循环协议

> **效力**：Raindeer-AWI 心流/无限循环模式的最高操作契约。与 `docs/FLOW-MODE.md`、`apps/quant_assistant/docs/WORKFLOWS.md` 互补：本文件定义**如何自派任务**；彼等定义**何时可停**。
> **版本**：1.0.0 · 2026-06-19

---

## 1. 定位

Loop Engineering = **Ralph Loop（自引用持久循环）** + **心流模式（不停顿推进）** + **任务树治理（单主线）** + **方法论永久记忆（每轮沉淀）**。

用户**不再需要每轮给 prompt**。Orchestrator 在每完成一项原子任务后，自行从事实源读取下一项，直到**裁判裁定规划收口**或命中**停止白名单**。

---

## 2. 六份同步真源（每轮必更 · 无缺口）

| 顺序 | 文档 / 状态 | 职责 |
|:----:|-------------|------|
| 1 | `docs/TASK_TREES.md` | 任务归属、主线、下一原子动作排序 |
| 2 | `apps/quant_assistant/docs/PROJECT_STATUS.md` §5 | 事实台账（做了什么、验了什么） |
| 3 | `apps/quant_assistant/docs/CONTINUATION_PROMPT.md` | 续接副本（下一动作、阻塞） |
| 4 | `apps/quant_assistant/docs/METHODOLOGY_MEMORY.md` | **方法论永久记忆**（每轮复盘 + 失败教训） |
| 5 | `apps/quant_assistant/docs/WORKFLOWS.md` 轮次日志 | 当前/下一/下下方向（单槽覆盖） |
| 6 | **Git 工作区状态** | `git status -sb` · 当前 branch · 与 remote 关系 · 脏文件计数；commit 由 git-master 并行 agent 负责，但**每轮真源同步必须记录** git 快照摘要（写入 §5 或 worker 报告） |

**工作汇报真源（与上表同步，每 tick 必维护）**：

| 组件 | 路径 | 职责 |
|------|------|------|
| Orchestrator 汇报 | `harness/reports/orchestrator/latest.md` + `index.json` | 委派/完成/验证摘要；机器可读索引 |
| Worker 汇报（21） | `harness/reports/workers/{worker-id}.md` | 每 worker 切片：task_id · tree · action · files · verification · status |
| 汇报索引 | `harness/work-reports-index.json` | `work_report_lifecycle.py` 去重与 last_updated |

可选同步：`harness/workflow-state.json`、`harness/progress.md`、`harness/session-handoff.md`。

---

## 3. 自治派任务算法（每轮 Step 1）

```
READ  TASK_TREES → 当前 in_progress 主线与「下一原子动作」列表
READ  CONTINUATION_PROMPT → 阻塞项、P0 验收
READ  PROJECT_STATUS §5 最新 3 条 → 避免重复劳动
READ  METHODOLOGY_MEMORY 最新轮 + P0 教训 → 不踩已知坑
READ  implementation-master-plan / intent-state-machine → 未收口切片

IF 存在 P0 阻塞且无法自动消除 → 停止白名单「真实阻塞」，短播报后等待
ELSE 取 TASK_TREES 排序第 1 条且未在 §5 标记 done 的原子动作
ELSE 取 master-plan 路线图下一未交付切片
ELSE 取 parking_lot 中 approved 且依赖已满足的项

EXECUTE 该原子动作（TDD → 实现 → 最小验证）
SYNC  六份真源（含 git 状态摘要）
RETRO 方法论门控（见 §4）：有则步骤 digest；关键任务 done 则收口 synthesis
LOOP  回到 READ（除非停止白名单或裁判收口）
```

**禁止**：完成一项后停下来问「是否继续」；**禁止**无台账声称完成。

---

## 4. 方法论提取（digest 门控 · v1.1）

原 `$session-retro` / AGENTS §15 闭环学习触发，**升级为分层写入**：

- 真源：`apps/quant_assistant/docs/METHODOLOGY_MEMORY.md`
- 生命周期（**每轮必跑 · 与 §5 台账同级**）：`python harness/methodology_memory_lifecycle.py run --apply` + `python harness/work_report_lifecycle.py run --apply`
- L1 机器桥：`loop_tick.py prepare` / `advance` **自动** subprocess 调用上述脚本；失败写入 `harness/loop-lifecycle-errors.log`（fail-closed 可见，不阻断 loop）

### 4.0 每轮 lifecycle（强制）

| 时机 | 命令 / 桥接 | 与 §5 关系 |
|------|-------------|------------|
| orchestrator/worker 原子任务收工 | 五 lifecycle `run --apply`（见下表） | **同级** — 无索引更新视同本轮未完成 |
| `loop_tick.py prepare` | 自动 subprocess 全部 lifecycle | 跨 turn handoff 前必跑 |
| `loop_tick.py advance` | 自动 subprocess（含 tick-id/note） | tick 推进后必跑 |
| compliance MEM/SYNC/VER/CLO | 各 index `last_lifecycle.at` ≤24h（Git dirty 时 warn） | 与 LEDGER-002 并列 |

**六真源 prose 同步（含顶部现状概述 + git）**：每完成一项原子任务，除 §5 台账外，**必须**更新 `PROJECT_STATUS.md` 顶部「心流模式当前轮」块（1–3 句：模式/本批完成/下一动作/阻塞），与 §5 最新条目及 `loop-state.json` 对齐；§5 或 worker 报告须含当轮 `git status -sb` 摘要（branch · ahead/behind · 脏文件数）。`sync_coherence_lifecycle.py` 只读校验漂移，不自动改写 prose。

| Lifecycle | 脚本 | 索引 |
|-----------|------|------|
| 方法论 | `methodology_memory_lifecycle.py` | `methodology-memory-index.json` |
| 工作汇报 | `work_report_lifecycle.py` | `work-reports-index.json` |
| 同步一致性 | `sync_coherence_lifecycle.py` | `sync-coherence-index.json` |
| 验证快照 | `verification_snapshot_lifecycle.py` | `verification-snapshot-index.json` + `verification-latest.json` |
| 收口门控 | `closure_gate_lifecycle.py` | `closure-gate-index.json` |

验证收工后可选：`python harness/verification_snapshot_lifecycle.py record --pytest-passed N --ruff ok --apply`

**禁止**：将 lifecycle 标为可选、`--dry-run` 替代 apply、或依赖用户提醒才跑；禁止 §5 已更新但顶部现状概述仍引用旧 §5.x。

### 4.1 三层模型

| 层级 | 何时写 | 写什么 |
|------|--------|--------|
| **微步骤 digest** | 每原子动作收工；**仅当**本步新增方法论 | `## 步骤 digest-*` 简短要点 |
| **收口 synthesis** | 关键任务 / 里程碑 done（loop-state 或 TASK_TREES 标记） | 回顾 digest → M-xx + GP-xx |
| **轮次复盘** | 仅失败/退回/多轮才成 | 完整 `## 轮次-*` 模板 |

**门控（强制）**：每微步骤自问「是否新增项目方法论？」→ **没有则零写入** METHODOLOGY。

### 4.2 永久库分区

| 分区 | 编号 | 范围 |
|------|------|------|
| 项目专属 | M-xx | raindeer / quant_assistant  only |
| 泛化 | GP-xx | 任意未来项目可复用 |

收口可结论「没有」— 则不加 M-xx/GP-xx，但仍记录 synthesis closed。

### 4.3 §5 指向

PROJECT_STATUS §5 每条台账末尾只保留一句：

- **M-17 零写入**：`方法论门控：M-17 零写入 · 见 METHODOLOGY §轮次-…`（默认参考 `§轮次-20260619-loop49-56`）
- **有新增**：`方法论门控：见 METHODOLOGY_MEMORY §步骤-digest-xxx` 或 `§收口 synthesis-xxx`

机器辅助：`python -c "from harness.loop_tick import format_methodology_gate_tail; print(format_methodology_gate_tail())"`（自仓库根目录）。

### 4.4 技能 / 子代理 / 计划决策矩阵

| 条件 | 选用 |
|------|------|
| 需求模糊、边界不清 | `$deep-interview` → `$ralplan` |
| 已有 approved 计划、多文件实现 | `$writing-plans` → `$subagent-driven-dev` 或 Task `executor` |
| 2+ 独立切片可并行 | `$dispatching-parallel-agents` 或 Task 多 worker（≤6） |
| 单切片 bounded 实现 | Task `executor` |
| 跨树架构决策 | Task `architect` + `critic` |
| UI/浏览器验收 | Task `qa-tester` + `$agent-browser` |
| 准备宣称 done | `$verification-before-completion` |
| Cursor Multitask / 后台 tick | L2 Automation + loop-tick；**不**与用户对话并行抢写同一文件 |

---

## 5. 裁判收口（唯一「全部完成」闸门）

以下**全部**满足时，由 **critic** 或 **constitution-guardian** 子代理出具「规划收口裁定」；用户未要求停止前，orchestrator **不得**自行宣布 master-plan 完成：

| 检查 | 真源 |
|------|------|
| master-plan R0→当前阶段切片均已 §5 台账 done 或显式 deferred | `2026-06-19-ai-quant-platform-implementation-master-plan.md` |
| intent-state-machine 远期除外项已标注 deferred | `2026-06-19-intent-understanding-state-machine-final.md` |
| TASK_TREES 前台主线无 `in_progress` 欠账 | `TASK_TREES.md` |
| 最小门禁最近一轮 green | ruff + pytest 证据在 §5 |
| 无 P0 阻塞未解 | `CONTINUATION_PROMPT.md` |

**远期不做**（用户共识，不阻塞收口裁定）：M/A/G 决策层、vn.py/LEAN 实盘 adapter、重写 T0、绑定 RD-Agent 运行时。

---

## 6. 停止白名单（与 WORKFLOWS 一致）

1. 用户明确要求停止  
2. 真实阻塞且无法安全自动继续（如 Docker/DB/密钥缺失且影响 P0 验收）  
3. 破坏性操作需授权  
4. 关键事实冲突无法自行消除  
5. 可试用增量已就绪且**必须**用户亲手体验（如首次实盘）

环境类阻塞：短播报 + 转做**不依赖该环境**的下一切片，**不**整轮停工。

---

## 7. 与 Ralph Loop / 心流的关系

| 机制 | 来源 | Loop Engineering 中的用法 |
|------|------|---------------------------|
| 自引用循环 | `$ralph-loop` | 每轮 READ 状态 → EXECUTE → SYNC → RETRO |
| 不停顿 | FLOW-MODE / WORKFLOWS | 用户侧 1–2 句进度；禁止收束式总结 |
| 回归验证 | Ralph Loop | 重大变更后跑最小门禁；全量按 QUALITY_GATES |
| 架构验证 | Ralph Loop | 跨包变更时读 ARCHITECTURE 边界 |
| 模式提取 | `$session-retro` | 写入 METHODOLOGY_MEMORY，非聊天 |

---

## 8. Orchestrator 启动清单

1. `docs/SESSION_BOOT.md`  
2. 本文件 + `WORKFLOWS.md`  
3. `TASK_TREES.md` + `CONTINUATION_PROMPT.md` + `PROJECT_STATUS.md` §5  
4. **`METHODOLOGY_MEMORY.md` 最新 2 轮**  
5. 执行 §3 派任务算法  

---

## 9. 真循环缺陷与三层桥接（v1.2 · 2026-06-19）

### 9.1 缺陷（诚实陈述）

| 层级 | 问题 | 后果 |
|------|------|------|
| **LLM turn** | 单轮回复结束即停 | 若仅 Markdown 协议、无机器态 → 下一 turn 失忆 |
| **WORKFLOWS** | 人类可读，非 scheduler | 无人读 `loop-state` 则断裂 |
| **方法论** | 仅追加 | 膨胀（已由 lifecycle 缓解） |

### 9.2 三层桥接（已落地 — **按优先级**）

| 层 | 组件 | 路径 | 作用 |
|:--:|------|------|------|
| **L0** | Cursor 硬规则 | `.cursor/rules/raindeer-loop-autonomous.mdc` | **每 turn 先读 loop-state**；禁止「是否继续」；同会话链式执行 |
| **L1** | Loop 机器态 + tick | `harness/loop-state.json` · `harness/loop_tick.py` | `prepare` 写 handoff；`advance` 更新下一动作；Automation 读 `emit-prompt` |
| **L2** | Automation | `schedule.json` → `loop-tick`（**enabled**）· `loop-tick-prompt.md` | 跨会话无人值守；cron `*/30` |

**同会话（Cursor/Trae）**：L0 + L1 即可连续推进，**不需用户每轮 prompt**。  
**跨会话/无人值守**：L2 Automation 或用户任意消息触发 L0（读 loop-state 续跑）。

### 9.3 Automation 配置

真源：`harness/schedule.json`（v1.1.0+）。在 Cursor **Automations** 中为每个 `id` 创建对应定时任务；cron 以**本地时区**为准。

| task id | cron | prompt 模板 | 说明 |
|---------|------|-------------|------|
| `loop-tick` | `*/30 * * * *` | `harness/templates/loop-tick-prompt.md` · `loop_tick.py emit-prompt` | Loop 自治续跑 · **enabled** |
| `daily-compliance` | `0 20 * * *` | `harness/templates/daily-compliance-prompt.md` | 日末合规 · compliance-check + 五 lifecycle + 双 git + gap → `harness/reports/daily-compliance-YYYYMMDD.md` |
| `daily-git-push` | `30 20 * * *` | `harness/templates/daily-git-push-prompt.md` | 日末 push（**在 compliance 之后**）· `harness/scripts/daily-git-push.ps1` · 仅 ahead>0 · 无 force · `.env` staged fail-closed |
| `daily-compliance-check` | `0 8 * * 1-5` | inline prompt | 工作日早间 baseline 快检 |
| `methodology-lifecycle` | `0 7 * * *` | inline prompt | 方法论索引维护 |

**loop-tick 停止条件**：

```text
Stop: loop-state.closure_gate.status == "closed" 或 stop_reason 非空
Tools: 仓库读写 + terminal
```

**日末 ops 约束（用户确认 2026-06-20）**：

- `daily-compliance` / `daily-git-push` 为 **scheduled ops**，**不是**新 worker（见 `WORKER_SKILL_GOVERNANCE.md` §3.3）
- **禁止**修改 `loop-state.json` 的 `next_atomic_action`（TREE-2 续跑不受影响）
- `daily-git-push` 只 push 已有 commit；不自动 commit

CLI::

```powershell
python harness/loop_tick.py status
python harness/loop_tick.py prepare
.\scripts\ps\loop_tick.ps1 advance -Next "..." -TickId loop5
.\harness\scripts\daily-compliance.ps1
.\harness\scripts\daily-git-push.ps1 -DryRun
```

### 9.4 与 TypeScript 的关系

- **Loop / Harness**：Python + PS + JSON + Cursor rule；**不必** TS 触发。
- **产品**：Brain/Quant = Python；Web = TS。

---

*Loop 默认 ON：orchestrator 处于 §3 循环；turn 末运行 `loop_tick.py prepare` 仅当上下文将满。*

