---
title: Strategy-to-Execution Operating System (Summary)
tags:
  - system
  - summary
---

# The system, in plain English

> The voice below is the author's first-person account of running this system. Treat it as a narrative explainer of the shape — adopt the artifacts and the loops; the voice will be yours.

A working strategy-to-execution operating system that lives in Obsidian (or Notion, or any markdown editor) and runs on Claude. Four cadences in a single coherent loop: a four-month charter, monthly bets, weekly win conditions, and daily checkouts. The pieces:

## The artifacts

**Charter.** One file. Three to five strategic themes covering the four-month horizon. Each theme has a take, an outcome served, a signal of progress, named blind spots, ranked initiatives, and the conditions that would change the ranking. Dual-purpose: it's how I orient my own work, and it's the artifact I bring into the room when I want my most senior reader's input on prioritization. If a sentence in it would make me hesitate in front of that reader, it gets rewritten before it lands.

**Monthly.** A thinner doc per month. Names this month's bets per theme, what I'm explicitly NOT doing, what's at risk, what would make this a good month, and the one thing I'd do if I only got one thing done.

**Weekly.** Generated every week on a day of my choosing via a slash command that runs four blocks plus a feedback step:

1. Reflection on the past week using journal entries from daily checkouts, worklogs, last week's weekly doc, and patterns observed
2. Win conditions for the new week, mapped explicitly to charter themes
3. Time-blocked calendar across the work day, honoring energy patterns
4. Chronological daily checklists with checkboxes
5. Feedback to the monthly and charter when reality has diverged from plan

**Daily checkout.** End of each work day. Runs via `/checkout` slash command. Five short questions asked one at a time without coaching:

- Got done (tagged by theme)
- Missed (with brief why)
- Led / Decided / Delegated (the leader axis)
- Noticed (energy, avoidance, surprises)
- People notes (optional)

Saves to `journal/YYYY-MM-DD.md`. These journal entries are a primary input to the next weekly ritual, complementary to the activity-level worklogs.

**Patterns.** A growing markdown file that holds reusable observations that cross strategic themes. Analogies, parallels, frames I find myself reaching for repeatedly. Feeds talks, posts, conversations.

## How the loops work

**The fast loop:** every day, `/checkout` captures the meaning of the day (not the activity, which the worklogs cover). Every week, the weekly ritual reads the week's checkouts and worklogs together to drive reflection. Win conditions for the new week emerge from that reflection, mapped to charter themes. The calendar gets time-blocked accordingly. Daily checklists fall out of the calendar.

**The slow loop:** when reality diverges from charter or monthly assumptions, the weekly session edits those documents directly and notes the change. Most weeks won't require edits; the check exists to keep the documents accurate without manufacturing work.

**The cross-loop:** at the four-month charter horizon mark, a new charter gets built and the previous one becomes an archived artifact. The patterns file persists across charters and accumulates.

## Why it works

Three properties carry the weight:

The same artifact does two jobs. The charter is both my private operating doc and the shareable artifact I bring into prioritization conversations. That dual-audience constraint forces me to write at the right altitude.

The system reads me before it asks me to plan. Weekly reflection isn't from cold memory; it reads my journal entries, my worklogs, my last weekly doc, and my patterns file. By the time we get to win conditions for the new week, the context is loaded. I'm not guessing what I did last week or what I'm avoiding.

The leader axis is forced into daily reflection. The "Led / Decided / Delegated" prompt in the daily checkout makes me declare each day what leadership moves I made. If that section is empty most days, that's a signal worth reading. The system surfaces it before my manager would.

## What it isn't

Not a productivity hack. The discipline is in the cadence, not in the system being clever. The system being clever just makes the cadence cheaper to maintain.

Not a planning replacement for thinking. The system makes the thinking visible. It doesn't do the thinking.

Not a complete personal operating model. It covers work. Body, relationships, and the rest live in other places.

## The minimum viable version

If you want to try this without building the full thing:

1. Write a charter today. Three themes maximum, each with a one-sentence take and three ranked initiatives. Keep it under 500 words.
2. Run a weekly session next week. Forty-five minutes. Reflect on the past week. Set win conditions for the new week. Block the calendar.
3. Do daily checkouts for one week. Three lines per day: got done, missed, noticed.
4. The next weekly session, see if the system already feels useful. If yes, expand. If no, iterate on the charter.

The full system the builder prompt walks you through is worth the four hours, but the minimum version reveals quickly whether the cadence works for you.
