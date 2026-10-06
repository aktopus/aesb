-- /config-pub-airflow pre-flight inventory. Read-only.
-- Replace SILONN (and silonn / S3_ASPANSILONNLOG) with the new silo, and SILOCC with the
-- control: the most recently onboarded silo that is live (SILO75 as of 2026-10). Run each
-- statement on the MCP that matches the silo's region. Every query carries a control so an
-- empty result cannot pass as good news: if the control comes back empty too, the query is
-- wrong, not the silo.

-- 0. The database's warehouse exists (every per-silo task defaults to it).
SHOW WAREHOUSES LIKE 'SILO%_WH';   -- want a SILONN_WH row; the other rows are the control

-- 1. Objects the new silo lacks that the control has. Classify EVERY row with the
--    "who creates it" table in SKILL.md before deciding it is fine.
SELECT c.table_name, c.table_type
FROM SILOCC.INFORMATION_SCHEMA.TABLES c
LEFT JOIN SILONN.INFORMATION_SCHEMA.TABLES n
       ON n.table_schema = c.table_schema AND n.table_name = c.table_name
WHERE c.table_schema = 'PUBLIC' AND n.table_name IS NULL
ORDER BY 1;
-- control: SELECT COUNT(*) FROM SILONN.INFORMATION_SCHEMA.TABLES WHERE table_schema = 'PUBLIC';  -- must be > 0

-- 2. Column drift on the objects both have (builder SQL compiles against these columns).
--    Want: zero rows besides the common_cols line, and common_cols in the hundreds.
WITH a AS (SELECT table_name, column_name FROM SILOCC.INFORMATION_SCHEMA.COLUMNS WHERE table_schema = 'PUBLIC'),
     b AS (SELECT table_name, column_name FROM SILONN.INFORMATION_SCHEMA.COLUMNS WHERE table_schema = 'PUBLIC'),
     t AS (SELECT table_name FROM SILONN.INFORMATION_SCHEMA.TABLES WHERE table_schema = 'PUBLIC')
SELECT 'in_control_not_new' AS side, a.table_name, a.column_name
FROM a JOIN t ON t.table_name = a.table_name
LEFT JOIN b ON b.table_name = a.table_name AND b.column_name = a.column_name
WHERE b.column_name IS NULL
UNION ALL
SELECT 'in_new_not_control', b.table_name, b.column_name
FROM b LEFT JOIN a ON a.table_name = b.table_name AND a.column_name = b.column_name
WHERE a.column_name IS NULL AND b.table_name IN (SELECT table_name FROM a)
UNION ALL
SELECT 'common_cols', 'ALL', COUNT(*)::STRING
FROM a JOIN b ON a.table_name = b.table_name AND a.column_name = b.column_name
ORDER BY 1, 2, 3;

-- 3. Streams. Read the `stale` and `stale_after` columns. ALL of them can be stale on a
--    database provisioned more than 14 days before its proc first runs.
SHOW STREAMS IN DATABASE SILONN;

-- 4. Legacy Snowflake tasks. The pattern must also match the control's tasks, or the
--    empty answer for the new silo proves nothing.
SHOW TASKS LIKE 'SILO7%' IN ACCOUNT;   -- widen/narrow the pattern so it spans SILOCC and SILONN

-- 5. Edge-log date parse. Old databases parse the day with a fixed offset that assumes a
--    14-character CloudFront id; a 13-character id loads nothing, with every run green.
SELECT REGEXP_SUBSTR(GET_DDL('TABLE', 'SILONN.PUBLIC.EDGEDMP_EXT'), '[^\n]*DAY DATE AS[^\n]*') AS day_expr;
--    If day_expr uses SUBSTRING(METADATA$FILENAME, 24, 10): LIST the stage and confirm
--    characters 24-33 of every path relative to the bucket (edgedmp/<id>.<date>-<hh>...)
--    are a date. SPLIT_PART(METADATA$FILENAME, '.', 2) is the width-independent form.
LIST @SILONN.PUBLIC.S3_ASPANSILONNLOG;

-- 6. Has the external table ever been refreshed? Zero registered files before the first
--    proc run is NORMAL (the proc refreshes it). It means EDGEDMP_EXT reads empty, which
--    is not the same as "no logs". Do not refresh it by hand: the stream is recreated
--    first and the proc's own refresh is what feeds it.
SELECT (SELECT COUNT(*) FROM TABLE(SILONN.INFORMATION_SCHEMA.EXTERNAL_TABLE_FILES(TABLE_NAME => 'SILONN.PUBLIC.EDGEDMP_EXT'))) AS new_registered_files,
       (SELECT COUNT(*) FROM SILOCC.PUBLIC.EDGEDMP_EXT WHERE day = CURRENT_DATE()) AS control_rows_today;

