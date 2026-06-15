# AWI — Raindeer Fusion

> **Default branch: `main`** — AWI enhanced with Raindeer task tree governance, flow mode, absolute traceability, runtime OS, and sandbox adaptation.

> A production-grade AI engineering workspace infrastructure for large-scale, long-term projects. Integrates 21+ open-source project methodologies into a unified foundation — one command to bootstrap, instantly ready for development.

---

## Raindeer-AWI Additions (on `main`)

This branch adds Raindeer-specific methodology on top of AWI:

| Addition | File | Problem Solved |
|----------|------|---------------|
| **Task Tree System** | `docs/TASK_TREES.md` | Prevents dirty workspace chaos — any idea must be registered in a TREE before implementation |
| **Flow Mode** | `docs/FLOW-MODE.md` | Eliminates "agent stops, user doesn't push, context is lost" dead loop — continuous automatic advancement |
| **Absolute Traceability** | `docs/PROJECT_STATUS.md` §5 | Turns "is it done?" from verbal claims into auditable file evidence |
| **Continuation Prompt** | `docs/CONTINUATION_PROMPT.md` | Cross-session recovery via fixed handoff copy, not memory |
| **Sandbox Adapter** | `harness/sandbox.ps1` | IDE restricted-write environments — isolated cache within project |
| **Security Zone Upgrade** | `SECURITY-ZONES.md` | Zone 0-4 five-level concentric model + data classification flow rules |
| **Dirty Worktree Ledger** | `docs/ENGINEERING/DIRTY_WORKTREE_CLEANUP_LEDGER.md` | Explicit multi-worktree background process management |
| **High-Risk Change Template** | `docs/ENGINEERING/HARNESS_CHANGE_TEMPLATE.md` | Mandatory invariants, failure modes, rollback path for risky changes |
| **Review Checklist** | `docs/ENGINEERING/HARNESS_REVIEW_CHECKLIST.md` | Structured review questions for engineering quality |
| **Runtime OS** | `harness/compliance-check.ps1`, `harness/adapters/`, `harness/mailbox/` | orchestrator-Only 团队 + 跨平台 PAL + Compliance Kernel |
| **Usage Guide** | `docs/USAGE.md` | 一条命令导入 + 日常使用说明 |

---

## What is this?

A complete operational foundation for AI coding agents. It provides agents with engineering contracts, state management, verification loops, and a skill ecosystem — so you focus entirely on your business logic while the infrastructure handles everything else.

After importing, just tell the AI agent what you want to build, and it automatically performs context recovery, task planning, execution, and verification — **your energy stays on the product, the infrastructure is already in place**.

---

## Quick Start

> 完整使用说明见 **[docs/USAGE.md](docs/USAGE.md)**

### 一条命令导入（新项目）

```powershell
git clone https://github.com/ninedeerhing/agent-workspace-infrastructure.git my-project; cd my-project; .\bootstrap.ps1 -TargetPath . -ProjectName my-project -Mode full -ProvisionTeam -Platform auto
```

### 一条命令导入（已有项目）

将 `D:\your-project` 换成你的项目路径：

```powershell
git clone https://github.com/ninedeerhing/agent-workspace-infrastructure.git _awi; .\_awi\bootstrap.ps1 -TargetPath "D:\your-project" -SourcePath .\_awi -ProjectName YourApp -Mode full -ProvisionTeam -Platform auto -Force
```

### 已 clone 本仓库，在当前目录配置

```powershell
.\bootstrap.ps1 -TargetPath . -ProjectName MyProject -Mode full -ProvisionTeam -Platform auto
```

### 导入后

1. 阅读 **`docs/SESSION_SETUP.md`**（bootstrap 自动生成）
2. **只日常打开 orchestrator 会话**，首条消息粘贴 `harness/templates/orchestrator-init-prompt.md`
3. 验证：`.\harness\compliance-check.ps1 -Mode post-bootstrap`（期望 findings=0）

### 对 orchestrator 说

```
加载工作区，告诉我当前项目状态和主线任务
```

Agent 会自动执行上下文预加载（`docs/SESSION_BOOT.md` → `AGENTS-lite.md` → `workflow-state.json` → …），然后汇报状态并开始工作。

---

### Importing into an Existing Project (mid-development)

