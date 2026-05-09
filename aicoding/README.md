# Vibe Coding Skill

Internal-use agent skill that turns "vibe coding" sessions into production-grade output. **Same speed, much higher quality.**

> Inspiration: the process-first paradigm of [`addyosmani/agent-skills`](https://github.com/addyosmani/agent-skills) + this repo's `.mdc` codification of "decision hygiene / quantitative limits / end-to-end gates".

## What It Solves

The standard failure path of vibe coding:

```
User says one sentence  →  AI dumps 500 lines  →  appears to run  →
sloppy names / heavy AI flavor / edges untested / change one breaks three
```

This skill cuts that path into 4 gates, each with a quantifiable exit condition:

```
DECIDE  ──▶  BUILD  ──▶  VERIFY  ──▶  POLISH
decompose    ≤100 LOC    5-axis review  anti-AI flavor
anchor       limits      e2e tests      a11y / states
```

## File Structure

```
aicoding/
├── SKILL.md                          ← main entry; agents load this
├── README.md                         ← you are reading this
└── references/
    ├── decision-hygiene.md           ← full Gate 1 (exclusive)
    ├── code-craft.md                 ← full Gate 2
    └── design-craft.md               ← full Gate 4
```

`SKILL.md` is the entry (~400 lines); references load on demand — progressive disclosure.

## Install / Enable

See the top-level [`../README.md`](../README.md) for install instructions across Cursor / Claude Code / Codex / Gemini. The skill ships alongside the rule pack and is normally installed together.

If you only want this skill (without the `common/ lang/ patterns/` rule layers):

```bash
# Claude Code
mkdir -p ~/.claude/skills && ln -s "$(pwd)/aicoding" ~/.claude/skills/aicoding

# Cursor (in your repo)
mkdir -p .cursor/rules && ln -s "$(pwd)/aicoding" .cursor/rules/aicoding

# Gemini CLI
gemini skills install ./aicoding
```

## Triggers (in the frontmatter)

The agent activates automatically when:

- The user gives a natural-language intent to generate a new feature / change architecture / generate UI / refactor a module
- You're about to write 100+ lines at once
- You're touching React / Vue / Svelte UI
- You're unsure whether to spec / plan / test first

It will **not** activate for (use the corresponding specialized skill):

- Single-line edits, comment fixes, Q&A
- Debugging an existing bug (use a debugging skill)

## Relationship to This Repo's Rule Layers

This skill **does not replace** the existing rule files — it's their **caller**:

| Layer | Files | How this skill references them |
|---|---|---|
| `common/` | `clean-code-core` / `architecture` / `decision-hygiene` / `quality-gates` / `error-handling` / `security-secrets` (always-on) | Source of Gates 1–3 quantitative limits + discipline |
| `common/` | `comments-docs` / `imports` / `refactoring-guidelines` / `testing-principles` (triggered) | Gate 2 / Gate 4 details |
| `lang/` | `clean-code-typescript` / `clean-code-rust` / `rust-fmt-discipline` / `typescript-testing` | code-craft language specifics |
| `patterns/` | `multi-worktree` (pre-flight) / `plugin-architecture` / `im-bot-integration` / `memory-mcp-discipline` / `persona-architecture` | Architectural pattern reference, when relevant |
| Consuming project's `.cursor/rules/project/` | Project-specific bindings (template: `../examples/project-evox/`) | Concrete values that bind patterns to the host project |

## Relationship to [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills)

This skill **learns its form, fills its gaps**:

| Dimension | addyosmani | This skill |
|---|---|---|
| Paradigm | Process > Prose ✓ | Inherited |
| Anti-rationalization table | Strong ✓ | Inherited |
| Red flags + Verification | Strong ✓ | Inherited |
| Decision-phase hygiene | Missing | **Filled** (Gate 1 fully borrowed from this repo's `common/decision-hygiene.mdc`) |
| End-to-end gate | Scattered | Concentrated in Gate 3 |
| Anti-AI-aesthetic checklist | Present | Further refined (rounding / shadows / spacing scale) |
| Quantitative hard limits | Partial (~100 lines) | **Concentrated** (500/120/3/100) |

## Usage Recommendations

1. **New onboards**: read `SKILL.md` first, references on demand
2. **During execution**: have the agent walk the `Final Verification` checklist before delivery
3. **Code review**: use Gate 3 5-axis + Gate 4 design checklist as the review checklist
4. **Continuous improvement**: after a few runs, add common rationalizations to `SKILL.md`'s table

## Maintenance

- Keep `SKILL.md` ≤ ~400 lines (token economics)
- Keep each reference ≤ ~250 lines
- Changes must preserve every "Use when" trigger condition in the frontmatter `description`

## License

Used under the repo's license. This skill draws extensively from MIT-licensed `addyosmani/agent-skills`.
