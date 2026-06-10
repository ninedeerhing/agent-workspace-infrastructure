# Continuation Prompt

## Continuation Positioning

- This document is only a cross-conversation continuation copy; it does not bear historical completion records.
- Historical facts, verification results, review conclusions, risks, and priorities all defer to `docs/PROJECT_STATUS.md`.
- If this document conflicts with `docs/PROJECT_STATUS.md`, `docs/PROJECT_STATUS.md` takes precedence.
- In flow mode, after each turn syncs `docs/PROJECT_STATUS.md`, this document must also be synced. If the stop whitelist is not hit, `docs/FLOW-MODE.md` must be re-read to calibrate the loop protocol before continuing with the next atomic action.

## Current Continuation Entry

- Current mainline: `[TREE-X feature name]`
- Current direction: `[what are we doing right now]`
- Next direction: `[what follows when current completes]`
- Next-next direction: `[prevents disconnection]`
- State facts: derived from `docs/PROJECT_STATUS.md`

## Current Mainline Facts

- [Key paths, current runtime state, watermarks, remaining work]

## Flow Mode Continuation Rules

- On new conversation recovery, continuation is not a turn — it is the entry point back into the loop.
- The default posture after continuation is `execute immediately`, NOT summary-style continuation.
- After continuation, must first read `docs/PROJECT_STATUS.md` "Flow Mode Current Turn" section.
- After continuation, "current direction" becomes the sole immediate execution entry; "next direction" becomes the direct switch entry after current completes; "next-next direction" becomes the backup entry preventing re-disconnection.
- Stop judgment must explicitly check against `docs/FLOW-MODE.md` "Stop Whitelist" and `docs/PROJECT_STATUS.md` "Current turn stop judgment."
- If the stop whitelist is NOT explicitly hit, stopping at "turn summary," "next steps suggestion," or "should I continue" is NOT allowed.
- After each turn syncs `docs/PROJECT_STATUS.md` and this document, if the stop whitelist is NOT hit, must first re-read `docs/FLOW-MODE.md`, then immediately execute an actual next atomic action. Re-reading the protocol itself does NOT count as the next atomic action.

## Effective Continuation Prompt

```text
Take over this project and build context strictly in the following order:
1. CONSTITUTION.md
2. AGENTS.md
3. docs/PROJECT_STATUS.md (focus on Section 5 latest ledger + "Flow Mode Current Turn")
4. docs/CONTINUATION_PROMPT.md (this file)
5. docs/FLOW-MODE.md
6. docs/TASK_TREES.md

Facts and constraints:
- docs/PROJECT_STATUS.md is the single source of truth for state.
- docs/CONTINUATION_PROMPT.md is the minimal continuation copy; if conflicts, defer to docs/PROJECT_STATUS.md.
- docs/FLOW-MODE.md is the sole source of truth for flow mode execution rules.
- Current sole foreground mainline = [TREE-X], status = [state].
- After recovery, the first action must be executing the current direction, NOT a summary-style reply.
```
