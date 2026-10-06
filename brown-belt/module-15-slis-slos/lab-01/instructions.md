# Lab 01: Implementing SLIs, SLOs, and Error Budgets with uFawkesObs

**Module**: Brown Belt — Module 15: SLIs, SLOs, and Error Budgets
**Estimated Time**: 45 minutes
**Difficulty**: Advanced (Modules 13-14 complete required)
**Runs against**: uFawkesObs v1.0.0 (not released yet) (Docker Compose)

> **Written ahead of its stack, not yet run for real.** uFawkesObs v1.0.0 has not been released, so no one has run every step of this lab against it. Treat the steps and the expected output as unverified. See the [audit](../../../docs/ai-sdlc/compose-curriculum/audit-2026-10-06.md).

---

## Objectives

By the end of this lab you will have:

1. Created SLI recording rules for a sample service (availability, latency, error rate)
2. Defined SLO recording rules with targets and time windows
3. Implemented error budget recording rules with burn rate alerts
4. Configured multi-window burn rate alerts in Alertmanager
5. Built a Grafana SLO dashboard with error budget visualization
6. Practiced SLO-driven deployment decisions

---

## Why This Lab Uses uFawkesObs

This lab runs against **uFawkesObs v1.0.0** — the Observability plane of the uFawkes suite — because it provides a complete SLI/SLO platform in Docker Compose:

- **Prometheus** — Metrics storage, PromQL queries, recording rules, alerting
- **Grafana** — SLO dashboards, error budget visualization
- **Alertmanager** — Alert routing and notification
- **Alloy** — Log collection (replaces Promtail)
- **OTel Collector** — Telemetry ingestion (OTLP)
- **Grafana** — Unified UI for all three pillars

No Kubernetes required — runs entirely in Docker Compose on your laptop.

---

## Prerequisites

**Required**: uFawkesObs v1.0.0 running locally (from Module 13)

```bash
# Verify your stack is running
cd ~/dojo-labs/uFawkesObs
make status
```

**Expected**: All services healthy (prometheus, grafana, loki, tempo, alertmanager, alloy, otel-collector)

**Required**: Modules 13 & 14 completed (understand observability pipeline and DORA metrics)

**Tools required** (already installed from previous modules):
- `curl` — HTTP client
- `jq` — JSON processor
- `git` — version control
- `make` — build automation

---

## Step 0 — Read the Theory First (if you haven't)

This lab assumes you've read the [Module 15 theory](../README.md#theory--concepts-30-minutes) up through "Error Budget Policies". You should be able to name the three pillars of observability, define SLI/SLO/Error Budget, and explain burn rate.

---

## Step 1 — Examine Existing Prometheus Rules (5 minutes)

### 1.1 Explore Prometheus Rules Directory

```bash
cd ~/dojo-labs/uFawkesObs
ls -la config/prometheus/rules/
```

**Expected**: You'll see files like `sli-recording.rules.yml`, `slo-recording.rules.yml`, `error-budget.rules.yml`, `slo-alerts.rules.yml`

### 1.2 Examine SLI Recording Rules

```bash
cat config/prometheus/rules/sli-recording.rules.yml
```

**Key observations**:
- Recording rules for SLIs (availability, latency, error_rate) at different time windows (1h, 7d, 30d)
- Uses `rate()` and `histogram_quantile()` for latency percentiles
- Output metric names follow pattern: `sli:<name>:<window>`

### 1.3 Examine SLO Recording Rules

```bash
cat config/prometheus/rules/slo-recording.rules.yml
```

**Key observations**:
- Recording rules that compute SLO compliance: `slo:<name>:<window>`
- Compares SLI against target: `sli:availability:30d >= 99.9`
- Output: 1 (meeting SLO) or 0 (violating SLO)

### 1.4 Examine Error Budget Rules

```bash
cat config/prometheus/rules/error-budget.rules.yml
```

