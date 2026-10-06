"""Portal + GAM pre-flight for /config-pub-airflow. READ-ONLY (SELECTs and one GAM read).

Runs INSIDE the prod airflow-webserver container as the `airflow` user. From the laptop:

    B64=$(base64 < portal_preflight.py | tr -d '\n')
    TASK=$(aws ecs list-tasks --profile prod --region us-east-1 --cluster ArcSpanProdCluster \
      --service-name arcspanairflow-AirflowService-vJtFXqmj5rLa --query 'taskArns[0]' --output text)
    aws ecs execute-command --profile prod --region us-east-1 --cluster ArcSpanProdCluster \
      --task "$TASK" --container airflow-webserver --interactive \
      --command "bash -c 'echo $B64 | base64 -d > /tmp/pp.py && su airflow -c \"python /tmp/pp.py\" 2>&1 | grep -E \"^(SILO|PUB|GAM|OPENX|NULLGAM|DONE)|Error|Traceback\"; rm -f /tmp/pp.py'"

Edit NEW and CONTROL below first. One command per execute-command call: a second command
chained after the first is often cut off, and "Cannot perform start session: EOF" at the end
of the output is noise, not a failure.
"""
import glob
import json
import os
import sys

NEW = ["silo77"]        # the silo(s) being onboarded
CONTROL = "silo75"      # a live silo whose rows and GAM access are known good

for cand in ["/opt/airflow/dags"] + glob.glob("/opt/airflow/dags/*/airflow-dags") + glob.glob("/opt/airflow/dags/*"):
    if os.path.exists(os.path.join(cand, "utils.py")):
        sys.path.insert(0, cand)
        break

import mysql.connector  # noqa: E402
from utils import get_mysql_credentials  # noqa: E402

# Keep the connection in a variable: chaining .cursor() off connect() lets the connection be
# collected and every query then fails with "Cursor is not connected".
conn = mysql.connector.connect(**get_mysql_credentials("arcspan_sandbox/prod/sql_database"))
cur = conn.cursor(dictionary=True, buffered=True)

subs = NEW + [CONTROL]
marks = ", ".join(["%s"] * len(subs))
cur.execute(
    "SELECT sid, subdomain, status, publisher_id, gam_network_codes, openx_org_id "
    f"FROM silos WHERE subdomain IN ({marks}) ORDER BY subdomain, sid", subs)
rows = cur.fetchall()
for r in rows:
    print("SILO", {k: r[k] for k in ("sid", "subdomain", "status", "publisher_id", "gam_network_codes")})
    print("OPENX", r["subdomain"], r["status"], r["openx_org_id"])

# Want, per new silo: exactly ONE row with status != 0, gam_network_codes a JSON string
# (never NULL), and a publisher row behind it whose data_center is the region you will write.
for pid in sorted({r["publisher_id"] for r in rows if r["publisher_id"] is not None}):
    cur.execute(
        "SELECT pid, publisher_name, status, data_center, builder_configuration IS NULL AS bc_null, "
        "CHAR_LENGTH(builder_configuration) AS bc_len FROM publisher WHERE pid = %s", (pid,))
    print("PUB", cur.fetchall())

cur.execute("SELECT COUNT(*) AS n FROM silos WHERE status = 1 AND gam_network_codes IS NULL")
print("NULLGAM", cur.fetchall())  # want 0: daily_gam_reports/entities.py json.loads()es it unguarded

# GAM API access, with the DAGs' own client. A configured code WITHOUT access is the state
# that fails nightly; an empty list ('[]') and a code WITH access are both fine.
from daily_gam_reports.shared import adManagerClient  # noqa: E402

for r in rows:
    if r["status"] == 0:
        continue
    for code in json.loads(r["gam_network_codes"] or "[]"):
        try:
            net = adManagerClient(code).GetService("NetworkService").getCurrentNetwork()
            print("GAM", r["subdomain"], code, "OK", net["displayName"])
        except Exception as e:  # AuthenticationError.NO_NETWORKS_TO_ACCESS = not granted
            print("GAM", r["subdomain"], code, "FAIL", type(e).__name__, str(e)[:200].replace("\n", " "))
print("DONE")
