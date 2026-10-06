# Module 14: DORA Metrics Deep Dive with uFawkesObs

**Belt Level**: 🟤 Brown Belt
**Estimated Time**: 3-4 hours (25 min theory + 60 min lab + 10 min quiz)
**Prerequisites**: Module 13 completed, uFawkesObs v1.0.0 running with DORA profile
**DORA Capability**: All five DORA metrics, Monitoring & Observability, Data-Driven Decision Making

---

## Learning Objectives

By the end of this module, you will be able to:

- ✅ Calculate and track all five DORA metrics automatically using uFawkesObs DORA profile
- ✅ Build comprehensive DORA dashboards in Grafana using uFawkesObs datasources
- ✅ Implement metric collection across the entire delivery pipeline with uFawkesPipe/Score Service
- ✅ Analyze trends and identify improvement opportunities
- ✅ Benchmark against industry standards
- ✅ Use metrics to drive platform improvements
- ✅ Present DORA metrics to leadership effectively

---

## Module Structure

| Section       | Time   | Description                                         |
| ------------- | ------ | --------------------------------------------------- |
| Theory        | 25 min | DORA metrics refresher, uFawkesObs DORA architecture |
| Architecture  | 15 min | dora-api in-process compute, event flow, scrape    |
| Calculations  | 15 min | How each metric is computed in uFawkesObs          |
| Lab 01        | 60 min | Deploy DORA profile, send events, build dashboard   |
| Quiz          | 10 min | 10-question knowledge check                        |

---

## Theory Summary (25 minutes)

### The Five DORA Metrics (Refresher)

| Metric | What It Measures | Elite Performance |
|--------|-------------------|-------------------|
| **Deployment Frequency** | How often you deploy | Multiple per day |
| **Lead Time for Changes** | Commit → Production time | < 1 hour |
| **Change Failure Rate** | % of deployments causing failures | 0-15% |
| **Mean Time to Restore** | Time to recover from failure | < 1 hour |
| **Deployment Rework Rate** | % of deployments caused by incidents | Lower is better |

### uFawkesObs DORA Architecture

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
│  │        dora-api — in-process compute loop                        │   │
│  │              (Aggregates events → DORA metrics)                 │   │
│  │                            │                                    │   │
│  │                            ▼                                    │   │
│  │  ┌─────────────────────────────────────────────────────────┐   │   │
│  │  │              Prometheus (PromQL queries)                  │   │   │
│  │  │         PromQL queries → Grafana dashboards               │   │   │
│  │  └─────────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                               │                                      │
│                               ▼                                      │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                        Grafana                                   │   │
│  │   DORA Dashboards (5 panels)                                    │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

### Key Components

| Component | Role in DORA |
|-----------|--------------|
| **dora-api** | Receives deployment events via HTTP, stores in SQLite, computes DORA metrics in-process, exposes them on `/metrics` |
| **Prometheus** | Scrapes `dora-api:8088/metrics`, stores time-series metrics, PromQL queries |
| **Grafana** | Dashboards, visualization, alerting UI |

---

## Lab

➡️ **[Lab 01: DORA Metrics with uFawkesObs](brown-belt/module-14-dora-deep-dive/lab-01/instructions.md)**

This lab walks you through:
1. Verifying DORA profile is running (`make up-dora`)
2. Sending deployment events to dora-api
3. Querying DORA metrics via PromQL
4. Building Grafana dashboard with all 5 DORA metrics
5. Testing failure/recovery scenarios
5. Configuring DORA-specific alerting

**Runs against**: uFawkesObs v1.0.0 (not released yet) with DORA profile

> **Written ahead of its stack, not yet run for real.** uFawkesObs v1.0.0 has not been released, so no one has run every step of this lab against it. Treat the steps and the expected output as unverified. See the [audit](../../docs/ai-sdlc/compose-curriculum/audit-2026-10-06.md).

**Prerequisites**: Module 13 completed, uFawkesObs running with `make up-dora`

**Validation**: `bash brown-belt/module-14-dora-deep-dive/lab-01/validate.sh`

---

## Success Criteria

You have mastered this module when you can:

- Deploy uFawkesObs with DORA profile (`make up-dora`)
- Send deployment events to dora-api and verify they're processed
- Query all 5 DORA metrics via PromQL in Grafana
- Build a complete DORA dashboard with all 5 metrics
- Configure alerting on DORA metric thresholds
- Analyze trends and identify bottlenecks

---

## Next Steps

After completing this module, you've completed all Brown Belt modules:

➡️ **Brown Belt Assessment** — Deploy 2 additional applications, written exam, troubleshooting scenario
