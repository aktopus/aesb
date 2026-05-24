---
name: "Merge Flow"
description: "Execute the full merge flow on the current set of implemented changes. Use when the user says /mf, 'merge flow', 'do the merge flow', or indicates they're done with changes and ready to merge."
---

# Merge Flow

Execute the **Merge Flow** as defined in the project's CLAUDE.md. This is the complete sequence: work-log, worktree, commit, push, PR, squash-merge, cleanup, and work-log update.

## Instructions

When invoked, execute ALL steps of the Merge Flow from CLAUDE.md in sequence **without pausing for confirmation**:

1. Create work-log
2. Create worktree
3. Copy modified files from main to worktree, then commit in the worktree
4. Push branch (from the worktree)
5. Create PR via `awscc create-pull-request`
6. **Run `/code-review:code-review` on the PR** — see Code Review section below
7. Squash-merge with a meaningful commit message (auto-generate, do NOT ask to confirm)
8. Cleanup — see critical rules below
9. Update work-log with PR ID, final commit SHA, set status to Completed

Refer to the **Merge Flow** section in the project CLAUDE.md (`/Users/akpanoluo/code/CLAUDE.md`) for exact commands and formatting rules.

## Key Rules

- **Never** leave the default "Squashed commit of the following:" merge message
- Commit message title: concise summary of what changed
- Commit message body: 1-3 sentences explaining why and what it affects
- Do not pause between steps to ask for confirmation
- If there's an existing worktree with uncommitted changes, use it rather than creating a new one
- Ask if the user wants a paired work-log only if one doesn't already exist for this work

## Step 5.5: Gotcha Checker — Run Between PR Creation and Code Review

After the PR is created (step 5) and **before** invoking `/code-review:code-review` (step 6), run the gotcha checker against the PR's diff. Findings are surfaced to the user AND injected into the step-6 reviewer prompt under a `## Pre-merge gotcha findings` section. The checker never blocks the merge — its purpose is to feed signal into the review, which has its own gating logic.

### Procedure

1. **Read the gotcha library** at `/Users/akpanoluo/code/vault/context/airflow-dag-gotchas.md`.

2. **Parse `gotcha-trigger:` YAML blocks.** Each block has fields `id`, `diff_pattern`, and `check`. Gotchas without a trigger block are reference-only — skip them silently.

3. **Compute the diff** from the worktree:
   ```bash
   cd <worktree-path>
   git fetch origin main --quiet
   git diff origin/main..HEAD
   ```

4. **For each gotcha trigger:** test the diff against `diff_pattern` (extended regex, line-oriented). If any line matches, execute `check` from the worktree root, piping the full diff on stdin. Capture stdout (findings) and stderr (errors).

5. **Aggregate findings.** If at least one finding was emitted, print to terminal:
   ```
   Gotcha checker: 1 of N rules triggered
   <finding lines>
   ```
   If none, print:
   ```
   Gotcha checker: 0 of N rules triggered
   ```

6. **Inject into step 6.** When invoking the code-review reviewer agents, prepend the findings to their prompt under a section header `## Pre-merge gotcha findings (from merge-flow step 5.5)`. The reviewers treat findings as concerns to evaluate during review.

### Failure handling

- **Malformed YAML in a gotcha-trigger block:** print the parse error, skip that gotcha, continue. Don't block the merge for a documentation bug.
- **Check script exits non-zero:** treat as a finding; surface its stderr in the output. Don't block.
- **No triggers match:** print the "0 of N rules triggered" line and proceed.
- **User wants to skip the checker:** if the user explicitly says to skip step 5.5, do so and proceed to step 6. No flag needed.

### Reference

- Spec and design: `/Users/akpanoluo/code/vault/work-logs/2026/04-april/2026-04-28-merge-flow-gotcha-checker/overview.md`
- Check scripts: `/Users/akpanoluo/.claude/skills/mf/gotcha-checks/`
- Gotcha library: `/Users/akpanoluo/code/vault/context/airflow-dag-gotchas.md`

## Code Review — Run Before Merge (CodeCommit-Adapted)

After the PR is created and **before** squash-merge, invoke `/code-review:code-review` against the PR. The shipped skill is GitHub-only (`gh` CLI + github.com permalink format). For abuilder (CodeCommit) it works with these adaptations baked in — apply them automatically without asking:

**Skip these steps from the shipped skill:**
- Step 1 (eligibility check via `gh pr view`) — you just opened the PR; it's open, not draft, no prior review
- Step 3 (Haiku PR-summary agent) — you authored the PR and have the diff in context

**Adapt these steps:**
- Step 4 reviewers: feed them `cd <worktree> && git diff <merge-base-sha>..<head-sha>` instead of `gh pr diff`. Reviewers are then host-agnostic.
- Step 8 (post comment): use `awscc post-comment-for-pull-request --pull-request-id <PR_ID> --repository-name abuilder --before-commit-id <full-base-sha> --after-commit-id <full-head-sha> --content "..."` instead of `gh pr comment`. CodeCommit requires explicit before/after commit IDs.
- Code citations: github.com permalink format (`https://github.com/.../blob/<sha>/file#L4-L7`) does not render in CodeCommit. If issues are found, cite as `path/to/file.py:42-45` plain text — accept the loss of clickable links.

**For non-abuilder repos on GitHub:** run the shipped skill as-is, no adaptations.

### Handling Findings

- **No high-confidence issues (score ≥ 80)** → proceed straight to squash-merge. Do not pause.
- **Issues found, minor (style, nit, small bug, missing edge case)** → fix in the worktree, commit + push (PR auto-updates), then proceed to squash-merge. Do **not** re-run the review (avoids infinite loops). Do **not** alert the user.
- **Issues found, significant** → STOP. Surface to user before any further action. "Significant" means: invalidates the PR's purpose (the change doesn't actually do what the PR claims), introduces a new bug worse than the one being fixed, or breaks a contract (API, data shape, downstream consumer). Use judgment — when in doubt, alert.

## Cleanup — Run Every Step From The Main Repo

**Always `cd` to the main repo before cleanup.** If the shell's cwd is inside the worktree when `git worktree remove` runs, the directory is deleted under it and all subsequent commands fail with "No such file or directory".

Run cleanup as **separate commands**, not a single chained `&&` line:

```bash
cd /Users/akpanoluo/code/abuilder
git push origin --delete <branch>
git worktree remove ../abuilder-<branch>
git branch -D <branch>
git checkout -- .          # discard local edits that were committed via the worktree
git pull
```

The `git checkout -- .` is necessary because files edited interactively in the main tree before the worktree was created will block `git pull` with "local changes would be overwritten". Discarding them is safe — the squash merge already contains those changes.
