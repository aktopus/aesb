# Exercise a new silo's overnight-only per-silo tasks NOW, under observation, instead of
# letting their first run happen at 1:30am. Runs INSIDE the prod airflow-webserver container
# as the `airflow` user, AFTER the first daily_proc run has succeeded (the syndicated task
# needs the view that run creates). Each task is delete-then-insert per day, so tonight's
# scheduled runs repeat it harmlessly. From the laptop (one ECS exec call; 5 to 10 minutes):
#
#   B64=$(base64 < exercise_overnight.sh | tr -d '\n')
#   aws ecs execute-command --profile prod --region us-east-1 --cluster ArcSpanProdCluster \
#     --task "$TASK" --container airflow-webserver --interactive \
#     --command "bash -c 'echo $B64 | base64 -d > /tmp/eo.sh && chmod 644 /tmp/eo.sh && su airflow -c \"bash /tmp/eo.sh siloNN name_slug $(date -u +%F)\" 2>&1 | grep -E \"^(RESULT|  DETAIL|EXERCISED)\"; rm -f /tmp/eo.sh'"
#
# Args: silo id (silo77), the name slug daily_aspancount uses in its task id (the block's
# daily_aspancount "name", lowercased, spaces as "_": fandom, better_collective), and the
# logical date.
# Skipped on purpose: aurora_* tasks (they read an XCom from the ingest and return early on no
# rows), and the Bombora / LiveRamp taxonomy DAGs (they publish to the builder; let their own
# slot run them, :40 past 4, 10, 16, 22 UTC).
#
# Each DAG is PAUSED for the seconds its tasks run, then unpaused (also on exit). On Airflow
# 2.8.4 `tasks test` with a date creates a real queued DagRun; an unpaused DAG's scheduler fills
# it with every other silo's task and the run's deletion kills them (rtif_ti_fkey, SIGTERM) —
# the 2026-10-06 ASB-4213..4216 burst. Paused, the scheduler never looks at the run. A DAG with
# a run in flight is not paused; its tasks print SKIPPED and count as not SUCCESS — rerun later.
# A DAG that is already paused is left paused (it is safe as it is, and it was paused on purpose).
# The tasks themselves run for real against DS; this is an exercise, not a dry run.
SILO="$1"; SLUG="$2"; DS="$3"
DAGS="daily_builder_syndicated_segment_metrics daily_builder_silo_custom_user_data daily_builder_silo_custom_data daily_builder_silo_categories daily_builder_silo_domains daily_builder_silo_keywords daily_builder_silo_taxonomy daily_builder_gam_line_items daily_builder_gam_orders daily_thresholds daily_aspancount daily_operational"
n=0; bad=0; PAUSED=""
unpause() { [ -n "$PAUSED" ] && airflow dags unpause "$PAUSED" >/dev/null 2>&1; PAUSED=""; }
trap unpause EXIT
for d in $DAGS; do
  tasks=$(airflow tasks list "$d" 2>/dev/null | grep -E "_(${SILO}|${SLUG})$" | grep -v "^aurora_")
  [ -z "$tasks" ] && continue
  if airflow dags list-runs -d "$d" --state running -o plain 2>/dev/null | grep -q "^$d "; then
    for t in $tasks; do n=$((n+1)); bad=$((bad+1)); echo "RESULT SKIPPED(run in flight, rerun later) $d $t"; done
    continue
  fi
  # Pause only a DAG that is active now, so a DAG someone paused on purpose stays paused.
  if [ "$(airflow dags list -o plain 2>/dev/null | awk -v d="$d" '$1==d {print $NF}')" = "False" ]; then
    airflow dags pause "$d" >/dev/null 2>&1; PAUSED="$d"
  fi
  for t in $tasks; do
    out=$(airflow tasks test "$d" "$t" "$DS" 2>&1); rc=$?
    if echo "$out" | grep -q "Marking task as SUCCESS"; then st=SUCCESS
    elif echo "$out" | grep -qE "Marking task as (FAILED|UP_FOR_RETRY)|Traceback"; then st=FAILED; bad=$((bad+1))
    else st="UNKNOWN(rc=$rc)"; bad=$((bad+1)); fi
    n=$((n+1)); echo "RESULT $st $d $t"
    [ "$st" != "SUCCESS" ] && echo "$out" | grep -vE "^\s*$" | tail -12 | sed 's/^/  DETAIL /' | cut -c1-300
  done
  unpause
done
# Zero tasks found is a failure of this script (wrong slug, DAG not deployed), never a pass.
echo "EXERCISED $n task(s), $bad not SUCCESS"
