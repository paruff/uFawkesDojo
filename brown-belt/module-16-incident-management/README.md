# Module 16: Advanced Incident Management with uFawkesObs

**Belt Level**: 🟤 Brown Belt
**Estimated Time**: 60 minutes (20 min theory + 45 min lab + 10 min quiz)
**Prerequisites**: Module 13 (Observability), Module 14 (DORA), Module 15 (SLIs/SLOs) complete, uFawkesObs v1.0.0 running
**DORA Capability**: Mean Time to Restore (MTTR) - Elite level, Incident Management Process, Postmortem Culture, Learning Organization

---

## Learning Objectives

By the end of this module, you will be able to:

- ✅ Implement advanced incident response frameworks with uFawkesObs
- ✅ Conduct effective incident command and communication using uFawkesObs tooling
- ✅ Perform root cause analysis (RCA) with structured methods (5 Whys, Fishbone, Fault Tree)
- ✅ Design and facilitate blameless postmortems using uFawkesObs data
- ✅ Build incident response automation with uFawkesObs observability stack
- ✅ Design and run chaos engineering experiments on uFawkesObs platform
- ✅ Measure and improve incident management effectiveness

---

## Module Structure

| Section       | Time   | Description                                         |
| ------------- | ------ | --------------------------------------------------- |
| Theory        | 20 min | Incident lifecycle, ICS roles, RCA methods         |
| ICS & Comms   | 15 min | Incident Command System, communication templates   |
| RCA           | 15 min | 5 Whys, Fishbone, Fault Tree, Timeline             |
| Postmortems   | 15 min | Blameless culture, templates, action items         |
| Automation    | 10 min | Detection, creation, remediation, notifications    |
| Chaos Eng     | 10 min | Principles, experiments, GameDays                  |
| Metrics       | 10 min | MTTR, MTTD, MTTI, frequency, repeat rate           |
| Lab 01        | 45 min | Full incident simulation end-to-end                |
| Quiz          | 10 min | 8-question knowledge check                         |

---

## Theory Summary (20 minutes)

### Incident Lifecycle with uFawkesObs

| Phase | Time Target | uFawkesObs Tools |
|-------|-------------|------------------|
| **Detection** | < 5 min | Prometheus alerts, Loki log alerts, Tempo trace anomalies |
| **Triage** | < 2 min | Grafana dashboards, severity assessment |
| **Investigation** | parallel | Loki (LogQL), Tempo (TraceQL), PromQL, Grafana |
| **Mitigation** | < 15 min SEV1 | Docker Compose scale/restart, ConfigMap updates |
| **Resolution** | varies | Grafana verify, Prometheus metrics, Loki logs |
| **Postmortem** | 24-48h | Timeline from Loki/Grafana, RCA, action items |

### uFawkesObs Incident Stack

| Component | Role in Incident Response |
|-----------|---------------------------|
| **Grafana** | War room dashboard, real-time metrics, alerting UI |
| **Prometheus** | Metrics queries, alerting rules, recording rules |
| **Loki** | Log aggregation, LogQL queries, log-based alerts |
| **Tempo** | Distributed tracing, root cause tracing |
| **Alertmanager** | Alert routing, silencing, notification routing |
| **Alloy** | Log collection (replaces Promtail) |
| **OTel Collector** | Telemetry ingestion (OTLP) |

### Incident Command System (ICS) Roles

| Role | Responsibilities | uFawkesObs Tools |
|------|------------------|------------------|
| **Incident Commander (IC)** | Overall coordination, decisions, comms | Grafana war room, Alertmanager, Slack/Teams |
| **Technical Lead (TL)** | Technical investigation, hypothesis testing | Grafana, Prometheus, Loki, Tempo |
| **Communications Lead** | Stakeholder updates, status page | Grafana annotations, status page API |
| **Scribe** | Timeline, decisions, actions | Grafana annotations, GitHub/Gitea issue |

---

## Lab

➡️ **[Lab 01: Full Incident Response Simulation](lab-01/instructions.md)**

This lab walks you through a complete incident response simulation:
1. Detection & triage (alert fires, IC assigned, severity assessed)
2. Investigation (Loki logs, Tempo traces, Prometheus metrics)
3. Mitigation (root cause identified, fix deployed)
6. Resolution & verification (Grafana/Prometheus/Loki)
7. Postmortem (timeline, RCA, action items in uFawkesObs format)

**Runs against**: uFawkesObs v1.0.0 (not released yet) (Docker Compose)

> **Written ahead of its stack, not yet run for real.** uFawkesObs v1.0.0 has not been released, so no one has run every step of this lab against it. Treat the steps and the expected output as unverified. See the [audit](../../docs/ai-sdlc/compose-curriculum/audit-2026-10-06.md).

**Prerequisites**: Module 13 (Observability), Module 14 (DORA), Module 15 (SLI/SLO) complete

**Validation**: `bash brown-belt/module-16-incident-management/lab-01/validate.sh`

---

## Success Criteria

You have mastered this module when you can:

- Run a complete incident response using uFawkesObs tooling
- Conduct root cause analysis with structured methods (5 Whys, Fishbone, Fault Tree)
- Facilitate blameless postmortems using uFawkesObs data
- Build incident response automation with uFawkesObs observability stack
- Design and run chaos engineering experiments on uFawkesObs platform
- Measure and improve incident management effectiveness

---

## Next Steps

After completing this module, you've completed all Brown Belt modules:

➡️ **Brown Belt Assessment** — Deploy 2 additional applications, written exam, troubleshooting scenario, passing score: 80%

---

## Questions or Issues?

- 💬 Ask in [GitHub Discussions](https://github.com/paruff/uFawkesDojo/discussions) ([Q&A](https://github.com/paruff/uFawkesDojo/discussions/categories/q-a))
- 📧 Email: dojo@ufawkes.dev
- 🐛 Report bugs: [GitHub Issues](https://github.com/paruff/fawkes/issues)
