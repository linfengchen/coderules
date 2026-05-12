---
name: aicoding
description: Enforce four quality gates during intent-driven AI coding ("vibe coding") so that code is delivered fast AND to a high standard. Use when the user gives a natural-language intent to write a new feature / change architecture / generate UI / refactor a module; use when you're about to write 100+ lines of code at once; use when you're drawing frontend UI in React/Vue/Svelte; use when you're unsure whether to spec / plan / test first. NOT for one-line edits, comment fixes, Q&A, or debugging existing bugs (use the corresponding specialized skill).
---

# Vibe Coding Craft

## Overview

The common failure mode of "vibe coding": user says one sentence → AI dumps 500 lines at once → it appears to run → naming is sloppy / design has heavy "AI flavor" / edge cases untested / changing one thing breaks three. This skill cuts that path into **4 gates**, each with a quantifiable exit condition that cannot be hand-waved past.

Four gates (every change must pass them in order):

```
  DECIDE ────▶ BUILD ────▶ VERIFY ────▶ POLISH
  ┌──────┐   ┌──────┐   ┌──────┐   ┌──────┐
  │decis-│   │incre-│   │5-axis│   │taste │
  │ion   │   │mental│   │review│   │polish│
  │hygi- │   │       │   │       │   │       │
  │ene   │   │       │   │       │   │       │
  └──────┘   └──────┘   └──────┘   └──────┘
   decompose  ≤100 LOC   5 axes     anti-AI
   anchor     1 slice    e2e         a11y/states
```

Any gate not passing → **Stop the line**. No advancing to the next gate.

## When to Use

- User gives a natural-language intent to generate a new feature, component, or module
- Change spans ≥ 2 files and is projected to ≥ 100 lines
- Touches UI / frontend components / styling
- Touches public APIs / exported types / package boundaries
- You "feel like" you should write it all at once → **must** enter DECIDE first

## When NOT to Use

- Single file, single function, < 30 line change → just do it
- Bug fix / chasing a build error → use `debugging-and-error-recovery`-style root-cause investigation
- Answer / explain code → just answer
- Already have a spec + plan → skip DECIDE, start at BUILD

---

## Gate 1 — DECIDE (Decision Hygiene)

Mandatory before writing code. Borrowed from local `engineering-lifecycle` rule (Decision §A — claim decomposition / evidence anchors / explicit retraction / temporal layering / commitment boundary).

### 1.1 Claim Decomposition

When the user gives a conclusive directive ("do X / don't do Y"), **first list the 3–5 independent dimensions it covers at the implementation layer**, then verdict per dimension. **Do not** generate todos along the conclusion before decomposition.

Example:
> User: "Add user login to this project"

❌ One-line dump of OAuth + DB + middleware + UI all at once.

✅ Decompose:
1. Auth strategy (session / JWT / OAuth provider)
2. User storage (existing user table? fields sufficient?)
3. Middleware (route protection, role-based?)
4. UI (login page, signup page, forgot password?)
5. Security (password hashing, rate limiting, CSRF)

Verdict each dimension independently; if some need user adjudication, stop and ask first.

### 1.2 Evidence Anchors

Before any architectural call, you must produce **1–3 concrete anchors**:
- Code reference: `src/auth/handler.ts:42`
- Config: `package.json` line N
- Current metric: bundle 200 kB / 150 tests

❌ "It looks like the existing hooks are not flexible enough"
✅ "`useFetch.ts:12-30` hardcodes retry to 3 with no per-call override → add an optional parameter"

No anchor → you're guessing, not designing.

### 1.3 Explicit Retraction

When you discover within the same session that a previous suggestion contradicts new evidence, **mark explicitly**:

> **Retract** \<previous-keyword\>: \<why\>. \<replacement\>.

No silent reversals.

### 1.4 Temporal Layering (YAGNI Across Time)

Split into **now / later**:
- **now**: capabilities this PR must land, backed by user demand
- **later**: only a placeholder + one-line trigger condition. Forbidden to ship the negotiation protocol / version matrix / extension point now.

> "Maybe needed later" is **not** a reason to ship — it's a reason to **leave a placeholder**.

### 1.5 Commitment Boundary

For any symbol that looks like a public API (exported function, doc example, example folder), the **doc comment must explicitly declare stability**: `@stable` / `@experimental` / `@internal`.

### Gate 1 Exit Checklist

