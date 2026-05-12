---
description: Example persona binding (MBTI 4-axis) — schema location, splitter, mention gate. Universal pattern in patterns/persona-architecture.mdc.
globs: <REPO>/packages/persona-mbti/**,<REPO>/packages/persona-core/**
alwaysApply: false
---

# Persona binding — MBTI sample

Universal bot-persona rules are in `../patterns/persona-architecture.mdc`. Replace every `<...>` with **your** crate or package paths.

## Concrete bindings (template)

| Pattern slot | Your value |
|---|---|
| Framework | MBTI 4-axis (E/I, S/N, T/F, J/P) — or swap for another taxonomy |
| Bot persona storage | `<AGENT_HOME>/persona.json` |
| Schema source of truth | `<REPO>/packages/persona-core/src/schema.rs` (or `.ts`) |
| Pure splitter fn | `<crate>::split::split_reply` |
| Mention gate module | `<REPO>/packages/im-channels/src/mention.rs` |
| Require-mention env | `REQUIRE_BOT_MENTION` (default `true` if unset) |

## Axis template assets

Keep **four** markdown templates (one per axis), loaded from fixed paths:

```
<REPO>/packages/persona-mbti/assets/
  dim_E_I.md
  dim_S_N.md
  dim_T_F.md
  dim_J_P.md
```

Constraints from `persona-architecture.mdc`:

- No 16-type mega-switches in code; compose from axes.
- Splitter stays pure (no env, files, RNG); host handles delays / IO.
- Single mention gate; platform adapters normalize mentions into one struct.

## See also

- `../patterns/persona-architecture.mdc`
- `../common/decision-hygiene.mdc` — decomposition before expanding axes
- `im-feishu-sample.md` — if persona affects IM streaming send path
