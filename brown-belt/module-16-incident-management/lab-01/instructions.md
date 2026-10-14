# Lab 01: Full Incident Response Simulation with uFawkesObs

**Module**: Brown Belt — Module 16: Advanced Incident Management
**Estimated Time**: 45 minutes
**Difficulty**: Advanced (Modules 13-15 complete required)
**Runs against**: [uFawkesObs `v1.1.0-rc.1`](https://github.com/paruff/uFawkesObs/releases/tag/v1.1.0-rc.1) (Docker Compose), a **pre-release**

> **Run for real on 2026-10-14 against `v1.1.0-rc.1` (pre-release), through the stack's APIs.** The incident is real: you stop a container, the stack's own `ServiceDown` alert fires, and you investigate with the stack's own metrics and logs. The commands ran verbatim and the outputs are what they printed (your numbers and times will differ). Grafana's browser-only clicks (Explore) were not exercised: the same queries run through the Prometheus, Loki and Alertmanager APIs. The lab moves to the stable tag when uFawkesObs ships it. See the [audit](../../../docs/ai-sdlc/compose-curriculum/audit-2026-10-06.md).

---

## Objectives

By the end of this lab you will have:

1. Caused a real incident and watched the stack detect it (`pending` then `firing`)
2. Assigned incident roles and kept a timeline as you went
3. Investigated with metrics (Prometheus), logs (Loki) and the host (Docker), and found why the loudest signal was not the cause
4. Mitigated, and verified the fix in the same telemetry that found the problem
5. Written a blameless postmortem from your own timeline

---

## Why This Lab Uses uFawkesObs

uFawkesObs ships the whole detect → investigate → verify loop in Docker Compose: **Prometheus** (metrics, alert rules), **Alertmanager** (routing), **Loki** (logs, collected by **Alloy**), **Tempo** (traces) and **Grafana** (one place to look). It also ships a `ServiceDown` alert (`up == 0` for 2 minutes), which is what this lab trips. No Kubernetes required.

---

## Prerequisites

**Required**: the uFawkesObs stack from Module 13, running at `v1.1.0-rc.1`

```bash
cd ~/dojo-labs/uFawkesObs
make status
```

**Expected**: every container `Up`, and every health endpoint `✅`.

**Required**: Modules 13, 14, 15 completed

**Tools required**: `curl`, `jq`, `docker compose`

---

## Step 0 — Read the Theory First (if you haven't)

This lab assumes you've read the [Module 16 theory](../README.md#theory--concepts-20-minutes) up through "Incident Command System (ICS)". You should be able to name the incident lifecycle phases, ICS roles, and RCA methods.

---

## Step 1 — Detect & Triage (5 minutes)

### 1.1 Cause the incident

Start a notes file now. The timeline for your postmortem is whatever you write down as it happens:

```bash
echo "$(date -u +%H:%M:%S) UTC  incident start: stopping node-exporter" | tee ~/dojo-labs/incident-timeline.txt
docker compose stop node-exporter
```

(You are playing both the person who breaks it and the person who responds. In a real incident you would not know the cause yet. Try to investigate as if you did not.)

### 1.2 Watch the alert arrive

Prometheus scrapes every 15 seconds and the `ServiceDown` rule waits two minutes (`for: 2m`) before firing. Watch the state change:

```bash
for i in $(seq 1 150); do
  s=$(curl -s --data-urlencode 'query=ALERTS{alertname="ServiceDown"}' http://localhost:9090/api/v1/query \
    | jq -r '.data.result[] | "\(.metric.job) \(.metric.alertstate)"' | tr '\n' ' ')
  [ "$s" = "${last:-}" ] || { echo "t+${i}s: $s"; last="$s"; }
  sleep 1
done
```

**Expected**: roughly `t+26s: node-exporter pending`, then `t+141s: node-exporter firing`. Note both times in your timeline file.

### 1.3 Observe the alert in Alertmanager

```bash
curl -s http://localhost:9093/api/v2/alerts \
  | jq -c '.[] | select(.labels.alertname=="ServiceDown") | {job: .labels.job, severity: .labels.severity, state: .status.state, receivers: [.receivers[].name]}'
```

**Expected**: `{"job":"node-exporter","severity":"critical","state":"active","receivers":["critical-alerts"]}`. The alert is routed to `critical-alerts` because its severity is `critical`. Open **http://localhost:9093** to see the same alert in the UI.

> ✅ **Checkpoint**: `ServiceDown` is firing in Alertmanager with severity `critical`. You can say how long detection took, and why (the rule's `for: 2m`).

---

## Step 2 — Triage & Incident Command (5 minutes)

### 2.1 Assume the Incident Commander role

In a real incident you would acknowledge the alert, open a war room channel and bring in a Technical Lead, a Communications Lead and a Scribe. Record the assignment (the heredoc is unquoted, so the time is filled in):

```bash
cat > ~/dojo-labs/incident-roles.md <<EOF
# Incident: ServiceDown on node-exporter
# Declared: $(date -u +%Y-%m-%dT%H:%M:%SZ) UTC

Incident Commander: @you
Technical Lead: @yourself
Communications Lead: @yourself
Scribe: @yourself
EOF
echo "$(date -u +%H:%M:%S) UTC  alert acknowledged, roles assigned" >> ~/dojo-labs/incident-timeline.txt
```

### 2.2 Decide the severity

`critical` is the alert's label, not your judgement. Ask what is broken for users: node-exporter feeds host CPU, memory and disk metrics. No user-facing request fails. Call it **SEV3** (monitoring degraded, no customer impact) and write down why. Severity is the commander's call, and the alert's label is one input to it.

> ✅ **Checkpoint**: Roles assigned and a severity chosen, with a reason.

---

## Step 3 — Investigation (15 minutes)

Work from the alert inwards. Add a line to your timeline file as you learn each thing.

### 3.1 Metrics: what does Prometheus say?

```bash
curl -s --data-urlencode 'query=up == 0' http://localhost:9090/api/v1/query \
  | jq -c '.data.result[] | {job: .metric.job, instance: .metric.instance}'
curl -s http://localhost:9090/api/v1/targets \
  | jq -c '.data.activeTargets[] | select(.labels.job=="node-exporter") | {health, lastError}'
```

**Expected**: one target down, `node-exporter`, and an error like `dial tcp: lookup node-exporter on 127.0.0.11:53: no such host`.

Read the error: Docker's DNS no longer knows the name `node-exporter`. A container that crashed and is restarting would usually still resolve. This one is **gone from the network**.

### 3.2 Logs: what did the service say?

Alloy ships every container's logs to Loki. Pull the last lines from the dead container (here with the Loki API; in Grafana use **Explore → Loki** with the same query):

```bash
curl -s -G http://localhost:3100/loki/api/v1/query_range \
  --data-urlencode 'query={container="/node-exporter"}' --data-urlencode 'limit=3' \
  --data-urlencode "start=$(( $(date +%s) - 1800 ))000000000" \
  | jq -r '.data.result[].values[][1]' | head -3 | cut -c1-200
```

**Expected**: lines like `level=error ... write: connection reset by peer`. Now count errors across the stack:

```bash
curl -s -G http://localhost:3100/loki/api/v1/query \
  --data-urlencode 'query=sum by (container) (count_over_time({service_name=~".+"} |~ "(?i)level=error" [30m]))' \
  | jq -c '[.data.result[] | {container: .metric.container, errors: .value[1]}]'
```

**Expected**: `/node-exporter` has thousands of error lines, far more than anything else.

**Pause here.** It looks like the cause. It is not: those `connection reset by peer` lines are old (look at the timestamps; they stop when the container stopped) and come from health checks hanging up. A noisy log is not a cause. A log that **ends** is a clue: the container did not log a crash or a panic before it stopped.

### 3.3 Traces: is there a request path to follow?

```bash
curl -s "http://localhost:3200/api/search?limit=5"
```

**Expected**: `{"traces":[],"metrics":{...}}`. Nothing in this stack sends traces, so Tempo is empty, and for this incident that is the right answer: a monitoring agent that just vanished has no request path to trace. Know what each pillar can and cannot tell you.

### 3.4 The host: what happened to the container?

```bash
docker compose ps -a node-exporter --format '{{.Name}}  {{.Status}}'
docker inspect node-exporter --format 'status={{.State.Status}} exit={{.State.ExitCode}} oom={{.State.OOMKilled}} finished={{.State.FinishedAt}}'
```

**Expected**: `Exited (143)`, `oom=false`, and a `finished` time that matches the moment your logs stop. Exit code 143 is 128 + 15: the container received **SIGTERM** (a polite stop), it was not killed for memory and it did not crash.

### 3.5 Conclude

Write the finding in your timeline file: *node-exporter was stopped (SIGTERM, exit 143), not crashed; nothing restarted it.* That is the root cause of the **alert**. The root cause of the **incident**, why it was stopped, is a postmortem question (here: you did it, but a real answer might be a deploy, an operator, or an orchestrator policy).

> ✅ **Checkpoint**: You can state what happened, name the evidence (the DNS error, the log that ended, exit 143), and say why the error-count query led you the wrong way.

---

## Step 4 — Mitigation & Resolution (10 minutes)

### 4.1 Restore the service

```bash
echo "$(date -u +%H:%M:%S) UTC  mitigation: starting node-exporter" >> ~/dojo-labs/incident-timeline.txt
docker compose start node-exporter
```

### 4.2 Verify in the same telemetry

```bash
for i in $(seq 1 40); do
  v=$(curl -s --data-urlencode 'query=up{job="node-exporter"}' http://localhost:9090/api/v1/query | jq -r '.data.result[0].value[1]')
  [ "$v" = 1 ] && { echo "up=1 at +${i}s"; break; }
  sleep 1
done
```

**Expected**: `up=1 at +5s` or thereabouts.

Then wait for the alert itself to clear. It stays `firing` until Prometheus next evaluates the rule:

```bash
for i in $(seq 1 60); do
  n=$(curl -s -G http://localhost:9090/api/v1/query --data-urlencode 'query=ALERTS{alertname="ServiceDown",alertstate="firing"}' | jq '.data.result | length')
  [ "$n" = 0 ] && { echo "ServiceDown cleared"; break; }
  sleep 2
done
echo "$(date -u +%H:%M:%S) UTC  resolved: up=1, alert cleared" >> ~/dojo-labs/incident-timeline.txt
```

> ✅ **Checkpoint**: `up` is 1 and the alert has cleared. "Fixed" means the telemetry that raised the alarm now says so, not that the command ran.

---

## Step 5 — Postmortem (10 minutes)

Write a blameless postmortem from your timeline file. The template below has `<fill in …>` markers. Replace every one of them; the validation script rejects the file while any remain.

### 5.1 Create the postmortem

```bash
cat ~/dojo-labs/incident-timeline.txt
cat > ~/dojo-labs/postmortem-$(date -u +%Y%m%d).md <<'EOF'
# Postmortem: node-exporter stopped, ServiceDown fired

**Date**: <fill in date>
**Duration**: <fill in minutes from start to resolved>
**Severity**: <fill in the severity you chose, and why>
**Impact**: <fill in what stopped working, and for whom>

## Timeline

| Time (UTC) | Event |
|------------|-------|
| <fill in> | Incident start |
| <fill in> | Alert `pending` |
| <fill in> | Alert `firing`, routed to `critical-alerts` |
| <fill in> | Acknowledged, roles assigned |
| <fill in> | Root cause found |
| <fill in> | Mitigation applied |
| <fill in> | Resolved: `up` back to 1 |

## Root Cause

**Primary**: <fill in: what happened to the container, with the evidence>

**Contributing factors**:
1. <fill in>

## Root Cause Analysis (5 Whys)

1. **Why** did the alert fire? → <fill in>
2. **Why** was the target down? → <fill in>
3. **Why** was the container stopped? → <fill in>
4. **Why** did nothing restart it? → <fill in>
5. **Why** is that acceptable (or not)? → <fill in>

## Resolution

<fill in: what you did and how you verified it>

## What Went Well
- <fill in>

## What Went Wrong
- <fill in: for example, the loudest log was a red herring; detection took two minutes by design>

## Action Items

| Action | Owner | Deadline | Status |
|--------|-------|----------|--------|
| <fill in> | <fill in> | <fill in> | ☐ |

## Lessons Learned

1. <fill in>
EOF
```

Open the file and fill it in. Write about the system, not about a person: assume everyone acted on what they knew at the time, and ask what let the failure happen.

> ✅ **Checkpoint**: Postmortem written, every placeholder replaced.

---

## Step 6 — Run Validation Script

```bash
# From your uFawkesDojo checkout
UF_OBS_DIR=~/dojo-labs/uFawkesObs bash brown-belt/module-16-incident-management/lab-01/validate.sh
```

**Expected output** (all checks pass):

```
[✓] Prerequisites: curl, jq, git, make, docker installed
[✓] uFawkesObs Stack: All 8 core services healthy
[✓] Alert Pipeline: ServiceDown rule is loaded and Alertmanager answers
[✓] Grafana Datasources: Prometheus, Loki, Tempo and Alertmanager are configured
[✓] Loki Logs: <n> node-exporter log lines in the last 24h
[✓] Tempo: trace search answers (it may well return no traces: see Step 3.3)
[✓] Service Restored: up{job="node-exporter"} = 1
[✓] Postmortem Document: postmortem-<date>.md has all 6 sections and no '<fill in' placeholders left

Total Tests : 8
Passed      : 8
Failed      : 0
```

---

## Clean Up

```bash
cd ~/dojo-labs/uFawkesObs
docker compose start node-exporter    # in case it is still stopped
rm -f ~/dojo-labs/incident-roles.md ~/dojo-labs/incident-timeline.txt ~/dojo-labs/postmortem-*.md
```

`make down` does not stop this stack at this version: it runs `docker compose down` without the profiles the stack started with ([uFawkesObs#617](https://github.com/paruff/uFawkesObs/issues/617)). To stop it, use `docker compose --profile '*' down`.

---

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| Alert never leaves `pending` | The `for: 2m` has not run out | Wait; it fires about two minutes after the first scrape that failed |
| No `ServiceDown` in Alertmanager | Alert not yet `firing`, or routed elsewhere | `curl -s http://localhost:9093/api/v2/alerts \| jq .`; check Prometheus `/alerts` |
| No logs in Loki | Alloy not collecting | `docker compose logs alloy` |
| Loki query returns nothing | Query window starts after the logs stopped | Widen `start`, or use `[30m]` instead of `[5m]` |
| Validation: Grafana datasources fail | No Grafana password found | `export GRAFANA_PASSWORD=...` (it is in `.env`) or set `UF_OBS_DIR` |
| Validation: postmortem fails | A `<fill in` marker is left, or a section is missing | `grep -n 'fill in' ~/dojo-labs/postmortem-*.md` |

---

## Retrieval Check (Answer Without Looking Back)

Write your answers down — the act of writing (not just thinking) strengthens retention.

1. What are the 4 ICS roles in incident response?
2. Which uFawkesObs component collects container logs and ships them to Loki?
3. Why did detection take about two minutes, and what would shorten it?
4. Why was the loudest log line not the root cause?
5. What makes a postmortem "blameless"?

(Suggested answers: 1 = Incident Commander, Technical Lead, Communications Lead, Scribe; 2 = Alloy; 3 = the rule's `for: 2m`; a shorter `for:` detects faster but pages on blips; 4 = it was old noise from health checks, and the useful clue was a log that ended, plus exit code 143; 5 = it looks at systems and process, assumes good intent, and asks what allowed the failure)

---

## Reference: What You Used

| Component | Purpose |
|-----------|---------|
| **Prometheus** | `up`, the `ServiceDown` rule, scrape target errors |
| **Alertmanager** | Routing the alert to `critical-alerts` |
| **Loki** | The container's logs, and an error count that misled |
| **Tempo** | Confirming there was no request path to trace |
| **Alloy** | Collecting container logs into Loki |
| **Docker** | Exit code 143, the evidence for what happened to the container |
| **Grafana** | The place you would run the same queries in Explore |

---

## What You've Accomplished

- ✅ **Detected** a real incident through the stack's own alerting
- ✅ **Triaged** with ICS roles and a severity you argued for
- ✅ **Investigated** with metrics, logs and the host, and caught a misleading signal
- ✅ **Mitigated** and **verified** in the telemetry that raised the alarm
- ✅ **Documented** a blameless postmortem built from your own timeline

---

➡️ **Next**: Return to [Module 16 README](../README.md), then prepare for the **Brown Belt Assessment**!
