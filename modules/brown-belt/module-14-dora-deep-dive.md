# Module 14: DORA Metrics Deep Dive with uFawkesObs

**Belt Level**: 🟤 Brown Belt
**Duration**: 3-4 hours
**Prerequisites**: Module 13 (Observability with uFawkesObs) complete, uFawkesObs v1.0.0 running with DORA profile enabled
**DORA Capabilities**: All five DORA metrics, Monitoring & Observability, Data-Driven Decision Making

---

## 1. Learning Objectives (5 minutes)

### What You'll Learn

By the end of this module, you will be able to:

- ✅ Calculate and track all five DORA metrics automatically using uFawkesObs DORA profile
- ✅ Build comprehensive DORA dashboards in Grafana using uFawkesObs datasources
- ✅ Implement metric collection across the entire delivery pipeline with uFawkesPipe/Score Service
- ✅ Analyze trends and identify improvement opportunities with uFawkesObs
- ✅ Benchmark against industry standards using uFawkesObs metrics
- ✅ Use metrics to drive platform improvements
- ✅ Present DORA metrics to leadership effectively

### Why It Matters

**The Observability Gap**

```
Traditional monitoring:
  ↓
  "Something is broken" → Scramble to find root cause
  Reactive, slow, stressful

Observability with DORA metrics:
  ↓
  "Here's what changed" → Targeted fix in minutes
  Proactive, fast, confident
```

**Why Brown Belt?**

You've mastered CI/CD (Yellow Belt), deployment (Green Belt), and observability (Module 13). Now you need to **measure and improve** delivery performance using the industry-standard DORA metrics — the lens that turns metrics into decisions.

### Success Criteria

You've mastered this module when you can:

- Deploy and configure uFawkesObs DORA profile (`make up-dora`)
- Configure DORA event emission from uFawkesPipe/Score Service
- Build Grafana dashboards for all five DORA metrics using uFawkesObs datasources
- Analyze trends, identify bottlenecks, and correlate metrics
- Present DORA metrics to stakeholders with actionable insights

---

## 2. Theory & Concepts (25 minutes)

### The Five DORA Metrics (Refresher)

| Metric | What It Measures | Elite Performance |
|--------|-------------------|-------------------|
| **Deployment Frequency** | How often you deploy | Multiple per day |
| **Lead Time for Changes** | Commit → Production time | < 1 hour |
| **Change Failure Rate** | % of deployments causing failures | 0-15% |
| **Mean Time to Restore** | Time to recover from failure | < 1 hour |
| **Deployment Rework Rate** | % of deployments caused by incidents | Lower is better |

Deployment Rework Rate measures unplanned deployments made in response to a production incident. DORA groups Deployment Frequency, Change Lead Time, and Failed Deployment Recovery Time as throughput. Change Failure Rate and Deployment Rework Rate measure instability.

### Why These Five?

Research shows these metrics are:

- **Predictive** of organizational performance
- **Balanced** between throughput (DF, LT, FDRT) and instability (CFR, DRR)
- **Actionable** — teams can directly improve them
- **Universal** — apply across industries and tech stacks

### Advanced DORA Concepts

**1. Metric Correlation**

Metrics don't exist in isolation:

```
High Deployment Frequency
    ↓
Smaller batch sizes
    ↓
Lower Change Failure Rate
    ↓
Faster Lead Time (less code per deploy)
    ↓
Better MTTR (easier to identify issues)
```

**2. Team-Level vs Organization-Level**

- **Team-level**: Track individual team performance
- **Organization-level**: Aggregate across all teams
- **Service-level**: Track per microservice/application

**3. Metric Distributions Matter**

Don't just track averages:

- **P50 (Median)**: Typical case
- **P95**: Worst 5% of cases
- **P99**: Outliers that hurt user experience

**Example**:

```
Lead Time:
- Average: 2 hours
- P50: 30 minutes ✅ (Most deploys are fast)
- P95: 8 hours ❌ (5% take too long - investigate why)
```

---

## 3. uFawkesObs DORA Architecture (20 minutes)

### How uFawkesObs Implements DORA

