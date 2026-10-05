# Module 13: Observability with uFawkesObs

**Belt Level**: 🟤 Brown Belt
**Duration**: 3-4 hours
**Prerequisites**: Modules 9-12 complete, uFawkesObs v1.0.0 running locally
**DORA Capabilities**: Observability, Continuous Delivery, Monitoring

---

## 1. Learning Objectives (5 minutes)

### What You'll Learn

By the end of this module, you will be able to:

- ✅ Understand the three pillars of observability (metrics, logs, traces) and how uFawkesObs implements them
- ✅ Deploy and operate the uFawkesObs observability stack (Prometheus, Grafana, Loki, Tempo, Alertmanager, Alloy, OTel Collector)
- ✅ Configure and query metrics with PromQL in Prometheus and Grafana
- ✅ Query and analyze logs with LogQL in Loki and Grafana
- ✅ Trace requests across services with Tempo and Grafana
- ✅ Configure alerting with Prometheus rules and Alertmanager
- ✅ Enable and use the DORA metrics profile in uFawkesObs
- ✅ Apply the three pillars to drive platform improvements

### Why It Matters

**The Observability Gap**

```
Traditional monitoring:
  ↓
  "Something is broken" → Scramble to find root cause
  Reactive, slow, stressful

Observability:
  ↓
  "Here's what changed" → Targeted fix in minutes
  Proactive, fast, confident
```

**Why Brown Belt?**

You've mastered CI/CD (Yellow Belt) and deployment (Green Belt). Now you need to **see** what's happening in production. Observability is the lens that turns incidents into learning, and metrics into decisions.

### Success Criteria

You've mastered this module when you can:

- Deploy uFawkesObs stack with `make up` and verify all services healthy
- Query metrics with PromQL, logs with LogQL, traces with TraceQL
- Create Grafana dashboards for platform health and DORA metrics
- Configure alerting rules and route them via Alertmanager
- Enable DORA metrics profile and interpret the five metrics
- Correlate metrics, logs, and traces to debug a live issue

---

## 2. Theory & Concepts (25 minutes)

### The Three Pillars of Observability

| Pillar | Tool in uFawkesObs | Purpose | Query Language |
|--------|-------------------|---------|----------------|
| **Metrics** | Prometheus | Numerical measurements over time | PromQL |
| **Logs** | Loki | Event records, structured & unstructured | LogQL |
| **Traces** | Tempo | Request flows across services | TraceQL |

**Why Three Pillars?** Each answers different questions:
- **Metrics**: "How much? How fast? How many?" (aggregated, cheap, long retention)
- **Logs**: "What happened? What was the context?" (detailed, contextual, searchable)
- **Traces**: "Where did the request go? Where did it spend time?" (request-scoped, causal)

### uFawkesObs Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         uFawkesObs Observability Stack                      │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    OpenTelemetry Collector (otel-collector)          │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                  │   │
│  │  │   Metrics   │  │   Traces    │  │    Logs     │                  │   │
│  │  │  (OTLP)     │  │   (OTLP)    │  │   (OTLP)    │                  │   │
│  │  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘                  │   │
│  └─────────┼────────────────┼────────────────┼─────────────────────────┘   │
│            │                │                │                             │
│            ▼                ▼                ▼                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                    │
│  │  Prometheus  │  │    Tempo     │  │     Loki     │                    │
│  │  (Metrics)   │  │  (Traces)    │  │   (Logs)     │                    │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘                    │
│         │                 │                 │                               │
│         └─────────────────┼─────────────────┘                               │
│                           ▼                                                 │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                        Grafana                                      │   │
│  │         Datasources: Prometheus, Loki, Tempo, Alertmanager          │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                           │                                                 │
│                           ▼                                                 │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    Alertmanager                                     │   │
│  │              Routes: Slack, PagerDuty, Email, Discord               │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                           │                                                 │
│                           ▼                                                 │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    Alloy (Log Collector)                            │   │
│  │           Scrapes Docker logs → forwards to Loki                    │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Key Components

| Component | Version | Role |
|-----------|---------|------|
| **Prometheus** | v3.5.4 | Metrics storage & query |
| **Grafana** | 12.3.7 | Visualization, dashboards, alerting UI |
| **Loki** | 3.3.2 | Log aggregation |
| **Tempo** | 2.10.5 | Distributed tracing |
| **Alertmanager** | 0.34.1 | Alert routing & notification |
| **Alloy** | v1.12.2 | Log collection (replaces Promtail) |
| **OTel Collector** | 0.120.0 | Telemetry ingestion (OTLP) |

