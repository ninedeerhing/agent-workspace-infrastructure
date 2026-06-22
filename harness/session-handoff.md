# Session Handoff

updated_at: 2026-06-22T12:48:51+08:00

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
[CONTEXT] 2026-06-22 loop184 · PL-G intent quant subgraph route-evidence refresh TDD mocked-only 完成：先写 `tests/test_intent_quant_subgraph_handoff_unit.py` 红测（expected 3 failed / 1 passed）确认 `build_dispatch_from_route()` 缺 `route_evidence`，再在 `src/qa/brain/graph/rule_route.py` 为 `mining_batch_dispatch` 与 mining handoff `backtest_dispatch` 加只读 route_evidence：flow=auto_mining_to_auto_backtest / flow_stage=mining_job_and_plan|backtest_handoff / runner_mode=injected_runner_required / auto_trigger=false / side_effects=none / pl_h_batch_execution=deferred_until_later_gate，并保留 mining_job / auto_backtest_plan / auto_backtest_execution refs；验证 focused 4 passed、adjacent regression 40 passed、ruff pass · TREE-2 data gate 已过，勿重复启动 daily_bar/daily_trade_status/adj_factor · 未读取 .env/未输出 DSN/token · 未触发 auto POST/trigger/真实 runner/background/migration/backfill/default DB-backed backtest/PL-H batch execution · worker names use pure role ids · Git main-only GP-08 · 下一拍从 loop-state.next_atomic_action 执行 PL-G route evidence execution propagation TDD mocked-only；closure/收口是阶段验收并继续下一切片，不是结束方案或停止 loop。

[CONTEXT] 2026-06-22 side capability · PL-002 Codex skills router / gating Phase 1 prototype completed in `harness/skill_router.py` with `harness/tests/test_skill_router.py` and `docs/ENGINEERING/2026-06-22-codex-skill-router-prototype.md`. It is advisory only: no global `~/.codex/skills` mutation, no raw query telemetry, and no quant `loop-state` change. Next optional PL-002 step is local eval set plus graph-aware rerank.
```

### Loop Machine State

| 字段 | 值 |
|---|---|
| `mode` | autonomous |
| `current_tree` | TREE-6 |
| `current_slice` | pl-g-route-evidence-execution-propagation-mocked-only |
| `last_tick` | loop184-pl-g-intent-route-evidence-refresh-mocked-only |
| `stop_reason` | null |
| `closure_gate.status` | closed (partial_closed on TREE-2 data) |

### next_atomic_action

Start PL-G route evidence execution propagation TDD mocked-only: preserve `route_evidence` from intent quant subgraph dispatches into mocked execution / brain-run surfaces for `mining_batch_dispatch` and `backtest_dispatch`, proving auto mining → auto backtest evidence remains observable after routing without auto POST/trigger/runner/background/migration/backfill/default DB-backed backtest, PL-H batch execution, or secret output.

### next_after

After route_evidence execution propagation is stable, continue PL-G flow hardening for auto mining → auto backtest full flow observability/acceptance; PL-H batch execution remains deferred until a later gate proves real batch demand; BENCH-2 remains env deferred.

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
# 下一拍按 loop-state 执行 PL-G route evidence execution propagation TDD mocked-only；不要打印 DSN/token；不要重启 daily_bar/daily_trade_status/adj_factor；不要接默认真实 runner 或 PL-H 批量执行。
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
- prompt: `harness/templates/codex-subagent-prompt.md`
- task: read-only verification of CodeX effective constraints
- note: orchestrator retains final authority; worker report is data, not truth source.

---

## Current Objective

TREE-2: data gate passed；daily_bar / daily_trade_status / adj_factor complete to 2026-06-18，loop144 adj_factor column path 审计确认 wired/closed；loop184 已完成 PL-G intent quant subgraph route-evidence refresh TDD mocked-only；TREE-RT/TREE-4 CodeX 有效约束已验收（automation/worker/self-check 全部有真源与验证）。用户策略：数据 closure 后退出 backfill-monitoring，连续推进 auto mining → auto backtest full flow + intent understanding state machine / intent quant subgraph；closure/收口是阶段验收并继续下一切片，不是终点。

## Next Step

CodeX orchestrator 执行 `PL-G route evidence execution propagation TDD mocked-only`：把 intent quant subgraph dispatch 的 `route_evidence` 传到 mocked execution / brain-run surfaces，确认 `mining_batch_dispatch` / `backtest_dispatch` route evidence 在路由后仍可观察；继续禁止 duplicate daily_bar/daily_trade_status/adj_factor、migration execution、backfill、background process、默认真实 DB-backed backtest、默认真实 runner 执行、PL-H batch execution 与 secret 输出。

## Resume Command

CodeX 新会话首聊粘贴 `codex-zero-config-prompt.md` + 上方 CONTEXT 一行；之后任意消息从 `loop-state.json` 续跑。

```powershell
python harness/loop_tick.py prepare
```