uFawkesObs provides a **self-contained DORA metrics platform** using Docker Compose — no external database required (uses SQLite):

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    uFawkesObs DORA Architecture                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐                 │
│  │   uFawkes    │───▶│  dora-api    │───▶│  SQLite DB   │                 │
│  │   Pipe /     │    │  (Port 8088) │    │  (Events)    │                 │
│  │  Score Svc   │    └──────┬───────┘    └──────────────┘                 │
│  └──────────────┘         │                               │               │
│                           ▼                               │               │
│  ┌─────────────────────────────────────────────────────────────────┐   │
  │                    dora-compute                                  │   │
  │              (Aggregates events → DORA metrics)                 │   │
  │                            │                                    │   │
  │                            ▼                                    │   │
  │  ┌─────────────────────────────────────────────────────────┐   │   │
  │  │              Prometheus (PromQL queries)                  │   │   │
  │  │         PromQL queries → Grafana dashboards               │   │   │
  │  └─────────────────────────────────────────────────────────┘   │   │
  └─────────────────────────────────────────────────────────────────┘   │
                               │                                      │
                               ▼                                      │
                    ┌─────────────────────────────┐                  │
                    │        Grafana              │                  │
                    │   DORA Dashboards (5 panels)│                  │
                    └─────────────────────────────┘                  │
└─────────────────────────────────────────────────────────────────────┘
```

### Key Components

| Component | Role in DORA |
|-----------|--------------|
| **uFawkesPipe / Woodpecker** | Pipeline execution, emits deployment events |
| **Score Service** | Validates specs, triggers pipelines, emits events |
| **dora-api** | Receives deployment events via HTTP, stores in SQLite |
| **dora-compute** | Aggregates raw events → DORA metrics, exposes Prometheus metrics |
| **Pushgateway** | Receives push metrics from short-lived jobs |
| **Prometheus** | Stores time-series metrics, PromQL queries |
| **Grafana** | Dashboards, visualization, alerting UI |
| **Pushgateway** | Receives metrics from short-lived batch jobs |

### DORA Event Flow

```
1. Developer pushes code → Git webhook
2. uFawkesPipe / Woodpecker pipeline runs
3. Pipeline completes → emits deployment event to dora-api
4. dora-api stores event in SQLite
5. dora-compute reads events → computes DORA metrics
6. dora-compute exposes Prometheus metrics
6. Prometheus scrapes metrics → Grafana dashboards
7. Grafana alerts → Alertmanager → notifications
```

### uFawkesObs DORA Profile

Enable with: `make up-dora`

This starts additional services:
- **dora-api** (port 8088) — HTTP API for receiving deployment events
- **dora-compute** — Background worker computing DORA metrics
- **pushgateway** (port 9091) — Receives metrics from short-lived jobs
- **dora-api** health: `http://localhost:8088/health`
- **dora-api** event endpoint: `POST http://localhost:8088/event`

---

## 4. Calculating DORA Metrics with uFawkesObs (15 minutes)

### How uFawkesObs Computes DORA Metrics

uFawkesObs automates metric calculation via **dora-compute** which reads events from SQLite and exposes Prometheus metrics.

### Event Schema

The dora-api accepts events at `POST /event`:

```json
{
  "event_type": "deployment",
  "service": "my-service",
  "environment": "production",
  "status": "success",
  "timestamp": "2026-10-05T14:30:00Z",
  "commit_sha": "abc123def456",
  "deployed_by": "ci-bot",
  "work_type": "feature"  // or "incident_rework"
}
```

### How Each Metric Is Computed

| Metric | Computation |
|--------|-------------|
| **Deployment Frequency** | `count(deployment_events) / time_window` |
| **Lead Time for Changes** | `deployment_timestamp - commit_timestamp` (from commit SHA in event) |
| **Change Failure Rate** | `failed_deployments / total_deployments` (windowed) |
| **MTTR** | `incident_resolved_timestamp - incident_created_timestamp` |
| **Deployment Rework Rate** | `deployments_with_work_type=incident_rework / total_deployments` |

### Prometheus Metrics Exposed by dora-compute

| Metric Name | Type | Description |
|-------------|------|-------------|
| `dora_deployment_frequency` | Gauge | Deployments per day |
| `dora_lead_time_seconds` | Histogram | Commit → production latency |
| `dora_change_failure_rate` | Gauge | Failure rate (0-1) |
| `dora_mttr_seconds` | Histogram | Incident resolution time |
| `dora_rework_rate` | Gauge | Rework rate (0-1) |

---

## 5. Hands-On Lab (60 minutes)

### Lab Overview

You'll enable the uFawkesObs DORA profile, send test events, and build a complete DORA dashboard in Grafana.