Already have a codebase? AWI supports incremental adoption. First, run a compatibility audit:

```bash
.\bootstrap.ps1 -TargetPath "D:\my-existing-project" -ProjectName "MyApp" -Mode audit
```

This produces a report showing which files are compatible, which are safe to add, and which would conflict — **without modifying anything**. Based on the score, choose one of three modes:

| Mode | Command | What it does |
|------|---------|--------------|
| **audit** | `-Mode audit` | Read-only scan + compatibility score + recommendations |
| **minimum** | `-Mode minimum` | Adds `harness/` + `.omx/` + core contracts *only*. **Never overwrites** any existing file. Your code stays untouched. |
| **full** | `-Mode full -Force` | Deploys everything (agents, skills, docs, rules, design).

**Default behavior:** when no `-Mode` is specified, AWI auto-detects — empty directory → `full`, existing project → `minimum`. This means you will never accidentally overwrite your project.

**What minimum mode adds to an existing project:**
```
your-project/
├── (existing code — untouched)
├── CONSTITUTION.md      # Non-negotiable engineering rules
├── AGENTS.md            # Agent instruction contract
├── SECURITY-ZONES.md    # Runtime security boundaries
├── harness/             # State management + verification
├── .omx/                # Persistent memory + semantic search
└── bootstrap.ps1        # Reusable for updates
```

The agent can then participate in your ongoing development — it reads your existing code, learns its structure, and starts helping with planning, implementation, and review using AWI's governance layer.

> Full import flow diagram: see [IMPORT-FLOW.txt](IMPORT-FLOW.txt)

---

## Architecture Overview

