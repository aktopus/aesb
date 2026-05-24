# aesb — Akpanoluo Etteh's Second Brain

A working set of Claude skills, prompts, and standing instructions for running
a strategy-to-execution operating system on top of Claude Code and Claude
Cowork. The system bridges a multi-month charter, monthly bets, a weekly
ritual that time-blocks the week, and a daily checkout that captures what
actually happened.

The inciting idea came from Dini Gurunandini's post "I let Claude plan my
entire week." The shape here is calibrated for knowledge workers navigating a
specific multi-month horizon (a review, a board moment, a contractor-to-perm
conversation, a launch). Everything is plain markdown plus bash, so the
system survives Claude eventually retiring features or you eventually
retiring Claude.

## What's in the box

Five skills, two slash commands, one cowork-project briefing, and two vision
artifacts. Each is documented in its own SKILL.md or markdown header. Briefly:

Slash commands (in `commands/`):

- `checkout` runs the end-of-work-day ritual that produces a journal entry,
- `weekly-ritual` runs the day-of-your-choosing session that reads last week's
  journal entries and time-blocks the new week.

Skills (in `skills/`):

- `worklog` writes per-chat worklog entries when a task wraps,
- `defer` parks follow-up work in `~/Documents/vault/deferred/` with a
  return date the SessionStart hook surfaces later,
- `new-window` spawns fresh Claude sessions from current work with
  self-contained handoff materials,
- `ss` pulls the N most recent macOS screenshots into context as inline
  images,
- `mf` (merge-flow) runs the full ship sequence on a feature branch,
  with platform multi-select for GitHub, GitLab, Bitbucket, and CodeCommit.

The `cowork-projects/` directory holds `thought-partner.md`, a templated
briefing for Claude as an ongoing thought-partner relationship calibrated to
push you toward leader-altitude writing and structural argument. Fill in the
`{{placeholder}}` markers with your own benchmark, voice document path, and
vault paths.

The `vision/` directory holds `system-builder-prompt.md` (the two-to-four-hour
bootstrap conversation that produces a charter, a monthly template, the
weekly and checkout prompts, and a patterns document) and `system-summary.md`
(a narrative explainer of how the system works once it's running). The
builder prompt is the lift; the skills are the cadence that keeps the lift
from going stale.

## Install

The canonical install target is **Claude Code v2.1.150+ via its plugin
marketplace**. If you're on an older Claude Code, on Cowork, or want a
non-plugin install for any other reason, the `install.sh` bootstrap is the
fallback. Other code agents (Cursor, Aider, Codex CLI, GitHub Copilot, etc.)
can adapt the skills with some agent-specific edits to frontmatter and
conventions; the package is built around the Claude SKILL.md shape but the
underlying prompts are portable.

### Plugin install (the canonical path)

In a Claude Code session:

    /plugin marketplace add aktopus/aesb-marketplace
    /plugin install aesb
    /reload-plugins

After install, skills and commands resolve under the `aesb:` namespace —
`/aesb:worklog`, `/aesb:defer`, `/aesb:checkout`, etc. Updates land via
`/plugin install aesb` once new versions are tagged in the marketplace stub.

The marketplace metadata lives at https://github.com/aktopus/aesb-marketplace
(a small repo that just points back at this one). The split exists because
Claude Code's plugin install flow does two separate clones — one for the
marketplace, one for the plugin — and a self-pointing config fails its
schema validator.

### Bootstrap script (fallback for older Claude Code, Cowork, or non-plugin contexts)

If you're on Claude Code older than v2.1.150, running aesb under a
non-plugin surface (Cowork, plain Claude.ai), or you'd rather wire skills
in via symlink than via the plugin manager, clone the repo and run the
bootstrap:

    git clone https://github.com/aktopus/aesb ~/code/aesb
    cd ~/code/aesb
    ./install.sh

The script creates `~/Documents/vault/{worklog,journal,deferred}`, symlinks
each skill under `~/.claude/skills/` and each command under
`~/.claude/commands/` to its location in the repo, and optionally appends
a small worklog standing instruction to `~/.claude/CLAUDE.md`. Re-running
is safe. Any existing entries that would collide get backed up rather than
clobbered.

Edits in the repo propagate to Claude Code on the laptop through the
symlinks. To reverse the bootstrap at any time, run `./uninstall.sh` from
the repo root. It removes only the symlinks that point into *this* repo,
strips the marker-bracketed worklog block from `~/.claude/CLAUDE.md`, and
leaves all your vault content (`~/Documents/vault/`) and any `install.sh`
backup directories untouched. Pass `--yes` to skip the confirmation prompt.

### Other code agents

If you're running another agent (Cursor, Aider, Codex CLI, GitHub Copilot,
etc.), expect to adapt the SKILL.md frontmatter and slash-command
conventions to whatever your agent expects. The underlying prompts are
portable; the wrappers are not.

