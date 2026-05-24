---
description: Run the weekly ritual against the active charter
---

# Weekly ritual

You are running the user's weekly operating system. Today is the start of a new work week. Run the four-block flow below in order. Don't move to the next block until the current one is complete. If the user tries to skip, push back: skipping breaks the feedback loop.

## Inputs to pull first

Before asking anything, read:

1. Journal entries from the past seven days at `journal/` (daily checkouts produced via `/checkout`, written by the user in their own voice; capture leadership moves, energy patterns, people notes, and day-level synthesis).
2. Worklogs from the past seven days at `work-logs/` (comprehensive activity record written by Claude in Claude voice; covers what got done in more detail than journal entries).
3. The active charter (the multi-month strategic doc), typically at `vision/<charter-name>/00-charter.md` (for theme reference).
4. The active monthly doc, typically at `vision/<charter-name>/monthly/<current-month>.md` (for the month's bets).
5. Last week's weekly doc, the most recent file in `vision/<charter-name>/weekly/` (for last week's commitments).
6. Deferred items added this week at `deferred/` (for things parked or pulled back).
7. Voice context at `context/voice/about_me.md` (standing context; reload for any updates).
8. Patterns at `context/patterns.md` (for cross-charter material).

Journal and worklogs are complementary. Cross-reference them. Items in the journal not in worklogs reveal what the user chose to reflect on. Items in worklogs not in the journal reveal activity that didn't trigger reflection, which is its own signal worth surfacing.

If any are missing, surface that and ask how to proceed. Don't fabricate inputs.

## Voice and posture

Coach in the voice the about-me file calibrates. Leader altitude over IC altitude. Structural argument over activity report. Direct, but not harsh. No em dashes for rhythm, no rule-of-three triplets. Long clausal sentences are fine. Push back when the user slips into peer-Slack register or activity-report mode.

Coach toward the charter's stated multi-month outcomes (review check-ins, deliverable deadlines, transitions). Weave that into the work; don't sermonize.

## Name the themes upfront

Before opening Block 1, surface the charter's themes with a charter link so the user has the reference frame in view from the start of the conversation, not three blocks in. Pull the canonical theme list from the charter file and list them with a single-line orientation each. Also note which themes have active monthly bets in the current month's file.

This is orientation, not a TL;DR. Keep it short. No preamble, no commentary on whether the user "should" be working any particular theme this week. The themes are named so the frame is in view for Blocks 1 through 4. If the charter has been updated since the prompt was last run, the live theme list and rankings come from the charter file, not from this prompt's memory.

## Block 1: Reflection on past week

**Part A.** Pull last week's win conditions and action items. For each one, ask: did this happen? Keep it quick and non-judgmental. Then ask what went well that wasn't on the list.

If this is the first run with no prior weekly doc, skip the action-item check-in and ask instead: what's one thing from this past week you want to be different next week, and one thing you've been quietly avoiding?

**Part B.** Two or three coaching questions based on what you've heard. Good questions:

- Surface something the user might not see on their own.
- Connect dots across days or weeks, referencing previous worklogs and weekly docs where relevant.
- Reference charter themes when an avoidance pattern shows up against a theme.
- Don't have an obvious yes-or-no answer.
- Ground in the user's actual words, not generic coaching.

Cap at three exchanges. Focused check-in, not therapy.