-- 6b. BEFORE the first run: the request mix straight from the stage (the external table is
--     still empty). Columns are CloudFront's: $1 date, $8 uri stem, $10 referer, $11 user
--     agent. A provisioning smoke test (referer aspantemp1.s3.amazonaws.com) and curl fetches
--     are not publisher traffic.
SELECT $8 AS cs_uri_stem, COUNT(*) AS n, MIN($1) AS first_day, MAX($1) AS last_day,
       MIN(LEFT($10, 50)) AS sample_referer, MIN(LEFT($11, 40)) AS sample_ua
FROM @SILONN.PUBLIC.S3_ASPANSILONNLOG (FILE_FORMAT => 'util_db.public.tsv_skip_2_header')
GROUP BY 1 ORDER BY 2 DESC;

-- 7. AFTER the first proc run: beacons or only script fetches? A live tag shows /as1.js,
--    /bs1.js and /p.png by the thousands; a page that only fetches /as.js (a 17-byte stub
--    on every silo) sends no events. Discount rows whose user agent is curl: a direct
--    fetch of /as1.js becomes a 'page' tag-fire row in ARCTAG_DAILY_EVENTS.
SELECT 'new' AS who, day, cs_uri_stem, COUNT(*) AS n, COUNT(DISTINCT c_ip) AS ips,
       MIN(LEFT(cs_referer, 60)) AS sample_referer
FROM SILONN.PUBLIC.EDGEDMP_EXT WHERE day >= DATEADD(day, -14, CURRENT_DATE())
GROUP BY 1, 2, 3
UNION ALL
SELECT 'control', day, cs_uri_stem, COUNT(*), COUNT(DISTINCT c_ip), NULL
FROM SILOCC.PUBLIC.EDGEDMP_EXT WHERE day = CURRENT_DATE() AND cs_uri_stem IN ('/p.png', '/as1.js', '/as.js')
GROUP BY 1, 2, 3
ORDER BY 1, 2 DESC, 4 DESC;

-- 8. AFTER the first proc run: rows down the chain, and failed statements.
SELECT 'EDGEDMP_EXT' AS obj, COUNT(*) AS n, MIN(day)::STRING AS min_day, MAX(day)::STRING AS max_day FROM SILONN.PUBLIC.EDGEDMP_EXT
UNION ALL SELECT 'EDGEDMP_INT', COUNT(*), MIN(day)::STRING, MAX(day)::STRING FROM SILONN.PUBLIC.EDGEDMP_INT
UNION ALL SELECT 'ARCTAG_DAILY_EVENTS_RAW', COUNT(*), MIN(day)::STRING, MAX(day)::STRING FROM SILONN.PUBLIC.ARCTAG_DAILY_EVENTS_RAW
UNION ALL SELECT 'ARCTAG_DAILY_EVENTS', COUNT(*), MIN(day)::STRING, MAX(day)::STRING FROM SILONN.PUBLIC.ARCTAG_DAILY_EVENTS
UNION ALL SELECT 'REPORT_COHORT_AGGREGATE', COUNT(*), NULL, NULL FROM SILONN.PUBLIC.REPORT_COHORT_AGGREGATE;
--    EDGEDMP_INT holds only day >= CURRENT_DATE - 1 by design, so it is far smaller than EXT.

SELECT TO_CHAR(CONVERT_TIMEZONE('UTC', start_time), 'HH24:MI:SS') AS utc, execution_status, query_tag,
       LEFT(REGEXP_REPLACE(query_text, '\\s+', ' '), 90) AS q, LEFT(error_message, 200) AS err
FROM TABLE(SILONN.INFORMATION_SCHEMA.QUERY_HISTORY(END_TIME_RANGE_START => DATEADD(minute, -30, CURRENT_TIMESTAMP()), RESULT_LIMIT => 1000))
WHERE user_name = 'AIRFLOWUSER'
  AND (database_name = 'SILONN' OR query_tag ILIKE '%silonn%')
  AND (execution_status <> 'SUCCESS' OR query_text ILIKE 'CALL %')
ORDER BY start_time DESC;
--    This table function is ACCOUNT-wide despite the SILONN prefix, hence the filters.
--    Expected on every sizer run: one failure "Database 'SILONNEU' does not exist" (logged
--    under database ASPANDB), a probe for an EU shadow database inside an exception handler.
--    The CALL rows are the control.