```
my-project/
├── CONSTITUTION.md           # Constitutional system prompt — non-negotiable rules, highest priority
├── AGENTS.md                 # Agent instruction entry — 16 principles + 46 skill routes + 5 agent layers
├── AGENTS-lite.md            # Lightweight execution layer version (~40 lines)
├── SOUL.md                   # Core identity & cross-tool portability
├── RULES.md                  # Rule contract — must-do / must-not-do lists
├── SECURITY.md               # Security policy — key management + injection defense
├── SECURITY-ZONES.md         # Runtime security zones — 🟢🟡🔴 three-tier boundaries
├── bootstrap.ps1             # One-command bootstrap (new + existing projects)
├── README.md                 # This file
│
├── agents/                   # 5 layers, 18 specialized agent roles
│   ├── orchestrator.md       #   Planning layer: workflow selection + task decomposition + final acceptance
│   ├── planner.md            #                requirement breakdown + task ordering + milestone planning
│   ├── architect.md          #                system boundaries + tech tradeoffs + ADR records
│   ├── critic.md             #                adversarial challenge, blind spot prevention
│   ├── executor.md           #   Execution layer: bounded implementation & refactoring
│   ├── explore.md            #                rapid codebase exploration (merged explorer)
│   ├── debugger.md           #                root cause analysis + reproduction + regression isolation
│   ├── code-reviewer.md      #   Quality layer: logic flaws + performance + style (absorbed code-simplifier)
│   ├── security-reviewer.md  #                secret detection + injection defense + supply chain audit
│   ├── test-engineer.md      #                TDD + coverage + stability
│   ├── verifier.md           #                completion evidence + acceptance + risk report
│   ├── designer.md           #   Product layer: UI/UX + design system + usability
│   ├── qa-tester.md          #                browser/CLI manual verification
│   ├── writer.md             #                documentation (absorbed document-specialist)
│   └── growth-engineer.md    #   Growth layer: capability accumulation + curation + metrics
│
├── skills/                   # 46 reusable workflow skills
│   ├── deep-interview/       #   OMX core: Socratic deep interview
│   ├── ralplan/              #            three-role consensus planning
│   ├── ultragoal/            #            multi-goal persistent tracking
│   ├── prometheus-strict/    #            raft-mode rigorous planning
│   ├── best-practice-research/  # Research: official evidence pre-planning research
│   ├── autoresearch/         #          bounded validator-gated research
│   ├── autoresearch-goal/    #          goal-mode continuous research
│   ├── github-research/      #          three-mode GitHub research (exact/fuzzy/Trending)
│   ├── brainstorming/        #   TDD flow: explore requirements before coding
│   ├── writing-plans/        #          decompose design into incremental plans
│   ├── test-driven-development/  #   Red→Green→Refactor
│   ├── subagent-driven-dev/  #   parallel subagent dispatch
│   ├── executing-plans/      #   serial execution without subagent environment
│   ├── team-pipeline/        #   5-stage team pipeline
│   ├── omc-conversation-continuity/  # Session continuity: handoff prompt + recovery
│   ├── omo-agent-router/     #   auto task classification routing (4-dimension matrix)
│   ├── omo-health-monitor/   #   health monitoring: heartbeat + degradation + self-healing
│   ├── session-retro/        #   auto retrospective + pattern extraction
│   ├── skillify/             #   experience → reusable skill
│   ├── capability-accumulation/  # Six-layer capability accumulation framework
│   ├── caveman-token-compress/  # Token optimization suite
│   ├── security-review/      #   + security audit
│   ├── code-review/          #   + engineering review
│   ├── frontend-design/      #   + frontend design
│   ├── git-publish/          #   auto commit + conventional commits + push
│   └── ...                   #   more skills in skills/ directory
│
├── harness/                  # State management hub
│   ├── init.ps1              #   34-item automated verification script
│   ├── feature_list.json     #   Feature module tracking (id/status/evidence/dependencies)
│   ├── progress.md           #   Human-readable progress log
│   ├── session-handoff.md    #   Session handoff template (with startup sequence)
│   ├── workflow-state.json   #   4 workflow state machines
│   ├── workflow-gates.md     #   28 stage quality gates
│   ├── grader-types.md       #   5 grader types + 25 check items + pass@k
│   ├── schedule.json         #   Recurring task definitions (Loop Engineering automations)
│   ├── schedule.ps1          #   Cron-based task dispatcher
│   ├── clean-state-checklist.md  # Session start/end/feature-complete three-tier checklists
│   ├── ci-cd-template.yml    #   GitHub Actions 6-stage pipeline
│   ├── audit.ps1             #   Compatibility audit for existing projects
│   └── archive/              #   Archive engine (8 operations + safe restore)
│
├── .omx/                     # OMX compatibility layer
│   ├── memory.md             #   Layered persistent memory (PROJECT/SESSION/AGENT/TURN)
│   ├── memory-index.md       #   Semantic search specification (3-stage pipeline)
│   ├── memory-search.ps1     #   Semantic search script (1055-line full implementation)
│   └── plans/                #   Workflow templates (standard/research/goal)
│
├── docs/                     # Documentation & decisions
│   ├── adr/                  #   Architecture Decision Records (ADR-001~006)
│   ├── scaling-guide.md      #   Large project scaling guide
│   ├── project-init-checklist.md   # Project launch 36-item checklist
│   ├── context-preload.md    #   New session auto-load sequence
│   ├── personal-growth-framework.md  # Six-dimension personal growth framework
│   ├── frontend-architecture.md      # Frontend design infrastructure
│   ├── personal-ai-infra-assessment.md
│   ├── task-queue.md         #   Task scheduling queue specification
│   └── inter-agent-comm.md   #   Inter-agent communication protocol
│
├── rules/common/             # 7 coding standards
│   ├── patterns.md           #   Architecture patterns
│   ├── coding-style.md       #   Code style
│   ├── testing.md            #   Testing standards
│   ├── security.md           #   Security rules
│   ├── agents.md             #   Agent rules
│   ├── database.md           #   Database standards
│   └── api-design.md         #   API design standards
│
├── cache/                    # 5 Token optimization strategies
│   ├── caveman-prompt.md     #   Extreme compression protocol
│   ├── rtk-strategy.md       #   Reasoning-Token-Knowledge three-stage
│   ├── headroom-strategy.md  #   Context compression + layered memory
│   ├── reasonix-cache.md     #   Prefix-Cache stability
│   └── token-budget.md       #   Four-layer Token budget architecture
│
└── design-architecture/      # Frontend design six-layer architecture (TypeScript, zero errors)
    ├── DESIGN.md             #   Design token single source of truth
    ├── src/core/theme-engine.ts    # L1 Theme engine
    ├── src/design/tokens.ts        # L2 Programmatic tokens
    ├── src/animation/engine.ts     # L4 Animation engine
    ├── src/design/skills/          # L5 AI intelligence layer (anti-patterns + design commands)
    └── src/copilot/copilot-layer.ts  # L6 Copilot collaboration layer
```