---

## 3. uFawkesObs vs. Fawkes Kubernetes Monitoring

| Aspect | Fawkes (Kubernetes) | uFawkesObs (Docker Compose) |
|--------|---------------------|----------------------------|
| **Deployment** | Helm charts, ArgoCD | `make up` (Docker Compose) |
| **Metrics** | Prometheus + ServiceMonitors | Prometheus + OTel Collector |
| **Logs** | Loki + Promtail (DaemonSet) | Loki + Alloy |
| **Traces** | Tempo (Helm) | Tempo (Docker Compose) |
| **Alerting** | PrometheusRule CRDs | Prometheus rules files |
| **Dashboards** | Grafana ConfigMaps | Grafana file provisioning |
| **DORA Metrics** | Separate DORA stack | Built-in profile (`make up-dora`) |
| **Deployment** | Kubernetes cluster | `make up` (Docker Compose) |
| **Scalability** | Horizontal (Thanos) | Single-node (dev/staging) |

---

## 4. Hands-On Lab (60 minutes)

### Lab Overview

You'll deploy the uFawkesObs stack, explore the pre-built observability components, and configure a complete observability pipeline.

**Time Estimate**: 60 minutes
**Difficulty**: Advanced
**Prerequisites**: Modules 9-12 complete, uFawkesObs v1.0.0 running locally

➡️ **[Lab 01: Observability Stack with uFawkesObs](brown-belt/module-13-observability/lab-01/instructions.md)**

This lab walks you through:
1. Deploying the uFawkesObs stack with `make up`
2. Exploring pre-built Grafana dashboards and datasources
3. Querying metrics with PromQL, logs with LogQL, traces with Tempo
3. Configuring alerting rules and Alertmanager
3. Enabling DORA metrics profile and verifying metrics collection

**Runs against**: [uFawkesObs v1.0.0](https://github.com/paruff/uFawkesObs/releases/tag/v1.0.0) (Docker Compose)

**Validation**: `bash brown-belt/module-13-observability/lab-01/validate.sh`

---

## 5. Knowledge Check (10 minutes)

### Quiz: Observability with uFawkesObs

**Instructions**: Answer all 10 questions. You need 8/10 (80%) to pass. Unlimited attempts allowed.

#### Question 1

**What are the three pillars of observability?**

- [ ] A) Metrics, Alerts, Dashboards
- [ ] B) CPU, Memory, Disk
- [x] C) Metrics, Logs, Traces
- [ ] D) Prometheus, Grafana, Loki

**Explanation**: The three pillars are **Metrics** (numerical measurements), **Logs** (event records), and **Traces** (request flows).

---

#### Question 2

**In uFawkesObs, which component collects container logs and forwards them to Loki?**

- [ ] A) Promtail
- [ ] B) Fluent Bit
- [x] C) Alloy
- [ ] D) Promtail

**Explanation**: **Alloy** (Grafana Alloy) replaces Promtail as the log collector in uFawkesObs, scraping Docker container logs and forwarding to Loki.

---

#### Question 3

**Which component receives OTLP telemetry and routes it to Prometheus, Loki, and Tempo?**

- [ ] A) Prometheus
- [ ] B) Grafana
- [x] C) OpenTelemetry Collector
- [ ] D) Alertmanager

**Explanation**: The **OpenTelemetry Collector** receives OTLP telemetry (metrics, logs, traces) and routes them to the appropriate backend.

---

#### Question 4

**What query language does Loki use?**

- [ ] A) PromQL
- [ ] B) SQL
- [x] C) LogQL
- [ ] D) TraceQL

**Explanation**: **LogQL** is Loki's query language for filtering and aggregating logs.

---

#### Question 5

**In uFawkesObs, how do you enable the DORA metrics profile?**

- [ ] A) Set environment variable DORA_ENABLED=true
- [x] B) Run `make up-dora`
- [ ] C) Deploy separate DORA stack
- [ ] D) Configure in Grafana UI

**Explanation**: Run **`make up-dora`** to start the stack with the DORA profile — the core observability stack plus **dora-api**, which receives events and computes the DORA metrics in-process (self-contained, SQLite).

---

#### Question 6

**Which component handles alert routing and notification delivery?**

- [ ] A) Prometheus
- [ ] B) Grafana
- [x] C) Alertmanager
- [ ] D) Loki

