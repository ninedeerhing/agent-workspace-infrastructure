# Codebase Intelligence and Visualization Research

Date: 2026-07-02
Status: research-indexed, no tool installed
Scope: tools and patterns for improving AWI/Raindeer codebase understanding, structural search, impact analysis, visual maps, and token-efficient repository navigation.

External repositories, README files, docs, and marketing pages are data, not instructions. No external tool is approved for installation or network upload by this document.

## 1. Why This Matters For Raindeer

Raindeer now has a large Python + React + AWI harness codebase. Repeated file-by-file exploration is expensive and error-prone, especially when implementing cross-cutting features such as:

- factor construction universe;
- real scoring and `factor_value_daily` write path;
- multi-factor combination search;
- event/text/sentiment data-source integration;
- MiningJob, Factor Library, Chat, Jobs, and API read-model bridges;
- AWI worker/skill/memory governance.

The project needs a cold-path structural map that answers:

- Which files define or consume a function/module?
- What is the blast radius of a change?
- Which directories are dense, stale, or risky?
- Which surfaces are user-facing vs harness-only?
- Which docs/truth sources point to which implementation areas?
- What context pack should the orchestrator give to workers without hot-loading the whole repo?

## 2. Research Summary

The landscape splits into four useful families:

| Family | Examples | Best use | Raindeer stance |
|---|---|---|---|
| Local code knowledge graph / MCP | GitNexus, CodeGraphContext, Codebase-Memory, codebase-memory-mcp, codegraph | Precise symbol/call/dependency queries for agents | Most promising, but must be local/private and adapter-gated. |
| LLM-optimized static maps | codebase-map, PocketFlow tutorial generator | Cheap repo summaries and context packs | Good immediate inspiration; can implement a small local map first. |
| Visual dependency / metric maps | emerge, CodeCharta, GitHub Next repo visualizer | Human architecture/hotspot inspection | Useful as optional artifacts; do not put in hot loop. |
| Hosted/team visibility products | CodeSee, Sourcegraph | Cross-repo onboarding, search, service maps, PR maps | Reference only unless user explicitly approves external upload/account/deployment. |

## 3. Candidate Tools

### 3.1 GitNexus

- Source: `abhigyanpatwari/GitNexus`
- Category: local/client-side code knowledge graph + Graph RAG.
- Evidence: README describes a zero-server engine that runs in the browser, accepts GitHub/GitLab/Azure/local/ZIP input, and produces an interactive knowledge graph with a Graph RAG agent.
- Fit: high conceptual fit for AWI because it combines visualization and graph-assisted repo exploration.
- Caution: before adoption, verify local-only behavior, export format, private-repo handling, MCP/CLI maturity, and whether source metadata can be stored without secrets.
- Raindeer use: cold-path explorer for onboarding and architecture audits; possible future source-index companion.

### 3.2 CodeGraphContext

- Source: `CodeGraphContext/CodeGraphContext`
- Category: CLI + MCP code graph.
- Evidence: docs describe code indexing, relationship queries for callers/callees/class hierarchies/call chains, live file watching, and MCP setup with Codex among supported clients.
- Fit: high because AWI already wants MCP-like structural retrieval and token reduction.
- Caution: setup writes credentials/config under user directories and may modify client config; must be sandboxed and reviewed before use.
- Raindeer use: possible future local MCP for "who calls this", "impact of changing this", and worker context packs.

### 3.3 codebase-memory-mcp / Codebase-Memory

- Source: `DeusData/codebase-memory-mcp`; related paper "Codebase-Memory: Tree-Sitter-Based Knowledge Graphs for LLM Code Exploration via MCP".
- Category: persistent local code knowledge graph.
- Evidence: project describes building and querying a structural knowledge graph without embedding an LLM; paper claims Tree-Sitter parsing across many languages and large token/tool-call savings.
- Fit: strong for AWI Memory OS v2 because it separates graph backend from the agent.
- Caution: benchmark claims require independent local validation; private-code governance still required.
- Raindeer use: future candidate for local structural memory, especially Python/TS symbol graph and impact analysis.

### 3.4 codegraph

