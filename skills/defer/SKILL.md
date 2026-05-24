---
name: defer
description: Create, review, or manage deferral files in ~/Documents/vault/deferred/. Use when the user says "create a deferral", "defer this", "add this to deferrals", "this is follow-up work", "we'll come back to this", OR when the SessionStart hook surfaces due deferrals and the user picks an action (extend / graduate / close / drop / skip).
---

# Defer skill

Deferrals are deferred work: tasks surfaced during a larger investigation that aren't ready for a full work-log yet. This skill handles creating new deferrals and reviewing existing ones when they come up on their return date.

**Location:** `~/Documents/vault/deferred/` (flat, not nested in worklogs).

**Filename convention:** `YYYY-MM-DD-<topic>.md` using today's date.

## Frontmatter schema (required on every file)

```yaml
---
title: <human-readable topic>
surfaced: YYYY-MM-DD                # when this deferral was created
surfaced-by: "[[...]]"              # optional: worklog/PR/meeting that spawned it
return-date: YYYY-MM-DD             # when the hook will re-surface this
priority: medium                    # low | medium | high
status: open                        # open | in-progress | done | dropped
reviews: []                         # append review entries here; never delete
---
```

Only `open` or `in-progress` items surface in the daily hook. `done` and `dropped` are terminal.

## Create operation

When the user asks to create a deferral or defer work:

### Step 1: Summarize the deferred work

Restate what's being deferred in 2-3 sentences. Confirm with the user before writing the file. If the conversation context already makes it obvious, proceed and ask for corrections in the confirmation.

### Step 2: Propose a return date

Apply these rules in priority order and state which rule triggered:

1. User specified a date → use it.
2. File content mentions a specific future dependency (e.g., "after the rollback window closes 2026-05-05", "after the vendor ships X") → that date + 1 day.
3. File content signals active waiting ("waiting on X", "urgent") → 5 business days from today.
4. File content signals cleanup or low priority → 10 business days from today.
5. Default → **3 business days from today**.

For business-day math (today + N business days, skipping Sat/Sun), run:

```bash
python3 -c "
from datetime import date, timedelta
d = date.today()
added = 0
while added < N:
    d += timedelta(days=1)
    if d.weekday() < 5:
        added += 1
print(d.isoformat())
"
```

Substitute `N` with the number of business days. Do NOT compute business days manually — month boundaries and DST will trip you up.

### Step 3: Propose a priority

Scan the summary for signals:
- **high**: cost savings > $1k/yr explicitly stated, production bug, blocking another piece of work
- **low**: cosmetic, cleanup, documentation-only, "nice to have"
- **medium**: default if no signal matches

Always show the proposed priority to the user; they override freely.

### Step 4: Auto-derive `surfaced-by`

If the conversation has an active worklog, PR, or meeting note in context, reference it as an Obsidian wiki-link:

```yaml
surfaced-by: "[[worklog/YYYY/MM-month/YYYY-MM-DD-<topic>/overview|YYYY-MM-DD-<topic>]]"
```

If there's no clear source, omit the field.

### Step 5: Write the file

```
~/Documents/vault/deferred/YYYY-MM-DD-<topic>.md
```

Frontmatter at the top, then a blank line, then the body. Body structure (free-form, but these sections are useful):

```markdown
## TL;DR
[1-3 sentences — the punchline]

## Context
[Why this was deferred, what prompted it]

## Proposed work
[What actually needs to be done]

## Return-date rationale
[Why this specific return date — which rule triggered]

## References
[Links to related worklogs, PRs, commits]
```

### Step 6: Confirm

"Created deferral at `<full path>`. Return date: `<weekday> <date>`. Priority: `<priority>`."

## Variant: aggregated post-deploy spot checks

Some deferrals are deliberately short-lived: you just shipped something, and you want a single cheap check tomorrow to confirm it landed as expected. Multiple such items piling up the same day belong in **one aggregated file**, not a separate file per topic. They're checked off together in tomorrow's review; anything that fails or needs deeper work gets graduated to a `/new-window` session per failure.

A "cheap check" can be a SQL query, a log scan, a metric pull, an HTTP probe, a CLI invocation — anything with a binary pass/fail outcome you can read in a few seconds.

### When this variant applies

Use the aggregate pattern when **any one** of these is true:

- Return-date is today + 1 day (calendar or business day)
- The proposed work is a single read-only check (SQL, shell one-liner, HTTP request, log grep) with a binary pass/fail
- The user calls it a "verification", "spot-check", "post-deploy check", or "did it land?"
- The trigger is a PR that just merged, a direct-to-prod deploy, or any production-surface mutation

If even one signal is missing, use the standard one-topic-per-file create flow instead — this variant is for the high-cadence "ship-and-verify-tomorrow" pattern, not for genuine multi-week investigations.

### File location and name

There is **at most one aggregate file per surfaced date**. Use the name:

```
~/Documents/vault/deferred/YYYY-MM-DD-next-day-checks.md
```