## What to do in your first month

The full system is a habit, not a tool, and people who try to adopt all of
it on a Saturday tend to bounce off by Tuesday. The sequence that survives
contact with a real week:

**Day 1.** Install the plugin and run `install.sh`. Use `/ss` and `/defer`
immediately on whatever you're working on. They have near-zero adoption cost
and they prove your install is wired correctly. Don't touch the rest yet.

**Week 1.** Run `/checkout` every workday. Let your `~/Documents/vault/journal/`
fill up. Use the `worklog` standing instruction to drop chat-session worklogs
in `~/Documents/vault/worklog/`. The weekly ritual has nothing to reflect on
without a populated journal and worklog directory, so build that first.

**The weekend after Week 1.** Block two to four hours, open a fresh Claude
session, and paste `vision/system-builder-prompt.md`. The conversation
produces your charter, the monthly template, the customized weekly ritual,
and the patterns document. Don't try to compress this. The cognitive lift is
the point.

**Week 2 onward.** Run `/weekly-ritual` on your chosen day, `/checkout` daily,
monthly review on the first weekend of the month. When something doesn't fit
the cadence, drop it in `/defer` and let the SessionStart hook surface it
later.

**When you start writing code with Claude.** Run `/mf` for the first time;
it'll ask which platform hosts the repo (GitHub, GitLab, Bitbucket, AWS
CodeCommit, or "tell me") and proceed with that platform's CLI commands.

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

## You're on the templated build (`main`)

This branch is the public, templated build: generic vault paths, no specific
benchmark, no specific charter, multi-platform merge-flow. `git clone` lands
you here by default; `/plugin install aesb` resolves here too.

The repo also has a `personal` branch — the author's lived-in fork with
personalizations intact (specific benchmark, real vault paths, a single
chosen platform for the merge-flow). If you've landed on that branch by
accident, the personal-branch README links back here.

Contributions go to `main` via PR. Refinements that travel `personal -> main`
go through a per-skill de-personalization pass, which is a Claude
conversation per skill rather than a regex pass. Most personalizations
carry information about the generalizable shape, so the pass is where the
templated version actually earns its keep.

## Where things go

| What                | Where                                        |
|---------------------|----------------------------------------------|
| Skills (source)     | `<repo>/skills/<name>/SKILL.md`               |
| Skills (laptop)     | `~/.claude/skills/<name>` (symlink)           |
| Journal entries     | `~/Documents/vault/journal/YYYY-MM-DD.md`     |
| Worklogs            | `~/Documents/vault/worklog/YYYY/MM-month/...` |
| Deferred items      | `~/Documents/vault/deferred/`                 |
| Charter, monthly    | `~/Documents/vault/vision/` (you create)      |
| Voice document      | `~/Documents/vault/context/voice/`            |

## Credits

The strategic-OS shape descends from Dini Gurunandini's "I let Claude plan
my entire week." The weekly-ritual and daily-checkout patterns are a direct
lift from her conversation, generalized. The voice-extraction step descends
from Ruben Hassid's "You're Just a Text File." The `ss` screenshot-pull
skill descends from Allie K. Miller's one-minute Claude tip post on
LinkedIn (https://www.linkedin.com/posts/alliekmiller_give-me-one-minute-and-ill-improve-your-activity-7457149184710758400-EYs1).
