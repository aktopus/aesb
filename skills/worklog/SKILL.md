---
name: worklog
description: "Use when the user signals a task is wrapping up (says 'done', 'ship it', 'good for now', 'wrapping up', finishes a merge flow), or invokes /worklog explicitly."
---

# /worklog

Write a worklog entry summarizing the chat session. Default location:

    ~/Documents/vault/worklog/YYYY/MM-month/YYYY-MM-DD-<topic>/overview.md

If a worklog for the active task already exists, update it rather than creating a new one. Use today's real date (run `date +%Y-%m-%d` if unsure) and a kebab-case topic slug derived from the session's dominant theme.

Sections (use these defaults; trim or extend as the session warrants):

- **TL;DR** — one to three sentences naming the punchline of the session,
- **What I did** — a bulleted summary of the actions taken, files touched, decisions made,
- **What I'm leaving for next time** — open questions, unfinished work, anything that should be picked up later or deferred,
- and **Verification / spot-checks** — the actual commands or test runs that confirmed the work, in code blocks so they're rerunnable.

Skip silently if the session produced nothing worth a worklog (chat-only, no findings, no decisions). Don't write speculative worklogs.
