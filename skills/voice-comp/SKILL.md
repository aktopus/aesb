---
name: voice-comp
description: Use when Akpanoluo says he has finalized, reworded or sent a piece Claude drafted for him (Slack message, email, Jira comment, document passage) and wants the before and after kept as a voice example, or invokes /voice-comp.
argument-hint: "[his final text, or where it lives]"
---

# /voice-comp

Keeps a pair: what Claude drafted, and what Akpanoluo said once he put it in his own words. The pairs are raw material for a later assessment of how his wording differs from Claude's.

This skill captures. It does not assess the difference, and it does not touch `akpanoluo_about_me.md` or `akpanoluo_voice_profile.md`.

## Where the pair goes

```
/Users/akpanoluo/code/vault/context/voice/examples/YYYY-MM-DD-NN/
    claude-speak.md
    akpanoluo-speak.md
```

The date is the day he finalized, in ET. `NN` is that day's sequence, from `01`. Next free directory:

```bash
d=/Users/akpanoluo/code/vault/context/voice/examples; day=$(TZ=America/New_York date +%F)
n=$(ls -d "$d/$day"-* 2>/dev/null | wc -l | tr -d ' '); printf '%s/%s-%02d\n' "$d" "$day" $((n+1))
```

## Steps

1. **Find his text.** In order: the skill arguments, his message, then the place it lives (a sent Slack message, a Jira comment, a file). An unsent Slack draft cannot be read back, so ask him to paste it. Take his text only from one of these, never from his description of what he changed.
2. **Find Claude's text.** The last complete version Claude wrote before he took over the wording. If Claude rewrote the draft mid-conversation to fix a fact, the rewrite is the one. If it is gone from context, look for an open directory (step 3), then the session transcript.
3. **Pick the directory.** A directory that holds `claude-speak.md` and no `akpanoluo-speak.md` for this same piece is open: complete it. Otherwise take the next free one.
4. **Write both files** in the shape below.
5. **Report in one line:** the directory path and how many examples the folder now holds. No commentary on the differences unless he asks.

## File shape

```markdown
---
date: 2026-10-06
medium: Slack group DM
audience: Taylor Smolik, Pete Rooney
about: one line on what the piece is for
content_changes: none
claude_wording: none
---

<the text>
```

- `audience` and `about` are the same in both files.
- `content_changes` goes in `akpanoluo-speak.md` only: `none`, or one short line per fact he added, dropped or corrected. It lets the later assessment tell a change of fact from a change of wording.
- `claude_wording` also goes in `akpanoluo-speak.md` only: `none`, or one line per passage of his final that Claude wrote in a later round (he asked for part of it to be rewritten and kept the result). Name what is his inside a mixed passage. Without it the assessment reads Claude's sentences as his voice. First seen on `2026-10-06-01`.
- **His text is verbatim**: his casing, punctuation, line breaks, typos and emoji, exactly as written. Claude's text is verbatim too. A link he describes ("these words carry the link") is written as a markdown link on those words.
- Slack mentions are written as `@Full Name`, not `<@U…>` ids.
- A piece that went out as several messages is one example; separate the messages with a line holding only `---`.

## Opening a pair early

When Claude hands him a draft and he says he will rework it, write `claude-speak.md` into the next free directory then, so a context compaction cannot lose the original. If Claude later rewrites the draft, overwrite that file. `/voice-comp` completes the pair.

## Leave out

Text carrying credentials or anything he marked private. Say so and save nothing.
