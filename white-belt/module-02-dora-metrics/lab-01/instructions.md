# Lab 01: See DORA Metrics Live in Grafana

**Module**: White Belt — Module 2: DORA Metrics
**Estimated Time**: 25 minutes (the dashboard needs up to two minutes to catch up after each event)
**Difficulty**: Beginner (no Grafana or DORA experience required)
**Runs against**: [uFawkesObs `v1.0.6-rc.1`](https://github.com/paruff/uFawkesObs/releases/tag/v1.0.6-rc.1) (Docker Compose), not `fawkes`/Kubernetes. This is a **pre-release** pin: uFawkesObs has no stable release yet, and the lab moves to the stable tag when it ships ([#41](https://github.com/paruff/uFawkesDojo/issues/41)).

---

## Objectives

By the end of this lab you will have:

1. Opened a real, already-built DORA dashboard and identified what each panel measures
2. Sent one real deployment event into the pipeline via a plain `curl` request
3. Watched the Deployment Frequency panel change within about a minute
4. Sent a failed deployment and an incident event, and watched Change Failure
   Rate and Time to Restore respond
5. Explained, in your own words, what data has to exist for a DORA dashboard
   to mean anything

## Why this lab looks different from Lab 01 in Module 1

Module 1's lab runs against the `fawkes` platform itself (Kubernetes,
ArgoCD, Backstage). This lab runs against a **different repository** —
[uFawkesObs](https://github.com/paruff/uFawkesObs) — because that's where a
complete, working DORA ingestion → compute → dashboard pipeline already
exists, self-contained in Docker Compose. You do not need a Kubernetes
cluster, ArgoCD, or Backstage for this lab. You need Docker.

---

## Step 0 — Read the theory first (if you haven't)

This lab assumes you've read
[`modules/white-belt/module-02-dora-metrics.md`](../../../modules/white-belt/module-02-dora-metrics.md)
up through "Why These Five Metrics?" You should be able to name all five
DORA metrics before starting.

## Prerequisites

```bash
# In a separate directory from your uFawkesDojo checkout:
export OBS_TAG=v1.0.6-rc.1
git clone -c advice.detachedHead=false --depth 1 --branch "$OBS_TAG" \
  https://github.com/paruff/uFawkesObs.git
cd uFawkesObs

# Copy the env template and set a real Grafana password
cp .env.example .env
# Edit .env and replace GRAFANA_ADMIN_PASSWORD's REPLACE_ME with a real value

# Start the core stack plus the self-contained DORA pipeline (SQLite-backed)
make up-dora
```

Wait for services to report healthy:

```bash
make status
```

**Tools required**: `docker`, `docker compose` (v2+), `curl`. All included
in a standard Docker Desktop install.

---

## Step 1 — Tour the DORA Overview dashboard (5 minutes)

Open Grafana: **<http://localhost:3000>** (login: `admin` / the password you
set in `.env`).

Navigate to **Dashboards → DORA Overview**. The stack has received no
events yet, so the panels read **0** or "No data". That is correct: you
are not looking at numbers yet, you are learning what each panel *will*
measure once events arrive in Steps 2 and 3.

Read the panel titles and match each to the DORA metric it shows:

- **Deployment Frequency** → how often you deploy
- **Lead Time for Changes** → commit-to-production time
- **Change Failure Rate** → the share of deploys that failed
- **Failed Deployment Recovery Time (FDRT)** → how long recovery takes (the
  theory doc calls this Time to Restore, or MTTR)
- **Rework Rate** → the share of merged work later reverted or hotfixed

Now open **Dashboards → uFawkesObs — DORA Metrics**. Its first panel says
**"DORA 2026 — Five Key Metrics"** — not four. Find the panel for the fifth
metric, **Rework Rate** (% of merged work later reverted or hotfixed). The
DORA research program added this in late 2025; the theory doc covers it as
"Deployment Rework Rate", and here you see it live. Ignore the two "uFawkesRes PostgreSQL" panels
near the bottom: uFawkesRes is deprecated and this lab does not use them.

✅ **Checkpoint**: You should be able to point at a specific panel for each
of the five metrics before moving on.

---

## Step 2 — Send a real deployment event (5 minutes)

Every panel you just looked at is driven by events sent to a real HTTP API.
Send one yourself:

```bash
curl -s -X POST http://localhost:8088/event \
  -H "Content-Type: application/json" \
  -d '{
    "schema_version": "1.0",
    "event_type": "deployment",
    "repo": "your-name/dojo-lab",
    "service": "dojo-lab-service",
    "environment": "production",
    "commit_sha": "'"$(printf '%040d' 1)"'",
    "deployed_at": "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'",
    "status": "success",
    "pipeline_url": "https://example.com/ci/1"
  }'
```

Expected response: `{"queued":true,"id":1}` (the id counts up from 1 on a
fresh stack).

