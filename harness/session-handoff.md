# Session Handoff

updated_at: 2026-06-22T23:05:40+08:00

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

[CONTEXT] 2026-06-22 worker-cluster · 用户要求参考 `cft0808/edict` 与 `MoonshotAI/kimi-code` 完善 CodeX 跨对话 worker cluster。已派发既有 roster 角色 `researcher` thread `019eeebf-629e-7013-bbf4-1db4d312b925` 与 `architect` thread `019eeebf-b3a3-7ab3-bfe8-5a9c4b8b2936`，均只读 success；新增 `docs/ENGINEERING/AWI-CODEX-WORKER-CLUSTER-GOVERNANCE.md`，并把 Worker Cluster/Rendezvous Gate 写入 `docs/LOOP_ENGINEERING.md` §3.4、`harness/templates/loop-tick-prompt.md`、`harness/scripts/codex-self-check.ps1` 与 METHODOLOGY M-34/GP-10。下一业务 tick 执行 PL-G consolidation bundle 前必须写 `cluster_manifest` / `worker_report_refs` / rendezvous gate。

[CONTEXT] 2026-06-22 loop203 · 已完成 PL-G route-evidence acceptance consolidation bundle mocked-only：cluster `test-engineer=019eeece-52d7-7b73-868a-7beb496ba303`、`executor=019eeece-c617-71c3-a80a-39a693ad3ac3`、`code-reviewer=019eeed1-7e14-7342-9d45-d7948aec94d2`、`verifier=019eeed2-dbc0-7313-8d64-f9c6f199c68b` 均回报 success；code-reviewer 初次发现 exit-to-real-flow semantic gap，executor 修复为真实 `read_only_next_route` / `next_route=pl_g_flow_hardening` source/UI markers，post-fix review/verifier 通过。下一拍必须执行 PL-G route guidance transition mocked-only，转向 `intent_quant_integration_readiness` / `auto_backtest_flow_readiness`，不要再追加 acceptance checklist marker family。

[CONTEXT] 2026-06-22 loop204 · 已完成 PL-G route guidance transition mocked-only：同一跨对话 worker cluster 均回报 success；Jobs read-only next-route 已从 active `next_route=pl_g_flow_hardening` 转为 `previous_route=pl_g_flow_hardening` + active `next_route=intent_quant_integration_readiness` / `next_route=auto_backtest_flow_readiness`。验证 focused pytest 13 passed，smoke ok=true / pageLoadTriggerRequests=[] / duplicateTriggerUrls=[]，web build/eslint/ruff pass。下一拍进入 intent-quant integration / auto mining -> auto backtest readiness handoff mocked-only，不要新增 route-evidence acceptance checklist family。

[CONTEXT] 2026-06-22 loop205 · 已完成 intent-quant readiness handoff bundle mocked-only：同一跨对话 worker cluster 均回报 success；Jobs fixture 现在把 loop204 body route guidance、submitted trigger route evidence、refreshed Jobs route evidence 与 PL-H deferred marker 汇入同一 readiness handoff bundle，未新增 route-evidence acceptance/checklist family。验证 focused pytest 14 passed，smoke ok=true / pageLoadTriggerRequests=[] / duplicateTriggerUrls=[]，web build/eslint/ruff pass。下一拍进入 auto mining -> auto backtest observability / real-batch demand gate review mocked-only。

[CONTEXT] 2026-06-22 loop206 · 已完成 auto mining -> auto backtest observability / real-batch demand gate review mocked-only：同一跨对话 worker cluster 均回报 success；Jobs fixture 现在把 loop205 readiness handoff 复核为 observability demand-gate review bundle，绑定 real-batch gate review_required、explicit runner required、PL-H deferred、no page-load auto POST/default runner/secret output，未新增 route-evidence acceptance/checklist family。验证 RED 2 failed / 13 passed expected，focused pytest 15 passed，smoke ok=true / pageLoadTriggerRequests=[] / duplicateTriggerUrls=[]，web build/eslint/ruff/stale-family scan/safety scan pass。下一拍进入 explicit user approval / runner readiness / PL-H eligibility preflight mocked-only。

