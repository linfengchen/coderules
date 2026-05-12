---
description: Example memory MCP binding — server id, tool prefix, signal vocabulary. Universal recall/record discipline lives in patterns/memory-mcp-discipline.mdc.
alwaysApply: false
---

# Memory MCP binding (sample)

Universal discipline — when to recall, record, summary/signals/score — is in `../patterns/memory-mcp-discipline.mdc`. This file is a **filled-out example shape** only; rename tools to match whatever your MCP exposes.

## Concrete bindings (placeholder)

| Pattern slot | Example value |
|---|---|
| MCP server id (Cursor / config) | `your-memory-server` |
| Tool prefix | `mem_` |
| Recall tool | `mem_recall` |
| Record tool | `mem_record_outcome` |

Adjust names to your server; keep **one** recall + **one** record pattern.

## Signal dictionary (extend in your repo)

Mix **generic** task signals from `memory-mcp-discipline.mdc` with **your** domain nouns (`payment_webhook`, `auth_session`, …). Prefer stable, grep-friendly tokens — not prose.

Example domain rows (replace with yours):

| Signal | When |
|---|---|
| `im_bridge` | Chat-platform integration |
| `plugin_loader` | Extension load / handshake |
| `ci_rust_fmt` | Format / toolchain drift |

## Workflow sketch (generic)

1. Before a substantive fix: recall with query + 1–2 signals.
2. After E2E / smoke green: record outcome with `summary`, `signals`, `score`.

## See also

- `../patterns/memory-mcp-discipline.mdc`
- `../common/engineering-lifecycle.mdc` — after substantive decisions, record signals like `decision_decomposition` / `temporal_layering` / `glue_layer` if your MCP supports them
- `monorepo-trunk-sample.md` — where E2E commands for your repo are documented
