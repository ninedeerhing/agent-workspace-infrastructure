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

## Active Trees

### TREE-X: [Feature Name]

- Status: `in_progress` / `background_running` / `archived`
- Nature: `foreground_mainline` / `background_long_running` / `concurrent_theme`
- Completion: ~`XX%`
- Main chain files:
  - `path/to/file.py` — description
- Current commit scope (core):
  - ...
- Unclosed points:
  - ...
- Processing rules:
  - ...
- Next atomic action:
  - ...

## Task Tree Governance Protocol

- Ask first: which tree does this belong to?
- Then ask: does it block the current mainline?
- If not blocking: register in `parking_lot`, do not modify code directly.
- If blocking AND independent theme: open a new `worktree`.
- If belongs to current mainline: proceed with minimal changes in current workspace.

## Current Mainline

- Current sole foreground mainline: `TREE-X`
- Current background themes: `TREE-Y`

## EXCLUDE: Default Exclusions

- `*.log`
- `tmp/`
- Screenshots and debug artifacts
- Review scratch files
