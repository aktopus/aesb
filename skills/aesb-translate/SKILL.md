---
name: aesb-translate
description: "Use when translating a personal-branch artifact (SKILL.md, command file, README, plugin.json) into its main-branch templated counterpart for the aesb package. Drives a four-phase de-personalization conversation (survey, disposition, produce, verify) and commits the templated version to main."
---

# /aesb:aesb-translate

Drive the per-artifact de-personalization pass that converts a `personal`-branch file into its `main`-branch templated counterpart. Invoked as `/aesb:aesb-translate <relative-path>` where the path is relative to the aesb repo root (e.g. `skills/new-window/SKILL.md`, `commands/checkout.md`, `README.md`).

**Personal-branch-only skill.** Adopters who install from main never get this skill. That's intentional — main doesn't need to re-de-personalize itself.

## Required context

The skill assumes:

- Current working directory is `/Users/akpanoluo/code/aesb/` and the user is on the `personal` branch with a clean working tree.
- A `main`-branch worktree exists at `/Users/akpanoluo/code/aesb-main/`, OR the skill is allowed to create it on first run.
- The user has read `/Users/akpanoluo/.claude/plans/synchronous-tumbling-church.md` (the generalization plan) and approves of executing against its Open-Question dispositions.

If any precondition fails, surface the specific failure and stop.

## Phase 0 — Sanity checks (always first)

```bash
# 0.1 — assert clean personal-branch tree
cd /Users/akpanoluo/code/aesb
test "$(git branch --show-current)" = "personal" || { echo "not on personal — stop"; exit 1; }
git diff --quiet && git diff --cached --quiet || { echo "uncommitted changes on personal — commit/stash first"; exit 1; }

# 0.2 — ensure main-branch worktree exists
test -d /Users/akpanoluo/code/aesb-main || git worktree add /Users/akpanoluo/code/aesb-main main

# 0.3 — pull both branches up to date
git pull origin personal --ff-only
( cd /Users/akpanoluo/code/aesb-main && git pull origin main --ff-only )
```

If any step fails, stop and surface.

## Phase 1 — Survey (read-only)

### 1.1 — Adopter-activity check (Q8 extension)

Before any templating work, check whether anyone else has interacted with the repo:

```bash
fork_count=$(gh api repos/aktopus/aesb/forks --jq 'length')
extra_branch_count=$(gh api repos/aktopus/aesb/branches --jq '[.[] | select(.name != "personal" and .name != "main")] | length')
echo "forks=$fork_count extra_branches=$extra_branch_count"
```

If `fork_count > 0` OR `extra_branch_count > 0`: **STOP**. The translation pass needs to coordinate with community activity, not steamroll it.

Surface to the user:

> Community activity detected. Before continuing the de-personalization pass, we should publish a `CONTRIBUTING.md` and a documented merge methodology so forks/branches know how to engage upstream and how upstream incorporates their changes.

Then walk the user through writing:

- `CONTRIBUTING.md` at the repo root on `main`, covering:
  - How forks pull updates from upstream (`git pull upstream main`)
  - How forks contribute back (PR against main)
  - The role of the `personal` branch (force-push-allowed daily driver; not a contribution target)
  - The role of this skill (`/aesb:aesb-translate`) in handling personal-derived changes that become main proposals
- A short merge-methodology section documenting:
  - Personal → main: via this skill, per-artifact
  - External → main: via PR review, with the maintainer (you) as the merge gate
  - Tag conventions: `v0.x.y` semver on main; personal carries no tags
- Update `aktopus/aesb-marketplace`'s README to note that contributions go to `aktopus/aesb` (not the marketplace stub)

Only after the CONTRIBUTING.md + merge methodology are in place, return to this skill's Phase 1.2 and resume the translation pass.

If `fork_count == 0` AND `extra_branch_count == 0`: proceed to 1.2.

### 1.2 — Read the artifact pair

```bash
# personal version — the source of this translation
cat "/Users/akpanoluo/code/aesb/<path>"

# main version (if exists — means this artifact was translated before and we're updating it)
test -f "/Users/akpanoluo/code/aesb-main/<path>" && cat "/Users/akpanoluo/code/aesb-main/<path>"
```

### 1.3 — Identify personalization spans

Scan the personal version for these patterns (this set is calibrated against the ArcSpan/Snowflake/abuilder/CodeCommit context — extend if you find new categories):

