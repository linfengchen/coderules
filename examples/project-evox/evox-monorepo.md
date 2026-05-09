---
description: EvoX monorepo project conventions — layout, runtime selection, extension dev, E2E test flow, process management
alwaysApply: true
---

# EvoX Monorepo Standards

EvoX-specific engineering practices. Universal rules live in `../common/`; language rules in `../lang/`.

## 1. Language & Communication

- All agent replies to users: **Chinese**
- Code / comments / docs: **no emoji** (except Feishu integration — see `feishu-sdk.mdc#feishu-emoji`)

## 2. Project Layout

```
~/.evox/
  agent/
    auth.json          -- provider API keys
    settings.json      -- default model, provider
    extensions/        -- evox extensions (plugins, .so/.dylib for Rust cdylib)
    skills/            -- skill modules (SKILL.md based)
~/evox/                -- evox source repo (monorepo)
  packages/
    ai/                -- LLM provider abstraction (Anthropic, OpenAI, Google, etc.)
    agent/             -- core agent runtime (loop, state, events, evolution hooks)
    coding-agent/      -- main CLI agent (TUI, RPC, tools, extensions) -- TS (dist/cli.js)
    evo-session/       -- evolution-aware session (glue between agent and evolution engine)
    tui/               -- terminal UI library (differential rendering)
    web-ui/            -- web components for AI chat interfaces (Lit 3)
  evox-rs/             -- Rust workspace (Phase 6b dual-write)
    crates/
      evox-coding-agent/   -- produces `evox` binary (Rust runtime)
      evox-ai/             -- produces `evox-ai` binary (OAuth + provider CLI)
      evox-ext-*/          -- extension cdylibs (.so/.dylib)
      evox-*/              -- library crates (kernel, ai, agent-core, evo-session, memory, ...)
    target/release/evox      -- Rust CLI binary (pointed to by EVOX_RUST_BINARY)
    docs/parity-matrix.md    -- TS <-> Rust module mapping + status
  bench/
    compare.mjs        -- dual-runtime parity harness (TS vs Rust print -p --mode json)
```

## 3. Runtime Selection (Phase 6b)

`EVOX_RUNTIME=rust` (with optional `EVOX_RUST_BINARY=/path/to/evox`) makes the TS `evox` wrapper exec into the Rust binary. Unset or `EVOX_RUNTIME=ts` takes the Node path.

## 4. EvoX Extension Development

The general extension-development pattern (folder layout, lifecycle hooks, tool registration, reload discipline) lives in `../patterns/plugin-architecture.mdc`. EvoX-specific bindings are in `evox-extension.mdc`. EvoX-only specifics here:

EvoX uses jiti (TypeScript JIT compiler) to load extensions; build artifacts are cached at `/tmp/jiti/`. After modifying extension code, you **must** clear the cache and restart the agent — per `../patterns/plugin-architecture.mdc#6-plugin-reload-discipline`:

```bash
pkill -9 -f "cli.js"; sleep 2; rm -rf /tmp/jiti
```

After restarting, verify the cached code contains your change:

```bash
grep "your_new_function_or_keyword" /tmp/jiti/<extension-name>-index.*.mjs
```

Extension source lives at `~/evox-extensions/`, symlinked into `~/.evox/agent/extensions/`. See `evox-extension.mdc`.

### 4.1 TUI-Specific Error-Handling Note

EvoX's TUI swallows console output. Per `../patterns/plugin-architecture.mdc#51-hosts-that-swallow-console-output`, write errors to a file:

```ts
import { appendFileSync } from "node:fs";

try { riskyCall(); }
catch (err) {
	appendFileSync("/tmp/feishu-bridge.log",
		`[${new Date().toISOString()}] [feishu-bridge] ${err}\n`);
}
```

## 5. Feishu API Reference

For every Feishu API parameter / return value / permission requirement, **verify against `feishu.apifox.cn`** — don't guess from memory.

