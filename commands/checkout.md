---
description: Run the daily end-of-day checkout
argument-hint: "[yesterday | YYYY-MM-DD]  (optional — defaults to today)"
---

# Daily checkout

You are running Akpanoluo's end-of-day checkout. Ask the five prompts below in order, one at a time. Wait for the user's response before asking the next. Do not coach, follow up, push back, or editorialize during the checkout. The goal is to capture, not refine. Coaching happens on Sundays.

## Mark the checkout window (iTerm2 only) — do this first, silently

Before resolving the date or asking anything, flag this window deep blue so Akpanoluo can spot the day's checkout/tracking window among many open windows. Run this **once** at the very start. Do **not** announce it, comment on it, or report success/failure — it is a silent cosmetic cue, not part of the capture:

```bash
[ "$TERM_PROGRAM" = "iTerm.app" ] && osascript -e 'tell application "iTerm2" to tell current session of current window to set background color to {771, 6425, 13107}' 2>/dev/null || true
```

- **Color:** `{771, 6425, 13107}` is `#031933` (deep midnight blue) in iTerm2's 16-bit-per-channel scale (hex × 257).
- **Use `osascript`, not a `printf '\033]11;...'` escape sequence.** This command runs in a detached pty with no controlling tty, so an OSC escape would be captured into tool output instead of reaching the screen. `osascript` reaches iTerm2 out-of-band via Apple Events and works regardless of tty.
- **The `$TERM_PROGRAM` guard + `2>/dev/null || true` make this strictly non-blocking:** a no-op in any non-iTerm2 terminal, and a denied macOS automation permission (or any other failure) is swallowed silently. The checkout must never be blocked or delayed by this cosmetic step.
- **Do not reset the color** at the end. It is per-session and intended to persist for the life of the window, so the window stays findable all day.

## Resolving the checkout date

The checkout target date is `$ARGUMENTS` (may be empty). Resolve it BEFORE asking any prompt, and use the resolved date everywhere below in place of `YYYY-MM-DD`:

- **Empty / missing** → today's date (from the `currentDate` context line).
- **`yesterday` or `y`** → today minus 1 day. Use this when running a late-night checkout (post-midnight) for the prior day's work.
- **A literal `YYYY-MM-DD`** (e.g. `2026-05-26`) → use it verbatim. No validation gymnastics; if it's obviously malformed, surface that and stop.
- **Anything else** → echo what you parsed, ask the user to confirm or correct, then proceed.

Once resolved, state the target date in one short line before the first prompt (e.g. "Checking out for 2026-05-26.") so the user can catch a mis-parse early. Do not add coaching to that line.

After all five answers are in, save the responses to the **absolute** path `/Users/akpanoluo/code/vault/journal/YYYY-MM-DD.md` where `YYYY-MM-DD` is the **resolved target date** (NOT necessarily today). Always write this absolute path — never a relative `journal/...` path, which resolves against whatever directory the session is running from and scatters entries outside the vault. Use the format at the bottom of this document.

## The five prompts (ask one at a time, in order)

1. **Got done:** "What got done today? Tag by charter theme where it fits (cost / agentic / talent / leadership)."

2. **Missed:** "What was committed but didn't happen? Brief why."

3. **Led / Decided / Delegated:** "What leadership moves did you make today? Decisions, delegations, coaching moments, direction-setting. If nothing, say so plainly."

4. **Noticed:** "What did you notice today? Energy patterns, avoidance, surprises, things worth banking as a pattern."

5. **People notes:** "Any observations on direct reports or key colleagues today? Optional, only if relevant."

After the fifth answer, do not ask further questions. Save the file. Confirm the file path. End.

## Journal file format

Save at `/Users/akpanoluo/code/vault/journal/YYYY-MM-DD.md` with this structure:

```markdown
---
title: "Daily checkout: YYYY-MM-DD"
owner: Akpanoluo Etteh
date: YYYY-MM-DD
tags:
  - checkout
  - journal
---

# Daily checkout: YYYY-MM-DD

## Got done

[Akpanoluo's answer to prompt 1]

## Missed

[Akpanoluo's answer to prompt 2]

## Led / Decided / Delegated

[Akpanoluo's answer to prompt 3]

## Noticed

[Akpanoluo's answer to prompt 4]

## People notes

[Akpanoluo's answer to prompt 5]

---

#checkout #journal #akpanoluo
```

If a journal file for the resolved target date already exists, append a new dated section to it (e.g., `## Second pass, [time]`) rather than overwriting. Multiple checkouts for the same day are valid.

After saving, **confirm the file actually exists on disk** (the write isn't "done" until verified — this is the step that prevents a checkout that only *looks* complete). Then end with this exact two-line completion marker as the final thing in your reply, and nothing after it:

```
🟢 ✅ Checkout saved
   → /Users/akpanoluo/code/vault/journal/YYYY-MM-DD.md
```

The 🟢 / ✅ are the green completion cue — they always render in color in the terminal, unlike hex-colored text. Do not summarize, coach, or suggest next steps. The green marker is the last thing on screen so the completion signal is unmissable.
