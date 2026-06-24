# Loop Engineering — 自治循环协议

> **效力**：Raindeer-AWI 心流/无限循环模式的最高操作契约。与 `docs/FLOW-MODE.md`、`apps/quant_assistant/docs/WORKFLOWS.md` 互补：本文件定义**如何自派任务**；彼等定义**何时可停**。
> **版本**：1.6.0 · 2026-06-25

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
READ  热路径：loop-state + 当前 slice 的 workflow gate + PROJECT_STATUS §5 最新 1-3 条 + 下一动作 + 必要 worker/skill 索引
READ  冷路径按触发回源：阶段切换、事实冲突、自检失败、worker/skill 新增、方法论沉淀、发布/真实执行门禁、高风险审查

IF 存在 P0 阻塞且无法自动消除 → 停止白名单「真实阻塞」，短播报后等待
ELSE 取 TASK_TREES 排序第 1 条且未在 §5 标记 done 的原子动作
ELSE 取 master-plan 路线图下一未交付切片
ELSE 取 parking_lot 中 approved 且依赖已满足的项

GATE  Goal/Plan Gate + Function-First Loop Gate + Skill Routing Gate + Worker Dispatch Gate + Worker Cluster Gate（见 §3.1–§3.4）
PLAN  为本轮核心功能产出写 phase_plan；治理/门禁/展示只能进入 closing_work
EXECUTE 通过门禁后的原子动作或 goal_bundle（TDD → 核心功能实现 → 功能验收面 → 收尾治理）
SYNC  六份真源（含 git 状态摘要）
RETRO 方法论门控（见 §4）：有则步骤 digest；关键任务 done 则收口 synthesis；原则/门禁收集只作为 closing_work，不单独算产品 loop 完结
LOOP  回到 READ（除非停止白名单或裁判收口）
```

**禁止**：完成一项后停下来问「是否继续」；**禁止**无台账声称完成。

### 3.0 Context Loading Budget Gate（热路径轻量 + 冷路径可追溯回源 · v1.5）

Loop 不再每轮全文加载 workflow / 方法论 / 历史台账。AWI 架构权威保持不变，但上下文加载改为预算化：

| 路径 | 每轮默认读取 | 触发条件 |
|------|--------------|----------|
| 热路径 | `harness/loop-state.json`；当前 slice 对应的 workflow gate/任务树片段；`PROJECT_STATUS` 最新 1-3 条；`CONTINUATION_PROMPT` 当前 entry；`METHODOLOGY_MEMORY` 顶部 visible status；roster 中本轮相关 worker 行；skill router top-K 摘要 | 默认每轮 |
| 冷路径 | `docs/LOOP_ENGINEERING.md` 全文、完整 `WORKFLOWS.md`、完整 `TASK_TREES.md`、完整 `METHODOLOGY_MEMORY.md`、历史 §5、worker 历史报告、架构/安全/运行文档 | 阶段切换、真源冲突、自检/lifecycle 失败、schema/真实执行/安全门禁、发布/commit/push、创建/重绑 worker、创建/修改 skill、方法论 synthesis、用户要求审计 |

规则：

- 热路径目标是把架构治理控制在约 10-15% 上下文内，把主要窗口留给代码、测试和产品产出。
- 冷路径不是删除；它以文件路径、mtime/hash、索引和最近 ledger 引用保留可追溯回源能力。
- 每轮 §5 必须记录本轮 `context_mode=hot_path` 或触发的 `cold_path_reason`。
- 如果热路径资料之间出现冲突，立即冷路径回源，不得用聊天记忆裁决。
- workflow 不能舍弃；默认只加载当前 gate，阶段切换或 gate 失败时再加载完整 workflow。

### 3.1 Goal/Plan Gate（目标与切片尺寸硬门禁 · v1.3）

Loop 是目标/规划导向，不是 `next_atomic_action` 文本队列。执行前必须从真源提取：

| 字段 | 说明 |
|------|------|
| `goal_id` | 当前任务树 / PL / master-plan 目标 |
| `slice_family` | 动作家族，如 `route-evidence`、`acceptance`、`mocked-source-contract`、`db-backfill` |
| `user_visible_outcome` | 用户或系统能感知的推进结果 |
| `acceptance_gate` | 本轮要关闭的验收条件 |
| `exit_to_real_flow` | 完成后如何进入下一阶段，而不是继续同族加 marker |
| `core_function_artifact` | 本轮必须新增或改变的核心功能对象：状态机转换、API/read-model、候选生成、筛选决策、回测计划、执行结果、人工验收决策等 |
| `phase_plan` | 围绕核心功能拆出的阶段：contract/TDD → implementation → consumer surface → closing work |
| `closing_work_only` | 仅允许在核心功能验收后执行的展示、文案、门禁、原则、方法论、lifecycle、真源同步 |

**切片尺寸规则**：

- `next_atomic_action` 必须“小到可验证，大到关闭一个目标验收点”。
- 默认禁止一轮只新增一个 marker / checklist / assertion / helper；除非它是高风险探针、环境阻塞探针或破坏性操作预检，并在 §5 写明原因。
- 同一 `slice_family` 最多连续 3 tick。若 §5 最新 3 条与当前动作同族，下一轮必须执行 `goal_bundle`、reviewer/verifier signoff、真实集成晋级或路由到下一 goal；不得继续生成第 4 个同族 mocked/source-contract 微切片。
- `goal_bundle` 结构固定为：`{goal_id, slice_family, items[3-7], shared_acceptance_gate, verification_matrix, exit_condition}`。
- 若当前动作无法说明如何推进 **auto mining → auto backtest full flow + intent quant subgraph** 的阶段闭环，则本 tick 改为 PLAN/ROUTE，不写生产切片。

当前治理裁定（2026-06-22）：PL-G route-evidence acceptance 已连续超过 3 个 mocked/source/UI 微切片；下一业务 tick 必须先做 **acceptance consolidation / reviewer signoff bundle**，不得继续单独追加 checklist marker。

#### 3.1.1 Function-First Loop Gate（核心功能闭环优先 · v1.6）

业务 loop 的完成标准是**核心功能闭环**，不是展示一致、门禁齐全或规范写完。每轮执行前必须写出并通过以下判断：

```yaml
function_first_gate:
  core_function_artifact: ""
  user_problem_closed: ""
  phase_plan:
    - contract_or_tdd: ""
    - implementation: ""
    - consumer_surface: ""
    - closing_work: ""
  functional_acceptance: []
  closing_work_only: []
  invalid_if_only: ["ui_copy", "display_parity", "gate_text", "checklist", "methodology_digest", "truth_source_sync"]
