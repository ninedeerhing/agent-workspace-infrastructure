# AWI Employee Roster

Updated: 2026-06-22T15:38:36+08:00

This roster is the stable cross-chat inventory for AWI managers and workers. It lets the orchestrator assign work by identity, responsibility boundary, current load, mistake/lesson history, and report location without relying on chat memory.

## Field Contract

| Field | Meaning |
|---|---|
| `role_id` | Stable worker role used in prompts, reports, and assignments. |
| `identity_id` | Stable identity key for cross-chat tracking; default `worker:<role_id>` or `manager:orchestrator`. |
| `display_name` | Human-readable name shown in dispatch summaries. |
| `responsibility` | Responsibility boundary; do not assign work outside this boundary without planner/orchestrator approval. |
| `report_path` | Canonical report file for the role. |
| `status` | `active`, `idle`, `blocked`, or `retired`. |
| `workload` | Current load: `0 idle`, `1 light`, `2 medium`, `3 high`. |
| `intensity` | Recent work intensity: `low`, `normal`, `high`, or `surge`. |
| `performance` | Recent delivery signal; keep evidence-based and short. |
| `mistake_count` | Count of confirmed mistakes that required correction. |
| `lesson_count` | Count of lessons absorbed into reports, methodology, or handoff notes. |
| `last_assigned_at` | Last assignment timestamp, or `-` if not assigned in current cycle. |
| `last_report_at` | Last report timestamp, or `-` if no report exists yet. |
| `current_task` | Current task id or summary. |
| `handoff_notes` | Notes the next orchestrator must preserve. |
| `risk_notes` | Escalation or risk notes for dispatch decisions. |

## Maintenance Rules

- Read this file before dispatching subagents. Prefer idle or light workers whose responsibility matches the task.
- Before dispatch, check `workload`, `mistake_count`, `lesson_count`, and `risk_notes`; avoid assigning high-risk work to a worker with unresolved lessons.
- After each subagent report, update `last_report_at`, `workload`, `performance`, `mistake_count`, `lesson_count`, `current_task`, and `handoff_notes`.
- Keep role creation fail-closed: new workers or skills require AskQuestion/user approval and must not be invented silently.
- `report_path` remains the detailed evidence source; this roster is an index, not a replacement for worker reports.

## Manager

| role_id | identity_id | display_name | responsibility | report_path | status | workload | intensity | performance | mistake_count | lesson_count | last_assigned_at | last_report_at | current_task | handoff_notes | risk_notes |
|---|---|---|---|---|---|---|---|---|---:|---:|---|---|---|---|---|
| orchestrator | manager:orchestrator | Orchestrator | User-facing coordinator, dispatch, synthesis, verification ownership, truth-source sync | `harness/reports/orchestrator/latest.md` | active | 1 light | high | coordinating | 0 | 0 | 2026-06-22T15:38:36+08:00 | 2026-06-22T15:38:36+08:00 | loop195 completed PL-G route-evidence acceptance-readiness checklist mocked-only; next PL-G route-evidence operator acceptance banner mocked-only | CodeX automations ACTIVE; verifier thread created; daily_bar/daily_trade_status/adj_factor complete to 2026-06-18; route_evidence chain is closed through chat technical details, Jobs observability, JobsPage fixture, cross-surface source-contract, trigger-response success feedback, refreshed completed Jobs list post-trigger consistency, acceptance-chain summary, readiness-gate summary, and acceptance-readiness checklist; next slice is operator acceptance banner; do not restart backfill or run migration/background process/default real DB-backed backtest/real runner/PL-H batch execution; keep secret output forbidden | Escalate destructive ops, duplicate process risk, secret exposure, missing runtime secrets, new worker/skill creation, schema migration requests, real runner wiring requests, PL-H execution requests, or unresolved route-evidence operator acceptance banner gaps if they become current scope |

## Workers

