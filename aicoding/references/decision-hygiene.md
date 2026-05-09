# Decision Hygiene (Full Gate 1)

Main SKILL: [`../SKILL.md`](../SKILL.md). This file expands Gate 1 "DECIDE".

> This is the core differentiator from addyosmani/agent-skills. The biggest root cause of "vibe coding" failure is not writing the wrong code — it's **writing very fast in the wrong direction**. This gate exists to prevent that.

Reference: this repo's `../../common/decision-hygiene.mdc` (verbatim source).

---

## 1. Claim Decomposition First

### 1.1 Why Decompose

When the user gives a conclusive directive ("do X / don't do Y"), **don't generate todos / plans / code along the conclusion**. The conclusion is one sentence in the user's head, but at the implementation layer it's typically a 3–5-dimension composite proposition. Following the conclusion blindly = expanding the user's "compressed expression" at the wrong layer.

### 1.2 One-Liners That Explode

| User says | Actual dimensions covered |
|---|---|
| "Add user login" | Auth strategy / user storage / middleware / UI / security (password hash, rate limit, CSRF) |
| "Replace in-memory cache with Redis" | Data layer / serialization / eviction strategy / deployment / rollback |
| "Don't introduce new deps" | Build-time deps / runtime deps / dev toolchain |
| "Don't do dynamic loading" | SDK ABI stability / cdylib dynamic loading / hot reload (three independent things) |
| "Refactor this module to be more decoupled" | Interface boundary / state ownership / error propagation / test boundary |
| "Support dark mode" | Color tokens / user preference detection / persistence / system follow / image assets |
| "Add a search" | Index / query syntax / frontend UX / performance (debounce / pagination) |

### 1.3 What to Do After Decomposing

1. List all dimensions (3–5 is typical)
2. Verdict **each** dimension independently: do / don't / pending
3. If some hold and some don't, call out the difference
4. For undecided ones → return to the user; don't decide on their behalf
5. The decomposition action must be **visible in the agent's reply** so the user can verify

### 1.4 Decomposition Template

```markdown
Your request "Add user login" decomposes into 5 dimensions:

1. **Auth strategy**: recommend session-cookie + bcrypt (project already uses express-session; no new dep needed)
2. **User storage**: existing `users` table has email + hash fields — sufficient
3. **Middleware**: add `requireAuth`, mount on routes that need protection
4. **UI**: add `/login` and `/register` pages; reuse existing form component
5. **Security**: rate limit (5 fails/min) + CSRF token

Pending:
- Forgot-password flow? Involves an email service → confirm which provider
- OAuth? Not now; reserve `AUTH_PROVIDER` env as placeholder

Confirm this decomposition and I'll start the slice from dimensions 1 + 2.
```

---

## 2. Evidence Anchors

### 2.1 Hard Floor: 1–3 Concrete Anchors

Before any architectural call / technical-direction recommendation / "current state isn't good enough" argument, you must produce concrete anchors via search / file reads:

- **Code reference**: a specific snippet at `src/auth/handler.ts:42-50`
- **Config reference**: `package.json:"deps".express` is currently `4.18.2`
- **Current metric**: bundle 240 kB / 156 tests all green / coverage 67%
- **Existing doc**: `docs/architecture.md` §N, ADR-007

### 2.2 Counter-Examples (Reject and Redo)

```
❌ "Sounds bad" type:
"The existing hooks aren't flexible enough; suggest a plugin architecture"
(no code cited, no specifics, guessing)

❌ "Future maybe" type:
"Future third-party extensions will need this capability"
(no user / issue / roadmap cited; worrying for future users)

❌ "I remember" type:
"I remember Tailwind 4 has breaking changes; we should upgrade first"
(no tool verification; concluding from training-data fuzz)
```

### 2.3 Positive Examples

