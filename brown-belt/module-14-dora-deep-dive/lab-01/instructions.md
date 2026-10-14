# Lab 01: DORA Metrics Deep Dive with uFawkesObs

**Module**: Brown Belt — Module 14: DORA Metrics Deep Dive
**Estimated Time**: 60 minutes
**Difficulty**: Advanced (Module 13 complete required)
**Runs against**: [uFawkesObs `v1.1.0-rc.1`](https://github.com/paruff/uFawkesObs/releases/tag/v1.1.0-rc.1) — a **pre-release**, the same checkout as Module 13 — with the DORA profile

> **Run for real on 2026-10-14 against `v1.1.0-rc.1` (pre-release), through the stack's APIs.** Every step ran verbatim: the events, the PromQL in Prometheus's HTTP API, the dashboard queries through Grafana's datasource API, and the alert rules (loaded, then checked as `pending` or `inactive`). Grafana's browser-only clicks (building and saving the dashboard) were not exercised in a browser. The lab moves to the stable tag when uFawkesObs ships it. See the [audit](../../../docs/ai-sdlc/compose-curriculum/audit-2026-10-06.md).

---

## Objectives

By the end of this lab you will have:

1. Verified uFawkesObs DORA profile is running (`dora-api`, which also computes the metrics)
2. Sent test deployment events to dora-api
3. Queried all 5 DORA metrics via PromQL in Grafana
4. Built a complete DORA dashboard in Grafana with all 5 metrics
5. Tested failure/recovery scenarios and observed metric changes
6. Configured DORA-specific alerting rules

---

## Why This Lab Uses uFawkesObs DORA Profile

This lab runs against **uFawkesObs** with the **DORA profile** (`make up-dora`) because it provides a complete, self-contained DORA metrics platform in Docker Compose:

- **dora-api** (port 8088, container `ufawkesdora-ingestion`) — Receives deployment and rework events, stores them in SQLite, computes the DORA metrics in-process and serves them on `/metrics` for Prometheus to scrape
- **Prometheus** (port 9090) — Stores time-series, PromQL queries
- **Grafana** (port 3000) — Dashboards, visualization
- **Alloy** — Log collection
- **OTel Collector** — Telemetry ingestion (OTLP)
- **Tempo** — Distributed tracing
- **Loki** — Log aggregation

No Kubernetes required — runs entirely in Docker Compose on your laptop.

---

## Prerequisites

**Required**: the uFawkesObs stack from Module 13, running **with the DORA profile** (`make up-dora`)

```bash
# Verify your stack is running with DORA profile
cd ~/dojo-labs/uFawkesObs
make status
```

**Expected** (image and port columns trimmed): nine containers up, then every health endpoint `✅`:

```
NAME                    SERVICE          STATUS
alertmanager            alertmanager     Up (healthy)
alloy                   alloy            Up (healthy)
grafana                 grafana          Up (healthy)
loki                    loki             Up (healthy)
node-exporter           node-exporter    Up (healthy)
otel-collector          otel-collector   Up
prometheus              prometheus       Up (healthy)
tempo                   tempo            Up
ufawkesdora-ingestion   dora-api         Up (healthy)

Health endpoints:
  ✅ Prometheus  :9090
  ✅ Tempo       :3200
  ✅ Loki        :3100
  ✅ Grafana     :3000
  ✅ Alertmanager:9093
  ✅ OTel Coll.  :8888
  ✅ Alloy       :12345
```

**Required**: Module 13 completed (understand observability pipeline with uFawkesObs)

**Tools required** (already installed from previous modules):
- `curl` — HTTP client
- `jq` — JSON processor
- `git` — version control
- `make` — build automation

---

## Step 0 — Read the Theory First (if you haven't)

This lab assumes you've read the [Module 14 theory](../README.md#theory--concepts-25-minutes) up through "uFawkesObs DORA Architecture". You should be able to name the five DORA metrics and identify the uFawkesObs DORA components.

---

## Step 1 — Verify DORA Profile is Running (5 minutes)

### 1.1 Check DORA Services

```bash
cd ~/dojo-labs/uFawkesObs
make status
```

**Expected**: All services up, including `dora-api` (container `ufawkesdora-ingestion`). `dora-api` also computes the metrics, so there is no second DORA container.

### 1.2 Verify DORA API Health

```bash
# Check DORA API health endpoint
curl -s http://localhost:8088/health
```

**Expected**: `{"status":"ok","queue_depth":0}`

### 1.3 Verify the DORA metrics endpoint

```bash
# dora-api serves the computed DORA metrics itself
curl -s http://localhost:8088/metrics | grep '^dora_' | head
```

**Expected**: after Module 13's test event, lines like these (no output on a stack that has computed no events yet):

```
dora_deployment_frequency_per_week{team_id="your-name/dojo-lab",tier="low"} 0.23333333333333334
dora_cfr_pct{team_id="your-name/dojo-lab",tier="elite"} 0.0
dora_rework_rate_pct{team_id="your-name/dojo-lab",tier="elite"} 0.0
```

Prometheus scrapes this endpoint directly.

> ✅ **Checkpoint**: All DORA profile services are running and accessible.

---

## Step 2 — Send Test Deployment Events (10 minutes)

### 2.1 Send a Successful Deployment Event

Every event uses the deployment-event schema 1.0. `commit_sha` must be a full 40-character SHA; the lab makes one with `printf '%040d'`.

```bash
# Send a successful deployment event
curl -s -w "  HTTP %{http_code}\n" -X POST http://localhost:8088/event \
  -H "Content-Type: application/json" \
  -d '{
    "schema_version": "1.0",
    "event_type": "deployment",
    "repo": "your-name/dojo-lab",
    "service": "test-service",
    "environment": "production",
    "commit_sha": "'"$(printf '%040d' 1401)"'",
    "deployed_at": "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'",
    "status": "success",
    "pipeline_url": "https://example.com/ci/1401"
  }'
```

**Expected**: `{"queued":true,"id":<n>}  HTTP 201`, where `<n>` counts up with each event. Every event in Steps 2 and 5 answers this way. An event with a missing or extra field is rejected with `HTTP 422`.

### 2.2 Send Multiple Events

```bash
# Send a few more events to build up data
for i in 2 3 4 5 6; do
  curl -s -w "  HTTP %{http_code}\n" -X POST http://localhost:8088/event \
    -H "Content-Type: application/json" \
    -d '{
      "schema_version": "1.0",
      "event_type": "deployment",
      "repo": "your-name/dojo-lab",
      "service": "test-service-'"$i"'",
      "environment": "production",
      "commit_sha": "'"$(printf '%040d' "$((1400 + i))")"'",
      "deployed_at": "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'",
      "status": "success",
      "pipeline_url": "https://example.com/ci/'"$((1400 + i))"'"
    }'
  sleep 1
done
```

### 2.3 Send a Failed Deployment Event

```bash
# Send a failed deployment event (status is one of success, failed, rollback)
curl -s -w "  HTTP %{http_code}\n" -X POST http://localhost:8088/event \
  -H "Content-Type: application/json" \
  -d '{
    "schema_version": "1.0",
    "event_type": "deployment",
    "repo": "your-name/dojo-lab",
    "service": "failing-service",
    "environment": "production",
    "commit_sha": "'"$(printf '%040d' 1407)"'",
    "deployed_at": "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'",
    "status": "failed",
    "pipeline_url": "https://example.com/ci/1407"
  }'
```

### 2.4 Send an Incident Rework Event

Rework is its own event type. It points at the deployment it reworks by that deployment's `commit_sha`, and counts toward the Rework Rate only when `user_visible` is `true`. Send the hotfix deployment first, then the rework event for it:

```bash
# The hotfix deployment
curl -s -w "  HTTP %{http_code}\n" -X POST http://localhost:8088/event \
  -H "Content-Type: application/json" \
  -d '{
    "schema_version": "1.0",
    "event_type": "deployment",
    "repo": "your-name/dojo-lab",
    "service": "hotfix-service",
    "environment": "production",
    "commit_sha": "'"$(printf '%040d' 1408)"'",
    "deployed_at": "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'",
    "status": "success",
    "pipeline_url": "https://example.com/ci/1408"
  }'

# The rework event that marks it as user-visible rework
curl -s -w "  HTTP %{http_code}\n" -X POST http://localhost:8088/event \
  -H "Content-Type: application/json" \
  -d '{
    "schema_version": "1.0",
    "event_type": "rework",
    "repo": "your-name/dojo-lab",
    "deployment_sha": "'"$(printf '%040d' 1408)"'",
    "rework_type": "hotfix",
    "triggered_at": "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'",
    "user_visible": true
  }'
```

### 2.5 Trigger DORA Computation

`dora-api` computes the metrics when it starts, then every `DORA_COMPUTE_INTERVAL_SECONDS` (3600 in `.env.example`). Restart it to compute now:

```bash
cd ~/dojo-labs/uFawkesObs
docker compose restart dora-api
sleep 10
curl -s http://localhost:8088/metrics | grep '^dora_'
```

**Expected** (after Module 13's event and the eight above; your values depend on what you have sent):

```
dora_deployment_frequency_per_week{team_id="your-name/dojo-lab",tier="high"} 1.8666666666666667
dora_fdrt_p50_hours{team_id="your-name/dojo-lab",tier="elite"} 0.0
dora_cfr_pct{team_id="your-name/dojo-lab",tier="medium"} 0.1111111111111111
dora_rework_rate_pct{team_id="your-name/dojo-lab",tier="medium"} 0.1111111111111111
```

One failed deployment in nine is a change failure rate of 0.111, and one user-visible rework event in nine deployments is a rework rate of 0.111. `fdrt` is failed deployment recovery time: the next successful deployment of the same repo after the failure. There is no `dora_lead_time_*` line, because these events carry no `first_commit_at` or `pr_merged_at`.

> ✅ **Checkpoint**: Events sent, dora-api restarted, `dora_` metrics served.

---

## Step 3 — Query DORA Metrics via PromQL (15 minutes)

### 3.1 Access Prometheus

Open **http://localhost:9090** (Prometheus UI) and use the **Graph** tab. Prometheus scrapes `dora-api` every 15 seconds, so give it a minute after the restart in Step 2.5.

### 3.2 Query Each DORA Metric

`dora-api` publishes one gauge per metric, labelled by `team_id` and `tier`. There are no histograms and no `rate()` to take: the gauge is already the answer. Run each query:

#### Deployment Frequency
```promql
# Deployments per week
dora_deployment_frequency_per_week

# Deployments per day
dora_deployment_frequency_per_week / 7
```

#### Lead Time for Changes
```promql
dora_lead_time_p50_hours
dora_lead_time_p95_hours
```

These return **nothing** on this lab's data. Lead time needs `first_commit_at` or `pr_merged_at` on the deployment event, and the events you sent carry neither. An empty result here means "no input", not "zero hours".

#### Change Failure Rate
```promql
# A ratio, 0.0 to 1.0, despite the "_pct" name
dora_cfr_pct

# As a percentage
dora_cfr_pct * 100
```

#### Failed Deployment Recovery Time (FDRT)
```promql
# Median hours from a failed deployment to the next success of the same repo
dora_fdrt_p50_hours

# In minutes
dora_fdrt_p50_hours * 60
```

#### Deployment Rework Rate
```promql
# A ratio, 0.0 to 1.0, despite the "_pct" name
dora_rework_rate_pct * 100
```

> ✅ **Checkpoint**: Four of the five metrics return a value, and you can say why lead time does not.

---

## Step 4 — Build Grafana DORA Dashboard (15 minutes)

### 4.1 Create a New Dashboard

1. In Grafana (**http://localhost:3000**), click **+** → **Dashboard** → **Add visualization**
2. Select the **Prometheus** datasource

### 4.2 Build the Executive Summary Row

Create 4 stat panels in a row. Each query is the gauge from Step 3, so there is nothing to aggregate:

| Panel | Title | Query | Type | Thresholds |
|-------|-------|-------|------|------------|
| 1 | Deployment Frequency (per week) | `dora_deployment_frequency_per_week` | Stat | Red: <1, Yellow: ≥1, Green: ≥7 |
| 2 | Change Failure Rate | `dora_cfr_pct * 100` (unit: percent) | Gauge | Green: <15, Yellow: <30, Red: ≥30 |
| 3 | Recovery Time (FDRT p50, minutes) | `dora_fdrt_p50_hours * 60` | Stat | Green: <60, Yellow: <240, Red: ≥240 |
| 4 | Rework Rate | `dora_rework_rate_pct * 100` (unit: percent) | Gauge | Green: <10, Yellow: <25, Red: ≥25 |

Add a fifth panel for Lead Time (`dora_lead_time_p95_hours`) if you like. It shows "No data" until events carry `first_commit_at`; leave it there on purpose, so the dashboard says so instead of hiding the gap.

### 4.3 Add Trend Panels

Add a time series panel for each of the same queries. Because each metric is a gauge, the trend is the same query drawn over time. After the Step 5 events you will see CFR and Rework Rate step up.

### 4.4 Save Dashboard

1. Click **Save dashboard**
2. Name: **"DORA Metrics - Platform Performance"**
3. Tags: `dora`, `metrics`, `platform`

> ✅ **Checkpoint**: Dashboard saved with a panel for each DORA metric that has data.

---

## Step 5 — Test Failure/Recovery Scenarios (10 minutes)

### 5.1 Test Change Failure Rate Increase

```bash
# Send 3 failed deployments
for i in 1 2 3; do
  curl -s -w "  HTTP %{http_code}\n" -X POST http://localhost:8088/event \
    -H "Content-Type: application/json" \
    -d '{
      "schema_version": "1.0",
      "event_type": "deployment",
      "repo": "your-name/dojo-lab",
      "service": "chaos-service-'"$i"'",
      "environment": "production",
      "commit_sha": "'"$(printf '%040d' "$((1410 + i))")"'",
      "deployed_at": "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'",
      "status": "failed",
      "pipeline_url": "https://example.com/ci/'"$((1410 + i))"'"
    }'
  sleep 1
done

# Trigger computation
cd ~/dojo-labs/uFawkesObs
docker compose restart dora-api
sleep 10
```

### 5.2 Verify CFR Increase

1. In Grafana dashboard, observe **Change Failure Rate** gauge
2. Should show a higher CFR than before (three more failures)

### 5.2 Test Deployment Rework Rate

```bash
# A second hotfix deployment, and the rework event for it
curl -s -w "  HTTP %{http_code}\n" -X POST http://localhost:8088/event \
  -H "Content-Type: application/json" \
  -d '{
    "schema_version": "1.0",
    "event_type": "deployment",
    "repo": "your-name/dojo-lab",
    "service": "hotfix-service",
    "environment": "production",
    "commit_sha": "'"$(printf '%040d' 1414)"'",
    "deployed_at": "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'",
    "status": "success",
    "pipeline_url": "https://example.com/ci/1414"
  }'
curl -s -w "  HTTP %{http_code}\n" -X POST http://localhost:8088/event \
  -H "Content-Type: application/json" \
  -d '{
    "schema_version": "1.0",
    "event_type": "rework",
    "repo": "your-name/dojo-lab",
    "deployment_sha": "'"$(printf '%040d' 1414)"'",
    "rework_type": "hotfix",
    "triggered_at": "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'",
    "user_visible": true
  }'

# Trigger computation
cd ~/dojo-labs/uFawkesObs
docker compose restart dora-api
sleep 10
```

### 5.3 Verify Rework Rate

1. In Grafana, observe **Deployment Rework Rate** gauge
2. Should show a higher Rework Rate than before

> ✅ **Checkpoint**: Failure and rework scenarios tested, metrics updated.

---

## Step 6 — Configure DORA Alerting (10 minutes)

The stack already ships DORA alerts (`ufawkesobs_dora_alerts`, thirty-day windows). Open **http://localhost:9090/alerts** and find them first. They watch the 30-day recording rules and wait days (`for: 7d`) before firing, which is right for production and useless in a lab. Here you add your own, short-window set on the live gauges.

### 6.1 Create the Alert Rules File

Rules go in the stack's rules directory, which Prometheus mounts read-only:

```bash
cat > ~/dojo-labs/uFawkesObs/config/prometheus/rules/dojo-dora-alerts.yml <<'EOF'
groups:
  - name: dojo-dora-alerts
    interval: 60s
    rules:
      - alert: DojoDeploymentFrequencyLow
        expr: dora_deployment_frequency_per_week < 7
        for: 1h
        labels:
          severity: warning
        annotations:
          summary: "Deployment frequency below one per day"
          description: "{{ $labels.team_id }} deploys {{ $value | printf \"%.1f\" }} times a week"

      - alert: DojoLeadTimeHigh
        expr: dora_lead_time_p95_hours > 4
        for: 30m
        labels:
          severity: warning
        annotations:
          summary: "P95 lead time exceeds 4 hours"
          description: "{{ $labels.team_id }} P95 lead time is {{ $value | printf \"%.1f\" }} hours"

      - alert: DojoChangeFailureRateHigh
        expr: dora_cfr_pct > 0.15
        for: 30m
        labels:
          severity: critical
        annotations:
          summary: "Change failure rate exceeds 15%"
          description: "{{ $labels.team_id }} CFR is {{ $value | humanizePercentage }}"

      - alert: DojoRecoveryTimeHigh
        expr: dora_fdrt_p50_hours > 1
        for: 30m
        labels:
          severity: warning
        annotations:
          summary: "Median recovery time exceeds 1 hour"
          description: "{{ $labels.team_id }} median FDRT is {{ $value | printf \"%.2f\" }} hours"

      - alert: DojoReworkRateHigh
        expr: dora_rework_rate_pct > 0.25
        for: 1h
        labels:
          severity: warning
        annotations:
          summary: "Rework rate exceeds 25%"
          description: "{{ $labels.team_id }} rework rate is {{ $value | humanizePercentage }}"
EOF
```

### 6.2 Apply the Alert Rules

Prometheus loads only the files named under `rule_files`, so a file dropped into the directory does nothing until you list it:

```bash
cd ~/dojo-labs/uFawkesObs

# Add the file to rule_files, after the dora-regression entry
sed -i.bak 's#^  - "/etc/prometheus/rules/ufawkesobs-dora-regression.yml"#&\n  - "/etc/prometheus/rules/dojo-dora-alerts.yml"#' config/prometheus/prometheus.yaml

# Check the rules, then reload
docker compose exec -T prometheus promtool check rules /etc/prometheus/rules/dojo-dora-alerts.yml
curl -s -o /dev/null -w "reload HTTP %{http_code}\n" -X POST http://localhost:9090/-/reload
```

**Expected**: `SUCCESS: 5 rules found` and `reload HTTP 200`. Delete `prometheus.yaml.bak` afterwards.

### 6.3 Verify Alert Rules

1. Open **http://localhost:9090/alerts** (Prometheus Alerts page)
2. Verify the `dojo-dora-alerts` group appears with 5 rules. With the Step 5 events sent, `DojoChangeFailureRateHigh` and `DojoDeploymentFrequencyLow` read **pending** (the condition is true, the `for:` wait has not run out). The other three read **inactive**; lead time stays inactive because it has no data, and no data means no alert.
3. Check **http://localhost:9093** (Alertmanager) → Alerts tab. It stays empty until a rule leaves *pending* and fires.

> ✅ **Checkpoint**: DORA alert rules loaded and visible.

---

## Step 7 — Run the Validation Script

```bash
# From your uFawkesDojo checkout
cd /path/to/uFawkesDojo
bash brown-belt/module-14-dora-deep-dive/lab-01/validate.sh
```

**Expected output** (the `[INFO]` lines and the per-item lines under each check are trimmed; all 9 checks pass):

```
[✓] Prerequisites: curl, jq, git, make installed
[✓] uFawkesObs Stack: All 9 services healthy (8 core + DORA API)
[✓] DORA API: API reachable at http://localhost:8088/health
[✓] DORA Event Ingestion: Event accepted by dora-api (HTTP 201)
[✓] DORA Metrics Query: All 5 DORA metrics queryable via PromQL
[✓] Grafana DORA Dashboard: Found 2 DORA dashboard(s)
[✓] DORA Alert Rules: Found 32 DORA alert rules
[✓] Event Ingestion → Metrics: Event ingested and reflected in metrics
[✓] DORA PromQL Queries: All DORA PromQL queries successful

==========================================
Brown Belt Module 14 Lab 01 — Results
==========================================
Total Tests : 9
Passed      : 9
Failed      : 0

[✓] All tests passed! ✅
```

What this does not check: the 2 dashboards and 32 alert rules it finds are the ones uFawkesObs provisions, not yours from Steps 4 and 6. Its PromQL checks pass when Prometheus answers, even for a metric name that returns no series. So a pass here says the stack and the event path work, not that you finished every step.

---

## Clean Up

```bash
# Stop the stack and remove its volumes (the profiles matter: plain `make down` leaves it running)
cd ~/dojo-labs/uFawkesObs
docker compose --profile '*' down -v --remove-orphans
```

`make down` does not stop this stack at this version ([uFawkesObs#617](https://github.com/paruff/uFawkesObs/issues/617)).

---

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| DORA API not responding | dora-api not running | `make up-dora` |
| No metrics in Prometheus | dora-api has not computed since your events (it computes at start, then hourly by default) | `docker compose restart dora-api` |
| An event returns `HTTP 422` | It does not match schema 1.0 (a missing field, an extra field, or a short `commit_sha`) | Compare it with Step 2.1; the response body names the field |
| Grafana dashboard empty | No data in Prometheus | Restart dora-api (Step 2.5), then check the scrape config |
| Alert rules not loading | Syntax error | `promtool check config /etc/prometheus/prometheus.yml` |

---

## Retrieval Check (Answer Without Looking Back)

Write your answers down — the act of writing (not just thinking) strengthens retention.

1. What are the 5 DORA metrics and their Elite benchmarks?
2. How does uFawkesObs collect deployment events?
3. Where are the DORA metrics computed?
4. How do you enable the DORA profile in uFawkesObs?
5. What PromQL query gives you Deployment Frequency per day?

(Suggested answers: 1 = DF/Lead Time/CFR/MTTR/Rework Rate with Elite benchmarks; 2 = POST to dora-api/event; 3 = inside `dora-api`, which aggregates events into DORA metrics and serves them on `/metrics`; 4 = `make up-dora`; 5 = `sum(rate(dora_deployment_frequency[7d])) * 86400`)

---

## Reference: What You Built

| Component | Purpose |
|-----------|---------|
| `dora-api` | Receives deployment and rework events, stores them in SQLite, computes the DORA metrics and serves them on `/metrics` |
| `Prometheus` | Stores time-series, PromQL queries |
| `Grafana` | DORA dashboards, visualization |
| `Alertmanager` | Alert routing from DORA metrics |

You've now built a complete DORA metrics pipeline with uFawkesObs — from event ingestion to executive dashboards. This is the foundation for data-driven platform improvement!

---

## Retrieval Check Answers

1. **5 DORA metrics + Elite**: DF (multiple/day), LT (<1hr), CFR (0-15%), MTTR (<1hr), Rework Rate (lower better)
2. **Event collection**: POST to `dora-api` at `http://localhost:8088/event` with deployment event JSON
3. **Where metrics are computed**: in `dora-api`, from the events in SQLite, served on `/metrics`
4. **Enable DORA**: `make up-dora` (starts the core stack plus `dora-api`)
5. **DF query**: `sum(rate(dora_deployment_frequency[7d])) * 86400`

---

➡️ **Next**: Return to [Module 14 README](../README.md), then prepare for the **Brown Belt Assessment**!
