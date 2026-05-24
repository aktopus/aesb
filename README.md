# aesb — Akpanoluo Etteh's Second Brain

A working set of Claude skills, prompts, and standing instructions for running
a strategy-to-execution operating system on top of Claude Code and Claude
Cowork. The system bridges a multi-month charter, monthly bets, a Sunday
ritual that time-blocks the week, and a daily checkout that captures what
actually happened. It is the artifact behind the May 2026 Newtown Analytics
Data Salon talk "AI and the Second Brain."

The inciting idea came from Dini Gurunandini's post "I let Claude plan my
entire week." The shape here is calibrated for knowledge workers navigating a
specific multi-month horizon (a review, a board moment, a contractor-to-perm
conversation, a launch). Everything is plain markdown plus bash, so the
system survives Claude eventually retiring features or you eventually
retiring Claude.

## What's in the box

The repo ships seven skills, one cowork-project briefing, and a builder
prompt. Each is documented in its own SKILL.md or markdown header. Briefly:

- `checkout` runs the end-of-work-day ritual that produces a journal entry,
- `weekly-ritual` runs the Sunday-or-whatever-day-you-pick session that reads
  last week's journal entries and time-blocks the new week,
- `worklog` writes per-chat worklog entries when a task wraps,
- `defer` parks follow-up work in `~/Documents/vault/deferred/` with a
  return date the SessionStart hook surfaces later,
- `new-window` spawns fresh Claude sessions from current work with
  self-contained handoff materials,
- `ss` pulls the N most recent macOS screenshots into context as inline
  images,
- and `mf` (merge-flow) runs the full ship sequence on a feature branch,
  customizable per platform via its setup conversation.

The cowork-projects directory holds `thought-partner.md`, a briefing for
Claude as an ongoing thought-partner relationship calibrated to push you
toward leader-altitude writing and structural argument.

The vision directory holds `system-builder-prompt.md`, the two-to-four-hour
bootstrap conversation that produces a charter, a monthly template, the
Sunday and checkout prompts, and a patterns document. This is the lift; the
skills are the cadence that keeps the lift from going stale.

## Install

Two paths. Most people will want both.

### Plugin install (loads in every Claude Cowork window)

In a Claude Code or Cowork session:

    /plugin marketplace add aktopus/aesb
    /plugin install aesb

From then on, the skills load at session start without anything mounted in
the session. This is the only way to get always-on Cowork access; the laptop
`~/.claude/skills/` path is not scanned by Cowork.

### Clone + install.sh (lets you edit skills locally)

If you want to edit the skills, refine them against your own taste, or hold
the `personal` branch as a long-lived fork, clone the repo and run the
bootstrap:

    git clone https://github.com/aktopus/aesb ~/code/aesb
    cd ~/code/aesb
    ./install.sh

The script creates `~/Documents/vault/{worklog,journal,deferred}`, symlinks
each skill under `~/.claude/skills/` to its location in the repo, and
optionally appends a small worklog standing instruction to
`~/.claude/CLAUDE.md`. Re-running is safe. Any existing `~/.claude/skills/`
entries that would collide get backed up rather than clobbered.

Edits in the repo propagate to Claude Code on the laptop through the
symlinks, and to Claude Cowork via `git push` plus a plugin reload.

## What to do in your first month

The full system is a habit, not a tool, and people who try to adopt all of
it on a Saturday tend to bounce off by Tuesday. The sequence that survives
contact with a real week:

**Day 1.** Install the plugin and run `install.sh`. Use `/ss` and `/defer`
immediately on whatever you're working on. They have near-zero adoption cost
and they prove your install is wired correctly. Don't touch the rest yet.

**Week 1.** Run `/checkout` every workday. Let your `~/Documents/vault/journal/`
fill up. Use the `worklog` standing instruction to drop chat-session worklogs
in `~/Documents/vault/worklog/`. The Sunday ritual has nothing to reflect on
without a populated journal and worklog directory, so build that first.

**The weekend after Week 1.** Block two to four hours, open a fresh Claude
session, and paste `vision/system-builder-prompt.md`. The conversation
produces your charter, the monthly template, the customized Sunday ritual,
and the patterns document. Don't try to compress this. The cognitive lift is
the point.

**Week 2 onward.** Run `/weekly-ritual` Sunday, `/checkout` daily, monthly
review on the first weekend of the month. When something doesn't fit the
cadence, drop it in `/defer` and let the SessionStart hook surface it later.

**When you start writing code with Claude.** Run the `mf` skill's setup
conversation to configure merge-flow for your platform (GitHub, GitLab,
CodeCommit, etc.).

## Voice extraction

A few of the artifacts here lean on having a voice document — a markdown
file describing how you write, what you refuse, what you sound like at peak
clarity. The fastest path I know to producing one is Ruben Hassid's process
in "You're Just a Text File"
(https://ruben.substack.com/p/youre-just-a-text-file). The post sells it as
a voice-extraction exercise, which it is, and the more interesting outcome
is that the conversation surfaces higher-level thinking you didn't know
you'd articulated. For me it produced the voice document and a four-month
vision draft in the same sitting. Worth the two hours.

## Personal vs main branch (for contributors and forkers)

The repo runs two long-lived branches. `main` is the public, templated
build: no Galloway-as-benchmark line, no ArcSpan paths, no specific charter.
`personal` is my lived-in fork with the personalizations intact. The
templated build is what `git clone` lands you in by default; the personal
branch exists so I can use the same repo as my daily driver.

Contributions go to `main` via PR. Refinements I want to publish from my
own use travel `personal -> main` through a per-skill de-personalization
pass, which is a Claude conversation per skill rather than a regex pass.
Most personalizations carry information, so the pass is where the
generalizable shape gets articulated. That conversation is where the actual
value of the templated version lives.

## Where things go

| What                | Where                                        |
|---------------------|----------------------------------------------|
| Skills (source)     | `<repo>/.claude/skills/<name>/SKILL.md`       |
| Skills (laptop)     | `~/.claude/skills/<name>` (symlink)           |
| Journal entries     | `~/Documents/vault/journal/YYYY-MM-DD.md`     |
| Worklogs            | `~/Documents/vault/worklog/YYYY/MM-month/...` |
| Deferred items      | `~/Documents/vault/deferred/`                 |
| Charter, monthly    | `~/Documents/vault/vision/` (you create)      |
| Voice document      | `~/Documents/vault/context/voice/`            |

## Credits

The strategic-OS shape descends from Dini Gurunandini's "I let Claude plan
my entire week." The Sunday-ritual and daily-checkout patterns are a direct
lift from her conversation, generalized. The voice-extraction step descends
from Ruben Hassid's "You're Just a Text File." The `ss` screenshot-pull
skill descends from Allie K. Miller's one-minute Claude tip post on
LinkedIn (https://www.linkedin.com/posts/alliekmiller_give-me-one-minute-and-ill-improve-your-activity-7457149184710758400-EYs1).
The salon framing is Soundshop, with the Data Salon being a 2026
collaboration with Michael Bartoli of Newtown Analytics.