**Key observations**:
- Error budget remaining: `1 - (SLO - SLI) / (1 - SLO_target)`
- Burn rate calculations for 1h and 6h windows
- Remaining budget percentage: `100 * (1 - (SLO - SLI) / (1 - SLO_target))`

### 1.5 Examine SLO Alert Rules

```bash
cat config/prometheus/rules/slo-alerts.rules.yml
```

**Key observations**:
- Multi-window burn rate alerts (1h, 6h, 24h)
- Fast burn alerts (1h window, high threshold)
- Slow burn alerts (6h/24h windows, lower threshold)
- SLO breach alerts (approaching SLO, exhausted budget)

---

## Step 2 — Add SLI Recording Rules for a Sample Service (10 minutes)

### 2.1 Create SLI Recording Rules for a Sample Service

We'll create SLI recording rules for a sample "payment-api" service. In uFawkesObs, recording rules are defined in `config/prometheus/rules/`.

```bash
cat > ~/dojo-labs/sli-recording-payment.yaml <<'EOF'
groups:
  - name: sli_recording_payment_api
    interval: 30s
    rules:
      # Availability SLI (1 hour window)
      - record: sli:payment-api:availability:1h
        expr: |
          sum(rate(http_requests_total{service="payment-api",status!~"5.."}[1h]))
          /
          sum(rate(http_requests_total{service="payment-api"}[1h]))
          * 100

      # Availability SLI (7 day window)
      - record: sli:payment-api:availability:7d
        expr: |
          sum(rate(http_requests_total{service="payment-api",status!~"5.."}[7d]))
          /
          sum(rate(http_requests_total{service="payment-api"}[7d]))
          * 100

      # Availability SLI (30 day window)
      - record: sli:payment-api:availability:30d
        expr: |
          sum(rate(http_requests_total{service="payment-api",status!~"5.."}[30d]))
          /
          sum(rate(http_requests_total{service="payment-api"}[30d]))
          * 100

      # Latency SLI (p95, 1 hour window)
      - record: sli:payment-api:latency_p95:1h
        expr: |
          histogram_quantile(0.95,
            sum(rate(http_request_duration_seconds_bucket{service="payment-api"}[1h])) by (le)
          )

      # Latency SLI (p95, 7 day window)
      - record: sli:payment-api:latency_p95:7d
        expr: |
          histogram_quantile(0.95,
            sum(rate(http_request_duration_seconds_bucket{service="payment-api"}[7d])) by (le)
          )

      # Latency SLI (p99, 7 day window)
      - record: sli:payment-api:latency_p99:7d
        expr: |
          histogram_quantile(0.99,
            sum(rate(http_request_duration_seconds_bucket{service="payment-api"}[7d])) by (le)
          )

      # Error Rate SLI (7 day window)
      - record: sli:payment-api:error_rate:7d
        expr: |
          sum(rate(http_requests_total{service="payment-api",status=~"5.."}[7d]))
          /
          sum(rate(http_requests_total{service="payment-api"}[7d]))
          * 100
EOF
```

### 2.2 Apply the Recording Rules

```bash
# Copy to Prometheus rules directory
cp ~/dojo-labs/sli-recording-payment.yaml ~/dojo-labs/uFawkesObs/config/prometheus/rules/sli-recording-payment-api.yml

# Reload Prometheus configuration
curl -X POST http://localhost:9090/-/reload
```

### 2.3 Verify Recording Rules

```bash
# Check that rules are loaded
curl -s "http://localhost:9090/api/v1/rules" | jq '.data.groups[] | select(.name=="sli_recording_payment_api")'

# Query the recorded SLIs
curl -s "http://localhost:9090/api/v1/query?query=sli:payment-api:availability:1h" | jq '.data.result'
curl -s "http://localhost:9090/api/v1/query?query=sli:payment-api:latency_p95:7d" | jq '.data.result'
curl -s "http://localhost:9090/api/v1/query?query=sli:payment-api:error_rate:7d" | jq '.data.result'
```

> ✅ **Checkpoint**: SLI recording rules are active and returning values.

---

