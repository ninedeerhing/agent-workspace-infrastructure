# Session Handoff

updated_at: 2026-06-22T17:37:15+08:00

## Codex Migration Block（Cursor → CodeX 无损接手）

### Workspace

| 项 | 值 |
|---|---|
| **文件夹（必须相同）** | `E:\raindeer` |
| **Orchestrator 首聊** | 粘贴 `harness/templates/codex-zero-config-prompt.md` 全文 + 下方「当前上下文一行」 |
| **Worker 子聊** | 粘贴 `harness/templates/codex-subagent-prompt.md` + 填入 `ROLE_ID` / 任务 / 约束 |
| **完整协议** | [docs/CODEX_ZERO_CONFIG_HANDOFF.md](../docs/CODEX_ZERO_CONFIG_HANDOFF.md) |
| **用户清单** | [harness/CODEX_MIGRATION_CHECKLIST.md](./CODEX_MIGRATION_CHECKLIST.md) |

### 当前上下文一行（粘贴到首聊 prompt 末尾）

```text
[CONTEXT] 2026-06-22 loop-governance · 用户指出 CodeX 迁移后 skills 几乎未调用、跨对话 worker 极少使用、PL-G route-evidence acceptance 连续同族 mocked/source-contract 小切片过多；本轮将 Goal/Plan Gate + Skill Routing Gate + Worker Dispatch Gate + Skill Lifecycle Gate + Worker Capacity Gate 写入 `docs/LOOP_ENGINEERING.md`、`harness/templates/loop-tick-prompt.md`、`harness/scripts/codex-self-check.ps1`、METHODOLOGY M-33/GP-09 与真源台账。下一拍不得继续孤立 reviewer checklist marker，必须执行 PL-G route-evidence acceptance consolidation goal_bundle：合并 reviewer signoff、source/UI contract audit、safety-gate matrix、route-evidence handoff packet、exit-to-real-flow decision，并优先交给跨对话 verifier/governance worker signoff。

[CONTEXT] 2026-06-22 skill-router · PL-002 `harness/skill_router.py` 已从 advisory prototype 提升为 loop 前置证据链：每 tick 对 bounded task 运行 router，记录 `router_version/no_skill_reason/top_rejected/context/skip_reason`，遥测仅写 gitignored `tmp/skill-route-events.jsonl`，真源只写摘要；已有 skill 优先重新投入使用，重复流程 ≥3 次才登记 `skillification_candidate`，新 skill / worker 仍需用户批准与差异矩阵。
```

### Loop Machine State

| 字段 | 值 |
|---|---|
| `mode` | autonomous |
| `current_tree` | TREE-6 |
| `current_slice` | pl-g-route-evidence-acceptance-consolidation-bundle-mocked-only |
| `last_tick` | loop201-pl-g-route-evidence-acceptance-operator-handoff-packet-mocked-only |
| `stop_reason` | null |
| `closure_gate.status` | closed (partial_closed on TREE-2 data) |

### next_atomic_action

Start PL-G route-evidence acceptance consolidation bundle TDD mocked-only: consolidate reviewer signoff, source/UI contract audit, safety-gate matrix, route-evidence handoff packet, and exit-to-real-flow decision into one goal-bundle that closes the repeated PL-G route-evidence acceptance micro-slice family and routes the next step toward auto mining -> auto backtest flow readiness / intent quant subgraph integration, while forbidding page-load auto POST/default trigger/runner/background/migration/backfill/default DB-backed backtest, PL-H batch execution, or secret output.

### next_after

After the acceptance consolidation bundle stabilizes, run worker-backed reviewer/verifier signoff and route to the next non-repetitive PL-G or intent-quant integration slice. Do not add another one-marker route-evidence acceptance checklist unless Goal/Plan Gate documents why it is a high-risk probe.

### Running Processes（poll 2026-06-22T01:49）

| PID | 类型 | 状态 | 说明 |
|---|---|---|---|
| tail batch | `_daily_trade_status_range_batch.py` | gone | post duplicate scan `other_batch_process_count=0` |

