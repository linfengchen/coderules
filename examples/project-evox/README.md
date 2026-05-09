# EvoX Project Bindings (Example)

This directory contains **EvoX-specific reference templates** showing how to write a `project/` layer that binds the universal `patterns/` rules to a concrete project's values.

## Why `.md` not `.mdc`?

Cursor only auto-loads `*.mdc` files from `.cursor/rules/`. These templates use `.md` so they are **not injected into any prompt** — they exist only as documentation / copy source.

## How to use these templates

If you want to set up a similar binding layer for your own project (whether you fork EvoX or set up a new project on top of `coderules/common + lang + patterns`):

1. In your repo, create `.cursor/rules/project/`
2. Copy the relevant templates here (`.md`) into it, renaming to `.mdc`
3. Replace EvoX-specific values with yours:

| Template | What to replace |
|---|---|
| `evox-monorepo.md` | layout / runtime / E2E / agent-process commands |
| `evox-extension.md` | extension paths, host-package symbol, log dir |
| `feishu-sdk.md` | IM platform endpoints, emoji_type table, message-block IDs |
| `gep-memory.md` | memory-MCP server name, tool prefix, signal dictionary |
| `mbti-persona.md` | persona framework axes, persona-crate paths, splitter call sites |

4. Make sure relative paths inside (e.g., `../patterns/multi-worktree.mdc`) still resolve from your `.cursor/rules/project/` location

## Pattern → Binding Map

Each template binds a universal pattern to EvoX-specific values:

| Pattern (`patterns/`) | EvoX binding (`project-evox/`) |
|---|---|
| `multi-worktree.mdc` | `evox-monorepo.md` (paths section) |
| `plugin-architecture.mdc` | `evox-extension.md` |
| `im-bot-integration.mdc` | `feishu-sdk.md` |
| `memory-mcp-discipline.mdc` | `gep-memory.md` |
| `persona-architecture.mdc` | `mbti-persona.md` |

## Why we keep these visible

The values themselves (e.g., the Feishu emoji_type table, the GEP signal dictionary) are non-trivial to reverse-engineer. Even if you're not on EvoX, reading these as concrete examples is a fast way to learn what a "good" binding layer looks like in practice.