> **Note:** `.trae/` directory (Trae IDE-specific skill and agent registrations) is excluded from the repository. Users can generate it by running `bootstrap.ps1` or manually syncing from `skills/` and `agents/`.

---

## Core Capabilities

### 🏗️ Engineering Foundation — Harness Engineering Five Subsystems

| Subsystem | Key Files | Function |
|-----------|-----------|----------|
| **Instructions** | CONSTITUTION.md + AGENTS.md + SOUL.md + RULES.md + SECURITY.md | 7-layer document priority chain, 16 operational principles |
| **State** | feature_list.json + progress.md + session-handoff.md + workflow-state.json | Feature tracking + progress logging + session handoff + state machine |
| **Verification** | workflow-gates.md + grader-types.md + clean-state-checklist.md + init.ps1 | 28 gates + 5 grader types + 3-tier checklists + 34 auto-checks |
| **Scope** | SECURITY-ZONES.md + project-init-checklist.md + scaling-guide.md | 🟢🟡🔴 security boundaries + project launch governance + scaling decisions |
| **Lifecycle** | archive/store.ps1 + bootstrap.ps1 + context-preload.md | Archive engine + one-command init + context recovery |

### 🔄 OMX Standard Workflows

```
Default path:    deep-interview → ralplan → ultragoal
Strict mode:     prometheus-strict (Interview→Critique→Synthesize, enforced gates each step)
Research boundary: best-practice-research → autoresearch → autoresearch-goal
```

### ✅ Verification Loop

```
5 grader types × 25 check items:
  G-CORRECT   — logical correctness + boundary conditions + error paths + idempotency + concurrency safety
  G-COMPLETE  — requirement coverage + file completeness + test coverage + doc sync + dependency declaration
  G-STYLE     — naming conventions + function length + file length + nesting depth + dead code
  G-SECURE    — secret detection + input validation + injection defense + auth/authz + error non-leakage
  G-PERF      — N+1 detection + sync blocking + memory leaks + bundle size bloat

pass@k quality targets: pass@1(G-SECURE) ≥ 100%, pass@1(G-CORRECT) ≥ 95%
```

### 🧠 Long-Term Memory System

```
.omx/memory.md         — 4-layer scoping (PROJECT/SESSION/AGENT/TURN) + 7 memory categories
memory-index.md        — 3-stage semantic search specification
memory-search.ps1      — 1055-line full implementation (exact+fuzzy+alias+tag+Levenshtein+9-factor scoring)
archive/store.ps1      — 8-operation complete archive engine
session-handoff.md     — structured session handoff + 7-step startup sequence
```

### 🔒 Runtime Security

```
CONSTITUTION.md        — Constitutional system prompt (non-negotiable rules, highest priority)
SECURITY-ZONES.md      — 🟢Free / 🟡Protected / 🔴Restricted three-tier runtime boundaries
Prompt Defense (6 rules) — user instruction priority + external content isolation + system prompt non-leakage
Secret auditing        — init.ps1 automatic hardcoded secret detection
```

### 🌱 Closed-Loop Learning

```
session-retro          →  auto retrospective + pattern extraction
skillify               →  experience → reusable skill
capability-accumulation  →  six-layer capability growth framework
growth-engineer        →  7-day curation cycle + capability metrics
```

### 🔁 Loop Engineering — Agentic Automations

AWI implements all five building blocks of the Loop Engineering methodology (June 2026):

```
Automations  →  harness/schedule.json + schedule.ps1 (cron-based recurring dispatch)
Worktrees    →  $using-git-worktrees + subagent-driven-dev (isolated parallel agents)
Skills       →  46 skills with SKILL.md (stop re-explaining your project)
Sub-Agents   →  18-agent 5-layer hierarchy (maker/checker separation)
Verification →  28 quality gates + 5 grader types + pass@k + TDD loop
```

Schedule engine (`harness/schedule.ps1`) reads task definitions from `harness/schedule.json`, determines which tasks are due via cron matching, and outputs them for the agent to execute. Four default tasks: daily health check, weekly curator cycle, post-session retro, weekly progress summary.

---

## Workflow Selection Guide

