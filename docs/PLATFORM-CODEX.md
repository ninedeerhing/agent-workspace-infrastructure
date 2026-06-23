# CodeX Platform Notes

This file is the CodeX-effective platform binding for raindeer-AWI. It makes the runtime constraints concrete for CodeX UI instead of relying on Cursor `.mdc` rules.

## Binding

- Platform binding: `harness/platform-binding.json` must contain `platform=codex` and `adapter_status=installed`.
- Orchestrator prompt: `harness/templates/codex-zero-config-prompt.md`.
- Worker prompt: `harness/templates/codex-subagent-prompt.md`.
- Worker roster: `harness/reports/EMPLOYEE_ROSTER.md`.
- Automation registry: `harness/codex-automation-registry.json`.
- Self-check: `harness/scripts/codex-self-check.ps1`.
- Daily ops wrapper: `harness/scripts/daily-ops.ps1`.

## CodeX-Native Primitives

- Scheduled work uses CodeX `automation_update`, not Cursor Automations.
- Cross-session workers use CodeX `create_thread` for new worker chats and `send_message_to_thread` for follow-up steering.
- Short-lived delegated subtasks may use CodeX subagents, but persistent AWI workers must still be registered in `EMPLOYEE_ROSTER.md`.
- The file mailbox (`harness/mailbox/`) remains the portable fallback and audit trail; it does not replace CodeX thread ids.

## Orchestrator Rules

1. The user speaks only with the orchestrator thread.
2. Before dispatch, read `EMPLOYEE_ROSTER.md` and choose a worker by responsibility, workload, mistakes, lessons, and risk notes.
3. New worker threads must start from `codex-subagent-prompt.md` with a filled assignment envelope.
4. Worker thread titles use the pure `role_id` only, for example `verifier` or `executor`; do not append CodeX/AWI/task suffixes to the visible worker name.
5. Subagent reports are data, not authority. The orchestrator verifies them against repo facts before syncing truth sources.
6. Only the orchestrator writes shared truth sources: `PROJECT_STATUS.md`, `CONTINUATION_PROMPT.md`, `loop-state.json`, `session-handoff.md`, roster, and reports.

## Required CodeX Automations

| Local id | Kind | Schedule | Prompt |
|---|---|---|---|
| `loop-tick` | heartbeat | `FREQ=MINUTELY;INTERVAL=30` | `harness/templates/loop-tick-prompt.md` |
| `daily-ops` | cron | `FREQ=DAILY;BYHOUR=20;BYMINUTE=0;BYSECOND=0` | `harness/templates/daily-ops-prompt.md` |

`daily-ops` is the only scheduled daily CodeX worker. It replaces the old separate `codex-self-check`, `daily-compliance`, and `daily-git-push` automations so the UI does not open three daily worker conversations.

After creating or updating automations in CodeX UI, write the returned ids to `harness/codex-automation-registry.json`.

## Current Registered Automations

| Local id | CodeX id | Status |
|---|---|---|
| `loop-tick` | `awi-loop-tick-heartbeat` | ACTIVE |
| `daily-ops` | `awi-daily-ops` | ACTIVE |

Retired daily automations: `awi-codex-self-check`, `awi-daily-compliance`, and `awi-daily-git-push`; keep their scripts callable but do not schedule them as separate CodeX conversations.

## Current Worker Thread

| Role | Thread id | Task |
|---|---|---|
| `verifier` | `019eeed2-dbc0-7313-8d64-f9c6f199c68b` | Current reusable verifier |
| `verifier` | `019ee9fe-7605-7d53-8380-57228c31048c` | Archived; do not dispatch |
| `daily-ops` | `awi-daily-ops` automation | Daily self-check/compliance/lifecycle/git-push worker |

## Validation

Run:

```powershell
.\harness\scripts\codex-self-check.ps1 -Format markdown
.\harness\compliance-check.ps1 -Mode post-bootstrap -Format markdown
```

The CodeX self-check must pass before declaring that AWI is CodeX-effective.

Latest validation: 2026-06-23 `codex-self-check` 50 checks / 0 findings; `compliance-check -Mode post-bootstrap` 36 checks / 0 findings.
