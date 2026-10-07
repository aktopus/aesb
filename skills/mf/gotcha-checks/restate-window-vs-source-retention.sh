#!/usr/bin/env bash
# restate-window-vs-source-retention.sh — gotcha check for the ASB-3431/3406-class
# issue: a full-window restate against a retention-bounded source silently EMPTIES
# destination partitions.
#
# Reads a unified diff on stdin; runs from the worktree root.
#
# Fires when the diff changes a trailing-window/lookback value, or introduces a
# WRITE_TRUNCATE / partition-replace restate loop. In either case the reviewer has
# to answer a question no diff can answer on its own: does the SOURCE still hold
# every day the new window asks for?
#
# Why it can't be decided statically: the answer lives in the source system's
# current MIN(date), which moves daily (measured 2026-08-10 -> 2026-08-11: an
# Iceberg keywords table's floor advanced 07-09 -> 07-10 inside twelve hours). So
# this check surfaces the obligation and names the exact query to run, rather than
# pretending to a verdict.
#
# Silent unless the diff touches a window value or a truncating load.

set -uo pipefail

diff_input="$(cat)"

lookback_lines="$(grep -nE "^\+.*(lookback_days|lookback|LOOKBACK|trailing_days|window_days)['\"]?[[:space:]]*[:=]" <<< "$diff_input" || true)"
truncate_lines="$(grep -nE "^\+.*(WRITE_TRUNCATE|write_truncate|load_partition_replace|partition_replace)" <<< "$diff_input" || true)"

[[ -z "$lookback_lines" && -z "$truncate_lines" ]] && exit 0

echo "restate-window-vs-source-retention: this diff changes a restate window and/or a truncating partition load. Confirm the SOURCE retains every day the window asks for before merging."

if [[ -n "$lookback_lines" ]]; then
    echo "  window value(s) added/changed:"
    sed 's/^/      /' <<< "$lookback_lines"
fi
if [[ -n "$truncate_lines" ]]; then
    echo "  truncating load(s) added:"
    sed 's/^/      /' <<< "$truncate_lines" | head -5
fi

cat <<'NOTE'
  WHY THIS IS NOT A NIT: a restate loop clears any day its query returned no rows
  for — deliberately, so an upstream correction-to-zero propagates. It cannot tell
  "genuinely empty now" from "DELETEd by the source's rolling retention". A window
  reaching past the source's floor therefore rewrites real destination partitions as
  EMPTY, and a `loaded_days == 0`-style guard does NOT catch it: that only fires when
  the ENTIRE window came back empty, never per-day. The task goes green.

  Sources with rolling retention in this repo (non-exhaustive):
    * daily_test Iceberg ports  — DELETE ... WHERE day < ds-31   (~32d held)
    * daily_ci upsert()         — DELETE ... WHERE day <= ds-550 (daily_ci/shared.py)
    * SP_DAILY_PROCSQL10 cleanup— delete ... day <= dateadd(day,-365,current_date)
  BUT measure, don't assume: TABLE AGE often binds before the retention rule does
  (measured 2026-08-11: GAM_CAMPAIGN_BRAND_SAFETY held ~130d against a nominal 550d).

  ASK THE SOURCE, for every time-series source the changed code reads:
      -- Snowflake (0 bytes on an Iceberg read-through, ~97ms)
      SELECT MIN(<date_col>), MAX(<date_col>) FROM <source>;
      -- Athena/Trino
      SELECT MIN(day), MAX(day) FROM <glue_db>.<table>;
  and require  (anchor - lookback) >= MIN(date_col)  for EVERY source, taking the
  TIGHTEST floor — an inner-joined source that dropped a day empties the partition,
  and an OUTER-joined one fills it with COALESCE(...,0) zeros, which is worse
  because it reads as a real business figure.

  Prior art to copy rather than re-derive: atlantic_bigquery_silo69.py declares
  per-dim `retention_sources` and enforces the floor in
  `_assert_window_within_retention` BEFORE the paid scan. See airflow-dag-gotchas.md #19.
NOTE