## Step 3 — Define SLO Recording Rules (10 minutes)

### 3.1 Create SLO Recording Rules

```bash
cat > ~/dojo-labs/slo-recording-payment.yaml <<'EOF'
groups:
  - name: slo_recording_payment_api
    interval: 1m
    rules:
      # Availability SLO (99.9% over 30 days)
      - record: slo:payment-api:availability:30d
        expr: |
          sli:payment-api:availability:30d >= 99.9

      # Availability SLO (7 day window)
      - record: slo:payment-api:availability:7d
        expr: sli:payment-api:availability:7d >= 99.9

      # Latency SLO (p95 <= 500ms over 7 days)
      - record: slo:payment-api:latency_p95:7d
        expr: sli:payment-api:latency_p95:7d <= 500

      # Latency SLO (p99 <= 1000ms over 7 days)
      - record: slo:payment-api:latency_p99:7d
        expr: sli:payment-api:latency_p99:7d <= 1000

      # Error Rate SLO (< 0.1% over 30 days)
      - record: slo:payment-api:error_rate:30d
        expr: sli:payment-api:error_rate:30d <= 0.1
EOF
```

### 3.2 Apply SLO Recording Rules

```bash
cp ~/dojo-labs/slo-recording-payment.yaml ~/dojo-labs/uFawkesObs/config/prometheus/rules/slo-recording-payment-api.yml
curl -X POST http://localhost:9090/-/reload
```

### 3.3 Verify SLO Recording Rules

```bash
# Check SLO compliance (1 = meeting, 0 = violating)
curl -s "http://localhost:9090/api/v1/query?query=slo:payment-api:availability:30d" | jq '.data.result'
curl -s "http://localhost:9090/api/v1/query?query=slo:payment-api:latency_p95:7d" | jq '.data.result'
curl -s "http://localhost:9090/api/v1/query?query=slo:payment-api:error_rate:30d" | jq '.data.result'
```

> ✅ **Checkpoint**: All SLOs show `1` (meeting targets) or `0` (violating).

---

## Step 4 — Configure Error Budget Recording Rules (10 minutes)

### 4.1 Create Error Budget Recording Rules

```bash
cat > ~/dojo-labs/error-budget-payment.yaml <<'EOF'
groups:
  - name: error_budget_payment_api
    interval: 1m
    rules:
      # Availability Error Budget Remaining (30d window)
      - record: error_budget:payment-api:availability:remaining_percent:30d
        expr: |
          (
            100 - (
              (99.9 - sli:payment-api:availability:30d) / (100 - 99.9) * 100
            )
          )

      # Availability Error Budget Consumed
      - record: error_budget:payment-api:availability:consumed_percent:30d
        expr: 100 - error_budget:payment-api:availability:remaining_percent:30d

      # Availability Burn Rate (1 hour window)
      - record: error_budget:payment-api:availability:burn_rate_1h
        expr: |
          (100 - sli:payment-api:availability:1h) / (100 - 99.9)

      # Availability Burn Rate (6 hour window)
      - record: error_budget:payment-api:availability:burn_rate_6h
        expr: |
          (100 - sli:payment-api:availability:6h) / (100 - 99.9)

      # Availability Burn Rate (24 hour window)
      - record: error_budget:payment-api:availability:burn_rate_24h
        expr: |
          (100 - sli:payment-api:availability:24h) / (100 - 99.9)

      # Error Rate Error Budget Remaining (30d)
      - record: error_budget:payment-api:error_rate:remaining_percent:30d
        expr: |
          (
            1 - (sli:payment-api:error_rate:30d / 0.1)
          ) * 100
EOF
```

### 4.2 Apply Error Budget Rules

```bash
cp ~/dojo-labs/error-budget-payment.yaml ~/dojo-labs/uFawkesObs/config/prometheus/rules/error-budget-payment-api.yml
curl -X POST http://localhost:9090/-/reload
```

### 4.3 Verify Error Budget Rules

