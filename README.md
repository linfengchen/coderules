# coderules

A project-agnostic, layered Cursor/Claude-Code rule pack — universal coding principles + language-specific syntax + reusable architectural patterns + a `aicoding` agent skill.

> **New here?** Read the team-facing introduction first: [`docs/PR-INTRODUCTION.md`](./docs/PR-INTRODUCTION.md) — what it solves, how it works, and how it compares to other approaches (in Chinese).

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

## Quick Start (one command, no git required)

### Option 1 — installer script (recommended, supports update / uninstall)

```bash
# Cursor — fetch rules + skill into the current project
curl -fsSL https://raw.githubusercontent.com/linfengchen/coderules/main/install.sh | bash -s cursor

# Cursor (global, all projects on this machine — pastes into User Rules)
curl -fsSL https://raw.githubusercontent.com/linfengchen/coderules/main/install.sh | bash -s global

# Claude Code — install aicoding skill globally
curl -fsSL https://raw.githubusercontent.com/linfengchen/coderules/main/install.sh | bash -s claude

# Both project-level (Cursor rules + Claude skill)
curl -fsSL https://raw.githubusercontent.com/linfengchen/coderules/main/install.sh | bash -s all ~/path/to/your/repo
```

The script downloads a tarball (no `git` needed) into `~/.coderules`, then symlinks the four layers into `<project>/.cursor/rules/`. Idempotent — re-running just refreshes. Set `CODERULES_MODE=git` if you prefer a `git clone` you can `git pull` later.

To uninstall:

```bash
~/.coderules/install.sh uninstall ~/path/to/your/repo
```

### Option 2 — pure curl + tar (no script, no git, no `~/.coderules`)

If you don't want any installer or central directory, extract the layers straight into your project:

```bash
mkdir -p .cursor/rules && \
  curl -fsSL https://codeload.github.com/linfengchen/coderules/tar.gz/refs/heads/main | \
  tar -xz -C .cursor/rules --strip-components=1 \
    coderules-main/common \
    coderules-main/lang \
    coderules-main/patterns \
    coderules-main/aicoding
```

This drops the four layers as **plain files** into `.cursor/rules/`. To update: re-run the same command (will overwrite). Trade-off: every consuming project carries its own copy.

---

## Install Details (per platform)

### Cursor — Project Level (recommended)

`install.sh cursor [project_dir]` does:

1. Download tarball (or `git clone` / `git pull` if `CODERULES_MODE=git`) into `$CODERULES_HOME` (default `~/.coderules`)
2. `mkdir -p <project>/.cursor/rules`
3. `ln -s` for each of `common/`, `lang/`, `patterns/`, `aicoding/`

Symlinks (not copies) by design — refresh the cached tarball / pull once and every consuming project picks up the update. `examples/*.md` is never loaded by Cursor (extension is `.md`, not `.mdc`).

### Cursor — Global (all projects on this machine)

Cursor stores **User Rules** (Settings → Rules for AI) as a single text blob applied to every project. There is no `~/.cursor/rules/*.mdc` directory equivalent. To install globally:

```bash
curl -fsSL https://raw.githubusercontent.com/linfengchen/coderules/main/install.sh | bash -s global
```

This:

1. Fetches the rule pack
2. Concatenates the 6 always-on rules into `~/.coderules/USER-RULES.md` (~32 KB / ~8K tokens, frontmatter stripped)
3. **Auto-copies to your clipboard** (macOS `pbcopy` / Linux `xclip` / Wayland `wl-copy`)
4. Tells you to paste into Cursor → Settings → Rules for AI → User Rules → Save

Trade-offs vs project-level:

| Aspect | Project (`cursor`) | Global (`global`) |
|---|---|---|
| Activation | per-project `.cursor/rules/` | every project |
| Layered triggers (glob/desc) | yes | **no — all rules become always-on** |
| Token cost | ~7K (always-on) + on-demand | ~8K (everything always-on) |
| Update mechanism | re-run `install.sh cursor` | re-run `install.sh global` + re-paste |
| Cross-machine sync | per repo (git) | per machine (manual paste) |
| Project conflicts | n/a | project rules win (Cursor priority) |

**Recommendation**: project-level for serious work; global as a "quick-start" for personal projects without per-project setup.