```
✅ Concrete reference:
"`src/hooks/useFetch.ts:12-30` hardcodes retry to 3,
 `src/api/uploadFile.ts:45` wraps it with extra try/catch to work around the limit
 → suggest making retry an optional parameter, so callers don't reinvent the wheel"

✅ Metric-backed:
"`bench/baseline.json` shows first-paint LCP 3.2s,
 P95 slow requests concentrated in `/api/dashboard` N+1 query
 → fix that first; expect LCP < 2s"
```

### 2.4 Anchors Must Appear in the Reply

Not "I checked, trust me" — write the file / line / number directly into the reply so the user can jump and verify. Anchor cost is tiny (one grep + one read); benefit is **eliminating hallucinated architecture**.

---

## 3. Explicit Retraction

### 3.1 Trigger

When you discover within the same session / PR that **a previous suggestion** contradicts **current facts / new evidence**, you must mark explicitly.

### 3.2 Format

> **Retract** \<previous-keyword\>: \<why retracting\>. \<replacement / next step\>.

### 3.3 Examples

```
✅ "**Retract** 'Redux Toolkit': just read src/store.ts; project already uses Zustand
   with only 3 stores. Not worth rewriting. New recommendation: keep Zustand;
   just extract a selectors hook from the user store."

✅ "**Retract** 'React Query': SWR is already wired into 5 components with no
   visible bottleneck. Don't switch libraries. New recommendation: extract the
   fetcher to a shared util."
```

### 3.4 Counter-Examples

```
❌ Silent reversal:
"...OK, let's use Zustand" (after previously recommending Redux)

❌ Vague language:
"On further thought, Zustand feels more appropriate"
(doesn't say what's being retracted or why)

❌ Wrapping into a new plan:
"We could do a Redux + Zustand hybrid solution..."
(textbook sunk-cost fallacy; perpetuating the wrong suggestion)
```

### 3.5 Why Explicit Retraction Matters to Users

Users can read the conversation and **immediately see which options are ruled out** without re-walking the decision tree. Critical for long sessions and for the next person picking up the work.

---

## 4. Temporal Layering (YAGNI Across Time)

### 4.1 Split Into now / later

Every architectural decision must distinguish:

- **now (pre-v1 / current phase)**: must land in this PR; de-facto standard + minimum complexity
- **later (post-v1 / next phase)**: only **placeholder + one-line trigger condition**

### 4.2 How to "Leave a Placeholder"

Not "write nothing" — write the **minimum placeholder**:

```ts
// ✅ Placeholder: env var reservation + doc
// Multi-provider switching not implemented now; ENV reserved as placeholder
const PROVIDER = process.env.AUTH_PROVIDER ?? 'local';
if (PROVIDER !== 'local') {
  throw new Error(`AUTH_PROVIDER=${PROVIDER} not supported yet, only 'local' is implemented`);
}

// ❌ Implementing the negotiation protocol now (YAGNI violation)
const providers = {
  local: new LocalProvider(),
  google: new GoogleProvider(),  // nobody asked for it; shouldn't be written now
  github: new GithubProvider(),
};
```

### 4.3 Trigger Conditions Must Be Concrete

```
❌ "We may need i18n later"
✅ "When issue#42 collects ≥ 3 i18n requests / OR revenue includes non-Chinese-speaking markets → start i18n"

❌ "We may split into microservices later"
✅ "QPS > 5000 sustained for a week / OR a single service's build > 10min → evaluate split"
```

### 4.4 Typical Forbidden Actions

- Implementing an ABI compatibility matrix now for possible future extensions
- Designing a binding generator now for possible multi-language SDKs
- Adding a data isolation layer now for possible multi-tenancy
- Extracting i18n keys now for possible internationalization
- Writing strategy patterns now for possible multi-provider

**"Maybe needed later" is not a reason to ship — it's a reason to leave a placeholder + write the trigger condition.**

---

## 5. Commitment Boundary

### 5.1 The Problem

