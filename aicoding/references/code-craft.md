# Code Craft (Full Gate 2)

Main SKILL: [`../SKILL.md`](../SKILL.md). This file expands Gate 2 "BUILD" — load on demand.

References:
- This repo's `../../common/clean-code-core.mdc` / `../../lang/clean-code-typescript.mdc` / `../../lang/clean-code-rust.mdc` quantitative limits
- Google Style Guides (TS / Python / Java / Go)
- addyosmani/agent-skills' `incremental-implementation` / `api-and-interface-design`

---

## 1. Naming

### 1.1 Universal Anti-Patterns (Forbidden)

Uninformative words → forced rename:

| ❌ | ✅ | Renaming idea |
|---|---|---|
| `data` | `userProfile` / `taskList` / `parsedConfig` | what the content is |
| `result` | `validationErrors` / `mergedSnapshot` | what the computation produced |
| `tmp` / `temp` | `pendingDelete` / `inFlightChunk` | the state it represents |
| `info` | `userMetadata` / `errorContext` | the kind of information |
| `item` (in a loop) | `task` / `child` / `entry` | the actual element |
| `manager` / `helper` / `util` | `taskScheduler` / `dateFormatter` | its responsibility |
| `handle` (verb) | `dismissDialog` / `submitForm` | the event being handled |
| `process(x)` | `parseManifest(x)` / `dispatchEvent(x)` | the specific action |

### 1.2 Predicates and Side Effects

```ts
// ✅ Predicates: is / has / can / should
function isExpired(token: Token): boolean {}
function hasPermission(user: User, action: Action): boolean {}
function canRetry(error: Error): boolean {}

// ✅ Imperatives (verb-first)
function flushQueue(): void {}
function createTask(input: TaskInput): Promise<Task> {}

// ❌ Getters must not mutate
function getUser(id: string): User {
  ensureUserCacheLoaded(); // mutates! should be fetchUser or loadUser
  return cache[id];
}
```

### 1.3 Per-Language Casing

| Element | TS / JS | Rust | Python | Go |
|---|---|---|---|---|
| Variable / function | `camelCase` | `snake_case` | `snake_case` | `camelCase` (export `PascalCase`) |
| Type / class | `PascalCase` | `PascalCase` | `PascalCase` | `PascalCase` |
| Constant | `SCREAMING_SNAKE_CASE` | `SCREAMING_SNAKE_CASE` | `SCREAMING_SNAKE_CASE` | `MixedCaps` |
| File | `kebab-case.ts`, components `PascalCase.tsx` | `snake_case.rs` | `snake_case.py` | `snake_case.go` |
| Private/internal | `_prefix` (convention) | `pub(crate)` for visibility | `_prefix` | lowercase first letter |

File naming strictly follows the language ecosystem. **No cross-language style mixing.**

---

## 2. Comments / Docs

### 2.1 Comments Explain Why Only

```ts
// ❌ Restating code
let count = 0; // initialize counter
count++;       // increment

// ❌ Stating the obvious
function add(a: number, b: number) {
  return a + b; // returns the sum
}

// ✅ Non-obvious trade-off / constraint
// Retry 3 because provider hits ~0.5% 5xx at peak; >3 means it's truly down
const RETRY_LIMIT = 3;

// ✅ Why not the seemingly-better alternative
// Not using Set.has — elements are deep objects with unstable identity; some + isEqual is correct
const exists = items.some(it => isEqual(it, target));
```

### 2.2 Public-API Documentation (Mandatory)

Cross-module / cross-package exports must have a doc comment with **at least**:
1. One-line description
2. One usage example
3. Error / exception behavior

```ts
/**
 * Creates a task and returns the persisted record.
 *
 * @example
 * const task = await createTask({ title: "Buy milk" });
 *
 * @throws ValidationError when title is empty or > 200 chars
 */
export async function createTask(input: TaskInput): Promise<Task> {}
```