| Scenario | Workflow | Skill Chain |
|----------|----------|-------------|
| Simple bug fix (1-2 files) | Direct execution | executor |
| Feature development (3-5 files) | **default** | brainstorming→tdd→code-review→verify |
| Architecture change (5-10 files) | **complex** | deep-interview→ralplan→team-execution→security-review |
| Product from scratch (0→1) | **product** | office-hours→ceo-review→eng-review→design-review→build→qa→ship |
| Multi-goal long-term project | **omx-standard** | deep-interview→ralplan→ultragoal |
| Security-sensitive feature | **complex + prometheus-strict** | Interview→Critique→Synthesize with enforced gates |

---

## Agent Hierarchy (5 Layers, 18 Roles)

| Layer | Roles | Responsibilities |
|-------|-------|------------------|
| **Planning** | orchestrator · planner · architect · critic | Workflow selection, task decomposition, ADR records, adversarial challenge |
| **Execution** | executor · explore · debugger · researcher | Bounded implementation, code exploration, root cause analysis, evidence collection |
| **Quality** | code-reviewer · security-reviewer · test-engineer · verifier | Logic review, security audit, TDD design, completion verification |
| **Product** | designer · qa-tester · writer | UI/UX design, manual verification, documentation |
| **Growth** | growth-engineer | Capability accumulation, 7-day curation, growth metrics |

---

## Skill Routes (46 skills, called by scenario)

| Scenario | Recommended Skill Chain |
|----------|------------------------|
| Start new project | `$deepinit` → generate full AGENTS.md instruction system |
| Explore requirements | `$brainstorming` → `$deep-interview` → `$ralplan` |
| External research | `$github-research` (3 modes) → `$best-practice-research` |
| Technical investigation | `$autoresearch` (bounded validator-gated) → `$autoresearch-goal` (goal mode) |
| Write code | `$test-driven-development` → `$karpathy-guidelines` |
| Parallel development | `$using-git-worktrees` → `$subagent-driven-dev` |
| Code review | `$requesting-code-review` · `$receiving-code-review` · `$code-review` |
| Security audit | `$security-review` (mandatory before commit) |
| Release | `$release-omc` (auto release + tag) |
| Session switch | `$omc-conversation-continuity` (handoff prompt generation) |
| Health check | `$omo-health-monitor` (heartbeat + degradation + self-healing) |
| Continuous improvement | `$ralph-loop` → `$session-retro` → `$capability-accumulation` |
| Multi-goal management | `$ultragoal` (persistent goal tracking) |
| Token optimization | `$token-budget` → `$caveman-token-compress` · `$rtk-strategy` · `$headroom-strategy` |
| Frontend development | `$frontend-design` · `$web-dev` → `$webapp-testing` |
| Rigorous planning | `$prometheus-strict` (Interview→Critique→Synthesize raft mode) |
| Publish to GitHub | `$git-publish` (auto commit + conventional commits + push) |

---

## Reference Projects (21)

### Core Engineering Frameworks

| Project | What We Absorbed |
|---------|-----------------|
| **learn-harness-engineering** | Five-subsystem architecture (Instructions/State/Verification/Scope/Lifecycle), Harness directory specification, clean-state checklists |
| **superpowers** | TDD enforced workflow (Red→Green→Refactor→PR→Code Review), subagent development protocol (max 6 parallel), Git Worktree |
| **gstack** | YC Office Hours 6-question pattern, CEO/Eng/Design three-perspective expert review chain, product/startup workflow |
| **ECC** | Six-dimension quality assessment framework, 5 grader type designs, layered security system (Prompt Defense + secret auditing + multi-language rule library) |
| **andrej-karpathy-skills** | 7 anti-overengineering rules, evidence-driven principle, context-awareness (avoid last 20% window for large tasks) |

### Token Optimization

| Project | What We Absorbed |
|---------|-----------------|
| **caveman** | Extreme compression protocol, 4-level compression strategy (L0→L1→L2→L3) |
| **rtk** | Reasoning-Token-Knowledge three-stage framework, layered context injection, per-layer Token budget hard constraints |
| **headroom** | Context compression strategy, layered scoped memory (PROJECT/SESSION/AGENT/TURN), memory bubbling |
| **reasonix** | Prefix-Cache stability strategy, DeepSeek model switching, API cost optimization |