**Time Estimate**: 60 minutes
**Difficulty**: Advanced (Module 13 complete, uFawkesObs running with DORA profile)
**Auto-Graded**: Yes
**Points**: 100

### Lab Environment

**Prerequisites**:
- ✅ Module 13 (Observability with uFawkesObs) complete
- ✅ uFawkesObs v1.0.0 running locally with DORA profile enabled (`make up-dora`)

**Tools required**: `curl`, `jq`, `git`, `make`

---

### Lab Steps

➡️ **[Lab 01: DORA Metrics with uFawkesObs](brown-belt/module-14-dora-deep-dive/lab-01/instructions.md)**

This lab walks you through:
1. **Verifying DORA Profile** — Confirm dora-api, dora-compute, pushgateway are running
2. **Sending Test Events** — POST deployment events to dora-api
3. **Verifying Metrics** — Query Prometheus for DORA metrics
3. **Building Dashboard** — Create Grafana dashboard with all 5 DORA metrics
4. **Testing Failure Scenarios** — Send failed deployment, verify CFR increases
4. **Testing Rework** — Send incident-driven deployment, verify rework rate
4. **Building Executive Dashboard** — Create executive summary dashboard
4. **Validation** — Run validation script checking all metrics

**Runs against**: [uFawkesObs v1.0.0](https://github.com/paruff/uFawkesObs/releases/tag/v1.0.0) with DORA profile

**Validation**: `bash brown-belt/module-14-dora-deep-dive/lab-01/validate.sh`

---

## 5. Knowledge Check (10 minutes)

### Quiz: DORA Metrics Deep Dive

**Instructions**: Answer all 10 questions. You need 8/10 (80%) to pass. Unlimited attempts allowed.

#### Question 1

**What does P95 lead time represent?**

- [ ] A) Average lead time
- [ ] B) Fastest lead time
- [x] C) 95% of deployments complete within this time
- [ ] D) Slowest lead time

**Explanation**: P95 means 95% of deployments complete within this time — the remaining 5% took longer.

---

#### Question 2

**How do you calculate Change Failure Rate?**

- [ ] A) Failed deployments × 100
- [x] B) (Failed deployments / Total deployments) × 100
- [ ] C) Total deployments / Failed deployments
- [ ] D) Failed deployments / Successful deployments

**Explanation**: CFR = (Failed deployments / Total deployments) × 100 — percentage of deployments that failed.

---

#### Question 3

**What's the Elite benchmark for Deployment Frequency?**

- [ ] A) Once per week
- [ ] B) Once per day
- [x] C) Multiple times per day
- [ ] D) Continuous deployment

**Explanation**: Elite performers deploy **multiple times per day** (DORA research).

---

#### Question 4

**What does MTTR measure?**

- [ ] A) Time to write code
- [ ] B) Time to test
- [x] C) Time to restore service after incident
- [ ] D) Time to deploy

**Explanation**: MTTR = Mean Time to Restore = time from incident detection to service restoration.

---

#### Question 5

**Why track team-level DORA metrics separately?**

- [ ] A) To rank teams
- [x] B) To identify improvement opportunities specific to each team
- [ ] C) To punish low performers
- [ ] D) It's not necessary

**Explanation**: Team-level metrics reveal context (legacy vs greenfield, team size, domain) that organization-level metrics hide.

---

#### Question 6

**What does high DF + low CFR indicate?**

- [ ] A) Luck
- [x] B) Mature CI/CD with good quality gates
- [ ] C) Metrics are broken
- [ ] D) Too much testing

**Explanation**: High deployment frequency with low change failure rate = mature CI/CD pipeline with effective quality gates.

---

#### Question 6

**What does `dora-compute` do in uFawkesObs?**

- [ ] A) Runs the pipelines
- [ ] B) Stores deployment events
- [x] C) Aggregates events → DORA metrics, exposes Prometheus metrics
- [ ] D) Sends notifications

**Explanation**: dora-compute reads events from SQLite, computes DORA metrics, exposes Prometheus metrics for Grafana/Prometheus.

---

#### Question 7

**How do you enable the DORA profile in uFawkesObs?**

- [ ] A) Set `DORA_ENABLED=true` in .env
- [x] B) Run `make up-dora`
- [ ] C) Deploy separate DORA stack
- [ ] D) Configure in Grafana UI

