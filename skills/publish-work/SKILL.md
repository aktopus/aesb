---
name: "publish-work"
description: "Publish (or update) a claude.ai Artifact under the ArcSpan work account (aetteh@arcspan.com, ArcSpan Team org) from a session signed into the personal Max account, by delegating the publish to the `artifact-publisher` peer session. Use when the user says /publish-work, 'publish this to the work account', 'work artifact', 'make this shareable with the team', or any time an artifact must be visible to ArcSpan teammates. Never substitute the local Artifact tool while the session is on the personal account — that publishes to the wrong org; if the session is itself signed into the work account, use the local tool directly."
---

# /publish-work

Day-to-day sessions run on the personal Max account; Artifacts they publish land in the personal
org and can only be shared by public link. The Artifact tool binds to the session's login, has no
per-tool override, and is absent in headless mode — so work-account publishing goes through a
second interactive session, `artifact-publisher`, signed in as aetteh@arcspan.com in the isolated
config dir `~/.claude-work`. This skill hands that session a file and relays the URL it returns.

**Usage:** `/publish-work <file> [--title T] [--desc D] [--favicon E] [--url U] [--label L] [--force]`
Bare `/publish-work` = publish the artifact page most recently written in this session.

## Procedure

0. **Which account is this session on?** `claude auth status` (in Bash; it reports the main config dir,
   which is this session's login). If `email` is already `aetteh@arcspan.com`, skip the publisher: this
   session's own `Artifact` tool publishes into ArcSpan Team directly — call it as normal (load
   `artifact-design` first if you are still writing the page) and stop here. Updating a page the
   publisher originally published works the same way; `WebFetch` the URL first if you hit a version
   conflict. Only the personal-account case goes on to step 1.
1. **Resolve the page.** Absolute path, must exist, must be `.html`/`.htm`/`.md`. Fill `title`
   (only needed if the file has no `<title>`), `description` (one sentence), `favicon` (1–2 emoji,
   stable across redeploys) from the args, else from the page you built, else ask. If this is an
   update of an artifact already published on the work account, carry its `url` — without it the
   publisher creates a new page.
2. **Find the publisher.** Call `ListAgents` and look for a peer named `artifact-publisher`.
   Load `SendMessage` via ToolSearch (`select:SendMessage`) if it isn't loaded.
   - **Absent** → it normally runs as a background session that every new terminal re-starts if needed.
     Start it yourself: `Bash: /Users/akpanoluo/code/scripts/artifact-publisher` (idempotent; prints why
     if it can't — usually `--login` needed, which only the user can do in a browser). Re-run `ListAgents`.
     Still absent → stop and tell the user what the launcher printed.
     Do **not** fall back to the local `Artifact` tool unless the user explicitly says to publish
     under the personal account.
3. **Send the request** to `artifact-publisher`:
   ```
   PUBLISH REQUEST
   file: <abs path>
   title: <title>            (omit if the file has a <title>)
   description: <one sentence>
   favicon: <emoji>
   url: <existing work-account artifact URL>   (only when updating)
   label: <short version label>                (optional)
   force: yes                                  (only after the user explicitly OKs overwriting a newer live version)
   reply-to: <this session's name from ListAgents>
   ```
4. **Wait for the reply** — it arrives as a `<cross-session-message from="artifact-publisher">`, `PUBLISHED <url>` or
   `PUBLISH FAILED <reason>`. Don't poll, don't re-send. The publish itself takes ~10s.
   **If nothing arrives within ~2 min and `ListAgents` shows the publisher idle, the reply was almost
   certainly held at *this* session's door, not lost:** the sender's bypass mode and the publisher's
   prompting mode fail mode-parity, so the reply is parked for approval and expires after `dialogExpiry`
   (5 min). `~/.claude/settings.json` sets `crossSessionInbound: "accept"` (added 2026-08-21) to stop
   this; a session started before that key existed still holds. Recover the URL from the publisher's
   own transcript rather than re-sending:
   ```bash
   grep -h "<your basename>" ~/.claude-work/projects/-Users-akpanoluo--claude-work-workspace/*.jsonl \
     | grep -o 'https://claude.ai/code/artifact/[0-9a-f-]*' | tail -1
   ``` If it hasn't arrived after a few
   minutes, the publisher may be sitting on a permission prompt — `artifact-publisher --attach` shows it.
   `PUBLISH FAILED — newer live version exists` means someone edited the page since it was last
   published (Team editors can). Surface that to the user; re-send with `force: yes` **only** on their OK.
4.5. **Stalled? Hand over the commands, with a verdict.** If no URL is in hand when you reply, the
   reply carries these verbatim plus one line saying whether the old session must be killed:
   ```
   publish                              # one shot: ensure running, print status + what it is parked on, attach
   artifact-publisher --status
   artifact-publisher --needs           # the prompt it is parked on (usually "approve Artifact: <file>")
   artifact-publisher --attach          # look; ← on an empty prompt detaches
   artifact-publisher --stop && artifact-publisher   # dead turn: kill + restart
   ```
   `publish` is the zsh shortcut (added 2026-09-14, `~/.zshrc`) — lead with it; the rest are its parts.
   Verdict comes from `~/.claude-work/jobs/<first-8-of-session-id>/state.json` (`state`, `detail`,
   `updatedAt`) and the transcript mtime: `working` with no transcript write for >15 min = dead →
   "kill it". A restart empties the queue — re-send the PUBLISH REQUEST yourself afterwards.
   (Added 2026-09-04 after a 2h+ hang; see MEMORY `feedback_publisher_stall_hand_over_commands`.)
5. **Relay.** Give the user the URL, note it was published as aetteh@arcspan.com, and remind them
   sharing (specific people / everyone at ArcSpan) is done from the page's Share control. Record the
   URL next to the page's source (worklog `overview.md`, deck doc, etc.) so later updates can pass it.

## Gotchas

- The publisher's allow-list is Read/Glob/Artifact/ListAgents/SendMessage only; it can't fix the
  page. If it reports a failure about content (size > 16 MiB, bad extension), fix here and re-send.
- Live-data (connector-backed) pages declare connectors from the **publishing** account, so the
  work claude.ai login must have those connectors attached. Static pages don't care.
- The publisher may read `claude.ai` artifact URLs (to sync the live version before an update) and nothing else; Bash, edits, search are denied.
- The publisher auto-accepts peer messages (`crossSessionInbound: "accept"` in `~/.claude-work/settings.json`). If a request sits unanswered, check that tab — a session started before that key existed holds each message for approval instead.
- The publisher session is discoverable only because `~/.claude-work/sessions` symlinks to
  `~/.claude/sessions`; the launcher re-creates the link every start.

- **`--attach` says "No job matching <uuid>"** — `claude attach` keys on the 8-char daemon job id, not the
  session UUID. The launcher was fixed 2026-08-24 (`${sid:0:8}`); if it recurs, run
  `CLAUDE_CONFIG_DIR=$HOME/.claude-work claude attach <first-8-of-session-id>` directly. The job's
  pending prompt is readable without attaching: `~/.claude-work/jobs/<short-id>/state.json` → `needs`.
