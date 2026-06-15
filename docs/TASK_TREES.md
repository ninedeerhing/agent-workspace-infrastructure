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
| PL-001 | Cursor SDK 团队编排（Phase 5） | 2026-06-15 | 待 TREE-RT Phase 4 完成 |

## Active Trees

### TREE-RT: AWI 运行时改善（协议 → 操作系统）

- Status: `in_progress`
- Nature: `foreground_mainline`
- Completion: ~`95%`（运行时 OS 骨架 + bootstrap 全链路 smoke 通过）
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
  - `harness/gate-runner.ps1` — 阶段门禁
  - `.cursor/hooks.json` + `harness/hooks/` — sessionStart / post-edit 提醒
  - `skills/agent-team-bootstrap` + `skills/workflow-phase-advance`
- Current commit scope (core):
  - Phase 0–7 交付：compliance、boot、registry、worker 边界、mailbox、PAL、hooks、gate-runner、bootstrap -ProvisionTeam 全链路
- Unclosed points:
  - Phase 5 SDK 原生多会话编排（PL-001 parking_lot，不阻塞主线）
  - 各平台 adapter 增强（Codex send_message 等）按需迭代
- Processing rules:
  - 用户只与 orchestrator 对话；worker 通过 mailbox 协作
  - 有变更必须写 §5 台账
- Next atomic action:
  - 用户导入后执行 `bootstrap -Mode full -ProvisionTeam -Platform auto`，打开 orchestrator 会话即可开工

## Task Tree Governance Protocol

- Ask first: which tree does this belong to?
- Then ask: does it block the current mainline?
- If not blocking: register in `parking_lot`, do not modify code directly.
- If blocking AND independent theme: open a new `worktree`.
- If belongs to current mainline: proceed with minimal changes in current workspace.

## Current Mainline

- Current sole foreground mainline: `TREE-RT`（AWI 运行时改善）
- Current background themes: （无）

## EXCLUDE: Default Exclusions

- `*.log`
- `tmp/`
- Screenshots and debug artifacts
- Review scratch files
