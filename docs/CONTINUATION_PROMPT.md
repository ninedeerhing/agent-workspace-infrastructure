# Continuation Prompt

## Continuation Positioning

- This document is only a cross-conversation continuation copy; it does not bear historical completion records.
- Historical facts, verification results, review conclusions, risks, and priorities all defer to `docs/PROJECT_STATUS.md`.
- If this document conflicts with `docs/PROJECT_STATUS.md`, `docs/PROJECT_STATUS.md` takes precedence.

## Current Continuation Entry

- Current mainline: AWI CodeX-effective baseline 已验收（TREE-RT 防漂移维护）；业务主线为 `TREE-6 / PL-G` mining_job Template B
- Business mainline: `apps/quant_assistant` — daily_bar / daily_trade_status / adj_factor complete to 2026-06-18；loop220 已完成 `PL-G real runner authorization packet / dry-run execution preflight mocked-only`
- Current direction: 使用 CodeX orchestrator-Only 模式；日常只开 orchestrator 会话；CodeX worker 优先通过跨对话 `create_thread`/`send_message_to_thread`；下一拍必须先过 Goal/Plan Gate + Skill Routing Gate + Worker Dispatch Gate + Worker Cluster/Rendezvous Gate + Skill Lifecycle Gate + Worker Capacity Gate，再执行 `minimal real-runner dry-run eligibility reassessment TDD mocked-only`，使用 loop220 authorization packet / dry-run execution preflight 定义 fail-closed eligibility decision matrix：authorization evidence completeness、injected adapter config validation、rollback/audit before-after observability、missing-runner fail-closed behavior、PL-H non-eligibility/real-batch gate、operator approval boundary
- Post-backfill directive: 已退出 backfill-monitoring 方式，按真源连续推进唯一核心主线 **auto mining → auto backtest full flow + intent understanding state machine / intent quant subgraph**；closure/收口表示阶段验收通过并继续下一切片，不是结束方案或停止 loop
- Next direction: 读 `apps/quant_assistant/docs/CONTINUATION_PROMPT.md`（含 §5.544 loop220 authorization packet preflight 结论与 `minimal real-runner dry-run eligibility reassessment TDD mocked-only` 下一原子动作）
- Recovery: CodeX 有效性自检 → `harness/scripts/codex-self-check.ps1 -Format markdown`
- State facts: 见 `docs/PROJECT_STATUS.md` §5 与 `apps/quant_assistant/docs/PROJECT_STATUS.md` §5.544 最新台账；loop220 worker cluster `test-engineer=019eeece-52d7-7b73-868a-7beb496ba303` / `executor=019eeece-c617-71c3-a80a-39a693ad3ac3` / `code-reviewer=019eeed1-7e14-7342-9d45-d7948aec94d2` / `verifier=019eeed2-dbc0-7313-8d64-f9c6f199c68b` 已回报 success

## Current Mainline Facts

- AWI 源：`https://github.com/ninedeerhing/agent-workspace-infrastructure.git` · 本地 **main** 跟踪 `origin/raindeer-AWI`（AWI 架构 only · **非 feature 分支**）
- QA 源：`apps/quant_assistant` → `https://github.com/ninedeerhing/raindeer-quant-assistant.git` · 本地 **MUST main** → `origin/main`（**禁止** `cursor/*`/feature 日常分支 · GP-08）
- CodeX automations：`harness/codex-automation-registry.json` 记录 ACTIVE ids：`awi-loop-tick-heartbeat`（heartbeat 15min）、`awi-codex-self-check`、`awi-daily-compliance`、`awi-daily-git-push`；loop heartbeat prompt 已更新为可通过项目 loader safe env loading，仍禁止输出 `.env`/DSN/token
- 日末 push：`harness/scripts/daily-git-push.ps1` + CodeX `automation_update` id `awi-daily-git-push`（见 `harness/templates/daily-git-push-prompt.md`）
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
- quant_assistant business code is on TREE-6 / PL-G; loop220 proves the extracted runner-adapter proof modules can expose a real runner authorization packet / dry-run execution preflight gate without widening execution semantics. The gate covers fail-closed preflight artifact, authorization evidence required-not-granted, injected adapter config validation required-not-connected, rollback/audit before-after observability, missing-runner fail-closed rejection, PL-H non-eligibility recheck, operator approval boundary, and minimal eligibility reassessment next gate; smoke still shows `pageLoadTriggerRequests=[]`, `duplicateTriggerUrls=[]`, and `miningJobsReadCount=5`, while real/default runner invocation, actual adapter dry-run execution, background, migration/backfill, DB-backed backtest, PL-H execution, and secret output remain forbidden. The next slice is minimal real-runner dry-run eligibility reassessment mocked-only. The unique core mainline remains auto mining → auto backtest full flow + intent understanding state machine / intent quant subgraph.
- Side capability `PL-002` Codex skill routing/gating is now promoted into loop preflight governance. Phase 1 prototype lives in `harness/skill_router.py` with tests in `harness/tests/test_skill_router.py`; it does not modify global `~/.codex/skills`; telemetry goes to Git-ignored `tmp/skill-route-events.jsonl` and truth sources record only bounded summaries.
- Verify AWI: .\harness\scripts\codex-self-check.ps1 -Format markdown; .\harness\compliance-check.ps1 -Mode post-bootstrap
- Verify app: cd apps/quant_assistant && uv run pytest -q -m "not db and not external"
```
