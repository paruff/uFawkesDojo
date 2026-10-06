# Module 15: SLIs, SLOs, and Error Budgets with uFawkesObs

**Belt Level**: 🟤 Brown Belt
**Estimated Time**: 3-4 hours (30 min theory + 45 min lab + 10 min quiz)
**Prerequisites**: Module 13 & 14 complete, uFawkesObs v1.0.0 running locally
**DORA Capability**: Monitoring and Observability, Service Reliability, Data-Driven Decision Making

---

## Learning Objectives

By the end of this module, you will be able to:

- ✅ Define Service Level Indicators (SLIs) for your services using uFawkesObs Prometheus
- ✅ Create meaningful Service Level Objectives (SLOs) with recording rules
- ✅ Calculate and track error budgets using uFawkesObs Prometheus recording rules
- ✅ Implement multi-window burn rate alerts for early SLO breach detection
- ✅ Build Grafana dashboards for SLO/error budget visualization
- ✅ Make data-driven deployment decisions using error budgets

---

## Module Structure

| Section       | Time   | Description                                         |
| ------------- | ------ | --------------------------------------------------- |
| Theory        | 30 min | SLI/SLO/Error Budget theory, uFawkesObs implementation |
| Lab 01        | 45 min | Implement SLIs, SLOs, Error Budgets, build dashboard |
| Quiz          | 10 min | 10-question knowledge check                        |

---

## Theory Summary (25 minutes)

### What is an SLI?

**SLI**: A carefully selected metric that represents user happiness

| SLI Type | What It Measures | Example Query |
|----------|------------------|---------------|
| **Availability** | Proportion of successful requests | `sum(rate(requests{status!~"5.."}[5m])) / sum(rate(requests[5m])) * 100` |
| **Latency** | Request response time (p95/p99) | `histogram_quantile(0.95, rate(http_duration_bucket[5m]))` |
| **Error Rate** | Proportion of failed requests | `rate(requests{status=~"5.."}[5m]) / rate(requests[5m]) * 100` |
| **Throughput** | Requests per second | `rate(requests_total[5m])` |
| **Durability** | Data integrity | `successful_writes / total_writes * 100` |

### What is an SLO?

**SLO**: A target value for an SLI over a time window

| SLO | Target | Window | Why |
|-----|--------|--------|-----|
| Availability | ≥ 99.9% | 30d | Users expect reliable access |
| Latency (p95) | ≤ 500ms | 7d | Users expect fast responses |
| Error Rate | < 0.1% | 30d | Users expect correct behavior |

### Error Budgets

**Error Budget = 100% - SLO**

| SLO | Error Budget | 30-Day Allowance |
|-----|--------------|------------------|
| 99.9% | 0.1% | 43.2 minutes |
| 99.95% | 0.05% | 21.6 minutes |
| 99.99% | 0.01% | 4.3 minutes |

**Burn Rate**: How fast you're consuming error budget
- 1x = sustainable
- 5x = will exhaust in ~6 days
- 10x = will exhaust in ~3 days

---

## Lab

➡️ **[Lab 01: Implementing SLIs/SLOs/Error Budgets](lab-01/instructions.md)**

This lab walks you through:
1. Creating SLI recording rules for a sample service
2. Defining SLO recording rules with targets and windows
3. Implementing error budget recording rules with burn rate alerts
4. Building a Grafana SLO dashboard with error budget visualization
5. Practicing SLO-driven deployment decisions

**Runs against**: uFawkesObs v1.0.0 (not released yet) (Docker Compose)

> **Written ahead of its stack, not yet run for real.** uFawkesObs v1.0.0 has not been released, so no one has run every step of this lab against it. Treat the steps and the expected output as unverified. See the [audit](../../docs/ai-sdlc/compose-curriculum/audit-2026-10-06.md).

**Prerequisites**: Module 13 & 14 complete, uFawkesObs v1.0.0 running

**Validation**: `bash brown-belt/module-15-slis-slos/lab-01/validate.sh`

---

## Success Criteria

You have mastered this module when you can:

- Define SLIs for your services using uFawkesObs Prometheus recording rules
- Create SLOs with appropriate targets and time windows
- Configure error budget tracking with multi-window burn rate alerts
- Build Grafana dashboards for SLO/error budget visualization
- Make data-driven deployment decisions using error budgets
- Communicate service health using shared SLO terminology

---

## Next Steps

After completing this module, proceed to:

➡️ **Module 16: Advanced Incident Management** — Postmortems, chaos engineering, MTTR optimization