[CONTEXT] 2026-06-22 loop207 · 已完成 explicit approval / runner readiness / PL-H eligibility preflight mocked-only：同一跨对话 worker cluster 均回报；Jobs fixture 现在把 loop206 demand-gate review 转成 approval/readiness preflight bundle，绑定 explicit approval required_not_granted、injected runner required_not_connected、PL-H not eligible until real-batch gate、no page-load auto POST/default runner/background/migration/backfill/DB-backed backtest/PL-H execution/secret output，未新增 acceptance/checklist family。验证 RED 2 failed / 14 passed expected，focused pytest 16 passed，smoke ok=true / pageLoadTriggerRequests=[] / duplicateTriggerUrls=[]，web build/eslint/ruff/stale-family execution-permission scan/safety scan pass。下一拍进入 real runner wiring demand/authorization gate planning mocked-only。

[CONTEXT] 2026-06-22 loop208 · 已完成 real runner wiring demand/authorization gate planning mocked-only：同一跨对话 worker cluster 汇合；Jobs fixture 现在把 loop207 approval/readiness preflight 转成 `realRunnerAuthorizationGatePlanChecks` / `assertRealRunnerAuthorizationGatePlan(...)` planning-only authorization gate bundle，绑定 explicit authorization contract、injected-runner configuration boundary、rollback/observability requirements、PL-H non-eligibility guard、no page-load auto POST/default runner/background/migration/backfill/DB-backed backtest/PL-H execution/secret output，未新增 acceptance/checklist family。验证 RED 2 failed / 15 passed expected，focused pytest 17 passed，smoke ok=true / pageLoadTriggerRequests=[] / duplicateTriggerUrls=[]，web build/eslint/ruff/stale-family enablement scan/safety scan pass。下一拍进入 explicit runner wiring design/implementation preflight mocked-only。

[CONTEXT] 2026-06-22 loop209 · 已完成 explicit runner wiring design/implementation preflight mocked-only：同一跨对话 worker cluster 汇合；Jobs fixture 现在把 loop208 authorization gate plan 转成 `explicitRunnerWiringPreflightChecks` / `assertExplicitRunnerWiringPreflight(...)` implementation preflight bundle，绑定 no-default-runner injected-runner-only design contract、explicit authorization inputs、rollback/audit evidence、fail-closed runner boundary、PL-H non-eligibility recheck、no page-load auto POST/default runner/background/migration/backfill/DB-backed backtest/PL-H execution/secret output，未新增 acceptance/checklist family。验证 RED 2 failed / 16 passed expected，focused pytest 18 passed，smoke ok=true / pageLoadTriggerRequests=[] / duplicateTriggerUrls=[]，web build/eslint/ruff/stale-family enablement scan/safety scan pass；code-reviewer/verifier final success。下一拍进入 fail-closed injected-runner implementation plan / manual authorization artifact TDD mocked-only。

[CONTEXT] 2026-06-22 loop210 · 已完成 fail-closed injected-runner implementation plan / manual authorization artifact mocked-only：同一跨对话 worker cluster 汇合；Jobs fixture 现在把 loop209 explicit runner wiring preflight 转成 `failClosedManualAuthorizationArtifactChecks` / `assertFailClosedManualAuthorizationArtifact(...)` artifact bundle，绑定 injected-runner-only artifact、disabled default runner wiring、rollback/audit hooks required、missing-runner fail-closed behavior、PL-H non-eligibility guard、no page-load auto POST/default runner/background/migration/backfill/DB-backed backtest/PL-H execution/secret output，未新增 acceptance/checklist family，也未授予 execution permission。验证 RED 2 failed / 17 passed expected，focused pytest 19 passed，smoke ok=true / pageLoadTriggerRequests=[] / duplicateTriggerUrls=[]，web build/eslint/ruff/stale-family enablement scan/safety scan/runtime cleanup pass；code-reviewer/verifier final success。下一拍进入 explicit injected-runner call boundary / rollback-observability contract TDD mocked-only。

