#!/usr/bin/env bash
# uninstall.sh — reverse what install.sh did.
#
# What it does, in order:
#   1. Confirms it's running from the same aesb repo it'll uninstall
#   2. Lists what will be removed and asks for confirmation (skip with --yes)
#   3. Removes ~/.claude/skills/<name> symlinks that point into THIS repo
#   4. Removes ~/.claude/commands/<name>.md symlinks that point into THIS repo
#   5. Strips the marker-bracketed worklog block from ~/.claude/CLAUDE.md
#   6. Leaves ~/Documents/vault/* alone (user data, never touched)
#   7. Leaves any .aesb-backup-* directories alone (user restore material)
#   8. Prints a summary
#
# Idempotent — re-running is safe.
#
# Symlinks pointing elsewhere are left in place untouched. Real
# directories/files (not symlinks) are never deleted.

set -euo pipefail

REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SKILLS_SRC="$REPO_ROOT/skills"
SKILLS_DST="$HOME/.claude/skills"
COMMANDS_SRC="$REPO_ROOT/commands"
COMMANDS_DST="$HOME/.claude/commands"
CLAUDE_MD="$HOME/.claude/CLAUDE.md"

WORKLOG_MARKER_START="<!-- aesb:worklog-prompt:start -->"
WORKLOG_MARKER_END="<!-- aesb:worklog-prompt:end -->"

# ---------- arg parsing ----------

assume_yes=0
for arg in "$@"; do
  case "$arg" in
    -y|--yes) assume_yes=1 ;;
    -h|--help)
      cat <<'HELP'
uninstall.sh — reverse aesb install.sh

Usage:
  uninstall.sh            # interactive — confirms before removing
  uninstall.sh --yes      # unattended — skips confirmation
  uninstall.sh -h         # this help

Removes:
  - ~/.claude/skills/<name>  symlinks pointing into THIS aesb repo
  - ~/.claude/commands/*.md  symlinks pointing into THIS aesb repo
  - the aesb worklog block in ~/.claude/CLAUDE.md (between markers)

Never removes:
  - ~/Documents/vault/{worklog,journal,deferred} (user data)
  - ~/.claude/skills/.aesb-backup-* (your restore material)
  - symlinks pointing somewhere other than this repo
  - real (non-symlink) files at the same paths
HELP
      exit 0
      ;;
    *)
      echo "uninstall.sh: unknown arg '$arg' (try --help)" >&2
      exit 2
      ;;
  esac
done

# ---------- plan ----------

echo "aesb uninstall planning"
echo "  repo:         $REPO_ROOT"
echo "  skills dst:   $SKILLS_DST"
echo "  commands dst: $COMMANDS_DST"
echo ""

skills_to_remove=()
if [[ -d "$SKILLS_SRC" && -d "$SKILLS_DST" ]]; then
  for skill_path in "$SKILLS_SRC"/*; do
    [[ -d "$skill_path" ]] || continue
    skill_name="$(basename "$skill_path")"
    dst="$SKILLS_DST/$skill_name"
    if [[ -L "$dst" && "$(readlink "$dst")" == "$skill_path" ]]; then
      skills_to_remove+=("$skill_name")
    fi
  done
fi

commands_to_remove=()
if [[ -d "$COMMANDS_SRC" && -d "$COMMANDS_DST" ]]; then
  for cmd_path in "$COMMANDS_SRC"/*.md; do
    [[ -f "$cmd_path" ]] || continue
    cmd_name="$(basename "$cmd_path")"
    dst="$COMMANDS_DST/$cmd_name"
    if [[ -L "$dst" && "$(readlink "$dst")" == "$cmd_path" ]]; then
      commands_to_remove+=("$cmd_name")
    fi
  done
fi

claude_md_has_block=0
if [[ -f "$CLAUDE_MD" ]] && grep -q "$WORKLOG_MARKER_START" "$CLAUDE_MD"; then
  claude_md_has_block=1
fi

# ---------- summary of what will happen ----------

total=$(( ${#skills_to_remove[@]} + ${#commands_to_remove[@]} + claude_md_has_block ))
if [[ "$total" -eq 0 ]]; then
  echo "nothing to uninstall — no aesb-owned symlinks or CLAUDE.md block found."
  exit 0
fi

echo "the following will be removed:"
if [[ "${#skills_to_remove[@]}" -gt 0 ]]; then
  for s in "${skills_to_remove[@]}"; do
    echo "  skill symlink:   $SKILLS_DST/$s"
  done
fi
if [[ "${#commands_to_remove[@]}" -gt 0 ]]; then
  for c in "${commands_to_remove[@]}"; do
    echo "  command symlink: $COMMANDS_DST/$c"
  done
fi
if [[ "$claude_md_has_block" -eq 1 ]]; then
  echo "  worklog block:   $CLAUDE_MD (between aesb:worklog-prompt markers)"
fi
echo ""

if [[ "$assume_yes" -ne 1 ]]; then
  read -r -p "proceed? [y/N] " reply
  reply="${reply:-N}"
  if [[ ! "$reply" =~ ^[Yy]$ ]]; then
    echo "aborted, nothing changed."
    exit 0
  fi
fi

# ---------- execute ----------

removed=0

for s in "${skills_to_remove[@]}"; do
  rm "$SKILLS_DST/$s"
  echo "removed skill symlink: $s"
  removed=$((removed + 1))
done

for c in "${commands_to_remove[@]}"; do
  rm "$COMMANDS_DST/$c"
  echo "removed command symlink: $c"
  removed=$((removed + 1))
done

if [[ "$claude_md_has_block" -eq 1 ]]; then
  tmp="$(mktemp)"
  awk -v start="$WORKLOG_MARKER_START" -v end="$WORKLOG_MARKER_END" '
    $0 ~ start { skip=1; next }
    $0 ~ end   { skip=0; next }
    !skip      { print }
  ' "$CLAUDE_MD" > "$tmp"
  mv "$tmp" "$CLAUDE_MD"
  echo "removed worklog block from: $CLAUDE_MD"
  removed=$((removed + 1))
fi

echo ""
echo "----------------------------------------"
echo "aesb uninstall complete ($removed items removed)"
echo ""
echo "not touched (by design):"
echo "  vault content under ~/Documents/vault/  (your journal, worklogs, deferrals)"
echo "  .aesb-backup-* directories              (anything install.sh moved aside on a re-run)"
echo "  symlinks pointing somewhere other than $REPO_ROOT"
echo "  real (non-symlink) files at the same paths"
echo ""
echo "if you want the repo itself gone too:"
echo "  rm -rf $REPO_ROOT"
echo ""
