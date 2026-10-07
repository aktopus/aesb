#!/usr/bin/env bash
# ltz-bucketing-timezone.sh — gotcha check for PR-#4018-class issues (gotcha #17).
#
# Reads a unified diff on stdin. Flags added lines that bucket a known
# TIMESTAMP_LTZ column (ACCOUNT_USAGE-style START_TIME/END_TIME etc.) with
# DATE_TRUNC / TO_DATE / ::DATE / DATE(...) WITHOUT a CONVERT_TIMEZONE on the
# same line. Such bucketing resolves in the querying session's TIMEZONE, so
# the result is non-deterministic across clients and disagrees with
# Snowflake's UTC-date-keyed billing tables at every bucket boundary.
# Emits one finding line per hit. Silent if clean. Advisory only.
#
# Heuristic is line-scoped: a CONVERT_TIMEZONE on a *different* line of the
# same expression will false-positive — cheap to dismiss, dangerous to miss.

set -uo pipefail

LTZ_COLS='START_TIME|END_TIME|QUERY_START_TIME|LAST_LOAD_TIME|CREATED_ON|COMPLETED_TIME|SCHEDULED_TIME'

current_file=""
lineno=0
while IFS= read -r line; do
    case "$line" in
        "+++ b/"*) current_file="${line#+++ b/}" ;;
        "+"*)
            content="${line#+}"
            if echo "$content" | grep -qiE "(DATE_TRUNC[[:space:]]*\(|TO_DATE[[:space:]]*\(|::DATE|[^_A-Za-z]DATE[[:space:]]*\()[^)]*(${LTZ_COLS})" \
               && ! echo "$content" | grep -qi "CONVERT_TIMEZONE"; then
                echo "FINDING [ltz-bucketing-timezone] ${current_file}: session-timezone bucketing of an LTZ column — wrap in CONVERT_TIMEZONE('UTC', …) before DATE_TRUNC/::DATE. Line: ${content}"
            fi
            ;;
    esac
done

exit 0
