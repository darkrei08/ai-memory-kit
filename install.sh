#!/usr/bin/env bash
# ==============================================================================
# ai-memory-kit — standalone installer (idempotent).
#
# Installs three things:
#   1. the `aimem` CLI            -> <prefix>/bin/aimem
#   2. the memory templates       -> <prefix>/share/ai-memory-kit/templates
#      and git hooks              -> <prefix>/share/ai-memory-kit/hooks
#   3. the `project-memory` skill -> every detected AI agent's skills dir
#
# Runs from a clone OR piped:  curl -fsSL <raw>/install.sh | bash
# (when piped it fetches the repo tarball first).
#
# Usage:
#   ./install.sh                     # install everything for detected agents
#   ./install.sh --list              # show what would happen, install nothing
#   ./install.sh --agents pi,claude  # only these agents for the skill
#   ./install.sh --no-skill          # CLI + templates only
#   ./install.sh --prefix DIR        # install CLI/templates under DIR (default ~/.local)
# ==============================================================================
set -Eeuo pipefail

REPO="darkrei08/ai-memory-kit"
REF="${AIMEM_REF:-main}"
SKILL_NAME="project-memory"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || pwd)"

LIST_ONLY=0; DO_SKILL=1; SELECTED=""; PREFIX="${AIMEM_PREFIX:-$HOME/.local}"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --list) LIST_ONLY=1; shift ;;
    --no-skill) DO_SKILL=0; shift ;;
    --agents) SELECTED="$2"; shift 2 ;;
    --agents=*) SELECTED="${1#*=}"; shift ;;
    --prefix) PREFIX="$2"; shift 2 ;;
    --prefix=*) PREFIX="${1#*=}"; shift ;;
    -h|--help) grep '^#' "${BASH_SOURCE[0]:-$0}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; exit 2 ;;
  esac
done

# ------------------------------------------------------------------------------
# Resolve source: run-from-clone, else fetch the tarball.
# ------------------------------------------------------------------------------
SRC="$SCRIPT_DIR"
CLEANUP=""
if [[ ! -f "$SRC/bin/aimem" ]]; then
  command -v curl >/dev/null 2>&1 || { echo "ERROR: curl required to fetch $REPO" >&2; exit 1; }
  command -v tar  >/dev/null 2>&1 || { echo "ERROR: tar required to unpack $REPO" >&2; exit 1; }
  tmp="$(mktemp -d)"; CLEANUP="$tmp"
  echo "Fetching $REPO@$REF ..."
  curl -fsSL "https://codeload.github.com/$REPO/tar.gz/refs/heads/$REF" | tar -xz -C "$tmp"
  SRC="$(find "$tmp" -maxdepth 1 -type d -name 'ai-memory-kit-*' | head -1)"
  [[ -n "$SRC" && -f "$SRC/bin/aimem" ]] || { echo "ERROR: could not locate kit sources after fetch" >&2; exit 1; }
fi
cleanup() { [[ -n "$CLEANUP" ]] && rm -rf "$CLEANUP"; }
trap cleanup EXIT

BIN_DIR="$PREFIX/bin"
SHARE_DIR="$PREFIX/share/ai-memory-kit"

# ------------------------------------------------------------------------------
# Agent skill targets (mirror of the ecosystem's other installers).
# ------------------------------------------------------------------------------
declare -A TARGETS=(
  [pi]="$HOME/.pi/agent/skills"
  [claude]="$HOME/.claude/skills"
  [gemini]="$HOME/.gemini/skills"
  [cursor]="$HOME/.cursor/skills"
  [antigravity]="$HOME/.antigravity/skills"
  [codex]="$HOME/.codex/skills"
  [opencode]="$HOME/.config/opencode/skills"
  [generic]="$HOME/.config/agent-skills"
)
declare -A PRESENCE=(
  [pi]="$HOME/.pi" [claude]="$HOME/.claude" [gemini]="$HOME/.gemini"
  [cursor]="$HOME/.cursor" [antigravity]="$HOME/.antigravity"
  [codex]="$HOME/.codex" [opencode]="$HOME/.config/opencode" [generic]="$HOME/.config"
)
agents() { if [[ -n "$SELECTED" ]]; then printf '%s\n' "${SELECTED//,/ }"; else printf '%s\n' "${!TARGETS[@]}"; fi; }

if [[ "$LIST_ONLY" -eq 1 ]]; then
  echo "Source:    $SRC"
  echo "CLI ->     $BIN_DIR/aimem"
  echo "Templates ->$SHARE_DIR/templates"
  echo "Skill:     $SKILL_NAME"
  printf '%-13s %-40s %s\n' "AGENT" "TARGET" "PRESENT"
  for a in $(agents); do
    t="${TARGETS[$a]:-<unknown>}"; p="no"; [[ -d "${PRESENCE[$a]:-/nonexistent}" ]] && p="yes"
    printf '%-13s %-40s %s\n' "$a" "$t/$SKILL_NAME" "$p"
  done
  exit 0
fi

mirror() { # src/ dest/
  if command -v rsync >/dev/null 2>&1; then rsync -a --delete "$1" "$2"; else rm -rf "$2"; mkdir -p "$2"; cp -a "$1." "$2"; fi
}

# 1) CLI
install -Dm755 "$SRC/bin/aimem" "$BIN_DIR/aimem"
echo "ok   CLI       -> $BIN_DIR/aimem"

# 2) templates + hooks
mkdir -p "$SHARE_DIR/templates" "$SHARE_DIR/hooks"
mirror "$SRC/templates/" "$SHARE_DIR/templates/"
cp -a "$SRC/hooks/." "$SHARE_DIR/hooks/" 2>/dev/null || true
chmod +x "$SHARE_DIR/hooks/"* 2>/dev/null || true
echo "ok   templates -> $SHARE_DIR/templates"

# 3) skill into detected agents
if [[ "$DO_SKILL" -eq 1 ]]; then
  [[ -f "$SRC/skills/$SKILL_NAME/SKILL.md" ]] || { echo "ERROR: skill source missing" >&2; exit 1; }
  for a in $(agents); do
    base="${TARGETS[$a]:-}"; [[ -n "$base" ]] || { echo "skip $a (unknown)"; continue; }
    if [[ ! -d "${PRESENCE[$a]:-/nonexistent}" ]]; then echo "skip $a (not detected)"; continue; fi
    mkdir -p "$base"
    mirror "$SRC/skills/$SKILL_NAME/" "$base/$SKILL_NAME/"
    echo "ok   skill     -> $base/$SKILL_NAME"
  done
fi

# PATH hint
case ":$PATH:" in
  *":$BIN_DIR:"*) : ;;
  *) echo "note: add $BIN_DIR to PATH  ->  export PATH=\"$BIN_DIR:\$PATH\"" ;;
esac

echo
echo "Done. In any project run:  aimem init   (then edit .ai/ and commit)"