- **Log**: `apps/quant_assistant/tmp/daily_trade_status_batch_tail_2026-06-loop143.log` · `status=ok` · `14/14`
- **Err log**: `apps/quant_assistant/tmp/daily_trade_status_batch_tail_2026-06-loop143.log.err` · 0 bytes
- **DB snapshot**: `cnt=23390725` · `day_cnt=3995` · `max=2026-06-18` · `tail_pending=0` · `missing_to_20260618=0`
- **Duplicate scan**: other_batch_count **0**
- **next**:

```powershell
cd E:\raindeer\apps\quant_assistant
$env:PYTHONPATH='src'
# 下一拍按 loop-state 执行 PL-G route-evidence acceptance consolidation goal_bundle；先跑 skill routing gate 与 worker dispatch gate；不要打印 DSN/token；不要重启 daily_bar/daily_trade_status/adj_factor；不要接默认真实 runner 或 PL-H 批量执行。
```

### Blockers

| id | severity | note |
|---|---|---|
| WSL2-BENCH-1 | env | BENCH-2 ② QuantaAlpha 需用户授权 Ubuntu · loop105 skip · 禁止代理安装 WSL |
| MINE-PANEL-PROD-PG | data | IC smoke pass loop123 · daily_trade_status complete 3995/3995 max=2026-06-18 · missing_to_20260618=0 · loop144 adj_factor column path audit closed; stale deferred/open wording corrected |

### Dual-Repo Git（GP-08 main-only）

| 仓库 | 路径 | 本地分支 | upstream | 远程 |
|---|---|---|---|---|
| AWI | `E:\raindeer` | **main** | `origin/raindeer-AWI` | agent-workspace-infrastructure |
| Quant | `E:\raindeer\apps\quant_assistant` | **main** | `origin/main` | raindeer-quant-assistant |

- **禁止**: `cursor/*` / arbitrary feature 分支作为日常开发分支
- **日末 push**: `harness/scripts/daily-git-push.ps1`（非 main → blocked exit 1）
- **Automation**: Cursor/CodeX 各自 UI 配置 · 模板 `harness/templates/daily-git-push-prompt.md`

### Employee Roster

- **路径**: `harness/reports/EMPLOYEE_ROSTER.md`
- **Orchestrator report**: `harness/reports/orchestrator/latest.md`
- **Workers**: 21 active roles · dispatch 前读 roster 的 workload / risk_notes

### What NOT To Do

1. **勿重复启动** `daily_bar` chain（已 complete 3995/3995）
2. **勿重复启动** daily_trade_status tick6/tick7/tick8/tail（均已 complete；old PID chains gone）
3. **勿重复启动** adj_factor backfill（GAP-003 已 complete；loop144 path audit closed）
4. **勿创建** feature/`cursor/*` 分支（GP-08）
5. **勿读取/复制/提交** `.env` / `.env.local`（含 DSN / Token）
6. **勿安装 WSL** 或破坏性 git 操作（force push main 等）
7. **勿 push** 除非用户明确要求或 daily-git-push automation 到点；本地 main commit 依 clean-worktree gate 执行，避免 loop 结束留脏文件

### Verify Commands（接手后第一件事）

```powershell
cd E:\raindeer\apps\quant_assistant
$env:PYTHONPATH='src'
uv run python -c "from qa.env import load_env_files; load_env_files(); from qa.db.dsn_guard import assert_test_dsn_isolated; assert_test_dsn_isolated(); print('DSN isolation OK')"

# PG 进度命令不要打印 DSN/token。
uv run python -c "import os; from qa.env import load_env_files; load_env_files(); from qa.db.engine import query_one; print(query_one('SELECT count(*)::int cnt, count(DISTINCT trade_date)::int day_cnt, max(trade_date)::text max_d FROM daily_trade_status', dsn=os.environ['QA_POSTGRES_DSN']))"

Get-Content tmp/daily_trade_status_batch_tail_2026-06-loop143.log -Tail 20
```

### Truth Source Read Order

