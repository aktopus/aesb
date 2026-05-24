---
name: new-window
description: "Use when the user says /new-window, types 'new window', 'hand off', 'context handoff', or wants to spin off one or more fresh Claude sessions from the current work. Always creates new worklog(s) for the spawned session(s) and writes self-contained handoff materials. Supports single-handoff (one fresh session continues this work) and fan-out (N fresh sessions investigate parallel concerns) from one entry point — same flow, N=1 vs N>1."
---

# /new-window — Spawn fresh sessions from current work

Optional arguments: one or more child topic slugs (`/aesb:new-window slug1 slug2`); otherwise interactive.

Every fresh session = its own new worklog. Lineage lives in worklog frontmatter (`parent_worklog:` on children, `children:` on parents). Single-handoff is just N=1 of fan-out — the skill flow below is identical for both.

## Step 1 — Confirm child topics and slugs

If the user passed slugs as arguments, use them. Otherwise:

1. Propose 1+ kebab-case slugs based on session context, one per concern that should become its own fresh-session worklog.
2. Show the proposed list with one-line topic summaries.
3. Wait for the user to confirm or edit before writing anything.

Single-handoff case (N=1) is normal. If the user just wants a context reset on the same work, propose one slug like `<original-topic>-continuation`.

## Step 2 — Identify or create the originating worklog

Scan `~/Documents/vault/worklog/YYYY/MM-month/` for in-flight candidates. Preference order:

1. Worklogs created today.
2. Worklogs with `status: In progress` or `status: Completed — awaiting ...` in frontmatter.
3. Worklogs the user referenced by name in the conversation.
4. Worklogs matching the user's current branch (`git worktree list`).

If multiple are plausible, name them and ask which is the parent.

If there is NO in-flight worklog (pure research / chat-only session): create an **umbrella parent worklog** at `~/Documents/vault/worklog/YYYY/MM-month/YYYY-MM-DD-<umbrella-slug>/overview.md`. The umbrella's job is to host the lineage. Body is 2–3 lines naming the originating context plus the `children:` frontmatter field. Propose the umbrella slug from the conversation's dominant theme and confirm with the user before writing.

## Step 3 — Create each child worklog

For each confirmed slug, create `YYYY-MM-DD-<slug>/overview.md` with frontmatter:

    ---
    status: In progress — fresh session pending pickup
    parent_worklog: ~/Documents/vault/worklog/YYYY/MM-month/<parent-folder>/overview.md
    spawned_from_session: YYYY-MM-DD
    ---

The body must be self-contained — a fresh Claude won't see this session's messages. Use this shape:

    # <Child topic — human readable>

    **Parent:** [[worklog/YYYY/MM-month/<parent-folder>/overview|<parent-folder>]]

    ## What this worklog investigates
    <1–2 sentences: what's the concern, why look at it>

    ## Context inherited from parent
    <5–15 lines: relevant file paths, prior findings, decisions already made, what to take as given. Inline what's needed; don't make the new session walk back to the parent for basics.>

    ## Open questions
    <bulleted list>

    ## Suggested first action
    <one sentence — what should the fresh session do first>

**No branch / worktree at spawn time.** Children start as investigation worklogs by default. If a child later decides it needs code changes, the fresh session creates a worktree+branch at that point as part of its own merge-flow. Branch creation stays decoupled from worklog spawning.

## Step 4 — Update the originating worklog's frontmatter

Add (or extend) the `children:` field:

    children:
      - ~/Documents/vault/worklog/YYYY/MM-month/YYYY-MM-DD-<child-1>/overview.md
      - ~/Documents/vault/worklog/YYYY/MM-month/YYYY-MM-DD-<child-2>/overview.md

Also apply today's existing /new-window updates to the parent: refresh `status`, fill `pr` / `final_commit_sha` if PRs landed in this session, flip `☐` operational items to `✅` with evidence. **`status` describes what *this* worklog did; `children:` describes the lineage. They're orthogonal — don't conflate.**

## Step 5 — Write next-window.md in the originating worklog

`<parent-worklog>/next-window.md` is the index of spawned children plus launch commands. Use this shape:

    # Spawned new windows — YYYY-MM-DD

    Each entry below is a fresh worklog. Launch in its own terminal for an isolated Claude session.

    ## Children

    ### 1. <slug> — <one-line topic>
    Worklog: `~/Documents/vault/worklog/YYYY/MM-month/YYYY-MM-DD-<slug>/overview.md`

    Launch:

        claude -n <slug> "@~/Documents/vault/worklog/YYYY/MM-month/YYYY-MM-DD-<slug>/overview.md — start fresh on this worklog" --dangerously-skip-permissions

    ### 2. <slug> — <one-line topic>
    ...

    ## When ready to integrate
    Read each child's `back-to-parent.md` (if written) to harvest findings.

