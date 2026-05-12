# coderules

A project-agnostic, layered Cursor/Claude-Code rule pack — universal coding principles + language-specific syntax + reusable architectural patterns + a `aicoding` agent skill. See [`INDEX.md`](./INDEX.md) for structure and migration history.

> What lives here, what does not: this repo ships **rules and a skill**. Project-specific bindings (paths, env vars, API URLs) belong in your **own** repo's `.cursor/rules/project/`. Generic copy-paste templates live under `examples/project-binding/` (`.md` only — never auto-loaded).

---

## What's Inside

```
coderules/
├── common/        Universal principles  (6 always-on, 4 triggered)
├── lang/          Per-language syntax   (TypeScript / Rust / Python / Go / testing)
├── patterns/      Reusable architecture (multi-worktree / multi-agent / plugin / IM bot / memory MCP / persona / database)
├── examples/      Reference templates   (.md only — never auto-loaded)
│   └── project-binding/
└── aicoding/   Agent skill           (DECIDE → BUILD → VERIFY → POLISH)
```

For the full layer/file map see [`INDEX.md`](./INDEX.md).

---

## Quick Start (one command, no git required)

This repo has **no hard-coded GitHub owner** in the docs or installer: point at whichever fork or org you install from.

1. **`curl | bash`** — export `CODERULES_REPO` (`owner/repo` as on GitHub), then fetch `install.sh` from that slug.
2. **Git clone** — run `./install.sh` inside the checkout; `install.sh` infers `CODERULES_REPO` from `origin` when it looks like `github.com/…`.

### Option 1 — installer script (recommended, supports update / uninstall)

```bash
# Set once per shell to the GitHub path of the repo you trust (fork or upstream).
export CODERULES_REPO=OWNER/coderules
export CODERULES_REF=main

# Cursor — fetch rules + skill into the current project
curl -fsSL "https://raw.githubusercontent.com/${CODERULES_REPO}/${CODERULES_REF}/install.sh" | bash -s cursor

# Cursor (global, all projects on this machine — pastes into User Rules)
curl -fsSL "https://raw.githubusercontent.com/${CODERULES_REPO}/${CODERULES_REF}/install.sh" | bash -s global

# Claude Code — install aicoding skill globally
curl -fsSL "https://raw.githubusercontent.com/${CODERULES_REPO}/${CODERULES_REF}/install.sh" | bash -s claude

# Both project-level (Cursor rules + Claude skill)
curl -fsSL "https://raw.githubusercontent.com/${CODERULES_REPO}/${CODERULES_REF}/install.sh" | bash -s all ~/path/to/your/repo
```

**Clone instead of curl:** after `git clone … && cd coderules`, run `./install.sh cursor` — no `CODERULES_REPO` env needed unless `origin` is not GitHub HTTPS/SSH.

The script downloads a tarball (no separate `git` needed for fetch) into `~/.coderules`, then symlinks `common/`, `lang/`, `patterns/`, `aicoding/`, and `examples/` into `<project>/.cursor/rules/`. Idempotent — re-running just refreshes. Set `CODERULES_MODE=git` if you prefer a `git clone` cache you can `git pull` later.

To uninstall:

```bash
~/.coderules/install.sh uninstall ~/path/to/your/repo
```

### Option 2 — pure curl + tar (no script, no git, no `~/.coderules`)

If you don't want any installer or central directory, extract the layers straight into your project:

```bash
export CODERULES_REPO=OWNER/coderules
export CODERULES_REF=main
_repo="${CODERULES_REPO##*/}"
mkdir -p .cursor/rules && \
  curl -fsSL "https://codeload.github.com/${CODERULES_REPO}/tar.gz/refs/heads/${CODERULES_REF}" | \
  tar -xz -C .cursor/rules --strip-components=1 \
    "${_repo}-${CODERULES_REF}"/common \
    "${_repo}-${CODERULES_REF}"/lang \
    "${_repo}-${CODERULES_REF}"/patterns \
    "${_repo}-${CODERULES_REF}"/aicoding \
    "${_repo}-${CODERULES_REF}"/examples
```

GitHub wraps the tarball in **`{repository-name}-{ref}`**. `_repo` is the trailing segment of `CODERULES_REPO` (the repo name); list the archive if your default branch tarball uses a non-obvious suffix.

This drops the layers as **plain files** into `.cursor/rules/`. Include `examples/` so relative links like `../examples/project-binding/*.md` from `patterns/*.mdc` resolve. To update: re-run the same command (will overwrite). Trade-off: every consuming project carries its own copy.

---

## Install Details (per platform)

