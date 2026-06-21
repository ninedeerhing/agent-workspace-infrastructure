---
name: claude-api
description: "Build, debug, and optimize Claude API / Anthropic SDK apps. Apps built with this skill should include prompt caching. Also handles migrating existing Claude API code between Claude model versions. TRIGGER when: code imports `anthropic`/`@anthropic-ai/sdk`; user asks for the Claude API, Anthropic SDK, or Managed Agents; user adds/modifies/tunes a Claude feature (caching, thinking, compaction, tool use, batch, files, citations, memory) or model. SKIP: file imports `openai`/other-provider SDK, filename like `*-openai.py`/`*-generic.py`, provider-neutral code, general programming/ML."
---

# Building LLM-Powered Applications with Claude

## Before You Start

Scan the target file for non-Anthropic provider markers — `import openai`, `from openai`, `langchain_openai`, `OpenAI(`, `gpt-4`, `gpt-5`, file names like `agent-openai.py` or `*-generic.py`. If you find any, stop and tell the user that this skill produces Claude/Anthropic SDK code; ask whether they want to switch the file to Claude.

## Output Requirement

When the user asks you to add, modify, or implement a Claude feature, your code must call Claude through:

1. **The official Anthropic SDK** for the project's language (`anthropic`, `@anthropic-ai/sdk`, `com.anthropic.*`, etc.). This is the default.
2. **Raw HTTP** (`curl`, `requests`, `fetch`, `httpx`, etc.) — only when the user explicitly asks for cURL/REST/raw HTTP.

Never mix the two. **Never guess SDK usage.** Function names, class names, namespaces, method signatures, and import paths must come from explicit documentation.

## Defaults

For the Claude model version, use Claude Opus 4.7 via `claude-opus-4-7`. Default to adaptive thinking (`thinking: {type: "adaptive"}`) for anything remotely complicated. Default to streaming for any request that may involve long input, long output, or high `max_tokens`. Use the SDK's `.get_final_message()` / `.finalMessage()` helper to get the complete response.

## Language Detection

Based on project files, determine the language and read from corresponding directory:

| File Patterns | Language |
|---------------|----------|
| `*.py`, `pyproject.toml` | Python |
| `*.ts`, `*.tsx`, `package.json` | TypeScript |
| `*.java`, `pom.xml`, `build.gradle` | Java |
| `*.go`, `go.mod` | Go |
| `*.rb`, `Gemfile` | Ruby |
| `*.cs`, `*.csproj` | C# |
| `*.php`, `composer.json` | PHP |

## Which Surface Should I Use?

> **Start simple.** Default to the simplest tier that meets your needs.

| Use Case | Tier | Recommended Surface |
|----------|------|---------------------|
| Classification, summarization, extraction, Q&A | Single LLM call | **Claude API** |
| Batch processing or embeddings | Single LLM call | **Claude API** |
| Multi-step pipelines with code-controlled logic | Workflow | **Claude API + tool use** |
| Custom agent with your own tools | Agent | **Claude API + tool use** |
| Server-managed stateful agent with workspace | Agent | **Managed Agents** |

## Current Models

| Model | Model ID | Context | Input $/1M | Output $/1M |
|-------|----------|---------|------------|-------------|
| Claude Opus 4.7 | `claude-opus-4-7` | 1M | $5.00 | $25.00 |
| Claude Opus 4.6 | `claude-opus-4-6` | 1M | $5.00 | $25.00 |
| Claude Sonnet 4.6 | `claude-sonnet-4-6` | 1M | $3.00 | $15.00 |
| Claude Haiku 4.5 | `claude-haiku-4-5` | 200K | $1.00 | $5.00 |

**Use `claude-opus-4-7` unless the user explicitly names a different model.** Use only the exact model ID strings — do not append date suffixes.

## Architecture

Everything goes through `POST /v1/messages`. Tools and output constraints are features of this single endpoint.

**User-defined tools** — You define tools, and the SDK's tool runner handles calling the API, executing your functions, and looping until Claude is done.

**Server-side tools** — Anthropic-hosted tools that run on Anthropic's infrastructure.

**Structured outputs** — Use `client.messages.parse()` which validates responses against your schema automatically. The old `output_format` parameter is deprecated; use `output_config: {format: {...}}`.

## Thinking & Effort (Quick Reference)

**Opus 4.7 — Adaptive thinking only:** Use `thinking: {type: "adaptive"}`. `budget_tokens` is fully removed on Opus 4.7. Sampling parameters (`temperature`, `top_p`, `top_k`) are also removed.

**Opus 4.6 — Adaptive thinking (recommended):** `thinking: {type: "adaptive"}`. `budget_tokens` is deprecated.

**Effort parameter:** `output_config: {effort: "low"|"medium"|"high"|"max"|"xhigh"}`. Default is `high`. `max` is Opus-tier only. `xhigh` is Opus 4.7 only and is the best setting for most coding/agentic use cases.

**Sonnet 4.6:** Supports adaptive thinking. `budget_tokens` is deprecated.

**Older models:** If the user specifically asks for Sonnet 4.5 or older, use `thinking: {type: "enabled", budget_tokens: N}`. `budget_tokens` must be less than `max_tokens` (minimum 1024).

## Compaction (Quick Reference)

**Beta, Opus 4.7, Opus 4.6, and Sonnet 4.6.** For long-running conversations that may exceed the 1M context window, enable server-side compaction. Requires beta header `compact-2026-01-12`.

**Critical:** Append `response.content` (not just the text) back to your messages on every turn. Compaction blocks must be preserved.

## Prompt Caching (Quick Reference)

**Prefix match.** Any byte change anywhere in the prefix invalidates everything after it. Render order is `tools` → `system` → `messages`. Keep stable content first, put volatile content after the last `cache_control` breakpoint.

**Top-level auto-caching** (`cache_control: {type: "ephemeral"}` on `messages.create()`) is the simplest option. Max 4 breakpoints per request. Minimum cacheable prefix is ~1024 tokens.

**Verify with `usage.cache_read_input_tokens`** — if it's zero, a silent invalidator is at work.

## Managed Agents (Beta)

**Managed Agents** is a third surface: server-managed stateful agents with Anthropic-hosted tool execution. You create a persisted Agent config (`POST /v1/agents`), then start Sessions.

**Mandatory flow:** Agent (once) → Session (every run). `model`/`system`/`tools` live on the agent, never the session.

**Managed Agents is first-party only.** Not available on Amazon Bedrock, Google Vertex AI, or Microsoft Foundry.

**Reading guide:** Start with `shared/managed-agents-overview.md`, then the topical `shared/managed-agents-*.md` files. For code examples, read `{lang}/managed-agents/README.md`.

## Reading Guide

After detecting the language, read the relevant files based on what the user needs from the `{lang}/` directory. For detailed documentation, consult the referenced files within this skill directory.