- **Hardcoded paths:** `/Users/akpanoluo/...`, `~/code/vault/...`, `/code/abuilder`, `/code/aspandb`, anything anchored to the user's local filesystem.
- **Named domain terms:** ArcSpan, Snowflake, abuilder, silo (with or without a number), Overwolf, Experian, Tapad, Anthropic, Bandcamp, daily_test, daily_ci, ASB-NNNN ticket IDs.
- **CLI / tool references:** `awscc` (CodeCommit), platform-specific `gh` subcommands assumed for ArcSpan workflow, specific MCP tool names (e.g., `mcp__snowflake__...`).
- **Named people:** any human name that's not the author. Examples to flag: Balaji, Artemio, Carter, Bartoli, Galloway, GV / Garret Vreeland, Art Muldoon. (Author attribution stays — the package is `aktopus/aesb` and that's Akpanoluo Etteh's package.)
- **Specific dates:** any `2026-MM-DD` (or other date) tied to a specific incident, work-log, or deferral, where the date carries no instructional value out of context.
- **Specific repos / projects:** abuilder, aspandb, dbt_explo, tag_test — anything from the user's work environment.
- **Charter / monthly / weekly references** tied to the user's specific strategic plan (e.g., "May 2026 charter", "the four-month charter ending September 2026").
- **Reasoning that depends on personal context** (e.g., "since this is the daily-driver for Akpanoluo's ArcSpan role…", "given the ADHD accommodation…").

Output a categorized list to the user. One section per category, with the matching line(s) quoted verbatim and line numbers if useful.

Run a residue grep as a sanity check that nothing obvious is missed:

```bash
grep -nE '/Users/akpanoluo|code/vault|abuilder|silo[0-9]|Snowflake|Balaji|CodeCommit|awscc|ArcSpan|Overwolf|Experian|Tapad|daily_test|daily_ci|ASB-[0-9]+' "/Users/akpanoluo/code/aesb/<path>"
```

If the grep finds matches the manual scan didn't, surface those too.

## Phase 2 — Disposition per span

For each personalization span, propose one of four dispositions:

- **TEMPLATE** — replace with a `{{placeholder}}` adopters fill in. Use for paths, names, and other "the structure is general but this specific value is mine."
- **DROP** — remove the span entirely; the artifact survives without it. Use for context-specific reasoning or examples that don't generalize.
- **EXAMPLE** — keep the span but reframe as a labeled inline example ("Example: Snowflake QUERY_HISTORY check"). Use when the specific instance teaches the general pattern.
- **KEEP** — false positive, the span is already generic enough despite matching a pattern. Use sparingly; prefer to be explicit.

The vocabulary matters: it forces a deliberate decision per span rather than "templatize-by-default."

Confirm dispositions with the user before producing:

- **Light skills / commands** (worklog, ss, README, plugin.json, command files): batch all dispositions in a single summary and ask "any objections before I produce the templated version?"
- **Heavy skills** (mf, defer, new-window): walk through spans in groups (one per major section of the SKILL.md) and confirm per group. This keeps the user's review surface manageable for high-stakes translations.

Surface the proposed disposition list as:

```
Span | Personal value | Proposed disposition | Templated value (if TEMPLATE)
-----|----------------|---------------------|------------------------------
line 12 | /Users/akpanoluo/code/vault/deferred/ | TEMPLATE | ~/Documents/vault/deferred/
line 47 | Snowflake QUERY_HISTORY | EXAMPLE | (kept, relabeled as "Example: Snowflake post-deploy check")
line 89 | 2026-05-12 burn | DROP | (removed)
...
```

## Phase 3 — Produce

### 3.1 — Write the templated version

Write the new file at the corresponding path inside the main-branch worktree:

```
/Users/akpanoluo/code/aesb-main/<path>
```

Apply all confirmed dispositions in one pass. Don't try to optimize the surrounding prose — preserve voice and structure; only touch what disposition said to touch.

### 3.2 — Show diff vs personal

```bash
diff -u "/Users/akpanoluo/code/aesb/<path>" "/Users/akpanoluo/code/aesb-main/<path>"
```

Or via git (if main already had a prior version):

```bash
cd /Users/akpanoluo/code/aesb-main && git diff -- "<path>"
```

### 3.3 — Confirm before committing

Surface the diff + a one-paragraph summary of dispositions made. Ask explicitly: "land this on main?" Wait for an affirmative.

If the user says no or wants changes, return to Phase 2 with the new dispositions; don't commit until the user is satisfied.

## Phase 4 — Verify

### 4.1 — Frontmatter check (SKILL.md files only)

```bash
head -5 "/Users/akpanoluo/code/aesb-main/<path>"
```