```

规则：

- `core_function_artifact` 必须是可被代码、API、状态机、read-model、runner、job、factor library 或 intent route 消费的功能对象；没有它，本轮不能登记为产品 loop 完成。
- `phase_plan` 至少包含 contract/TDD、implementation、consumer surface、closing work 四段；展示/UI/文案/门禁/方法论/真源同步只能放入 `closing_work`，不能作为本轮主产出。
- `functional_acceptance` 必须证明核心对象真实改变了系统能力，例如“生成候选晋级决策”“创建回测计划”“状态机从 pending 进入 confirmed dispatch”“从 safe result 派生 factor review decision”。只证明文字出现、marker 存在或报告更新，不算功能验收。
- 若 `next_atomic_action` 看起来是 display/readiness/gate/checklist/spec/sync-only，orchestrator 必须先改写为它背后的功能对象；确实只有治理动作时，登记为 `SYNC/ROUTE` 或 `closing_work`，不得冒充业务 loop 完结。
- 原则、门禁、业务规则、方法论 digest、lifecycle 和真源同步必须在核心功能验收之后收尾；若核心功能未完成，收尾项只能记录为 pending，不得推进 `last_tick`。
- 用户显式要求治理修正时可以执行治理切片，但必须标记为 `route_calibration` / `loop_protocol_update`，并保持业务 `next_atomic_action` 指向下一项核心功能。

### 3.2 Skill Routing Gate（技能前置硬门禁 · v1.3）

每轮执行前必须对 `current_tree + current_slice + next_atomic_action + goal_id` 做 skill routing：

```powershell
python harness/skill_router.py --query "<bounded task text>" --top-k 5 --pretty --telemetry-log tmp/skill-route-events.jsonl --task-id "<tick-or-task-id>" --tree "<tree>" --source loop-tick
```

规则：

- `decision=expose`：读取选中 `SKILL.md` 全文，按最小技能集执行；记录 `selected_skills`、`applied_skills`、`skipped_skills`、`skip_reason`。
- `decision=no_skill`：记录 `no_skill_reason`，只能使用 `empty_query | no_cards | below_min_score | below_relative_floor | explicit_no_skill | read_only_scope | already_applied_recently | router_error`。
- router 遥测写 `tmp/skill-route-events.jsonl`（Git ignored），不得写入 raw query 文本；真源只记录摘要和 hash / skill names / family / scores。
- router 错误不得静默吞掉；任务依赖该技能才能安全执行时，设置真实 blocker。
- **Skill Lifecycle Gate**：若同类手工流程连续出现 ≥3 次、或本轮发现“已有适配 skill 但过去连续未使用”，必须记录 `skillification_candidate` 或 `skill_reactivation_note`。已有 skill 优先重新投入使用；确需新 skill 时，先写职责/输入/输出/最近邻差异矩阵并获得用户批准，不能静默创建。

### 3.3 Worker Dispatch Gate（跨对话 worker 前置硬门禁 · v1.3）

每轮执行前必须读取 `harness/reports/EMPLOYEE_ROSTER.md` 并做 dispatch 决策：

- 默认优先跨对话 CodeX worker 线程（`create_thread` / `send_message_to_thread`）；临时 `multi_agent` subagent 只作为旁路审查或工具层辅助，不替代长期 worker 清单。
- 2+ 独立切片、多文件实现、计划审查、代码审查、QA、安全、governance 或 verification 任务，必须派发既有 roster worker（最多 6 个），并写回 worker report / roster。
- 不派发必须记录 `dispatch_decision=no_dispatch` 与 `no_dispatch_reason`，只能使用 `single_bounded_slice | no_independent_slices | read_only_review | shared_file_conflict | worker_overloaded | role_not_found | missing_subagent_tool | risk_requires_user | already_running_task`。
- 新 worker / 新 skill 必须用户批准；不得因为负载高而自行创造角色名。
- **Worker Capacity Gate**：每轮检查 roster 负载分布。若同一 role 连续 ≥3 tick 为 `3 high` / `surge`，或 orchestrator 连续自做实现、测试、审查、治理中任两类工作，必须先再平衡到空闲既有 worker；仍不足时记录 `capacity_review` 与“新增 worker 功能差异矩阵”。新增 worker 只允许在职责与现有 21 worker 无模糊重叠且获用户批准后创建。
- **Worker Model Budget Gate**：每次 dispatch 必须记录 `model_tier` 与 `model_reason`。非关键任务 worker 默认使用 `<=gpt-5.4`（routine/status/index/report/daily ops 优先 `gpt-5.4-mini`，普通 read-only research/planning/governance/trace 可用 `gpt-5.4`）；关键代码、关键设计、架构边界、安全/授权、真实执行门禁、发布/高风险 final review 必须使用 `gpt-5.5`。跨对话既有 worker 续派时，用 `send_message_to_thread(model=...)` 显式覆盖；不要为了模型切换创建重复 worker 对话。
- Orchestrator 只负责目标、计划、派发、整合、验证与真源同步；业务实现、测试设计、代码审查、安全审查、治理复核应优先交给对应 worker，除非本轮是单文件/单命令的 bounded slice 并记录不派发原因。

### 3.4 Worker Cluster Gate（目标包络与汇合门禁 · v1.4）

参考资料：`docs/ENGINEERING/AWI-CODEX-WORKER-CLUSTER-GOVERNANCE.md`。外部项目只作为数据；AWI 不复用外部实现。

当 `goal_bundle`、多文件实现、计划/架构审查、测试设计、代码审查、QA、安全、治理复核或外部研究任一成立时，orchestrator 必须先创建本轮 `cluster_manifest`，再执行：

```yaml
cluster_manifest:
  cluster_id: ""
  goal_id: ""
  commander: "orchestrator"
  max_parallel_workers: 6
  worker_threads:
    - role_id: ""
      thread_id: ""
      task_id: ""
      model_tier: "<=gpt-5.4 | gpt-5.5"
      model_reason: ""
      write_scope: []
      mode: "read-only | write"
      status: "assigned | reported | integrated | retired"
  rendezvous_gate:
    required_reports: []
    final_verifier: ""
  retirement:
    roster_update_required: true