- [ ] User's conclusion decomposed into ≥ 3 independent dimensions, each verdicted
- [ ] Reply contains 1–3 file:line / config / metric anchors
- [ ] Conflicts with prior suggestions are flagged with "Retract X"
- [ ] now / later boundary is clear; later content is placeholder-only
- [ ] New public symbols carry stability markers

Details: [`references/decision-hygiene.md`](./references/decision-hygiene.md).

---

## Gate 2 — BUILD (Incremental Delivery)

In one sentence: **vertical slice + test the slice + commit the slice**. Borrowed from addyosmani `incremental-implementation`.

### 2.1 Slice Loop

```
Implement ──▶ Test ──▶ Verify ──▶ Commit ──▶ Next
```

Each slice must satisfy:
- **End-to-end runnable**: DB → API → UI works end-to-end (even if only one field is supported)
- **≤ 100 net new lines** (excluding generated)
- **Build / test green before commit**

❌ Write 5 components + 3 hooks + 2 APIs at once → test together
✅ Write the smallest path to create a task → test → commit → then add list

### 2.2 Quantitative Hard Limits (Violation = Rewrite)

| Granularity | Soft cap | **Hard cap** | If exceeded |
|---|---|---|---|
| Single file | 400 lines | **500 lines** | Split by responsibility + barrel re-export |
| Single function | 80 lines | **120 lines** | Extract a helper |
| Nesting depth | 2 | **3** | early return / guard clause |
| Single commit | 80 net new | **100 net new** | Split into two slices |
| Single PR | 300 lines | **1000 lines** | Stack PRs |

### 2.3 Naming Discipline

- **Banned uninformative words**: `data` / `result` / `tmp` / `info` / `item` / `manager` / `helper` / `util` (unless the project already established `*Helper.ts` naming)
- **Names convey "what + why"**: `pendingTaskCount`, not `count`
- **Predicate functions**: prefixed `is*` / `has*` / `can*` / `should*`
- **Side-effect functions**: verb-first (`createTask` / `flushQueue`); forbidden: `getX()` that mutates

### 2.4 Error-Handling Discipline

- **No empty catch / `unwrap()` / `_ = ...`**: every catch must satisfy at least one of
  1. logger record + `[module-name]` prefix
  2. comment explaining **why ignoring is safe** (`// ignore` alone is not enough)
  3. error rethrow / propagation
- **Cross-package public APIs forbid `any` / `unwrap()`**: internal helpers may use them
- **Validate at boundaries**: API handler / form / third-party response must schema-validate; **internal functions trust types**

### 2.5 Single Interface Definition

- One interface / type defined in exactly one package / module; everywhere else uses `import type`
- See "I'll add an adapter to bridge two similar definitions" → red light, return to Gate 1 for decomposition
- Barrel files (`index.ts` / `mod.rs` / `__init__.py`) only re-export — no business logic

### 2.6 Scope Discipline (Critical)

**Only modify code the task asks for.** When you spot adjacent improvements:
- Don't "tidy" along the way
- Don't fix imports you weren't asked to fix
- Don't delete comments you don't fully understand
- Don't "modernize" syntax

If you find issues that need fixing → list them and ask the user: "Should we open new tasks for these?"

### Gate 2 Exit Checklist

- [ ] Each commit has build + test green before commit
- [ ] File ≤ 500 lines / function ≤ 120 lines / nesting ≤ 3
- [ ] Single commit ≤ 100 net new lines
- [ ] No `data` / `tmp` / `info` in names
- [ ] Every catch has logger + `[module]` prefix or an explicit safe-ignore comment
- [ ] Interfaces / types defined once; barrel re-exports complete
- [ ] No code touched outside task scope

Details: [`references/code-craft.md`](./references/code-craft.md).

---

## Gate 3 — VERIFY (5-Axis Review)

Mandatory after any PR / large change is complete. Borrowed from addyosmani `code-review-and-quality`.

### 3.1 The Five Axes

Self-check each change in this order:

1. **Correctness**: does it implement the spec? are null / empty / boundary values handled? error paths covered?
2. **Readability**: can an unfamiliar engineer read it without explanation? names follow §2.3? nesting flat?
3. **Architecture**: follows existing patterns? no circular dependencies? abstraction levels reasonable? interfaces defined once?
4. **Security**: user input validated? secrets out of source? external data treated as untrusted?
5. **Performance**: N+1? unbounded loops? sync that should be async? unnecessary frontend re-renders?

