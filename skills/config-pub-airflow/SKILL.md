---
name: config-pub-airflow
description: "Use when a ticket asks to configure Airflow for a new publisher or silo (an ASB 'Configure Airflow' ticket, step 7 of a '<Publisher> (siloNN) Technical Onboarding' parent), when adding a new silo block to abuilder's airflow-dags/config.py, or when a shell silo is ready for its analytics stage (daily_ci, Pre-Sales, Iceberg discovery) because the tag now sends production traffic."
argument-hint: <ASB-key | siloNN>
---

# Configure Airflow for a publisher

Onboarding a silo is **two stages with one outside trigger between them**. Stage 1 is a shell *and its activation*, done in one sitting as soon as the silo is assigned. Stage 2 is analytics, and waits for production traffic. Every failed onboarding on record broke one of two rules:

1. **Merging the block starts work for the silo at the next slot of every shared DAG keyed on `daily_builder`.** So whatever those tasks read must exist before the earliest one fires, and "merge now, activate later" is not a safe state: a `daily_builder` silo with a paused proc fails nightly at 05:30 UTC.
2. **Every miss was a check nobody ran against the live system.** The repo cannot tell you whether a stream is stale, a table was provisioned, the portal row exists or GAM access was granted. This skill is mostly pre-flight for that reason.

Read live state first and resume at the stage it shows. Do not restart from the top.

| Observable state | You are at |
|---|---|
| No `"silo": "siloNN"` in `config.py` | Identify and scope, then Stage 1 |
| Block merged, `daily_proc_siloNN` paused, or streams `stale = true` | Stage 1, activation (finish it today) |
| Shell running, edge logs show script fetches but no `/p.png` (`preflight.sql` 6b or 7) | Between stages. Nothing to do but the deferral |
| `/p.png` beacons arriving, shell block still has its opt-outs | Stage 2 |

