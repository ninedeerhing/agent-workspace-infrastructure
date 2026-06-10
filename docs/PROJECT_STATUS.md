# Project Status

This file serves as the **single source of truth for project state**. On every implementation push or decision change, synchronously update the following sections: overall milestones, module progress table, in-progress tasks, incomplete module list.

## Absolute Traceability Rule (Hard Constraint)

In this project, **everything you do must be recorded** with its current state, achieving absolute traceability.

"Everything" includes: reading/writing code, modifying scripts, running tests, browser re-verification, background task start/stop, root cause investigation, plan switching, risk judgment, and governance decisions.

The **sole traceability ledger** is Section 5 of this document ("Task Execution Ledger"). Any action without a file / test / review / runtime record in Section 5 is considered **not done**.

No gap is allowed where "code changed / tests ran / process started" but the ledger is not updated. If a gap is discovered, the ledger must be backfilled before continuing any mainline action.

## 1. Overall Milestones

| Milestone | Target | Status | Evidence |
|-----------|--------|--------|----------|

## 2. Module Progress

| Module | Completion | Status | Last Verified |
|--------|-----------|--------|---------------|

## 3. In-Progress Tasks

| Task | Tree | Owner | Status | Blockers |
|------|------|-------|--------|----------|

## 4. Incomplete Modules

| Module | Gap | Priority |
|--------|-----|----------|

## 5. Task Execution Ledger

This section is the sole traceability source for all executed actions. Every action (code change, test run, browser verification, process start/stop, root cause, decision) must be recorded here with: timestamp, action type, files touched, test evidence, review status, runtime state, and current conclusion.

### 5.1 Active Entries

| Timestamp | Action | Files | Tests | Evidence | Conclusion |
|-----------|--------|-------|-------|----------|------------|

### 5.2 Archival Anchor

Historical ledger entries can be archived below this line to keep the active section lean. Archived entries remain fully traceable.

---

## 6. Flow Mode Current Turn

- Current direction: [sole foreground mainline]
- Next direction: [natural follow-up after current completes]
- Next-next direction: [prevents disconnection after completion]
- Current turn stop judgment: only stop if whitelist is hit
- Recovery action: on continuation, read this section first to determine the three-layer direction, then cross-reference `docs/CONTINUATION_PROMPT.md` and `docs/TASK_TREES.md` to confirm which tree the current changes belong to. If not belonging to the current mainline, do not write in the current workspace by default.
