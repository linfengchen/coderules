# Regression Test Plan (6th Cut)

This document is **how we verify the rule set works** — not a rule itself. It is the 6th and final cut of the v2 restructure.

The first 5 cuts were structural:

| Cut | Action | Status |
|---|---|---|
| 1 | Initial restructure into `common/ lang/ project/` | ✅ done |
| 2 | Split `project-standards.mdc` → `quality-gates` + `security-guide` + `project/trunk.mdc` (later moved to `examples/`) | ✅ done |
| 3 | Extract `error-handling.mdc` from `architecture` + `clean-code-typescript` + `clean-code-rust` | ✅ done |
| 4 | Fill Google-Style gaps: `comments-docs` + `imports` + `testing-principles` | ✅ done |
| 5 | Downgrade unnecessary `alwaysApply: true` to `false` (memory / project-scope rules) | ✅ done |
| **6** | **Regression test the rules in real sessions** | **plan below** |

A 7th cut followed in v2.2: extracted architectural patterns from `project/` to a new `patterns/` layer so other projects can adopt the rules without inheriting foreign paths or tool names.

An 8th cut in v2.3 capped the always-on tier at **≤ 7 files / ~9K tokens** by demoting 6 files from `alwaysApply: true` → `false`.

A 9th cut in v2.4 dropped `project/` entirely from the rule pack: bindings moved to `examples/project-binding/` as `.md` templates (Cursor only loads `.mdc`). Consuming repos keep real values under their own `.cursor/rules/project/`. Always-on tier in `coderules/` is **≤ 6 files / ~7K tokens**. See INDEX migration map.

---

## 1. Goal

Confirm that the v2 + English-translation rule set:

1. **Triggers correctly** in Cursor / Claude Code / other agents
2. **Produces the expected behavior** in real coding sessions (no rule degradation vs v1)
3. **Saves tokens** (English unification benefit) without losing instruction-following quality
4. **Cross-references resolve** for both humans and agents

---

## 2. Test Matrix

Six scenarios that together touch all three universal layers (`common/` + `lang/` + `patterns/`) and the `aicoding/` skill. Project-binding cooperation is tested in a separate consuming project (see T3 caveat).

| ID | Scenario | Expected to trigger | Why this scenario |
|---|---|---|---|
| **T1** | Decision hygiene / lifecycle check: ask the agent "give me a plan to add OAuth login to this project" | `aicoding/SKILL.md` (Gate 1) + `common/engineering-lifecycle.mdc` §A | Verify claim decomposition + evidence anchors flow |
| **T2** | Edit a `.rs` file with a bare `unwrap()`, ask the agent to review | `lang/clean-code-rust.mdc` + `common/error-handling.mdc` (via reference) + `lang/rust-fmt-discipline.mdc` | Verify the dedupe via reference still triggers `error-handling` discipline |
| **T3** | In a **separate** consuming project that copied `examples/project-binding/im-feishu-sample.md` → `.cursor/rules/project/<bridge>-sdk.mdc`: add a chat-bridge handler under `extensions/<bridge>/` that empty-catches | `patterns/plugin-architecture.mdc` + `patterns/im-bot-integration.mdc` + the project's binding + `common/error-handling.mdc` | Verify pattern + project-binding cooperation works **outside** `coderules/` |
| **T4** | Refactor a 800-line .ts file into smaller modules | `common/refactoring-guidelines.mdc` (desc-triggered) + `lang/clean-code-typescript.mdc` | Verify desc-triggered rules fire on intent (not always-on) |
| **T5** | Generate a React dashboard component without a design system | `aicoding/SKILL.md` (Gate 4) + `aicoding/references/design-craft.md` | Verify anti-AI-aesthetic rules + four-state requirement triggers |
| **T6** | Ask "how should we structure a new chat-platform integration for Discord?" in a fresh repo | `patterns/im-bot-integration.mdc` must stay vendor-neutral in body text | Discord plan must not silently import another vendor's env vars / emoji tables from a sample binding |

---

## 3. Per-Test Pass Criteria

### T1 — Decision Hygiene

**Prompt**: "Add OAuth login to this Express + Postgres project."

**Pass**:
- Reply contains a numbered decomposition with ≥ 3 dimensions (auth strategy / storage / middleware / UI / security)
- Reply contains ≥ 1 evidence anchor (file:line or grep result)
- Reply explicitly marks "now / later" boundary
- Reply asks for user adjudication on at least one undecided dimension before generating code

**Fail**:
- Agent dumps OAuth code without decomposition → Gate 1 not triggered
- No file:line anchors → evidence-anchor rule not enforced

### T2 — Rust Error Handling

**Setup**: a `.rs` file with `let port: u16 = env::var("PORT").unwrap().parse().unwrap();`

**Prompt**: "Review this for issues."

