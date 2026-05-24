#!/usr/bin/env bash
# silo60-overwolf-transient-drop-list.sh — gotcha check for ASB-2929 refactor.
#
# Reads a unified diff on stdin. For each line that adds a `CREATE OR REPLACE
# TRANSIENT TABLE <name>` in airflow-dags/custom_user_data/silo60_overwolf.py,
# verifies that <name> appears (single-quoted) in TAPAD_TRANSIENT_TABLES or
# SILO60_TRANSIENT_TABLES of the post-edit file. Emits one finding line per
# missing entry. Silent if every new transient is in a drop list.
#
# Run from the worktree root so relative paths land correctly.

set -uo pipefail

TARGET_FILE="airflow-dags/custom_user_data/silo60_overwolf.py"

diff_input="$(cat)"
current_file=""
missing=()

while IFS= read -r line; do
    case "$line" in
        "+++ b/"*)
            current_file="${line#+++ b/}"
            ;;
        "+"*)
            # Only check additions in the target file
            if [[ "$current_file" != "$TARGET_FILE" ]]; then
                continue
            fi
            content="${line#+}"
            if [[ "$content" =~ [Cc][Rr][Ee][Aa][Tt][Ee][[:space:]]+[Oo][Rr][[:space:]]+[Rr][Ee][Pp][Ll][Aa][Cc][Ee][[:space:]]+[Tt][Rr][Aa][Nn][Ss][Ii][Ee][Nn][Tt][[:space:]]+[Tt][Aa][Bb][Ll][Ee][[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*) ]]; then
                table_name="${BASH_REMATCH[1]}"
                # Check if the table name appears single-quoted in either drop list
                # (looks for: 'table_name' anywhere in the file — both lists use single quotes)
                if ! grep -qE "'${table_name}'" "$TARGET_FILE" 2>/dev/null; then
                    missing+=("$table_name")
                fi
            fi
            ;;
    esac
done <<< "$diff_input"

if [[ ${#missing[@]} -gt 0 ]]; then
    # Dedupe (same table could appear multiple times in diff if context shifts)
    unique_missing=($(printf '%s\n' "${missing[@]}" | sort -u))
    echo "FINDING: silo60-overwolf transient tables missing from drop list:"
    for t in "${unique_missing[@]}"; do
        echo "  - $t  → add to TAPAD_TRANSIENT_TABLES or SILO60_TRANSIENT_TABLES at top of $TARGET_FILE"
    done
fi

exit 0
