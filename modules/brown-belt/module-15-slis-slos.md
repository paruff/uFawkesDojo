# Module 15: SLIs, SLOs, and Error Budgets with uFawkesObs

**Belt Level**: 🟤 Brown Belt
**Duration**: 3-4 hours
**Prerequisites**: Module 13 (Observability with uFawkesObs) and Module 14 (DORA Metrics Deep Dive) complete, uFawkesObs v1.0.0 running locally
**DORA Capabilities**: Monitoring and Observability, Service Reliability, Data-Driven Decision Making, Customer Focus

---

## 1. Learning Objectives (5 minutes)

### What You'll Learn

By the end of this module, you will be able to:

- ✅ Define Service Level Indicators (SLIs) for your services using uFawkesObs Prometheus
- ✅ Create meaningful Service Level Objectives (SLOs) with uFawkesObs recording rules
- ✅ Calculate and track error budgets using uFawkesObs Prometheus recording rules
- ✅ Implement SLI/SLO monitoring in Prometheus with uFawkesObs stack
- ✅ Balance innovation velocity with reliability using error budgets
- ✅ Make data-driven decisions about service reliability with uFawkesObs Grafana dashboards

### Why It Matters

**Without SLIs/SLOs**:

```
Team: "Our service is pretty reliable"
Customer: "It's been down twice this week!"
PM: "Can we deploy this risky feature?"
Ops: "I don't know, maybe?"

Result:
- No shared understanding of reliability
- Arbitrary decisions about risk
- Customer dissatisfaction
- Team stress and conflict
```

**With SLIs/SLOs/Error Budgets**:

```
Team: "We have 99.9% availability (SLO) and we're at 99.95%"
Customer: "Within SLO, acceptable"
PM: "We have error budget remaining, let's deploy"
Ops: "Budget shows we can tolerate this risk"

Result:
- Shared language for reliability
- Data-driven risk decisions
- Customer expectations managed
- Team alignment
```

### Success Criteria

You've mastered this module when you can:

- Define SLIs for your services using uFawkesObs Prometheus
- Create SLOs with appropriate targets and time windows using recording rules
- Calculate and track error budgets with burn rate alerts
- Build Grafana dashboards for SLO/error budget visualization
- Make data-driven deployment decisions using error budgets
- Communicate service health to stakeholders with shared terminology

---

## 2. Theory & Concepts (30 minutes)

### The Reliability Framework

**The SRE Hierarchy**

```
┌─────────────────────────────────────┐
│     User Happiness (Ultimate Goal)  │
└───────────────┬─────────────────────┘
                │
┌───────────────▼─────────────────────┐
│   Service Level Indicators (SLIs)   │
│   What we measure (metrics)         │
└───────────────┬─────────────────────┘
                │
┌───────────────▼─────────────────────┐
│  Service Level Objectives (SLOs)    │
│  Targets for SLIs (promises)        │
└───────────────┬─────────────────────┘
                │
┌───────────────▼─────────────────────┐
│       Error Budget                   │
│  Allowed unreliability (innovation)  │
└─────────────────────────────────────┘
```

### uFawkesObs SLI/SLO Architecture

uFawkesObs provides a complete SLI/SLO platform using Docker Compose:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    uFawkesObs SLI/SLO Stack                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐                 │
│  │   Your Apps  │───▶│   Alloy      │───▶│  Prometheus  │                 │
│  │  (Metrics)   │    │  (Logs)      │    │  (Metrics)   │                 │
│  └──────────────┘    └──────────────┘    └──────┬───────┘                 │
│                                                 │                           │
│                                                 ▼                           │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │              Prometheus Recording Rules (SLI/SLO/Error Budget)       │   │
│  │  ┌─────────────────────────────────────────────────────────────┐    │   │
│  │  │  SLI Recording Rules (availability, latency, error_rate)     │    │   │
│  │  │  SLO Recording Rules (targets, windows, thresholds)          │    │   │
│  │  │  Error Budget Rules (remaining, burn rate, consumed)         │    │   │
│  │  └─────────────────────────────────────────────────────────────┘    │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                 │                           │
│                                                 ▼                           │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    Alertmanager (SLO Alerts)                         │   │
│  │              Multi-window burn rate alerts                           │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                 │                           │
│                                                 ▼                           │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                        Grafana                                       │   │
│  │         SLO Dashboards, Error Budget Panels, Alerting UI            │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Key Components in uFawkesObs