[CONTEXT] 2026-06-22 loop211 · 已完成 explicit injected-runner call boundary / rollback-observability contract mocked-only：同一跨对话 worker cluster 汇合；Jobs fixture 现在把 loop210 fail-closed manual authorization artifact 转成 `explicitInjectedRunnerCallBoundaryChecks` / `assertExplicitInjectedRunnerCallBoundary(...)` contract bundle，绑定 explicit authorization handoff required、rollback observability required before call、audit events required before/after call、missing-runner fail-closed behavior、PL-H non-eligibility recheck、no page-load auto POST/default runner/background/migration/backfill/DB-backed backtest/PL-H execution/secret output，未新增 acceptance/checklist family，也未触发 runner invocation。验证 RED 2 failed / 18 passed expected，focused pytest 20 passed，smoke ok=true / pageLoadTriggerRequests=[] / duplicateTriggerUrls=[]，web build/eslint/ruff/stale-family enablement scan/safety scan/runtime cleanup pass；code-reviewer/verifier final success。下一拍进入 explicit authorized runner injection test seam / PL-H eligibility re-evaluation TDD mocked-only。

[CONTEXT] 2026-06-22 loop212 · 已完成 authorized runner injection seam / PL-H eligibility re-evaluation mocked-only：同一跨对话 worker cluster 汇合；Jobs fixture 现在把 loop211 call-boundary/rollback-observability contract 转成 `authorizedRunnerInjectionSeamChecks` / `assertAuthorizedRunnerInjectionSeam(...)` seam bundle，绑定 opaque operator token required/not persisted、user/job/action/runner-config input shape、rollback/audit proof、explicit parameter-only adapter boundary、PL-H not eligible until authorized real-batch gate、no page-load auto POST/default runner/background/migration/backfill/DB-backed backtest/PL-H execution/secret output，未新增 acceptance/checklist family，也未授权或触发 runner invocation。验证 RED 2 failed / 19 passed expected，focused pytest 21 passed，smoke ok=true / pageLoadTriggerRequests=[] / duplicateTriggerUrls=[]，web build/eslint/ruff/stale-family enablement scan/refined safety scan/runtime cleanup pass；code-reviewer/verifier final success。下一拍进入 explicit real runner adapter dry-run planning / PL-H eligibility gate TDD mocked-only。

[CONTEXT] 2026-06-22 loop213 · 已完成 explicit real runner adapter dry-run planning / PL-H eligibility gate mocked-only：同一跨对话 worker cluster 汇合；Jobs fixture 现在把 loop212 seam/recheck bundle 转成 `realRunnerAdapterDryRunPlanningChecks` / `assertRealRunnerAdapterDryRunPlanning(...)` planning gate，绑定 adapter contract review required、authorization evidence handoff required、rollback/audit gates required、explicit runner config required、PL-H fail-closed/not eligible、dry-run planning only/not runner invocation、no page-load auto POST/default runner/background/migration/backfill/DB-backed backtest/PL-H execution/secret output，未新增 acceptance/checklist family，也未授权、未触发 adapter/runner invocation 或 dry-run execution。验证 RED 2 failed / 20 passed expected，focused pytest 22 passed，smoke ok=true / pageLoadTriggerRequests=[] / duplicateTriggerUrls=[]，web build/eslint/ruff/family scan/active enablement scan/refined secret marker scan/runtime cleanup pass；code-reviewer/verifier final success。下一拍进入 explicit adapter contract review / dry-run proof harness TDD mocked-only。