```bash
# Check error budget remaining
curl -s "http://localhost:9090/api/v1/query?query=error_budget:payment-api:availability:remaining_percent:30d" | jq '.data.result'

# Check burn rates
curl -s "http://localhost:9090/api/v1/query?query=error_budget:payment-api:availability:burn_rate_1h" | jq '.data.result'
curl -s "http://localhost:9090/api/v1/query?query=error_budget:payment-api:availability:burn_rate_6h" | jq '.data.result'
```

> ✅ **Checkpoint**: Error budget metrics show reasonable values (e.g., 100% remaining if no errors, burn rates ~1x).

---

## Step 5 — Configure Multi-Window Burn Rate Alerts (10 minutes)

### 5.1 Create SLO Alert Rules

```bash
cat > ~/dojo-labs/slo-alerts-payment.yaml <<'EOF'
groups:
  - name: slo_alerts_payment_api
    interval: 30s
    rules:
      # Fast burn alert (1 hour window) - Critical
      - alert: PaymentAPI_FastBurnRate
        expr: |
          error_budget:payment-api:availability:burn_rate_1h > 14.4
        for: 5m
        labels:
          severity: critical
          slo: payment-api-availability
        annotations:
          summary: "Payment API: Critical burn rate (1h) - will exhaust budget in 2 days"
          description: "Burn rate is {{ $value }}x normal. Budget exhausted in ~2 days."

      # Medium burn alert (6 hour window) - Warning
      - alert: PaymentAPI_MediumBurnRate
        expr: |
          error_budget:payment-api:availability:burn_rate_6h > 6
          and
          error_budget:payment-api:availability:remaining_percent:30d < 50
        for: 30m
        labels:
          severity: warning
          slo: payment-api-availability
        annotations:
          summary: "Payment API: High burn rate with low remaining budget"
          description: "6h burn rate is {{ $value }}x, budget remaining: {{ $value | printf \"%.1f\" }}%"

      # Slow burn alert (24 hour window) - Warning
      - alert: PaymentAPI_SlowBurnRate
        expr: |
          error_budget:payment-api:availability:burn_rate_24h > 2
          and
          error_budget:payment-api:availability:remaining_percent:30d < 30
        for: 1h
        labels:
          severity: warning
          slo: payment-api-availability
        annotations:
          summary: "Payment API: Sustained burn rate with low budget"
          description: "24h burn rate {{ $value }}x, {{ $value }}% budget remaining"

      # SLO breach alert (approaching SLO)
      - alert: PaymentAPI_SLOApproachingBreach
        expr: |
          slo:payment-api:availability:30d == 0
        for: 1h
        labels:
          severity: critical
          slo: payment-api-availability
        annotations:
          summary: "Payment API Availability SLO breached"
          description: "Availability SLO violated for 30-day window"

      # Error budget exhausted
      - alert: PaymentAPI_ErrorBudgetExhausted
        expr: |
          error_budget:payment-api:availability:remaining_percent:30d <= 0
        for: 5m
        labels:
          severity: critical
          slo: payment-api-availability
        annotations:
          summary: "Payment API Error Budget Exhausted"
          description: "Error budget exhausted. Deploy freeze in effect per error budget policy."
EOF
```

### 5.2 Apply Alert Rules

```bash
cp ~/dojo-labs/slo-alerts-payment.yaml ~/dojo-labs/uFawkesObs/config/prometheus/rules/slo-alerts-payment-api.yml
curl -X POST http://localhost:9090/-/reload
```

### 5.3 Verify Alert Rules

```bash
# Check alert rules loaded
curl -s "http://localhost:9090/api/v1/rules" | jq '.data.groups[] | select(.name=="slo_alerts_payment_api")'

# Check Alertmanager
curl -s http://localhost:9093/api/v2/alerts | jq '.[] | select(.labels.alertname | test("PaymentAPI"))'
```

> ✅ **Checkpoint**: Alert rules loaded and visible in Prometheus/Alertmanager.

---

## Step 6 — Build Grafana SLO Dashboard (10 minutes)

