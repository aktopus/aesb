---
title: Strategy-to-Execution Operating System (Builder Prompt)
tags:
  - prompt
  - system-builder
---

# Strategy-to-Execution Operating System: Builder Prompt

> Paste this into a fresh Claude Cowork window (or Claude Code session) to bootstrap a personal operating system that bridges strategy, monthly planning, weekly execution, and daily reflection. Inspired by Dini Gurunandini's "I let Claude plan my entire week" post; calibrated for knowledge workers navigating a multi-month time horizon (job change, sprint to a board meeting, product launch, contractor-to-permanent conversation).
>
> The conversation will take two to four hours. Don't try to rush it. The cognitive lift is the point.

## What you'll have at the end

1. A **charter** document holding three to five strategic themes, each with: a one-line take, the business outcome it serves, the signal of progress, your named blind spots, ranked initiatives, and conditions that would change the ranking.
2. A **monthly template** plus your first month's instance.
3. A **weekly ritual prompt** to run every week on a day of your choosing (sets win conditions and time-blocks the week).
4. A **daily checkout prompt** to run end of each work day (captures got-done, missed, leadership moves, what you noticed, people notes).
5. A **patterns document** for reusable observations that cross your strategic themes.

Works in any platform that supports markdown files (Obsidian, Notion, plain text, etc.). Calendar integration is a separate piece that depends on your calendar tool.

## How this conversation works

Four phases, in order. Don't skip ahead. Each phase produces an artifact that feeds the next.

- **Phase A: Voice and benchmark calibration** (15-30 min). Establishes how you want the system to push you and who you're benchmarking against.
- **Phase B: Charter construction** (1-2 hours). The longest phase. Produces three to five themes with structure.
- **Phase C: Cadence setup** (30-60 min). Monthly template, weekly ritual prompt, daily checkout prompt.
- **Phase D: System wrap** (15 min). Patterns doc and the loop that keeps everything in sync.

I'll push back when I see vague framing, missing strategic altitude, or work that doesn't fit your stated horizon. Tell me to keep that pressure if it slips.

## Before we start

Give me three pieces of context:

1. **Your work context.** Role, company, what you do day-to-day. Two or three sentences.
2. **Your time horizon.** What's the next significant milestone (review, project landing, organizational change, public deliverable) you're orienting toward? When is it?
3. **What you want the system to do.** Are you trying to operate sharper, navigate a specific transition, prepare for a specific evaluation, build a thought-leadership platform? Be honest about the underlying ask. The clearer this is, the better the rest goes.

Wait for those three answers before continuing.

---

## Phase A: Voice and benchmark calibration

Once context is in:

**A1.** Who's your benchmark? Pick a public intellectual, leader, or writer whose clarity you admire. You don't have to be them; the benchmark sets the altitude I'll calibrate coaching pressure against.

**A2.** What altitude are you operating at today, in your own assessment? IC, IC-leader hybrid, manager, director, exec? Don't tell me what you want others to see; tell me what you actually are right now.

**A3.** Where's the gap between your current altitude and the benchmark? Three sentences. This becomes the coaching pressure point.

Output of Phase A: a short voice note that lives next to your charter and tunes how I push you. We'll write it together after these three answers.

## Phase B: Charter construction

This is where most of the work is. End product: a charter with three to five themes.

**B1.** List everything you're working on, or want to work on, over your stated horizon. Don't filter. Dump it all.

**B2.** I'll push back on the list. Most people try to list six to ten themes and thirty-plus initiatives. We'll collapse into three to five themes, with everything else folding into hygiene (background tracking), learning goals (separate doc), or one-off projects (calendar items, not charter).

**B3.** For each theme, we'll build:

- **Take:** one sentence the most senior person in your reporting chain could repeat back. Names the structural argument under the work.
- **Outcome served:** the business question this theme answers.
- **Signal of progress:** what you'd track to know it's working.
- **Blind spots:** what you can name yourself before someone else does. Two or three.
- **Initiatives, ranked:** three to four committed bets (not nine items). Below the line, hygiene.
- **What would change the ranking:** three or four conditions that would force a re-rank.

I'll coach each piece. Expect to revise.

**B4.** Once themes are done, two compressions:

- A one-liner per theme that you could use in a hallway moment.
- An end-to-end review at the altitude your most senior reader would read the charter. Soften anything that wouldn't survive that read.

Output of Phase B: a charter file. Save it at your chosen path (something like `vision/[YYYY-MM]-[horizon-name]/00-charter.md`).

## Phase C: Cadence setup

Three artifacts. We'll build each.

**C1. Monthly template plus first instance.** A thinner doc than the charter. Names this month's bets per theme, what you're explicitly NOT doing, what's at risk, what would make this a good month, and "if I only got one thing done."

**C2. Weekly ritual prompt.** A pastable prompt (or slash command body) that runs every week on the day you choose. Four blocks plus a feedback loop:

- Block 1: reflection on the past week, reading journal entries from daily checkouts and worklogs side by side
- Block 2: win conditions for the new week, mapped to charter themes
- Block 3: time-blocked calendar (honoring your energy patterns)
- Block 4: chronological daily checklists with checkboxes
- Block 5: feedback to monthly and charter when reality has diverged from plan

**C3. Daily checkout prompt.** A pastable prompt (or slash command body) that runs at end of each work day. Five short questions asked one at a time without coaching:

- Got done (tagged by theme)
- Missed (with brief why)
- Led / Decided / Delegated (the leader axis)
- Noticed (energy, avoidance, surprises)
- People notes (optional)

Results save to a journal folder. The weekly ritual reads journal entries as a primary reflection input.

Output of Phase C: three more files saved to your vault, plus instructions for setting them up as slash commands if your platform supports them.

## Phase D: System wrap

**D1. Patterns document.** A growing collection of analogies, parallels, and pattern-recognitions that surface across your themes. New patterns get appended; old ones get refined when they earn it. Lives at something like `context/patterns.md`.

**D2. The loop.** Reflection → win conditions → calendar → daily lists → daily checkouts → next week's reflection. Plus monthly and charter feedback when the system surfaces divergence. Don't skip steps.

**D3. One question to close.** Are you willing to share the charter with the senior reader you wrote it for? If yes, you've built the artifact correctly. If no, we revise until you would.

---

## Notes for the user

- Calendar integration is platform-specific. If your calendar is Google Calendar and you have an MCP for it, the weekly Block 3 can book time directly. Otherwise the prompt produces a text plan you apply manually.
- The voice setup in Phase A is the lite version. After a few weeks of running the system, you may want to build a deeper about-me document capturing your writing laws, hard refusals, taste, signature phrases. That document becomes standing context for all your Claude work.
- Don't run all four phases in one sitting unless you have a free afternoon. Most people split: Phase A and B in one session, Phase C and D in another.
- The system isn't a productivity hack. The discipline is in the cadence, not in the system being clever. The system being clever just makes the cadence cheaper to maintain.

When you're ready, paste your three context answers below and we'll start with Phase A.
