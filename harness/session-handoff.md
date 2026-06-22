# Session Handoff

updated_at: 2026-06-22T11:18:00+08:00

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
[CONTEXT] 2026-06-22 loop176 · PL-G real batch demand gate TDD contract-only 完成：先写 demand gate 合同红测（expected ImportError for missing build_real_batch_demand_gate），再新增纯只读 build_real_batch_demand_gate()，从已加载 MiningJobV1 列表汇总 queue/backtest request pressure；单个小 ready job 返回 pl_h_deferred，多个 ready jobs、单 job 高请求数、retryable failed pressure 或 runtime evidence 返回 pl_h_revisit；验证 focused 4 passed、adjacent regression 33 passed、ruff pass · TREE-2 data gate 已过，勿重复启动 daily_bar/daily_trade_status/adj_factor · 未读取 .env/未输出 DSN/token · 未调用 store/DB/env loader/runner/background/migration/backfill/DB-backed backtest · worker names use pure role ids · Git main-only GP-08 · 下一拍从 loop-state.next_atomic_action 执行 PL-G real batch demand gate API surface TDD mocked-only；closure/收口是阶段验收并继续下一切片，不是结束方案或停止 loop。
```

### Loop Machine State

| 字段 | 值 |
|---|---|
| `mode` | autonomous |
| `current_tree` | TREE-6 |
| `current_slice` | pl-g-real-batch-demand-gate-api-surface-mocked-only |
| `last_tick` | loop176-pl-g-real-batch-demand-gate-contract-only |
| `stop_reason` | null |
| `closure_gate.status` | closed (partial_closed on TREE-2 data) |

### next_atomic_action

Start PL-G real batch demand gate API surface TDD mocked-only: expose the pure gate summary in the read-only mining jobs API payload from mocked store rows, proving no runner/background/migration/backfill/default DB-backed backtest or secret output; PL-H remains deferred unless the gate decision is `pl_h_revisit`.

### next_after

After the API surface is stable, continue JobsPage read-only demand gate display / PL-G flow hardening for auto mining → auto backtest full flow / intent quant subgraph; PL-H remains deferred unless the gate produces real batch execution demand; BENCH-2 remains env deferred.

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
# 下一拍按 loop-state 执行 PL-G real batch demand gate API surface TDD mocked-only；不要打印 DSN/token；不要重启 daily_bar/daily_trade_status/adj_factor；不要接默认真实 runner。
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
7. **勿 commit/push** 除非用户明确要求

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

TREE-2: data gate passed；daily_bar / daily_trade_status / adj_factor complete to 2026-06-18，loop144 adj_factor column path 审计确认 wired/closed；loop175 已完成 PL-G JobsPage post-trigger completed affordance TDD mocked-only；TREE-RT/TREE-4 CodeX 有效约束已验收（automation/worker/self-check 全部有真源与验证）。用户策略：数据 closure 后退出 backfill-monitoring，连续推进 auto mining → auto backtest full flow + intent understanding state machine / intent quant subgraph；closure/收口是阶段验收并继续下一切片，不是终点。

## Next Step

CodeX orchestrator 执行 `PL-G real batch demand gate TDD contract-only`：增加纯只读 demand gate，汇总 mining job queue / auto-backtest request pressure 并返回 `pl_h_deferred` / `pl_h_revisit`；继续禁止 duplicate daily_bar/daily_trade_status/adj_factor、migration execution、backfill、background process、默认真实 DB-backed backtest、默认真实 runner 执行与 secret 输出。

## Resume Command

CodeX 新会话首聊粘贴 `codex-zero-config-prompt.md` + 上方 CONTEXT 一行；之后任意消息从 `loop-state.json` 续跑。

```powershell
python harness/loop_tick.py prepare
```