For SKILL.md files: assert frontmatter contains **only** `name` and `description` keys (per memory `reference_claude_code_plugin_skill_frontmatter`). Any other keys (e.g., `argument-hint:`, `metadata:`, custom fields) cause silent skill rejection under the marketplace's `strict: true` flag.

Also assert `name` is a single token, no spaces — slash-command-safe.

If frontmatter violates either rule, fix and re-show.

### 4.2 — Residue grep

```bash
grep -nE '/Users/akpanoluo|code/vault|abuilder|silo[0-9]|Snowflake|Balaji|CodeCommit|awscc|ArcSpan|Overwolf|Experian|Tapad|daily_test|daily_ci|ASB-[0-9]+' "/Users/akpanoluo/code/aesb-main/<path>"
```

Expect zero matches. If matches appear:

- A span was missed in Phase 1.3 — add it, return to Phase 2.
- A disposition produced a leak (e.g., a TEMPLATE replacement that still contained the old value) — fix the replacement, re-write.

### 4.3 — Commit + push

```bash
cd /Users/akpanoluo/code/aesb-main
git add "<path>"
git -c user.name="Akpanoluo Etteh" -c user.email="aktopus@gmail.com" commit -m "$(cat <<'EOF'
<title: artifact-name: one-line summary>

<body: 2-4 sentences explaining what was templated, what was dropped, what
was kept as example, and why. Reference the disposition decisions from
Phase 2 if non-obvious.>
EOF
)"
git push origin main
```

Commit-message conventions:

- **Title:** `<artifact-name>: <one-line summary of what changed>` (e.g., `new-window: parameterize worklog paths, drop fanpoint migration note`)
- **Body:** what was templated, what was dropped, what was kept as labeled example, why. References to disposition decisions if non-obvious from the diff alone.

## Phase 5 — Optional translation log update

After each successful translation, append a one-line entry to the bottom of the plan file:

```
/Users/akpanoluo/.claude/plans/synchronous-tumbling-church.md
```

Under a "## Translation log" section (create the section on first run if missing):

```markdown
## Translation log

- 2026-MM-DD — `skills/<name>/SKILL.md` — main commit `<sha>` — TEMPLATE×<n>, DROP×<n>, EXAMPLE×<n>, KEEP×<n>
```

Also append the same line to the vault copy at:

```
/Users/akpanoluo/code/vault/work-logs/2026/05-may/2026-05-23-aesb-bootstrap/aesb-generalization-plan.md
```

This builds an audit trail. Skip if the user explicitly opts out.

## Red flags — stop and surface

- **Working tree dirty on personal at Phase 0.** Stash or commit before running this skill.
- **Main worktree has uncommitted changes** at Phase 0 (means a prior translation didn't finish cleanly). Resolve before running.
- **Fork or extra-branch count > 0** at Phase 1.1. Pause and write `CONTRIBUTING.md` + merge methodology first.
- **Residue grep at Phase 4.2 finds matches.** Don't push. Return to Phase 2 and re-disposition.
- **User says "no" at Phase 3.3.** Don't commit; surface what would have changed; let the user direct the next move.
- **Frontmatter violates plugin-loader rules at Phase 4.1.** Fix before pushing — silent rejection is worse than no skill.

## Worktree setup notes

If `/Users/akpanoluo/code/aesb-main/` doesn't exist on first run, Phase 0.2 creates it:

```bash
cd /Users/akpanoluo/code/aesb
git worktree add /Users/akpanoluo/code/aesb-main main
```

The worktree persists across invocations of this skill. You can also use it directly for manual main-branch edits when not running the skill (e.g., for the README pass at the end of the plan).

## Companion files

- `/Users/akpanoluo/.claude/plans/synchronous-tumbling-church.md` — the generalization plan this skill executes against (12-step sequencing, per-skill weight, 10 Open Questions with user-approved dispositions).
- `/Users/akpanoluo/code/vault/work-logs/2026/05-may/2026-05-23-aesb-bootstrap/aesb-generalization-plan.md` — vault copy of the same plan.
- `/Users/akpanoluo/.claude/projects/-Users-akpanoluo-code/memory/reference_claude_code_plugin_skill_frontmatter.md` — the frontmatter rules verified at Phase 4.1.
- `~/.claude/plugins/marketplaces/superpowers-marketplace/.claude-plugin/marketplace.json` — working-example shape if Phase 4 verification surfaces a frontmatter question.

## Invocation summary

Typical use:

```
/aesb:aesb-translate skills/new-window/SKILL.md
```

The skill drives the four phases interactively. Each invocation translates exactly one artifact; for the full plan execution, invoke the skill once per artifact in the sequence laid out in the generalization plan.