```rust
/// Splits a streaming reply into chunks per persona configuration.
///
/// # Examples
///
/// ```
/// let chunks = split_reply("hello world", Some("INTP"), &etiquette);
/// assert_eq!(chunks.len(), 2);
/// ```
///
/// # Errors
///
/// Returns single-chunk fallback when `mbti` is invalid.
pub fn split_reply(...) -> Vec<Chunk> {}
```

### 2.3 TODO / FIXME — Required Format

```
// TODO(joy, #123): switch to streaming once provider supports SSE
// FIXME(joy, #145): race condition under concurrent writes — see issue
```

Missing owner or issue → treated as dead comment, deleted.

### 2.4 Deprecation — Required Format

```ts
/**
 * @deprecated since 0.5.0, use `createTaskV2` instead.
 *             Removed in 1.0.0.
 */
export function createTask(...) {}
```

Missing replacement or removal schedule → treated as residue.

---

## 3. Error Handling

### 3.1 Universal Rules

- **Each catch / Result handler must satisfy at least one of**:
  1. logger record with `[module-name]` prefix
  2. comment explaining **why ignoring is safe** (`// ignore` alone is not enough)
  3. error rethrow / propagation

```ts
// ❌
try { riskyCall(); } catch {}
try { riskyCall(); } catch { /* ignore */ }

// ✅
try { riskyCall(); }
catch (err) {
  logger.error(`[task-service] riskyCall failed: ${err instanceof Error ? err.message : err}`);
}

// ✅ Explicit safe-ignore
try { statSync(path); }
catch {
  // path may not exist — that's expected; the undefined fallback below handles it
}
```

```rust
// ❌
let port: u16 = env::var("PORT").unwrap().parse().unwrap();

// ✅
let port: u16 = env::var("PORT")
    .map_err(|_| ConfigError::MissingPort)?
    .parse()
    .map_err(ConfigError::InvalidPort)?;
```

### 3.2 Validate at Boundaries; Trust Inside

```ts
// API handler / form / third-party response → schema validation
app.post('/api/tasks', async (req, res) => {
  const result = CreateTaskSchema.safeParse(req.body);
  if (!result.success) return res.status(422).json({ error: 'VALIDATION_ERROR', details: result.error });
  const task = await taskService.create(result.data); // internal: trust the type
  res.status(201).json(task);
});
```

Third-party API responses = **untrusted data**; validate the shape before use. The attack surface includes (but is not limited to) poisoned LLM responses, hijacked webhook payloads, and CI log output.

### 3.3 Strict Constraints on Cross-Package Public APIs

- TS: forbid `any` as parameter / return type; in-package helpers may relax
- Rust: define error enums with `thiserror` across crate boundaries; forbid `panic` / `unwrap`
- Read the source of a third-party library before calling it; don't paper over with `any`

---

## 4. Interfaces and Architecture

### 4.1 Single Interface Definition

- Same interface / type defined in exactly one package; everywhere else uses `import type`
- **See "I'll write an adapter to bridge two similar definitions" → red light**: merge first, then proceed
- When adding a new field to an interface, synchronously check all wiring sites (definition, implementation, delegation/forwarding, call site) — none can be skipped

### 4.2 Barrel + Delegation Split

When a file exceeds 500 lines: keep the original as a barrel, extract logic into submodules:

```ts
// task-service.ts (barrel) — keeps the class, delegates to submodules
import { runTaskCreate } from "./task-service-create.js";
import { runTaskBatch } from "./task-service-batch.js";

class TaskService {
  create(input: TaskInput) { return runTaskCreate(this.db, this.logger, input); }
  batch(items: TaskInput[]) { return runTaskBatch(this.db, this.logger, items); }
}

export { TaskService };
export * from "./task-service-types.js";
```

Post-split checks:
- [ ] Barrel covers all public APIs
- [ ] Submodules have no circular deps
- [ ] Type check passes
- [ ] No duplicate functions (extraction commonly produces them)

### 4.3 Single Cross-Process / Cross-Language Glue

Need an external runtime / hot reload / multi-language bridge → reuse the project's existing glue channel first (e.g., MCP / existing IPC). **Forbidden** to build a second IPC / socket / private RPC for a new requirement, unless:
1. List concrete shortcomings of the existing glue (with file:line)
2. Explain why extending the existing layer doesn't work
3. Get user adjudication before acting

---

## 5. Test Discipline

### 5.1 How Many Tests

- **New logic module**: must have tests (at least one happy path + one error path)
- **Bug fix**: must have a regression test; **reproduce the failure first**, then write the fix
- **Refactor**: rely on existing tests as a safety net; if coverage is thin, add tests before refactoring

