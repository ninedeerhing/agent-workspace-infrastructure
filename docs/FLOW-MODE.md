# Flow Mode Protocol

When an agent reads this document, `docs/FLOW-MODE.md` is the sole source of truth for flow mode execution loops. Full turn summaries default to writing into the internal turn log in this document, and the log is a "single-slot for current turn" — not a historical append zone: each turn overwrites with the latest turn state. If the stop whitelist is not hit, only 1-2 short progress lines are allowed to the user; then immediately continue the next turn of work, advancing by the `spec -> plan -> execute` loop, until the stop whitelist is hit or the user explicitly requests a stop.

## Goals

- Lock down the sole current direction, next direction, and next-next direction.
- Decompose the current direction into continuously executable small tasks.
- Advance via `spec -> plan -> execute` loop.
- After each turn, sync status documents and continuation documents.
- Each turn must also sync two long-term memory files: `docs/PROJECT_STATUS.md` and `docs/CONTINUATION_PROMPT.md`.

## Execution States

- `in_progress`: Default state; must stay here and continue unless stop whitelist is hit.
- `need_question`: Only for critical branch selection, unclear requirements, or unclear facts; must return to `in_progress` after the question.
- `blocked`: Only for genuine blockage with no safe, accurate automatic continuation path.
- `ready_for_delivery`: Only after hitting the stop whitelist; only this state permits full summaries, staged deliveries, and stop-style replies.

## Output Constraints

- When stop whitelist is not hit: user side defaults to only 1-2 short progress lines.
- Full turn conclusions are written to this document's internal turn log, NOT the default user-side reply.
- When stop whitelist is not hit, prohibited outputs: `turn completed`, `turn results below`, `stage summary`, `suggested next steps`, `should I continue`, `if you want I can continue`, `documents synced, OK to stop`.
- Any intent to output a formal closing reply must first check whether the stop whitelist is hit.

## Execution Loop

1. Read `docs/PROJECT_STATUS.md`, `docs/CONTINUATION_PROMPT.md`, `apps/quant_assistant/docs/METHODOLOGY_MEMORY.md`, and current relevant spec/plan.
2. Review the ultimate goal, current completion, mainline risks, and the most natural next big direction.
3. Simultaneously assess "next big direction" and "next-next big direction".
4. Lock the sole mainline for the current turn; multiple concurrent mainlines not allowed.
5. Execute the current mainline (search, design, test, implement; if UI changes, do browser re-verification).
6. Write a full turn conclusion and update this document's internal turn log, including at minimum: completed facts, verification evidence, residual risks, next atomic action, and "why we cannot stop now" or "which stop whitelist entry was hit and why."
7. Sync this turn's results to `docs/PROJECT_STATUS.md` and `docs/CONTINUATION_PROMPT.md`.
7b. Sync retrospective to `apps/quant_assistant/docs/METHODOLOGY_MEMORY.md` (failures/rejections P0).
8. Determine whether the stop whitelist is hit.
9. If NOT hit: re-read this document to calibrate the loop protocol, then immediately execute an actual "next atomic action", then return to step 1. "Re-reading this document" itself does NOT count as the "next atomic action". User side keeps only short progress broadcast.
10. If whitelist IS hit: formal delivery and stop are permitted.

## Stop Whitelist

- User explicitly requests stopping flow mode: user clearly expresses "stop / pause / exit flow / don't auto-continue" or equivalent intent in the current conversation.
- Genuine blockage encountered with no safe, accurate automatic continuation path: missing required input, external dependency persistent errors, permission denied, or environment fault rendering the current mainline unverifiable or unimplementable.
- Destructive operation requiring explicit user authorization: will delete/overwrite real data, rewrite irreversible state, execute high-risk migration, publish to external environment, or produce actual external side effects.
- Critical facts unclear, continuing would cause high-probability implementation or data damage: key requirements, data ownership, target environment, interface contract, or operation target has unresolved conflicts that cannot be resolved through code, documentation, logs, or read-only investigation.
- Arrival at a key node that must be delivered for user trial or review: mainline goal has produced a runnable, accessible, verifiable user-trial-able increment, or has produced a complete rules/document result that must be reviewed/confirmed by the user, and further progress requires actual user experience, direction confirmation, or feedback.

## Constraints

- Default: do not wait for human review, do not ask "should I continue" pause questions.
- Each turn must explicitly state: current direction, next direction, next-next direction.
- `in_progress` is not a state that permits formal closing output.
- "Turn results" is not a stop point.
- Focused tests passing, browser re-verification passing, document sync completing — none are stop points.
- Unless stop whitelist is hit, must continue pushing forward.
- Each turn must complete the sync of `docs/PROJECT_STATUS.md` and `docs/CONTINUATION_PROMPT.md`.
- After syncing, if stop whitelist is NOT hit, must first re-read this document to calibrate the loop protocol, then immediately execute a "next atomic action".
- "Next atomic action" must be an actual action: reading relevant code/docs, fixing a failing test, doing minimal implementation, running targeted tests, doing real re-verification. "Re-reading this document" does not count.
- Planning sentences like "next step: prepare to start" or "if you confirm I'll continue" do NOT count as the next atomic action.
- If reusable methodology is formed this turn, it should be synced to project documentation or long-term memory.

## Current Turn Log

This area is a single-slot for the current turn, not a historical archive. Each turn end must overwrite the following fields with the latest turn content, NOT append multiple turns chronologically.

- Current direction: [sole foreground mainline]
- Next direction: [what naturally follows after current completes]
- Next-next direction: [prevents loss of direction after completion]
- This turn completed: [facts, not intentions]
- Verification evidence: [tests, commands, browser checks]
- Residual risks: [what could still break]
- Next atomic action: [specific, executable, not a plan sentence]
- Why we cannot stop now: [whitelist check]
