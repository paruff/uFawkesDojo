# Lab 02: Emit a Delivery Event and See It in Grafana

**Module**: White Belt — Module 2: DORA Metrics
**Estimated Time**: 15 minutes
**Difficulty**: Beginner (no CI/CD pipeline experience required)
**Prerequisites**: Lab 01 completed (uFawkesObs stack running, `dora-compute` reachable)
**Runs against**: uFawkesObs (Docker Compose) + uFawkesAI scripts

---

## What this lab replaces

Lab 01 had you `curl` the `dora-api` directly. That was a workaround for
GAP-01..03 (missing `jsonschema`, broken repo inference, no Loki proof).
Those gaps are now fixed in `uFawkesAI/scripts/emit-dora-event.sh` and
`verify-dora-event-in-loki.sh`. This lab uses the **real emitter** — the
same script uFawkesPipe runs in CI — and proves the event reaches Grafana
via Loki.

---

## Prerequisites

```bash
# In a separate directory from your uFawkesDojo checkout:
git clone https://github.com/paruff/uFawkesAI.git
cd uFawkesAI

# Start uFawkesObs (if not still running from Lab 01)
cd ../uFawkesObs
make up-dora
make status
```

**Tools required**: `docker`, `docker compose` (v2+), `bash`, `jq`, `curl`,
`python3`, `gh` (optional, for PR metadata). All included in a standard
Docker Desktop install plus `gh` from GitHub CLI.

---

## Step 1 — Emit a real delivery event (5 minutes)

Every panel you looked at in Lab 01 is driven by events sent to
`dora-api` / Loki. The canonical way to emit one is
`scripts/emit-dora-event.sh deploy-marker` — it builds a full DORA
deployment event with PR metadata, agent tokens, and schema validation.

```bash
# From inside your uFawkesAI checkout:
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318 \
  bash scripts/emit-dora-event.sh deploy-marker \
    --status success \
    --environment production \
    --deployment-intent planned \
    --repo your-name/dojo-lab
```

Expected output: one JSON line on stdout (the event), and the same line
sent via OTLP to the collector at `localhost:4318`.

**What just happened**:
- The emitter built a `deploy-marker` event with your repo, a generated
  commit SHA, environment `production`, intent `planned`.