### 6.1 Create Dashboard JSON

```bash
cat > ~/dojo-labs/slo-dashboard-payment.json <<'EOF'
{
  "dashboard": {
    "title": "SLO Dashboard - Payment API",
    "tags": ["slo", "payment-api", "error-budget"],
    "timezone": "utc",
    "panels": [
      {
        "id": 1,
        "title": "Availability SLO (30d)",
        "type": "gauge",
        "targets": [
          {
            "expr": "sli:payment-api:availability:30d",
            "legendFormat": "Current"
          },
          {
            "expr": "99.9",
            "legendFormat": "SLO Target"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "thresholds": {
              "steps": [
                {"value": 0, "color": "red"},
                {"value": 99.8, "color": "yellow"},
                {"value": 99.9, "color": "green"}
              ]
            },
            "unit": "percent",
            "min": 99,
            "max": 100
          },
        "gridPos": {"h": 8, "w": 6, "x": 0, "y": 0}
      },
      {
        "id": 2,
        "title": "Error Budget Remaining (30d)",
        "type": "gauge",
        "targets": [
          {
            "expr": "error_budget:payment-api:availability:remaining_percent:30d",
            "legendFormat": "Remaining"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "thresholds": {
              "steps": [
                {"value": 0, "color": "red"},
                {"value": 25, "color": "yellow"},
                {"value": 50, "color": "green"}
              ]
            },
            "unit": "percent"
          },
        "gridPos": {"h": 8, "w": 6, "x": 6, "y": 0}
      },
      {
        "id": 3,
        "title": "Latency SLO (p95, 7d)",
        "type": "gauge",
        "targets": [
          {
            "expr": "sli:payment-api:latency_p95:7d / 1000",
            "legendFormat": "p95 Latency (seconds)"
          },
          {
            "expr": "0.5",
            "legendFormat": "SLO Target (0.5s)"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "thresholds": {
              "steps": [
                {"value": 0, "color": "green"},
                {"value": 0.5, "color": "yellow"},
                {"value": 1.0, "color": "red"}
              ]
            },
            "unit": "s"
          },
        "gridPos": {"h": 8, "w": 6, "x": 12, "y": 0}
      },
      {
        "id": 4,
        "title": "Error Budget Remaining (30d)",
        "type": "gauge",
        "targets": [
          {
            "expr": "error_budget:payment-api:availability:remaining_percent:30d",
            "legendFormat": "Remaining %"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "thresholds": {
              "steps": [
                {"value": 0, "color": "red"},
                {"value": 25, "color": "yellow"},
                {"value": 50, "color": "green"}
              ]
            },
            "unit": "percent"
          },
        "gridPos": {"h": 8, "w": 6, "x": 18, "y": 0}
      },
      {
        "id": 5,
        "title": "Availability SLO Status (30d)",
        "type": "stat",
        "targets": [
          {
            "expr": "slo:payment-api:availability:30d",
            "legendFormat": "Meeting SLO"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "thresholds": {
              "steps": [
                {"value": 0, "color": "red"},
                {"value": 1, "color": "green"}
              ]
            },
            "mappings": [
              {"type": "value", "options": {"0": {"text": "VIOLATING", "color": "red"}, "1": {"text": "MEETING", "color": "green"}}}
            ]
          }
        },
        "gridPos": {"h": 4, "w": 6, "x": 0, "y": 8}
      },
      {
        "id": 6,
        "title": "Burn Rate (1h)",
        "type": "stat",
        "targets": [
          {
            "expr": "error_budget:payment-api:availability:burn_rate_1h",
            "legendFormat": "1h Burn Rate"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "thresholds": {
              "steps": [
                {"value": 0, "color": "green"},
                {"value": 2, "color": "yellow"},
                {"value": 14.4, "color": "red"}
              ]
            }
          }
        },
        "gridPos": {"h": 4, "w": 6, "x": 6, "y": 8}
      },
      {
        "id": 7,
        "title": "Burn Rate (6h)",
        "type": "stat",
        "targets": [
          {
            "expr": "error_budget:payment-api:availability:burn_rate_6h",
            "legendFormat": "6h Burn Rate"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "thresholds": {
              "steps": [
                {"value": 0, "color": "green"},
                {"value": 2, "color": "yellow"},
                {"value": 6, "color": "red"}
              ]
            }
          }
        },
        "gridPos": {"h": 4, "w": 6, "x": 12, "y": 8}
      },
      {
        "id": 8,
        "title": "Error Budget Remaining (30d)",
        "type": "graph",
        "targets": [
          {
            "expr": "error_budget:payment-api:availability:remaining_percent:30d",
            "legendFormat": "Remaining %"
          },
          {
            "expr": "error_budget:payment-api:availability:consumed_percent:30d",
            "legendFormat": "Consumed %"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 12}
      },
      {
        "id": 9,
        "title": "Burn Rate Trend (6h)",
        "type": "graph",
        "targets": [
          {
            "expr": "error_budget:payment-api:availability:burn_rate_1h",
            "legendFormat": "1h"
          },
          {
            "expr": "error_budget:payment-api:availability:burn_rate_6h",
            "legendFormat": "6h"
          },
          {
            "expr": "error_budget:payment-api:availability:burn_rate_24h",
            "legendFormat": "24h"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 12}
      }
    ],
    "time": {
      "from": "now-7d",
      "to": "now"
    },
    "refresh": "30s"
  },
  "overwrite": true
}
EOF
```

