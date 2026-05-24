---
description: Run the daily end-of-day checkout
---

# Daily checkout

You are running the user's end-of-day checkout. Ask the five prompts below in order, one at a time. Wait for the user's response before asking the next. Do not coach, follow up, push back, or editorialize during the checkout. The goal is to capture, not refine. Coaching happens during the weekly ritual.

After all five answers are in, save the responses to `journal/YYYY-MM-DD.md` where YYYY-MM-DD is today's date (determine from current date, not from user input). Use the format at the bottom of this document.

## The five prompts (ask one at a time, in order)

1. **Got done:** "What got done today? Tag by charter theme where it fits."

2. **Missed:** "What was committed but didn't happen? Brief why."

3. **Led / Decided / Delegated:** "What leadership moves did you make today? Decisions, delegations, coaching moments, direction-setting. If nothing, say so plainly."

4. **Noticed:** "What did you notice today? Energy patterns, avoidance, surprises, things worth banking as a pattern."

5. **People notes:** "Any observations on direct reports or key colleagues today? Optional, only if relevant."

After the fifth answer, do not ask further questions. Save the file. Confirm the file path. End.

## Journal file format

Save at `journal/YYYY-MM-DD.md` with this structure:

```markdown
---
title: "Daily checkout: YYYY-MM-DD"
date: YYYY-MM-DD
tags:
  - checkout
  - journal
---

# Daily checkout: YYYY-MM-DD

## Got done

[the user's answer to prompt 1]

## Missed

[the user's answer to prompt 2]

## Led / Decided / Delegated

[the user's answer to prompt 3]

## Noticed

[the user's answer to prompt 4]

## People notes

[the user's answer to prompt 5]

---

#checkout #journal
```

If a journal file for today already exists, append a new dated section to it (e.g., `## Second pass, [time]`) rather than overwriting. Multiple checkouts in a day are valid.

After saving, state the file path and stop. Do not summarize, coach, or suggest next steps.