### OMX System

| Project | What We Absorbed |
|---------|-----------------|
| **oh-my-codex** | Standard workflow path (deep-interview→ralplan→ultragoal), research boundary tripartition, prometheus-strict raft mode, .omx/ persistent state directory, bounded validator-gated research |
| **oh-my-openagent** | Background agent loop, health monitoring system (heartbeat+degradation+self-healing), auto task classification routing (4-dimension matrix), inter-agent shared memory communication |

### Memory & Persistence

| Project | What We Absorbed |
|---------|-----------------|
| **mempalace** | Memory palace metaphor, layered storage (core+extended+archive), 3-stage semantic search pipeline, 8-factor weighted scoring engine → memory-search.ps1 (1055-line implementation) |
| **everos** | Persistent Agent OS, four-tier task queue, complete Agent lifecycle management, shared memory communication model |
| **hermes-agents** (23k+ ⭐) | Closed-loop learning flywheel → capability-accumulation six-layer framework, dual memory architecture (MEMORY.md+FTS5) → .omx/memory.md + memory-index, Curator 7-day curation cycle, progressive disclosure, self-nudge mechanism |

### Personal Infrastructure

| Project | What We Absorbed |
|---------|-----------------|
| **personal_AI_infrastructure** | Constitutional system prompt → CONSTITUTION.md, runtime security zones (Containment Zones) → SECURITY-ZONES.md, document priority chain, context preload pipeline → context-preload.md |

### Frontend Design

| Project | What We Absorbed |
|---------|-----------------|
| **open-design** | Design token system (55+ fields), component atomic design (Atom→Molecule→Organism→Template) → DESIGN.md |
| **copilotKit** | AI agent UI development role separation (generator/reviewer/refactorer), Agent Runtime + Generative UI + Shared State → copilot-layer.ts |
| **taste-skill** | Design taste evaluation (visual+interaction+responsive), 12 anti-patterns with programmable detection → anti-patterns.ts |
| **awesome-design-md** | Markdown-driven design (DESIGN.md as single source of truth), PRD→Wireframe→Component workflow |
| **anime** | Animation engine wrapper (Anime.js+CSS fallback), 60fps performance constraint, ENTRANCE/HOVER/PAGE presets → engine.ts |
| **impeccable** | Perfect delivery standards (LCP<2.5s, FID<100ms, CLS<0.1), WCAG 2.1 AA accessibility, 23 design commands → design-commands.ts |

---

## FAQ

**Q: How is this different from just using Cursor/Copilot?**

A: Cursor/Copilot provide code-completion-level assistance. This framework provides a complete engineering methodology — task state management, quality gates, verification loops, session handoff, long-term memory, security auditing, and more. It doesn't replace AI coding tools; it makes them run in an engineering-grade environment.

**Q: Is this suitable for solo projects?**

A: Absolutely. The core philosophy is "solo developer + AI agents = virtual team." Even alone, 18 agent roles assist you at different stages — planner+architect during planning, executor during implementation, code-reviewer+security-reviewer during review.

**Q: What are the prerequisites?**

A: Node.js 22+, Git, PowerShell 5.1+, any AI coding tool (Trae / Claude Code / Codex CLI / Cursor).

**Q: Can I use AWI with an existing project that's already in development?**

A: Yes. Run `.\bootstrap.ps1 -Mode audit` first to get a compatibility report without modifying anything. Then `.\bootstrap.ps1 -Mode minimum` to add only the governance layer (harness/ + .omx/ + core contracts). Your existing code and config files are never touched in minimum mode.

**Q: How do I update the framework?**

A: `git pull` to get the latest version, then run `.\bootstrap.ps1` to sync. Your project files will not be overwritten.

**Q: Is it safe to run the `.ps1` scripts?**

A: Yes, fully. All scripts are open-source and operate **exclusively within the project directory**. They never touch system settings, never make network calls, and never require administrator privileges. You can (and should) read every line before running — they're pure file operations and read-only checks.

> If PowerShell's execution policy blocks them, run with `-ExecutionPolicy Bypass` or set `Set-ExecutionPolicy RemoteSigned` once.
> Non-Windows users: install `pwsh` (PowerShell Core) to use the scripts, or run the equivalent operations manually.

---

## License

MIT © 2026
