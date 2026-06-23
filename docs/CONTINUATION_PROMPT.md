# Continuation Prompt

## Continuation Positioning

- This document is only a cross-conversation continuation copy; it does not bear historical completion records.
- Historical facts, verification results, review conclusions, risks, and priorities all defer to `docs/PROJECT_STATUS.md`.
- If this document conflicts with `docs/PROJECT_STATUS.md`, `docs/PROJECT_STATUS.md` takes precedence.

## Current Continuation Entry

- Current mainline: AWI CodeX-effective baseline 已验收（TREE-RT 防漂移维护）；业务主线为 `TREE-6 / PL-G` mining_job Template B
- Business mainline: `apps/quant_assistant` — daily_bar / daily_trade_status / adj_factor complete to 2026-06-18；loop239 已完成 `PL-G explicit executable handoff authorization packet mocked-only`
- Current direction: 使用 CodeX orchestrator-Only 模式；日常只开 orchestrator 会话；CodeX worker 优先通过跨对话 `create_thread`/`send_message_to_thread`；daily ops 只由 `daily-ops` worker/automation 统一执行，旧 `codex-self-check` / `daily-compliance` / `daily-git-push` 不再单独开对话；下一拍必须先过 Goal/Plan Gate + Skill Routing Gate + Worker Dispatch Gate + Worker Cluster/Rendezvous Gate + Skill Lifecycle Gate + Worker Capacity Gate，再执行 `executable handoff gate review TDD mocked-only`，使用 loop239 explicit executable handoff authorization packet 定义 fail-closed executable handoff gate review：operator/reviewer authorization still not granted、runner/adapter config still not connected、rollback/audit before-after readiness still required、missing-runner fail-closed rejection、PL-H still not eligible until real-batch gate、no-execution executable handoff gate review acceptance、executable handoff still blocked until explicit authorization+config+rollback/audit+real-batch gate
- Post-backfill directive: 已退出 backfill-monitoring 方式，按真源连续推进唯一核心主线 **auto mining → auto backtest full flow + intent understanding state machine / intent quant subgraph**；closure/收口表示阶段验收通过并继续下一切片，不是结束方案或停止 loop
- Next direction: 读 `apps/quant_assistant/docs/CONTINUATION_PROMPT.md`（含 §5.563 loop239 explicit executable handoff authorization packet 结论与 `executable handoff gate review TDD mocked-only` 下一原子动作）
- Recovery: CodeX 有效性自检 → `harness/scripts/codex-self-check.ps1 -Format markdown`
- State facts: 见 `docs/PROJECT_STATUS.md` §5 与 `apps/quant_assistant/docs/PROJECT_STATUS.md` §5.563 最新台账；loop239 worker cluster `test-engineer=019ef130-2e3a-7210-a305-bc34ff0a5bcc` / `executor=019ef130-5a38-7951-933f-4f64c4b7917d` / `code-reviewer=019ef130-86cb-7e23-8a8f-fc490f1a07bd` / `verifier=019ef130-b3c9-7201-a4cd-af2240391a6b` 已回报 success

## Current Mainline Facts

- AWI 源：`https://github.com/ninedeerhing/agent-workspace-infrastructure.git` · 本地 **main** 跟踪 `origin/raindeer-AWI`（AWI 架构 only · **非 feature 分支**）
- QA 源：`apps/quant_assistant` → `https://github.com/ninedeerhing/raindeer-quant-assistant.git` · 本地 **MUST main** → `origin/main`（**禁止** `cursor/*`/feature 日常分支 · GP-08）
- CodeX automations：`harness/codex-automation-registry.json` 记录 ACTIVE ids：`awi-loop-tick-heartbeat`（heartbeat 15min）与 `awi-daily-ops`；旧 `awi-codex-self-check` / `awi-daily-compliance` / `awi-daily-git-push` 已被 `daily-ops` 取代；loop heartbeat prompt 已更新为可通过项目 loader safe env loading，仍禁止输出 `.env`/DSN/token
- 日末 push：由 `harness/scripts/daily-ops.ps1` 调用 `harness/scripts/daily-git-push.ps1`，不再单独开 daily git push 对话（见 `harness/templates/daily-ops-prompt.md`）
- 同步方式：`bootstrap.ps1 -Mode minimum` + `-Mode full -Force -ProvisionTeam -Platform codex` 或 `harness/adapters/Invoke-PlatformAdapter.ps1 -Platform codex`
- Runtime OS：`harness/scripts/codex-self-check.ps1`, `harness/compliance-check.ps1`, `harness/codex-automation-registry.json`, `harness/reports/EMPLOYEE_ROSTER.md`, `harness/adapters/`
- 业务隔离：loop199 仅做 mocked/source-contract/browser-smoke route evidence acceptance risk register，未输出 DSN/token；未读取 `.env`；未执行 page-load auto POST、默认 trigger、真实 runner、migration/backfill/background process/default real runner/DB-backed backtest/PL-H batch execution
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
- CodeX worker threads use `create_thread` and `harness/templates/codex-subagent-prompt.md`; mailbox is fallback/audit only. Complex goal bundles require `cluster_manifest`, `worker_report_refs`, and rendezvous gate before completion.
- CodeX daily operations use the single `daily-ops` worker; do not create duplicate verifier, compliance, self-check, or git-push daily threads.
- quant_assistant business code is on TREE-6 / PL-G; loop239 proves the extracted runner-adapter proof modules can expose an explicit executable handoff authorization packet without widening execution semantics. The gate is authorization-packet-only/not-execution and covers source=loop238 later executable handoff gate preflight, fail_closed_explicit_executable_handoff_authorization_packet_not_execution, operator/reviewer authorization still_not_granted, runner/adapter config still_not_connected, rollback/audit before-after readiness required, missing-runner fail-closed rejection, PL-H not eligible until real-batch gate, no-execution executable authorization packet acceptance, executable handoff blocked until explicit authorization+config+rollback/audit+real-batch gate, and the executable handoff gate review next gate; smoke still shows `pageLoadTriggerRequests=[]`, `duplicateTriggerUrls=[]`, and `miningJobsReadCount=5`, while real/default runner invocation, adapter invocation, actual adapter dry-run execution, background, migration/backfill, DB-backed backtest, PL-H execution, and secret output remain forbidden. The next slice is executable handoff gate review mocked-only. The unique core mainline remains auto mining → auto backtest full flow + intent understanding state machine / intent quant subgraph.
- Side capability `PL-002` Codex skill routing/gating is now promoted into loop preflight governance. Phase 1 prototype lives in `harness/skill_router.py` with tests in `harness/tests/test_skill_router.py`; it does not modify global `~/.codex/skills`; telemetry goes to Git-ignored `tmp/skill-route-events.jsonl` and truth sources record only bounded summaries.
- Verify AWI: .\harness\scripts\codex-self-check.ps1 -Format markdown; .\harness\compliance-check.ps1 -Mode post-bootstrap
- Verify app: cd apps/quant_assistant && uv run pytest -q -m "not db and not external"
```
