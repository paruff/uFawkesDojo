# Module 13: Observability with uFawkesObs

**Belt Level**: 🟤 Brown Belt
**Estimated Time**: 3-4 hours (25 min theory + 60 min lab + 10 min quiz)
**Prerequisites**: Modules 9-12 complete, uFawkesObs v1.0.0 running locally
**DORA Capability**: Observability, Monitoring, Alerting

---

## Learning Objectives

By the end of this module, you will be able to:

- ✅ Understand the three pillars of observability (metrics, logs, traces) and how uFawkesObs implements them
- ✅ Deploy and operate the uFawkesObs observability stack (Prometheus, Grafana, Loki, Tempo, Alertmanager, Alloy, OTel Collector)
- ✅ Configure and query metrics with PromQL in Prometheus and Grafana
- ✅ Query and analyze logs with LogQL in Loki and Grafana
- ✅ Trace requests across services with Tempo and Grafana
- ✅ Configure alerting with Prometheus rules and Alertmanager
- ✅ Enable and use the DORA metrics profile in uFawkesObs
- ✅ Apply the three pillars to drive platform improvements

---

## Module Structure

| Section       | Time   | Description                                         |
| ------------- | ------ | --------------------------------------------------- |
| Theory        | 25 min | Three pillars, uFawkesObs architecture, vs Fawkes  |
| Lab 01        | 60 min | Deploy stack, explore datasources, query data      |
| Knowledge     | 10 min | 10-question quiz                                    |

---

## Theory Summary (25 minutes)

### Three Pillars of Observability

| Pillar | Tool in uFawkesObs | Purpose | Query Language |
|--------|-------------------|---------|----------------|
| **Metrics** | Prometheus | Numerical measurements over time | PromQL |
| **Logs** | Loki | Event records, structured & unstructured | LogQL |
| **Traces** | Tempo | Request flows across services | TraceQL |

### uFawkesObs Stack Components

| Component | Version | Role |
|-----------|---------|------|
| **Prometheus** | v3.5.4 | Metrics storage & query |
| **Grafana** | 12.3.7 | Visualization, dashboards, alerting UI |
| **Loki** | 3.3.2 | Log aggregation |
| **Tempo** | 2.10.5 | Distributed tracing |
| **Alertmanager** | 0.34.1 | Alert routing & notification |
| **Alloy** | v1.12.2 | Log collection (replaces Promtail) |
| **OTel Collector** | 0.120.0 | Telemetry ingestion (OTLP) |

### uFawkesObs vs Fawkes (Kubernetes)

| Aspect | Fawkes (K8s) | uFawkesObs (Docker Compose) |
|--------|--------------|----------------------------|
| Deployment | Helm + ArgoCD | `make up` (Docker Compose) |
| Metrics | Prometheus + ServiceMonitors | Prometheus + OTel Collector |
| Logs | Loki + Promtail (DaemonSet) | Loki + Alloy |
| Traces | Tempo (Helm) | Tempo (Docker Compose) |
| Alerting | PrometheusRule CRDs | Prometheus rules files |
| Dashboards | Grafana ConfigMaps | Grafana file provisioning |
| DORA Metrics | Separate DORA stack | Built-in profile (`make up-dora`) |

---

## Lab

➡️ **[Lab 01: Observability Stack with uFawkesObs](lab-01/instructions.md)**

This lab walks you through:
1. Deploying uFawkesObs stack with `make up`
2. Exploring Grafana datasources and pre-built dashboards
3. Querying metrics with PromQL, logs with LogQL, traces with Tempo
4. Configuring alerting rules and Alertmanager
5. Enabling DORA metrics profile and verifying metrics collection

**Runs against**: [uFawkesObs `v1.1.0-rc.1`](https://github.com/paruff/uFawkesObs/releases/tag/v1.1.0-rc.1) (Docker Compose), a **pre-release**

> **Run for real on 2026-10-07 against `v1.1.0-rc.1` (pre-release), through the stack's APIs.** Grafana's browser-only clicks were not exercised in a browser. See the [audit](../../docs/ai-sdlc/compose-curriculum/audit-2026-10-06.md).

**Prerequisites**: Module 12 complete, a pinned uFawkesObs checkout (the lab shows how)

**Validation**: `bash brown-belt/module-13-observability/lab-01/validate.sh`

---

## Success Criteria

You have mastered this module when you can:

- Deploy uFawkesObs stack with `make up` and verify all services healthy
- Query metrics with PromQL, logs with LogQL, traces with Tempo
- Create Grafana dashboards for platform health and DORA metrics
- Configure alerting rules and route them via Alertmanager
- Enable DORA metrics profile and interpret the five metrics
- Correlate metrics, logs, and traces to debug a live issue

---

## Next Steps

After completing this module, proceed to:

➡️ **Module 14: DORA Deep Dive**