**Pass**:
- Reply flags the bare `unwrap()` as a violation
- Reply suggests `Result + ? + map_err` pattern
- Reply references `common/error-handling.mdc` or its discipline (no swallowed errors / module-prefix log line)
- If asked, the agent runs `cargo fmt --all -- --check` per `lang/rust-fmt-discipline.mdc`

**Fail**:
- Agent says "looks fine" → error-handling rule didn't trigger
- Agent rewrites with `unwrap_or` but doesn't surface the discipline → cross-reference broken

### T3 — Chat-bridge project overlay

**Setup**: a handler with `try { sendCard(); } catch {}` under `$AGENT_HOME/extensions/<bridge>/handler.ts` (path from **your** binding).

**Prompt**: "Improve error handling here."

**Pass** (in the consuming project that has loaded its own `project/<bridge>-sdk.mdc`):
- Reply requires writing errors appropriately for the host environment (e.g. file append for TUI) per **your** project's binding (`examples/project-binding/monorepo-trunk-sample.md` sketches where to document this)
- Reply includes the `[<bridge>]` module prefix per `common/error-handling.mdc#2-module-prefixed-log-lines`
- If suggesting an IM-platform API call, reply references the platform's official API doc URL pattern from the consuming project's binding (compare `examples/project-binding/im-feishu-sample.md` for shape)

**Fail**:
- Agent suggests `console.error` despite TUI environment → project-binding overlay didn't trigger
- Agent uses Unicode emoji instead of the platform's emoji code (e.g., `:THUMBSUP:`) → IM-binding didn't trigger

### T4 — Refactoring (desc-triggered rule)

**Setup**: a `.ts` file ~800 lines mixing types, validation, and HTTP handlers.

**Prompt**: "This file is too big — refactor it."

**Pass**:
- Agent first reads `common/refactoring-guidelines.mdc` (was demoted to desc-triggered in v2.3) before proposing splits
- Reply proposes barrel + delegation split per `common/refactoring-guidelines.mdc#barrel-delegation-pattern`
- Reply does NOT remove existing exports during the split (compat layer at the old path)
- Reply suggests an incremental commit plan (~100 lines per commit)

**Fail**:
- Agent rewrites the file in-place without barrel pattern → desc-trigger didn't fire
- Agent removes old exports immediately → didn't read refactoring-guidelines, broke importers

### T5 — Frontend Anti-AI Aesthetic

**Prompt**: "Design a tasks dashboard component for our React app. We don't have a design system yet."

**Pass**:
- Reply pauses before coding to ask whether to design a minimum token set first per `aicoding/references/design-craft.md#71-project-has-no-design-system`
- Reply does NOT ship `bg-gradient-to-r from-purple-500 to-pink-500` or `rounded-2xl` everywhere
- Reply explicitly draws all four states (loading / empty / error / success) per Gate 4
- Reply addresses keyboard a11y + contrast per WCAG 2.1 AA

**Fail**:
- Reply ships purple gradient + `p-12` everywhere → anti-AI aesthetic rule not triggered
- Reply only renders the success state → four-state rule not triggered

### T6 — Pattern Portability (Patterns Layer Sanity)

**Setup**: a fresh repo with only `common/` + `lang/` + `patterns/` linked under `.cursor/rules/`. **No `project/` layer at all.** (This is the default `coderules/` shape.)

**Prompt**: "I want to add a Discord chat bot to this project. How should I structure it?"