Files beside this one: `preflight.sql` (read-only Snowflake inventory, every query paired with a control), `portal_preflight.py` (portal rows plus a GAM access probe, run over ECS exec; its docstring has the command) and `exercise_overnight.sh` (runs the silo's overnight-only tasks now, after activation).

## Identify and scope

- **Silo number and geo come from the onboarding PARENT ticket** (`<Publisher> (siloNN) Technical Onboarding`), never the Airflow ticket's title. Titles get copied from the previous onboarding (ASB-4089 said silo76 for silo77/Fandom). Confirm the number against the portal `silos` row and the region against RDS `publisher.data_center`.
- **Scope comes from the signed SOW** in the Arcteam Documents share, `Contracts and Legal Documents/Clients/<Publisher>/` (the folder may carry a site name, e.g. `MaxPreps` for PlayOn): sites, Exhibit 3 capabilities, contracted volume. Stop short of commercials. Drafts live under `Sales & Marketing/Clients & Prospects/<Publisher>/Legal/` and do not count. No signed SOW means nothing publisher-specific gets switched on, and volume is unknown, not zero.
- Read the parent's GAM step: a network code with "API Reporting" unticked predicts the GAM probe will fail.

## Stage 1: shell and activation, one sitting, working hours

**Trigger:** the onboarding owner has asked for it, the silo is assigned, the `SILONN` database and `SILONN_WH` are provisioned, and the portal rows are present. The parent ticket's status is not the trigger (both 2026-10 parents sat On Hold while the publisher was actively testing), and neither is a signed SOW: a shell is publisher-agnostic. If the portal has no active `silos` row or no `publisher` row yet, stop and hand that to the onboarding owner; the fallback is a `daily_proc`-only stub left paused, and nothing else.

A second shell on the same day as another is fine, but first confirm the earlier one's slots that have already run are green (`AMS_COHORTS` exists, no failed statements): the two share every unknown.

### 1. Pre-flight (all read-only)

Run `portal_preflight.py`, then `preflight.sql` queries 0 to 6b. Required answers before writing the block:

| Check | Pass | If not |
|---|---|---|
| Portal `silos` | exactly one row `status != 0`; `gam_network_codes` a JSON string | stop: two shared tasks raise (`daily_builder/silo_custom_user_data.py`, `daily_gam_reports/entities.py`) |
| Portal `publisher` | row exists, `data_center` matches the region you write | stop |
| GAM probe | `OK`, or the code list is `[]` | a code that returns `NO_NETWORKS_TO_ACCESS`: the block needs `"daily_gam_reports": False` and no `monthly_data_cost` |
| Streams | note which are stale. Expect all of them on a database older than 14 days | recreate at activation (step 4) |
| Objects missing vs the control | classify each with the table below | create what a first run reads and nothing creates |
| Legacy `SILONN_DAILY` / `SILONN_SIZER_BUILD` tasks | none (control rows returned) | suspend them in the same change; Airflow is the single control surface |
| `EDGEDMP_EXT` day expression | `SPLIT_PART` form, or fixed offset AND every stage filename parses | recreate the external table from `schema/silo.sql`, then its stream |

**Who creates what** (anything `_ICEBERG`, `T_*`, `GAM_CAMPAIGN_*`, `ath-*`, `siloNN-*`, `SKETCH_*` or `COHORT_URL_AFFINITY` in the control diff is Stage 2 or opt-in, and ignorable here):

| Object | Created by | First reader with no guard |
|---|---|---|
| `CUSTOMDATA_INGESTED` | provisioning template since 2026-07-08, else the 07:00 UTC `daily_builder_silo_custom_user_data` shared task | the **sizer step of `daily_proc`** (`sp/build_sizer_events.sql`). Create it by hand before unpausing: `CREATE TRANSIENT TABLE IF NOT EXISTS SILONN.PUBLIC.CUSTOMDATA_INGESTED (ARCID VARCHAR, CUSTOMDATA VARIANT, LAST_UPDATED TIMESTAMP_NTZ(9));` |
| `ARCID_PROFILES` (view), `SIZER_EVENTS`, `ML_IABLABEL` | the first **full** `daily_proc` run | `daily_builder_syndicated_segment_metrics`, 05:30 UTC |
| `AMS_COHORTS` | `daily_builder_ams_cohorts`, hourly at :15 | `daily_ci`, `monthly_data_cost` (not the shell) |
| `GAM_LINE_ITEMS`, `GAM_ORDERS`, `BOMBORA_SEGMENTS`, `LIVERAMP_SEGMENTS` | builder, Bombora and LiveRamp tasks, from MySQL or a rate card | `monthly_data_cost` |
| `GAM_REPORT_*` | `daily_gam_reports_*`, only with GAM API access | `monthly_data_cost` reads `GAM_REPORT_PROGRAMMATIC_COHORT_INSIGHTS` |
| `ARCTAG_DAILY_ERRORS`, `ARCTAG_DAILY_PERF_EVENTS`, `ARCTAG_CARRIER_RAW_STREAM`, `ARCTAG_DAILY_EVENTS_STREAM` | their own DAG or proc, `IF NOT EXISTS` | none |

### 2. The block

Copy the most recent **shell** block in `config.py` (silo76/PlayOn is the first), never a full analytics block: the repo's shape moves, so no template lives here. A shell carries `silo`, `name`, `region`, `daily_proc` (`{"inc_flag": 0, "schedule_interval": "0 4 * * *"}`), `daily_aspancount`, `daily_builder`, `daily_errors`, and the opt-outs from the flag table. Also:

- Remove `'SILONN'` from `KNOWN_NON_CLIENT_DBS` in `airflow-dags/daily_operational.py`.
- The block comment names each absent block and its trigger. No **value** in the block may carry another silo's id (`.review/checks/check_silo_config.py` reads the parsed dict and warns on donor residue; keep other silos' ids out of the comments too, so the next copy starts clean). No added line, comment or not, may contain the literal custom-data table name (`check_customdata_push.py` matches it anywhere in an added `config.py` line).
- Once a day at shell stage on purpose: with no `sizer_gate_hour` every run is full, so the run that fires on unpause builds the view and sizer table while you watch.

### 3. Merge flow

