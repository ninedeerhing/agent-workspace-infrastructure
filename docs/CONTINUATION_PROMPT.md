# Continuation Prompt

## Continuation Positioning

- This document is only a cross-conversation continuation copy; it does not bear historical completion records.
- Historical facts, verification results, review conclusions, risks, and priorities all defer to `docs/PROJECT_STATUS.md`.
- If this document conflicts with `docs/PROJECT_STATUS.md`, `docs/PROJECT_STATUS.md` takes precedence.

## Current Continuation Entry

- Current mainline: AWI CodeX-effective baseline 已验收（TREE-RT 防漂移维护）；业务主线为 `TREE-6 / PL-G` mining_job Template B
- Business mainline: `apps/quant_assistant` — daily_bar / daily_trade_status / adj_factor complete to 2026-06-18；loop176 已完成 `PL-G real batch demand gate TDD contract-only`
- Current direction: 使用 CodeX orchestrator-Only 模式；日常只开 orchestrator 会话；CodeX worker 通过 `create_thread`/`send_message_to_thread`；下一拍执行 `PL-G real batch demand gate API surface TDD mocked-only`，只暴露只读 gate summary，不接默认真实 runner
- Post-backfill directive: 已退出 backfill-monitoring 方式，按真源连续推进 **auto mining → auto backtest full flow + intent understanding state machine / intent quant subgraph**；closure/收口表示阶段验收通过并继续下一切片，不是结束方案或停止 loop
- Next direction: 读 `apps/quant_assistant/docs/CONTINUATION_PROMPT.md`（含 §5.499 real batch demand gate 结论与 `PL-G real batch demand gate API surface TDD mocked-only` 下一原子动作）
- Recovery: CodeX 有效性自检 → `harness/scripts/codex-self-check.ps1 -Format markdown`
- State facts: 见 `docs/PROJECT_STATUS.md` §5 与 `apps/quant_assistant/docs/PROJECT_STATUS.md` §5.499 最新台账

## Current Mainline Facts

- AWI 源：`https://github.com/ninedeerhing/agent-workspace-infrastructure.git` · 本地 **main** 跟踪 `origin/raindeer-AWI`（AWI 架构 only · **非 feature 分支**）
- QA 源：`apps/quant_assistant` → `https://github.com/ninedeerhing/raindeer-quant-assistant.git` · 本地 **MUST main** → `origin/main`（**禁止** `cursor/*`/feature 日常分支 · GP-08）
- CodeX automations：`harness/codex-automation-registry.json` 记录 ACTIVE ids：`awi-loop-tick-heartbeat`（heartbeat 15min）、`awi-codex-self-check`、`awi-daily-compliance`、`awi-daily-git-push`；loop heartbeat prompt 已更新为可通过项目 loader safe env loading，仍禁止输出 `.env`/DSN/token
- 日末 push：`harness/scripts/daily-git-push.ps1` + CodeX `automation_update` id `awi-daily-git-push`（见 `harness/templates/daily-git-push-prompt.md`）
- 同步方式：`bootstrap.ps1 -Mode minimum` + `-Mode full -Force -ProvisionTeam -Platform codex` 或 `harness/adapters/Invoke-PlatformAdapter.ps1 -Platform codex`
- Runtime OS：`harness/scripts/codex-self-check.ps1`, `harness/compliance-check.ps1`, `harness/codex-automation-registry.json`, `harness/reports/EMPLOYEE_ROSTER.md`, `harness/adapters/`
- 业务隔离：loop176 仅改 pure demand gate/test 合同与真源文档；未输出 DSN/token；未读取 `.env`；未执行 store/DB/env loader、migration/backfill/background process/default real runner/DB-backed backtest
- 会话入口：`docs/SESSION_SETUP.md` + `harness/templates/codex-zero-config-prompt.md`

## Effective Continuation Prompt

```text
Take over this project and build context strictly in the following order:
1. CONSTITUTION.md
2. AGENTS.md
3. docs/PROJECT_STATUS.md (focus on Section 5 latest ledger + "Flow Mode Current Turn")
4. docs/SESSION_BOOT.md
5. docs/CONTINUATION_PROMPT.md (this file)
6. docs/FLOW-MODE.md
7. docs/TASK_TREES.md
8. apps/quant_assistant/docs/PROJECT_STATUS.md (business mainline)

Facts and constraints:
- AWI Runtime OS is installed and CodeX-effective; orchestrator is the only user-facing agent.
- CodeX worker threads use `create_thread` and `harness/templates/codex-subagent-prompt.md`; mailbox is fallback/audit only.
- quant_assistant business code is on TREE-6 / PL-G; loop176 added pure `build_real_batch_demand_gate()` contract: it summarizes already-loaded `MiningJobV1` queue/backtest request pressure and returns `pl_h_deferred` / `pl_h_revisit` without store/DB/env/runner/background work. Read-only API surface mocked-only remains next.
- Verify AWI: .\harness\scripts\codex-self-check.ps1 -Format markdown; .\harness\compliance-check.ps1 -Mode post-bootstrap
- Verify app: cd apps/quant_assistant && uv run pytest -q -m "not db and not external"
```
