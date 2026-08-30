# Lab 01: See DORA Metrics Live in Grafana

**Module**: White Belt — Module 2: DORA Metrics
**Estimated Time**: 20 minutes
**Difficulty**: Beginner (no Grafana or DORA experience required)
**Runs against**: [uFawkesObs](https://github.com/paruff/uFawkesObs) (Docker Compose), not `fawkes`/Kubernetes

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
up through "Why These Four Metrics?" You should be able to name the four
original DORA metrics before starting. (Spoiler for later in this lab:
there's now a fifth.)

## Prerequisites

```bash
# In a separate directory from your uFawkesDojo checkout:
git clone https://github.com/paruff/uFawkesObs.git
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

Navigate to **Dashboards → DORA Overview**. This dashboard already has
seed/historical data in it — you haven't done anything yet, and it isn't
empty. That's deliberate: you're studying a **worked example** before you
touch anything.

For each panel, write down (mentally or on paper) which of the DORA key
metrics it maps to:

- A panel showing deploys-per-day → **Deployment Frequency**
- A panel showing commit-to-production time → **Lead Time for Changes**
- A panel showing % of deploys that failed → **Change Failure Rate**
- A panel showing incident recovery time → **Time to Restore**

Now open **Dashboards → DORA Metrics**. Look at its title bar. It says
**"DORA 2026 — Five Key Metrics"** — not four. Find the panel for the fifth
metric, **Rework Rate** (% of merged work later reverted or hotfixed). The
DORA research program added this in late 2025; the theory doc's "Four Key
Metrics" framing predates that change, which is exactly why you're seeing
it live here instead.

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

Expected response: `{"queued":true,"id":<some number>}`.

> **What just happened**: `dora-api` validated your payload against
> [`dora/events/deployment-event.schema.json`](https://github.com/paruff/uFawkesObs/blob/main/dora/events/deployment-event.schema.json)
> and queued it. A background worker will pick it up and write it to the
> DORA database. This is the exact same schema a real CI/CD pipeline would
> POST to — you just did by hand what a robot normally does.

By default the compute job that turns queued events into dashboard numbers
runs once an hour (`DORA_COMPUTE_INTERVAL_SECONDS=3600`). Restarting it
forces an immediate recompute instead of waiting:

```bash
docker compose restart dora-compute
```

Wait about 20 seconds, then refresh the **DORA Metrics** dashboard in your
browser.

✅ **Checkpoint**: The Deployment Frequency panel's count should have gone
up by one. If it hasn't after a minute, see Troubleshooting below.

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

Restart `dora-compute` again and refresh the dashboard:

```bash
docker compose restart dora-compute
```

✅ **Checkpoint**: Change Failure Rate should now show a non-zero
percentage (1 failed out of however many deployments you've now sent).

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
5 = an event had to be sent to `dora-api` and successfully processed by
`dora-compute`.)

---

## Step 5 — Run the validation script

```bash
# From inside your uFawkesObs checkout:
bash /path/to/uFawkesDojo/white-belt/module-02-dora-metrics/lab-01/validate.sh
```

**Expected output** (all checks pass):

```
[INFO] Starting White Belt Module 02 Lab 01 validation...

[✓] Prerequisites: docker and curl are installed
[✓] Stack: dora-api container is running
[✓] Stack: dora-compute container is running
[✓] Stack: grafana container is running
[✓] dora-api Health: reachable, queue_depth reported
[✓] Grafana Health: reachable
[✓] DORA Overview Dashboard: reachable via Grafana API
[✓] DORA Metrics Dashboard: reachable via Grafana API

==========================================
Total Tests: 7
Passed: 7
Failed: 0

[✓] All tests passed! ✅

🎉 Congratulations! You've completed White Belt Module 2 Lab 01.
   You've seen real DORA metrics move because of events you sent yourself.
   Move on to Module 03: GitOps Principles.
```

---

## Clean Up

```bash
# From your uFawkesObs checkout:
make down
```

This lab used the `dora` profile's self-contained SQLite backend — nothing
to clean up beyond stopping containers.

---

## Troubleshooting

| Problem                                   | Cause                                       | Fix                                                                 |
| ------------------------------------------ | -------------------------------------------- | -------------------------------------------------------------------- |
| `curl: (7) Failed to connect` on port 8088 | Stack not up yet, or `dora` profile not started | Run `make up-dora`, then `make status`                             |
| `422` response from `/event`               | Payload doesn't match the schema             | Check every required field is present; `commit_sha` must be exactly 40 hex characters |
| Dashboard still shows old numbers          | `dora-compute` hasn't recomputed yet         | `docker compose restart dora-compute`, wait ~20s, refresh           |
| Grafana asks for login you don't know      | `.env` still has the placeholder password    | Check `.env`; `make check-env` will refuse to start with a weak default |
| `make up-dora` fails immediately           | Docker not running, or ports already in use  | Start Docker Desktop; check nothing else uses 3000/8088/9090        |

---

➡️ **Next**: Return to [Module 2 README](../README.md), then continue to
Module 3: GitOps Principles.
