# Task Tree Ledger

Maintenance principle: any new idea, new slice, or new concurrent theme must be registered in this file before implementation.

## Usage Rules

- Only 1 foreground mainline is allowed in `in_progress` at any time.
- New ideas default to `parking_lot` — do not start writing in the current workspace.
- Any second independent theme requires a separate `worktree / branch`.
- Commits are grouped by "task tree closure" — not by "files changed today."
- Temporary files, screenshots, review output, and environment directories are NOT task tree content — exclude by default.

## Parking Lot

New ideas registered here before implementation. Move to a TREE when ready to execute.

| ID | Theme | Registered | Status |
|----|-------|-----------|--------|
| PL-001 | SDK 原生团队编排深水区（Phase 5+） | 2026-06-15 | parking_lot；CodeX `create_thread`/`send_message_to_thread` 已覆盖当前跨会话 worker 需求 |
| PL-002 | Codex skills router / gating：hybrid retrieval、family dedupe、top-K exposure、telemetry/eval | 2026-06-22 | promoted into loop preflight governance：`Goal/Plan Gate` + `Skill Routing Gate` + `Worker Dispatch Gate`; router prototype stays under `harness/` and does not mutate global `~/.codex/skills` |
| PL-003 | CodeX worker cluster / rendezvous governance：goal envelope、cluster manifest、worker reports、retirement | 2026-06-22 | promoted into TREE-RT防漂移维护：参考 edict/kimi-code 只吸收治理模式，不复用代码；loop prompt/self-check/roster now require Worker Cluster/Rendezvous Gate |
| PL-004 | CodeX daily-ops consolidation：self-check/compliance/git-push 三个 daily 对话收束为一个 worker | 2026-06-23 | promoted into TREE-RT防漂移维护：`daily-ops` worker owns daily self-check, compliance, lifecycles, dual-repo git status, and daily git push reporting |

## Active Trees

### TREE-RT: AWI 运行时改善（协议 → 操作系统）

- Status: `in_progress`
- Nature: `foreground_mainline`
- Completion: `100%` for CodeX-effective baseline（运行时 OS 骨架 + bootstrap smoke + CodeX automation/worker/self-check 验收通过）
- Main chain files:
  - `docs/ENGINEERING/RAINDEER-AWI-NORTHSTAR.md` — 北极星目标态（Hub-Only / 跨平台 / 零提醒）
  - `docs/ENGINEERING/AWI-RUNTIME-IMPROVEMENT-PLAN.md` — 九阶段施工计划 v0.2
  - `harness/compliance-check.ps1` — Compliance Kernel（baseline + post-bootstrap）
  - `docs/SESSION_BOOT.md` — 统一会话入口
  - `harness/scripts/Build-AgentRegistryFromAgentsDir.ps1` — roster → registry
  - `harness/scripts/Apply-WorkerBoundaryToAgents.ps1` — 17 worker 边界注入
  - `harness/agent-registry.json` — 18 角色（1 hub + 17 worker）
  - `harness/mailbox/` + `Send-MailboxMessage.ps1` — 文件总线
  - `harness/adapters/` + `Invoke-PlatformAdapter.ps1` — PAL 跨平台
  - `docs/PLATFORM-CODEX.md` — CodeX 原生 primitives 与有效约束
  - `harness/codex-automation-registry.json` — CodeX `automation_update` 返回 id 台账
  - `harness/scripts/codex-self-check.ps1` — CodeX 有效性自检
  - `harness/scripts/daily-ops.ps1` — 单入口 daily ops wrapper
  - `harness/templates/daily-ops-prompt.md` — 单入口 daily ops CodeX prompt
  - `harness/templates/codex-self-check-prompt.md` — 定时自检 prompt
  - `harness/gate-runner.ps1` — 阶段门禁
  - `.cursor/hooks.json` + `harness/hooks/` — sessionStart / post-edit 提醒
  - `skills/agent-team-bootstrap` + `skills/workflow-phase-advance`
- Current commit scope (core):
  - Phase 0–7 交付：compliance、boot、registry、worker 边界、mailbox、PAL、hooks、gate-runner、bootstrap -ProvisionTeam 全链路
  - CodeX 生效交付：loop-tick heartbeat 按用户 2026-06-23 指令临时暂停为 `PAUSED_BY_USER`，当前业务 loop 改由 continuous orchestrator thread 执行；daily-ops 仍 ACTIVE 并绑定 pinned `daily-ops` thread；旧 self-check/compliance/git-push 三条 daily automation retired；旧 verifier duplicate 已归档；CodeX self-check 已验收 loop-tick `ACTIVE|PAUSED_BY_USER`
  - Worker cluster 交付：`researcher` thread `019eeebf-629e-7013-bbf4-1db4d312b925` + `architect` thread `019eeebf-b3a3-7ab3-bfe8-5a9c4b8b2936`；loop207 业务 cluster 已用 `test-engineer` / `executor` / `code-reviewer` / `verifier` 跨对话汇合；Worker Cluster/Rendezvous Gate 已接入 loop prompt/self-check/subagent prompt/roster/report
- Unclosed points:
  - Phase 5+ SDK 深水区仍 parking_lot，不阻塞当前 CodeX baseline
- Processing rules:
  - 用户只与 orchestrator 对话；CodeX worker 优先通过 `create_thread` / `send_message_to_thread`，`harness/mailbox/` 仅作 fallback 与审计
  - 有变更必须写 §5 台账
- Next atomic action:
  - 日常业务继续 `apps/quant_assistant` TREE-6 / PL-G manual-safe simulation happy path；架构侧用 `.\harness\scripts\daily-ops.ps1` + `.\harness\scripts\codex-self-check.ps1 -Format markdown` 防 skill/worker/goal/daily ops gate 漂移

## Task Tree Governance Protocol

- Ask first: which tree does this belong to?
- Then ask: does it block the current mainline?
- If not blocking: register in `parking_lot`, do not modify code directly.
- If blocking AND independent theme: open a new `worktree`.
- If belongs to current mainline: proceed with minimal changes in current workspace.

## Current Mainline

- Current sole foreground mainline: `TREE-6 / PL-G` mining_job Template B；`TREE-RT` CodeX-effective baseline 已验收，后续只做防漂移维护
- Current operational loop: `apps/quant_assistant` PL-G `MANUAL_SAFE_SIMULATION_HAPPY_PATH`（TREE-2 data gate passed；loop260 completed reviewed backtest plan handoff across MiningJob/API, Chat, and Jobs; worker permanent `codex_thread_id` and temporary `runtime_agent_id` are separated, and dispatch must verify cross-dialogue thread reachability before assignment；见 `harness/loop-state.json` and app §5.587）
- Post-backfill route: leave backfill-monitoring mode and continue `apps/quant_assistant` quant core toward the unique core mainline auto mining → auto backtest full flow + intent understanding state machine / intent quant subgraph. Closure/收口 means a stage gate passes and the loop advances to the next planned slice; it is not a terminal stop.
- Current background themes: `apps/quant_assistant` TREE-2 degraded/future/env gaps remain explicit but non-blocking; no active backfill batch
- Side capability themes: `PL-002` Codex skills router / gating, `PL-003` worker cluster / rendezvous governance, and `PL-004` daily-ops consolidation are promoted into loop/TREE-RT preflight gates; neither may overwrite global `~/.codex/skills` or create new worker roles without approval except the user-approved `daily-ops` worker. Router telemetry stays in Git-ignored `tmp/` unless summarized into truth sources.

## EXCLUDE: Default Exclusions

- `*.log`
- `tmp/`
- Screenshots and debug artifacts
- Review scratch files
