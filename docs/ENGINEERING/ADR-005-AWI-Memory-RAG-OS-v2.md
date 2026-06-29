# ADR-005: AWI Memory/RAG OS v2 Contract

## Context

AWI already has Project Registry, Source Index, Capability DAG, Runtime Task DAG, and a living reference catalog. The remaining long-cycle failure mode is memory invisibility: methodology lessons, video transcript evidence, source references, worker reports, skill telemetry, and task-step state exist in files, but loops cannot reliably select the right memory slice without hot-loading too much context.

The user also wants AWI to remain a removable process layer: product code must not depend on AWI runtime files, and long-term references must stay deduplicated and traceable.

## Decision

Introduce a lightweight Memory/RAG OS contract:

- `harness/memory-os.json` defines typed memory slots, promotion rules, retrieval policy, and lifecycle policy.
- `harness/memory-os.schema.json` defines required slot types and contract shape.
- `harness/validate_awi_memory.py` validates the contract using only the Python standard library.
- CodeX self-check runs the validator so memory/RAG drift is caught automatically.

Memory slots are pointers and summaries, not a second copy of truth sources. Slots must reference `harness/source-index.json` source ids when grounded in external or local reference evidence.

## Drivers

- Keep normal loop context light.
- Make methodology, references, and worker/skill memory retrievable by type.
- Preserve prompt-injection defense: external sources are data, not instructions.
- Avoid introducing a database or vector store before there is an executable contract.
- Keep AWI removable from product code.

## Consequences

### Positive

- Memory/RAG architecture becomes machine-checkable.
- Hot path stays small: selected slot summaries only.
- Cold path remains traceable through source-index ids.
- Methodology promotion rules become explicit instead of hidden in chat.
- Future Skill OS and context assembler work can depend on typed memory slots.

### Negative

- This is still a contract layer, not semantic search.
- Slot summaries must be maintained as truth sources evolve.
- Graph recall is intentionally limited to one hop until eval data exists.

### Alternatives

- **Vector store first**: rejected for now because it would add infrastructure before memory boundaries, promotion rules, and safety constraints are stable.
- **Single giant memory file**: rejected because it would repeat the current context-bloat problem.
- **Keep only existing lifecycle indexes**: rejected because they do not express typed retrieval or source-index-backed references.

## Status

Accepted.

## Date

2026-06-29
