#!/usr/bin/env bash
# current-date-session-clock.sh — gotcha check for #17c.
#
# Reads a unified diff on stdin. Flags added lines that anchor a RELATIVE
# window on CURRENT_DATE / CURRENT_TIMESTAMP (via DATEADD / DATE_TRUNC /
# DATEDIFF) without pinning the timezone. Those functions resolve in the
# Snowflake SESSION's timezone, which for this account is Pacific — not the
# DAG's UTC cron. Any DAG firing before ~08:00 UTC therefore computes a window
# one calendar day earlier than the cron implies, and a DAG at exactly
# 07:00 UTC flips alignment at each DST transition.
#
# Advisory only: a CURRENT_DATE window is perfectly correct in a DAG scheduled
# after 08:00 UTC. The finding's job is to make you check the cron hour.
#
# Emits one finding line per hit. Silent if clean.

set -uo pipefail

ANCHOR='CURRENT_DATE|CURRENT_TIMESTAMP|GETDATE|SYSDATE'
WRAPPER='DATEADD|DATE_TRUNC|DATEDIFF'

current_file=""
while IFS= read -r line; do
    case "$line" in
        "+++ b/"*) current_file="${line#+++ b/}" ;;
        "+"*)
            content="${line#+}"
            if echo "$content" | grep -qiE "(${WRAPPER})[[:space:]]*\([^)]*(${ANCHOR})" \
               && ! echo "$content" | grep -qi "CONVERT_TIMEZONE"; then
                echo "FINDING [current-date-session-clock] ${current_file}: relative window anchored on a session-clock function. Check the driving DAG's cron HOUR in UTC — below 07 is ALWAYS shifted one day (session is Pacific), exactly 07 flips at DST, 08+ is safe. If the window must track UTC, pin it: CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP)::DATE, or ALTER SESSION SET TIMEZONE='UTC' first. Line: ${content}"
            fi
            ;;
    esac
done

exit 0