- It resolved the repo from `git remote get-url origin` (no `--repo`
  needed because you're in a git clone).
- It validated the payload against
  `dora/events/deployment-event.schema.json` (stdlib draft-07, no pip).
- It printed the event to stdout **and** posted it via OTLP to the
  collector at `localhost:4318`, which routes logs to Loki.

---

## Step 2 — Verify the event reached Loki (3 minutes)

The `verify-dora-event-in-loki.sh` script emits a marker event and polls
Loki until it appears.

```bash
# From inside your uFawkesAI checkout:
bash scripts/verify-dora-event-in-loki.sh
```

Expected output:

```
LogQL: {service_name="uFawkesAI", exporter="OTLP"} | json | line_format "{{.body}}" | json | event="job-finish" | step="verify-20261004T120000Z-12345"
✅ Event found in Loki:
{"@timestamp":"2026-10-04T12:00:00Z","level":"info","logger":"dora","event":"job-finish","step":"verify-20261004T120000Z-12345",...}
```

**What just happened**:
- The script emitted a unique `job-finish` event with a per-run `step`
  marker over OTLP.
- It polled Loki's `query_range` API with the documented LogQL until the
  marker appeared (or timed out after 30s).
- Exit 0 = event found; Exit 1 = timeout; Exit 2 = Loki unreachable
  (SKIP).

> **Note**: This is the exact verification used by uFawkesAI's AC-AI-06
> and the `dora-events-portability` spec (REQ-003 / AC-04).

---

## Step 3 — See it in Grafana (5 minutes)

Now open Grafana and watch the dashboards update.

```bash
# Open Grafana
open http://localhost:3000
# Login: admin / the password you set in uFawkesObs/.env
```

1. **Dashboards → DORA Metrics** — refresh after 20–30 seconds
   - **Deployment Frequency** count goes up by 1
   - **Rework Rate** shows your new event's `ai_assisted` flag
   - **Lead Time for Changes** appears (from PR metadata)

2. **Dashboards → DORA Overview** — refresh
   - The worked-example data now includes your real event

3. **Explore** → select **Loki** data source → run the LogQL:
   ```logql
   {service_name="uFawkesAI", exporter="OTLP"} | json | event="deployment"
   ```
   You'll see your `deploy-marker` event with full DORA payload:
   `schema_version`, `event_type`, `repo`, `service`, `environment`,
   `commit_sha`, `deployed_at`, `status`, `deployment_intent`,
   `pipeline_url`, `ai_assisted`, `first_commit_at`, `pr_merged_at`.

---

## Step 4 — Retrieval check (2 minutes)

Answer these without looking back. Write your answers down.

1. What OTLP endpoint did the emitter POST to, and what component in
   uFawkesObs received it?
2. The `verify-dora-event-in-loki.sh` script uses `job-finish` as the
   event type, not `deploy-marker`. Why?
3. In Grafana Explore, which Loki label did you filter on to find only
   your events?
4. If the Loki query returned no results, what are the three most likely
   causes?

(Suggested answers: 1 = `localhost:4318` → OTel Collector → Loki; 2 = the
verification script was written for `job-finish` events (GAP-03), but the
same LogQL works with `event="deployment"`; 3 = `service_name="uFawkesAI"`
or `exporter="OTLP"`; 4 = collector not running, Loki not scraping, OTLP
endpoint wrong.)

---

## Step 5 — Run the validation script

```bash
# From inside your uFawkesAI checkout:
bash /path/to/uFawkesDojo/white-belt/module-02-dora-metrics/lab-02/validate.sh
```

Expected output (all checks pass):

```
[INFO] Starting White Belt Module 02 Lab 02 validation...

[✓] Prerequisites: docker, curl, jq, python3, gh are installed
[✓] Stack: dora-api container is running
[✓] Stack: dora-compute container is running
[✓] Stack: grafana container is running
[✓] uFawkesAI scripts: emit-dora-event.sh present
[✓] uFawkesAI scripts: verify-dora-event-in-loki.sh present
[✓] emit-dora-event.sh: deploy-marker event emitted and queued
[✓] verify-dora-event-in-loki.sh: marker event found in Loki
[✓] DORA Metrics Dashboard: deploy-marker event visible via Grafana API

==========================================
Total Tests: 9
Passed: 9
Failed: 0

[✓] All tests passed! ✅

🎉 Congratulations! You've completed White Belt Module 2 Lab 02.
   You emitted a real delivery event via the canonical emitter,
   proved it reached Loki, and saw it in Grafana.
   Move on to Module 03: GitOps Principles.
```

---

## Clean Up

```bash
# From your uFawkesObs checkout:
make down
```

---

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| `emit-dora-event.sh` fails with `jq: not found` | `jq` not installed | `apt-get install jq` / `brew install jq` |
| `verify-dora-event-in-loki.sh` exits 2 (SKIP) | Loki not reachable | `cd ../uFawkesObs && make up-dora && make status` |
| `verify-dora-event-in-loki.sh` exits 1 (timeout) | Collector not routing to Loki, or Loki not scraping | Check `docker compose logs otel-collector` and `docker compose logs loki` |
| Dashboard doesn't update | `dora-compute` hasn't recomputed | `docker compose restart dora-compute`, wait ~20s, refresh |
| `gh` PR lookup fails | `gh` not authenticated or no PR for commit | `gh auth login` or supply `--repo` explicitly |

---

## What you learned

- The **canonical emitter** is `scripts/emit-dora-event.sh deploy-marker`
  — no `curl` hand-crafting needed.
- **Repo inference** works automatically from `git remote` (GAP-02 fixed).
- **Schema validation** uses stdlib draft-07, no `pip install` (GAP-01 fixed).
- **Loki verification** is a first-class script (GAP-03 fixed / REQ-003).
- **Grafana Explore + LogQL** is how you debug the full path.

---

➡️ **Next**: Return to [Module 2 README](../README.md), then continue to
Module 3: GitOps Principles.