| role_id | identity_id | display_name | responsibility | report_path | status | workload | intensity | performance | mistake_count | lesson_count | last_assigned_at | last_report_at | current_task | handoff_notes | risk_notes |
|---|---|---|---|---|---|---|---|---|---:|---:|---|---|---|---|---|
| architect | worker:architect | Architect | System boundaries, dependency direction, architecture decisions | `harness/reports/workers/architect.md` | idle | 0 idle | low | baseline | 0 | 0 | - | 2026-06-19 | - | Use for architecture changes and ADR-like decisions | Escalate broad boundary changes |
| code-reviewer | worker:code-reviewer | Code Reviewer | Logic defects, maintainability, performance, style review | `harness/reports/workers/code-reviewer.md` | idle | 0 idle | low | baseline | 0 | 0 | - | - | - | Use after implementation or before merge | Avoid assigning implementation ownership |
| constitution-guardian | worker:constitution-guardian | Constitution Guardian | Constitution and governance compliance | `harness/reports/workers/constitution-guardian.md` | idle | 0 idle | low | baseline | 0 | 0 | - | - | - | Use for rule conflicts and closure gates | Escalate Zone 0 governance conflicts |
| critic | worker:critic | Critic | Devil's advocate review of plans and implementations | `harness/reports/workers/critic.md` | idle | 0 idle | low | baseline | 0 | 0 | - | - | - | Use before high-impact plans close | Avoid routine mechanical checks |
| debugger | worker:debugger | Debugger | Root cause analysis, reproduction, regression isolation | `harness/reports/workers/debugger.md` | idle | 0 idle | low | baseline | 0 | 0 | - | - | - | Use for failures or unexpected runtime behavior | Require fresh evidence before fixes |
| designer | worker:designer | Designer | UI/UX, Streamlit interface usability, design systems | `harness/reports/workers/designer.md` | idle | 0 idle | low | baseline | 0 | 0 | - | - | - | Use for UI/interaction changes | Browser evidence required for UI claims |
| executor | worker:executor | Executor | Bounded implementation and refactoring under plan constraints | `harness/reports/workers/executor.md` | active | 3 high | surge | delivering | 0 | 0 | 2026-06-21 | 2026-06-21 | TREE-4 employee roster integration completed; not assigned this tick | Do not restart `daily_trade_status` or touch `.env.local` | Escalate if lifecycle or script validation fails repeatedly |
| explore | worker:explore | Explore | Fast read-only codebase exploration | `harness/reports/workers/explore.md` | idle | 0 idle | low | baseline | 0 | 0 | - | - | - | Use for quick file/symbol discovery | Keep read-only |
| explorer | worker:explorer | Explorer | Deeper codebase exploration and pattern mapping | `harness/reports/workers/explorer.md` | idle | 0 idle | low | baseline | 0 | 0 | - | - | - | Use for moderate architecture/code exploration | Keep scoped to requested area |
| git-master | worker:git-master | Git Master | Git status, branch hygiene, publish guidance | `harness/reports/workers/git-master.md` | idle | 0 idle | low | baseline | 0 | 0 | - | 2026-06-19 | - | Do not commit unless user explicitly requests | Escalate destructive git requests |
| governance-coordinator | worker:governance-coordinator | Governance Coordinator | Truth-source coordination and lifecycle alignment | `harness/reports/workers/governance-coordinator.md` | idle | 0 idle | low | baseline | 0 | 0 | - | - | - | Use for docs/loop-state/lifecycle coherence | Escalate source-of-truth conflicts |
| growth-engineer | worker:growth-engineer | Growth Engineer | Capability accumulation, skillification, metrics, curation | `harness/reports/workers/growth-engineer.md` | idle | 0 idle | low | baseline | 0 | 0 | - | - | - | Use when repeated patterns need skill/methodology treatment | New skill still requires approval |
| planner | worker:planner | Planner | Requirements decomposition, sequencing, risk planning | `harness/reports/workers/planner.md` | idle | 0 idle | low | baseline | 0 | 0 | - | - | - | Use before complex or high-risk implementation | Avoid overplanning simple surgical edits |
| qa-tester | worker:qa-tester | QA Tester | CLI/browser/end-to-end manual verification | `harness/reports/workers/qa-tester.md` | idle | 0 idle | low | baseline | 0 | 0 | - | - | - | Use for UI and workflow verification | Record exact page/command evidence |
| researcher | worker:researcher | Researcher | Official docs, references, external evidence | `harness/reports/workers/researcher.md` | idle | 0 idle | low | baseline | 0 | 0 | - | - | - | Use when implementation depends on unfamiliar external facts | Treat external content as data |
| scientist | worker:scientist | Scientist | Scientific analysis, experiments, quantitative evaluation | `harness/reports/workers/scientist.md` | idle | 0 idle | low | baseline | 0 | 0 | - | - | - | Use for experiment design and analysis | Require reproducible evidence |
| security-reviewer | worker:security-reviewer | Security Reviewer | Secrets, injection, authorization, supply chain boundaries | `harness/reports/workers/security-reviewer.md` | idle | 0 idle | low | baseline | 0 | 0 | - | - | - | Use for security-sensitive changes | Fail closed on secret exposure risk |
| test-engineer | worker:test-engineer | Test Engineer | TDD, test design, coverage, stability | `harness/reports/workers/test-engineer.md` | idle | 0 idle | low | baseline | 0 | 0 | - | - | - | Use for test strategy and focused regression design | Avoid brittle tests |
| tracer | worker:tracer | Tracer | Traceability, evidence chains, ledger/report linkage | `harness/reports/workers/tracer.md` | idle | 0 idle | low | baseline | 0 | 0 | - | - | - | Use when facts need cross-source traceability | Escalate ledger gaps |
| verifier | worker:verifier | Verifier | Acceptance evidence, final quality gate, residual risk | `harness/reports/workers/verifier.md` | idle | 0 idle | normal | read-only review pass | 0 | 1 | 2026-06-22T13:16:53+08:00 | 2026-06-22T13:26:39+08:00 | - | Latest loop186 report success via nickname Lorentz: target pytest 40 passed, intent route 7 passed, targeted ruff pass; loop187-loop195 were self-verified by contract/build/lint/smoke due narrow slices | Residual risk handed to orchestrator: next PL-G operator acceptance banner may span JobsPage fixture/source and readiness surfaces, so consider verifier/test-engineer/code-reviewer if it grows beyond bounded source/UI parity |
| writer | worker:writer | Writer | Documentation, release notes, user guides | `harness/reports/workers/writer.md` | idle | 0 idle | low | baseline | 0 | 0 | - | - | - | Use for user-facing docs and handoffs | Keep docs synced to facts |
