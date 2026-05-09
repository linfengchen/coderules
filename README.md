# coderules

A project-agnostic, layered Cursor/Claude-Code rule pack — universal coding principles + language-specific syntax + reusable architectural patterns + a `aicoding` agent skill.

> What lives here, what does not: this repo ships **rules and a skill**. Project-specific bindings (paths, env vars, API URLs) belong in your **own** repo's `.cursor/rules/project/`. We provide an EvoX-flavored example template under `examples/project-evox/`.

---

## What's Inside

```
coderules/
├── common/        Universal principles  (6 always-on, 4 triggered)
├── lang/          Per-language syntax   (TypeScript / Rust / testing)
├── patterns/      Reusable architecture (multi-worktree / plugin / IM bot / memory MCP / persona)
├── examples/      Reference templates   (.md only — never auto-loaded)
│   └── project-evox/
└── aicoding/   Agent skill           (DECIDE → BUILD → VERIFY → POLISH)
```

For the full layer/file map see [`INDEX.md`](./INDEX.md).

---

## Quick Start

```bash
# 1) Clone next to your project (or anywhere stable)
git clone <this-repo-url> ~/.coderules

# 2) Link the universal layers into your project
cd ~/path/to/your/repo
mkdir -p .cursor/rules
ln -s ~/.coderules/common    .cursor/rules/common
ln -s ~/.coderules/lang      .cursor/rules/lang
ln -s ~/.coderules/patterns  .cursor/rules/patterns

# 3) (Optional) Link the aicoding skill
ln -s ~/.coderules/aicoding .cursor/rules/aicoding
```

Open the project in Cursor — rules activate automatically per their frontmatter.

> Why symlinks: when this repo updates, every consuming project gets the new rules immediately. If you prefer copies, replace `ln -s` with `cp -r`.

---

## Install by Platform

### Cursor

Use **either** symlinks (recommended, see Quick Start) **or** copies:

```bash
cp -r ~/.coderules/{common,lang,patterns,aicoding} \
      ~/path/to/your/repo/.cursor/rules/
```

`examples/*.md` is **never loaded** by Cursor (only `.mdc` is) — leaving it linked is harmless.

### Claude Code

Skills go to `~/.claude/skills/`; rule-pack goes to your project workspace.

```bash
# Skill: aicoding
mkdir -p ~/.claude/skills
ln -s ~/.coderules/aicoding ~/.claude/skills/aicoding

# Rules: read from any AGENTS.md in the project root
echo "Read rules from $HOME/.coderules/{common,lang,patterns}" > ~/path/to/your/repo/AGENTS.md
```

### Codex / Other CLI agents

Splice the always-on tier into your system prompt:

```bash
cat ~/.coderules/common/{clean-code-core,architecture,decision-hygiene,error-handling,quality-gates,security-secrets}.mdc \
    > /tmp/system-prompt-rules.txt
# Then prepend that file to your agent's system prompt
```

For broader coverage, also splice in the relevant `lang/` and `patterns/` files for the active task.

### Gemini CLI

```bash
gemini skills install ~/.coderules/aicoding
```

---

## Customize for Your Project

The rule pack is project-agnostic. To bind universal patterns to **your** project's concrete values (paths, IM platform, memory MCP server, etc.):

```bash
# 1) Pick a template that matches your need
ls ~/.coderules/examples/project-evox/
#   evox-monorepo.md   ← layout / runtime / E2E / agent-process commands
#   evox-extension.md  ← plugin paths + host symbol + log dir
#   feishu-sdk.md      ← IM platform endpoints + emoji table + block IDs
#   gep-memory.md      ← memory-MCP server name + tool prefix + signal dictionary
#   mbti-persona.md    ← persona axes + persona-crate paths

# 2) Copy + rename .md → .mdc, replace EvoX values
mkdir -p ~/path/to/your/repo/.cursor/rules/project
cp ~/.coderules/examples/project-evox/feishu-sdk.md \
   ~/path/to/your/repo/.cursor/rules/project/discord-sdk.mdc
# ↑ open the file and replace Feishu values with Discord
```

The pattern → binding map (which template binds which `patterns/` file) is in [`examples/project-evox/README.md`](./examples/project-evox/README.md).

---

## Verify Install

```bash
cd ~/path/to/your/repo

# 1) How many rules will be always-on?
find .cursor/rules -name '*.mdc' -exec rg -l 'alwaysApply: true' {} \;
# Expected (≤ 7 total): 6 from coderules/common/ + your own project trunk if any

# 2) Are rules being picked up by Cursor?
# In Cursor: open Settings → Rules → confirm the linked files appear
```

Then ask Cursor a small task and check that:
- It plans before coding (Gate 1 from `aicoding/SKILL.md` triggered)
- It cites `common/clean-code-core.mdc` limits if you push back on a 600-line file
- It does not invent bindings (e.g., it asks you which IM platform when you mention "bot")

The full regression matrix is in [`REGRESSION-TEST-PLAN.md`](./REGRESSION-TEST-PLAN.md) (T1–T6).

---

## Update / Uninstall

```bash
# Update
cd ~/.coderules && git pull

# Uninstall
rm ~/path/to/your/repo/.cursor/rules/{common,lang,patterns,aicoding}
rm -rf ~/path/to/your/repo/.cursor/rules/project    # only if you wrote bindings
```

---

## Design Principles (TL;DR)

- **Always-on tier capped at ≤ 6 files / ~7K tokens** — keeps agent focus on the task, not the rules
- **Every `alwaysApply: true` must justify itself** — fires on every prompt, dilutes attention
- **Patterns are project-agnostic; bindings live in the consuming project** — examples here are reference, not deploy
- **Progressive disclosure** — `aicoding/SKILL.md` is the entry; `references/*.md` load on demand

Read [`INDEX.md`](./INDEX.md) for the full layer responsibility table and migration history (v1 → v2.4).

---

## License

MIT for original content. The `aicoding/` skill draws structure from the MIT-licensed [`addyosmani/agent-skills`](https://github.com/addyosmani/agent-skills).
