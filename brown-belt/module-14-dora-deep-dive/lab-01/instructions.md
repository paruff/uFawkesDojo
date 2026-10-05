# Lab 01: DORA Metrics Deep Dive with uFawkesObs

**Module**: Brown Belt — Module 14: DORA Metrics Deep Dive
**Estimated Time**: 60 minutes
**Difficulty**: Advanced (Module 13 complete required)
**Runs against**: [uFawkesObs v1.0.0](https://github.com/paruff/uFawkesObs/releases/tag/v1.0.0) with DORA profile

---

## Objectives

By the end of this lab you will have:

1. Verified uFawkesObs DORA profile is running (dora-api, dora-compute, pushgateway)
2. Sent test deployment events to dora-api
3. Queried all 5 DORA metrics via PromQL in Grafana
4. Built a complete DORA dashboard in Grafana with all 5 metrics
5. Tested failure/recovery scenarios and observed metric changes
6. Configured DORA-specific alerting rules

---

## Why This Lab Uses uFawkesObs DORA Profile

This lab runs against **uFawkesObs v1.0.0** with the **DORA profile** (`make up-dora`) because it provides a complete, self-contained DORA metrics platform in Docker Compose:

- **dora-api** (port 8088) — Receives deployment events, stores in SQLite
- **dora-compute** — Aggregates events → DORA metrics, exposes Prometheus metrics
- **pushgateway** (port 9091) — Receives metrics from short-lived jobs
- **Prometheus** (port 9090) — Stores time-series, PromQL queries
- **Grafana** (port 3000) — Dashboards, visualization
- **Alloy** — Log collection
- **OTel Collector** — Telemetry ingestion (OTLP)
- **Tempo** — Distributed tracing
- **Loki** — Log aggregation

No Kubernetes required — runs entirely in Docker Compose on your laptop.

---

## Prerequisites

**Required**: uFawkesObs v1.0.0 running locally **with DORA profile enabled**

```bash
# Verify your stack is running with DORA profile
cd ~/dojo-labs/uFawkesObs
make status
```

**Expected**: All services healthy including DORA services:
```
NAME               STATUS
prometheus         healthy
grafana            healthy
loki               healthy
tempo              healthy
alertmanager       healthy
alloy              healthy
otel-collector     healthy
node-exporter      healthy
dora-api           healthy
dora-compute       healthy
pushgateway        healthy
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

**Expected**: All services healthy including `dora-api`, `dora-compute`, `pushgateway`

### 1.2 Verify DORA API Health

```bash
# Check DORA API health endpoint
curl -s http://localhost:8088/health
```

**Expected**: `{"status":"ok"}` or similar healthy response

### 1.3 Verify Pushgateway

```bash
# Check Pushgateway is accessible
curl -s http://localhost:9091/metrics | head -20
```

**Expected**: Prometheus metrics output including pushgateway metadata

> ✅ **Checkpoint**: All DORA profile services are running and accessible.

---

## Step 2 — Send Test Deployment Events (10 minutes)

### 2.1 Send a Successful Deployment Event

```bash
# Send a successful deployment event
curl -s -X POST http://localhost:8088/event \
  -H "Content-Type: application/json" \
  -d '{
    "event_type": "deployment",
    "service": "test-service",
    "environment": "production",
    "status": "success",
    "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",
    "commit_sha": "abc123def456",
    "deployed_by": "lab-user",
    "work_type": "feature"
  }'
```

**Expected**: JSON response with event ID or success confirmation.

### 2.2 Send Multiple Events

```bash
# Send a few more events to build up data
for i in {1..5}; do
  curl -s -X POST http://localhost:8088/event \
    -H "Content-Type: application/json" \
    -d '{
      "event_type": "deployment",
      "service": "test-service-'$i'",
      "environment": "production",
      "status": "success",
      "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",
      "commit_sha": "abc123def456",
      "deployed_by": "lab-user",
      "work_type": "feature"
    }'
  sleep 1
done
```

### 2.3 Send a Failed Deployment Event

```bash
# Send a failed deployment event
curl -s -X POST http://localhost:8088/event \
  -H "Content-Type: application/json" \
  -d '{
    "event_type": "deployment",
    "service": "failing-service",
    "environment": "production",
    "status": "failed",
    "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",
    "commit_sha": "fedcba987654",
    "deployed_by": "lab-user",
    "work_type": "feature"
  }'
```

### 2.4 Send an Incident Rework Event

```bash
# Send an incident-driven deployment (rework)
curl -s -X POST http://localhost:8088/event \
  -H "Content-Type: application/json" \
  -d '{
    "event_type": "deployment",
    "service": "hotfix-service",
    "environment": "production",
    "status": "success",
    "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",
    "commit_sha": "hotfix123",
    "deployed_by": "lab-user",
    "work_type": "incident_rework"
  }'
```

### 2.5 Trigger DORA Computation

```bash
# Trigger dora-compute to process events
docker compose restart dora-compute