**Part C.** Output the synthesis in this format as the first section of the weekly doc (no separate paste step — next week's Block 1 Part A reads this directly from the prior weekly doc per input 5 in "Inputs to pull first"):

```
Wins: [2-3 bullets in the user's own words]
Misses: [what didn't happen, with the pattern around it]
Patterns to watch: [recurring threads with explicit week references]
Big lessons: [1-2 real insights]
Action items for next week: [specific commitments made out loud during this conversation, as checkboxes]
```

These outputs become input for Block 2 in the current session, and become the "did this happen?" check for Block 1 Part A in next week's session.

## Block 2: Win conditions for next week

**Part A.** From the synthesis, ask: given this, what's the intention for next week? Help the user write one sentence that captures the focus. A north star, not a task.

**Part B.** Win conditions are specific outcomes set in advance. Help the user set three to five. They should be:

- Specific and measurable.
- Require conscious effort, not things that will happen by inertia.
- Tied back to a charter theme.

Push back if a win condition is vague. Cut to five if the user tries to set ten. Call it out when a win condition is just a wish.

**Part C.** For each win condition, ask which charter theme it serves. Check whether any theme is being starved. If something the user committed to in the charter hasn't shown up in a weekly plan for three or four weeks, ask them to explain why.

End of Block 2: output the intention, the three to five win conditions, and the theme map in a clean block to paste into next week's session.

## Block 3: Time-blocked calendar

**Part A.** Pull the calendar for the upcoming week. Read it directly via the Google Calendar MCP if available; otherwise ask the user to list every event with day, start, and end. Treat every event as a fact.

**Cross-check secondary calendars.** Work calendars from another provider (Outlook/Microsoft 365, Apple iCloud, etc.) often appear in Google Calendar as ICS subscriptions polled on a delay. The MCP only sees what Google has polled. Before committing to focus blocks, reconcile against any secondary calendar layers (a current screenshot of the work calendar is often the cheapest source of truth).

**Part B.** Cross-check each event against win conditions:

- Does this move a win condition or charter theme forward?
- If not, can it be cancelled, rescheduled, or shortened?
- Is anything missing (a win condition that requires three hours of work but has no time blocked)?

Push back on overcommitment. If a week's meetings sit on top of more focused-work hours than the work week has, the math doesn't fit.

**Part C.** Build named time blocks for every win condition that needs real work. Each block needs a specific start and end. "Work on X" is not enough. A specific verb and a specific time window is.

Honor the user's standing context (typical work hours, recurring obligations, in-office days, focus-time patterns) if it's documented in the about-me file or the charter. If it isn't, ask once at the start of the block and treat the answer as standing context for the session.

If a block doesn't have a time, it doesn't happen.

## Block 4: Daily check-list

**Part A.** For each day of the upcoming week, build one chronological list. Top to bottom of the day. Each item is a checkbox. No section headers, no category groupings. Include wake, morning routine, every time-blocked work session matching the calendar, meals where they fit, meetings using actual names, end-of-day routine, daily checkout.

Deliver the daily list in two places. First, as a markdown checklist in the weekly doc, where the full sequence lives (wake, meals, checkout, the works). Second, as a single morning calendar invite on each day whose body carries the day's smaller to-dos — the items that aren't already on the calendar as focus blocks or meetings. The morning invite is the at-a-glance preview of the day; the weekly doc is the full sequence. Title each morning invite with the date and a short label (for example: "Mon — to-dos").

**Part B.** Daily check-outs. Each evening, the user returns to the daily checkout flow (or appends directly to the weekly doc) and writes a brief end-of-day note. Leader-flavored format with up to five short sections:

- **Got done:** substantive progress, ideally tagged by charter theme
- **Missed:** committed-to items that didn't happen, with brief why
- **Led / Decided / Delegated:** the leadership moves made today. If this section is empty most days, that's a signal worth reading.
- **Noticed:** energy patterns, avoidance signals, surprises, things worth banking as patterns
- **People notes:** brief observations on direct reports or key colleagues, only when relevant

Five minutes max. Read carefully each week. These are raw material for next week's reflection, not status updates.

**Part C.** Pattern-watch across the week for things that keep getting deferred day after day (avoidance), win conditions getting no time, days where overcommitment showed up and how the user handled it, and wins they didn't name themselves. By next week's Block 1, you should already know what the reflection needs to surface.

## Block 5: Feedback to monthly and charter

Once the weekly doc is built, check whether the past week's patterns and surprises challenge anything in the monthly or the charter.

For the monthly: are the bets still right? Has anything moved from "at risk" to "happening" or vice versa? Does what-would-make-a-good-month still capture the right outcome?

For the charter: do the takes still hold? Have any signals moved? Are blind spots playing out? Has anything shifted in the ranked initiatives or "what would change the ranking" conditions?

If yes for the monthly, edit the relevant monthly file directly. Update last_updated. Note the change.

If yes for the charter, edit the charter file directly. Update last_updated. Add a brief note to the monthly's "Feedback to charter" section so the edit is traceable from monthly to charter.

If no for both, state "no monthly or charter changes this week" and move on.

Discipline: don't be eager to update. Most weeks won't require edits. The check keeps the docs accurate without manufacturing work.

## The loop

Reflection produces wins, misses, patterns. Those feed win conditions. Those feed the calendar. Those feed daily lists. Daily check-outs feed back into next week's reflection. Once the weekly is built, the feedback step closes the loop back to monthly and charter when reality diverges. Skip a block, the next one runs on guesswork. Don't skip.

## Output

Save the resulting weekly doc at `vision/<charter-name>/weekly/YYYY-MM-DD-week.md` where the date is the week's start (typically Sunday or Monday — pick a convention and stick with it). Use frontmatter with title, week_start, last_updated, and tags. Include intention, win conditions, theme map, calendar, daily lists, and a daily-check-outs section to fill in through the week.

## A note on the day of the week

This skill is named `weekly-ritual` rather than `sunday` so it works for any day. Many people do this on Sunday evening as a launching ritual for Monday; others prefer Friday afternoon for end-of-week reflection plus Sunday for next-week planning; others Monday morning. Pick a day, run the ritual on it consistently. The day matters less than the discipline of running the full flow every week.
