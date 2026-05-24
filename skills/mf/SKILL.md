---
name: mf
description: "Execute the full merge flow on the current set of implemented changes. Use when the user says /mf, 'merge flow', 'do the merge flow', or indicates they're done with changes and ready to merge."
---

# Merge Flow

A self-contained pipeline for getting a set of local changes from your working tree to your project's default branch: worklog, worktree, commit, push, PR, code review, squash-merge, cleanup, worklog update.

Most steps are platform-agnostic. **The PR-creation, code-review-comment, and squash-merge steps depend on which forge hosts the repo** — GitHub, GitLab, Bitbucket, AWS CodeCommit. The first time `/mf` runs against an unfamiliar repo, ask the user which platform they're on and proceed with that platform's CLI commands. After that, just keep using it.

## Sequence

Execute these in order, **without pausing for confirmation between steps** unless a step explicitly says to stop:

1. **Create or update a worklog** at `~/Documents/vault/worklog/YYYY/MM-month/YYYY-MM-DD-<topic>/overview.md`. The worklog header should include the branch name and worktree path. If a worklog already exists for this work, update it rather than creating a new one.
2. **Create a worktree** if you aren't already in one: `git worktree add ../<repo>-<branch> -b <branch>`. After creation, surface to the user on its own line: `Run \`/rename <branch>\` to align the session chip with the new worktree.` (Substitute the actual branch name. `/rename` is a Claude Code slash command the user must type — the model cannot rename the live session itself.)
3. **Make changes and commit** in the worktree. Skip this step if changes are already committed.
4. **Push the branch**: `git push -u origin <branch>`.
4.5. **Pre-flight rebase onto latest default branch.** Catches conflicts at the cheap resolution venue (your branch) rather than at squash-merge time on the platform.
   ```bash
   git fetch origin <default-branch>
   git merge-base --is-ancestor origin/<default-branch> HEAD || \
     (git rebase origin/<default-branch> && git push --force-with-lease)
   ```
   When the branch is already up to date this is a ~1s no-op. When it isn't, the rebase plus `--force-with-lease` resolves at branch level. Some platforms' squash-merge refuses merge commits on the source branch, so a reactive `git merge origin/<default-branch>` doesn't always rescue you later — rebase is the more general fix.
5. **Create the PR.** Platform-dependent:
   - **GitHub** (`gh`):
     ```bash
     gh pr create --title "<concise title>" --body "$(cat <<'EOF'
     ## Summary
     <description>

     ## Work Log
     ~/Documents/vault/worklog/YYYY/MM-month/YYYY-MM-DD-<topic>/overview.md
     EOF
     )"
     ```
   - **GitLab** (`glab`): `glab mr create --title "<title>" --description "<body>"`
   - **Bitbucket Cloud** (`bb` or `bb-cli`): `bb pr create --title "<title>" --body "<body>"` (verify against your installed CLI)
   - **AWS CodeCommit**: `aws codecommit create-pull-request --title "..." --description "..." --targets repositoryName=<repo>,sourceReference=<branch>,destinationReference=<default-branch>`
   - **Unrecognized platform**: ask the user for the exact command.

   Keep the PR title concise (under ~70 chars). The body should explain *why* this change is being made; the diff explains *what*.
5.5. **Optional: run a project-specific gotcha checker.** See the *Gotcha-checker pattern* section below. The kit ships no implementation — adopters wire this up if and when they have a gotcha library worth automating against.
6. **Code-review the PR** via `/code-review:code-review` (or your project's review skill). **Findings policy:**
   - **No high-confidence issues** → proceed straight to squash-merge.
   - **Minor issues** (style, nit, small bug, missing edge case) → fix in the worktree, commit + push (PR auto-updates), then proceed to squash-merge. Do **not** re-run the review (avoids infinite loops). Do **not** alert the user.
   - **Significant issues** → STOP and surface to the user before any further action. "Significant" = invalidates the PR's purpose (the change doesn't actually do what the PR claims), introduces a new bug worse than the one being fixed, or breaks a contract (API, data shape, downstream consumer).
