# High-Risk Change Template

Use this template for any change rated as medium or higher risk. Fill all sections before starting implementation. Project-level methodology is governed by `AGENTS.md`.

## 1. Current Problem

- Problem description:
- Impact scope:
- Risk level:

## 2. Target Behavior

- What should change:
- What explicitly should NOT change:

## 3. Invariants

- Which facts must not be broken:
- Which tables, watermarks, interfaces, or script behaviors must be preserved:

## 4. Failure Modes

- What happens on failure:
- Why `fail-open` or `fail-closed` was chosen:

## 5. Impact Surface

- Files affected:
- Documents affected:
- Tests affected:
- Scheduling/operations affected:

## 6. Verification Plan

- Local commands:
- Test suite:
- Manual checkpoints:

## 7. Rollback Path

- How to stop the new change from taking effect:
- How to restore to the last known good state:
- How to confirm rollback is complete:
