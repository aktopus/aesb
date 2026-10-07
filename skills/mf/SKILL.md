---
name: mf
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
4.8. **Run the test suite — hard gate, blocks PR creation on failure** — see Step 4.8 below
4.9. **Update or create the Jira ticket — hook-enforced** — see Step 4.9 below (In Review transition happens after step 7)
5. Create PR via `awscc create-pull-request`
6. **Run `/code-review:code-review` and `/preflight --full` at the same time** — see Code Review and Step 6.5 below; fix nothing until both have returned
6.5. **Review comparison** — table in the worklog, one row in the ledger; assessment at 40 rows — see Step 6.5 below
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

## Step 4.7: Out-of-VCS Dependency Check — Run Before PR Creation

Code review only sees the diff, and the diff only sees version control. When a change retires, replaces, re-points, or renames an object whose **dependents are not in the repo**, the review structurally cannot catch the breakage. This step closes that hole.

### When it fires

The branch diff does any of:
- Suspends, drops, or stops scheduling a **Snowflake Task** (or adds Airflow code that "replaces" one)
- Replaces/renames an **SP, table, or view** that Snowflake Tasks, Balaji's crons (his Mac / aspantemp2), or Artemio's QuickSight SQL might call
- Renames/removes **secrets, IAM-referenced resources, S3 paths** consumed by name outside the repo

### Procedure

1. **Snowflake Task graphs:** `SHOW TASKS IN ACCOUNT` on the matching account(s) — read the silo's region from `config.py` first; dual-region silos (e.g. silo66) need BOTH accounts. Inspect `predecessors`/`task_relations` for children chained `AFTER` the retired task. A suspended parent silently stops its children; a dropped parent orphans them (`CHILD_BECAME_ROOT`) and they cannot be re-chained.
2. **Unknown callers of SPs/tables:** cross-walk `ACCOUNT_USAGE.QUERY_HISTORY` (90d) for the object name; `user_name='FMUSER' AND client_application_id LIKE 'JDBC%'` indicates Balaji-cron consumers.
3. **Dashboard consumers:** grep `/code/artemio-vault/Resources/` for the object name (QuickSight SQL).
4. **Disposition:** every dependent found must be (a) migrated in the same change, (b) re-scheduled/re-created, or (c) explicitly accepted as retired — surfaced to the user, never silently dropped.

PASS → continue to step 5. Findings → surface to the user with the dependent list and proposed disposition before creating the PR.

Origin: ASB-3038 (2026-06-11) — the daily_proc Airflow migration suspended `SILOxx_DAILY` Tasks without enumerating children; all 31 `SILOxx_SIZER_BUILD` tasks (`AFTER SILOxx_DAILY`) silently stopped, and sizer counts decayed for ~2 weeks toward client-visible zeros. Gotcha #11 in `/code/vault/context/airflow-dag-gotchas.md` covers the Task-specific trigger; this step is the general rule.

## Step 4.8: Test Suite — Run Before PR Creation

**This is the primary test gate for abuilder.** There is no automatic CI. Both CodeBuild
projects are manual and webhook-less (`airflow_docker` → `airflow/buildspec.yml`,
`airflow_deploy` → `airflow/buildspecdeploy.yml`), and DAG/test code reaches production via
the **git-sync sidecar**, which polls the repo and never touches either pipeline. If merge
flow doesn't run the tests, nothing does before the code is live.

### Procedure

From the worktree root:

```bash
python3 -m pytest tests/ -q
```

**On this laptop, run it as `/usr/bin/python3 -m pytest tests/ -q`** (2026-10-06). Bare `python3`
now resolves to Homebrew 3.14, which has no pytest, so the command above dies with
`No module named pytest` before collecting a test. That is a missing interpreter, not a red
suite and not a pass; `/usr/bin/python3` (3.9.6) is the one with the dev deps.

- **PASS** → continue to step 5.
- **FAIL** → **block**. Do not open the PR. Surface the failing output to the user, fix it,
  re-run until green. This is a hard gate, unlike step 5.5's gotcha checker.
- **Deps missing** (`ModuleNotFoundError` at collection) → `pip install -r
  airflow/requirements-dev.txt`, then re-run. That file is deliberately self-sufficient:
  those two commands take a clean interpreter to a green suite, verified in an empty venv.

### Rules

- **Always run the WHOLE suite**, never just the files in the diff. The 2026-08-12
  regression was a `sys.modules` stub leaking *across* test modules: every file passed in
  isolation, and the failure only appeared when all modules were imported into one process
  in collection order. Per-file runs are structurally blind to it.
- **Skip only if the diff cannot affect Python behavior** — e.g. a pure `.md` or `.sql`
  change with no `.py`, `conftest.py`, or requirements edit. When unsure, run it; the suite
  takes ~5s.
- **Do not silence a failure by narrowing scope** (`-k`, `--ignore`, `-x`). If a test is
  genuinely wrong, fix or delete it in the same change and say so in the PR.

### What this step does NOT cover

Three interpreters are in play and **none of the test runs use production's**:

| Interpreter | Where | Runs |
|-------------|-------|------|
| ~3.9 (laptop) | this step | pytest |
| 3.11 | CodeBuild `standard:7.0` | pytest |
| **3.8.19** | `apache/airflow:2.8.4` | **what production actually executes** |

So 3.9+ syntax (`match`, runtime `X | None`, `datetime.UTC`) passes this gate, passes
CodeBuild, then fails at DagBag import in prod — where the DAG **silently disappears from
the scheduler** rather than erroring loudly. `airflow/buildspec.yml` covers this with a
`compileall` step against the real base image, but that only runs on a manual AirflowDeploy.

If a diff adds syntax you're unsure about, check it directly:

```bash
docker run --rm -v "$PWD":/src --entrypoint python apache/airflow:2.8.4 \
  -m compileall -q /src/airflow-dags
```

`airflow/buildspec.yml` runs the same pytest command in its `pre_build` phase as a backstop,
so a red suite can't ship inside a built image. Keep the two in sync — if the invocation
changes here, change it there. That buildspec has a `SKIP_TESTS=1` escape hatch for incident
response covering its dev-dep install and its pytest run — the two steps that can fail for
reasons unrelated to the hotfix in hand. Its **DAG syntax check is deliberately not
bypassable**: it is the only automated place DAG code meets the 3.8 production interpreter,
and its one external dependency (pulling the base image) is shared with `docker build`, so
skipping it could never unblock a hotfix that would otherwise succeed.

**This step has no hatch and is always mandatory.** The asymmetry is deliberate: skipping in
the buildspec only lets an already-merged, already-gated commit reach the image during an
incident, whereas skipping here would let unreviewed code through.

Reference: `/code/vault/dev-setup/testing.md` ·
`/code/vault/work-logs/2026/08-august/2026-08-12-pytest-stub-leak-collection-failure/overview.md`

## Step 4.9: Jira Ticket — Update or Create, Then In Review After Merge

Every merge flow leaves a ticket behind: it **updates** the ASB ticket for the work, or **creates** one.
Nothing merges without one. Rule set by Akpanoluo 2026-09-17, after four idle-time warehouse changes
(PRs 4438, 4455, 4467, 4471) merged with no ticket and had to be back-filled under ASB-3906.

### Before the PR (so the key can go in the PR description and commit message)

1. **Find the existing ticket.** Look in the conversation, the worklog frontmatter/body, and the branch
   name (`ASB-3878-shared-bi-warehouse`). If none, search: `project = ASB AND text ~ "<distinctive term>"
   AND updated >= -30d`. One ticket per change; a change that finishes an existing ticket updates it.
2. **Otherwise create one** (`createJiraIssue`, project `ASB`, type Task or Bug): body follows
   `/code/vault/context/jira-ticket-conventions.md` (`contentFormat: "markdown"`, 2–3 sentence summary plus
   1–2 sentences per change, no session internals), exactly one theme label, and
   `assignee_account_id` = Akpanoluo (`712020:00a2bf82-a0a7-4caa-b7a6-39731362bbff`), since merge-flow work
   is his and the ASB default would assign Jose. Set `parent` if the work belongs to an open epic.
3. Put the key in the PR description (`## Jira` line) and plan the squash-commit trailer below.

### At squash-merge (step 7)

The commit message ends with a trailer line, above any `Co-Authored-By`:

```
Jira: ASB-3909
```

`/Users/akpanoluo/code/scripts/merge-ticket-guard.py` (PreToolUse on Bash, registered in
`~/.claude/settings.json`) **denies** any `merge-pull-request-by-*` command without a `Jira: ASB-<n>` line.
An ASB id mentioned elsewhere in the message does not count. There is no bypass: finding or creating a ticket
takes seconds, and the hook cannot tell a hotfix from a forgotten step.

### After the merge succeeds

4. **Transition the ticket to In Review** (`getTransitionsForJiraIssue` → the `In Review` id; it was `41`
   on 2026-09-17). Leave a ticket that is already Done as Done.
5. **Comment** the PR id and squash SHA in one line (`addCommentToJiraIssue`, markdown).
6. Moving to **Done** is not part of merge flow; it happens when the change is verified in production
   (the step 7.5 first-exercise check, or a later measurement).
7. Record the key in the worklog `overview.md` (step 9).

The hook checks only that a key is cited; it cannot read Jira status. Steps 4–5 are the part it can't see,
so don't skip them.

## Step 5.5: Gotcha Checker — Run Between PR Creation and Code Review

After the PR is created (step 5) and **before** invoking `/code-review:code-review` (step 6), run the gotcha checker against the PR's diff. Findings are surfaced to the user AND injected into the step-6 reviewer prompt under a `## Pre-merge gotcha findings` section. The checker never blocks the merge — its purpose is to feed signal into the review, which has its own gating logic.

### Procedure

1. **Run the runner** from the worktree root. Do not re-implement the matching by hand:
   ```bash
   cd <worktree-path>
   git fetch origin main --quiet
   git diff origin/main..HEAD | python3 /Users/akpanoluo/.claude/skills/mf/gotcha-checks/run_triggers.py
   ```
   It reads every `gotcha-trigger:` block in `/Users/akpanoluo/code/vault/context/airflow-dag-gotchas.md`
   (`id`, `diff_pattern`, `check`; gotchas without a block are reference-only), tests each `diff_pattern`
   against the diff with `grep -E`, runs the matching `check` with the diff on stdin, and prints each finding
   followed by `Gotcha checker: K of N rules triggered`.

   **Why a script (2026-09-17):** re-implementing this by hand got it wrong twice in one run. The fields are
   YAML `|` block scalars with a trailing newline, and a raw pattern passed to `grep -E` splits on that newline;
   the empty second half matches every line, so all 17 rules fired on every diff. Matching with Python `re`
   instead misreads the POSIX classes (`[[:space:]]`). The runner strips both fields, matches only with
   `grep -E`, and reports any pattern that matches an empty line as `CHECKER PROBLEM: … BROKEN` instead of
   firing it.

2. **Sanity-check the count before using it.** `N of N` triggered on an ordinary diff means the runner or a
   pattern is broken, not that the diff is dangerous. Stop and fix it. Exit 2 with `no diff on stdin` means
   nothing was checked (wrong directory, or the branch has no commits past `origin/main`) — never report
   that as a clean pass. Tests:
   `bash /Users/akpanoluo/.claude/skills/mf/gotcha-checks/test_run_triggers.sh`.

3. **Surface the output** to the terminal as printed, including any `CHECKER PROBLEM:` lines, and keep
   the fired rule ids: step 6.5's `## Review comparison` table has a `Gotcha checker` column, and the
   ledger row records which rules fired and whether each was real.

4. **Inject into step 6.** When invoking the code-review reviewer agents, prepend the findings to their prompt under a section header `## Pre-merge gotcha findings (from merge-flow step 5.5)`. The reviewers treat findings as concerns to evaluate during review.

### Failure handling

- **Malformed gotcha-trigger block, or a pattern `grep -E` rejects or that matches an empty line:** the runner prints `CHECKER PROBLEM:`, skips that gotcha and continues. Don't block the merge for a documentation bug; fix the block in the library.
- **Check script exits non-zero:** treat as a finding; surface its stderr in the output. Don't block.
- **No triggers match:** print the "0 of N rules triggered" line and proceed.
- **User wants to skip the checker:** if the user explicitly says to skip step 5.5, do so and proceed to step 6. No flag needed.

### Reference

- Spec and design: `/Users/akpanoluo/code/vault/work-logs/2026/04-april/2026-04-28-merge-flow-gotcha-checker/overview.md`
- Runner and its tests: `/Users/akpanoluo/.claude/skills/mf/gotcha-checks/run_triggers.py`, `test_run_triggers.sh`
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

## Step 6.5: Preflight `--full` And The Review Comparison — Run With The Code Review, Before Squash-Merge

Two independent reviews run on every PR, started together, and the worklog records what each
found, alongside what the step 5.5 gotcha checker fired on the same diff. Standing since
2026-10-06, Akpanoluo's decision, with an assessment due after 40 merge flows. The comparison
answers two questions: keep both reviews or drop one, and which patterns (gotcha-checker rules,
or anything else pattern-shaped that caught something real) belong in `/preflight`'s
`.review/checks/` so every author gets them, not just this seat (added 2026-10-07).

**Why both:** on the two PRs of 2026-10-06 they found different classes of thing. The code review
(step 6) found the only defect in the diff; `/preflight --full` found the things around the diff
(a wrong cost claim in the description, a precedent that had not run a night, a pre-existing table
worth checking) and the repo's own `.review/run_checks.sh` rules, which Akpanoluo's PRs otherwise
never meet because he is not on the bot's author list for abuilder. Dropping either loses a class
of finding, not a fraction.

### Procedure

1. **Start both as soon as step 5.5 is done, in the same turn.** Launch the step 6 code review
   agents, and in parallel run Jose Cabal-Ugaz's preflight skill in full mode from the worktree
   root, with the PR title and the description file (as posted in step 5, `.review/PR_TEMPLATE.md`
   headers kept) passed, or the description checks are skipped silently:
   ```bash
   /preflight --full --base origin/main --title "<PR title>" --description-file <description file>
   ```
   `--full` is the checks, the playbook pass and the bug hunt (5 to 12 minutes, one headless Opus
   session on the seat); follow the preflight skill's **Full review** section, including the
   `hunt.py wait` step. The code review takes about 3 minutes.
2. **Fix nothing until both have returned.** Each must see the same commit. On 2026-10-06 the
   step-6 fix landed while the hunt was still reading the worktree, and the comparison for that
   finding was lost.
3. **Merge the findings and apply the step 6 findings policy to the union.** `BLOCK` and real
   `WARN` lines from the checks, and real playbook or hunt findings, are fixed like a step 6 minor
   (worktree commit + push, or `awscc update-pull-request-description` for description-only ones),
   then the checks re-run once. A false positive from the checks is noted with its reason; the fix
   for it is a PR to `.review/checks/`, never a silent skip.
4. **Write the `## Review comparison` table into the worklog** (step 9 fills the rest):

   | Finding | Gotcha checker | Code review | Preflight checks | `--full` playbook | `--full` hunt | Real? |
   |---|---|---|---|---|---|---|

   One row per distinct finding from any of the three sources, `raised (<score>)` / `raised` / `no`
   per column, and in `Real?` the verdict with the fix or the reason it was a false positive. The
   `Gotcha checker` column carries the rule id from step 5.5 (`raised [inc-flag-two-domain-filter-branches]`);
   a rule that fired and was read as fine is a false positive here, like any other cleared note.
   Add a line under the table for anything none of them could see (live-system facts found in
   pre-flight).
5. **Append one row to the ledger** `/Users/akpanoluo/code/vault/context/review-comparison-ledger.md`
   (columns are in the file, including the gotcha-checker rule ids that fired and how many were
   real). If any rule, or any real code-review finding, caught something the preflight checks did
   not and the finding is pattern-shaped (a diff grep plus a check, the shape `.review/checks/`
   takes), add it to the ledger's `## Preflight candidates` list with the row number, or increment
   its count if it is already there. Then count the rows.
6. **Assessment at 40.** When the row just appended is number 40 (or any later multiple of 40
   with no assessment since), run the assessment in that same merge flow and report it to
   Akpanoluo before squash-merge: by diff kind, what each source found that the others missed,
   false positive rates per source and per gotcha rule, time and seat cost, a recommendation to
   keep both reviews or drop one, and the `## Preflight candidates` list ranked by real catches,
   as the proposed set of checks to offer Jose Cabal-Ugaz for `pr-review-bot`. Record it under
   `## Assessments` in the ledger. Until then, no commentary on the comparison in chat.

Repo has no `.review/` folder → `--full` does not apply; run the code review alone, say so, and
record the ledger row with the preflight columns as `n/a`.

Installed from `~/Repositories/pr-review-bot` (`~/.claude/skills/preflight` is a symlink into the
clone's `skill/` folder); `git -C ~/Repositories/pr-review-bot pull` picks up Jose's updates.

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

## Step 7.5: First-Exercise Check — Run After Squash-Merge, Before Cleanup

Formerly the "weekend-run check". Reframed 2026-09-13: the risk it guards is a change whose **first
run against production data** happens unwatched (Balaji, ASB-3033, 2026-05-27). The weekend is only
one way that happens, and projecting the next slot when the change has already run is noise.

Ask in order; stop at the first that applies:

1. **Already exercised?** The merged code has run against production data in a same-interval rerun
   or replay that completed and was compared to an oracle (snapshot, Snowflake twin, EXCEPT-zero).
   → Report the run ids and outcome. **Stop.** No next-run projection, no invite.
2. **Can it be exercised now?** The DAG binds a window the merge did not change (e.g. a manual
   `presales_weekly_iceberg_*` trigger gets the same weekly `data_interval_end` as the slot run and
   `reload_ade=false` reuses the mirror), or a snapshot oracle can be taken before a rerun.
   → **Rerun now and gate on it.** A replay today beats a calendar invite for next weekend.
3. **Neither.** For every affected DAG (enumerate per-silo consumers of a shared template from
   `config.py`), compute the next scheduled run that picks up the merge (git-sync ≈ 5 min) and the
   expected completion clock time (mean of the last 7–14 successful runs added to next-run start;
   `check-dag` or `QUERY_HISTORY` by `QUERY_TAG`), both in America/New_York. Weekend completion →
   report dag_id, next-run, expected completion, and offer a **Google** calendar invite at completion
   (never ms365). Weekday → surface the same three facts, no invite. Paused DAGs → note and skip.

If the user says to skip the check, skip it. Memory of record: `feedback_weekend_run_checkin_after_merge`.