### Cursor — Project Level (recommended)

`install.sh cursor [project_dir]` does:

1. Download tarball (or `git clone` / `git pull` if `CODERULES_MODE=git`) into `$CODERULES_HOME` (default `~/.coderules`)
2. `mkdir -p <project>/.cursor/rules`
3. `ln -s` for each of `common/`, `lang/`, `patterns/`, `aicoding/`, and `examples/` (templates only; `.md` is never auto-loaded as a rule)

### Cursor — Global (all projects on this machine)

Cursor stores **User Rules** (Settings → Rules for AI) as a single text blob applied to every project. There is no `~/.cursor/rules/*.mdc` directory equivalent. To install globally:

```bash
export CODERULES_REPO=OWNER/coderules
export CODERULES_REF=main
curl -fsSL "https://raw.githubusercontent.com/${CODERULES_REPO}/${CODERULES_REF}/install.sh" | bash -s global
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
cat ~/.coderules/common/{clean-code-core,architecture,decision-hygiene,error-handling,quality-gates,security-guide}.mdc \
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
ls ~/.coderules/examples/project-binding/
#   monorepo-trunk-sample.md   ← layout / worktrees / kill + E2E commands
#   plugin-extension-sample.md ← extension root + host symbol + logs
#   im-feishu-sample.md       ← Lark/Feishu API sample (swap vendor for Slack/Discord/…)
#   memory-mcp-sample.md      ← memory MCP id + tools + signals
#   persona-mbti-sample.md    ← persona axes + paths (replace with your taxonomy)

# 2) Copy + rename .md → .mdc, replace every `<...>` placeholder
mkdir -p ~/path/to/your/repo/.cursor/rules/project
cp ~/.coderules/examples/project-binding/im-feishu-sample.md \
   ~/path/to/your/repo/.cursor/rules/project/discord-sdk.mdc
# ↑ open the file and replace Feishu fields with Discord (or drop for a greenfield chat binding)
```

The pattern → binding map is in [`examples/project-binding/README.md`](./examples/project-binding/README.md).

---

## Verify Install

```bash
cd ~/path/to/your/repo

# Note: install.sh creates symlinks; use `find -L` to follow them.

# 1) Total rule files reachable
find -L .cursor/rules -name '*.mdc' | wc -l
# Expected: 24   (11 common + 6 lang + 7 patterns)

# 2) Always-on tier (alwaysApply: true) — should be ≤ 6 from coderules
find -L .cursor/rules -name '*.mdc' | xargs grep -l 'alwaysApply: true' | xargs -n1 basename | sort
# Expected:
#   architecture.mdc
#   clean-code-core.mdc
#   decision-hygiene.mdc
#   error-handling.mdc
#   quality-gates.mdc
#   security-guide.mdc

# 3) Are rules being picked up by Cursor?
# In Cursor: open Settings → Rules → confirm layers appear (common, lang, patterns, examples, aicoding)
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
        ├── examples/    → ~/.coderules/examples    (symlink; binding templates `.md`)
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
export CODERULES_REPO=OWNER/coderules
export CODERULES_REF=main
curl -fsSL "https://codeload.github.com/${CODERULES_REPO}/tar.gz/refs/heads/${CODERULES_REF}" -o coderules.tar.gz

# Transfer + extract (top-level dir inside the tarball is {repo-name}-{ref}, e.g. coderules-main):
mkdir -p ~/.coderules && tar -xz -C ~/.coderules --strip-components=1 -f coderules.tar.gz
ln -s ~/.coderules/{common,lang,patterns,examples,aicoding} ~/path/to/your/repo/.cursor/rules/
```

---

## Design Principles (TL;DR)

- **Always-on tier capped at ≤ 6 files / ~7K tokens** — keeps agent focus on the task, not the rules
- **Every `alwaysApply: true` must justify itself** — fires on every prompt, dilutes attention
- **Patterns are project-agnostic; bindings live in the consuming project** — examples here are reference, not deploy
- **Progressive disclosure** — `aicoding/SKILL.md` is the entry; `references/*.md` load on demand
- **Language extensibility** — new languages get their own `lang/<lang>.mdc`; common principles stay in `common/`

Read [`INDEX.md`](./INDEX.md) for the full layer responsibility table and migration history (v1 → v2.5).

---

## License

Original code and docs: [MIT](LICENSE). The `aicoding/` skill cites process inspiration from MIT-licensed [`addyosmani/agent-skills`](https://github.com/addyosmani/agent-skills); formal notice: [`aicoding/NOTICE`](aicoding/NOTICE).