# Wait for computation
sleep 10
```

> ✅ **Checkpoint**: Events sent, dora-compute restarted, metrics should be available.

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
for i in {1..3}; do
  curl -s -X POST http://localhost:8088/event \
    -H "Content-Type: application/json" \
    -d '{
      "event_type": "deployment",
      "service": "chaos-service-'$i'",
      "environment": "production",
      "status": "failed",
      "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",
      "commit_sha": "fail'$i'",
      "deployed_by": "chaos-user",
      "work_type": "feature"
    }'
  sleep 1
done

# Trigger computation
docker compose restart dora-compute
sleep 10
```

### 5.2 Verify CFR Increase

1. In Grafana dashboard, observe **Change Failure Rate** gauge
2. Should show increased CFR (was ~0%, now >0%)

### 5.2 Test Deployment Rework Rate

```bash
# Send incident-driven deployment (rework)
curl -s -X POST http://localhost:8088/event \
  -H "Content-Type: application/json" \
  -d '{
    "event_type": "deployment",
    "service": "hotfix-service",
    "environment": "production",
    "status": "success",
    "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",
    "commit_sha": "hotfix123",
    "deployed_by": "lab-user",
    "work_type": "incident_rework"
  }'

# Trigger computation
docker compose restart dora-compute
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

**Expected output** (all checks pass):

```
[INFO] Starting Brown Belt Module 14 Lab 01 validation...

[✓] Prerequisites: curl, jq, git, make installed
[✓] uFawkesObs Stack: all 11 services healthy (including DORA services)
[✓] DORA API: Reachable and healthy
[✓] Prometheus Metrics: All 5 DORA metrics queryable
[✓] Grafana Dashboard: DORA dashboard exists with 5+ panels
[✓] Event Ingestion: Test events accepted by dora-api
[✓] Metric Computation: All 5 DORA metrics queryable via PromQL
[✓] Alerting: DORA alert rules loaded in Prometheus
[✓] Dashboard: DORA dashboard exists with 5+ panels

==========================================
Total Tests: 9
Passed: 9
Failed: 0

[✓] All tests passed! ✅

🎉 Congratulations! You've completed Brown Belt Module 14 Lab 01.
   You've built a complete DORA metrics pipeline with uFawkesObs.
   You're ready for the Brown Belt Assessment!
```

---

## Clean Up

```bash
# Stop the stack (optional)
cd ~/dojo-labs/uFawkesObs
make down

# Remove data (optional)
docker compose down -v
rm -rf data/
make init
```

---

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| DORA API not responding | dora-api not running | `make up-dora` |
| No metrics in Prometheus | dora-compute not running | `docker compose restart dora-compute` |
| No events in dora-api | Event format invalid | Check JSON schema, check dora-api logs |
| Grafana dashboard empty | No data in Prometheus | Wait for dora-compute, check scrape config |
| Alert rules not loading | Syntax error | `promtool check config /etc/prometheus/prometheus.yml` |

---

## Retrieval Check (Answer Without Looking Back)

Write your answers down — the act of writing (not just thinking) strengthens retention.

1. What are the 5 DORA metrics and their Elite benchmarks?
2. How does uFawkesObs collect deployment events?
3. What does `dora-compute` do?
4. How do you enable the DORA profile in uFawkesObs?
5. What PromQL query gives you Deployment Frequency per day?

(Suggested answers: 1 = DF/Lead Time/CFR/MTTR/Rework Rate with Elite benchmarks; 2 = POST to dora-api/event; 3 = Aggregates events → DORA metrics, exposes Prometheus metrics; 4 = `make up-dora`; 5 = `sum(rate(dora_deployment_frequency[7d])) * 86400`)

---

## Reference: What You Built

| Component | Purpose |
|-----------|---------|
| `dora-api` | Receives deployment events, stores in SQLite |
| `dora-compute` | Aggregates events → DORA metrics, exposes Prometheus metrics |
| `pushgateway` | Receives metrics from short-lived jobs |
| `Prometheus` | Stores time-series, PromQL queries |
| `Grafana` | DORA dashboards, visualization |
| `Alertmanager` | Alert routing from DORA metrics |

You've now built a complete DORA metrics pipeline with uFawkesObs — from event ingestion to executive dashboards. This is the foundation for data-driven platform improvement!

---

## Retrieval Check Answers

1. **5 DORA metrics + Elite**: DF (multiple/day), LT (<1hr), CFR (0-15%), MTTR (<1hr), Rework Rate (lower better)
2. **Event collection**: POST to `dora-api` at `http://localhost:8088/event` with deployment event JSON
3. **dora-compute**: Aggregates events from SQLite → computes DORA metrics → exposes Prometheus metrics
4. **Enable DORA**: `make up-dora` (starts dora-api, dora-compute, pushgateway)
5. **DF query**: `sum(rate(dora_deployment_frequency[7d])) * 86400`

---

➡️ **Next**: Return to [Module 14 README](../README.md), then prepare for the **Brown Belt Assessment**!
