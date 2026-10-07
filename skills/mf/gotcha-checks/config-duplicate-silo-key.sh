#!/usr/bin/env bash
# config-duplicate-silo-key.sh — gotcha check for ASB-3206-class issues.
#
# Reads a unified diff on stdin; runs from the worktree root. Fires when the
# diff ADDS a `"silo": "siloNN"` entry to airflow-dags/config.py AND the
# post-rebase working-tree config.py now contains that silo id more than once.
#
# Why: the merge-flow preflight rebase advances the branch onto a newer main.
# If another branch added the SAME silo block concurrently, the textual rebase
# sees two valid Python dicts on different lines and reports NO conflict — but
# SILO_PARAMS now has a semantic duplicate. daily_proc.py (and peers) build the
# DAG for whichever entry the loop hits last, so a richer/live config can be
# shadowed by a stub (or vice-versa). See airflow-dag-gotchas.md #12.
#
# Silent unless the diff adds a silo key and a duplicate exists.

set -uo pipefail

diff_input="$(cat)"

# Only act if the diff adds at least one silo-key line.
if ! grep -qE "^\+.*['\"]silo['\"][[:space:]]*:[[:space:]]*['\"]silo[0-9]+['\"]" <<< "$diff_input"; then
    exit 0
fi

cfg="airflow-dags/config.py"
[[ -f "$cfg" ]] || exit 0

# Collect the silo ids this diff newly adds (so we only flag relevant dups).
# The key is `"silo"` (no digits) and the value `"siloNN"`; only the value
# matches silo[0-9]+, so grep -o yields exactly the id.
added_ids="$(grep -oE "^\+.*['\"]silo['\"][[:space:]]*:[[:space:]]*['\"]silo[0-9]+['\"]" <<< "$diff_input" \
    | grep -oE "silo[0-9]+" | sort -u)"

# Count occurrences of every silo id in the current working-tree config.py.
# A SILO_PARAMS entry is identified by a `"silo": "siloNN"` line.
dup_ids="$(grep -oE "['\"]silo['\"][[:space:]]*:[[:space:]]*['\"]silo[0-9]+['\"]" "$cfg" \
    | grep -oE "silo[0-9]+" \
    | sort | uniq -d)"

for id in $dup_ids; do
    # Only flag duplicates for silos this diff actually touched.
    if grep -qx "$id" <<< "$added_ids"; then
        n="$(grep -cE "['\"]silo['\"][[:space:]]*:[[:space:]]*['\"]${id}['\"]" "$cfg")"
        echo "config-duplicate-silo-key: '${id}' appears ${n}× in ${cfg} after rebase — your diff added it and another (concurrent) entry already exists. SILO_PARAMS must have one entry per silo; the duplicate will shadow one config (last-in-list wins in the per-silo DAG loops). Verify whether the other entry is a live publisher onboarded on main (e.g. ASB-3206/On3) and drop the redundant block. See airflow-dag-gotchas.md #12."
    fi
done