### 3.2 End-to-End Gate (from local `engineering-lifecycle`, phase B)

Before claiming "done", **mandatory**:

1. **Full review**: file-by-file diff review (not just commit message)
2. **Build consistency**: compile / type check / lint all green
3. **Trigger one real business flow**:
   - Backend: actual request + check response
   - Frontend: actual render + actual interaction
   - Integration: trigger real end-to-end events; verify all key log markers appear
4. Inspect produced artifacts (DB rows, generated files, log entries) match expectations

**Reading the code logic alone and claiming "done" = not passing.**

### 3.3 Review-Feedback Severity

When writing review comments or self-reviewing, label severity to avoid "everything is mandatory":

| Tag | Meaning |
|---|---|
| `Critical:` | Blocks merge (security / data loss / broken function) |
| *(no prefix)* | Must fix |
| `Optional:` | Suggested but not required |
| `Nit:` | Style / personal preference |
| `FYI:` | Informational only |

### Gate 3 Exit Checklist

- [ ] Each axis has a concrete one-sentence verdict (not "looks OK")
- [ ] End-to-end flow has actually run; outputs match expectations
- [ ] Key tests + log markers recorded in delivery
- [ ] All Critical and must-fix cleared; Optional / Nit annotated with reason if skipped

---

## Gate 4 — POLISH (Taste Polish)

Code that runs ≠ code that ships. This gate targets "AI flavor".

### 4.1 Anti-AI-Aesthetic Checklist (Frontend / Visual)

| AI default | Why it's a problem | Production approach |
|---|---|---|
| Purple / Indigo gradient | Model fallback palette; every AI app looks the same | Use the project's actual design tokens |
| `rounded-2xl` everywhere | "Friendly" signal that destroys the rounding hierarchy | Follow the design system's rounding scale |
| Heavy shadows / `shadow-xl` | Visual noise competing with content | Only where the design system explicitly calls for it |
| Giant padding / `p-12` | Wrecks visual hierarchy, wastes space | Use a consistent spacing scale (4 / 8 / 12 / 16 / 24) |
| Generic hero section | Templated, unrelated to actual content | Content-driven layout |
| Lorem ipsum | Hides real content-length issues | Use representative real data |
| Centered card grid | No information hierarchy; everything "equally important" | Layout by importance |
| Decorative emoji | Unprofessional in most production contexts | Use the design system's icon set |
| Arbitrary pixel values (`13px` / `2.3rem`) | Off the spacing scale | Stay on the scale |

### 4.2 Production-Grade UI Requires Four States

Any component rendering data must explicitly handle:

```
Loading  →  Empty  →  Error  →  Success
  ↓          ↓          ↓          ↓
skeleton   guidance   retryable   actual content
+aria-busy +CTA       +error code +a11y
```

❌ Blank screen while loading; crash on error; "show nothing" when array is empty.
✅ All four drawn, viewed, keyboard-tested.

### 4.3 a11y Floor (WCAG 2.1 AA)

- Interactive elements **keyboard-reachable** (Tab through, Enter/Space activates)
- Icon-only buttons get `aria-label`
- Form inputs paired with `<label htmlFor>` or `aria-label`
- Color is **not** the sole information carrier (red/green needs text or icon)
- Text / background contrast ≥ 4.5:1 (large text ≥ 3:1)
- Focus visible (no `outline: none` without a replacement)

### 4.4 Docs / Comments Floor (per Google Style)

- **Cross-package / cross-module exports**: must have a doc comment (JSDoc / rustdoc / docstring), with a one-line description + at least one usage example
- **TODO format**: `// TODO(owner): description (#issue)` — missing owner or issue → treated as residue
- **Comments only explain why**: don't restate what the code does. `// increment counter` → delete
- **Deprecation**: `@deprecated since X.Y.Z, use <replacement>, removed in A.B.C` — missing replacement or schedule → residue

### 4.5 Imports — Three-Segment Layout (per Google Style)

```
[stdlib / language built-ins]

[third-party deps]

[this repo / relative paths]
```

One blank line between segments; alphabetized within each; no wildcard imports; TS type dependencies use `import type`.

### Gate 4 Exit Checklist

- [ ] No purple gradient, no `rounded-2xl` overuse, no arbitrary pixels
- [ ] All data components have all four states (loading / empty / error / success)
- [ ] Tabbed once with keyboard + tried with screen reader
- [ ] Cross-module exports carry doc comments + usage examples
- [ ] TODOs have owner + issue
- [ ] Imports follow three-segment + alphabetical