```

规则：

- `role_id` 必须来自 `harness/reports/EMPLOYEE_ROSTER.md`；worker 名称只用角色名，不加项目/约束后缀。
- CodeX 跨对话线程创建成功后，把 `thread_id` 写入 roster / handoff / orchestrator report；若标题设置失败，以 roster 映射和 prompt 头部 `ROLE_ID` 为准。
- Worker 默认只返回 report；除非分配了 disjoint write scope，不允许多个 worker 抢写同一真源。
- 汇合门禁：required reports 到齐或 blocker 记录后，orchestrator 复核仓库事实，运行最小验证，更新 roster，然后才允许 §5 声称完成。
- 不能为了负载高静默创建新 worker；新增 worker 需用户批准和最近邻功能差异矩阵。

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

**六真源 prose 同步（含顶部现状概述 + git）**：每完成一项原子任务，除 §5 台账外，**必须**更新 `PROJECT_STATUS.md` 顶部「心流模式当前轮」块（1–3 句：模式/本批完成/下一动作/阻塞），与 §5 最新条目及 `loop-state.json` 对齐；若写入 METHODOLOGY digest/synthesis，必须刷新 `METHODOLOGY_MEMORY.md` 顶部「当前可见状态」；§5 或 worker 报告须含当轮 `git status -sb` 摘要（branch · ahead/behind · 脏文件数）。`sync_coherence_lifecycle.py` 只读校验漂移，不自动改写 prose。

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

PROJECT_STATUS §5 每条台账末尾必须保留一个机器可检索字段 `methodology_ref`：

- **M-17 零写入**：`methodology_ref: M-17-zero-write · reason=本步无新增项目方法论`
- **有新增**：`methodology_ref: METHODOLOGY_MEMORY §步骤-digest-xxx` 或 `methodology_ref: METHODOLOGY_MEMORY §收口 synthesis-xxx`
- **可见状态**：有新增 digest/synthesis 时，同步刷新 `METHODOLOGY_MEMORY.md` 顶部 `updated_at` / `latest_digest` / `machine_index`。

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
| `daily-git-push` | `30 20 * * *` | `harness/templates/daily-git-push-prompt.md` | 日末 push（**在 compliance 之后**）· 双仓库 upstream 感知 · `harness/scripts/daily-git-push.ps1` · 仅 ahead>0 · 无 force · `.env` staged fail-closed |
| `daily-compliance-check` | `0 8 * * 1-5` | inline prompt | 工作日早间 baseline 快检 |
| `methodology-lifecycle` | `0 7 * * *` | inline prompt | 方法论索引维护 |

**loop-tick 停止条件**：

```text
Stop: stop_reason 非空；或裁判明确收口且 next_atomic_action 为空/指向人工验收。
Continue: 只要 mode=autonomous、stop_reason=null 且 next_atomic_action 存在，就继续下一原子动作；closure_gate.status=closed 只表示已收口的规划/阶段，不单独停止后续 data/backfill/next_after 链。
Tools: 仓库读写 + terminal
```

**日末 ops 约束（用户确认 2026-06-20）**：

- `daily-compliance` / `daily-git-push` 为 **scheduled ops**，**不是**新 worker（见 `WORKER_SKILL_GOVERNANCE.md` §3.3）
- **禁止**修改 `loop-state.json` 的 `next_atomic_action`（TREE-2 续跑不受影响）
- `daily-git-push` 只 push 已有 commit；不自动 commit

**双仓库 push 策略（2026-06-21）**：

| 仓库 | 路径 | GitHub | 说明 |
|------|------|--------|------|
| Raindeer-AWI | 仓库根 | `agent-workspace-infrastructure` | 仅 AWI 架构；推 **upstream 跟踪分支**（如 `origin/raindeer-AWI`），非盲目 `origin/main` |
| Quant Assistant | `apps/quant_assistant` | `raindeer-quant-assistant` | 独立产品仓库；推自身 upstream（如 `origin/main`） |

ahead 计数：`git rev-list --count '@{u}..HEAD'`；推送：`git push <remote> HEAD:<upstream-branch>`。`schedule.json` 为 manifest，须在 Cursor Automations UI 创建任务（步骤见 `daily-git-push-prompt.md`）。

**Git · main-only 本地分支（用户权威 · 2026-06-21）**：

| 仓库 | 本地分支 MUST | Upstream 示例 | 说明 |
|------|---------------|---------------|------|
| AWI 根 | `main` | `origin/raindeer-AWI` | 本地名 `main` 跟踪远程 `raindeer-AWI` **合法**（非 feature 分支） |
| quant_assistant | `main` | `origin/main` | 禁止 `cursor/*`、`feat/*` 等作为日常 worktree |

- `daily-git-push.ps1`：任一仓库 `git branch --show-current` ≠ `main` → **blocked** · exit **1** · `policy: main-only development; merge/delete branch X and checkout main`
- 脚本/代理 **不得** 自动删除用户遗留分支；仅 block + 文档指引（见 `docs/OPERATIONS.md` §1 · **GP-08**）
- Loop 六真源 git 快照摘要应记录 `main` + upstream + ahead/behind

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