- Use the WebFetch tool against `https://feishu.apifox.cn` to look up specific endpoint docs.
- Pay special attention to SDK return shapes (e.g., `messageResource.get` returns `{ getReadableStream(), writeFile() }`, not `{ data }`).
- Before adding a new Feishu tool, look up the endpoint doc to confirm parameters and permission scope.

## 6. Agent Process Management (Important)

Before starting the agent, you **must** confirm and kill any existing `pi` process — otherwise multiple instances compete for WebSocket messages:

- Old process steals messages; new process never receives them
- Old process uses old code, your changes don't take effect
- Multiple WebSocket connections cause lost or duplicated messages

```bash
# Run before every start
sudo pkill -9 -f "^pi$" 2>/dev/null; sleep 2
ps aux | grep "pi$" | grep -v grep  # confirm 0 residuals
```

Run before every test; confirm 0 `pi` processes before starting a new agent.

## 7. Feishu Bridge E2E Testing

After modifying the feishu-bridge extension, run end-to-end verification per `../common/quality-gates.mdc#post-change-review--e2e-gate`:

1. **Kill all old agent processes and clear the cache**

   ```bash
   sudo pkill -9 -f "^pi$" 2>/dev/null; sleep 2
   ps aux | grep "pi$" | grep -v grep  # confirm 0 processes
   rm -rf /tmp/jiti
   cd ~/evox && source ~/.evox/.env && export FEISHU_APP_ID FEISHU_APP_SECRET
   nohup node packages/coding-agent/dist/cli.js > /tmp/evox-agent.log 2>&1 &
   ```

2. **Confirm successful startup**: check `/tmp/feishu-bridge.log` for `WebSocket connected.`

3. **Fetch tenant_access_token**

   ```bash
   curl -s -X POST 'https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal' \
     -H 'Content-Type: application/json' \
     -d '{"app_id": "'$FEISHU_APP_ID'", "app_secret": "'$FEISHU_APP_SECRET'"}'
   ```

4. **Send a test message via the browser**: use the browser MCP tool to open `https://autogame.feishu.cn/next/messenger/`, find the Evox chat, send a test message (e.g., "who are you").

5. **Verify three layers**:
   - `/tmp/feishu-bridge.log`: confirm `Received from`, `before_agent_start: injecting`, `Streaming card created`, `Replied to` appear end-to-end
   - The `.jsonl` session file under `~/.evox/agent/sessions/`: confirm the user message uses `<feishu_context>` XML format and the assistant reply matches expectations
   - Feishu client screenshot: confirm the card renders correctly with the right content

## 8. Dependencies (EvoX-Specific)

Universal dependency management lives in `../common/quality-gates.mdc#4-dependencies--builds`. EvoX-specific:

- Use `npm install` (**not** yarn / pnpm) to match the monorepo setup
- TS-side changes: run `npm run build`
- Rust-side changes: `cd evox-rs && cargo build --release`; for fast iteration, `cargo check --workspace`; on memory-constrained hosts, `cargo test --workspace -j 1 -- --test-threads=1` to avoid OOM
- The dual-runtime parity harness `node bench/compare.mjs` runs TS vs Rust equivalence comparison; new behavior on the Rust side must align via this harness

## 9. Coordination With Other Rules

- `../common/quality-gates.mdc`: §7 of this file is its EvoX / Feishu concrete instance
- `../common/clean-code-core.mdc` / `../lang/clean-code-typescript.mdc` / `../lang/clean-code-rust.mdc`: universal + language rules
- `evox-extension.mdc` / `feishu-sdk.mdc` / `mbti-persona.mdc`: EvoX-specific bindings of the `../patterns/` layer
- `../patterns/multi-worktree.mdc`: multi-worktree collaboration
- `gep-memory.mdc`: experience capture (binds `../patterns/memory-mcp-discipline.mdc`)