### Claude Code

`install.sh claude` does:

1. Download / refresh `coderules` into `$CODERULES_HOME`
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

# Note: install.sh creates symlinks; use `find -L` to follow them.

# 1) Total rule files reachable
find -L .cursor/rules -name '*.mdc' | wc -l
# Expected: 19   (10 common + 4 lang + 5 patterns)

# 2) Always-on tier (alwaysApply: true) — should be ≤ 6 from coderules
find -L .cursor/rules -name '*.mdc' | xargs grep -l 'alwaysApply: true' | xargs -n1 basename | sort
# Expected:
#   architecture.mdc
#   clean-code-core.mdc
#   decision-hygiene.mdc
#   error-handling.mdc
#   quality-gates.mdc
#   security-secrets.mdc

# 3) Are rules being picked up by Cursor?
# In Cursor: open Settings → Rules → confirm the four layers appear (common, lang, patterns, aicoding)
```

Then ask Cursor a small task and check that:
- It plans before coding (Gate 1 from `aicoding/SKILL.md` triggered)
- It cites `common/clean-code-core.mdc` limits if you push back on a 600-line file
- It does not invent bindings (e.g., it asks you which IM platform when you mention "bot")

The full regression matrix is in [`REGRESSION-TEST-PLAN.md`](./REGRESSION-TEST-PLAN.md) (T1–T6).

---

## What Gets Installed

After `install.sh cursor`, your project layout:

```
your-repo/
└── .cursor/
    └── rules/
        ├── common/      → ~/.coderules/common      (symlink)
        ├── lang/        → ~/.coderules/lang        (symlink)
        ├── patterns/    → ~/.coderules/patterns    (symlink)
        └── aicoding/    → ~/.coderules/aicoding    (symlink)
```

After `install.sh claude`:

```
~/.claude/
└── skills/
    └── aicoding/        → ~/.coderules/aicoding    (symlink)
```

`~/.coderules/` itself is a tarball-extracted snapshot (or a `git clone` if `CODERULES_MODE=git`). Roughly 200 KB of plain text — no binaries, no node_modules, no toolchain.

---

## Update / Uninstall

```bash
# Update — re-running install.sh re-downloads the tarball, reuses existing symlinks
~/.coderules/install.sh cursor ~/path/to/your/repo

# (Or, if you installed with CODERULES_MODE=git: cd ~/.coderules && git pull)

# Uninstall (removes only the symlinks created by install.sh)
~/.coderules/install.sh uninstall ~/path/to/your/repo

# To remove the fetched cache too:
rm -rf ~/.coderules
```

---

## Troubleshooting

### `find` returns 0 rule files

Default `find` doesn't follow symlinks. Use `find -L .cursor/rules -name '*.mdc'`.

### `curl: (35) SSL_ERROR_SYSCALL` or other network glitch

Transient. Retry the same command. If persistent, check corporate proxy / firewall against `codeload.github.com` and `raw.githubusercontent.com`.

### Want to install but didn't specify a project dir

`install.sh cursor` defaults to current directory (`$PWD`). If you ran it in your home directory by accident, undo with:

```bash
~/.coderules/install.sh uninstall ~   # removes the wrong-place symlinks
```

### "exists, not a symlink: …" warning

Something at the target path already exists (a real directory or file, not a symlink). The installer skips it to avoid clobbering your stuff. To force-relink, remove the existing thing first:

```bash
rm -rf .cursor/rules/common && ~/.coderules/install.sh cursor .
```

### Need to upgrade only the rule pack, keep symlinks intact

Re-run `install.sh` — symlinks survive, the cache `~/.coderules/` is replaced atomically.

### Need air-gapped install (no curl access)

Manually fetch the tarball anywhere with internet, scp into the target machine, extract, and link:

```bash
# On a machine with internet:
curl -fsSL https://codeload.github.com/linfengchen/coderules/tar.gz/refs/heads/main -o coderules.tar.gz

# Transfer + extract:
mkdir -p ~/.coderules && tar -xz -C ~/.coderules --strip-components=1 -f coderules.tar.gz
ln -s ~/.coderules/{common,lang,patterns,aicoding} ~/path/to/your/repo/.cursor/rules/
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