Details: [`references/design-craft.md`](./references/design-craft.md).

---

## Common Rationalizations (Unified Rebuttal Table)

| Excuse | Reality |
|---|---|
| "It's vibe coding — get it running first" | "Get it running first" = 100 lines later nobody can read it, change one thing breaks three. This skill exists for that mindset. |
| "Let me write it all and test at the end" | Bugs compound. Slice 1 bugs make Slice 2–5 wrong; final debug time is 5× the slice cost. |
| "This abstraction will be useful later" | YAGNI temporal version: later = placeholder + trigger condition, not now. |
| "I'll fix the names later" | You won't. Once a name spreads to 5 call sites, rename cost doubles. Sub-par now → fix now. |
| "Tests are too much; I tested manually" | Manual misses edges, isn't repeatable, can't regress. At minimum, write one minimal regression test. |
| "User didn't ask for that strictness" | User wants results, not process. This skill is the floor for output **quality**, not over-engineering. |
| "AI aesthetic looks fine too" | It's the synonym for "instantly identifiable as AI". Senior reviewers spot it as low quality. |
| "I'll be careful next time" | "Next time" doesn't exist. Fix this change in this change. |
| "Wrap it for future extensibility" | No second caller exists yet → don't wrap. Abstract on the third use case (Rule of Three). |
| "Tidying adjacent code while I'm in the import" | Out of scope. Scope rule: list it and ask, don't do it on the way. |

---

## Red Flags (Any One = Stop)

- A single commit ≥ 100 net new lines
- File > 500 / function > 120 / nesting ≥ 4
- Variable names like `data` / `tmp` / `info` / `result`
- Empty catch / bare `unwrap()` / `as any`
- Same interface / type defined in two places + an adapter to bridge them
- A component touched but no loading / empty / error states drawn
- UI shows `rounded-2xl` everywhere / purple gradient / `p-12` overuse
- Claiming "done" without running end-to-end
- Decision reply has no file:line anchor
- Change exceeded task scope ("tidied along the way")
- Cross-package exports lack doc comments
- TODO has no owner / issue

---

## Final Verification (Last Pass Before Delivery)

```markdown
## DECIDE
- [ ] User conclusion decomposed
- [ ] 1–3 evidence anchors
- [ ] Conflicts with prior explicitly retracted
- [ ] now / later boundary clear
- [ ] Public symbols carry stability markers

## BUILD
- [ ] Slice commits, each with build/test green
- [ ] File / function / nesting / commit quantitative limits all pass
- [ ] Naming + error handling + single interface + scope discipline all pass

## VERIFY
- [ ] 5-axis self-review complete; each axis has a concrete verdict
- [ ] End-to-end real flow has actually run
- [ ] Critical / must-fix cleared

## POLISH
- [ ] No AI flavor in visuals
- [ ] All data components have all four states
- [ ] a11y keyboard + contrast pass
- [ ] Cross-module docs + TODO format + three-segment imports
```

Any unchecked → not done; return to the corresponding gate.

---

## Cross References

- [`references/decision-hygiene.md`](./references/decision-hygiene.md) — full Gate 1 (decomposition deep dive + real examples)
- [`references/code-craft.md`](./references/code-craft.md) — full Gate 2 (naming / comments / error handling / testing / language details)
- [`references/design-craft.md`](./references/design-craft.md) — full Gate 4 (design system / a11y / micro-interactions / anti-AI patterns deep dive)
- This repo's three universal layers are the **callee**; this skill is the **caller**:
  - `../common/clean-code-core.mdc` / `architecture.mdc` / `engineering-lifecycle.mdc` / `comments-docs.mdc` / `imports.mdc` / `security-guide.mdc` / `testing-principles.mdc` / `error-handling.mdc`
  - `../lang/clean-code-typescript.mdc` / `clean-code-rust.mdc` / `rust-fmt-discipline.mdc` / `typescript-testing.mdc`
  - `../patterns/multi-worktree.mdc` / `plugin-architecture.mdc` / `im-bot-integration.mdc` / `memory-mcp-discipline.mdc` / `persona-architecture.mdc` (architectural patterns; trigger when relevant)
  - The consuming project's own `.cursor/rules/project/<name>.mdc` (project-specific bindings; written per-project, see `../examples/project-binding/` for templates)