**REQUIRED SUB-SKILL:** `mf`, with `/usr/bin/python3 -m pytest tests/ -q`. The PR description uses `.review/PR_TEMPLATE.md` and its new-silo section. Things reviewers asked for that the template does not prompt: the date-parse evidence from pre-flight; a cost line that lists **every** task defaulting to `SILONN_WH` (proc 04:00, domains and keywords 02:00, syndicated metrics 05:30, two operational builds 06:00, counts merge 12:20), not only the proc; and that `daily_builder` also enrolls the silo in the Bombora and LiveRamp taxonomy DAGs with no separate flag.

### 4. Activate, in this order, as soon as the DAG is listed (about 3 minutes after merge)

Airflow CLI calls go over ECS exec, one command per call:

```bash
TASK=$(aws ecs list-tasks --profile prod --region us-east-1 --cluster ArcSpanProdCluster --service-name arcspanairflow-AirflowService-vJtFXqmj5rLa --query 'taskArns[0]' --output text)
X() { aws ecs execute-command --profile prod --region us-east-1 --cluster ArcSpanProdCluster --task "$TASK" --container airflow-webserver --interactive --command "bash -c 'su airflow -c \"$1\"'"; }
X "airflow dags list -o plain | grep siloNN"          # then: X "airflow dags list-import-errors -o plain"
X "airflow dags unpause daily_proc_siloNN"
X "airflow tasks states-for-dag-run daily_proc_siloNN <run_id> -o plain"
```

1. Confirm: `airflow dags list | grep siloNN` shows only `daily_proc_siloNN`, paused; no import errors.
2. Recreate **every** stale stream (the unpause follows at once, so they cannot age):
   ```sql
   CREATE OR REPLACE STREAM SILONN.PUBLIC.EDGEDMP_EXT_STREAM ON EXTERNAL TABLE SILONN.PUBLIC.EDGEDMP_EXT INSERT_ONLY = TRUE;
   CREATE OR REPLACE STREAM SILONN.PUBLIC.EDGEDMP_INT_STREAM ON TABLE SILONN.PUBLIC.EDGEDMP_INT APPEND_ONLY = TRUE;
   CREATE OR REPLACE STREAM SILONN.PUBLIC.ARCTAG_DAILY_EVENTS_RAW_STREAM ON TABLE SILONN.PUBLIC.ARCTAG_DAILY_EVENTS_RAW APPEND_ONLY = TRUE;
   ```
   Run them through the MCP whose role owns the silo's objects (`TAVANTGROUP`).
3. Create the custom-data table if pre-flight showed it missing.
4. `airflow dags unpause daily_proc_siloNN`. Unpausing **fires one run immediately** (run id `scheduled__<start of the last completed interval>`); it takes under a minute on an empty silo.
5. Verify with `preflight.sql` queries 7 and 8: both tasks `success`; rows down the chain; `ARCID_PROFILES` and `SIZER_EVENTS` exist; the only failed `AIRFLOWUSER` statement is the sizer's `SILONNEU` probe (logged under database `ASPANDB`). **Say plainly whether the logs hold `/p.png` beacons or only script fetches.** Then `python3 /Users/akpanoluo/code/scripts/refresh-silo-domain-summary.py`.