[CONTEXT] 2026-06-22 loop214 · 已完成 explicit adapter contract review / dry-run proof harness mocked-only：同一跨对话 worker cluster 汇合；Jobs fixture 现在把 loop213 dry-run planning gate 转成 `adapterContractReviewDryRunProofHarnessChecks` / `assertAdapterContractReviewDryRunProofHarness(...)` proof harness，绑定 adapter contract review only、mocked proof only not execution、authorization evidence validation、rollback/audit before-after proof、explicit runner config/no default lookup、PL-H fail-closed/not eligible、no page-load auto POST/default runner/adapter invocation/dry-run execution/background/migration/backfill/DB-backed backtest/PL-H execution/secret output，未新增 Acceptance/Checklist family，也未授权、未触发 adapter/runner invocation 或 dry-run execution。验证 RED 1 failed expected，focused pytest 1 passed，related regression 23 passed，smoke ok=true / pageLoadTriggerRequests=[] / duplicateTriggerUrls=[]，web build/eslint/ruff/family scan/active enablement scan/runtime cleanup pass；code-reviewer/verifier final success。下一拍先做 Jobs smoke fixture adapter/runner proof-harness modularization TDD mocked-only，因为 fixture pure LOC=3166，之后再继续 dry-run proof review gate / runner-adapter readiness matrix。

