---
name: close
description: "Use when the user says /close, 'close this window', 'close this out', 'wrap up and close', or asks whether it is safe to close the current session/window."
---

# /close — close out the current window

Deliver a **close-out verdict** for the current thread. The verdict has three parts, in this order, and the message to the user is exactly those three parts:

1. **Completed-work audit** — what was promised in this thread and whether each item is done. The user-facing label is **Completed work:** (renamed from "Outstanding work" 2026-09-17 — the old label read as if the list were still open, when it is the list of promises with their done / finished-just-now / deferred status).
2. **Worklog** — the absolute path of the worklog that now records this thread, and what was changed in it.
3. **Verdict line** — one of the two sentences below, verbatim, as the last line:
   - `You can close this window.`
   - `Not yet — <the one thing still running or still owed>.`

## Step 1 — Audit the thread for outstanding work

Sweep the whole thread, not the last few turns. Build the audit from these sources:

| Source | What counts as outstanding |
|---|---|
| Your own sentences of the form "I'll …", "next I'll …", "once X passes I'll …" | Any promise with no matching tool call afterwards |
| Background tasks, Monitors, subagents, `/loop` | Anything still running or never reaped |
| Git | Worktrees you created, branches unpushed, PRs open without a merge decision |
| Jira / Slack / email | Comments or messages you said you would post |
| Deferrals you created this thread | Must exist on disk with a return date |
| Verification you said you would run | Must have been run, with the result in the thread |

**Every outstanding item that can be finished inline (a comment, a file edit, a query, killing a stale monitor) is finished now, before the verdict — not listed as a follow-up.** Only work the user must decide on, or work that belongs to a later date, stays outstanding; those go into a deferral (`/defer`) and are named in the verdict line.

## Step 2 — Update or create the worklog

- If a worklog for this thread exists under `/Users/akpanoluo/code/vault/work-logs/YYYY/MM-month/YYYY-MM-DD-<topic>/overview.md`, update it: status line current, results and the Verification / spot-checks section present, any artifacts/tickets/deferrals linked.
- If none exists and the thread produced findings, decisions, or changes, create one via the `worklog` skill's section shape (TL;DR · What I did · What I'm leaving for next time · Verification / spot-checks) at that path — never the skill's stale `~/Documents/vault/worklog/` default.
- If the thread was chat-only with nothing worth recording, say so in part 2 instead of inventing a worklog.

## Step 3 — Verdict

`You can close this window.` is allowed only when parts 1 and 2 show nothing running, nothing owed, and the worklog written. Otherwise the line names the single blocking item. Never soften the verdict into a question or a menu.

## Output contract

```
Akpanoluo, close-out for <thread topic>.

**Completed work:** <one line per promise → done / finished just now / deferred to <file>>
**Worklog:** </Users/akpanoluo/code/vault/work-logs/…/overview.md> — <status set to …; sections added>
You can close this window.
```

Keep it under ~150 words unless an audit item needed fixing inline, in which case say what was fixed in one sentence each.
