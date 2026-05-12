---
description: Example plugin / extension binding — host API entry, extension root, log directory. Pair with patterns/plugin-architecture.mdc.
alwaysApply: false
---

# Plugin extension binding (example)

Replace all `<...>` placeholders. Not auto-loaded (`.md`).

## Bindings

| Pattern slot | Your value |
|---|---|
| Extension root on disk | `<AGENT_HOME>/extensions/<my-bridge>/` or `<REPO_ROOT>/extensions/<name>/` |
| Host package / symbol that loads extensions | e.g. `createExtensionHost()` from `<host-module>` |
| Manifest or config file | `<path>/extension.json` |
| Log directory (if TUI: avoid `console.error`; use file append per host rules) | `<path>/logs/` |

## Red lines

- One extension manifest format; no second parallel loader.
- Extensions do not reach around the host’s public API into internal modules.

## See also

- `../patterns/plugin-architecture.mdc`
