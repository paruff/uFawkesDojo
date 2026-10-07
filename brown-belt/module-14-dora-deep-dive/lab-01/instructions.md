# Lab 01: DORA Metrics Deep Dive with uFawkesObs

**Module**: Brown Belt — Module 14: DORA Metrics Deep Dive
**Estimated Time**: 60 minutes
**Difficulty**: Advanced (Module 13 complete required)
**Runs against**: [uFawkesObs `v1.1.0-rc.1`](https://github.com/paruff/uFawkesObs/releases/tag/v1.1.0-rc.1) — a **pre-release**, the same checkout as Module 13 — with the DORA profile

> **Partly run for real.** Steps 1, 2, 5 and 7, the prerequisite check and the clean-up were run verbatim against `v1.1.0-rc.1` on 2026-10-07, and their expected output is what they printed. Steps 3, 4 and 6 (PromQL, the Grafana dashboard and the alert rules) were not run, and still use metric names from before uFawkesObs 1.0. The stack serves `dora_deployment_frequency_per_week`, `dora_lead_time_p50_hours`, `dora_lead_time_p95_hours`, `dora_fdrt_p50_hours`, `dora_cfr_pct` and `dora_rework_rate_pct`, all gauges. Rewriting those steps is [#43](https://github.com/paruff/uFawkesDojo/issues/43). See the [audit](../../../docs/ai-sdlc/compose-curriculum/audit-2026-10-06.md).

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

Open **http://localhost:9090** (Prometheus UI)

### 3.2 Query Each DORA Metric

Test these PromQL queries in Prometheus Graph tab:

#### Deployment Frequency
```promql
# Deployments per day (last 7 days)
sum(increase(dora_deployment_frequency[7d])) / 7
```

#### Lead Time for Changes
```promql
# Average lead time (seconds)
avg(dora_lead_time_seconds)

# P95 lead time (hours)
histogram_quantile(0.95, rate(dora_lead_time_seconds_bucket[7d])) / 3600
```

#### Change Failure Rate
```promql
# Change Failure Rate (%)
dora_change_failure_rate * 100
```

#### Mean Time to Restore (MTTR)
```promql
# Average MTTR (minutes)
avg(dora_mttr_seconds) / 60

# P95 MTTR (minutes)
histogram_quantile(0.95, rate(dora_mttr_seconds_bucket[7d])) / 60
```

#### Deployment Rework Rate
```promql
# Rework rate (%)
dora_rework_rate * 100
```

> ✅ **Checkpoint**: All 5 DORA metrics return values in Prometheus.

---

## Step 4 — Build Grafana DORA Dashboard (15 minutes)

### 4.1 Create a New Dashboard

1. In Grafana (**http://localhost:3000**), click **+** → **Dashboard** → **Add visualization**
2. Select **Prometheus** datasource

### 4.2 Build the Executive Summary Row

Create 5 stat panels in a row:

| Panel | Title | Query | Type | Thresholds |
|-------|-------|-------|------|------------|
| 1 | Deployment Frequency | `sum(rate(dora_deployment_frequency[7d])) * 86400` | Stat | Green: >1/day, Yellow: >0.1/day, Red: ≤0.1 |
| 2 | Lead Time (P95) | `histogram_quantile(0.95, rate(dora_lead_time_seconds_bucket[7d])) / 3600` | Stat | Green: <1h, Yellow: <4h, Red: >4h |
| 3 | Change Failure Rate | `dora_change_failure_rate * 100` | Gauge | Green: <15%, Yellow: <30%, Red: >30% |
| 4 | MTTR (Avg) | `avg(dora_mttr_seconds) / 60` | Stat | Green: <60m, Yellow: <240m, Red: >240m |
| 5 | Rework Rate | `dora_rework_rate * 100` | Gauge | Green: <10%, Yellow: <25%, Red: >25% |

### 4.3 Add Trend Panels

Add time series panels below the stat row:

| Panel | Title | Query | Type |
|-------|-------|-------|------|
| 1 | Deployment Frequency Trend | `sum(rate(dora_deployment_frequency[1d])) * 86400` | Time Series |
| 2 | Lead Time Trend (P50/P95) | `histogram_quantile(0.50, rate(dora_lead_time_seconds_bucket[1d])) / 3600` + P95 | Time Series |
| 3 | CFR Trend | `dora_change_failure_rate * 100` | Time Series |
| 3 | MTTR Trend | `avg(dora_mttr_seconds) / 60` | Time Series |

### 4.3 Add Distribution Panels

Add heatmap/histogram panels:

| Panel | Title | Query | Type |
|-------|-------|-------|------|
| 1 | Lead Time Distribution | `sum(rate(dora_lead_time_seconds_bucket[7d])) by (le)` | Heatmap |
| 2 | MTTR Distribution | `sum(rate(dora_mttr_seconds_bucket[7d])) by (le)` | Heatmap |

### 4.3 Save Dashboard

1. Click **Save dashboard**
2. Name: **"DORA Metrics - Platform Performance"**
3. Tags: `dora`, `metrics`, `platform`

> ✅ **Checkpoint**: Dashboard created with all 5 DORA metrics visible.

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
2. Should show increased CFR (was ~0%, now >0%)

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
2. Should show >0% (was 0%, now >0%)

> ✅ **Checkpoint**: Failure and rework scenarios tested, metrics updated.

---

## Step 6 — Configure DORA Alerting (10 minutes)

### 6.1 Create DORA Alert Rules

Create alert rule file:

```bash
cat > ~/dojo-labs/dora-alerts.yml <<'EOF'
groups:
  - name: dora-alerts
    interval: 60s
    rules:
      - alert: HighDeploymentFrequency
        expr: sum(rate(dora_deployment_frequency[1d])) * 86400 < 1
        for: 1h
        labels:
          severity: warning
        annotations:
          summary: "Deployment frequency dropped below 1/day"
          description: "Current DF: {{ $value }}/day — below elite threshold"

      - alert: HighLeadTime
        expr: histogram_quantile(0.95, rate(dora_lead_time_seconds_bucket[1h])) / 3600 > 4
        for: 30m
        labels:
          severity: warning
        annotations:
          summary: "P95 Lead Time exceeds 4 hours"
          description: "P95 lead time is {{ $value | printf \"%.1f\" }} hours"

      - alert: HighChangeFailureRate
        expr: dora_change_failure_rate > 0.15
        for: 30m
        labels:
          severity: critical
        annotations:
          summary: "Change Failure Rate exceeds 15%"
          description: "CFR is {{ $value | printf \"%.1f\" }}% — above elite threshold (15%)"

      - alert: HighMTTR
        expr: avg(dora_mttr_seconds) / 60 > 60
        for: 30m
        labels:
          severity: warning
        annotations:
          summary: "MTTR exceeds 60 minutes"
          description: "Average MTTR is {{ $value | printf \"%.1f\" }} minutes"

      - alert: HighReworkRate
        expr: dora_rework_rate > 0.25
        for: 1h
        labels:
          severity: warning
        annotations:
          summary: "Deployment Rework Rate exceeds 25%"
          description: "Rework rate is {{ $value | printf \"%.1f\" }}%"
EOF
```

### 6.2 Apply Alert Rules

```bash
# Copy to Prometheus rules directory
cp ~/dojo-labs/dora-alerts.yml ~/dojo-labs/uFawkesObs/config/prometheus/rules/dora-alerts.yml

# Reload Prometheus
curl -X POST http://localhost:9090/-/reload
```

### 6.3 Verify Alert Rules

1. Open **http://localhost:9090/alerts** (Prometheus Alerts page)
2. Verify `dora-alerts` group appears with 5 rules
3. Check **http://localhost:9093** (Alertmanager) → Alerts tab

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
