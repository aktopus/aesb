#!/usr/bin/env bash
# unbounded-arrayagg-lob.sh — gotcha check for ASB-3753-class issues.
#
# Reads a unified diff on stdin; runs from the worktree root. Fires when the
# diff ADDS an ARRAY_AGG / LISTAGG / OBJECT_AGG over per-arcid or per-session
# event data without a visible bound (a QUALIFY row cap, a LIMIT inside the
# grouped subquery, or an ARRAY_SLICE) in the same hunk.
#
# Why: Snowflake caps any single value at 128 MB (134,217,728 bytes). An
# aggregate keyed by (day, arcid, sid) is bounded only by how many events one
# browser session can send, and on 2026-09-04 one silo66 session sent 554,316
# — the aggregate hit the ceiling and daily_proc failed three nights. See
# airflow-dag-gotchas.md #29.
#
# Silent unless the diff adds an unbounded aggregate.

set -uo pipefail

diff_input="$(cat)"

added="$(grep -nE "^\+.*(array_agg|arrayagg|listagg|object_agg)[[:space:]]*\(" <<< "$diff_input" | grep -viE "^[0-9]+:\+[[:space:]]*--" || true)"
[[ -n "$added" ]] || exit 0

# A bound anywhere in the added lines of the diff clears the check. Coarse on
# purpose: the point is to make the author say where the bound is.
if grep -qiE "^\+.*(qualify[[:space:]]+(count|row_number)\(|array_slice[[:space:]]*\(|within[[:space:]]+group.*limit|10000|<=[[:space:]]*[0-9]{3,})" <<< "$diff_input"; then
    exit 0
fi

echo "GOTCHA #29 — unbounded aggregate added without a visible per-group bound:"
sed 's/^/    /' <<< "$added"
echo "  Snowflake caps a single value at 128 MB. If this aggregates per arcid/session/day,"
echo "  one runaway client session can overflow it (ASB-3753: 554,316 events in 8 minutes)."
echo "  Bound the group (QUALIFY COUNT(*) OVER (PARTITION BY …) <= N, or ARRAY_SLICE) or say why it cannot grow."