### 6.2 Import Dashboard

```bash
# Import via Grafana API
curl -s -X POST http://localhost:3000/api/dashboards/db \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $(cat ~/dojo-labs/uFawkesObs/.env | grep GRAFANA_ADMIN_PASSWORD | cut -d= -f2)" \
  -d @~/dojo-labs/slo-dashboard-payment.json
```

Or import manually:
1. Open Grafana → **+** → **Import**
2. Upload `~/dojo-labs/slo-dashboard-payment.json`
3. Select **Prometheus** datasource
4. Click **Import**

> ✅ **Checkpoint**: Dashboard visible with all 9 panels showing SLO status, error budget, burn rates.

---

## Step 7 — Practice SLO-Driven Decisions (10 minutes)

### 7.1 Scenario: Deploy Decision

**Scenario**: You're about to deploy a new feature to `payment-api`. Current state:
- Error budget remaining: 60%
- Burn rate: 1.2x (normal)
- Time: 2 PM on Tuesday

```bash
# Check current error budget
curl -s "http://localhost:9090/api/v1/query?query=error_budget:payment-api:availability:remaining_percent:30d" | jq '.data.result'

# Check burn rate
curl -s "http://localhost:9090/api/v1/query?query=error_budget:payment-api:availability:burn_rate_1h" | jq '.data.result'
```

**Decision Framework**:
1. Error budget > 25% ✅
2. Burn rate < 2x ✅
3. Time: Off-peak hours ✅
4. Rollback plan exists ✅

**Decision**: ✅ **DEPLOY** - Sufficient budget, normal burn rate, low-risk timing

### 7.2 Scenario: High Burn Rate

```bash
# Simulate increased error rate
for i in {1..10}; do
  curl -s "http://localhost:5001/api/payment/fail" > /dev/null &
done

# Wait for metrics to update
sleep 30

# Check burn rate
curl -s "http://localhost:9090/api/v1/query?query=error_budget:payment-api:availability:burn_rate_1h" | jq '.data.result'
```

**Decision Framework**:
1. Budget > 25% ✅ but burn rate > 10x ❌
2. **Decision**: ❌ **HOLD DEPLOY** - Investigate root cause first
3. Action: Investigate, fix root cause, then deploy

### 7.3 Scenario: Budget Exhausted

```bash
# Check budget remaining
curl -s "http://localhost:9090/api/v1/query?query=error_budget:payment-api:availability:remaining_percent:30d" | jq '.data.result[0].value[1]'
```