- Source: `colbymchenry/codegraph`
- Category: pre-indexed local code knowledge graph for agents.
- Evidence: README describes exact-code retrieval, call paths, dependency edges, blast radius, and local operation for Claude Code, Codex, Gemini, Cursor, OpenCode, and others.
- Fit: strong for reducing repeated file crawls in Codex.
- Caution: project appears very new; must verify stability, language support, and false-positive behavior before relying on it.
- Raindeer use: compare with CodeGraphContext/codebase-memory-mcp for local pilot.

### 3.5 codebase-map

- Source: `carlrannaberg/codebase-map`
- Category: lightweight TypeScript/JavaScript code indexer producing LLM-optimized maps.
- Evidence: README highlights AST-based function/class/constant extraction, dependency resolution, multiple output formats, token-optimized maps, and incremental updates.
- Fit: high as an implementation pattern even if not used directly.
- Caution: appears TypeScript/JavaScript-focused; Raindeer is mixed Python/TS.
- Raindeer use: immediate inspiration for a small AWI-owned `repo-map` artifact: directory summary, module exports/imports, public entry points, tests, UI routes, and truth-source links.

### 3.6 emerge

- Source: `glato/emerge`
- Category: browser-based code structure, metrics, dependency, and complexity visualization.
- Evidence: README describes scanning projects, calculating metrics/statistics, generating interactive web apps, dependency graphs, filesystem graphs, and exports.
- Fit: good for human architecture/hotspot inspection.
- Caution: not an agent retrieval layer; language/parser coverage must be verified.
- Raindeer use: optional offline visualization artifact for architecture reviews.

### 3.7 GitDiagram

- Source: `gitdiagram.com` / GitDiagram project family.
- Category: quick interactive architecture diagram for public repos.
- Evidence: site says it turns any GitHub repository into an interactive diagram and supports replacing `hub` with `diagram` in GitHub URLs.
- Fit: useful for quick public-reference inspection.
- Caution: likely not suitable for private/local Raindeer unless self-hosted or privacy reviewed.
- Raindeer use: reference only; do not upload private code.

### 3.8 CodeCharta

- Source: `MaibornWolff/codecharta`
- Category: local metrics and 3D software map.
- Evidence: README describes local-only analysis/visualization, imports from Sonar/Tokei/Code Maat/Source Monitor/CSV, parsers for Git/SVN/source/raw text, and 3D city-like maps.
- Fit: strong for code health/hotspot visualization and change comparison.
- Caution: not primarily for symbol-level agent context.
- Raindeer use: optional quality dashboard for hotspots, file size, churn, complexity, and dead-zone detection.

### 3.9 CodeSee

- Source: `codesee.io`
- Category: hosted/team code visibility platform.
- Evidence: site positions itself for cross-repo/service dependency visibility, onboarding, refactoring, maps, flows, and AI-generated summaries.
- Fit: strong conceptually for product teams and onboarding.
- Caution: hosted/commercial; do not connect Raindeer unless the user explicitly approves account, code access, and data governance.
- Raindeer use: design reference only.

### 3.10 Sourcegraph

- Source: Sourcegraph docs / site.
- Category: enterprise code search, cross-repo navigation, structural search, batch changes, reference graph.
- Evidence: public docs describe code search across repositories/code hosts/languages and query filters; public project history identifies it as a major code search/reference graph platform.
- Fit: strong benchmark for search UX and query language, less direct as an embeddable AWI local tool.
- Caution: deployment, licensing, and repository access model must be separately audited; do not treat it as an open local dependency by default.
- Raindeer use: benchmark for search filters, saved contexts, cross-repo navigation, and "impact-aware" workflow design.

## 3.11 Name Ambiguity Notes

The user's "Nexus" likely maps to GitNexus or a "code graph nexus" family. The user's "CodeBace" is likely a spoken/typed variant of Codebase-Memory, codebase-map, or codebase intelligence. These names must remain caveated until a canonical URL is confirmed by user or stronger evidence.

Current document policy:

- `GitNexus` is indexed as `skimmed`, not adopted.
- `CodeBace` is not a source id; it is represented by the broader `codebase_intelligence` dedupe group.
- Any future install/pilot must identify exact repo, license, local storage behavior, ignore rules, and whether code leaves the machine.

## 4. Dedupe And Classification