| Component | Role in SLI/SLO |
|-----------|-----------------|
| **Prometheus** | Stores metrics, evaluates recording rules, evaluates alerts |
| **Grafana** | SLO dashboards, error budget visualization, alerting UI |
| **Alertmanager** | Routes SLO breach notifications |
| **Alloy** | Scrapes application metrics, forwards to Prometheus |
| **Prometheus Rules** | Recording rules (SLI/SLO/Error Budget), Alert rules |

---

## 3. Service Level Indicators (SLIs) (20 minutes)

### What is an SLI?

**SLI**: A carefully selected metric that represents user happiness

**Good SLI characteristics**:
- ✅ User-centric (measures what users care about)
- ✅ Measurable (can be quantified)
- ✅ Actionable (team can improve it)
- ✅ Aggregatable (can combine across services)

### Common SLI Types

#### 1. Availability (Uptime)

**Definition**: Proportion of time service is operational

```promql
# Availability SLI
sum(rate(http_requests_total{service="myapp",status!~"5.."}[5m]))
/
sum(rate(http_requests_total{service="myapp"}[5m]))
* 100

# Example: 99.5% availability
```

**User impact**: "Can I access the service?"

#### 2. Latency (Speed)

**Definition**: Time to respond to requests

```promql
# Latency SLI (p95)
histogram_quantile(0.95,
  sum(rate(http_request_duration_seconds_bucket{service="myapp"}[5m])) by (le)
)

# Example: p95 < 200ms
```

**User impact**: "How fast does it respond?"

#### 3. Error Rate (Correctness)

**Definition**: Proportion of requests that fail

```promql
# Error rate SLI
sum(rate(http_requests_total{service="myapp",status=~"5.."}[5m]))
/
sum(rate(http_requests_total{service="myapp"}[5m]))
* 100

# Example: 0.1% error rate
```

**User impact**: "Does it work correctly?"

#### 4. Throughput (Capacity)

**Definition**: Requests handled per unit time

```promql
# Throughput SLI
sum(rate(http_requests_total{service="myapp"}[5m]))

# Example: 1000 req/s
```

**User impact**: "Can it handle my load?"

#### 5. Durability (Data Safety)

**Definition**: Proportion of data successfully stored/retrieved

```promql
# Durability SLI
sum(successful_writes) / sum(total_writes) * 100

# Example: 99.999% durability
```

**User impact**: "Is my data safe?"

### Selecting SLIs for Your Service

**Step 1: Identify User Journeys**

Example: E-commerce checkout

```
User Journey: Purchase Product
1. Browse catalog
2. Add to cart
3. Enter payment
4. Complete purchase
5. Receive confirmation
```

**Step 2: Map to SLIs**

| Journey Step         | SLI          | Target      | Why It Matters              |
| -------------------- | ------------ | ----------- | --------------------------- |
| Browse catalog       | Latency      | p95 < 300ms | Slow browsing = abandoned   |
| Add to cart          | Availability | 99.9%       | Can't shop if cart broken   |
| Enter payment        | Error rate   | < 0.1%      | Payment errors = lost sales |
| Complete purchase    | Latency      | p99 < 1s    | Checkout must be fast       |
| Receive confirmation | Availability | 99.99%      | Legal requirement           |

**Step 3: Prioritize**

Focus on 3-5 most critical SLIs:

1. **Checkout error rate** (revenue impact)
2. **Checkout latency** (abandonment risk)
3. **Catalog availability** (engagement)

---

## 4. Service Level Objectives (SLOs) (15 minutes)

### What is an SLO?

**SLO**: A target value or range for an SLI over a time window

**Format**: `SLI ≥ Target over Time Window`

**Examples**:
- Availability ≥ 99.9% over 30 days
- p95 latency ≤ 200ms over 7 days
- Error rate < 0.5% over 30 days

### Setting Good SLOs

#### Rule 1: Align with User Expectations