**Decision Framework**:
- Budget < 10% remaining ❌
- **Decision**: **FREEZE DEPLOYS** - Focus on reliability sprint
- Action: Root cause analysis, fix reliability issues, rebuild budget

---

## Step 8 — Run the Validation Script

```bash
# From your uFawkesDojo checkout
cd /path/to/uFawkesDojo
bash brown-belt/module-15-slis-slos/lab-01/validate.sh
```

**Expected output** (all checks pass):

```
[INFO] Starting Brown Belt Module 15 Lab 01 validation...

[✓] Prerequisites: curl, jq, git, make installed
[✓] uFawkesObs Stack: all 8 services healthy
[✓] Prometheus Rules: SLI recording rules loaded
[✓] Prometheus Rules: SLO recording rules loaded
[✓] Prometheus Rules: Error budget rules loaded
[✓] Prometheus Rules: SLO alert rules loaded
[✓] SLI Recording: availability, latency, error_rate recording
[✓] SLO Recording: availability, latency, error_rate SLOs
[✓] Error Budget: Remaining %, burn rates calculated
[✓] Alert Rules: Burn rate and SLO breach alerts loaded
[✓] Grafana Dashboard: SLO dashboard with 9 panels
[✓] SLO Decision: Deploy/hold logic verified

==========================================
Total Tests: 11
Passed: 11
Failed: 0

[✓] All tests passed! ✅

🎉 Congratulations! You've completed Brown Belt Module 15 Lab 01.
   You've implemented SLIs, SLOs, Error Budgets with uFawkesObs.
   You're ready for the Brown Belt Assessment!
```

---

## Clean Up

```bash
# Remove custom rules (optional - they'll be cleaned on next make up)
rm ~/dojo-labs/uFawkesObs/config/prometheus/rules/sli-recording-payment-api.yml
rm ~/dojo-labs/uFawkesObs/config/prometheus/rules/slo-recording-payment-api.yml
rm ~/dojo-labs/uFawkesObs/config/prometheus/rules/error-budget-payment-api.yml
rm ~/dojo-labs/uFawkesObs/config/prometheus/rules/slo-alerts-payment-api.yml

# Reload Prometheus
curl -X POST http://localhost:9090/-/reload
```

---

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| Recording rules not loading | Syntax error in YAML | `promtool check rules /path/to/rules.yml` |
| Metrics not appearing | Prometheus not scraping | Check `prometheus.yml` scrape config |
| SLO showing 0 | SLI not meeting target | Check SLI query, verify metrics exist |
| Alert not firing | `for:` duration not met | Wait for duration, check `for:` clause |
| Dashboard empty | Datasource not selected | Select Prometheus datasource in panel |

---

## Retrieval Check (Answer Without Looking Back)

Write your answers down — the act of writing (not just thinking) strengthens retention.

1. What is the formula for error budget?
2. How do you calculate burn rate?
3. What does a burn rate of 10x mean?
4. What are the three key SLIs for most services?
5. What's the purpose of multi-window SLOs?

(Suggested answers: 1 = 100% - SLO; 2 = (Error Rate / Error Budget) × Time Window; 3 = Consuming budget 10x faster than sustainable; 4 = Availability, Latency, Error Rate; 5 = Early warning of SLO violations)

---

## Reference: What You Built

| File | Purpose |
|------|---------|
| `sli-recording-payment-api.yml` | SLI recording rules (availability, latency, error rate) |
| `slo-recording-payment-api.yml` | SLO compliance recording rules |
| `error-budget-payment-api.yml` | Error budget remaining, burn rates |
| `slo-alerts-payment-api.yml` | Multi-window burn rate alerts |
| `slo-dashboard-payment.json` | Grafana dashboard with 9 panels |

You've now implemented a complete SLI/SLO/Error Budget system with uFawkesObs — from metric collection to alerting to visualization. This is the foundation for data-driven reliability engineering!

---

➡️ **Next**: Return to [Module 15 README](../README.md), then prepare for the **Brown Belt Assessment**!
