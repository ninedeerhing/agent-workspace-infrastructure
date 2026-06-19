# Continuation Prompt

## Continuation Positioning

- This document is only a cross-conversation continuation copy; it does not bear historical completion records.
- Historical facts, verification results, review conclusions, risks, and priorities all defer to `docs/PROJECT_STATUS.md`.
- If this document conflicts with `docs/PROJECT_STATUS.md`, `docs/PROJECT_STATUS.md` takes precedence.

## Current Continuation Entry

- Current mainline: AWI 基础设施已同步（TREE-RT 达标）
- Business mainline: `apps/quant_assistant` — PL-C-KB KB-0 完成；PL-C-GEN R0 验收待跑
- Current direction: 使用 orchestrator-Only 模式；日常只开 orchestrator 会话
- Next direction: 读 `apps/quant_assistant/docs/CONTINUATION_PROMPT.md`（含 Cursor 会话恢复索引 + 今日 P0/P1）
- Recovery: AWI 日度自检 prompt → `harness/templates/awi-daily-audit-prompt.md`
- State facts: 见 `docs/PROJECT_STATUS.md` §5 与 `apps/quant_assistant/docs/PROJECT_STATUS.md` §5 最新台账

## Current Mainline Facts

- AWI 源：`https://github.com/ninedeerhing/agent-workspace-infrastructure.git` @ main
- 同步方式：`bootstrap.ps1 -Mode minimum` + `-Mode full -Force -ProvisionTeam -Platform cursor`
- Runtime OS：`harness/compliance-check.ps1`, `harness/mailbox/`, `harness/adapters/`, `.cursor/hooks.json`
- 业务隔离：`apps/quant_assistant/` 未改动；pytest 1251 passed
- 会话入口：`docs/SESSION_SETUP.md` + `harness/templates/orchestrator-init-prompt.md`

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
- AWI Runtime OS is installed; orchestrator is the only user-facing agent.
- quant_assistant business code and harness/brain-workflows/ are unchanged.
- Verify AWI: .\harness\compliance-check.ps1 -Mode post-bootstrap
- Verify app: cd apps/quant_assistant && uv run pytest -q -m "not db and not external"
```