## Step 6 — If the originating worklog is itself a child, prompt for back-to-parent.md

Check the originating worklog's frontmatter for `parent_worklog:`. If set, this session is closing out a child worklog — prompt the user:

> This worklog is a child of [grand-parent]. Want me to write a `back-to-parent.md` with curated findings to surface up?

Default yes; draft from the session. Location: `<originating-worklog>/back-to-parent.md`. Shape:

    # back-to-parent — findings for <grand-parent-name>

    ## TL;DR
    <1–2 sentences: the single most important thing the grand-parent needs to know>

    ## Findings
    <bulleted>

    ## Decisions made
    <bulleted — decisions taken without grand-parent input, flagged for awareness>

    ## Open asks for the grand-parent
    <bulleted — questions/decisions kicked back up>

    ## Key file references
    <absolute paths>

Skip this step entirely if `parent_worklog:` is unset on the originating worklog.

## Step 7 — Report back

End the turn with a compact status and ready-to-paste launch commands:

> Spawned N new worklog(s) under parent: `<parent-path>`.
>
> Paste each into a new terminal for an isolated fresh Claude session:
>
> ```
> claude -n <slug-1> "@<absolute-path-1>/overview.md — start fresh on this worklog" --dangerously-skip-permissions
> claude -n <slug-2> "@<absolute-path-2>/overview.md — start fresh on this worklog" --dangerously-skip-permissions
> ```
>
> When ready to integrate, harvest findings from each child's `back-to-parent.md`.

If back-to-parent.md was also written this session (step 6), note that too: "Also wrote `back-to-parent.md` at `<path>` for grand-parent `<grand-parent-name>`."

### Launch command rules

- Always absolute paths.
- Always quote the whole prompt argument so `@<path>` and the trailing instruction land as one argv.
- Always include `--dangerously-skip-permissions` — same-user same-machine continuation, re-prompting is pure friction.
- Always include `-n <slug>` — names the spawned session so the top-right chip in Claude Code matches the worklog folder. Use the exact kebab-case slug from the child worklog directory (the `YYYY-MM-DD-<slug>` folder's `<slug>` portion, not the date prefix). This is the only fully-automatic way to name a session; `/rename` mid-session is a fallback, and the model has no tool to rename the live session on the user's behalf.
- Do NOT use `--resume` or session IDs — every spawn is a *fresh* session reading the handoff worklog, not a resume of the prior conversation.
- Do NOT substitute `cat` / `$(...)` piping — the `@<path>` form preserves the file as an attachment rather than inlining its contents.

## Principles

- **Self-contained handoffs.** Each child worklog's overview.md must let a fresh Claude start work without asking clarifying questions. Inline necessary context; don't make the new session walk back up to the parent for basics.
- **Absolute paths everywhere.** `~/Documents/vault/...` (or your equivalent) form so they're clickable in the user's terminal.
- **Frontmatter is the lineage source of truth.** `parent_worklog:` on children, `children:` on parents — both on the worklog's existing overview.md. No separate `thread.md` file (would duplicate).
- **One flow for all spawns.** Single-handoff (N=1) and fan-out (N>1) are the same skill — no mode switch, no second code path.
- **Concerns are siblings, not nested children.** Each fan-out child is its own top-level worklog under `~/Documents/vault/worklog/YYYY/MM-month/`, not a subdirectory of the parent. Lineage is in frontmatter; directory structure stays flat.

## Red flags

- **Never edit a child worklog to "fix" the parent's session record.** The parent's session record stays in the parent worklog.
- **Never skip `parent_worklog:` frontmatter on a child.** It is the only thing connecting a child back upward — frontmatter is the lineage; without it the thread is broken.
- **Never put time-decay phrases in next-window.md** ("earlier today", "just now"). Use absolute timestamps or the session date.
- **Never spawn a code-change branch+worktree at fan-out time.** Children start as investigation worklogs; branches are a separate user action when code is actually needed.
- **Never bundle multiple unrelated concerns into one child worklog.** Each distinct concern = its own child. That's the point of fan-out.
- **Never re-introduce a `fanout/` subdirectory.** Fan-out children are flat siblings + frontmatter lineage, not nested subdirectories.

## When to DECLINE the skill

- User typed `/new-window` mid-task by mistake. Confirm first: "Want me to wrap up the session now? Current work: <1-line summary>."
- Session truly produced nothing worth handing off (no work, no findings, no questions). Tell the user the handoff would be empty; offer to write minimal anyway if they insist.
