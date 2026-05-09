#!/usr/bin/env bash
# coderules installer — clone once, link into your agent of choice.
#
# Usage (after cloning):
#   ./install.sh <target> [project_dir]
#
# One-liner (without cloning first):
#   curl -fsSL https://raw.githubusercontent.com/linfengchen/coderules/main/install.sh | bash -s <target> [project_dir]
#
# Targets:
#   cursor [dir]      Link rules + skill into <dir>/.cursor/rules/  (default: $PWD)
#   claude            Link vibe-coding skill into ~/.claude/skills/ (rules: see note below)
#   all [dir]         Both of the above
#   uninstall [dir]   Remove all symlinks created by this installer
#   help              Show this message
#
# Env overrides:
#   CODERULES_HOME    Where to clone/keep the repo  (default: ~/.coderules)
#   CODERULES_REPO    Repo URL                       (default: https://github.com/linfengchen/coderules.git)
#   CODERULES_REF     Branch / tag / commit to use   (default: main)

set -euo pipefail

CODERULES_REPO="${CODERULES_REPO:-https://github.com/linfengchen/coderules.git}"
CODERULES_HOME="${CODERULES_HOME:-$HOME/.coderules}"
CODERULES_REF="${CODERULES_REF:-main}"

LAYERS=(common lang patterns aicoding)
SKILL_DIR="aicoding"

red()    { printf '\033[31m%s\033[0m\n' "$*"; }
green()  { printf '\033[32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }
blue()   { printf '\033[34m%s\033[0m\n' "$*"; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || { red "Required command not found: $1"; exit 1; }
}

ensure_clone() {
  require_cmd git
  if [[ -d "$CODERULES_HOME/.git" ]]; then
    blue "==> Updating $CODERULES_HOME ($CODERULES_REF)"
    git -C "$CODERULES_HOME" fetch --quiet origin "$CODERULES_REF"
    git -C "$CODERULES_HOME" checkout --quiet "$CODERULES_REF"
    git -C "$CODERULES_HOME" pull --ff-only --quiet
  else
    blue "==> Cloning $CODERULES_REPO into $CODERULES_HOME"
    git clone --quiet --depth 1 --branch "$CODERULES_REF" "$CODERULES_REPO" "$CODERULES_HOME"
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
  echo "  • To bind project-specific values, copy a template:"
  echo "      mkdir -p $project_dir/.cursor/rules/project"
  echo "      cp $CODERULES_HOME/examples/project-evox/feishu-sdk.md \\"
  echo "         $project_dir/.cursor/rules/project/<your-binding>.mdc"
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
  yellow "Note: $CODERULES_HOME (the cloned repo) is left in place."
  yellow "      To remove the clone too: rm -rf $CODERULES_HOME"
}

usage() {
  sed -n '2,21p' "$0" | sed 's/^# \{0,1\}//'
}

main() {
  local target="${1:-help}"
  local project_dir="${2:-$PWD}"

  case "$target" in
    cursor)    ensure_clone; install_cursor "$project_dir" ;;
    claude)    ensure_clone; install_claude ;;
    all)       ensure_clone; install_all "$project_dir" ;;
    uninstall) uninstall "$project_dir" ;;
    help|--help|-h) usage ;;
    *) red "Unknown target: $target"; echo; usage; exit 1 ;;
  esac
}

main "$@"
