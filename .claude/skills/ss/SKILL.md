---
name: "ss"
description: "Pull N most recent macOS screenshots from /Users/akpanoluo/Documents/screenshots/ into context as inline images. /ss = latest 1; /ss 5 = latest 5 (newest first). Optimized for speed — read the files and stop, no description, no narration."
---

# /ss

Speed is the contract. The user's next message after `/ss` will almost always supply the context — what these screenshots are, why they matter, what to do with them. **Read the files and stop.** Don't describe, don't summarize, don't ask "what would you like to discuss?" — just load the images and end the turn. The user's follow-up will tell you what they're actually trying to accomplish; any commentary you generate first is either redundant with their forthcoming framing or guesses wrong about what's salient.

1. **N** = the integer argument, or `1` if none.
2. **Get paths** (substitute N):
   ```bash
   find /Users/akpanoluo/Documents/screenshots -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.heic' \) -exec stat -f '%m %N' {} + 2>/dev/null | sort -rn | head -n N | cut -d' ' -f2-
   ```
3. **Read each path** via the Read tool. Then end the turn — no closing prose. The user will speak next.

Edge cases — one-line responses, no investigation:
- 0 rows → "no screenshots in `~/Documents/screenshots/`."
- Non-integer / negative / zero arg → "got `<arg>`, expected positive integer."