### 5.2 Test Naming

```ts
// ❌ Names describe implementation
it('calls db.query with correct args', () => {});

// ✅ Names describe behavior
it('returns 404 when task does not exist', () => {});
it('rejects creation when title exceeds 200 chars', () => {});
```

### 5.3 Test Pyramid

```
        E2E (5%)        ← real user journeys
      Integration (15%) ← cross-module / DB
     Unit (80%)         ← single function / pure logic
```

Don't pile every feature into E2E — slow and fragile. Use unit when you can.

### 5.4 Mock Boundaries

- Mock things **outside** the system: HTTP / DB / filesystem / clock
- Don't mock the services you wrote (test the real thing)
- The deeper the mock, the more fragile and lower-value the test

---

## 6. Imports (per Google Style)

### 6.1 Three Segments

```ts
// 1. stdlib / language built-ins
import { readFileSync } from "node:fs";

// 2. third-party
import { z } from "zod";
import express from "express";

// 3. this repo / relative paths
import type { Task } from "./types.js";
import { taskService } from "./services/task.js";
```

```python
# 1. stdlib
import json
from pathlib import Path

# 2. third-party
import requests
from pydantic import BaseModel

# 3. local
from .models import Task
from .services import task_service
```

```rust
// 1. std
use std::collections::HashMap;

// 2. external crates
use serde::{Deserialize, Serialize};
use tokio::sync::Mutex;

// 3. crate-local
use crate::types::Task;
use super::service;
```

### 6.2 Rules

- One blank line between segments
- Alphabetized within a segment
- No wildcard `import * as X from ...` (language-native `use foo::*` likewise; except known preludes)
- TS type dependencies **must** use `import type` to avoid runtime side-effects

---

## 7. Incremental-Delivery Specifics

### 7.1 Slice Strategies

| Strategy | When | Example |
|---|---|---|
| **Vertical** | Default | One narrow DB → API → UI path |
| **Contract First** | Frontend / backend in parallel | Define OpenAPI / types first; both sides mock-progress |
| **Risk First** | High uncertainty | Validate the WebSocket connection works first; then business logic |

### 7.2 Feature Flag Backstop

Unfinished capabilities merged into trunk must be gated:

```ts
const ENABLE_TASK_SHARING = process.env.FEATURE_TASK_SHARING === 'true';
if (ENABLE_TASK_SHARING) { /* new path */ }
```

### 7.3 Safe Defaults

New parameter / new option → default to the **conservative value** (off, minimum side-effect):

```ts
function createTask(data: TaskInput, options?: { notify?: boolean }) {
  const shouldNotify = options?.notify ?? false; // default: don't notify
}
```

---

## 8. Per-Language Specifics

### 8.1 TypeScript

- Line width 100 (matches Biome / Prettier; not Google's 80)
- `import type` mandatory
- Use `?.` / `??` / `satisfies` deliberately
- React: functional components + hooks; no new class components
- Effect deps array must be complete; missing deps are bugs

### 8.2 Rust

- Line width 120 (rustfmt default)
- **No** `unwrap()` / `expect()` in production paths
- Use `thiserror` for error enums; `?` propagates across crates
- Borrow over clone; APIs take `&str` / `&[T]` / `&Path`, return owned
- async via tokio; `tokio::time::sleep`, not `std::thread::sleep`
- `unsafe` requires `// SAFETY: ...` explaining the invariant

### 8.3 Python

- Line width 88 (black default) / 100
- Mandatory type hints (mypy strict)
- Dataclass / pydantic for data structures
- No `from x import *`

### 8.4 Go

- gofmt + golangci-lint
- Errors explicit `(T, error)`; no panics
- Small interfaces (1–3 methods preferred); define on demand
- context as the first parameter

---

## 9. Pre-Flight Check (Multi-Branch / Multi-Worktree)

When the project has multiple git worktrees / multiple humans / multiple agents in parallel:

1. List all worktrees: `git worktree list`
2. Inspect each branch's current activity (latest commit / dirty status / `HANDOFF.md`)
3. Scan whether the target file is claimed by another worktree
4. Claimed → stop, ask the user; never create a parallel implementation

Details: `../../patterns/multi-worktree.mdc`.