[CONTEXT] 2026-06-22 loop215 · 已完成 Jobs smoke fixture runner-adapter proof-harness modularization mocked-only：同一跨对话 worker cluster 汇合；loop208-loop214 runner-adapter proof/check matrices 已从 oversized `web/scripts/smoke-jobs-page-fixture.mjs` 抽入 7 个 bounded pure modules，fixture 经 aggregator 继续配置 `assertTextCheck` 并保留 body/submitted/refreshed 三面证据。验证 RED 2 failed expected，focused pytest 2 passed，related regression 24 passed，ruff pass，targeted eslint pass，smoke ok=true / pageLoadTriggerRequests=[] / duplicateTriggerUrls=[] / miningJobsReadCount=5，web build/family scan/active enablement scan/runtime cleanup pass；code-reviewer/verifier final success。fixture pure LOC 3166 -> 2165，下一拍进入 explicit dry-run proof review gate / runner-adapter readiness matrix TDD mocked-only，仍禁止 real/default runner、adapter dry-run execution、background、migration/backfill、DB-backed backtest、PL-H execution 与 secret output。
```

### Loop Machine State

| 字段 | 值 |
|---|---|
| `mode` | autonomous |
| `current_tree` | TREE-6 |
| `current_slice` | pl-g-dry-run-proof-review-runner-adapter-readiness-matrix-mocked-only |
| `last_tick` | loop215-jobs-smoke-fixture-runner-adapter-proof-modularization |
| `stop_reason` | null |
| `closure_gate.status` | closed (partial_closed on TREE-2 data) |

### next_atomic_action

Start explicit dry-run proof review gate / runner-adapter readiness matrix TDD mocked-only: use the extracted runner-adapter proof modules and loop208-loop215 evidence to define a compact readiness matrix covering authorization evidence, injected runner config, rollback/audit before-after proof, fail-closed missing-runner behavior, and PL-H eligibility decision; forbid invoking a real/default runner, adapter dry-run execution, page-load auto POST, background process, migration/backfill, default DB-backed backtest, PL-H batch execution, or secret output.

### next_after

After the readiness matrix stabilizes, continue toward the minimal explicit real-runner adapter preflight implementation gate. Do not invoke a real/default runner, real background worker, DB-backed backtest, PL-H batch execution, migration, backfill, or secret output unless a later explicit gate proves authorization evidence, injected runner configuration, rollback/observability, audit before/after, fail-closed behavior, and PL-H eligibility decision matrix.

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
# 下一拍按 loop-state 执行 explicit dry-run proof review gate / runner-adapter readiness matrix；先跑 skill routing gate、worker dispatch gate 与 worker cluster/rendezvous gate；不要打印 DSN/token；不要重启 daily_bar/daily_trade_status/adj_factor；不要调用默认真实 runner、adapter dry-run execution 或 PL-H 批量执行。
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

- governance-coordinator thread: `019eeea7-6dc1-7121-8734-2e41c6e21b54`
- governance-coordinator report: success · read-only review confirmed missing hard gates and recommended skill_route_evidence / worker_dispatch_decision / goal_bundle detector
- researcher thread: `019eeebf-629e-7013-bbf4-1db4d312b925` · title `researcher` · report success on edict/kimi-code orchestration evidence scan
- architect thread: `019eeebf-b3a3-7ab3-bfe8-5a9c4b8b2936` · title `architect` · report success on CodeX worker cluster governance architecture
- test-engineer thread: `019eeece-52d7-7b73-868a-7beb496ba303` · title `test-engineer` · report success on loop213 dry-run planning gate RED design
- executor thread: `019eeece-c617-71c3-a80a-39a693ad3ac3` · title `executor` · report success on loop213 implementation scope review; final shared fixture patch serialized by orchestrator
- code-reviewer thread: `019eeed1-7e14-7342-9d45-d7948aec94d2` · title `code-reviewer` · report success on loop213 final semantic signoff
- verifier thread: `019eeed2-dbc0-7313-8d64-f9c6f199c68b` · title `verifier` · report success on loop213 final verification; clean-worktree closure belongs to orchestrator sync+commit gate
- prompt: `harness/templates/codex-subagent-prompt.md`
- task: read-only verification of CodeX effective constraints; latest multi-agent verifier run `019eedc6-f9c5-7c50-8170-18e415f7ce26` / nickname Lorentz reviewed loop186 target files and reported `success`
- note: orchestrator retains final authority; worker report is data, not truth source. Cross-dialogue worker is now preferred for governance / verifier signoff; temporary multi_agent is auxiliary only.

---

## Current Objective

TREE-2: data gate passed；daily_bar / daily_trade_status / adj_factor complete to 2026-06-18，loop144 adj_factor column path 审计确认 wired/closed；loop215 已完成 PL-G Jobs smoke fixture runner-adapter proof-harness modularization mocked-only，并用跨对话 worker cluster 完成 test design / scope review / code review / final verification。2026-06-22 governance repair 将 skill router / worker dispatch / goal bundle 从 advisory 提升为 loop 前置硬门禁；下一步必须执行 explicit dry-run proof review gate / runner-adapter readiness matrix TDD mocked-only，避免把 modularized proof evidence 误认为 runner invocation、adapter dry-run execution 或 PL-H execution。用户策略：数据 closure 后退出 backfill-monitoring，连续推进 auto mining → auto backtest full flow + intent understanding state machine / intent quant subgraph；closure/收口是阶段验收并继续下一切片，不是终点。

## Next Step

CodeX orchestrator 先跑 Goal/Plan Gate + Skill Routing Gate + Worker Dispatch Gate + Worker Cluster/Rendezvous Gate，然后执行 `explicit dry-run proof review gate / runner-adapter readiness matrix TDD mocked-only`：使用 extracted runner-adapter proof modules 与 loop208-loop215 evidence 定义 compact authorization evidence / injected runner config / rollback-audit before-after / fail-closed missing-runner / PL-H eligibility decision matrix；继续禁止 duplicate daily_bar/daily_trade_status/adj_factor、migration execution、backfill、background process、默认真实 DB-backed backtest、默认真实 runner/adapter dry-run execution、PL-H batch execution 与 secret 输出。

## Resume Command

CodeX 新会话首聊粘贴 `codex-zero-config-prompt.md` + 上方 CONTEXT 一行；之后任意消息从 `loop-state.json` 续跑。

```powershell
python harness/loop_tick.py prepare
```