**Explanation**: Run `make up-dora` to start the stack with DORA profile (dora-api, dora-compute, pushgateway).

---

#### Question 7

**What does `stages.image_scan.fail_on: CRITICAL` do?**

- [ ] A) Scans only CRITICAL vulnerabilities
- [ ] B) Ignores CRITICAL vulnerabilities
- [x] C) Fails the build if CRITICAL vulnerabilities found
- [ ] D) Reports only CRITICAL vulnerabilities

**Explanation**: `fail_on: CRITICAL` sets the severity threshold — the build **fails** if any CRITICAL vulnerabilities are found.

---

#### Question 8

**How does uFawkesObs handle artifact retention?**

- [ ] A) Manual cleanup via Harbor UI
- [x] B) `advanced.artifacts.retention` in `.fawkespipe.yml`
- [ ] C) Manual Docker image pruning
- [ ] D) Kubernetes TTL controller

**Explanation**: uFawkesPipe uses `advanced.artifacts.retention` in `.fawkespipe.yml` to configure artifact retention period (in days).

---

#### Question 10

**What happens when `stages.image_scan.fail_on: CRITICAL` is set and a CRITICAL vulnerability is found?**

- [ ] A) Warning logged, pipeline continues
- [x] B) Pipeline fails immediately
- [ ] C) Only logs warning, continues
- [ ] D) Marks image as quarantined

**Explanation**: When `fail_on: CRITICAL` is set and a CRITICAL vulnerability is detected, the **pipeline fails immediately**, preventing the vulnerable image from being promoted.

---

### Quiz Results

**Score: X / 10**

- ✅ **Passed** (8+): Excellent! You understand DORA metrics with uFawkesObs.
- ❌ **Not Yet** (<8): Review the theory section and try again.

**Incorrect answers?** Each question links back to the relevant section for review.

---

## 6. Reflection & Next Steps (5 minutes)

### What You Learned

✅ **You now know**:
- How uFawkesObs implements all five DORA metrics via dora-api/dora-compute
- How to enable DORA profile (`make up-dora`)
- How to send deployment events and query DORA metrics
- How to build Grafana dashboards for all five metrics
- How to analyze trends, identify bottlenecks, and correlate metrics
- How to present DORA metrics to leadership

### How This Connects to Your Work

**For Developers**:
- You can now instrument your pipelines to emit DORA events automatically
- You understand what the metrics mean and how to improve them

**For Platform Engineers**:
- You can deploy and operate the uFawkesObs DORA stack
- You can help teams interpret their metrics and drive improvements

**For Leaders**:
- You can now track delivery performance with industry-standard metrics
- You can make data-driven decisions about platform investments

### Reflection Questions

1. **What surprised you most about DORA metrics in uFawkesObs?**
2. **How does your current observability compare?**
3. **What bottleneck would you tackle first in your pipeline?**
4. **Who on your team should go through this module?**

### Preview: Green Belt

**Next Up: GitOps & Progressive Delivery (Green Belt Modules 9-12)**

In Green Belt, you'll learn:
- GitOps with ArgoCD (declarative deployments)
- Deployment strategies (blue-green, canary, rolling)
- Progressive delivery with Flagger
- Rollback & incident response

**Time**: 4 modules × 3-4 hours each
**Prerequisites**: Brown Belt complete ✅

---

## Module Completion

### ✅ You've Completed Module 14

**Next Steps**:

1. ✅ Mark this module complete in your Backstage profile
2. 📊 View your progress on the Dojo dashboard
3. 💬 Share your completion in `#dojo-achievements` (optional!)
4. 🎓 **Prepare for Green Belt Assessment** when ready

**Time Investment**: 3-4 hours
**Skills Gained**: DORA metrics automation, advanced PromQL, dashboard design, bottleneck analysis, data-driven improvement
**Progress**: 2 of 4 modules toward Brown Belt (50% complete)

---

**Questions or Issues?**
- 💬 Ask in [GitHub Discussions](https://github.com/paruff/uFawkesDojo/discussions) for `#dojo-brown-belt`
- 📧 Email: dojo@ufawkes.dev
- 🐛 Report bugs: [GitHub Issues](https://github.com/paruff/fawkes/issues)

**Feedback?**
- Rate this module (takes 30 seconds)
- Suggest improvements
- Help us make the dojo better!

---

**Module Author**: Fawkes Learning Team
**Last Updated**: October 2026
**Version**: 2.0
