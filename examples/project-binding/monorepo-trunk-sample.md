---
description: Example monorepo / trunk binding — workspace layout, kill commands, E2E smoke, agent-process notes. Pair with patterns/multi-worktree.mdc and patterns/multi-agent.mdc.
alwaysApply: false
---

# Monorepo trunk binding (example)

Fill every `<...>` with values from **your** repository. This file is not loaded by Cursor (`.md` extension).

## Layout (example shape)

- App / packages root: `<REPO_ROOT>/packages/` or `<REPO_ROOT>/apps/`
- Status / parity doc (optional): `<REPO_ROOT>/docs/migration-status.md`
- Extension host (if any): `<REPO_ROOT>/extensions/` or `<AGENT_HOME>/extensions/`

## Worktree discovery

Document where long-lived worktrees usually live (so `multi-worktree.mdc` pre-flight has context):

- Main checkout: `<path>`
- Feature worktrees: `<path-prefix>-<branch-slug>/`

## Kill / cache-clear (dev)

```bash
# examples only — replace with your stack
# pnpm store prune
# docker compose down -v
```

## E2E / smoke (project-specific)

```bash
# examples only
# npm run test:e2e
```

## Multi-agent / magnet files

List files that **at most one** parallel agent may edit (see `patterns/multi-agent.mdc` §3):

- `<REPO_ROOT>/package.json` and lockfile
- `<REPO_ROOT>/i18n/*.json` (if any)
- `<REPO_ROOT>/<shared-schema>.ts`

## See also

- `../patterns/multi-worktree.mdc`
- `../patterns/multi-agent.mdc`
- `../common/quality-gates.mdc`