**Bad**: "5 nines (99.999%) because we're perfectionists"
**Good**: "99.9% because user research shows this meets needs"

**User tolerance** varies by context:
- Search engine: p95 < 100ms (users expect instant)
- Banking transfer: p95 < 2s (users tolerate some delay)
- Batch report: p95 < 30s (users expect processing time)

#### Rule 2: Start Conservative, Tighten Over Time

**Initial SLO**: 99.5% availability

- Monitor for 3 months
- Actual: 99.7%
- **Tighten**: 99.6% (between actual and previous)

**Why**: Easier to exceed SLO and tighten than miss and relax

#### Rule 3: Fewer is Better

**Bad**: 15 SLOs for one service
**Good**: 3-5 SLOs that matter most

**Example**:
```
Service: Payment API
SLOs:
1. Availability ≥ 99.95% (30 days)
2. p95 latency ≤ 500ms (7 days)
3. Error rate < 0.1% (30 days)
```

#### Rule 4: Document Your SLOs

```yaml
# slo-definition.yaml
service: payment-api
slos:
  - name: availability
    description: "Proportion of successful requests"
    type: availability
    target: 99.95
    window: 30d
    sli: |
      sum(rate(http_requests_total{service="payment-api",status!~"5.."}[5m]))
      /
      sum(rate(http_requests_total{service="payment-api"}[5m]))
      * 100

  - name: latency
    description: "95th percentile response time"
    type: latency
    target: 500ms
    window: 7d
    sli: |
      histogram_quantile(0.95,
        sum(rate(http_request_duration_seconds_bucket{service="payment-api"}[5m])) by (le)
      )

  - name: error_rate
    description: "Proportion of failed requests"
    type: error_rate
    target: 0.1
    window: 30d
    sli: |
      sum(rate(http_requests_total{service="payment-api",status=~"5.."}[5m]))
      /
      sum(rate(http_requests_total{service="payment-api"}[5m]))
      * 100
```

### Multi-Window SLOs

Track SLOs over different time windows:

```
Service: API
SLO: 99.9% availability

Windows:
- 1 hour:  99.99% ✅ (shorter window, stricter)
- 1 day:   99.95% ✅
- 7 days:  99.92% ✅
- 30 days: 99.91% ✅ (meets SLO)
```

**Benefit**: Early warning system
- Hour/day violations = potential trend
- 30-day still met = no customer impact yet

---

## 5. Error Budgets (20 minutes)

### What is an Error Budget?

**Error Budget**: Allowed unreliability based on SLO

**Formula**: `Error Budget = 100% - SLO`

**Example**:
```
SLO: 99.9% availability
Error Budget: 0.1% (100% - 99.9%)

In a 30-day month:
- Total time: 30 days = 43,200 minutes
- Error budget: 0.1% × 43,200 = 43.2 minutes
- Allowed downtime: ~43 minutes per month
```

### Error Budget as Currency

Think of error budget as **innovation currency**:

```
Monthly Error Budget: 43 minutes

Spent on:
- Planned maintenance: 10 minutes
- Feature deploy issues: 15 minutes
- Infrastructure failure: 8 minutes
- Security patching: 5 minutes
─────────────────────────────────────
Total spent: 38 minutes
Remaining: 5 minutes (healthy) ✅
```

### Burn Rate

**Burn Rate**: How fast you're consuming error budget

**Formula**: `Burn Rate = (Error Rate / Error Budget) × Time Window`

**Example**:
```
Current error rate: 0.5%
Error budget: 0.1%
Burn rate: 0.5% / 0.1% = 5x

At this rate:
- 30-day budget consumed in 6 days
- Action required! 🚨
```

### Error Budget Policies

Define policies for budget exhaustion:

```yaml
error_budget_policy:
  - condition: "50% remaining"
    action: "Continue normal operations"

  - condition: "25% remaining"
    action:
      - "Freeze non-critical feature deploys"
      - "Increase monitoring"
      - "Review recent changes"

  - condition: "10% remaining"
    action:
      - "Freeze ALL feature deploys"
      - "Focus on reliability improvements"
      - "Daily team review"
      - "Incident commander assigned"

  - condition: "0% remaining (exhausted)"
    action:
      - "Complete deploy freeze"
      - "Root cause analysis required"
      - "Reliability sprint"
      - "Executive notification"
```

