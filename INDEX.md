# Coderules Index

> **Looking for install instructions?** See [`README.md`](./README.md). This file documents the **structure and migration history** of the rule pack.

This repository's rule files are organized in a **four-layer structure** (`common/` + `lang/` + `patterns/` + `examples/`). Each rule belongs to exactly one layer; cross-references go through relative paths.

```
coderules/
├── INDEX.md                ← you are reading this
├── common/                 ← language-agnostic principles (always-on tier capped at ≤7)
├── lang/                   ← language-specific syntax, glob-triggered
├── patterns/               ← architectural patterns (project-agnostic), desc/glob-triggered
├── examples/               ← reference templates, NOT loaded (.md, not .mdc)
│   └── project-binding/    ← binding templates (.md), copy + fill `<...>` placeholders
└── aicoding/            ← agent skill (top-level caller, not a rule)
    ├── SKILL.md
    ├── README.md
    └── references/
```

> **No `project/` layer in this repo.** Project-specific bindings (paths, env vars, API URLs) belong in your repo's own `.cursor/rules/project/`. See `examples/project-binding/` for templates.

---

## Layer Responsibilities

| Layer | Responsibility | alwaysApply | Scope |
|---|---|---|---|
| **common/** | Language-agnostic principles, decision hygiene, gates, cross-language conventions | mixed (6 always-on / 4 triggered) | Always-on tier injected every prompt |
| **lang/** | Per-language syntax, formatter, test framework | ✗ (globs) | Only when editing the corresponding language file |
| **patterns/** | Architectural patterns (multi-worktree, multi-agent, plugin, IM bot, memory MCP, persona, database) — project-agnostic | ✗ (desc/globs) | Only when the project has the corresponding feature |
| **examples/** | Reference templates (`.md`, not `.mdc`) — Cursor never loads them | n/a (not loaded) | Documentation only |

---

## Context Budget (always-on tier)

To prevent rule-set bloat from diluting agent attention, keep the **always-on tier ≤ 6 files / ~7K tokens** within `coderules/`. Everything else loads on demand via `globs` or `description` triggers. (A consuming project may add ≤ 1 always-on `project/` trunk for its own layout / runtime conventions, capped at total ≤ 7.)

### Always-on (6 files, ~7K tokens)

| File | Why always-on |
|---|---|
| `common/clean-code-core.mdc` | Naming / sizing / nesting limits — fires on every code change |
| `common/architecture.mdc` | Interface single definition, wiring — fires on every cross-module change |
| `common/decision-hygiene.mdc` | Claim decomposition / anchors — needed up-front to prevent reasoning drift |
| `common/error-handling.mdc` | Error discipline — every code change touches control flow |
| `common/quality-gates.mdc` | "Are you done?" gate — fires after every change |
| `common/security-guide.mdc` | Security cannot be opt-in; cost of missing is too high |

### Triggered (loaded only when needed)

| File | Trigger |
|---|---|
| `common/comments-docs.mdc` | desc — when writing/reviewing doc comments / TODO / Deprecation markers |
| `common/imports.mdc` | desc — when adding / reorganizing imports or barrel files |
| `common/refactoring-guidelines.mdc` | desc — when refactoring / splitting a large file / tightening types |
| `common/testing-principles.mdc` | globs — `**/test/**`, `**/*.test.*`, `**/*.spec.*` |
| `lang/*.mdc` | globs per language |
| `patterns/multi-worktree.mdc` | desc — multi-worktree / parallel session / continue-port-implement on multi-branch repo |
| `patterns/multi-agent.mdc` | desc — running multiple agents / sessions / `best-of-n` against the same repo |
| `patterns/plugin-architecture.mdc` | globs — `extensions/`, `plugins/`, `addons/` |
| `patterns/im-bot-integration.mdc` | globs — `bridge/`, `bot/`, `im/`, `channels/` |
| `patterns/memory-mcp-discipline.mdc` | desc — when memory-MCP available + substantive task |
| `patterns/persona-architecture.mdc` | globs — `persona/`, `style/`, `mention/` |
| `patterns/database-patterns.mdc` | desc — SQL/NoSQL schema, indexing, transactions, ORM N+1 audit |

### Why this matters

Every `alwaysApply: true` file pays its full token cost on **every prompt**, plus dilutes the model's attention away from the actual task (needle-in-haystack effect). Rule of thumb:

- ≤ 7 always-on files: focus stays on user task
- > 10 always-on files: agent starts citing rules over solving problems
- > 15 always-on files: cost noticeable; instruction-following degrades

When adding a new rule, default to `alwaysApply: false` and prove a triggering need before promoting.

---

## common/ (10 files)

| File | Responsibility |
|---|---|
| `clean-code-core.mdc` | KISS / YAGNI / SRP / DRY; 500/120/3 limits; naming / comment red lines |
| `architecture.mdc` | Single interface definition, barrel / wiring completeness, single cross-process glue |
| `decision-hygiene.mdc` | **Exclusive**: claim decomposition / evidence anchors / explicit retraction / temporal layering / commitment boundary |
| `error-handling.mdc` | Universal error discipline (no swallowed errors, validate at boundaries, no escape hatches across public APIs) |
| `refactoring-guidelines.mdc` | barrel + delegation split, gradual `any` tightening, large-file prevention, common refactor moves (extract service / replace conditional with strategy) |
| `quality-gates.mdc` | Completion Standard + Post-Change Review & E2E Gate + Git Hooks |
| `comments-docs.mdc` | Public-API doc / TODO / Deprecation / Stability markers (per Google Style) |
| `imports.mdc` | Three-segment grouping, alphabetical, anti-patterns (per Google Style) |
| `security-guide.mdc` | Credentials, log redaction, input trust boundary, injection defense, web operational hardening + framework entry-point cheat sheet |
| `testing-principles.mdc` | Pyramid, AAA, naming, mock boundaries, coverage philosophy |

---

## lang/ (6 files)

| File | globs | Responsibility |
|---|---|---|
| `clean-code-typescript.mdc` | `**/*.ts,**/*.tsx` | naming / typing / async / `?.` `??` `satisfies` / React |
| `clean-code-rust.mdc` | `**/*.rs` | naming / `Result` / `?` / ownership / async / `unsafe` |
| `rust-fmt-discipline.mdc` | `**/*.rs` | rustfmt counter-example library + write-side proactive alignment |
| `typescript-testing.mdc` | `**/test/**/*.test.ts` | Vitest framework specifics |
| `clean-code-python.mdc` | `**/*.py,**/*.pyw` | Python clean-code — naming, typing, error handling, async, dataclasses |
| `clean-code-go.mdc` | `**/*.go` | Go clean-code — naming, error handling, interfaces, concurrency, structs |

> Future Java / Kotlin / per-test-framework rules get their own `lang/<name>.mdc` when a real consumer needs them — not before.

---

## patterns/ (7 files)

Architectural patterns extracted to be project-agnostic. Each pattern expects a project-side binding (in your own repo's `.cursor/rules/project/<name>.mdc`) for concrete values.

| File | alwaysApply | Triggered by | Expected binding |
|---|---|---|---|
| `multi-worktree.mdc` | ✗ (desc) | "continue / port / implement X" on a multi-branch repo | `project/<name>-monorepo.mdc` (paths only) |
| `multi-agent.mdc` | ✗ (desc) | running multiple agents / sessions / `best-of-n` against the same repo | `project/<name>-monorepo.mdc` (module-axis table, magnet files, test commands) |
| `plugin-architecture.mdc` | ✗ (globs) | `extensions/`, `plugins/`, `addons/` | `project/<name>-extension.mdc` |
| `im-bot-integration.mdc` | ✗ (globs) | `bridge/`, `bot/`, `im/`, `channels/` | `project/<platform>-sdk.mdc` |
| `memory-mcp-discipline.mdc` | ✗ (desc) | Memory-MCP available + substantive task | `project/<name>-memory.mdc` |
| `persona-architecture.mdc` | ✗ (globs) | `persona/`, `style/`, `mention/` | `project/<name>-persona.mdc` |
| `database-patterns.mdc` | ✗ (desc) | SQL / NoSQL schema design, indexing, transaction & ORM N+1 audit | `project/<name>-database.mdc` |

---

## examples/project-binding/ (templates, NOT loaded)

Generic reference templates for a `project/` binding layer in **your** repo. Files use `.md` so Cursor never auto-injects them.

| Template | Binds | Carries |
|---|---|---|
| `monorepo-trunk-sample.md` | `multi-worktree.mdc`, `multi-agent.mdc` | Layout hints, worktrees, kill/E2E commands, magnet-file list |
| `plugin-extension-sample.md` | `plugin-architecture.mdc` | Extension root, host loader symbol, log dir |
| `im-feishu-sample.md` | `im-bot-integration.mdc` | Lark/Feishu API sample (substitute your chat vendor) |
| `memory-mcp-sample.md` | `memory-mcp-discipline.mdc` | MCP server id, tool naming, signal examples |
| `persona-mbti-sample.md` | `persona-architecture.mdc` | MBTI-style axes + placeholder paths |

To deploy: copy into your repo's `.cursor/rules/project/`, rename `.md` → `.mdc`, replace placeholders. See `examples/project-binding/README.md`.

---

## aicoding/ (agent skill, not a rule)

`aicoding/SKILL.md` is the top-level agent skill that calls the four-layer rules above.

- Trigger: intent-driven rapid generation / UI design / large changes
- 4 gates: DECIDE → BUILD → VERIFY → POLISH
- Details: `aicoding/README.md`

---

## Migration Map

### v1 → v2 (Initial Restructure)

| v1 path (old) | v2 path | Note |
|---|---|---|
| `clean-code-core.mdc` | `common/clean-code-core.mdc` | move |
| `architecture.mdc` | `common/architecture.mdc` | move + dedupe (error-handling extracted) |
| `decision-hygiene.mdc` | `common/decision-hygiene.mdc` | move |
| `refactoring-guidelines.mdc` | `common/refactoring-guidelines.mdc` | move |
| `project-standards.mdc` | **split into 3** | → `common/quality-gates.mdc` + `common/security-guide.mdc` + `project/trunk.mdc` (later moved to examples) |
| `clean-code-typescript.mdc` | `lang/clean-code-typescript.mdc` | move + dedupe |
| `clean-code-rust.mdc` | `lang/clean-code-rust.mdc` | move + dedupe |
| `rust-fmt-discipline.mdc` | `lang/rust-fmt-discipline.mdc` | move |
| `testing-conventions.mdc` | `lang/typescript-testing.mdc` | move + rename |
| `extension.mdc` | `project/extension.mdc` | move |
| `im-sdk.mdc` | `project/im-sdk.mdc` | move |
| `mbti-persona.mdc` | `project/mbti-persona.mdc` | move + frontmatter |
| `worktree-coordination.mdc` | `project/worktree-coordination.mdc` | move |
| `memory.mdc` | `project/memory.mdc` | move + `alwaysApply: false` |
| — (new) | `common/error-handling.mdc` | extracted |
| — (new) | `common/comments-docs.mdc` | per Google Style |
| — (new) | `common/imports.mdc` | per Google Style |
| — (new) | `common/security-guide.mdc` | extracted |
| — (new) | `common/testing-principles.mdc` | extracted |

### v2 → v2.1 (English Unification)

All `.mdc` files + `aicoding/*` were translated to English for token economy and improved instruction following. Repo-specific jargon in **consuming projects** stays in their own `.cursor/rules/project/` bindings, not in this pack.

### v2.1 → v2.2 (Pattern Extraction)

The new `patterns/` layer carries project-agnostic architectural patterns lifted out of `project/`. The split:

| v2.1 file (project/) | v2.2 destination |
|---|---|
| `project/worktree-coordination.mdc` | → `patterns/multi-worktree.mdc` (deleted from project/) |
| `project/extension.mdc` | trimmed to thin binding; pattern → `patterns/plugin-architecture.mdc` |
| `project/im-sdk.mdc` | trimmed to vendor SDK table; pattern → `patterns/im-bot-integration.mdc` |
| `project/memory.mdc` | trimmed to signals dictionary; pattern → `patterns/memory-mcp-discipline.mdc` |
| `project/mbti-persona.mdc` | trimmed to 4-axis + paths; pattern → `patterns/persona-architecture.mdc` |
| `project/trunk.mdc` | values-only trunk; cross-refs updated to `../patterns/...` |

Outcome: `project/` files dropped ~50% in size (rules → patterns/, values stay in project/). Any other project can adopt `common/` + `lang/` + `patterns/` directly and only write its own `project/<bindings>.mdc`.

### v2.2 → v2.3 (Context Budget)

To prevent attention dilution, demoted 6 files from `alwaysApply: true` → `false`:

| File | New trigger | Reason |
|---|---|---|
| `common/comments-docs.mdc` | desc | Only fires when writing/reviewing docs / TODO / Deprecation |
| `common/imports.mdc` | desc | Only fires when editing imports |
| `common/refactoring-guidelines.mdc` | desc | Only fires during refactor / large-file split / type tightening |
| `common/testing-principles.mdc` | globs (`**/test/**`, `**/*.test.*`, `**/*.spec.*`) | Only fires when editing tests |
| `lang/rust-fmt-discipline.mdc` | globs (`**/*.rs`) | Was incorrectly always-on; should fire only on Rust files |
| `patterns/multi-worktree.mdc` | desc | Project-specific reality (only some repos use worktrees) |

Outcome: always-on count `13 → 7`, always-on tokens `~18K → ~9K` (-50%).

### v2.3 → v2.4 (`project/` → `examples/`)

Loaded `project/*.mdc` bindings were lifted out of the portable pack so Cursor never injects foreign paths into arbitrary repos.

| Old intent | New canonical template (never loaded — `.md`) |
|---|---|
| Monorepo / trunk (worktrees, E2E, kill commands) | `examples/project-binding/monorepo-trunk-sample.md` |
| Extension host wiring | `examples/project-binding/plugin-extension-sample.md` |
| Vendor chat SDK cheatsheet | `examples/project-binding/im-feishu-sample.md` (substitute vendor) |
| Memory MCP naming + signals | `examples/project-binding/memory-mcp-sample.md` |
| Persona axes / paths | `examples/project-binding/persona-mbti-sample.md` |

Extension `.mdc → .md` guarantees Cursor skips them.

### v2.5+ (neutral binding examples)

The `examples/project-binding/` tree uses **generic placeholders** (`<AGENT_HOME>`, `<REPO>/…`) instead of embedding one product's crates or MCP ids in portable rules.

### v2.4 → v2.5 (Targeted Additions, no always-on growth)

Three real additions plus two salvage merges. Always-on tier unchanged at 6 files.

| Change | Where | Why |
|---|---|---|
| `lang/clean-code-python.mdc` (new) | lang/ | Python language support; glob-triggered on `**/*.py` |
| `lang/clean-code-go.mdc` (new) | lang/ | Go language support; glob-triggered on `**/*.go` |
| `patterns/database-patterns.mdc` (new) | patterns/ | SQL/NoSQL schema, indexing, transactions, ORM N+1; desc-triggered |
| `patterns/multi-agent.mdc` (new) | patterns/ | Hard rules for parallel-agent runs (worktree isolation, magnet files, git constraints, pre-merge checklist). Companion to `multi-worktree.mdc` |
| `common/security-guide.mdc` (extended) | common/ | New §7 "Operational Hardening (Web)": security headers cheat sheet, rate limiting, framework entry-point table (Express / FastAPI / Spring / Django) |
| `common/refactoring-guidelines.mdc` (extended) | common/ | New "Common Refactoring Moves" section: extract service layer, conditional → strategy table |

Rejected during v2.5 review (would have bloated trigger surface or duplicated existing rules):

- A standalone `security-owasp-hardening.mdc` — overlapped 60% with `security-guide.mdc`; framework cheat-sheet salvaged into §7
- A standalone `refactoring-patterns.mdc` — 80% React-specific framework lore; two truly universal moves salvaged into `refactoring-guidelines.mdc`
- `api-documentation.mdc` / `readme-standards.mdc` — README/changelog templates are not "code rules"; agents don't repeatedly touch them
- Phantom test-framework files (`*-jest`, `*-mocha`, `pytest`) — never written to disk; INDEX has been corrected

---

## Deploying

See [`README.md`](./README.md) for install instructions (Cursor / Claude Code / Codex / Gemini, plus customizing for your project).

Note: Cursor decides when to inject rules by file name + frontmatter; the directory structure does **not** affect final triggering — it only affects human readability.

## Maintenance Conventions

1. **New rule** → first decide which layer:
   - Universal principle / cross-language → `common/`
   - Single-language syntax / tooling → `lang/`
   - Architectural pattern reusable across projects → `patterns/`
   - Project-specific value (path / tool name / URL) → **NOT here**; put in your consuming repo's `.cursor/rules/project/`. If the binding pattern is reusable as a learning example, also drop a `.md` template into `examples/`.
2. **Duplicate content**: cross-reference rather than copy-paste
3. **alwaysApply**: default `false`; only escalate to `true` if the rule fires on truly every prompt and missing it has high cost (security, naming, error handling). Always-on tier in this repo capped at ≤ 6 files / ≤ 7K tokens.
4. **After changing frontmatter**: run `rg "alwaysApply" -A1` for a global sweep
5. **After rename / move**: run `rg "<old-name>\.mdc"` to inspect all cross-refs
6. **Pattern + binding pair**: when a project binding grows past ~200 lines, look for the universal pattern hidden inside and lift it to `patterns/`. Keep the binding to values only.
7. **Token economy**: prefer English for rule bodies (~30% fewer tokens than Chinese for technical content); keep code paths / project nouns as-is.
8. **examples/ hygiene**: examples are `.md` not `.mdc` so Cursor never loads them. If you add a new example, keep the `.md` extension; if you accidentally use `.mdc`, Cursor will inject it and pollute the prompt budget.
