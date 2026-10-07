#!/usr/bin/env bash
# intermediate-table-cross-read.sh — gotcha check for ASB-3465.
#
# Reads a unified diff on stdin. Fires when the diff adds a task-dependency edge
# between two intermediate-table tasks (`t_a >> t_b`), which is the signature of
# one materialized intermediate now READING another inside its SQL template.
#
# That ordering is correct for a scheduled run, but it makes the downstream query
# non-self-contained: clearing that single task in the Airflow UI re-runs it
# against whatever the upstream table holds on disk, which can be arbitrarily
# stale. Emits a reminder to (a) document the clear-both-tasks requirement at the
# reader site, and (b) confirm the edge is set BEFORE the group-level dependency
# wiring so TaskGroup.roots still recomputes.
#
# Advisory only — it cannot tell a legitimate ordering from a hazardous one, so
# it never asserts a defect. Run from the worktree root.

set -uo pipefail

diff_input="$(cat)"
current_file=""
edges=()

while IFS= read -r line; do
    case "$line" in
        "+++ b/"*)
            current_file="${line#+++ b/}"
            ;;
        "+"*)
            content="${line#+}"
            # Skip comments — prose about dependencies is not a dependency.
            [[ "$content" =~ ^[[:space:]]*# ]] && continue
            if [[ "$content" =~ ([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*\>\>[[:space:]]*([a-zA-Z_][a-zA-Z0-9_]*) ]]; then
                up="${BASH_REMATCH[1]}"
                down="${BASH_REMATCH[2]}"
                # Only intermediate-table tasks (t_*), not group/orchestration wiring.
                if [[ "$up" == t_* && "$down" == t_* ]]; then
                    edges+=("$current_file|$up >> $down")
                fi
            fi
            ;;
    esac
done <<< "$diff_input"

if [[ ${#edges[@]} -gt 0 ]]; then
    unique_edges=$(printf '%s\n' "${edges[@]}" | sort -u)
    echo "FINDING: new dependency edge between intermediate-table tasks (gotcha 18):"
    while IFS='|' read -r f e; do
        echo "  - $e  ($f)"
    done <<< "$unique_edges"
    echo "  Confirm: (1) the downstream SQL template documents that clearing it alone"
    echo "  prunes/joins against a possibly-stale upstream table — clear BOTH tasks;"
    echo "  (2) the edge is set before the group-level deps so TaskGroup.roots recomputes;"
    echo "  (3) the serialization cost is acceptable (these tasks no longer run in parallel)."
fi

exit 0
