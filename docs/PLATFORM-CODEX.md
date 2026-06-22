# CodeX Platform Notes

This file is the CodeX-effective platform binding for raindeer-AWI. It makes the runtime constraints concrete for CodeX UI instead of relying on Cursor `.mdc` rules.

## Binding

- Platform binding: `harness/platform-binding.json` must contain `platform=codex` and `adapter_status=installed`.
- Orchestrator prompt: `harness/templates/codex-zero-config-prompt.md`.
- Worker prompt: `harness/templates/codex-subagent-prompt.md`.
- Worker roster: `harness/reports/EMPLOYEE_ROSTER.md`.
- Automation registry: `harness/codex-automation-registry.json`.
- Self-check: `harness/scripts/codex-self-check.ps1`.

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
| `codex-self-check` | cron | `FREQ=DAILY;BYHOUR=8;BYMINUTE=0;BYSECOND=0` | `harness/templates/codex-self-check-prompt.md` |
| `daily-compliance` | cron | `FREQ=DAILY;BYHOUR=20;BYMINUTE=0;BYSECOND=0` | `harness/templates/daily-compliance-prompt.md` |
| `daily-git-push` | cron | `FREQ=DAILY;BYHOUR=20;BYMINUTE=30;BYSECOND=0` | `harness/templates/daily-git-push-prompt.md` |

After creating or updating automations in CodeX UI, write the returned ids to `harness/codex-automation-registry.json`.

## Current Registered Automations

| Local id | CodeX id | Status |
|---|---|---|
| `loop-tick` | `awi-loop-tick-heartbeat` | ACTIVE |
| `codex-self-check` | `awi-codex-self-check` | ACTIVE |
| `daily-compliance` | `awi-daily-compliance` | ACTIVE |
| `daily-git-push` | `awi-daily-git-push` | ACTIVE |

## Current Worker Thread

| Role | Thread id | Task |
|---|---|---|
| `verifier` | `019ee9fe-7605-7d53-8380-57228c31048c` | Read-only verification |

## Validation

Run:

```powershell
.\harness\scripts\codex-self-check.ps1 -Format markdown
.\harness\compliance-check.ps1 -Mode post-bootstrap -Format markdown
```

The CodeX self-check must pass before declaring that AWI is CodeX-effective.

Latest validation: 2026-06-21 `codex-self-check` 27 checks / 0 findings; `compliance-check -Mode post-bootstrap` 36 checks / 0 findings.