(YYYY-MM-DD = today's date.) Before creating, look for an existing file at that path. If it exists, **append** a new `### Check N — <topic>` subsection rather than creating a new file or replacing the existing one.

Legacy single-topic deferrals from prior days don't get retroactively merged — only fold new items into today's file.

### Time-window principle for any rolling check

For any check that filters by time (logs, query history, metrics, audit trails), **always use a rolling lookback** relative to the current moment (`now - 24h`, `now - 1h`, etc.) rather than a calendar-day boundary (`>= today`, `>= start of day`). The system you're querying may evaluate "today" in a session timezone that differs from yours, and events from the gap between those timezones will silently fall outside the filter.

> Example — Snowflake `QUERY_HISTORY`: use `start_time >= DATEADD(hour, -24, CURRENT_TIMESTAMP())`, never `start_time >= CURRENT_DATE`. The MCP session timezone may differ from yours (e.g., US MCP evaluates `CURRENT_DATE` in PT = 08:00 UTC, so 03:00–08:00 UTC events from "this morning" fail the filter). A rolling window is timezone-agnostic.

The principle generalizes: any time-windowed check against a system with mutable session timezones (databases, log stores, observability platforms) benefits from rolling lookbacks.

### Aggregate file structure

```yaml
---
title: Next-day checks for YYYY-MM-DD deploys
surfaced: YYYY-MM-DD
return-date: <today + 1 BD>
priority: medium
status: open
reviews: []
---

## TL;DR
Aggregated verification of <N> things that shipped today. Each check is a single read-only probe with a binary outcome. Run all of them tomorrow morning; tick off the passes; spin a `/new-window` per failed check for deeper investigation.

## Checks

### Check 1 — <topic>
- [ ] **Status:** pending
- **Account / surface:** <which system / environment>
- **Why it matters:** <1-3 sentences linking back to today's deploy>

```sql
<the single SQL / shell / probe>
```

| Outcome | Meaning | Action |
|---|---|---|
| <pass case> | <interpretation> | Tick this check. |
| <partial / known degradation> | <interpretation> | `/new-window` — <narrow next step>. |
| <hard fail> | <interpretation> | `/new-window` — <recovery plan>. |

---

### Check 2 — <topic>
... (same shape)

## Return-date rationale
Rule #1 — natural <task / pipeline / cron> runs happen <when>. Return date: <tomorrow's date> (<weekday>).

## References
- ...
```

### Surfaced-by for the aggregate

Each check carries its own `surfaced-by` worklog reference inside its subsection (in the "Why it matters" line or a separate `**Surfaced-by:**` row). The file-level frontmatter `surfaced-by` field is OK to omit, or to set to the *first* worklog that triggered creation of the day's aggregate.

### Review action for the aggregate (extends the standard Review operation)

When this aggregate file surfaces on its return date:

1. **Run each check's query** in order.
2. For each **passing** check, flip the markdown checkbox `- [ ]` to `- [x]` and update **Status:** to `passed YYYY-MM-DD`. Don't delete the check — keep the history of what was verified.
3. For each **failing** check, choose one:
   - **Recoverable inline** (e.g., re-fetch a config, re-run a single command) → fix it in the current session, then flip the checkbox. Note the recovery in **Status:** (`recovered + passed YYYY-MM-DD`).
   - **Needs deeper investigation** → graduate **that specific check** to a `/new-window` worklog. Flip the checkbox to `- [-]` (in-progress) and update **Status:** to `graduated to [[<new worklog wikilink>]]`. The standard `graduate` action's worklog-creation and check-in-date logic applies per-check.
4. **Roll up the file-level status:**
   - All checks `passed` or `recovered` → close the deferral (`status: done`, append a `reviews:` entry summarizing).
   - Any check `graduated` to a worklog → keep `status: in-progress`, re-roll `return-date` to today + 5 BD as a progress-check cadence, append `reviews:` entry listing which checks closed inline and which graduated.
   - All checks still `pending` (the overnight run didn't happen yet, e.g., weekend) → use the standard `extend` flow to push return-date forward by 1 BD.

### Multi-failure: prefer multiple narrow `/new-windows` over one wide one

When two or more checks fail in unrelated ways, spawn one `/new-window` per failure rather than bundling them. Each failure gets its own focused session and worklog. The aggregate deferral file remains the index — its References section accumulates wikilinks to the spawned worklogs.

## Review operation

Triggered when the SessionStart hook emits a due-items list and the user picks an action for a specific item. The five actions:

### extend
Ask for new return date (offer a default of today + 3 business days). Append to `reviews`:

```yaml
reviews:
  - {date: <today>, action: extend, new-date: <new-date>, note: "<why>"}
```

Update `return-date` to the new date. Keep `status: open`.

### graduate
The deferred work is starting now. Actions:

1. Create a work-log at `~/Documents/vault/worklog/YYYY/MM-month/YYYY-MM-DD-<topic>/overview.md` following the standard work-log template.
2. Cross-link: add a "References" line in the new worklog pointing to the deferral, and add a "Graduated to" line in the deferral body pointing to the new worklog.
3. Propose a progress check-in date (default: today + 5 business days — one work-week cadence). Ask the user to confirm or override. Use the business-day snippet from the create operation's Step 2 to compute the date. This becomes the new `return-date` so the deferral surfaces for a progress check, not same-day.
4. Update the deferral: `status: in-progress`, `return-date: <check-in-date>`, append to `reviews`:

```yaml
reviews:
  - {date: <today>, action: graduate, worklog: "[[...]]", new-date: <check-in-date>, note: "starting now — progress check in N BD"}
```

5. Ask the user if they want a paired branch/worktree for the new worklog.

### close
The work got done (possibly inline in conversation). Update:

```yaml
status: done
reviews:
  - {date: <today>, action: close, note: "<what happened>"}
```

### drop
Decided not to do this. Update:

```yaml
status: dropped
reviews:
  - {date: <today>, action: drop, note: "<why not>"}
```

### skip
Not right now — keep the nag. No file modification. The file will surface again on the next session start.

## Edits to frontmatter

When modifying an existing deferral, preserve the body verbatim. Only touch the frontmatter block between the two `---` markers. If a file has no frontmatter (a legacy file), add it and leave the body untouched.

## Date always uses today's real date

Use the `currentDate` value from the session context, or run `date +%Y-%m-%d` to confirm. Do not guess dates.
