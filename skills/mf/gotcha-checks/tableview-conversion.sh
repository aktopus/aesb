#!/usr/bin/env bash
# tableview-conversion.sh — gotcha check for ASB-2909-class issues.
#
# Reads a unified diff on stdin. For each line that adds a `CREATE OR REPLACE
# (TABLE|VIEW) <name>` DDL, looks for OPPOSITE-type DDL of the same name in
# sibling files (excluding the file the diff modifies). Emits one finding
# line per collision. Silent if no collisions.
#
# Run from the worktree root so relative greps land on the right files.

set -uo pipefail

diff_input="$(cat)"
current_file=""

while IFS= read -r line; do
    case "$line" in
        "+++ b/"*)
            current_file="${line#+++ b/}"
            ;;
        "+"*)
            content="${line#+}"
            if [[ "$content" =~ [Cc][Rr][Ee][Aa][Tt][Ee][[:space:]]+[Oo][Rr][[:space:]]+[Rr][Ee][Pp][Ll][Aa][Cc][Ee][[:space:]]+([Tt][Rr][Aa][Nn][Ss][Ii][Ee][Nn][Tt][[:space:]]+)?(table|view|TABLE|VIEW|Table|View)[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*) ]]; then
                declared_type_lower="$(echo "${BASH_REMATCH[2]}" | tr '[:upper:]' '[:lower:]')"
                object_name="${BASH_REMATCH[3]}"
                if [[ "$declared_type_lower" = "table" ]]; then
                    opposite_lower="view"
                else
                    opposite_lower="table"
                fi
                declared_type_upper="$(echo "$declared_type_lower" | tr '[:lower:]' '[:upper:]')"
                opposite_upper="$(echo "$opposite_lower" | tr '[:lower:]' '[:upper:]')"

                # Search opposite-type DDL of same name. Limit to typical
                # abuilder layout dirs when present; fall back to repo root.
                # Include fixtures/ for the self-test.
                search_paths=()
                [[ -d schema ]] && search_paths+=("schema")
                [[ -d airflow-dags ]] && search_paths+=("airflow-dags")
                [[ ${#search_paths[@]} -eq 0 ]] && search_paths=(".")

                # Pattern: create [or replace] [transient] <opposite> [if not exists] <name>
                # followed by whitespace, paren, or end-of-line. The IF NOT EXISTS
                # form is the most dangerous case (silent type-collision).
                hits="$(grep -rni -E "create[[:space:]]+(or[[:space:]]+replace[[:space:]]+)?(transient[[:space:]]+)?${opposite_lower}[[:space:]]+(if[[:space:]]+not[[:space:]]+exists[[:space:]]+)?${object_name}([[:space:]]|\(|$)" \
                    "${search_paths[@]}" 2>/dev/null \
                    | grep -v "^${current_file}:" \
                    || true)"

                if [[ -n "$hits" ]]; then
                    while IFS= read -r hit; do
                        [[ -z "$hit" ]] && continue
                        hit_file="$(echo "$hit" | cut -d: -f1)"
                        hit_line="$(echo "$hit" | cut -d: -f2)"
                        echo "tableview-conversion: ${object_name} declared as ${declared_type_upper} in ${current_file} but also created as ${opposite_upper} in ${hit_file}:${hit_line}"
                    done <<< "$hits"
                fi
            fi
            ;;
    esac
done <<< "$diff_input"
