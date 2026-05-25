---
name: aesbflow
description: Use when the user says /aesbflow, 'aesb flow', 'aesbflow this', or wants to merge changes in the aesb repo with full second-brain hygiene — commits the aesb edit (auto-pushes via the personal-branch post-commit hook), creates a worklog at vault/work-logs/, and appends a row + detail block to vault/vision/second-brain-changelog.md. Personal-branch only. Not present on aesb main (adopter-facing surface).
---

# /aesbflow — Merge flow for the aesb personal-branch worktree

The aesb equivalent of `/mf`. Differs from `/mf` because aesb has no PR step (single-author personal branch with auto-push) — instead, the work-logging side is structurally richer: every meaningful aesb change generates both a *concise* second-brain-changelog row and an *in-depth* worklog.

Use this for any meaningful change to `/Users/akpanoluo/code/aesb/` on `personal`. Skip for typo fixes or trivial reformats — they don't warrant a worklog. The user decides "meaningful enough."

## Pre-flight checks

Before doing anything, verify:

1. `cd /Users/akpanoluo/code/aesb && git branch --show-current` returns `personal`. If not, **stop** and ask the user — aesbflow does not auto-switch branches.
2. `git status --short` shows actual changes. If clean, ask the user whether they meant to invoke aesbflow at all.
3. `ls /Users/akpanoluo/code/aesb/.git/hooks/post-commit` exists and is executable. If missing, surface the gap — the auto-push convention is load-bearing for this flow.

## Step 1 — Capture the change

Ask (in one combined message, not sequential):

- **Topic slug** (kebab-case, used for both worklog folder and changelog reference). Propose one based on the diff; let the user override.
- **One-sentence summary** for the changelog index row's "Change" column.
- **Why** — motivation, problem solved, or origin (a conversation, an incident, a sub-agent pattern).
- **Time-of-day suffix** for the date (`""`, `(AM)`, `(PM)`, `(late PM)`, `(night)`) — match the changelog's existing convention.
- **Is this generally applicable?** — i.e., should it eventually land on `aesb-main` via `/aesb-translate`? If yes, file a deferral via `/defer` or flag it in the worklog's open-questions section. Don't translate inline — that's a separate skill's job.

## Step 2 — Commit the aesb change

Stage the aesb-side changes only (the worklog + changelog edits are vault-side and land after):

```bash
cd /Users/akpanoluo/code/aesb
git add <changed files>
git commit -m "$(cat <<'EOF'
<Concise title>

<1-3 sentences: what changed and why. Match the changelog's "Change" column tone.>
EOF
)"
```

The post-commit hook auto-pushes to `origin/personal`. Capture the resulting SHA (`git rev-parse HEAD`) — it goes in both the worklog header and the changelog detail block.

If the hook prints `post-commit: push to origin/personal failed (...)`, surface it to the user. The commit landed locally; GitHub will catch up on the next successful push. Do not attempt to manually re-push without checking the cause (network, auth, branch-gate).

## Step 2.5 — Refresh symlinks if `skills/` or `commands/` changed

`install.sh` enumerates `skills/*` and `commands/*.md` dynamically and creates symlinks under `~/.claude/skills/` and `~/.claude/commands/`. New skill directories or new command files only become invocable in a fresh Claude session *after* `install.sh` is re-run. Existing symlinks are idempotent — re-running the script links new entries and leaves correct ones alone.

After the commit, check the touched paths:

```bash
git show --name-only --pretty=format: HEAD | grep -E '^(skills|commands)/' | head
```

If the result is non-empty (i.e., this commit added or modified a skill directory or command file), run:

```bash
/Users/akpanoluo/code/aesb/install.sh
```

The script is interactive only on first bootstrap (it prompts for the `CLAUDE.md` worklog block). On a re-bootstrapped machine the marker check trips and it runs non-interactively. If the user's CLAUDE.md hasn't been touched yet, defer the install.sh run and surface it to them — the prompt isn't something to pipe past silently.

Skip this step if the commit only touches docs (README, install.sh itself, plugin.json metadata) or non-symlinked content. Surface the skip explicitly: *"Step 2.5 skipped — diff doesn't touch skills/ or commands/."*