---

## 6. Hands-On Lab (45 minutes)

### Lab Overview

You'll implement a complete SLI/SLO/Error Budget system for a sample service using uFawkesObs:

1. Define SLIs with Prometheus recording rules
2. Create SLOs with recording rules and targets
3. Implement error budget tracking with burn rate alerts
4. Build Grafana dashboard for SLO/error budget visualization
5. Practice SLO-driven deployment decisions

**Time Estimate**: 45 minutes
**Difficulty**: Advanced (Modules 13-14 complete)
**Auto-Graded**: Yes
**Points**: 100

### Lab Environment

**Prerequisites**:
- ✅ Module 13 & 14 complete
- ✅ uFawkesObs v1.0.0 running locally
- ✅ Module 13 (Observability) and Module 14 (DORA) complete

➡️ **[Lab 01: Implementing SLIs/SLOs/Error Budgets](brown-belt/module-15-slis-slos/lab-01/instructions.md)**

This lab walks you through:
1. Creating SLI recording rules for a sample service
2. Defining SLO recording rules with targets
3. Implementing error budget recording rules
4. Configuring multi-window burn rate alerts
5. Building Grafana SLO dashboard with error budget visualization
6. Practicing SLO-driven deployment decisions

**Runs against**: [uFawkesObs v1.0.0](https://github.com/paruff/uFawkesObs/releases/tag/v1.0.0) (Docker Compose)

**Validation**: `bash brown-belt/module-15-slis-slos/lab-01/validate.sh`

---

## 7. Knowledge Check (10 minutes)

### Quiz: SLIs, SLOs, and Error Budgets

**Instructions**: Answer all 10 questions. You need 8/10 (80%) to pass. Unlimited attempts allowed.

#### Question 1

**What is an SLI?**

- [ ] A) A promise to users about reliability
- [x] B) A metric that indicates user happiness
- [ ] C) The allowed unreliability
- [ ] D) A dashboard panel

**Explanation**: An **SLI** is a metric that indicates user happiness (e.g., availability, latency, error rate).

---

#### Question 2

**What is an SLO?**

- [ ] A) A metric collection system
- [x] B) A target value for an SLI over a time window
- [ ] C) An error budget calculation
- [ ] D) A monitoring tool

**Explanation**: An **SLO** is a target value for an SLI over a time window (e.g., "99.9% availability over 30 days").

---

#### Question 3

**How is error budget calculated?**

- [ ] A) 100% - SLI
- [x] B) 100% - SLO
- [ ] C) SLO - SLI
- [ ] D) SLI - SLO

**Explanation**: Error Budget = 100% - SLO. If SLO is 99.9%, error budget = 0.1%.

---

#### Question 4

**What does a burn rate of 5x mean?**

- [ ] A) Service is 5x faster
- [ ] B) 5 errors per minute
- [x] C) Consuming error budget 5x faster than normal
- [ ] D) 5% error rate

**Explanation**: Burn rate = (Error Rate / Error Budget) × Time Window. 5x = consuming budget 5x faster than sustainable rate.

---

#### Question 5

**When should you freeze feature deploys?**

- [ ] A) Never, always ship features
- [ ] B) Only during incidents
- [x] C) When error budget is critically low (<10%)
- [ ] D) Every Friday

**Explanation**: Freeze deploys when error budget is critically low (<10% remaining) per error budget policy.

---

#### Question 6

**What's a good starting point for SLOs?**

- [ ] A) 100% (perfection)
- [ ] B) 50% (average)
- [x] C) Slightly below current performance
- [ ] D) As long as it takes

**Explanation**: Start slightly below current performance, then tighten as you improve. Easier to tighten than loosen.

---

#### Question 6

**How many SLOs should a service have?**

- [ ] A) Exactly 1
- [ ] B) At least 10
- [x] C) 3-5 most critical metrics
- [ ] D) One per feature

**Explanation**: 3-5 well-chosen SLOs beat 20 mediocre ones. Focus on what users care about.

---

#### Question 7

**What's the purpose of multi-window SLOs?**

