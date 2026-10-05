# Lab 01: Full Incident Response Simulation with uFawkesObs

**Module**: Brown Belt — Module 16: Advanced Incident Management
**Estimated Time**: 45 minutes
**Difficulty**: Advanced (Modules 13-15 complete required)
**Runs against**: [uFawkesObs v1.0.0](https://github.com/paruff/uFawkesObs/releases/tag/v1.0.0) (Docker Compose)

---

## Objectives

By the end of this lab you will have:

1. Detected and triaged an incident using uFawkesObs alerting
2. Investigated root cause using Loki (logs), Tempo (traces), Prometheus (metrics)
3. Mitigated the incident by applying a fix
4. Verified resolution through uFawkesObs observability stack
5. Documented a blameless postmortem using uFawkesObs data
6. Practiced incident command roles and communication

---

## Why This Lab Uses uFawkesObs

This lab runs against **uFawkesObs v1.0.0** — the Observability plane of the uFawkes suite — because it provides a complete incident management platform in Docker Compose:

- **Grafana** — War room dashboard, real-time metrics, alerting UI
- **Prometheus** — Metrics storage, PromQL queries, alerting rules
- **Loki** — Log aggregation, LogQL queries, log-based alerts
- **Tempo** — Distributed tracing, TraceQL queries
- **Alertmanager** — Alert routing, silencing, notification routing
- **Alloy** — Log/metric collection (replaces Promtail)
- **OTel Collector** — Telemetry ingestion (OTLP)

No Kubernetes required — runs entirely in Docker Compose on your laptop.

---

## Prerequisites

**Required**: uFawkesObs v1.0.0 running locally with full stack

```bash
# Verify your stack is running
cd ~/dojo-labs/uFawkesObs
make status
```

**Expected**: All services healthy (prometheus, grafana, loki, tempo, alertmanager, alloy, otel-collector, node-exporter)

**Required**: Modules 13, 14, 15 completed (understand observability pipeline, DORA metrics, SLI/SLO)

**Tools required** (already installed from previous modules):
- `curl` — HTTP client
- `jq` — JSON processor
- `git` — version control
- `make` — build automation
- `docker` / `docker compose` — container orchestration

---

## Step 0 — Read the Theory First (if you haven't)

This lab assumes you've read the [Module 16 theory](../README.md#theory--concepts-20-minutes) up through "Incident Command System (ICS)". You should be able to name the incident lifecycle phases, ICS roles, and RCA methods.

---

## Step 1 — Detect & Triage (5 minutes)

### 1.1 Trigger an Incident

We'll simulate a SEV1 incident by sending a test alert through Alertmanager.

```bash
# Send a test alert to Alertmanager
curl -s -X POST http://localhost:9093/api/v2/alerts \
  -H "Content-Type: application/json" \
  -d '[{
    "labels": {
      "alertname": "HighErrorRate",
      "severity": "sev1",
      "service": "checkout-api",
      "instance": "checkout-api-1",
      "job": "checkout-api"
    },
    "annotations": {
      "summary": "High error rate on checkout-api",
      "description": "Error rate is 25% (threshold: 5%)",
      "runbook": "https://runbooks.company.com/high-error-rate"
    },
    "generatorURL": "http://prometheus:9090/graph?g0.expr=rate(http_requests_total%7Bstatus%3D~%225..%22%5D%5B5m%5D%29+%2F+rate(http_requests_total%5B5m%5D)%3E0.05"
  }]'
```

### 1.2 Observe Alert in Alertmanager

1. Open **http://localhost:9093** (Alertmanager UI)
2. Verify the `HighErrorRate` alert is firing
3. Note the `service: checkout-api` and `severity: sev1` labels

> ✅ **Checkpoint**: Alert is firing in Alertmanager with severity=sev1

### 1.3 Observe in Grafana

1. Open **http://localhost:3000** (Grafana)
2. Navigate to **Alerting** → **Alert rules**
3. Verify the `HighErrorRate` rule is firing
3. Check the **Alerting** dashboard for active alerts

> ✅ **Checkpoint**: Alert visible in both Alertmanager and Grafana

---

## Step 2 — Triage & Incident Command (5 minutes)

### 2.1 Assume Incident Commander Role

In a real incident, you'd:
1. Acknowledge the alert in Alertmanager
2. Create a war room channel (e.g., `#incident-2025-10-12-checkout`)
3. Assemble the team (TL, Comms, Scribe)

For this lab, simulate the role assignment:

```bash
# Record your role assignments
cat > ~/dojo-labs/incident-roles.md <<'EOF'
# Incident: HighErrorRate on checkout-api
# Started: $(date -u +%Y-%m-%dT%H:%M:%SZ) UTC

Incident Commander: @you
Technical Lead: @yourself
Communications Lead: @yourself
Scribe: @yourself
EOF
```

> ✅ **Checkpoint**: War room "created", roles assigned

---

## Step 3 — Investigation (15 minutes)

### 3.1 Examine Logs in Loki

**Open Grafana Explore → Loki**

Run these LogQL queries to investigate:

#### 3.1.1 Check error logs for the affected service

```logql
{service="checkout-api"} |= "ERROR" | json | level="error"
```

**What to look for**: Error patterns, stack traces, timestamps

#### 3.1.2 Find error rate spike

```logql
sum(rate({service="checkout-api"} |= "ERROR" [5m]))
/
sum(rate({service="checkout-api"}[5m]))
```

**Expected**: Value > 0.05 (5% error rate)

#### 3.1.3 Find specific error messages

```logql
{service="checkout-api"} | json | level="error" | line_format "{{.timestamp}} {{.message}}"
```

> ✅ **Checkpoint**: Identified error patterns in Loki (e.g., database connection timeouts)

### 3.2 Explore Traces in Tempo

**Open Grafana Explore → Tempo**

### 3.2.1 Search for failed traces

```traceql
{service.name="checkout-api"} && {span.status="error"} | limit 20
```

### 3.2.2 Examine a failed trace

1. Click on a trace with `status=error`
2. Examine the **span timeline** - look for:
   - Long duration spans (> 1s)
   - Spans with `error=true`
   - Database calls with errors
   - Downstream service calls failing

### 3.2.3 TraceQL query for errors

```traceql
{service.name="checkout-api"} && {span.status="error"} | count() by (span.name)
```

> ✅ **Checkpoint**: Identified failing spans (e.g., database query timeouts)

### 3.3 Correlate Metrics in Prometheus

**Open Grafana Explore → Prometheus**

```promql
# Error rate for checkout-api
sum(rate(http_requests_total{service="checkout-api",status=~"5.."}[5m]))
/
sum(rate(http_requests_total{service="checkout-api"}[5m]))

# Latency spike
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{service="checkout-api"}[5m]))

# Database connection pool
max(pg_stat_activity_count{service="checkout-api"})
```

> ✅ **Checkpoint**: Correlated logs (errors), traces (spans), metrics (error rate, latency)

---

## Step 4 — Mitigation & Resolution (10 minutes)

### 4.1 Identify Root Cause

Based on investigation, you determine:
- **Root cause**: Database connection pool exhausted (max 20 connections, 50 concurrent requests)
- **Evidence**:
  - Loki: "connection pool exhausted" errors
  - Tempo: Spans showing "connection pool exhausted" errors
  - Prometheus: `pg_pool_used / pg_pool_max = 1.0`

### 4.2 Execute Mitigation

In a real incident, you'd scale the connection pool. For this lab, simulate the fix:

```bash
# Simulate the fix by updating a config (in real life: ConfigMap update + rollout)
cat > ~/dojo-labs/mitigation.yml <<'EOF'
# Mitigation: Increase database connection pool from 20 to 100
# File: config/checkout-api.yaml
# Change:
#   pool_size: 20
# To:
#   pool_size: 100
EOF

# Simulate applying the fix (in real life: ConfigMap update + rollout restart)
echo "Mitigation applied: connection_pool_size 20 -> 100"
echo "Rolling restart initiated..."

# Wait for rollout (simulated)
sleep 5
echo "Rollout complete"
```

### 4.3 Verify Resolution

```bash
# Verify error rate drops
curl -s "http://localhost:9090/api/v1/query?query=sum(rate(http_requests_total{service=\"checkout-api\",status=~\"5..\"}[5m]))/sum(rate(http_requests_total{service=\"checkout-api\"}[5m]))" | jq '.data.result[0].value[1]'

# Check latency recovery
curl -s "http://localhost:9090/api/v1/query?query=histogram_quantile(0.95,rate(http_request_duration_seconds_bucket{service=\"checkout-api\"}[5m]))" | jq '.data.result[0].value[1]'
```

> ✅ **Checkpoint**: Error rate < 1%, latency back to normal

---

## Step 5 — Postmortem (5 minutes)

### 5.1 Create Postmortem Document

Using the uFawkesObs blameless postmortem template:

```bash
cat > ~/dojo-labs/postmortem-$(date -u +%Y%m%d).md <<'EOF'
# Postmortem: Checkout API High Error Rate

**Date**: $(date -u +%Y-%m-%d)
**Duration**: 23 minutes
**Severity**: SEV1
**Impact**: 15% of checkout requests failed (500 errors)

## Timeline

| Time (UTC) | Event |
|------------|-------|
| 14:22 UTC | Alert fired: HighErrorRate on checkout-api (25% error rate) |
| 14:23 UTC | Alert acknowledged, war room created |
| 14:24 UTC | IC assigned, war room created |
| 14:25 UTC | Investigation started (Loki, Tempo, Prometheus) |
| 14:30 UTC | Root cause identified: DB connection pool exhausted |
| 14:32 UTC | Mitigation: Increase DB connection pool from 20 to 100 |
| 14:35 UTC | ConfigMap updated, rollout initiated |
| 14:38 UTC | Error rate dropping |
| 14:40 UTC | Error rate < 1%, latency normal |
| 14:45 UTC | Incident resolved |

## Root Cause

**Primary**: Database connection pool exhausted (pool=20, peak=50 concurrent requests)

**Contributing Factors**:
1. No connection pool monitoring/alerting
2. No auto-scaling for connection pool
3. Load test didn't simulate peak traffic
4. Connection pool size not reviewed in 6 months

## Root Cause Analysis (5 Whys)

1. **Why** 500 errors? → DB connection pool exhausted
2. **Why** pool exhausted? → 50 concurrent requests > pool size 20
3. **Why** pool too small? → Not reviewed since initial deploy
4. **Why** not monitored? → No alert on pool utilization
4. **Why** no alert? → Not considered critical metric

## Resolution

1. Increased pool size from 20 to 100 (ConfigMap update + rollout)
2. Added connection pool utilization alert (>80% for 5m)
4. Added pool size to capacity planning checklist

## What Went Well ✅
- Detection: < 1 min (automated alert)
- Communication: Clear war room, regular updates
- Mitigation: Correct fix applied quickly (5 min)
- Resolution: 23 minutes total (within SEV1 target < 30 min)

## What Went Wrong
- No proactive monitoring on connection pool
- No auto-scaling for DB pool
- No capacity planning for traffic spikes

## Action Items

| Action | Owner | Deadline | Status |
|--------|-------|----------|--------|
| Add connection pool utilization alert (>80% for 5m) | @sre-team | 1 week | ☐ |
| Implement auto-scaling for DB pool | @infra-team | 2 weeks | ☐ |
| Load test with 3x expected traffic | @qa-team | 2 weeks | ☐ |
| Document pool sizing formula | @sre-lead | 1 week | ☐ |

---

## Lessons Learned

1. **Monitor resources, not just symptoms** — pool exhaustion caused 500s, but pool usage was invisible
2. **Auto-scale critical resources** — manual scaling too slow for traffic spikes
3. **Test at 3x expected load** — peak was 3x average, pool sized for average

---

## Follow-up

- **Postmortem review**: Next team meeting
- **Action item tracking**: GitHub Issues #1234, #1235, #1236
- **Follow-up review**: 2 weeks
EOF
```

> ✅ **Checkpoint**: Postmortem created with timeline, RCA, action items

---

## Step 6 — Run Validation Script

```bash
# From your uFawkesDojo checkout
cd /path/to/uFawkesDojo
bash brown-belt/module-16-incident-management/lab-01/validate.sh
```

**Expected output** (all checks pass):

```
[INFO] Starting Brown Belt Module 16 Lab 01 validation...

[✓] Prerequisites: curl, jq, git, make installed
[✓] uFawkesObs Stack: all 12 services healthy
[✓] Alertmanager: Alert firing (HighErrorRate)
[✓] Grafana: Datasources configured (Prometheus, Loki, Tempo, Alertmanager)
[✓] Loki: Error logs queryable
[✓] Tempo: Traces searchable
[✓] Prometheus: Metrics queryable
[✓] Alerting: Rules loaded, firing
[✓] Grafana Dashboard: Incident dashboard exists
[✓] Postmortem: Document exists with required sections

==========================================
Total Tests: 11
Passed: 11
Failed: 0

[✓] All tests passed! ✅

🎉 Congratulations! You've completed Brown Belt Module 16 Lab 01.
   You've executed a full incident response lifecycle.
   Brown Belt Complete! 🎉
```

---

## Clean Up

```bash
# Resolve the alert (simulate resolution)
curl -s -X POST http://localhost:9093/api/v2/alerts \
  -H "Content-Type: application/json" \
  -d '[{"status": "resolved", "labels": {"alertname": "HighErrorRate", "service": "checkout-api"}}]'

# Clean up test files
rm -f ~/dojo-labs/incident-roles.md ~/dojo-labs/mitigation.yml ~/dojo-labs/postmortem-*.md

# Stop the stack (optional)
cd ~/dojo-labs/uFawkesObs
make down
```

---

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| Alert not firing | Alert rule syntax error | `promtool check rules /path/to/rules.yml` |
| No logs in Loki | Alloy not collecting | `docker compose logs alloy` |
| No traces in Tempo | OTel collector not receiving | `docker compose logs otel-collector` |
| Grafana datasource not working | Service not ready | Wait for healthcheck, check `make status` |
| Alert not firing | Rule syntax / threshold | Check rule syntax, `promtool check rules` |

---

## Retrieval Check (Answer Without Looking Back)

Write your answers down — the act of writing (not just thinking) strengthens retention.

1. What are the 4 ICS roles in incident response?
2. What uFawkesObs component collects logs and forwards to Loki?
3. What is the 5 Whys technique?
4. What makes a postmortem "blameless"?
5. What is a burn rate of 10x?

(Suggested answers: 1=IC, TL, Comms, Scribe; 2=Alloy; 3=Ask "why" 5 times; 4=Focus on systems not people; 5=Consuming budget 10x faster)

---

## Reference: What You Used

| Component | Purpose |
|-----------|---------|
| **Alertmanager** | Alert routing, silencing, notification routing |
| **Loki** | Log aggregation, LogQL queries |
| **Tempo** | Distributed tracing, root cause tracing |
| **Prometheus** | Metrics, PromQL, alerting rules, recording rules |
| **Grafana** | War room dashboard, visualization, alerting UI |
| **Alertmanager** | Alert routing, silencing, notifications |
| **Alloy** | Log/metric collection (replaces Promtail) |
| **OTel Collector** | Telemetry ingestion (OTLP) |

---

## What You've Accomplished

🎉 **Congratulations!** You've completed a full incident response lifecycle with uFawkesObs:

- ✅ **Detected** incident via automated alerting
- ✅ **Triaged** with Incident Command System roles
- ✅ **Investigated** using Loki (logs), Tempo (traces), Prometheus (metrics)
- ✅ **Mitigated** root cause with targeted fix
- ✅ **Verified** resolution through observability stack
- ✅ **Documented** blameless postmortem with timeline, RCA, action items

---

## Retrieval Check Answers

1. **ICS Roles**: Incident Commander, Technical Lead, Communications Lead, Scribe
2. **Log Collector**: Alloy (replaces Promtail)
3. **5 Whys**: Ask "why" five times to reach root cause
4. **Blameless**: Focus on systems/processes, assume good intent, learn not punish
5. **Burn Rate 10x**: Consuming error budget 10x faster than sustainable

---

➡️ **Next**: Return to [Module 16 README](../README.md), then prepare for the **Brown Belt Assessment**!