> **What just happened**: `dora-api` validated your payload against
> [`dora/events/deployment-event.schema.json`](https://github.com/paruff/uFawkesObs/blob/main/dora/events/deployment-event.schema.json)
> and queued it. A background worker will pick it up and write it to the
> DORA database. This is the exact same schema a real CI/CD pipeline would
> POST to — you just did by hand what a robot normally does.

You do not need to restart anything. `make up-dora` sets the compute loop
to run every 15 seconds (`DORA_COMPUTE_INTERVAL_SECONDS=15`), inside the
`dora-api` container. You can see its result straight away:

```bash
curl -s http://localhost:8088/metrics | grep '^dora_deployment_frequency'
```

**Expected output**:

```
dora_deployment_frequency_per_week{team_id="your-name/dojo-lab",tier="low"} 0.23333333333333334
```

That is one deployment in the last 30 days, expressed per week. Prometheus
then refreshes the dashboard's numbers every 60 seconds, so wait up to about
two minutes and refresh **uFawkesObs — DORA Metrics** in your browser.

✅ **Checkpoint**: The Deployment Frequency panel should read about **0.23**.
It shows a weekly rate, not a count. If it still reads 0 after two minutes,
see Troubleshooting below.

---

## Step 3 — Send a failure and an incident (5 minutes)

Repeat Step 2, but this time send a **failed** deployment:

```bash
curl -s -X POST http://localhost:8088/event \
  -H "Content-Type: application/json" \
  -d '{
    "schema_version": "1.0",
    "event_type": "deployment",
    "repo": "your-name/dojo-lab",
    "service": "dojo-lab-service",
    "environment": "production",
    "commit_sha": "'"$(printf '%040d' 2)"'",
    "deployed_at": "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'",
    "status": "failed",
    "pipeline_url": "https://example.com/ci/2"
  }'
```

Wait up to two minutes and refresh the dashboard. To see the API's side of
it straight away:

```bash
curl -s http://localhost:8088/metrics | grep '^dora_cfr_pct'
```

**Expected output**:

```
dora_cfr_pct{team_id="your-name/dojo-lab",tier="low"} 0.5
```

✅ **Checkpoint**: Change Failure Rate should now read **50.0%** (the panel
shows the ratio 0.5 as a percentage: 1 failed deployment out of 2). The
Deployment Frequency figure stays at 0.23, because it counts successful
deployments.

Recall from the theory doc: **elite performers have a nonzero CFR too**
(0–15%). A dashboard showing 0% forever is a sign that failures aren't
being reported, not that everything is perfect.

---

## Step 4 — Retrieval check (5 minutes)

Answer these without looking back at the theory doc. Write your answers
down — there's no auto-grader, but writing them (not just thinking them)
is the point.

1. Which panel would you check first if you suspected a recent release
   caused an outage?
2. You just sent 2 deployments, 1 of them failed. What's your Change
   Failure Rate? What performance tier does that put you in?
3. Your team ships 3 small PRs a day instead of 1 large one a week. Which
   DORA metric moves first, and why?
4. What is the fifth DORA metric, and why might a fast-moving AI-assisted
   team want to watch it closely?
5. Name one thing that had to be true for the panel you looked at in Step 1
   to show real numbers instead of "No data."

(Suggested answers, don't peek until you've tried: 1 = Change Failure Rate
or Time to Restore; 2 = 50%, which is well outside even the "Low" tier —
one bad sample size isn't a real signal, which is itself worth noticing;
3 = Deployment Frequency, because batch size shrank; 4 = Rework Rate,
because AI-assisted code can ship fast and still need heavy correction;
5 = an event had to be sent to `dora-api` and processed by the compute
loop inside `dora-api`.)

---

## Step 5 — Run the validation script

```bash
# From inside your uFawkesObs checkout:
bash /path/to/uFawkesDojo/white-belt/module-02-dora-metrics/lab-01/validate.sh
```

**Expected output** (all 8 checks pass):

```
[✓] Prerequisites: docker and curl are installed
[✓] Stack: dora-api container (ufawkesdora-ingestion) is running
[✓] Stack: grafana container (grafana) is running
[✓] DORA Compute: dora-api exposes DORA metrics at http://localhost:8088/metrics (compute runs in-process)
[✓] dora-api Health: reachable at http://localhost:8088, response: {"status":"ok","queue_depth":0}
[✓] Grafana Health: reachable at http://localhost:3000
[✓] DORA Overview Dashboard: reachable via Grafana API (uid=ufawkesobs-dora-overview)
[✓] DORA Metrics Dashboard: reachable via Grafana API (uid=ufawkesobs-dora-metrics)

Total Tests : 8
Passed      : 8
Failed      : 0

[✓] All tests passed! ✅
```

---

## Clean Up

```bash
# From your uFawkesObs checkout:
docker compose --profile core --profile dora down
```

`make down` does not stop this stack at this version: it runs
`docker compose down` without the profiles `make up-dora` started
([uFawkesObs#617](https://github.com/paruff/uFawkesObs/issues/617)). This lab
used the `dora` profile's self-contained SQLite backend — nothing to clean up
beyond stopping containers.

---

## Troubleshooting

| Problem                                   | Cause                                       | Fix                                                                 |
| ------------------------------------------ | -------------------------------------------- | -------------------------------------------------------------------- |
| `curl: (7) Failed to connect` on port 8088 | Stack not up yet, or `dora` profile not started | Run `make up-dora`, then `make status`                             |
| `422` response from `/event`               | Payload doesn't match the schema             | Check every required field is present; `commit_sha` must be exactly 40 hex characters |
| Dashboard still shows old numbers          | Prometheus refreshes the DORA rules every 60 s | Wait up to two minutes. Check the API first: `curl -s http://localhost:8088/metrics \| grep '^dora_'` |
| Grafana asks for login you don't know      | `.env` still has the placeholder password    | Check `.env`; `make check-env` will refuse to start with a weak default |
| `make up-dora` fails immediately           | Docker not running, or ports already in use  | Start Docker Desktop; check nothing else uses 3000/8088/9090        |

---

➡️ **Next**: Return to [Module 2 README](../README.md), then continue to
Module 3: GitOps Principles.