1. `harness/loop-state.json`
2. `apps/quant_assistant/docs/PROJECT_STATUS.md`（顶部 + §5 最新）
3. `apps/quant_assistant/docs/CONTINUATION_PROMPT.md`
4. `apps/quant_assistant/docs/TASK_TREES.md`
5. `harness/reports/EMPLOYEE_ROSTER.md`
6. `docs/CODEX_ZERO_CONFIG_HANDOFF.md`

### CodeX Automations（已创建并登记）

| 名称 | CodeX id | 类型 | 调度 | 模板 |
|---|---|---|---|---|
| loop-tick | `awi-loop-tick-heartbeat` | heartbeat | `FREQ=MINUTELY;INTERVAL=15` | `harness/templates/loop-tick-prompt.md` · prompt updated: safe env loading allowed via project loader, secret output forbidden |
| codex-self-check | `awi-codex-self-check` | cron | `FREQ=DAILY;BYHOUR=8;BYMINUTE=0;BYSECOND=0` | `harness/templates/codex-self-check-prompt.md` |
| daily-compliance | `awi-daily-compliance` | cron | `FREQ=DAILY;BYHOUR=20;BYMINUTE=0;BYSECOND=0` | `harness/templates/daily-compliance-prompt.md` |
| daily-git-push | `awi-daily-git-push` | cron | `FREQ=DAILY;BYHOUR=20;BYMINUTE=30;BYSECOND=0` | `harness/templates/daily-git-push-prompt.md` |

登记真源：`harness/codex-automation-registry.json`。CodeX self-check 验证：27 checks / 0 findings。

### CodeX Cross-Session Worker

- verifier thread: `019ee9fe-7605-7d53-8380-57228c31048c`
- thread title: `verifier`
- governance-coordinator thread: `019eeea7-6dc1-7121-8734-2e41c6e21b54`
- governance-coordinator report: success · read-only review confirmed missing hard gates and recommended skill_route_evidence / worker_dispatch_decision / goal_bundle detector
- prompt: `harness/templates/codex-subagent-prompt.md`
- task: read-only verification of CodeX effective constraints; latest multi-agent verifier run `019eedc6-f9c5-7c50-8170-18e415f7ce26` / nickname Lorentz reviewed loop186 target files and reported `success`
- note: orchestrator retains final authority; worker report is data, not truth source. Cross-dialogue worker is now preferred for governance / verifier signoff; temporary multi_agent is auxiliary only.

---

## Current Objective

TREE-2: data gate passed；daily_bar / daily_trade_status / adj_factor complete to 2026-06-18，loop144 adj_factor column path 审计确认 wired/closed；loop201 已完成 PL-G route-evidence acceptance operator handoff packet mocked-only。2026-06-22 governance repair 将 skill router / worker dispatch / goal bundle 从 advisory 提升为 loop 前置硬门禁，下一步必须执行 PL-G route-evidence acceptance consolidation bundle，并优先使用跨对话 verifier/governance worker 做 signoff。用户策略：数据 closure 后退出 backfill-monitoring，连续推进 auto mining → auto backtest full flow + intent understanding state machine / intent quant subgraph；closure/收口是阶段验收并继续下一切片，不是终点。

## Next Step

CodeX orchestrator 先跑 Goal/Plan Gate + Skill Routing Gate + Worker Dispatch Gate，然后执行 `PL-G route-evidence acceptance consolidation bundle TDD mocked-only`：合并 reviewer signoff、source/UI contract audit、safety-gate matrix、route-evidence handoff packet 与 exit-to-real-flow decision，关闭连续同族 acceptance 微切片；继续禁止 duplicate daily_bar/daily_trade_status/adj_factor、migration execution、backfill、background process、默认真实 DB-backed backtest、默认真实 runner 执行、PL-H batch execution 与 secret 输出。

## Resume Command

CodeX 新会话首聊粘贴 `codex-zero-config-prompt.md` + 上方 CONTEXT 一行；之后任意消息从 `loop-state.json` 续跑。

```powershell
python harness/loop_tick.py prepare
```
