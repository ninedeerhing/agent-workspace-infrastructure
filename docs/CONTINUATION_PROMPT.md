# Continuation Prompt

## Continuation Positioning

- This document is only a cross-conversation continuation copy; it does not bear historical completion records.
- Historical facts, verification results, review conclusions, risks, and priorities all defer to `docs/PROJECT_STATUS.md`.
- If this document conflicts with `docs/PROJECT_STATUS.md`, `docs/PROJECT_STATUS.md` takes precedence.

## Current Continuation Entry

- Current mainline: AWI CodeX-effective baseline 已验收（TREE-RT 防漂移维护）；业务主线为 `TREE-6 / Factor Construction Universe`
- Business mainline: `apps/quant_assistant` — 因子构造宇宙真实可用链路正在补齐消费级自检和正式验收后发现的功能/产品缺口。loop892/SYNC-906 已完成 Factor Library result continuity context：真实回测复盘卡现在显示 plan refs、factor refs、run ids、`qa-pg-alt` DB runtime、runner ref、无替代 DB/Docker、page-load 不执行、will-run false 和下一步。下一步是 `POST_ACCEPTANCE_REPORT_FEEDBACK_MEMORY_HANDOFF_CONTEXT_LOOP893`。
- Current direction: 使用 CodeX orchestrator-only 模式；日常只开 orchestrator 会话；CodeX worker 优先通过跨对话 `send_message_to_thread` 续用永久 `codex_thread_id`；daily ops 只由 pinned `daily-ops` thread `019ef261-de0b-7ad0-8e9c-bb005dd38af0` 执行。canonical worker threads: test-engineer `019eeece-52d7-7b73-868a-7beb496ba303`, executor `019eeece-c617-71c3-a80a-39a693ad3ac3`, code-reviewer `019eeed1-7e14-7342-9d45-d7948aec94d2`, verifier `019eeed2-dbc0-7313-8d64-f9c6f199c68b`; `019ef130...` 是 runtime_agent_id 辅助证据，不得当 Codex thread id。下一拍必须先过 Goal/Plan Gate + Function-First Loop Gate + Skill Routing Gate + Worker Dispatch Gate + Worker Cluster/Rendezvous Gate + Skill Lifecycle Gate + Worker Capacity Gate，再执行 `POST_ACCEPTANCE_REPORT_FEEDBACK_MEMORY_HANDOFF_CONTEXT_LOOP893`；展示、UI 文案、业务原则、门禁、方法论、lifecycle 和真源同步只能作为核心功能完成后的 closing work。
- Post-backfill directive: 已退出 backfill-monitoring 方式，按真源连续推进唯一核心主线 **auto mining → auto backtest full flow + intent understanding state machine / intent quant subgraph**；closure/收口表示阶段验收通过并继续下一切片，不是结束方案或停止 loop
- **Next direction**: 读 `harness/loop-state.json`（当前业务下一原子动作是 `POST_ACCEPTANCE_REPORT_FEEDBACK_MEMORY_HANDOFF_CONTEXT_LOOP893`；Function-First Loop Gate v1.6 要求先声明 `core_function_artifact` / `phase_plan` / `functional_acceptance` / `closing_work_only`）
- Recovery: CodeX 有效性自检 → `harness/scripts/codex-self-check.ps1 -Format markdown`
- State facts: 见 `docs/PROJECT_STATUS.md` §5、`harness/loop-state.json` 与最新台账；SYNC-906 已完成 Factor Library result continuity context。下一步把 Factor Library 可见的 plan/run/factor context 写入 feedback memory/trajectory summary；缺口必须继续作为下一目标推进，不是停止点。
- Context loading mode: 正式切换为 **热路径轻量 + 冷路径可追溯回源**。每轮默认只加载当前 slice gate、§5 最新 1-3 条、下一动作、方法论 visible status、必要 worker/skill 索引；阶段切换、冲突、自检失败、安全/真实执行/发布门禁、worker/skill 新增或重绑、方法论 synthesis、用户审计时再冷路径回源完整真源。workflow 不舍弃，默认按当前 gate 片段使用。

## Current Mainline Facts

