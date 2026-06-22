# Codex Skill Router Prototype

Date: 2026-06-22
Status: Phase 1 prototype
Scope: AWI runtime side capability, not the current `apps/quant_assistant` loop mainline.

## Inputs

- User-provided radar report: `C:/Users/NINEDEER/Documents/Codex/2026-06-22/ba/outputs/radar-skills-routing-2026-06-22.md`
- Primary-source spot checks:
  - SkillMesh: top-K retrieval-gated exposure for large skill/tool catalogs.
  - Graph of Skills: offline skill graph plus dependency/co-occurrence rerank.
  - SkillResolve-Bench: same-capability harmful sibling suppression and `HSR@K`.
  - AnyTool: performance-aware tool memory and reliability ranking.

## Implemented

`harness/skill_router.py` provides a local, stdlib-only router:

- Discover local Codex `SKILL.md` files from `~/.codex/skills` and plugin cache.
- Parse `name` / `description` frontmatter.
- Build a skill index with inferred capability families.
- Route a task query with BM25-style lexical scoring plus trigram surface similarity.
- Apply intent guards for routing and debugging queries.
- Dedupe final exposure by family and report suppressed siblings.
- Render bounded JSON exposure bundles.
- Optionally record JSONL telemetry without raw query text; telemetry stores query hash, query length, shown skills, suppressed siblings, and outcome only.

## Verification

- RED: `python -m unittest discover -s harness\tests -p test_skill_router.py -v` initially failed because `harness.skill_router` did not exist.
- GREEN: `python -m unittest discover -s harness\tests -p test_skill_router.py -v` -> 8 tests OK.
- Syntax: `python -m py_compile harness\skill_router.py harness\tests\test_skill_router.py` -> pass.
- Real catalog smoke:
  - `python harness\skill_router.py --query "build a local Codex skills router with family dedupe and telemetry" --top-k 5 --pretty`
  - `python harness\skill_router.py --query "debug a failing regression" --top-k 3 --pretty`

## Current Findings

- Current Codex-local discovery sees about 500 skill cards and about 315 inferred families.
- The largest families are now bounded (`skill-management`, `qa`, `debug`, `tdd`, `code-review`, `browse`) instead of collapsing all skills under a generic `skills` path term.
- Path terms are excluded from scoring to avoid false positives from common folders like `.codex/skills`.
- Explicit route/router tasks now prefer router skills over generic local build skills.
- Explicit debug tasks now prefer debug family over benchmark noise.

## Limitations

- Dense embeddings are not implemented yet; current "hybrid" means BM25-style lexical + trigram surface scoring.
- Family clustering is still mostly deterministic aliasing, not learned or graph-aware.
- Telemetry is opt-in and local; no automatic Codex hook is installed.
- The router is advisory and does not alter Codex's native `/skill` exposure behavior yet.

## Next Steps

1. Add a small local eval set with positive, no-skill, ambiguous sibling, and multi-skill-chain cases.
2. Add graph-aware rerank metadata: dependency, workflow-next, substitute, risky-overlap.
3. Add telemetry summary gates: shown rate, outcome rate, and noisy-skill suppression candidates.
4. Consider a CodeX-safe wrapper prompt or automation that calls the router before large-skill tasks, but only after evaluation shows precision improves.
