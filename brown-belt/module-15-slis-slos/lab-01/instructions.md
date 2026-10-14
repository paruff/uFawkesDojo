# Lab 01: Implementing SLIs, SLOs, and Error Budgets with uFawkesObs

**Module**: Brown Belt — Module 15: SLIs, SLOs, and Error Budgets
**Estimated Time**: 45 minutes
**Difficulty**: Advanced (Modules 13-14 complete required)
**Runs against**: [uFawkesObs `v1.1.0-rc.1`](https://github.com/paruff/uFawkesObs/releases/tag/v1.1.0-rc.1) (Docker Compose), a **pre-release**

> **Run for real on 2026-10-14 against `v1.1.0-rc.1` (pre-release), through the stack's APIs.** Every rule, query and command below ran verbatim, and the outputs are what they printed (your numbers will differ). Grafana's browser-only clicks were not exercised: the dashboard is imported through Grafana's API. The lab moves to the stable tag when uFawkesObs ships it. See the [audit](../../../docs/ai-sdlc/compose-curriculum/audit-2026-10-06.md).

---

## Objectives

By the end of this lab you will have:

1. Written SLI recording rules (availability and latency) for a real service
2. Set an SLO target and derived its error budget and burn rate
3. Configured multi-window burn rate alerts
4. Spent error budget on purpose, and watched the burn rate and the alerts react
5. Imported a Grafana SLO dashboard
6. Practiced SLO-driven deployment decisions

---

## Why This Lab Uses uFawkesObs

uFawkesObs ships Prometheus, Grafana and Alertmanager in Docker Compose, and Prometheus already scrapes every service in it. The stack ships **no SLO rules**, so you write them. The service you measure is **Grafana's own HTTP API**: it is running, it is scraped (`grafana_http_request_duration_seconds_*`), and you can make it fail on demand by stopping Loki, one of its datasources. No Kubernetes required.

---

## Prerequisites

**Required**: the uFawkesObs stack from Module 13, running at `v1.1.0-rc.1`

```bash
cd ~/dojo-labs/uFawkesObs
make status
```

**Expected**: every container `Up`, and every health endpoint `✅`.

**Required**: Modules 13 & 14 completed

**Tools required**: `curl`, `jq`, `docker compose`

Set the Grafana password once for this shell (it is in `.env`):

```bash
export GRAFANA_PASSWORD=$(grep -E '^GRAFANA_ADMIN_PASSWORD=' .env | cut -d= -f2-)
```

---

## Step 0 — Read the Theory First (if you haven't)

This lab assumes you've read the [Module 15 theory](../README.md#theory--concepts-30-minutes) up through "Error Budget Policies". You should be able to define SLI, SLO and error budget, and explain burn rate.

---

## Step 1 — Meet the Service and Its Metrics (5 minutes)

### 1.1 See what the stack already watches

```bash
ls config/prometheus/rules/
```

**Expected**: `ai-rules.yml`, `ufawkesobs-dora-metrics.yml`, `ufawkesobs-dora-regression.yml`, `ufawkesobs-self-monitoring.yml`. Nothing about SLOs. That is your job.

### 1.2 Look at the raw material

Grafana counts every HTTP request it answers, by status code, and times it in a histogram:

```bash
curl -s --data-urlencode 'query=sum by (status_code) (grafana_http_request_duration_seconds_count)' \
  http://localhost:9090/api/v1/query | jq -r '.data.result[] | "\(.metric.status_code)  \(.value[1])"'
```

**Expected**: one line per status code, for example `200  46` and `302  8`. The numbers are counters since Grafana started.

An **SLI** is a ratio of good events to all events. Two come out of this data:

- **Availability**: requests that did not answer `5xx`, divided by all requests
- **Latency**: requests answered in 500 ms or less (the `le="0.5"` histogram bucket), divided by all requests

> ✅ **Checkpoint**: You can see the status-code counters, and say which events are "good" for each SLI.

---

## Step 2 — Add SLI Recording Rules (10 minutes)

### 2.1 Create the rules file

```bash
cat > config/prometheus/rules/dojo-slo-rules.yml <<'EOF'
groups:
  - name: dojo-sli-recording
    interval: 15s
    rules:
      # SLI 1: availability = share of requests that did not answer 5xx
      - record: sli:grafana_api:availability:ratio_5m
        expr: |
          1 - (
            (sum(rate(grafana_http_request_duration_seconds_count{status_code=~"5.."}[5m])) or vector(0))
            / sum(rate(grafana_http_request_duration_seconds_count[5m]))
          )
      - record: sli:grafana_api:availability:ratio_1h
        expr: |
          1 - (
            (sum(rate(grafana_http_request_duration_seconds_count{status_code=~"5.."}[1h])) or vector(0))
            / sum(rate(grafana_http_request_duration_seconds_count[1h]))
          )
      # SLI 2: latency = share of requests answered in 500 ms or less
      - record: sli:grafana_api:latency_500ms:ratio_5m
        expr: |
          sum(rate(grafana_http_request_duration_seconds_bucket{le="0.5"}[5m]))
          / sum(rate(grafana_http_request_duration_seconds_count[5m]))
EOF
```

The `or vector(0)` matters: with no `5xx` at all the numerator would be empty and the whole SLI would vanish instead of reading 100%.

### 2.2 Apply the rules

Prometheus loads only the files named under `rule_files`:

```bash
sed -i.bak 's#^  - "/etc/prometheus/rules/ufawkesobs-dora-regression.yml"#&\n  - "/etc/prometheus/rules/dojo-slo-rules.yml"#' config/prometheus/prometheus.yaml
docker compose exec -T prometheus promtool check rules /etc/prometheus/rules/dojo-slo-rules.yml
curl -s -o /dev/null -w "reload HTTP %{http_code}\n" -X POST http://localhost:9090/-/reload
```

**Expected**: `SUCCESS: 3 rules found` and `reload HTTP 200`.

### 2.3 Send steady traffic and verify

An SLI needs traffic. Start a background loop that calls Grafana once a second for ten minutes:

```bash
( for i in $(seq 1 600); do curl -s -o /dev/null -u "admin:$GRAFANA_PASSWORD" http://localhost:3000/api/health; sleep 1; done ) &
```

Wait about a minute, then:

```bash
for q in sli:grafana_api:availability:ratio_5m sli:grafana_api:latency_500ms:ratio_5m; do
  curl -s --data-urlencode "query=$q" http://localhost:9090/api/v1/query | jq -r '.data.result[0].value[1]'
done
```

**Expected**: `1` and `1`. Everything succeeded and everything was fast.

> ✅ **Checkpoint**: Both SLIs read 1 (100%).

---

## Step 3 — Set the SLO and Derive the Error Budget (10 minutes)

An **SLO** is a target for an SLI. Choose **99.5%** availability. The **error budget** is what the target leaves over: `1 - 0.995 = 0.5%` of requests may fail. The **burn rate** says how fast you spend it: `(1 - SLI) / (1 - target)`. A burn rate of 1 spends the budget exactly as fast as the window refills it; 10 spends it ten times too fast.

### 3.1 Append the budget rules

```bash
cat >> config/prometheus/rules/dojo-slo-rules.yml <<'EOF'

  - name: dojo-slo-error-budget
    interval: 15s
    rules:
      # The SLO target is a number you choose; 99.5% leaves a 0.5% error budget
      - record: slo:grafana_api:availability:target
        expr: vector(0.995)
      # Burn rate: how fast the budget is spent. 1 = exactly on budget.
      - record: error_budget:grafana_api:availability:burn_rate_5m
        expr: (1 - sli:grafana_api:availability:ratio_5m) / (1 - slo:grafana_api:availability:target)
      - record: error_budget:grafana_api:availability:burn_rate_1h
        expr: (1 - sli:grafana_api:availability:ratio_1h) / (1 - slo:grafana_api:availability:target)
EOF
docker compose exec -T prometheus promtool check rules /etc/prometheus/rules/dojo-slo-rules.yml
curl -s -o /dev/null -w "reload HTTP %{http_code}\n" -X POST http://localhost:9090/-/reload
```

**Expected**: `SUCCESS: 6 rules found` and `reload HTTP 200`.

### 3.2 Verify

After about a minute:

```bash
curl -s --data-urlencode 'query=error_budget:grafana_api:availability:burn_rate_5m' \
  http://localhost:9090/api/v1/query | jq -r '.data.result[0].value[1]'
```

**Expected**: `0`. No failures, no budget spent.

> ✅ **Checkpoint**: Burn rate reads 0, and you can explain why `0.5%` is the budget.

---

## Step 4 — Configure Multi-Window Burn Rate Alerts (10 minutes)

One window is a bad alarm: a short one flaps on blips, a long one reacts late. Require **both** windows to burn fast before paging.

### 4.1 Append the alert rules

```bash
cat >> config/prometheus/rules/dojo-slo-rules.yml <<'EOF'

  - name: dojo-slo-alerts
    interval: 15s
    rules:
      # Multi-window: both the short and the long window must burn fast
      - alert: DojoAvailabilityFastBurn
        expr: |
          error_budget:grafana_api:availability:burn_rate_5m > 14.4
          and error_budget:grafana_api:availability:burn_rate_1h > 14.4
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Grafana API is spending its error budget 14x too fast"
          description: "5m burn rate {{ $value | printf \"%.1f\" }}x"
      - alert: DojoAvailabilitySlowBurn
        expr: |
          error_budget:grafana_api:availability:burn_rate_5m > 1
          and error_budget:grafana_api:availability:burn_rate_1h > 1
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "Grafana API is spending its error budget faster than it earns it"
          description: "5m burn rate {{ $value | printf \"%.1f\" }}x"
EOF
docker compose exec -T prometheus promtool check rules /etc/prometheus/rules/dojo-slo-rules.yml
curl -s -o /dev/null -w "reload HTTP %{http_code}\n" -X POST http://localhost:9090/-/reload
```

**Expected**: `SUCCESS: 8 rules found` and `reload HTTP 200`.

(`14.4` is the standard fast-burn threshold: at that rate a 30-day budget is gone in about two days. These windows are short so the lab can show you the result in minutes; production uses longer ones.)

### 4.2 Verify

Open **http://localhost:9090/alerts** and find `DojoAvailabilityFastBurn` and `DojoAvailabilitySlowBurn`, both **inactive**.

> ✅ **Checkpoint**: Both alerts are loaded and inactive.

---

## Step 5 — Spend Some Error Budget (10 minutes)

Stop Loki. Grafana then answers `502` whenever something asks it for Loki data, and each `502` is a failed request:

```bash
docker compose stop loki
for i in $(seq 1 130); do
  curl -s -o /dev/null -u "admin:$GRAFANA_PASSWORD" http://localhost:3000/api/health
  curl -s -o /dev/null -u "admin:$GRAFANA_PASSWORD" http://localhost:3000/api/datasources/proxy/uid/loki/loki/api/v1/labels
  sleep 1
done
```

That is one good request and one `502` every second, about 130 seconds in all. Then:

```bash
for q in sli:grafana_api:availability:ratio_5m error_budget:grafana_api:availability:burn_rate_5m error_budget:grafana_api:availability:burn_rate_1h; do
  curl -s --data-urlencode "query=$q" http://localhost:9090/api/v1/query | jq -r '.data.result[0].value[1]'
done
curl -s --data-urlencode 'query=ALERTS{alertname=~"Dojo.*Burn"}' http://localhost:9090/api/v1/query \
  | jq -r '.data.result[] | "\(.metric.alertname) \(.metric.alertstate)"'
```

**Expected** (roughly): availability near `0.74`, burn rates near `50`, and both alerts `firing` (or `pending` for a minute or two first). Your numbers depend on how long the loop ran.

Bring Loki back:

```bash
docker compose start loki
```

> ✅ **Checkpoint**: You turned a failure into a number, and the number into an alert.

---

## Step 6 — Import a Grafana SLO Dashboard (5 minutes)

The dashboard JSON sits next to this file: six panels (the two SLIs, the 1h burn rate, the target, burn rate over time, and requests by status code).

```bash
curl -s -u "admin:$GRAFANA_PASSWORD" -X POST http://localhost:3000/api/dashboards/db \
  -H 'Content-Type: application/json' \
  -d @/path/to/uFawkesDojo/brown-belt/module-15-slis-slos/lab-01/slo-dashboard.json
```

**Expected**: `{"status":"success","uid":"dojo-slo-grafana-api",...}`

Open **http://localhost:3000/d/dojo-slo-grafana-api**. The burn rate panel shows the spike from Step 5.

> ✅ **Checkpoint**: The dashboard shows your SLIs, the target, and the spike.

---

## Step 7 — Practice SLO-Driven Decisions (10 minutes)

Use the live numbers, not a story. Ask the two questions an SLO exists to answer:

```bash
# Is the service meeting its SLO right now?
curl -s --data-urlencode 'query=sli:grafana_api:availability:ratio_1h >= bool slo:grafana_api:availability:target' \
  http://localhost:9090/api/v1/query | jq -r '.data.result[0].value[1]'

# How fast is the budget going?
curl -s --data-urlencode 'query=error_budget:grafana_api:availability:burn_rate_1h' \
  http://localhost:9090/api/v1/query | jq -r '.data.result[0].value[1]'
```

Decide for each case, then check against the framework:

| State | Decision |
|---|---|
| SLO met, burn rate under 2 | **Deploy.** Normal risk, normal pace |
| SLO met, burn rate over 10 | **Hold.** Find the cause first; a deploy now hides it |
| SLO missed, budget spent | **Freeze deploys.** Reliability work only, until the budget refills |

Where were you, by the numbers, right after Step 5? (Burn near 50 and the 1h SLO missed: **freeze**.) Where are you after the traffic has run clean for an hour? (Burn falling toward 0: **deploy** again.)

> ✅ **Checkpoint**: You can state your decision and the number that justifies it.

---

## Step 8 — Run the Validation Script

```bash
# From your uFawkesDojo checkout
UF_OBS_DIR=~/dojo-labs/uFawkesObs bash brown-belt/module-15-slis-slos/lab-01/validate.sh
```

**Expected output** (all checks pass):

```
[✓] Prerequisites: curl, jq, git, make installed
[✓] uFawkesObs Stack: All 8 core services healthy
[✓] SLO Rules: dojo-sli-recording, dojo-slo-error-budget and dojo-slo-alerts are loaded
[✓] SLI Recording: availability=<value> latency_500ms=<value>
[✓] Error Budget: target=0.995 burn_rate_1h=<value>
[✓] SLO Alerts: DojoAvailabilityFastBurn and DojoAvailabilitySlowBurn are loaded
[✓] Grafana SLO Dashboard: dojo-slo-grafana-api has 6 panels

Total Tests : 7
Passed      : 7
Failed      : 0
```

The SLI and burn rate checks need traffic in the last few minutes: keep the Step 2.3 loop running, or restart it.

---

## Clean Up

```bash
cd ~/dojo-labs/uFawkesObs
docker compose start loki    # in case you stopped it and did not restart it
rm config/prometheus/rules/dojo-slo-rules.yml
mv config/prometheus/prometheus.yaml.bak config/prometheus/prometheus.yaml
curl -s -o /dev/null -w "reload HTTP %{http_code}\n" -X POST http://localhost:9090/-/reload
curl -s -u "admin:$GRAFANA_PASSWORD" -X DELETE http://localhost:3000/api/dashboards/uid/dojo-slo-grafana-api
```

(`mv ... .bak` restores the original file. If you also did Module 14 Step 6, its `.bak` may be the one you are holding: keep the stack's original `prometheus.yaml` from git with `git checkout config/prometheus/prometheus.yaml` instead.)

---

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| Rules not loading | Syntax error, or file missing from `rule_files` | `docker compose exec -T prometheus promtool check rules /etc/prometheus/rules/dojo-slo-rules.yml`, then check `prometheus.yaml` |
| SLI query returns nothing | No traffic in the last 5 minutes | Restart the Step 2.3 loop and wait a minute |
| Availability reads 1 after Step 5 | Loki was not stopped, or the proxy call failed to reach Grafana | `docker compose ps loki`; check the `curl` prints no connection error |
| Alert stays `pending` | The `for:` wait has not run out | Keep the failing traffic going for the full `for:` duration |
| Dashboard import returns 401 | Wrong Grafana password | Re-run the `export GRAFANA_PASSWORD=...` line from Prerequisites |
| Dashboard panels empty | No traffic yet | Wait a minute with the Step 2.3 loop running |

---

## Retrieval Check (Answer Without Looking Back)

Write your answers down — the act of writing (not just thinking) strengthens retention.

1. What is the error budget for a 99.5% availability SLO?
2. How do you calculate burn rate?
3. What does a burn rate of 10 mean?
4. Which events were "good" for each of this lab's two SLIs?
5. Why does an alert require both a 5-minute and a 1-hour window to burn?

(Suggested answers: 1 = 0.5% of requests may fail; 2 = (1 - SLI) / (1 - SLO target); 3 = the budget is being spent ten times faster than the window refills it; 4 = availability: answered with anything but 5xx; latency: answered in 500 ms or less; 5 = the short window makes it react fast, the long window stops a brief blip paging anyone)

---

## Reference: What You Built

| File | Purpose |
|------|---------|
| `config/prometheus/rules/dojo-slo-rules.yml` | SLI recording rules, SLO target and burn rates, multi-window burn alerts |
| `slo-dashboard.json` | Grafana dashboard with 6 panels (imported through the API) |

You've now implemented a complete SLI/SLO/Error Budget loop on a real service: metric to ratio, ratio to budget, budget to alert, alert to decision.

---

➡️ **Next**: Return to [Module 15 README](../README.md), then prepare for the **Brown Belt Assessment**!