- [ ] A) Confuse people with more metrics
- [ ] B) Show off monitoring capabilities
- [x] C) Provide early warning of SLO violations
- [ ] D) Meet compliance requirements

**Explanation**: Multi-window SLOs (1h, 1d, 7d, 30d) provide early warning - shorter windows detect trends before 30-day SLO is breached.

---

#### Question 8

**What does Deployment Rework Rate measure?**

- [ ] A) All failed deployments
- [x] B) Incident-driven, unplanned deployments
- [ ] C) All deployments during an incident
- [ ] D) Reverted commits

**Explanation**: Deployment Rework Rate = unplanned, incident-driven deployments / total deployments. Measures unplanned work due to incidents.

---

#### Question 10

**What should you do when error budget is exhausted?**

- [ ] Keep deploying and hope for the best
- [x] Freeze feature deploys, focus on reliability
- [ ] Blame the team and continue
- [ ] Ignore it and keep shipping

**Explanation**: Per error budget policy: budget exhausted → deploy freeze + reliability sprint.

---

### Quiz Results

**Score: X / 10**

- ✅ **Passed** (8+): Excellent! You understand SLIs/SLOs/Error Budgets with uFawkesObs.
- ❌ **Not Yet** (<8): Review the theory section and try again.

---

## 6. Reflection & Next Steps (5 minutes)

### What You Learned

✅ **You now know**:
- How to define SLIs that measure user happiness
- How to set SLOs that balance reliability and innovation
- How to calculate and track error budgets with uFawkesObs
- How to configure burn rate alerts for early warning
- How to make SLO-driven deployment decisions

✅ **You can now**:
- Define SLIs for your services using uFawkesObs Prometheus
- Set appropriate SLOs with appropriate time windows
- Implement error budget tracking with burn rate alerts
- Build Grafana dashboards for SLO/error budget visualization
- Make data-driven deployment decisions using error budgets

### How This Connects to Your Work

**For Developers**:
- You can now define SLIs that reflect user experience
- You can use error budgets to justify deployment decisions
- You have a framework for negotiating scope vs reliability

**For Platform Engineers**:
- You understand how to maintain the SLO platform
- You can help teams set appropriate SLOs
- You see how error budgets enable innovation

**For Leaders**:
- You can articulate reliability in business terms
- You understand the trade-offs between speed and reliability
- You can make data-driven investment decisions

### Reflection Questions

1. **What surprised you most about SLIs/SLOs/Error Budgets?**
2. **How does your current reliability process compare?**
3. **What would you change about your current SLOs?**
4. **Who on your team should go through this module?**

### Preview: Module 16

**Next Up: Incident Management Mastery**

In Module 16, you'll learn:
- Advanced incident response procedures
- Chaos engineering for reliability validation
- MTTR optimization techniques
- Postmortem culture and blameless postmortems

**Time**: 3-4 hours
**Prerequisites**: Modules 13-15 complete ✅

---

## Module Completion

### ✅ You've Completed Module 15

**Next Steps**:
1. ✅ Mark this module complete in your Backstage profile
2. 📊 View your progress on the Dojo dashboard
3. 💬 Share your completion in [Show and tell](https://github.com/paruff/uFawkesDojo/discussions/categories/show-and-tell) (optional!)
4. ➡️ **Continue to Module 16: Advanced Incident Management**

**Time Investment**: 3-4 hours
**Skills Gained**: SLI/SLO definition, error budget management, burn rate alerting, SLO dashboards, data-driven reliability decisions
**Progress**: 3 of 4 modules toward Brown Belt (75% complete)

---

**Questions or Issues?**
- 💬 Ask in [GitHub Discussions](https://github.com/paruff/uFawkesDojo/discussions) ([Q&A](https://github.com/paruff/uFawkesDojo/discussions/categories/q-a))
- 📧 Email: dojo@ufawkes.dev
- 🐛 Report bugs: [GitHub Issues](https://github.com/paruff/fawkes/issues)

**Feedback?**
- Rate this module (takes 30 seconds)
- Suggest improvements
- Help us make the dojo better!

---

**Module Author**: Fawkes Learning Team
**Last Updated**: October 2026
**Version**: 2.0 (uFawkesObs migration)
