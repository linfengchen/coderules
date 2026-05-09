---
description: EvoX-specific binding for the plugin-architecture pattern — folder location, host API symbol, log directory
globs: .evox/agent/extensions/**/*.ts,evox-extensions/**/*.ts
alwaysApply: false
---

# EvoX Extension Binding

Generic plugin / extension architecture lives in `../patterns/plugin-architecture.mdc`. This file binds the pattern to EvoX-specific values.

## Concrete Bindings

| Pattern slot | EvoX value |
|---|---|
| Plugins root | `~/.evox/agent/extensions/<name>/` (symlinks into `~/evox-extensions/<name>/`) |
| Manifest section | `package.json` field `"pi": { "extensions": ["./index.ts"] }` |
| Host API import | `import type { ExtensionAPI } from "@evox/coding-agent"` |
| Entry signature | `export default function (pi: ExtensionAPI)` |
| Tool registration | `pi.registerTool({ ... })` |
| Lifecycle hooks | `session_start` / `agent_end` / `session_shutdown` |
| Log directory | `/tmp/<name>.log` (TUI swallows console — see below) |
| JIT cache | `/tmp/jiti/` (clear after every code change; see `evox-monorepo.mdc#4-evox-extension-development`) |

## TUI-Specific Error Logging

EvoX's TUI swallows console output. Per `../patterns/plugin-architecture.mdc#51-hosts-that-swallow-console-output`, write errors to a file:

```ts
import { appendFileSync } from "node:fs";

try { riskyCall(); }
catch (err) {
  appendFileSync(`/tmp/<name>.log`,
    `[${new Date().toISOString()}] [<name>] ${err instanceof Error ? err.message : err}\n`);
}
```

## Tool Return Format

```typescript
function ok(data: any) {
  return { content: [{ type: "text" as const, text: JSON.stringify(data, null, 2) }], details: {} };
}
function fail(msg: string): never {
  throw new Error(msg);
}
```

## See Also

- `../patterns/plugin-architecture.mdc` — full plugin-architecture pattern
- `evox-monorepo.mdc#4-evox-extension-development` — jiti cache + reload discipline
- `feishu-sdk.mdc` — concrete example of an EvoX extension