7. **Squash-merge** with a meaningful commit message. Auto-generate; do NOT ask to confirm. Platform-dependent:
   - **GitHub**: `gh pr merge <PR_NUMBER> --squash --subject "<title>" --body "<body>"`
   - **GitLab**: `glab mr merge <MR_IID> --squash --message "<commit message>"`
   - **AWS CodeCommit**: `aws codecommit merge-pull-request-by-squash --pull-request-id <PR_ID> --repository-name <repo> --source-commit-id <SHA> --commit-message "<message>"`

   Commit message shape:
   - Title line: concise summary of what changed.
   - Blank line, then 1-3 sentences explaining *why* and *what it affects*.
8. **Cleanup.** Always `cd` to the main repo before cleanup — if the shell's cwd is inside the worktree when `git worktree remove` runs, the directory is deleted under it and all subsequent commands fail with "No such file or directory". Run as **separate commands**, not a single chained `&&` line:
   ```bash
   cd <main-repo-path>
   git push origin --delete <branch>
   git worktree remove ../<repo>-<branch>
   git branch -D <branch>
   git checkout -- .          # discard any edits that leaked into the main tree
   git pull
   ```
   The `git checkout -- .` is necessary because files edited interactively in the main tree before the worktree was created will block `git pull` with "local changes would be overwritten". Discarding them is safe — the squash merge already contains those changes.
9. **Update the worklog** with the PR ID, the final squash-commit SHA, and `status: Completed`.

## Key rules

- **Never** leave the default "Squashed commit of the following:" merge message — auto-generate a meaningful one.
- Commit message: concise title; 1-3 sentence body explaining why and what's affected.
- Do not pause between steps to ask for confirmation unless step 6 surfaces a significant finding.
- If there's an existing worktree with uncommitted changes, use it rather than creating a new one.
- Ask if the user wants a paired work-log only if one doesn't already exist for this work.

## Gotcha-checker pattern (concept-spec only)

Some projects accumulate a library of *gotchas* — known patterns in diffs that often correlate with bugs (e.g., "splitting SQL on `;` ignores semicolons in comments", "adding a column to a schema dict but not running ALTER", "removing a CSV row that some downstream system still keys on"). When that library exists, it's useful to scan each PR's diff against it as a pre-review signal.

This skill **does not ship a gotcha-checker implementation** — the pattern is project-specific and the maintenance surface isn't worth shipping a generic stub for. Here's the shape if you want to build one:

1. Maintain a library file (e.g., `~/Documents/vault/context/<project>-gotchas.md`) that documents each gotcha. Embed a structured trigger block in each entry:
   ```yaml
   gotcha-trigger:
     id: split-sql-comment-semicolon
     diff_pattern: '\.split\(["\x27];["\x27]\)'        # extended regex, line-oriented
     check: scripts/check-split-sql.sh                  # script that reads diff on stdin, emits findings to stdout
   ```
2. At step 5.5 of the merge-flow, parse all `gotcha-trigger:` blocks from the library file. Skip entries without a trigger block — those are reference-only.
3. Compute the PR diff: `git fetch origin <default-branch> --quiet && git diff origin/<default-branch>..HEAD`.
4. For each trigger, test the diff against its `diff_pattern`. If any line matches, run `check` from the worktree root with the full diff on stdin. Capture stdout as findings.
5. Surface findings to the user and inject them into the step-6 review prompt under `## Pre-merge gotcha findings`. The checker is purely advisory — only step 6 gates the merge.

Failure handling: malformed YAML in a trigger block → log the parse error and skip that gotcha. Check script exits non-zero → treat its stderr as a finding. Zero triggers match → no-op message and proceed. User says "skip the checker" → skip and proceed.

## When to STOP

- Step 6 surfaces a significant finding (see findings policy above).
- A `git push` or PR-create command fails — diagnose before retrying.
- The pre-flight rebase (step 4.5) reports conflicts the model can't safely resolve unattended — surface to the user.
- The user changes their mind mid-flow ("hold on, I want to add another commit") — pause until they're ready.