**Pass**:
- Reply pulls `patterns/im-bot-integration.mdc` — references WebSocket bridge / event dispatch / typing indicator / pagination / tool grouping
- Reply does NOT mention placeholder signal tokens from unrelated sample bindings (e.g. another chat vendor's internal bridge codename when the prompt was Discord-only)
- Reply also pulls `patterns/plugin-architecture.mdc` if the project has a host
- Reply prompts the user to define the Discord-specific binding (env var names, native emoji enum, receive-id prefixes)

**Fail**:
- Reply leaks Feishu-specific terminology → pattern extraction was incomplete; revisit `patterns/im-bot-integration.mdc`
- Reply hardcodes Slack-isms → similarly leaked

---

## 4. Quantitative Token Comparison

For verifying the English-translation benefit:

```bash
cd "$CODERULES_ROOT"   # clone path on your machine

# Total file size as byte proxy (rough)
wc -c common/*.mdc lang/*.mdc patterns/*.mdc

# More accurate: use tiktoken or an LLM-tokenizer
python3 -c "
import tiktoken
enc = tiktoken.get_encoding('cl100k_base')
import os, glob
total = 0
for path in sorted(glob.glob('common/*.mdc') + glob.glob('lang/*.mdc') + glob.glob('patterns/*.mdc')):
    with open(path) as f:
        n = len(enc.encode(f.read()))
        print(f'{n:>6}  {path}')
        total += n
print(f'{total:>6}  TOTAL')
"
```

**Expected**: total token count drops by 25–35% vs the v2 (Chinese) snapshot. If the drop is < 15%, the translation has too much retained Chinese — investigate.

---

## 5. Cross-Reference Sanity

Run before declaring "regression done":

```bash
cd "$CODERULES_ROOT"
rg -n '[a-z-]+\.mdc' --no-heading | sort -u > /tmp/refs.txt

# 2. List every .mdc file actually present
find . -name '*.mdc' | sed 's|^\./||' | sort -u > /tmp/files.txt

# 3. For each reference, check the target exists (basename match — Cursor resolves by basename)
while read -r line; do
    target=$(echo "$line" | grep -oE '[a-z-]+\.mdc' | head -1)
    if ! grep -q "/${target}$" /tmp/files.txt 2>/dev/null && ! grep -qx "${target}" /tmp/files.txt 2>/dev/null; then
        echo "BROKEN: $line"
    fi
done < /tmp/refs.txt
```

**Pass**: zero `BROKEN:` lines (placeholders like `<language>.mdc` and `<name>.mdc` are expected and benign).

---

## 6. Frontmatter Distribution Check

```bash
echo "alwaysApply: true   →"
rg -l 'alwaysApply: true' --type-add 'mdc:*.mdc' -t mdc

echo
echo "alwaysApply: false  →"
rg -l 'alwaysApply: false' --type-add 'mdc:*.mdc' -t mdc
```

**Expected distribution (v2.6+ — lifecycle merge)**:
- `alwaysApply: true` (always-on tier, ≤ 6 files / ~7K tokens — **five** in upstream `common/`):
  - `common/clean-code-core.mdc`
  - `common/architecture.mdc`
  - `common/engineering-lifecycle.mdc`
  - `common/error-handling.mdc`
  - `common/security-guide.mdc`
- `alwaysApply: false` (everything else): see INDEX.md for exact counts (`lang/` + `patterns/` + triggered `common/`)
- `examples/project-binding/*.md`: not loaded by Cursor (extension is `.md`, not `.mdc`)

If a non-listed `common/` file is `true`, the total `alwaysApply: true` count must still stay ≤ 6 within `coderules/`. Consuming projects may add ≤ 1 always-on `project/` trunk for total ≤ 7.

---

## 7. Manual A/B Smoke (Optional but Recommended)

For each of T1–T5:

1. Run with **v1** rules (the original flat layout, Chinese)
2. Run with **v2.1** rules (this 3-layer English layout)
3. Compare:
   - Time to first useful suggestion
   - Number of clarifying questions asked
   - Whether the agent self-references the right rule file
   - Final code quality (file size, error handling, naming, four-state UI completeness)

If your project has a memory-MCP binding (shape per `examples/project-binding/memory-mcp-sample.md`), record outcomes with signals like:
- `rule_set_v2_4` / `coderules_pure_template` / `decision_hygiene_triggered` / `error_handling_dedupe`
- `summary`: "Rule set v2.4 dropped project/ from coderules; bindings now live in consuming repo"

---

## 8. Acceptance Criteria for "v2.2 Regression Done"

- [ ] All 6 test scenarios T1–T6 pass on Cursor (or the agent platform of choice)
- [ ] Token comparison shows ≥ 15% reduction (target: 25–35%)
- [ ] Cross-reference sanity scan reports zero broken references
- [ ] Frontmatter distribution matches the expected table in §6
- [ ] No regression in user-facing reply quality (consuming project's binding still controls reply language; the `coderules/` rule pack is language-neutral)
- [ ] T6 specifically: Discord plan avoids importing another vendor's sample constants unless the user asked for them

When all checked → mark regression stable for this rule-pack revision. Optionally record lessons in **your** memory MCP (if configured) so future upkeep has recall signal.

---

## 9. Known Open Items (Defer to v2.2 or v3)

These were noticed during the cuts but **not** addressed; documented here so they don't get forgotten:

1. **Section-anchor precision**: many cross-references use loose anchors (`#strict-type-boundaries` for "## Strict Type Boundaries (Public-API Tightening)"). GitHub / Cursor markdown viewers do prefix matching, so these work for humans, but a strict anchor walker would flag them. Cleanup is mechanical but tedious — defer.

2. **Per-language testing files**: only `lang/typescript-testing.mdc` exists. When Python / Go / Java come online, add `lang/python-testing.mdc` etc. so `common/testing-principles.mdc` continues to be the language-agnostic source.

3. **Per-language `error-handling-<lang>.mdc`**: currently the language-specific syntax lives inline in `lang/clean-code-<lang>.mdc#error-handling`. If the discipline grows substantially, split into `lang/error-handling-<lang>.mdc`.

4. **Rule-pack lint script**: write a `scripts/lint-rules.sh` that runs §5 + §6 in CI / pre-commit. Today this is manual.