- AWI 源：`https://github.com/ninedeerhing/agent-workspace-infrastructure.git` · 本地 **main** 跟踪 `origin/raindeer-AWI`（AWI 架构 only · **非 feature 分支**）
- QA 源：`apps/quant_assistant` → `https://github.com/ninedeerhing/raindeer-quant-assistant.git` · 本地 **MUST main** → `origin/main`（**禁止** `cursor/*`/feature 日常分支 · GP-08）
- CodeX automations：`harness/codex-automation-registry.json` 记录 `loop-tick=PAUSED_BY_USER`（用户要求暂时停止 heartbeat，改用 continuous orchestrator thread loop，避免上下文爆炸）与 `awi-daily-ops=ACTIVE`（heartbeat bound to pinned `daily-ops` thread `019ef261-de0b-7ad0-8e9c-bb005dd38af0`）；旧 `awi-codex-self-check` / `awi-daily-compliance` / `awi-daily-git-push` 已被 `daily-ops` 取代；self-check 接受 loop-tick `ACTIVE|PAUSED_BY_USER`，仍禁止输出 `.env`/DSN/token
- 日末 push：由 pinned `daily-ops` thread 调用 `harness/scripts/daily-ops.ps1`，再调用 `harness/scripts/daily-git-push.ps1`，不再单独开 daily git push 对话（见 `harness/templates/daily-ops-prompt.md`）
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
- Worker model routing is now part of dispatch: non-critical/routine workers use `<=gpt-5.4` (`gpt-5.4-mini` for daily/status/index/report hygiene; `gpt-5.4` for ordinary read-only research/planning/governance/trace); critical code/design/architecture/security/real-execution/release-final-review workers must use `gpt-5.5`. Record `model_tier` and `model_reason`; do not create duplicate worker threads just to change model.
- Methodology memory is a visible truth source: read `apps/quant_assistant/docs/METHODOLOGY_MEMORY.md` top "当前可见状态" before loop work; every new `apps/quant_assistant/docs/PROJECT_STATUS.md` §5 row must include `methodology_ref` pointing to a digest/synthesis or `M-17-zero-write`.
- Context loading is budgeted: use `context_mode=hot_path` by default with only current slice gate, latest 1-3 ledger entries, next action, methodology visible status, and relevant worker/skill indexes. Trigger cold-path full-source reads only for phase switches, source conflicts, failed checks, security/real-execution/release gates, worker/skill creation or rebinding, methodology synthesis, or explicit audits.
- CodeX daily operations use the single pinned `daily-ops` worker thread `019ef261-de0b-7ad0-8e9c-bb005dd38af0`; do not create duplicate verifier, compliance, self-check, or git-push daily threads.
- quant_assistant business code is on TREE-6 / PL-G; current slice is `POST_ACCEPTANCE_REPORT_FEEDBACK_MEMORY_HANDOFF_CONTEXT_LOOP893`: carry Factor Library-visible plan/run/factor context into feedback memory and trajectory summary, so next generation can distinguish blocked/failed/completed-no-report/completed-report-ready provenance. No DB/Docker/scorer/backtest unless a later explicit controlled execution loop requires it. The unique core mainline remains auto mining → auto backtest full flow + intent understanding state machine / intent quant subgraph.
- Loop protocol is now Function-First v1.6: every business loop must declare `core_function_artifact`, `phase_plan`, `functional_acceptance`, and `closing_work_only`; display/UI copy/gates/checklists/methodology/lifecycle/truth-source sync may only close after the function is accepted and must not advance product `last_tick` by themselves.
- Side capability `PL-002` Codex skill routing/gating is now promoted into loop preflight governance. Phase 1 prototype lives in `harness/skill_router.py` with tests in `harness/tests/test_skill_router.py`; it does not modify global `~/.codex/skills`; telemetry goes to Git-ignored `tmp/skill-route-events.jsonl` and truth sources record only bounded summaries.
- Verify AWI: .\harness\scripts\codex-self-check.ps1 -Format markdown; .\harness\compliance-check.ps1 -Mode post-bootstrap
- Verify app: cd apps/quant_assistant && uv run pytest -q -m "not db and not external"
```
