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

## Quick Start (one command)

```bash
# Cursor — link rules + skill into the current project
curl -fsSL https://raw.githubusercontent.com/linfengchen/coderules/main/install.sh | bash -s cursor

# Claude Code — install aicoding skill globally
curl -fsSL https://raw.githubusercontent.com/linfengchen/coderules/main/install.sh | bash -s claude

# Both, into a specific project
curl -fsSL https://raw.githubusercontent.com/linfengchen/coderules/main/install.sh | bash -s all ~/path/to/your/repo
```

The script clones to `~/.coderules` (override via `CODERULES_HOME=...`), then symlinks `common/`, `lang/`, `patterns/`, `aicoding/` into `<project>/.cursor/rules/`. Re-running is **idempotent**. Open the project in Cursor — rules activate automatically per their frontmatter.

To uninstall:

```bash
~/.coderules/install.sh uninstall ~/path/to/your/repo
```

---

## Install Details (per platform)

### Cursor

`install.sh cursor [project_dir]` does, in order:

1. Clone (or `git pull`) `coderules` into `$CODERULES_HOME` (default `~/.coderules`)
2. `mkdir -p <project>/.cursor/rules`
3. `ln -s` for each of `common/`, `lang/`, `patterns/`, `aicoding/`

Symlinks (not copies) by design — `git pull` once and every consuming project picks up the update. `examples/*.md` is never loaded by Cursor (extension is `.md`, not `.mdc`).

### Claude Code

`install.sh claude` does:

1. Clone / pull `coderules` into `$CODERULES_HOME`
2. `ln -s ~/.coderules/aicoding ~/.claude/skills/aicoding`

For the rule layers in a project, also run `install.sh cursor <dir>` — Claude Code reads `.cursor/rules/` too.

### Codex / Other CLI agents

No installer support yet; splice the always-on tier into your system prompt manually:

```bash
cat ~/.coderules/common/{clean-code-core,architecture,decision-hygiene,error-handling,quality-gates,security-secrets}.mdc \
    > /tmp/system-prompt-rules.txt
# Then prepend that file to your agent's system prompt
```

### Gemini CLI

```bash
gemini skills install ~/.coderules/aicoding
```

### Manual install (no curl, no script)

```bash
git clone https://github.com/linfengchen/coderules ~/.coderules
cd ~/path/to/your/repo
mkdir -p .cursor/rules
ln -s ~/.coderules/{common,lang,patterns,aicoding} .cursor/rules/
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
# Update — re-running install.sh pulls latest, reuses existing symlinks
~/.coderules/install.sh cursor ~/path/to/your/repo

# Or just:
cd ~/.coderules && git pull

# Uninstall (removes only the symlinks created by install.sh)
~/.coderules/install.sh uninstall ~/path/to/your/repo

# To remove the cloned repo too:
rm -rf ~/.coderules
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
