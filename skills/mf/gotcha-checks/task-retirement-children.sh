#!/usr/bin/env bash
# task-retirement-children.sh — gotcha check for ASB-3038-class issues.
#
# Reads a unified diff on stdin. Fires when the diff suspends or drops a
# Snowflake Task, or adds code claiming to replace a Snowflake-native Task.
# Snowflake task graphs live outside version control, so the diff alone can
# never prove a retired Task has no children — emit one finding per retired
# task name instructing the reviewer to enumerate dependents on the live
# account(s) before merge. Silent if the diff retires nothing.

set -uo pipefail

diff_input="$(cat)"

emit_for() {
    local task_name="$1" action="$2"
    echo "task-retirement-children: diff ${action} Snowflake Task '${task_name}'. Task graphs are not in version control — before merging, run SHOW TASKS IN ACCOUNT on the matching account(s) (US and EU for dual-region silos) and inspect predecessors/task_relations for children chained AFTER this task. Every child must be migrated or re-scheduled in the same change, or it silently stops firing (see airflow-dag-gotchas.md #11, ASB-3038 sizer incident)."
}

while IFS= read -r line; do
    [[ "$line" == "+"* ]] || continue
    content="${line#+}"
    if [[ "$content" =~ [Aa][Ll][Tt][Ee][Rr][[:space:]]+[Tt][Aa][Ss][Kk][[:space:]]+([A-Za-z0-9_.\"]+).*[Ss][Uu][Ss][Pp][Ee][Nn][Dd] ]]; then
        emit_for "${BASH_REMATCH[1]}" "suspends"
    elif [[ "$content" =~ [Dd][Rr][Oo][Pp][[:space:]]+[Tt][Aa][Ss][Kk][[:space:]]+([Ii][Ff][[:space:]]+[Ee][Xx][Ii][Ss][Tt][Ss][[:space:]]+)?([A-Za-z0-9_.\"]+) ]]; then
        emit_for "${BASH_REMATCH[2]}" "drops"
    elif [[ "$content" =~ [Rr]eplaces[[:space:]]the[[:space:]]Snowflake-native[[:space:]]+([A-Za-z0-9_.{}\"]+) ]]; then
        emit_for "${BASH_REMATCH[1]}" "claims to replace"
    fi
done <<< "$diff_input" | sort -u
