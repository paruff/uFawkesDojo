# Lab 01: Observability Stack with uFawkesObs

**Module**: Brown Belt — Module 13: Observability
**Estimated Time**: 60 minutes
**Difficulty**: Advanced (Modules 9-12 complete required)
**Runs against**: [uFawkesObs `v1.1.0-rc.1`](https://github.com/paruff/uFawkesObs/releases/tag/v1.1.0-rc.1) (Docker Compose), a **pre-release**

> **Run for real on 2026-10-07 against `v1.1.0-rc.1` (pre-release), through the stack's APIs.** Grafana's browser-only clicks were not exercised in a browser. The lab moves to the stable tag when uFawkesObs ships it. See the [audit](../../../docs/ai-sdlc/compose-curriculum/audit-2026-10-06.md).

---

## Objectives

By the end of this lab you will have:

1. Deployed the uFawkesObs observability stack with `make up`
2. Explored Grafana datasources and pre-built dashboards
3. Queried metrics with PromQL in Prometheus and Grafana
3. Queried logs with LogQL in Loki and Grafana
3. Explored distributed traces with Tempo in Grafana
4. Configured alerting rules and Alertmanager notifications
4. Enabled and verified the DORA metrics profile

---

## Why This Lab Uses uFawkesObs

This lab runs against **uFawkesObs `v1.1.0-rc.1`** (pre-release) — the Observability plane of the uFawkes suite — because it provides a complete, production-grade observability stack in Docker Compose:

- **Prometheus** — Metrics storage and PromQL query engine
- **Grafana** — Dashboards, visualization, alerting UI
- **Loki** — Log aggregation with LogQL
- **Tempo** — Distributed tracing with TraceQL
- **Alertmanager** — Alert routing and notification
- **Alloy** — Log collection (replaces Promtail)
- **OTel Collector** — Telemetry ingestion (OTLP)
- **Grafana** — Unified UI for all three pillars

No Kubernetes required — runs entirely in Docker Compose on your laptop.

---

## Prerequisites

**Required**: a pinned uFawkesObs checkout

```bash
mkdir -p ~/dojo-labs && cd ~/dojo-labs
export OBS_TAG=v1.1.0-rc.1
git clone -c advice.detachedHead=false --depth 1 --branch "$OBS_TAG" \
  https://github.com/paruff/uFawkesObs.git
cd uFawkesObs
cp .env.example .env
# Edit .env and replace GRAFANA_ADMIN_PASSWORD's REPLACE_ME with a real value
```

The other `REPLACE_ME` values in `.env` (the Slack and Discord webhooks) can stay as they are.

**Required**: Modules 9-12 completed (understand CI/CD, deployment, security patterns)

**Tools required** (already installed from previous modules):
- `curl` — HTTP client
- `jq` — JSON processor
- `git` — version control
- `make` — build automation

---

## Step 0 — Read the Theory First (if you haven't)

This lab assumes you've read the [Module 13 theory](../README.md#theory--concepts-25-minutes) up through "uFawkesObs vs. Fawkes Kubernetes Monitoring". You should be able to name the three pillars of observability and identify the uFawkesObs stack components.

---

## Step 1 — Deploy the uFawkesObs Stack (5 minutes)

### 1.1 Start the Stack

```bash
cd ~/dojo-labs/uFawkesObs

# Start the core observability stack
make up
```

Wait for all services to become healthy:

```bash
# Wait for all services to report healthy (timeout: 120s default)
./scripts/wait-healthy.sh
```

**Expected output**: All 7 HTTP endpoints responding (Prometheus, Grafana, Loki, Tempo, Alloy, OTel Collector, Alertmanager)

### 1.2 Verify Services

```bash
make status
```

**Expected output**: `make status` prints a `docker compose ps` table with these nine services, then a health list:

```
alertmanager  alloy  grafana  loki  node-exporter
otel-collector  prometheus  telemetry-generator  tempo

Health endpoints:
  ✅ Prometheus  :9090
  ✅ Tempo       :3200
  ✅ Loki        :3100
  ✅ Grafana     :3000
  ✅ Alertmanager:9093
  ✅ OTel Coll.  :8888
  ✅ Alloy       :12345
```

Tempo and Grafana can show ❌ for about 15 seconds while they start; `./scripts/wait-healthy.sh` above waits for them.

> ✅ **Checkpoint**: All 9 services running and every health endpoint ✅. If any service is unhealthy, check logs with `docker compose logs <service>`.

---

## Step 2 — Explore Grafana Datasources & Dashboards (10 minutes)

### 2.1 Access Grafana

Open **http://localhost:3000** in your browser.

Login with credentials from your `.env`:
- Username: `GRAFANA_ADMIN_USER` (default: `admin`)
- Password: `GRAFANA_ADMIN_PASSWORD` (from your `.env`)

### 2.2 Verify Pre-configured Datasources

1. Click **Connections** → **Data sources** in the left sidebar
2. Verify these datasources exist and show "Working":

| Datasource | Type | URL | Purpose |
|------------|------|-----|---------|
| **Prometheus** | Prometheus | `http://prometheus:9090` | Metrics |
| **Loki** | Loki | `http://loki:3100` | Logs |
| **Tempo** | Tempo | `http://tempo:3200` | Traces |
| **Alertmanager** | Alertmanager | `http://alertmanager:9093` | Alerts |

Click each datasource → **Save & test**. Prometheus, Loki and Tempo report that they work (checked through Grafana's API). The **Alertmanager** datasource has no health check in the API (it answers "Plugin unavailable"); the UI button was not exercised, so don't be alarmed if that one is not green.

> ✅ **Checkpoint**: Prometheus, Loki and Tempo show "Working"

### 2.3 Explore Pre-built Dashboards

1. Click **Dashboards** → **Browse** in the left sidebar
2. The folders are **Application**, **Platform** and **Services**
3. Open **Node Exporter** (in Application) → observe host-level metrics
4. Open **Platform - Prometheus Overview** (in Platform) → observe Prometheus self-metrics

> ✅ **Checkpoint**: You can navigate Grafana and see pre-provisioned dashboards

---

## Step 3 — Query Metrics with PromQL (15 minutes)

### 3.1 Explore Metrics in Prometheus

Open **http://localhost:9090** (Prometheus UI)

1. Click **Graph** tab
2. Try these queries:

```promql
# All targets up
up

# Container CPU usage
rate(container_cpu_usage_seconds_total[5m])

# Container memory usage
(container_memory_usage_bytes / container_spec_memory_limit_bytes) * 100

# HTTP request rate (Prometheus's own API traffic; the demo app exports traces and
# logs, not request metrics, so there is no http_requests_total)
rate(prometheus_http_requests_total[5m])

# Request latency p95
histogram_quantile(0.95, sum by (le) (rate(prometheus_http_request_duration_seconds_bucket[5m])))
```

### 3.2 Build a Custom Query

Try building this query step by step:

```promql
# Container memory usage percentage by container
(container_memory_usage_bytes / container_spec_memory_limit_bytes) * 100
```

1. Type `container_memory_usage_bytes` → observe autocomplete
2. Add division: `/ container_spec_memory_limit_bytes`
3. Multiply by 100: `* 100`
4. Add `by (container)` to group by container

> ✅ **Checkpoint**: You can write PromQL queries and see results in Prometheus and Grafana

### 3.3 Create a Custom Grafana Panel

1. In Grafana, click **+** → **Dashboard** → **Add visualization**
2. Select **Prometheus** datasource
3. Enter query: `rate(prometheus_http_requests_total[5m])`
4. Set **Legend** to `{{job}} - {{instance}}`
5. Click **Apply** → **Save dashboard** → name it "My First Dashboard"

> ✅ **Checkpoint**: You've created a custom Grafana panel with PromQL

---

## Step 4 — Query Logs with LogQL (10 minutes)

### 4.1 Explore Logs in Loki

In Grafana, click **Explore** → select **Loki** datasource

### 4.2 Try LogQL Queries

```logql
# All logs from the stack
{compose_project!=""}

# Errors only
{compose_project!=""} |= "ERROR"

# Logs from a specific container
{compose_service="otel-collector"}

# Parse JSON logs and filter
{compose_project!=""} | json | level="error"
```

### 4.3 Parse JSON and Extract Fields

```logql
# Parse JSON logs and extract specific fields
{compose_project!=""} | json | __error__="" | line_format "{{.timestamp}} {{.level}} {{.message}}"

# Extract specific fields from JSON
{compose_project!=""} | json | line_format "service={{.service}} trace_id={{.trace_id}} msg={{.message}}"
```

### 4.4 Create a Log-Based Dashboard Panel

1. In Grafana, **Explore** → **Loki**
2. Enter: `{compose_project!=""} |= "ERROR" | json | line_format "{{.timestamp}} {{.message}}"`
2. Click **Add to dashboard** → select your dashboard
3. Set visualization to **Logs**

> ✅ **Checkpoint**: You can query logs with LogQL and create log panels in Grafana

---

## Step 5 — Explore Traces with Tempo (10 minutes)

### 5.1 Access Tempo in Grafana

1. In Grafana **Explore**, select **Tempo** datasource
2. The demo app (`telemetry-generator`) should be generating traces

### 5.2 Search for Traces

1. Click **Search** tab
2. Service name: `telemetry-generator`
3. Click **Search**

### 5.3 Examine a Trace

1. Click on any trace row
2. Explore the **Trace timeline** — see spans, duration, parent/child relationships
3. Click a span → see **Span details**: attributes, events, links

### 5.4 TraceQL Query (Advanced)

In Tempo Explore, switch to **TraceQL** mode:

```traceql
{span.http.method = "GET"} && {duration > 100ms}
```

> ✅ **Checkpoint**: You can search and examine distributed traces in Tempo

---

## Step 6 — Configure Alerting (10 minutes)

### 6.1 Create a Prometheus Alert Rule

Create alert rule file:

```bash
cat > ~/dojo-labs/alert-rules.yml <<'EOF'
groups:
  - name: platform-alerts
    interval: 30s
    rules:
      - alert: HighCPUUsage
        expr: |
          (100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)) > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage on {{ $labels.instance }}"
          description: "CPU usage > 80% for 5 minutes"

      - alert: HighMemoryUsage
        expr: |
          (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage on {{ $labels.instance }}"

      - alert: DeploymentFailure
        expr: increase(deployment_result{status="failure"}[5m]) > 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Deployment failure detected"
          description: "Deployment for {{ $labels.application }} failed"
EOF
```

### 6.2 Apply Alert Rules

Prometheus reads only the rule files named in `rule_files` in
`config/prometheus/prometheus.yaml`; it does not scan the `rules/` folder. Copy your
file in, then add it to that list:

```bash
cd ~/dojo-labs/uFawkesObs
cp ~/dojo-labs/alert-rules.yml config/prometheus/rules/platform-alerts.yml

python3 - <<'PY'
import pathlib
p = pathlib.Path("config/prometheus/prometheus.yaml")
s = p.read_text()
last = '  - "/etc/prometheus/rules/ufawkesobs-dora-regression.yml"\n'
new = s.replace(last, last + '  - "/etc/prometheus/rules/platform-alerts.yml"\n')
assert new != s, "rule_files line not found"
with open(p, "r+") as f:  # edit in place: see the warning below
    f.seek(0); f.write(new); f.truncate()
PY

curl -s -o /dev/null -w "reload -> HTTP %{http_code}\n" -X POST http://localhost:9090/-/reload
```

**Expected output**: `reload -> HTTP 200`.

> ⚠️ **Edit that file in place.** `prometheus.yaml` is a single-file mount. If an editor or
> `sed -i` replaces the file, Prometheus keeps a deleted copy and every reload fails with
> `HTTP 500` (`open /etc/prometheus/prometheus.yaml: no such file or directory`). Fix it with
> `docker compose --profile '*' restart prometheus`.

### 6.3 Verify Alert Rules

1. Open **http://localhost:9090/alerts** (Prometheus Alerts page)
2. Verify your rules appear: `HighCPUUsage`, `HighMemoryUsage`, `DeploymentFailure`
3. Check **http://localhost:9093** (Alertmanager) → see routing configuration

To check from the terminal:

```bash
curl -s http://localhost:9090/api/v1/rules | jq -r '.data.groups[] | select(.name=="platform-alerts") | .rules[].name'
```

**Expected output**:

```
HighCPUUsage
HighMemoryUsage
DeploymentFailure
```

> ✅ **Checkpoint**: Alert rules loaded and visible in Prometheus/Alertmanager

---

## Step 7 — Enable DORA Metrics Profile (5 minutes)

### 7.1 Enable DORA Profile

The DORA profile adds to the running stack. You do not need to stop anything first.

```bash
cd ~/dojo-labs/uFawkesObs
make up-dora
./scripts/wait-healthy.sh
```

> `make down` does not stop this stack at this version: it runs `docker compose down`
> without the profiles `make up` started
> ([uFawkesObs#617](https://github.com/paruff/uFawkesObs/issues/617)), so it changes nothing.

### 7.2 Verify the DORA service

```bash
docker ps --format '{{.Names}}' | grep dora
```

**Expected output**: one container, `ufawkesdora-ingestion`. It is the DORA API (port 8088), and it
computes the metrics itself, so there is no separate `dora-compute` or Pushgateway.

### 7.3 Send a deployment event

```bash
curl -s http://localhost:8088/health

curl -s -w "  HTTP %{http_code}\n" -X POST http://localhost:8088/event \
  -H "Content-Type: application/json" \
  -d '{
    "schema_version": "1.0",
    "event_type": "deployment",
    "repo": "your-name/dojo-lab",
    "service": "test-service",
    "environment": "production",
    "commit_sha": "'"$(printf '%040d' 7)"'",
    "deployed_at": "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'",
    "status": "success",
    "pipeline_url": "https://example.com/ci/7"
  }'
```

**Expected output**:

```
{"status":"ok","queue_depth":0}
{"queued":true,"id":1}  HTTP 201
```

An event that leaves out a required field (`schema_version`, `repo`, `deployed_at`,
`pipeline_url`, a 40-character `commit_sha`) is rejected with `HTTP 422`.

### 7.4 See the metric

The compute loop runs every 15 seconds. Wait about 20 seconds, then:

```bash
curl -s http://localhost:8088/metrics | grep '^dora_deployment_frequency'
```

**Expected output**:

```
dora_deployment_frequency_per_week{team_id="your-name/dojo-lab",tier="low"} 0.23333333333333334
```

> ✅ **Checkpoint**: DORA profile enabled and test event processed

---

## Step 8 — Run Validation Script

```bash
# From your uFawkesDojo checkout
cd /path/to/uFawkesDojo
bash brown-belt/module-13-observability/lab-01/validate.sh
```

**Expected output** (all 11 checks pass):

```
[✓] Prerequisites: curl, jq, git, make installed
[✓] uFawkesObs Stack: All 8 services healthy (prometheus, grafana, loki, tempo, alertmanager, alloy, otel-collector, node-exporter)
[✓] Prometheus Metrics: Query successful, 12 targets found
[✓] Loki Logs: LogQL query successful
[✓] Tempo Traces: Found traces for telemetry-generator
[✓] Prometheus Rules: Found 68 alerting rules loaded
[✓] Alertmanager: Alertmanager API reachable
[✓] DORA Profile: dora-api healthy and exposing DORA metrics (compute runs in-process)
[✓] PromQL Queries: All test PromQL queries successful
[✓] LogQL Queries: All test LogQL queries successful
[✓] TraceQL Query: TraceQL query successful

Total Tests : 11
Passed      : 11
Failed      : 0

[✓] All tests passed! ✅
```

The target count and the rule count can differ a little between runs. Note what this script does
not check: it passes on a stack you have only started, whether or not your alert rules are loaded
or your event was processed. Use the commands in Steps 6.3 and 7.4 for that.

---

## Clean Up

```bash
# Stop the stack and remove its volumes (the profiles matter: plain `make down` leaves it running)
cd ~/dojo-labs/uFawkesObs
docker compose --profile '*' down -v --remove-orphans

# Remove data (optional)
rm -rf data/
```

---

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| Service unhealthy | Config error, port conflict | `docker compose logs <service>` |
| `make up` fails | Port already in use | `lsof -i :3000` etc., free the port |
| Grafana datasource not working | Service not ready | Wait for healthcheck, check service logs |
| No traces in Tempo | Stack only just started | Wait a minute and search again; the demo app (`telemetry-generator`) starts with `make up` |
| Alert rules not loading | The file is not listed in `rule_files` | Add it as in Step 6.2, then reload |
| Reload returns `HTTP 500` | The config file was replaced, not edited in place | `docker compose --profile '*' restart prometheus` |
| No DORA metrics | DORA profile not enabled, or the event was rejected | Run `make up-dora`; check the event returned `HTTP 201` |

---

## Retrieval Check (Answer Without Looking Back)

Write your answers down — the act of writing (not just thinking) strengthens retention.

1. What are the three pillars of observability and their tools in uFawkesObs?
2. Which component collects container logs and forwards to Loki?
3. How do you enable the DORA metrics profile?
4. What query language does Loki use?
5. Which component routes alerts to Slack/PagerDuty?

(Suggested answers: 1 = Metrics/Prometheus, Logs/Loki, Traces/Tempo; 2 = Alloy; 3 = `make up-dora`; 4 = LogQL; 5 = Alertmanager)

---

## What You've Accomplished

🎉 **Congratulations!** You've completed Brown Belt Module 13 Lab 01.

You've:
- ✅ Deployed a full observability stack with `make up`
- ✅ Explored all three pillars: metrics (PromQL), logs (LogQL), traces (TraceQL)
- ✅ Configured alerting with Prometheus rules and Alertmanager
- ✅ Enabled DORA metrics profile and processed test events
- ✅ Validated the complete observability stack

**Next**: Module 14 — DORA Deep Dive (advanced PromQL, benchmarking, SLOs)

---

## Module Completion

### ✅ You've Completed Module 13

**Next Steps**:
1. ✅ Mark this module complete in your Backstage profile
2. 📊 View your progress on the Dojo dashboard
3. 💬 Share your completion in [Show and tell](https://github.com/paruff/uFawkesDojo/discussions/categories/show-and-tell) (optional!)
4. ➡️ **Continue to Module 14: DORA Deep Dive**

**Time Investment**: 3-4 hours
**Skills Gained**: Observability stack deployment, PromQL/LogQL/TraceQL, alerting, DORA metrics
**Progress**: 1 of 4 modules toward Brown Belt (25% complete)

---

**Questions or Issues?**
- 💬 Ask in [GitHub Discussions](https://github.com/paruff/uFawkesDojo/discussions) ([Q&A](https://github.com/paruff/uFawkesDojo/discussions/categories/q-a))
- 📧 Email: dojo@ufawkes.dev
- 🐛 Report bugs: [GitHub Issues](https://github.com/paruff/fawkes/issues)

**Feedback?**
- Rate this module (takes 30 seconds)
- Suggest improvements
- Help us make the dojo better!
