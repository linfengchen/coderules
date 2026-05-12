#!/usr/bin/env bash
# coderules installer — fetch once, link into your agent of choice.
# Default uses curl + tar (no git required); --git opts into git clone for pull-based updates.
#
set -euo pipefail

CODERULES_HOME="${CODERULES_HOME:-$HOME/.coderules}"
CODERULES_REF="${CODERULES_REF:-main}"
CODERULES_MODE="${CODERULES_MODE:-tarball}"

LAYERS=(common lang patterns aicoding examples)
SKILL_DIR="aicoding"

red()    { printf '\033[31m%s\033[0m\n' "$*"; }
green()  { printf '\033[32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }
blue()   { printf '\033[34m%s\033[0m\n' "$*"; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || { red "Required command not found: $1"; exit 1; }
}

slug_from_github_remote_url() {
  local raw="${1%.git}"
  if [[ "$raw" =~ ^git@github\.com:([^/]+)/(.+)$ ]]; then
    printf '%s\n' "${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
    return 0
  fi
  if [[ "$raw" =~ ^ssh://git@github\.com/([^/]+)/(.+)$ ]]; then
    printf '%s\n' "${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
    return 0
  fi
  if [[ "$raw" =~ ^https://github\.com/([^/]+)/([^/?#]+)$ ]]; then
    printf '%s\n' "${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
    return 0
  fi
  return 1
}

infer_coderules_repo() {
  local script_path="${BASH_SOURCE[0]:-}"
  if [[ -z "$script_path" || "$script_path" == "-" || ! -f "$script_path" ]]; then
    return 1
  fi
  local root
  root="$(cd "$(dirname "$script_path")" && pwd)"
  if [[ ! -d "$root/.git" ]]; then
    return 1
  fi
  require_cmd git
  local url
  url="$(git -C "$root" remote get-url origin 2>/dev/null)" || return 1
  [[ -n "$url" ]] || return 1
  slug_from_github_remote_url "$url"
}

resolve_coderules_repo() {
  if [[ -n "${CODERULES_REPO:-}" ]]; then
    return 0
  fi
  local inferred
  inferred="$(infer_coderules_repo)" || return 1
  CODERULES_REPO="$inferred"
  blue "==> Inferred CODERULES_REPO=$CODERULES_REPO (from install.sh checkout origin)"
}

_fetch_url_to_stdout() {
  local url="$1"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL --connect-timeout 10 --max-time 60 "$url"
    return
  fi
  if command -v wget >/dev/null 2>&1; then
    wget -qO- --timeout=60 "$url" 2>/dev/null || wget -qO- "$url"
    return
  fi
  red "[coderules-install] Tarball fetch needs curl or wget on PATH (Alpine/minimal images: apk add curl or wget)."
  exit 1
}

fetch_tarball() {
  require_cmd tar
  local url="https://codeload.github.com/${CODERULES_REPO}/tar.gz/refs/heads/${CODERULES_REF}"
  local tmp
  tmp="$(mktemp -d)"
  blue "==> Downloading $url"
  if ! _fetch_url_to_stdout "$url" | tar -xz -C "$tmp"; then
    rm -rf "$tmp"
    red "Download / extract failed (check CODERULES_REPO and CODERULES_REF)"
    yellow "[coderules-install] Corporate proxy or air-gap? Try: export HTTPS_PROXY=... and/or http_proxy=... (lowercase for some tools)."
    yellow "[coderules-install] TLS or network flake: retry; confirm codeload.github.com is reachable from this environment."
    return 1
  fi
  local extracted
  extracted="$(find "$tmp" -mindepth 1 -maxdepth 1 -type d | head -1)"
  if [[ -z "$extracted" ]]; then
    rm -rf "$tmp"
    red "Tarball had no top-level directory"
    return 1
  fi
  rm -rf "$CODERULES_HOME"
  mkdir -p "$(dirname "$CODERULES_HOME")"
  mv "$extracted" "$CODERULES_HOME"
  rm -rf "$tmp"
}

fetch_git() {
  require_cmd git
  if [[ -d "$CODERULES_HOME/.git" ]]; then
    blue "==> Updating $CODERULES_HOME (git, $CODERULES_REF)"
    git -C "$CODERULES_HOME" fetch --quiet origin "$CODERULES_REF"
    git -C "$CODERULES_HOME" checkout --quiet "$CODERULES_REF"
    git -C "$CODERULES_HOME" pull --ff-only --quiet
  else
    blue "==> Cloning https://github.com/${CODERULES_REPO}.git into $CODERULES_HOME (git)"
    rm -rf "$CODERULES_HOME"
    git clone --quiet --depth 1 --branch "$CODERULES_REF" \
      "https://github.com/${CODERULES_REPO}.git" "$CODERULES_HOME"
  fi
}

ensure_fetch() {
  if ! resolve_coderules_repo; then
    red "[coderules-install] Set CODERULES_REPO to owner/repo (GitHub), e.g. export CODERULES_REPO=myorg/coderules"
    red "[coderules-install] Or run ./install.sh from a git clone of this repo (origin must be github.com)."
    exit 1
  fi
  if [[ -d "$CODERULES_HOME/.git" ]] || [[ "$CODERULES_MODE" == "git" ]]; then
    fetch_git
  else
    fetch_tarball
  fi
}

link_one() {
  local src="$1" dst="$2"
  if [[ -L "$dst" ]]; then
    local current
    current="$(readlink "$dst")"
    if [[ "$current" == "$src" ]]; then
      green "  ✓ already linked: $dst"
      return
    fi
    yellow "  ~ relinking: $dst (was $current)"
    rm "$dst"
  elif [[ -e "$dst" ]]; then
    red "  ! exists, not a symlink: $dst (skipped — remove manually if you want to relink)"
    return
  fi
  ln -s "$src" "$dst"
  green "  ✓ linked: $dst -> $src"
}

install_cursor() {
  local project_dir="$1"
  [[ -d "$project_dir" ]] || { red "Project dir not found: $project_dir"; exit 1; }
  blue "==> Installing for Cursor in $project_dir"
  mkdir -p "$project_dir/.cursor/rules"
  for layer in "${LAYERS[@]}"; do
    link_one "$CODERULES_HOME/$layer" "$project_dir/.cursor/rules/$layer"
  done
  echo
  green "Cursor install complete."
  echo "  • Open $project_dir in Cursor; rules activate automatically per frontmatter."
  echo "  • To bind project-specific values, copy a template (rename .md → .mdc):"
  echo "      mkdir -p $project_dir/.cursor/rules/project"
  echo "      cp $CODERULES_HOME/examples/project-binding/im-feishu-sample.md \\"
  echo "         $project_dir/.cursor/rules/project/your-binding.mdc"
}

install_global() {
  blue "==> Generating Cursor User Rules blob (global, all projects)"
  local always_on=(
    "common/clean-code-core.mdc"
    "common/architecture.mdc"
    "common/engineering-lifecycle.mdc"
    "common/error-handling.mdc"
    "common/security-guide.mdc"
  )
  local out="$CODERULES_HOME/USER-RULES.md"

  {
    echo "<!-- Auto-generated by coderules install.sh global. Do not edit by hand. -->"
    echo "<!-- Re-run \`install.sh global\` to regenerate after upstream updates. -->"
    echo
    echo "# coderules — Global User Rules"
    echo
    echo "The always-on tier of coderules (**5** merged core files, previously 6), flattened for Cursor's"
    echo "**Settings → Rules for AI → User Rules**. Applies to every project on this machine."
    echo
    echo "Trade-offs vs project-level install:"
    echo "  • Loses layered behavior — every rule becomes always-on (no glob/desc triggers)"
    echo "  • Cursor User Rules don't sync across machines — re-paste per machine"
    echo "  • Project-level \`.cursor/rules/\` still takes priority on conflicts (good)"
    echo
    for f in "${always_on[@]}"; do
      [[ -f "$CODERULES_HOME/$f" ]] || continue
      echo "---"
      echo
      echo "## ${f}"
      echo
      awk 'BEGIN{fm=0} /^---[[:space:]]*$/{fm++; next} fm>=2{print}' "$CODERULES_HOME/$f"
      echo
    done
  } > "$out"

  local bytes
  bytes=$(wc -c < "$out" | tr -d ' ')
  green "Wrote: $out  (${bytes} bytes)"
  echo

  if command -v pbcopy >/dev/null 2>&1; then
    pbcopy < "$out"
    green "✓ Copied to macOS clipboard."
  elif command -v xclip >/dev/null 2>&1; then
    xclip -selection clipboard < "$out"
    green "✓ Copied to clipboard via xclip."
  elif command -v xsel >/dev/null 2>&1; then
    xsel --clipboard --input < "$out"
    green "✓ Copied to clipboard via xsel."
  elif command -v wl-copy >/dev/null 2>&1; then
    wl-copy < "$out"
    green "✓ Copied to clipboard via wl-copy."
  else
    yellow "  No clipboard tool found (tried pbcopy, xclip, xsel, wl-copy). To copy manually:"
    yellow "    cat $out          (paste from terminal selection)"
  fi

  echo
  echo "Next steps:"
  echo "  1. Open Cursor → Settings (Cmd/Ctrl + ,) → Rules for AI"
  echo "  2. Paste into the User Rules text field"
  echo "  3. Click Save"
  echo
  yellow "Note: ~6K of always-on tokens added to every prompt."
  yellow "      For per-project layered triggering (recommended), use:  install.sh cursor"
}

install_claude() {
  blue "==> Installing $SKILL_DIR skill for Claude Code"
  mkdir -p "$HOME/.claude/skills"
  link_one "$CODERULES_HOME/$SKILL_DIR" "$HOME/.claude/skills/$SKILL_DIR"
  echo
  green "Claude Code skill install complete."
  echo "  • Restart Claude Code; $SKILL_DIR skill auto-discovers via SKILL.md frontmatter."
  echo "  • For the rule layers (common/lang/patterns), also run:"
  echo "      $0 cursor /path/to/your/project   (Claude Code reads .cursor/rules/ too)"
}

install_all() {
  local project_dir="$1"
  install_cursor "$project_dir"
  echo
  install_claude
}

uninstall() {
  local project_dir="${1:-$PWD}"
  blue "==> Uninstalling from $project_dir/.cursor/rules/ and ~/.claude/skills/"
  for layer in "${LAYERS[@]}"; do
    local dst="$project_dir/.cursor/rules/$layer"
    if [[ -L "$dst" ]]; then
      rm "$dst" && green "  ✓ removed: $dst"
    fi
  done
  local skill="$HOME/.claude/skills/$SKILL_DIR"
  if [[ -L "$skill" ]]; then
    rm "$skill" && green "  ✓ removed: $skill"
  fi
  echo
  yellow "Note: $CODERULES_HOME (the fetched rule pack) is left in place."
  yellow "      To remove it too: rm -rf $CODERULES_HOME"
}

usage() {
  cat <<'EOF'
coderules installer — fetch once, link into your agent of choice.
Default uses curl + tar (no git required); CODERULES_MODE=git opts into git clone.

Usage:
  ./install.sh <target> [project_dir]

One-liner (no clone needed):
  export CODERULES_REPO=Evomap/coderules
  export CODERULES_REF=main
  curl -fsSL "https://raw.githubusercontent.com/${CODERULES_REPO}/${CODERULES_REF}/install.sh" | bash -s <target> [project_dir]

Targets:
  cursor [dir]      Link rules + skill into <dir>/.cursor/rules/  (default: $PWD)
  claude            Link aicoding skill into ~/.claude/skills/    (rules: see note below)
  global            Generate a paste-ready blob for Cursor's User Rules (global, all projects)
  all [dir]         Cursor (project) + Claude (skill)
  uninstall [dir]   Remove all symlinks created by this installer
  help              Show this message

Env overrides:
  CODERULES_HOME    Where to keep the rule pack    (default: ~/.coderules)
  CODERULES_REPO    Source repo (owner/repo on GitHub). Required for curl|bash;
                    optional when running ./install.sh from a clone (inferred from origin)
  CODERULES_REF     Branch / tag / commit to fetch (default: main)
  CODERULES_MODE    "tarball" (default) | "git"    — git enables pull-based updates

Note: tarball mode prefers curl, falls back to wget; both honor HTTPS_PROXY / http_proxy. The curl|bash one-liner still requires curl to bootstrap install.sh unless you fetch the script with wget manually.
EOF
}

main() {
  local target="${1:-help}"
  local project_dir="${2:-$PWD}"

  case "$target" in
    cursor)    ensure_fetch; install_cursor "$project_dir" ;;
    claude)    ensure_fetch; install_claude ;;
    global)    ensure_fetch; install_global ;;
    all)       ensure_fetch; install_all "$project_dir" ;;
    uninstall) uninstall "$project_dir" ;;
    help|--help|-h) usage ;;
    *) red "Unknown target: $target"; echo; usage; exit 1 ;;
  esac
}

main "$@"