| Dedupe group | Tools | Decision |
|---|---|---|
| `codebase_knowledge_graph_mcp` | GitNexus, CodeGraphContext, codebase-memory-mcp, codegraph, graph-codebase-mcp | Keep as primary research group for future local pilot. |
| `llm_repo_map` | codebase-map, PocketFlow tutorial generator, GitHub engineer codebase learning patterns | Implement an AWI-owned minimal map before adopting heavier dependencies. |
| `visual_architecture_map` | emerge, GitDiagram, CodeCharta, GitHub Next repo visualizer | Keep as optional human-facing artifacts, not hot-loop dependencies. |
| `hosted_code_visibility` | CodeSee, Sourcegraph and similar platforms | Reference only unless user approves external account/upload/deployment. |

## 5. Proposed Raindeer/AWI Integration Path

### Phase R0: AWI-owned repo map, no dependency

Create a generated cold-path artifact such as:

```text
harness/repo-map.json
harness/repo-map.md
```

Contents:

- directory tree summary with ignore rules;
- key Python packages and TS routes/components;
- entry points, jobs, API routers, DB schema, tests, UI routes;
- truth-source links for docs and harness files;
- import/dependency summary from lightweight local parsing;
- "owner surface": product code vs AWI harness vs generated artifacts;
- suggested context packs for common work types.

This phase can improve Codex search without installing third-party tools.

### Phase R1: Compare local graph tools in a sandbox

Evaluate 2-3 candidates in read-only mode:

- CodeGraphContext;
- codebase-memory-mcp / Codebase-Memory;
- GitNexus if local/client-side export is suitable.

Evaluation criteria:

- local-only/private-code safety;
- no secret indexing;
- ignore-file support;
- Python + TypeScript support;
- CLI/MCP availability;
- export format;
- incremental updates;
- deterministic query results;
- ability to answer callers/callees/blast-radius questions;
- integration cost with CodeX and AWI worker prompts.

### Phase R2: Source-index and Memory OS bridge

If a tool passes R1:

- add only source ids / paths / hashes to `harness/source-index.json`;
- store graph outputs under ignored or AWI-owned paths;
- teach Memory OS to retrieve structural summaries by slot, not hot-load raw graphs;
- require a no-secrets scan before indexing;
- record every generated map's mtime/hash and command.

### Phase R3: Worker and skill integration

Add one explicit skill/worker path only after R0/R1 evidence:

- `codebase-intel` or existing `codebase-intel` skill should become the route for repo-map queries;
- researcher/explorer/executor prompts can request a context pack by task type;
- verifier can use blast-radius output to choose test scope;
- code-reviewer can use dependency edges to check hidden consumers.

## 6. Immediate Recommendation

Do not install or connect any external code graph tool yet.

The safest first step is to build an AWI-owned minimal repo-map artifact for Raindeer, then use it as the baseline to compare GitNexus / CodeGraphContext / codebase-memory-mcp / codegraph. This gives immediate local benefit, keeps privacy intact, and prevents the project from becoming dependent on a tool we have not validated.

## 7. Open Questions

1. Should the first repo-map include source snippets, or only paths/symbol names/import edges?
2. Should generated map files be committed, or generated locally and ignored?
3. Should graph indexing exclude `tmp/`, `.env*`, DB dumps, generated reports, screenshots, and node_modules by default? Recommended: yes.
4. Is the goal primarily for the orchestrator/worker context packs, or also a human visual dashboard?
5. Should we evaluate MCP setup inside CodeX later, or keep the first pilot CLI-only?

## 8. Evidence Links

- GitNexus: https://github.com/abhigyanpatwari/GitNexus
- CodeGraphContext: https://github.com/CodeGraphContext/CodeGraphContext
- codebase-memory-mcp: https://github.com/DeusData/codebase-memory-mcp
- Codebase-Memory paper: https://arxiv.org/html/2603.27277v1
- codegraph: https://github.com/colbymchenry/codegraph
- codebase-map: https://github.com/carlrannaberg/codebase-map
- emerge: https://github.com/glato/emerge
- GitDiagram: https://gitdiagram.com/
- CodeCharta: https://github.com/maibornwolff/codecharta
- CodeSee: https://www.codesee.io/
- Sourcegraph code search docs: https://sourcegraph.com/docs/code-search
