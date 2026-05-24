#!/usr/bin/env bash
# install.sh — bootstrap aesb on a new machine.
#
# What it does, in order:
#   1. Confirms it's running from inside a cloned aesb repo
#   2. Creates ~/Documents/vault/{worklog,journal,deferred} if missing
#   3. Creates ~/.claude/skills/ if missing
#   4. Backs up any existing ~/.claude/skills/<name> that would collide, then
#      symlinks ~/.claude/skills/<name> -> <repo>/.claude/skills/<name>
#   5. Offers to append the worklog standing instruction to ~/.claude/CLAUDE.md
#   6. Prints a final status block + what to do next
#
# Idempotent — re-running is safe. Existing symlinks pointing at the right
# place are left alone; existing real directories are backed up, not clobbered.

set -euo pipefail

REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SKILLS_SRC="$REPO_ROOT/skills"
SKILLS_DST="$HOME/.claude/skills"
COMMANDS_SRC="$REPO_ROOT/commands"
COMMANDS_DST="$HOME/.claude/commands"
VAULT_ROOT="$HOME/Documents/vault"
CLAUDE_MD="$HOME/.claude/CLAUDE.md"
BACKUP_DIR="$SKILLS_DST/.aesb-backup-$(date +%Y%m%d-%H%M%S)"

WORKLOG_MARKER_START="<!-- aesb:worklog-prompt:start -->"
WORKLOG_MARKER_END="<!-- aesb:worklog-prompt:end -->"

# ---------- pre-flight ----------

if [[ ! -d "$SKILLS_SRC" ]]; then
  echo "error: expected $SKILLS_SRC to exist."
  echo "run this script from the root of a cloned aesb repo."
  exit 1
fi

echo "aesb install starting"
echo "  repo:         $REPO_ROOT"
echo "  vault:        $VAULT_ROOT"
echo "  skills dst:   $SKILLS_DST"
echo "  commands dst: $COMMANDS_DST"
echo ""

# ---------- vault dirs ----------

for sub in worklog journal deferred; do
  target="$VAULT_ROOT/$sub"
  if [[ -d "$target" ]]; then
    echo "vault: $target already exists, leaving alone"
  else
    mkdir -p "$target"
    echo "vault: created $target"
  fi
done
echo ""

# ---------- skills dir ----------

mkdir -p "$SKILLS_DST"

# ---------- symlinks ----------

backup_used=0
linked=0
already_linked=0

for skill_path in "$SKILLS_SRC"/*; do
  [[ -d "$skill_path" ]] || continue
  skill_name="$(basename "$skill_path")"
  dst="$SKILLS_DST/$skill_name"

  if [[ -L "$dst" ]]; then
    current_target="$(readlink "$dst")"
    if [[ "$current_target" == "$skill_path" ]]; then
      echo "skill: $skill_name already linked, skipping"
      already_linked=$((already_linked + 1))
      continue
    else
      echo "skill: $skill_name is a symlink pointing elsewhere ($current_target)"
      echo "       backing up before re-linking"
      mkdir -p "$BACKUP_DIR"
      mv "$dst" "$BACKUP_DIR/$skill_name"
      backup_used=1
    fi
  elif [[ -e "$dst" ]]; then
    echo "skill: $skill_name exists as a real directory, backing up"
    mkdir -p "$BACKUP_DIR"
    mv "$dst" "$BACKUP_DIR/$skill_name"
    backup_used=1
  fi

  ln -s "$skill_path" "$dst"
  echo "skill: linked $skill_name -> $skill_path"
  linked=$((linked + 1))
done
echo ""

# ---------- commands ----------

cmd_linked=0
cmd_already=0

if [[ -d "$COMMANDS_SRC" ]]; then
  mkdir -p "$COMMANDS_DST"
  for cmd_path in "$COMMANDS_SRC"/*.md; do
    [[ -f "$cmd_path" ]] || continue
    cmd_name="$(basename "$cmd_path")"
    dst="$COMMANDS_DST/$cmd_name"

    if [[ -L "$dst" ]]; then
      current_target="$(readlink "$dst")"
      if [[ "$current_target" == "$cmd_path" ]]; then
        echo "command: $cmd_name already linked, skipping"
        cmd_already=$((cmd_already + 1))
        continue
      else
        echo "command: $cmd_name is a symlink pointing elsewhere ($current_target)"
        echo "         backing up before re-linking"
        mkdir -p "$BACKUP_DIR/commands"
        mv "$dst" "$BACKUP_DIR/commands/$cmd_name"
        backup_used=1
      fi
    elif [[ -e "$dst" ]]; then
      echo "command: $cmd_name exists as a real file, backing up"
      mkdir -p "$BACKUP_DIR/commands"
      mv "$dst" "$BACKUP_DIR/commands/$cmd_name"
      backup_used=1
    fi

    ln -s "$cmd_path" "$dst"
    echo "command: linked $cmd_name -> $cmd_path"
    cmd_linked=$((cmd_linked + 1))
  done
  echo ""
fi

# ---------- worklog standing instruction ----------

append_worklog_block() {
  cat <<'EOF' >> "$CLAUDE_MD"

<!-- aesb:worklog-prompt:start -->
## Worklog habit (aesb)

When the user signals a task is wrapping (says "done", "ship it", "good for
now", "wrapping up", or finishes a merge flow), proactively offer to write a
worklog entry at:

  ~/Documents/vault/worklog/YYYY/MM-month/YYYY-MM-DD-<topic>/overview.md

If a worklog for the active task already exists, update it instead of
creating a new one. Default sections: TL;DR, what I did, what I am leaving
for next time, and verification / spot-checks (with the actual SQL or
commands used).

Skip silently if the session truly produced nothing worth a worklog (chat
only, no findings, no decisions).
<!-- aesb:worklog-prompt:end -->
EOF
}

mkdir -p "$(dirname "$CLAUDE_MD")"

if [[ -f "$CLAUDE_MD" ]] && grep -q "$WORKLOG_MARKER_START" "$CLAUDE_MD"; then
  echo "claude.md: worklog prompt already present, leaving alone"
else
  read -r -p "claude.md: append the worklog standing instruction to $CLAUDE_MD? [Y/n] " reply
  reply="${reply:-Y}"
  if [[ "$reply" =~ ^[Yy]$ ]]; then
    append_worklog_block
    echo "claude.md: appended worklog block to $CLAUDE_MD"
  else
    echo "claude.md: skipped, append it later by hand or re-run install.sh"
  fi
fi
echo ""

# ---------- summary ----------

echo "----------------------------------------"
echo "aesb install complete"
echo "  skills linked this run:   $linked"
echo "  skills already linked:    $already_linked"
echo "  commands linked this run: $cmd_linked"
echo "  commands already linked:  $cmd_already"
if [[ "$backup_used" -eq 1 ]]; then
  echo "  backup of replaced entries: $BACKUP_DIR"
fi
echo ""
echo "next steps:"
echo "  1. open a new Claude Code session and confirm the skills load"
echo "     (try: /ss, /defer, /checkout)"
echo "  2. read $REPO_ROOT/README.md for the week-1 sequence"
echo ""
echo "if you're new to Claude Code, the friendlier on-ramp is Claude Code"
echo "from Claude (the claude.ai app's in-browser code surface) — same"
echo "skills, less setup."
echo ""
