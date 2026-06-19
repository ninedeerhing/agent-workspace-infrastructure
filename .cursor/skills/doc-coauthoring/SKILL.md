---
name: doc-coauthoring
description: Guide users through a structured workflow for co-authoring documentation. Use when user wants to write documentation, proposals, technical specs, decision docs, or similar structured content. This workflow helps users efficiently transfer context, refine content through iteration, and verify the doc works for readers. Trigger when user mentions writing docs, creating proposals, drafting specs, or similar documentation tasks.
---

# Doc Co-Authoring Workflow

This skill provides a structured workflow for guiding users through collaborative document creation. Act as an active guide, walking users through three stages: Context Gathering, Refinement & Structure, and Reader Testing.

## When to Offer This Workflow

**Trigger conditions:**
- User mentions writing documentation: "write a doc", "draft a proposal", "create a spec", "write up"
- User mentions specific doc types: "PRD", "design doc", "decision doc", "RFC"
- User seems to be starting a substantial writing task

**Initial offer:**
Offer the user a structured workflow with three stages:

1. **Context Gathering**: User provides all relevant context while Claude asks clarifying questions
2. **Refinement & Structure**: Iteratively build each section through brainstorming and editing
3. **Reader Testing**: Test the doc with a fresh Claude (no context) to catch blind spots before others read it

Explain that this approach helps ensure the doc works well when others read it. Ask if they want to try this workflow or prefer to work freeform.

If user declines, work freeform. If user accepts, proceed to Stage 1.

## Stage 1: Context Gathering

**Goal:** Close the gap between what the user knows and what Claude knows.

### Initial Questions

Start by asking the user for meta-context:
1. What type of document is this? (e.g., technical spec, decision doc, proposal)
2. Who's the primary audience?
3. What's the desired impact when someone reads this?
4. Is there a template or specific format to follow?
5. Any other constraints or context to know?

### Info Dumping

Encourage the user to dump all context: background, related discussions, why alternatives aren't used, organizational context, timeline pressures, technical architecture, stakeholder concerns. Don't worry about organizing it.

### Asking clarifying questions
When user signals they've done their initial dump, ask 5-10 clarifying questions based on gaps in the context.

**Exit condition:** Sufficient context when questions show understanding — when edge cases and trade-offs can be asked about without needing basics explained.

## Stage 2: Refinement & Structure

**Goal:** Build the document section by section through brainstorming, curation, and iterative refinement.

For each section:
1. Ask clarifying questions about what to include
2. Brainstorm 5-20 options
3. User indicates what to keep/remove/combine
4. Draft the section
5. Refine through surgical edits

**Section ordering:** Start with whichever section has the most unknowns. For decision docs, that's usually the core proposal. For specs, it's typically the technical approach. Summary sections are best left for last.

**If user doesn't know what sections they need:** Suggest 3-5 sections appropriate for the doc type and ask if that structure works.

**Once structure is agreed:** Create the initial document structure with placeholder text for all sections. If artifacts are available, use `create_file` to create an artifact. Otherwise, create a markdown file in the working directory.

### For each section:

**Step 1: Clarifying Questions** — Ask 5-10 specific questions about what should be included.

**Step 2: Brainstorming** — Generate 5-20 numbered options depending on section complexity.

**Step 3: Curation** — Ask which points to keep, remove, or combine. Request brief justifications.

**Step 4: Gap Check** — Ask if there's anything important missing.

**Step 5: Drafting** — Replace placeholder text with actual drafted content using `str_replace`.

**Step 6: Iterative Refinement** — As user provides feedback, use `str_replace` to make edits. Continue iterating until user is satisfied.

### Quality Checking
After 3 consecutive iterations with no substantial changes, ask if anything can be removed without losing important information.

### Near Completion
When 80%+ of sections are done, re-read the entire document and check for flow, consistency, redundancy, and whether every sentence carries weight.

## Stage 3: Reader Testing

**Goal:** Test the document with a fresh Claude (no context bleed) to verify it works for readers.

### Testing Approach
1. Start a fresh Claude context
2. Provide the document content
3. Give the fresh Claude the role of the intended audience
4. Ask specific questions to test comprehension
5. Request a single sentence summary of what action the document asks of readers
6. Check if the summary matches the intended message

### Testing Questions
Ask the fresh Claude questions like:
- What is this document asking from you?
- What's unclear or confusing?
- What background knowledge do you feel you're missing?
- What information would you need to act on this?

### Final Polish
Based on reader testing results, fix blind spots and clarify any confusing sections. After final polish, the document is ready for the intended audience.