Anything that "looks like a public API" — exported functions, example folder code, documentation samples — once depended on by users / contributors becomes a de-facto contract (Hyrum's Law). If you don't declare stability explicitly, it's **assumed stable by default**.

### 5.2 Solution: Stability Markers

Cross-package / cross-module exports must declare stability in a doc comment:

```ts
/**
 * Creates a task.
 *
 * @stable since 0.3.0
 */
export function createTask() {}

/**
 * Internal task validation. Schema and behavior may change without notice.
 *
 * @experimental
 * @internal
 */
export function _validateTaskShape() {}

/**
 * @deprecated since 0.5.0, use `createTaskV2`. Removed in 1.0.0.
 */
export function createTaskLegacy() {}
```

### 5.3 Boundary vs Internal

| Class | Marker | Commitment |
|---|---|---|
| `@stable` | semver-compatible; breaking changes require a major version | strong |
| `@experimental` | may change in a minor version; users must watch the changelog | medium |
| `@internal` | no stability promise; external use is at-your-own-risk | none |
| `@deprecated` | scheduled-for-removal, with replacement | reverse commitment |

### 5.4 Examples and Docs Need Markers Too

example-folder code looks "officially recommended". If it uses an internal API, **say so explicitly in a comment**:

```ts
// example/advanced.ts

// NOTE: this example uses _validateTaskShape (internal API).
// It exists to demonstrate the validation hook design;
// production code should use the stable createTask() flow above.
import { _validateTaskShape } from "../src/internal";
```

---

## 6. Single Glue Layer

### 6.1 Promote "Single Interface Definition" to Cross-Process / Cross-Language

Each **cross-process / cross-language** channel can only have one definition. See "let me build a second one" → red light.

### 6.2 Examples

| Project context | Existing glue | Forbidden |
|---|---|---|
| Already has an MCP server doing stdio JSON-RPC | `crates/evox-mcp` | Building a second IPC / socket / private RPC for hot-reload |
| Already has a unified IM channel layer | `evox-channels` | Reaching past the trait to wire a new platform directly into the trunk |
| Already has a plugin loader | `extensions/loader.ts` | Spawning a child process for one specific ext to communicate |

### 6.3 Prerequisites for Building a New Glue

1. Per §2, list concrete shortcomings of the existing glue (with file:line)
2. Explain why **extending the existing layer** doesn't work
3. Take the decision to the user before acting

---

## 7. Gate 1 Full Checklist

Before sending an architecture / direction reply, walk:

- [ ] **Decomposition**: user's conclusion decomposed into ≥ 3 independent dimensions, each verdicted
- [ ] **Anchors**: reply contains 1–3 file:line / config / metric anchors
- [ ] **Retraction**: conflicts with prior suggestions in this session are flagged with "Retract X"
- [ ] **Temporal**: now / later split is clear; post-v1 is placeholder + trigger only
- [ ] **Boundary**: new public symbols carry stability markers
- [ ] **Single glue**: new cross-process channels don't violate the single-glue rule

Any unchecked → reply is non-compliant; redo.

---

## 8. Full Decision-Reply Template

```markdown
## Decomposition
Your request "<conclusive directive>" decomposes into N dimensions:
1. **<dim 1>**: <verdict + anchor>
2. **<dim 2>**: <verdict + anchor>
3. ...

Pending (need your confirmation):
- <undecided 1>
- <undecided 2>

## Evidence Anchors
- `<file>:<line>`: <snippet or current state>
- Metric / config: <specific value>
- Existing doc: <reference>

## Retraction (if any)
**Retract** <previous keyword>: <why>. <replacement>.

## Now / Later
**Now**:
- <capability 1>
- <capability 2>

**Later** (placeholder + trigger):
- <capability X>, trigger: <specific condition>

## Commitment Boundary
New public symbols:
- `<symbolA>` @stable
- `<symbolB>` @experimental

## Next Step
With this decomposition confirmed, I'll start dimensions 1 + 2 and enter Gate 2 incremental delivery.
```
