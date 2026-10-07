#!/bin/bash
# Gotcha #13: a new/changed schedule can silently skip its first run, because a
# DAG run is unique on (dag_id, logical_date) and Airflow will not create one
# that already exists. Nothing goes red — you just lose a full period.
#
# Input: unified diff on stdin.
#
# WIDENED 2026-08-12 (fourth miss of this class). The library's diff_pattern was
# widened 2026-08-06 to any line containing 'schedule' or 'cron', but THIS SCRIPT
# still grepped only the literal 'schedule_interval' — so on a registry-style
# change the trigger fired and then the check cleared it with silence, which
# reads exactly like a pass. Caught on the silo56/WebMD flip (PR 4071), whose
# diff sets discovery_common.SILO_DAGS["silo56"]["schedule"] and contains no
# 'schedule_interval' anywhere.
#
# Three schedule-carrying shapes are now recognised:
#   1. schedule_interval = "..."            (classic DAG kwarg)
#   2. "schedule": "..."                    (registry style — Iceberg SILO_DAGS)
#   3. <NAME>CRON<NAME> = "..."             (module-level cron constant)

DIFF=$(cat)

SCHED_RE='schedule_interval|"schedule"[[:space:]]*:|[A-Z_]*CRON[A-Z_]*[[:space:]]*='

removed=$(grep -E "^-.*($SCHED_RE)" <<<"$DIFF" | grep -cve '^$')
added=$(grep -E "^\+.*($SCHED_RE)" <<<"$DIFF" | grep -cve '^$')

# A manual-only DAG gaining its first cron is the case most likely to be waved
# through: 'schedule: None' -> a cron reads as a pure addition, but manual
# backfills carry logical dates too, so the history that can collide is real.
first_cron=$(grep -E '^\+.*"schedule"[[:space:]]*:' <<<"$DIFF" | grep -cE '"schedule"[[:space:]]*:[[:space:]]*"' )
none_removed=$(grep -E '^-.*"schedule"[[:space:]]*:[[:space:]]*None' <<<"$DIFF" | grep -cve '^$')

if [ "$removed" -gt 0 ] && [ "$added" -gt 0 ]; then
  if [ "$none_removed" -gt 0 ] && [ "$first_cron" -gt 0 ]; then
    echo "MANUAL-ONLY DAG IS GAINING ITS FIRST CRON (schedule: None -> cron). Manual seed/top-up/catch-up runs carry logical dates, so this is NOT a history-free addition. Before merge, list every existing logical date for the DAG and confirm NONE matches the new cron's minute:"
    echo "    airflow dags list-runs -d <dag_id> -o plain | awk 'NR>1 {print \$4}' | sort -u"
    echo "  A match means Airflow silently skips that period (gotcha #13). Note the runbook's own example command uses T09:00:00+00:00, so '0 9 * * *' is the classic trap."
  else
    echo "SCHEDULE CHANGED (${removed} removed / ${added} added lines). If the new schedule's first logical date matches a run the old cadence already created, Airflow silently skips that run (gotcha #13, ASB-3251 2026-07-16). After deploy: verify the first new-schedule run via 'airflow dags list-runs' and manually trigger if skipped."
  fi
  grep -E "^[-+].*($SCHED_RE)" <<<"$DIFF" | head -20
fi
exit 0