6. **Exercise the overnight-only tasks now** with `exercise_overnight.sh` (its header has the command): it runs each of the silo's per-silo tasks in the 01:30 to 12:20 UTC slots through `airflow tasks test`, pausing each DAG for the seconds its tasks run so the scheduler cannot dispatch the other silos' tasks into the throwaway run (the 2026-10-06 ASB-4213..4216 burst; gotcha #31), and prints one `RESULT` line per task. A DAG with a run in flight is skipped, not paused — rerun for it later. Want `EXERCISED 15 task(s), 0 not SUCCESS` (15 on a plain shell; zero tasks found means the slug is wrong, not that all is well). This is what lets a merge at midday stand without a night's wait, and it is the evidence a reviewer will ask for.

The proc stays unpaused from here even with zero traffic. A running proc is what keeps a silent silo's streams fresh; a paused one lets them go stale in 14 days.

## Stage 2: analytics

**Trigger:** steady production `/p.png` volume (`preflight.sql` query 7 against the control), not a ticket and not the tag being "implemented". Each item is its own change; this stage points at the playbook instead of restating it.

- Iceberg discovery enrollment and its S3 lifecycle rule: `/code/vault/context/snowflake-to-iceberg-athena-playbook/` (`04a-enroll-seed.md`, `04b-parity-flip.md`). The `daily_test` block arrives here, always `"dag_enabled": False`.
- Pre-Sales enrollment on Athena, with the roster pins in `tests/test_presales_consumer_cutover.py` bumped in the same change.
- `daily_ci`, then `weekly_ci` only after `daily_ci`'s first green run. Needs GAM API access.
- Proc to the 2-hourly fleet shape (`sizer_gate_hour`, `rca_interval_hours`) after the reader audit its docstring asks for; drop the sketch opt-out once `SIZER_EVENTS` has rows.
- Warehouse size and `AUTO_SUSPEND 30` from measured volume, never from the SOW figure alone.
- QuickSight hand-off to Artemio Rimando; SSP/Identifier tabs if the SOW contracts them.

## First-run table

Which shared DAGs pick a silo up, and what each needs. Re-derive it when a DAG is added: `grep -rlE "SILO_PARAMS" airflow-dags | grep '\.py$'`, then read each file's gate (`'<key>' not in silo_config`).

| DAG (UTC slot) | Gate | Needs | On an empty shell |
|---|---|---|---|
| `daily_proc_siloNN` (block's schedule; once on unpause) | `daily_proc` | fresh streams, custom-data table | green; builds the view, sizer table, carrier stream |
| `daily_builder_ams_cohorts` (:15 hourly) | `daily_builder` | portal rows | creates `AMS_COHORTS` |
| `cohort_metrics`, `silo_metrics`, `silo_trends` (:30 at 3-5, 11, 17, 23) | `daily_builder` | proc's tables | green, no rows |
| `silo_categories` (01:30); `silo_domains`, `silo_keywords`, `silo_taxonomy` (02:00) | `daily_builder` | proc's tables | green, no rows |
| `gam_line_items`, `gam_orders` (05:15) | `daily_builder` | MySQL only | creates empty tables; no GAM API call |
| **`syndicated_segment_metrics` (05:30)** | `daily_builder` | **`ARCID_PROFILES` view** | **fails until the first full proc run** |
| `silo_custom_data`, `silo_custom_user_data` (07:00) | `daily_builder` | one active `silos` row and a `publisher` row | raises if either is missing |
| **`daily_gam_reports_*`** (04:00 to 05:30; entities hourly :45) | `daily_builder`, unless `daily_gam_reports: False` | **GAM API access for the configured code** | `line_item_summary` raises nightly; `programmatic_cohort_insights` raises from its 2nd run |
| `bombora_taxonomies`, `liveramp_taxonomies` (:40 at 4, 10, 16, 22); `liveramp_data` | `daily_builder`, no flag | nothing | publishes the Bombora standard rate card; LiveRamp exits early |
| **`weekly_sketch_refresh` (Sat 02:00)** | `daily_builder`, unless `sketch_builder.enabled: False` | **non-empty `SIZER_EVENTS`** | **raises on empty** |
| `daily_errors` (08:05), `daily_thresholds` (09:08), `daily_aspancount` (12:20), `nlp_stats` | `daily_errors` / `daily_aspancount` | proc's tables | green; `nlp_stats` gains a column |
| `daily_operational`, `daily_cost_rollup` (06:00) | region only | the silo out of `KNOWN_NON_CLIENT_DBS` | green; zero rows on the operational dashboard |
| **`monthly_siloxx_data_cost` (3rd of month)** | `monthly_data_cost` | `AMS_COHORTS`, `GAM_REPORT_PROGRAMMATIC_COHORT_INSIGHTS`, `LIVERAMP_SEGMENTS`, `BOMBORA_SEGMENTS` | **unguarded; one missing table holds back the fleet's email** |
| `openx_export_dag` | portal `silos.openx_org_id` (not a config key) | n/a | not enrolled while NULL |

## Flag table

"The donor block had it" is never the reason. Each key is on because of the fact in the middle column.

| Key | Turned on (or off) by | Where that fact is recorded |
|---|---|---|
| `daily_builder.daily_gam_reports: False` | GAM probe fails for a configured code | `portal_preflight.py` output; parent ticket's GAM step |
| `monthly_data_cost` (absent) | absent until GAM reports are on and their table exists | Snowflake `SILONN.PUBLIC` |
| `sketch_builder: {"enabled": False}` | no events yet | `preflight.sql` query 7 |
| `use_primary_domain` | the publisher's hosts are subdomains of one site | SOW site list; edge-log referers |
| `daily_adx_insights*`, `monthly_adx_insights*` | AdX insights sold | SOW; default False |
| `custom_page_attributes` (+ key lists) | a pageData key list exists | parent ticket's pageData step |
| `hourly_invalidation` | cohort delivery starts | CloudFront distribution id |
| `customdata_push` | a custom-data build exists | custom-data methodology doc (match-rate test first) |
| `daily_ci`, `weekly_ci`, `weekly_audience_insights`, `daily_test` block | Stage 2 | this skill |
| SSP / Identifier tabs | contracted, and a QuickSight ask exists | SOW Exhibit 3 |

## Close-out

- Ticket: In Review per `mf`; one comment in the succinct shape (what is on, what is deliberately off and why, whether events are flowing). It closes when events flow end to end, not at merge.
- A deferral carrying the next stage's triggers (first beacons; GAM access; production traffic), and next-morning checks in the day's `next-day-checks` file for the first unattended cycle (04:00, 05:30, 07:00 UTC).
- A message to the onboarding owner goes out as a **draft**. Give fact and consequence (for example "the dev page fetches only `/as.js` and sends no events"); whether to raise it with the publisher is their call.
- Worklog with the commands and results, including run ids and the row counts down the chain.

## Self-correction protocol

When a run of this skill meets a failed task, a check that should have existed, or a row in the first-run table that turned out wrong, **append to Known gotchas below before closing the worklog**, with the date, what happened and the check that would have caught it; fix the table or `preflight.sql` in the same edit. The table is only as good as its last onboarding.

## Known gotchas

1. **All three streams can be stale, not two** (silo76, 2026-10-06). A database provisioned in July had `EDGEDMP_EXT_STREAM`, `EDGEDMP_INT_STREAM` and `ARCTAG_DAILY_EVENTS_RAW_STREAM` all stale. Read `SHOW STREAMS`; do not recreate from a remembered list.
2. **Script fetches are not events** (silo76, 2026-10-06). `/as.js` is a 17-byte stub (`const silonum=NN;`) on every silo; the tag is `/as1.js`. A page that only fetches `/as.js` sends nothing, and Airflow cannot manufacture cohort counts from it. Compare the request mix with a live silo.
3. **Do not `curl` `/as1.js` to look at it.** The proc maps any `/as1.js` request to a tag-fire row, so your own fetch shows up as the silo's first "event" (`ua = curl/...`, `arcid` NULL).
4. **`EDGEDMP_EXT` reads empty until the proc's first run** refreshes it. Zero rows there before activation is not "no logs"; `LIST` the stage. Do not refresh it by hand.
5. **`EDGEDMP_INT` only ever holds `day >= CURRENT_DATE - 1`.** A handful of rows there next to thousands in `EDGEDMP_EXT` is by design.
6. **A real GAM network code without API access fails two tasks** (silo76 and silo77, 2026-10-06), and an empty list does not. The plan for silo76 checked only that the column was a JSON string, on the earlier precedent of `'[]'`.
7. **`monthly_data_cost` and `daily_gam_reports: False` do not mix.** No block in `config.py` carries both.
8. **A copied `"serving_engine": "athena"` line fails CI** on a silo outside the Pre-Sales roster, and the Snowflake default fails the pin that keeps Snowflake WAI to two silos. No form of `weekly_audience_insights` passes before enrollment.
9. **The sizer logs one failed statement per run** (`Database 'SILONNEU' does not exist`): a handled probe. Do not chase it.
10. **Reviewers cannot see any of this.** On silo76 neither the code review nor the review bot's full review had a way to find the GAM gap; it came from the portal pre-flight, before the PR existed. Reviews confirm the opt-outs are honoured; they do not replace steps 1 and 4.