## Step 3 — Create the worklog

Path: `/Users/akpanoluo/code/vault/work-logs/YYYY/MM-month/YYYY-MM-DD-<slug>/overview.md`

Template (lean version — expand sections only when the change genuinely warrants):

```markdown
---
status: Completed
tags:
  - aesb
  - second-brain
  - <topic-specific tags>
aesb_commit: <full SHA>
aesb_branch: personal
aesb_worktree: /Users/akpanoluo/code/aesb
---

# <Title>

**Commit:** [`<short SHA>`](https://github.com/aktopus/aesb/commit/<full SHA>) on `personal`
**Worktree:** `/Users/akpanoluo/code/aesb`

## What changed

<2-5 sentences. The actual diff in human terms. Cite paths like `skills/<name>/SKILL.md` (repo-relative since this is in narrative about the aesb repo, per the path-scope feedback convention).>

## Why

<The motivation. If this came from a multi-window pattern (e.g., /convergence synthesis) or sub-agent finding, name it. If it was triggered by a specific failure or near-miss, capture the failure mode so future sessions can recognize it.>

## Verification / spot-checks

<Per the worklog-overview-includes-spot-checks convention. For aesb changes this usually means: confirmed the skill loads in a fresh session, confirmed the symlink resolves, confirmed the auto-push fired. SQL/commands in code blocks.>

## Open follow-ups

<Optional. Use only if there's real follow-up — e.g., "translate to main via /aesb-translate" or "watch for behavior change in next /sunday run". Otherwise omit the section entirely.>
```

## Step 4 — Append to the second-brain-changelog

File: `/Users/akpanoluo/code/vault/vision/second-brain-changelog.md`

Two edits in this file, in this order:

1. **Update `last_updated:` in frontmatter** to today's date + the time-of-day suffix from Step 1.
2. **Insert a new row at the top of the `## Index` table** (below the header row, above the most recent entry):

   ```
   | <YYYY-MM-DD> <suffix> | <one-sentence summary from Step 1> | <rich paragraph: what + how + why + non-obvious findings. Match the tone of recent rows — substantial, not single-line. End with key file paths or commit SHA where it earns visibility.> | [[work-logs/YYYY/MM-month/YYYY-MM-DD-<slug>/overview\|YYYY-MM-DD-<slug>]] |
   ```

3. **Add a detailed entry** in the `## Detailed entries` section (chronological — newest at top):

   ```markdown
   ### <YYYY-MM-DD> <suffix> — <Title>

   <Multi-paragraph narrative. Pull from the worklog's "What changed" + "Why" + any non-obvious findings, but written for a future reader who isn't already in this session's context. Include: the commit SHA, the failure mode if any, the risk accepted (if any). Match the tone of the existing 2026-05-24 (night) entry — substantive but not exhaustive.>
   ```

## Step 5 — Report final state

Tell the user, in this exact shape:

```
aesbflow complete.

Commit:     <short SHA> on personal (pushed via hook)
Symlinks:   <"refreshed via install.sh" | "skipped — diff doesn't touch skills/ or commands/">
Worklog:    /Users/akpanoluo/code/vault/work-logs/YYYY/MM-month/YYYY-MM-DD-<slug>/overview.md
Changelog:  vault/vision/second-brain-changelog.md (row + detail block)

<If any follow-ups were flagged, one line each here.>
```

## What this skill is for

It enforces three-altitude capture on every meaningful aesb change:

- **Source** — the commit itself, on GitHub, instantly via auto-push
- **Concise narrative** — the changelog row + detail block, scannable from the system-level timeline
- **In-depth narrative** — the worklog, recoverable when someone (often future-you) needs the full context

Without aesbflow, the source layer auto-captures but the two narrative layers depend on memory. The whole point of the second-brain operating system is that meaningful changes don't depend on memory.

## Personal-branch only

This skill exists on `personal` and is intentionally absent from `aesb-main`. Adopters of the templated build don't have a vault layout to write into and shouldn't inherit a workflow that assumes one. If a generalized "merge-flow for an aesb-style personal repo" is ever warranted, it would be a different skill (likely `/personal-flow` or similar), with the vault paths parameterized.