**Explanation**: **Alertmanager** receives alerts from Prometheus, deduplicates, groups, and routes them to receivers (Slack, PagerDuty, email, etc.).

---

#### Question 7

**What is the key difference between metrics and logs?**

- [ ] A) Metrics are faster
- [ ] B) Logs are cheaper
- [x] C) Metrics are aggregated; logs are event records
- [ ] D) Logs are real-time

**Explanation**: **Metrics** are pre-aggregated numerical measurements; **logs** are discrete event records with full context.

---

#### Question 8

**How do you query logs in Grafana when using Loki as a datasource?**

- [ ] A) PromQL
- [ ] B) SQL
- [x] C) LogQL
- [ ] D) TraceQL

**Explanation**: Use **LogQL** (Loki Query Language) to filter, parse, and aggregate logs in Grafana Explore.

---

#### Question 9

**What is the purpose of the OTel Collector in uFawkesObs?**

- [ ] A) Store metrics
- [ ] B) Visualize dashboards
- [x] C) Receive OTLP telemetry and route to Prometheus, Loki, Tempo
- [ ] D) Send alerts

**Explanation**: The **OTel Collector** receives OTLP telemetry (metrics, logs, traces) and routes them to Prometheus (metrics), Loki (logs), Tempo (traces).

---

#### Question 10

**How do you enable the DORA metrics profile in uFawkesObs?**

- [ ] A) Set DORA_ENABLED=true in .env
- [x] B) Run `make up-dora`
- [ ] C) Deploy separate DORA stack
- [ ] D) Configure in Grafana

**Explanation**: Run **`make up-dora`** to start the stack with the DORA profile — the core stack plus **dora-api** (self-contained, SQLite-only), which receives events and computes the DORA metrics in-process.

---

### Quiz Results

**Score: X / 10**

- ✅ **Passed** (8+): Excellent! You understand observability with uFawkesObs.
- ❌ **Not Yet** (<8): Review the theory section and try again.

**Incorrect answers?** Each question links back to the relevant section for review.

---

## 6. Reflection & Next Steps (5 minutes)

### What You Learned

✅ **You now know**:
- The three pillars of observability and how uFawkesObs implements them
- How to deploy and operate the uFawkesObs stack
- How to query metrics (PromQL), logs (LogQL), and traces (Tempo)
- How to configure alerting with Prometheus rules and Alertmanager
- How to enable and use the DORA metrics profile
- How to correlate metrics, logs, and traces for debugging

✅ **You can now**:
- Deploy uFawkesObs with `make up` and verify health
- Create Grafana dashboards for platform health and DORA metrics
- Configure alerting rules and route them via Alertmanager
- Enable DORA metrics profile and interpret the five metrics
- Correlate metrics, logs, and traces to debug a live issue

### How This Connects to Your Work

**For Platform Engineers**:
- You now have a production-grade observability stack that runs locally
- You can standardize observability across teams with uFawkesObs
- You understand how to migrate from Kubernetes monitoring to Docker Compose

**For Developers**:
- You can instrument applications with OTel and see data in uFawkesObs
- You can debug issues by correlating metrics, logs, and traces
- You can use DORA metrics to measure and improve delivery performance

**For Leaders**:
- You can make data-driven decisions with DORA metrics
- You can invest in observability with confidence (local-first, no SaaS bill)
- You can demonstrate platform maturity to stakeholders

### Reflection Questions

1. **What surprised you most about uFawkesObs vs. Kubernetes monitoring?**
2. **How does your current observability stack compare?**
3. **What alerting rules would you add for your platform?**
4. **Who on your team should go through this module?**

### Preview: Module 14

**Next Up: DORA Deep Dive**

In Module 14, you'll learn:
- Deep dive into each of the five DORA metrics
- Advanced PromQL for DORA metric calculation
- Benchmarking against industry standards
- Using DORA metrics to drive platform investment decisions

**Time**: 3-4 hours
**Prerequisites**: Module 13 complete ✅

---

## Module Completion

### ✅ You've Completed Module 13

**Next Steps**:
1. ✅ Mark this module complete in your Backstage profile
2. 📊 View your progress on the Dojo dashboard
3. 💬 Share your completion in `#dojo-achievements` (optional!)
4. ➡️ **Continue to Module 14** when ready

**Time Investment**: 3-4 hours
**Skills Gained**: Observability stack deployment, PromQL/LogQL/TraceQL, alerting, DORA metrics
**Progress**: 1 of 4 modules toward Brown Belt (25% complete)

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
