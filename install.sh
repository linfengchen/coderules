#!/usr/bin/env bash
# coderules installer — fetch once, link into your agent of choice.
# Default uses curl + tar (no git required); --git opts into git clone for pull-based updates.
#
# Usage (after fetching):
#   ./install.sh <target> [project_dir]
#
# One-liner (without fetching first):
#   curl -fsSL https://raw.githubusercontent.com/linfengchen/coderules/main/install.sh | bash -s <target> [project_dir]
#
# Targets:
#   cursor [dir]      Link rules + skill into <dir>/.cursor/rules/  (default: $PWD)
#   claude            Link aicoding skill into ~/.claude/skills/    (rules: see note below)
#   all [dir]         Both of the above
#   uninstall [dir]   Remove all symlinks created by this installer
#   help              Show this message
#
# Env overrides:
#   CODERULES_HOME    Where to keep the rule pack    (default: ~/.coderules)
#   CODERULES_REPO    Source repo (owner/repo form)  (default: linfengchen/coderules)
#   CODERULES_REF     Branch / tag / commit to fetch (default: main)
#   CODERULES_MODE    "tarball" (default) | "git"    — git enables `git pull` updates

set -euo pipefail

CODERULES_REPO="${CODERULES_REPO:-linfengchen/coderules}"
CODERULES_HOME="${CODERULES_HOME:-$HOME/.coderules}"
CODERULES_REF="${CODERULES_REF:-main}"
CODERULES_MODE="${CODERULES_MODE:-tarball}"

LAYERS=(common lang patterns aicoding)
SKILL_DIR="aicoding"

red()    { printf '\033[31m%s\033[0m\n' "$*"; }
green()  { printf '\033[32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }
blue()   { printf '\033[34m%s\033[0m\n' "$*"; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || { red "Required command not found: $1"; exit 1; }
}

fetch_tarball() {
  require_cmd curl
  require_cmd tar
  local url="https://codeload.github.com/${CODERULES_REPO}/tar.gz/refs/heads/${CODERULES_REF}"
  local tmp
  tmp="$(mktemp -d)"
  blue "==> Downloading $url"
  if ! curl -fsSL "$url" | tar -xz -C "$tmp"; then
    rm -rf "$tmp"
    red "Download / extract failed (check CODERULES_REPO and CODERULES_REF)"
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
  echo "      cp $CODERULES_HOME/examples/project-evox/feishu-sdk.md \\"
  echo "         $project_dir/.cursor/rules/project/your-binding.mdc"
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
  curl -fsSL https://raw.githubusercontent.com/linfengchen/coderules/main/install.sh | bash -s <target> [project_dir]

Targets:
  cursor [dir]      Link rules + skill into <dir>/.cursor/rules/  (default: $PWD)
  claude            Link aicoding skill into ~/.claude/skills/    (rules: see note below)
  all [dir]         Both of the above
  uninstall [dir]   Remove all symlinks created by this installer
  help              Show this message

Env overrides:
  CODERULES_HOME    Where to keep the rule pack    (default: ~/.coderules)
  CODERULES_REPO    Source repo (owner/repo form)  (default: linfengchen/coderules)
  CODERULES_REF     Branch / tag / commit to fetch (default: main)
  CODERULES_MODE    "tarball" (default) | "git"    — git enables pull-based updates
EOF
}

main() {
  local target="${1:-help}"
  local project_dir="${2:-$PWD}"

  case "$target" in
    cursor)    ensure_fetch; install_cursor "$project_dir" ;;
    claude)    ensure_fetch; install_claude ;;
    all)       ensure_fetch; install_all "$project_dir" ;;
    uninstall) uninstall "$project_dir" ;;
    help|--help|-h) usage ;;
    *) red "Unknown target: $target"; echo; usage; exit 1 ;;
  esac
}

main "$@"
