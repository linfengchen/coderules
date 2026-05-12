# Project binding examples (reference only)

This directory holds **generic `.md` templates** that show how to bind `patterns/` to your repo’s concrete paths, env vars, and commands.

## Why `.md` not `.mdc`?

Cursor only auto-loads `*.mdc` under `.cursor/rules/`. These files use `.md` so they are **never injected** into prompts — copy-paste sources only.

## How to use

1. Create `.cursor/rules/project/` in your repo.
2. Copy the templates you need, rename `.md` → `.mdc`, fill in placeholders (`<YOUR_...>`).
3. Ensure relative paths to `../patterns/...` still resolve from `.cursor/rules/project/`.

## Pattern → template map

| Pattern (`patterns/`) | Example binding (`examples/project-binding/`) |
|---|---|
| `multi-worktree.mdc` | `monorepo-trunk-sample.md` |
| `multi-agent.mdc` | same trunk file (paths, magnet list, test commands) |
| `plugin-architecture.mdc` | `plugin-extension-sample.md` |
| `im-bot-integration.mdc` | `im-feishu-sample.md` (Lark/Feishu illustrates one vendor; substitute your platform) |
| `memory-mcp-discipline.mdc` | `memory-mcp-sample.md` |
| `persona-architecture.mdc` | `persona-mbti-sample.md` |
| _(error-handling facade)_ | `logging-facade-sample.md` (bind `common/error-handling.mdc` `[module-name]` convention to your logger) |

The Feishu sample is **one concrete IM integration**; Discord/Slack bindings follow the same shape with different URLs and emoji vocabularies per `im-bot-integration.mdc`.
