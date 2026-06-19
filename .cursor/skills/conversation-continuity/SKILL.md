---
name: conversation-continuity
description: Use when the user wants to start a fresh conversation, generate a handoff prompt, resume a long-running project in a new chat, recover context after the current conversation gets too long, or avoid repeating work across conversations
---

# Conversation Continuity

## Overview

This skill packages repository facts into a clean handoff for the next conversation.

Core principle: the status ledger is the truth, while the continuation prompt and the final handoff are just organized views of that truth.

## When to Use

Use this skill when the user asks for any of the following:

- a new-chat prompt
- a handoff prompt
- a resume prompt
- a continuity summary for the next conversation
- a way to continue after the current chat gets too long
- a reminder of what to read first and what not to redo

Do not use this skill for normal progress summaries inside the current conversation unless the user explicitly wants cross-conversation handoff material.

## Required Inputs

Read these sources in order before producing the final output:

1. `AGENTS.md`
2. `docs/PROJECT_STATUS.md`
3. `docs/CONTINUATION_PROMPT.md` if it exists
4. any directly relevant active spec or plan only if needed

## Source Hierarchy

- `docs/PROJECT_STATUS.md` is the status truth
- `docs/CONTINUATION_PROMPT.md` is the copyable continuation view
- the final answer organizes facts; it does not invent or override them

If `docs/CONTINUATION_PROMPT.md` conflicts with `docs/PROJECT_STATUS.md`:

- say that a conflict exists
- follow `docs/PROJECT_STATUS.md`
- tell the user the continuation document should be refreshed

## Output Contract

Always produce these four blocks:

1. `可复制 Prompt`
2. `先读清单`
3. `下一步建议`
4. `避免重复劳动提醒`

If the repository is missing one of the expected source files, say so explicitly and continue with the best available facts instead of guessing.

## Workflow

1. Read `AGENTS.md` and capture the expected read order.
2. Read `docs/PROJECT_STATUS.md` and extract:
   - current mainline
   - recently completed work
   - latest verification summary
   - next-step priorities
   - explicit constraints or known pitfalls
3. Read `docs/CONTINUATION_PROMPT.md` and check whether it matches the current status.
4. If it matches, use it as a concise starting point.
5. If it does not match, rebuild the output from `docs/PROJECT_STATUS.md` and call out the drift.
6. Return the four required blocks in concise, copyable form.

## Preferred Shape

Use this structure:

- `可复制 Prompt`
  - short explanation
  - one fenced `text` block containing the copyable prompt body
- `先读清单`
  - `AGENTS.md`
  - `docs/PROJECT_STATUS.md`
  - `docs/CONTINUATION_PROMPT.md`
- `下一步建议`
  - next priority
- `避免重复劳动提醒`
  - what is already done

The prompt body should include:

- project name
- read order
- current mainline
- recent completions
- verification already done
- next step
- explicit "do not redo" reminders

## Common Failure Patterns

Without this workflow, agents often:

- treat a stale continuation note as the truth
- miss the current next-step priority
- forget validated constraints and rerun solved work
- produce a vague summary instead of a copyable handoff

This skill exists to prevent those failures.

## Common Mistakes

- Using `docs/CONTINUATION_PROMPT.md` as the truth source
- Copying the entire status ledger into the handoff
- Omitting the next-step recommendation
- Omitting the "do not redo" reminders
- Writing a narrative status essay instead of a copyable prompt

## Example Trigger

User: "当前对话太长了，帮我准备一段下一轮可以直接复制的续接 prompt。"

Result:

- read the repository truth sources
- reconcile any drift
- return the four fixed blocks
