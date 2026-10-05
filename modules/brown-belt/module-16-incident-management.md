# Module 16: Incident Management (Advanced) with uFawkesObs

**Belt Level**: 🟤 Brown Belt
**Duration**: 60 minutes
**Difficulty**: Advanced
**Prerequisites**: Modules 13, 14, 15 complete, uFawkesObs v1.0.0 running with DORA profile
**DORA Capabilities**: Mean Time to Restore (MTTR) - Elite level, Incident Management Process, Postmortem Culture, Learning Organization

---

## 1. Learning Objectives (5 minutes)

### What You'll Learn

By the end of this module, you will be able to:

- ✅ Implement advanced incident response frameworks with uFawkesObs
- ✅ Conduct effective incident command and communication using uFawkesObs stack
- ✅ Perform root cause analysis (RCA) with structured methods
- ✅ Design and facilitate blameless postmortems using uFawkesObs tooling
- ✅ Build incident response automation with uFawkesObs observability stack
- ✅ Design and run chaos engineering experiments on uFawkesObs platform
- ✅ Measure and improve incident management effectiveness with uFawkesObs

### Why It Matters

**The Incident Management Gap**

```
Traditional incident response:
  ↓
  "Something broke" → Panic → Random fixes → Eventually fixed
  Reactive, chaotic, stressful

Modern incident management:
  ↓
  "Alert fires" → Structured response → Root cause found → Fixed → Learned
  Structured, calm, confident
```

**Why Brown Belt Final Module?**

You've mastered:
- CI/CD (Yellow Belt)
- Deployment (Green Belt)
- Observability (Module 13)
- DORA Metrics (Module 14)
- SLI/SLO/Error Budgets (Module 15)

Now you need to **respond to incidents like a pro** — the capstone of Brown Belt.

### Success Criteria

You've mastered this module when you can:

- Run a complete incident response using uFawkesObs tooling
- Conduct root cause analysis with structured methods
- Facilitate blameless postmortems using uFawkesObs tooling
- Build incident response automation with uFawkesObs observability stack
- Design and run chaos engineering experiments on uFawkesObs
- Measure and improve incident management effectiveness

---

## 2. Theory & Concepts (20 minutes)

### The Incident Lifecycle with uFawkesObs

```
┌─────────────────────────────────────────────────────────────────────────────┐
│              Advanced Incident Lifecycle with uFawkesObs                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  1. DETECTION (< 5 min)                                                     │
│     ├─ Prometheus alerts → Alertmanager                                     │
│     ├─ Loki log alerts                                                      │
│     ├─ Tempo trace anomalies                                                │
│     └─ Synthetic monitoring (uFawkesObs)                                    │
│                                                                             │
│  2. TRIAGE (< 2 min)                                                        │
│     ├─ Grafana dashboards → assess impact                                   │
│     ├─ Loki logs → context                                                  │
│     ├─ Tempo traces → request flow                                          │
│     └─ Prometheus → system health                                           │
│                                                                             │
│  3. INVESTIGATION (parallel)                                                │
│     ├─ Loki LogQL queries → log patterns                                    │
│     ├─ Tempo TraceQL → trace flows                                          │
│     ├─ PromQL → metrics correlation                                         │
│     └─ Grafana → unified view                                               │
│                                                                             │
│  4. MITIGATION (< 15 min for SEV1)                                          │
│     ├─ Docker Compose scale / restart                                       │
│     ├─ ConfigMap updates → rolling restart                                  │
│     ├─ Feature flags / circuit breakers                                     │
│     └─ Rollback via git revert                                              │
│                                                                             │
│  5. RESOLUTION                                                               │
│     ├─ Root cause fix deployed                                              │
│     ├─ Grafana → verify metrics recovered                                   │
│     ├─ Tempo → traces normal                                                │
│     └─ Loki → error rate normal                                             │
│                                                                             │
│  6. RECOVERY                                                                 │
│     ├─ Service restoration verified                                         │
│     ├─ Data integrity verified                                              │
│     └─ Stakeholder communication                                            │
│                                                                             │
│  7. POSTMORTEM (within 24-48h)                                              │
│     ├─ Timeline from Loki/Grafana annotations                               │
│     ├─ RCA with 5 Whys + Fishbone (uFawkesObs data)                         │
│     └─ Action items in GitHub/Gitea                                         │
│                                                                             │
│  8. FOLLOW-UP                                                                │
│     ├─ Action item tracking in GitHub/Gitea                                 │
│     ├─ Pattern analysis (repeat incidents)                                  │
│     └─ Process improvement (chaos engineering)                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### uFawkesObs Incident Response Stack

| Component | Role in Incident Response |
|-----------|---------------------------|
| **Grafana** | War room dashboard, real-time metrics, alerting UI |
| **Prometheus** | Metrics queries, alerting rules, recording rules |
| **Loki** | Log aggregation, LogQL queries, log-based alerts |
| **Tempo** | Distributed tracing, root cause tracing |
| **Alertmanager** | Alert routing, silencing, notification routing |
| **Alloy** | Log/metric collection from containers |
| **OTel Collector** | Trace ingestion, metric pipeline |
| **Grafana** | War room dashboard, incident timeline |

---

## 3. Incident Command System (ICS) for uFawkesObs (15 minutes)

### uFawkesObs ICS Roles

| Role | Responsibilities | uFawkesObs Tools |
|------|------------------|------------------|
| **Incident Commander (IC)** | Overall coordination, decisions, comms | Grafana war room, Alertmanager, Slack/Teams |
| **Technical Lead (TL)** | Technical investigation, hypothesis testing | Grafana, Prometheus, Loki, Tempo |
| **Communications Lead** | Stakeholder updates, status page | Grafana annotations, status page API |
| **Scribe** | Timeline, decisions, actions | Grafana annotations, GitHub/Gitea issue |

### Communication Channels in uFawkesObs Context

```yaml
# uFawkesObs Incident Channels
war_room:
  platform: "Mattermost/Slack/Teams"
  channel: "#incident-war-room-<id>"
  purpose: "Real-time coordination"

status_page:
  platform: "Grafana/Statuspage.io"
  updates: "Every 15 min (SEV1), 30 min (SEV2)"

executive_updates:
  channel: "#exec-incidents"
  frequency: "SEV0/1 only, every 30 min"

internal_docs:
  platform: "Grafana annotations / GitHub issue"
  purpose: "Timeline, decisions, actions"
```

### Communication Templates for uFawkesObs

#### Initial Notification
```markdown
🚨 INCIDENT DECLARED - SEV1

**Service**: <service-name>
**Impact**: <user/business impact>
**Detection**: <Grafana alert / Loki log alert / Tempo trace anomaly / user report>
**Incident Commander**: @<ic-name>
**Started**: <timestamp> UTC
**War Room**: <channel-link>
**Status Page**: <status-page-url>

Current Status: INVESTIGATING
```

#### Status Update (Every 15-30 min)
```markdown
📊 INCIDENT UPDATE - <timestamp> UTC

**Status**: <INVESTIGATING | MITIGATING | RESOLVED>
**Impact**: <current impact>
**Progress**:
- Root cause hypothesis: <hypothesis>
- Mitigation in progress: <action>
- ETA for resolution: <estimate>

Next update: <timestamp>
```

#### Resolution Notification
```markdown
✅ INCIDENT RESOLVED - <timestamp> UTC

**Service**: <service-name>
**Duration**: <duration>
**Resolution**: <root cause summary>
**Impact**: <quantified impact>
**Root Cause**: <root cause summary>

**Next Steps**:
- Postmortem scheduled: <date/time>
- Action items: <count> created
- War room closes: <time>
```

---

## 4. Root Cause Analysis (RCA) with uFawkesObs (15 minutes)

### The 5 Whys with uFawkesObs Data

**Method**: Ask "why" five times using uFawkesObs data

```
Problem: Payment API returning 500 errors

Why #1: Why are we getting 500s?
→ Loki logs show: "connection pool exhausted"
→ Grafana shows: connection pool at 100%

Why #2: Why is connection pool exhausted?
→ Grafana shows: connection pool usage at 100%
→ Prometheus: connection_pool_used / connection_pool_max = 1.0

Why #3: Why is connection pool maxed out?
→ Tempo traces show: new feature "bulk payments" opens 50 connections/request
→ Loki logs: "bulk payments" feature deployed 2 hours ago

Why #3: Why does bulk payments open 50 connections?
→ Code review: connection not returned to pool after batch
→ Missing defer pool.Return() in error path

Why #5: Why wasn't this caught?
→ No load test for bulk payments
→ No connection pool monitoring/alerting

ROOT CAUSE: Missing connection pooling safeguards + no monitoring
```

### Fishbone Diagram (Ishikawa) with uFawkesObs Data

```
                     ┌─────────────────────┐
                     │  Payment API 500s   │
                     └─────────────────────┘
                              │
         ┌────────────────────┼────────────────────┐
         │                    │                    │
     PEOPLE              PROCESS              TECHNOLOGY
         │                    │                    │
   ┌─────┴─────┐        ┌────┴────┐         ┌─────┴─────┐
   │           │        │         │         │           │
Oncall   Training   No load   Manual   Memory    No
tired     lacking   testing   deploy   leak    monitoring
```

### Timeline Reconstruction with uFawkesObs

```markdown
## Incident Timeline (Auto-generated from uFawkesObs)

**14:20 UTC** - Traffic begins increasing (Grafana: request rate)
**14:22 UTC** - Connection pool usage hits 80% (Prometheus: pool_usage > 0.8)
**14:23 UTC** - First timeout errors occur (Loki: "connection pool exhausted")
**14:23 UTC** - Alerts fire: "High Error Rate" (Alertmanager)
**14:24 UTC** - Oncall engineer paged (Alertmanager → PagerDuty)
**14:25 UTC** - Engineer joins war room (Mattermost)
**14:28 UTC** - Incident declared SEV1 (Grafana annotation)
**14:30 UTC** - IC assigned (@alice)
**14:32 UTC** - Investigation begins (Grafana war room)
**14:35 UTC** - Root cause hypothesis: connection pool
**14:37 UTC** - Hypothesis confirmed via Tempo traces (pool exhausted)
**14:40 UTC** - Decision: Scale connection pool
**14:42 UTC** - Config change deployed (ConfigMap update)
**14:45 UTC** - Error rate begins decreasing
**14:50 UTC** - Error rate back to normal
**15:10 UTC** - Incident resolved

**Total Duration**: 47 minutes
**Detection to Mitigation**: 17 minutes
**Mitigation to Resolution**: 28 minutes
```

---

## 5. Blameless Postmortems with uFawkesObs (15 minutes)

### uFawkesObs Postmortem Template

```markdown
# Postmortem: <TITLE>

## Executive Summary

**Date**: YYYY-MM-DD, HH:MM - HH:MM UTC
**Duration**: X minutes
**Severity**: SEV<X>
**Impact**: [User/Business impact quantified]

**Root Cause**: <one sentence>

**Resolution**: <one sentence>

---

## Timeline (Auto-generated from uFawkesObs)

[Auto-generated from Grafana annotations, Loki logs, Alertmanager]

---

## Root Cause Analysis

### Primary Cause
<One sentence root cause>

### Contributing Factors
1. <Factor 1> - <evidence from uFawkesObs>
2. <Factor 2> - <evidence from uFawkesObs>
3. <Factor 3> - <evidence from uFawkesObs>

### Systemic Issues
- [ ] Lack of monitoring on X
- [ ] No chaos experiment for X
- [ ] No runbook for X
- [ ] Manual process for X

---

## What Went Well ✅
- [ ] <Positive aspect>
- [ ] <Positive aspect>

## What Went Wrong ❌
- [ ] <Area for improvement>
- [ ] <Area for improvement>

---

## Action Items

| Action | Owner | Deadline | Status |
|--------|-------|----------|--------|
| <Action> | @owner | <date> | <status> |

---

## Lessons Learned

1. **<Lesson 1>**: <Detail>
2. **<Lesson 2>**: <Detail>

---

## Action Items Tracking

| Action | Owner | Deadline | Status |
|--------|-------|----------|--------|
| <Action> | @owner | <date> | <status> |

---

## Approval

- [ ] Engineering Manager
- [ ] SRE Lead
- [ ] CTO (if SEV0/1)
```

---

## 5. Hands-On Lab (45 minutes)

### Lab Overview

You'll conduct a complete incident response simulation from detection through postmortem using uFawkesObs.

**Scenario**: Payment API experiencing high error rates due to database connection pool exhaustion

**Duration**: 45 minutes
**Difficulty**: Advanced (Modules 13-15 complete required)
**Auto-Graded**: Yes
**Points**: 100

### Lab Environment

**Prerequisites**:
- ✅ Module 13 (Observability) complete
- ✅ Module 14 (DORA Metrics) complete
- ✅ Module 15 (SLI/SLO/Error Budgets) complete
- ✅ uFawkesObs v1.0.0 running with DORA profile (`make up-dora`)

**Tools**: `curl`, `jq`, `git`, `make`, `docker`, `kubectl` (for simulation)

---

### Lab Steps

➡️ **[Lab 01: Full Incident Response Simulation](brown-belt/module-16-incident-management/lab-01/instructions.md)**

This lab walks you through:
1. **Detection**: Alert fires, alertmanager pages oncall
2. **Triage**: IC assigned, war room created, severity assessed
3. **Investigation**: Loki logs, Tempo traces, Prometheus metrics, Grafana dashboards
4. **Mitigation**: Root cause identified, mitigation executed
5. **Resolution**: Fix deployed, verified via Grafana/Prometheus/Loki
6. **Postmortem**: Timeline, RCA, action items in uFawkesObs format

**Validation**: `bash brown-belt/module-16-incident-management/lab-01/validate.sh`

---

## 6. Knowledge Check (10 minutes)

### Quiz: Advanced Incident Management

**Instructions**: Answer all 10 questions. You need 8/10 (80%) to pass. Unlimited attempts allowed.

#### Question 1

**What is the primary goal of incident response?**

- [ ] A) Find who caused the problem
- [x] B) Restore service as quickly as possible
- [ ] C) Write detailed reports
- [ ] D) Prevent all future incidents

**Explanation**: Incident response primary goal is **service restoration**. Blame comes later (if at all) in blameless postmortems.

---

#### Question 2

**What makes a postmortem "blameless"?**

- [ ] A) Not mentioning anyone's name
- [ ] B) Focusing only on technology
- [x] C) Assuming good intentions and learning from systems
- [ ] D) Avoiding technical details

**Explanation**: Blameless = assuming good intentions, focusing on systems/processes, learning from the incident.

---

#### Question 3

**What is the target MTTR for SEV1 incidents?**

- [ ] A) < 5 minutes
- [ ] B) < 15 minutes
- [x] C) < 30 minutes
- [ ] D) < 2 hours

**Explanation**: Elite MTTR for SEV1 is **< 30 minutes** (Google SRE standard).

---

#### Question 4

**What is the role of an Incident Commander?**

- [ ] A) Fix the technical problem
- [x] B) Coordinate response and make decisions
- [ ] C) Write the postmortem
- [ ] D) Page the oncall engineer

**Explanation**: IC coordinates the response, makes decisions, communicates — doesn't necessarily fix the code.

---

#### Question 5

**What is Chaos Engineering?**

- [ ] A) Creating random problems in production
- [ ] B) Testing in chaotic environments
- [x] C) Experimenting to build confidence in system resilience
- [ ] D) Stress testing before launch

**Explanation**: Chaos Engineering = disciplined experimentation on a system to build confidence in its ability to withstand turbulent conditions.

---

#### Question 6

**How often should postmortem action items be reviewed?**

- [ ] A) Never, they're just documentation
- [ ] B) Only when incidents recur
- [x] C) Regularly (weekly/bi-weekly) until complete
- [ ] D) Once at the postmortem meeting

**Explanation**: Action items must be tracked to completion. Weekly/bi-weekly review ensures follow-through.

---

#### Question 7

**What is MTTD?**

- [ ] A) Mean Time To Deploy
- [x] B) Mean Time To Detect
- [ ] C) Mean Time To Document
- [ ] D) Mean Time To Decide

**Explanation**: MTTD = Mean Time To Detect = time from incident start to detection.

---

#### Question 8

**When should you conduct chaos experiments?**

- [ ] A) Only in development
- [ ] B) Only during incidents
- [x] C) Regularly in production with safety measures
- [ ] D) Never, too risky

**Explanation**: Chaos Engineering requires production experiments (with safety measures) to build real confidence.

---

### Quiz Results

**Score: X / 8**

- ✅ **Passed** (8+): Excellent! You understand advanced incident management.
- ❌ **Not Yet** (<8): Review the theory section and try again.

---

## 7. Reflection & Next Steps (5 minutes)

### What You Learned

✅ **You now know**:
- Advanced incident response framework (ICS adapted for SRE)
- Root cause analysis methods (5 Whys, Fishbone, Fault Tree)
- Blameless postmortem facilitation
- Incident response automation (detection → creation → remediation)
- Chaos engineering for proactive reliability
- Metrics for measuring incident management effectiveness

✅ **You can now**:
- Run incident response simulations end-to-end
- Conduct blameless postmortems
- Automate incident creation and response
- Design and run chaos engineering experiments
- Measure and improve incident management maturity

### How This Connects to Your Work

**For SREs/Platform Engineers**:
- You can now design and run GameDays
- You can build incident automation
- You can facilitate blameless postmortems

**For Engineering Leaders**:
- You can measure incident management maturity
- You can justify chaos engineering investment
- You can drive cultural change toward blameless culture

**For Leaders**:
- You can articulate the ROI of incident management investment
- You understand the metrics that matter (MTTR, MTTD, etc.)
- You can champion blameless culture

### Reflection Questions

1. **What surprised you most about incident management with uFawkesObs?**
2. **How does your current incident process compare?**
3. **What automation would have the biggest impact on your MTTR?**
4. **Who on your team should run a GameDay this quarter?**

### Preview: Black Belt

**Next Up: Black Belt - Platform Engineering Mastery**

Modules 17-20:
- Module 17: Platform Architecture & Design
18: Multi-Tenancy & RBAC
19: Cost Optimization & FinOps
20: Platform Team Leadership

**Prerequisites**: Brown Belt complete ✅

---

## Module Completion

### ✅ You've Completed Module 16

**Next Steps**:
1. ✅ Mark this module complete in your Backstage profile
2. 📊 View your progress on the Dojo dashboard
3. 💬 Share your completion in `#dojo-achievements` (optional!)
4. 🎓 **Prepare for Brown Belt Assessment!**

**Time Investment**: 60 minutes
**Skills Gained**: Advanced incident response, RCA, blameless postmortems, automation, chaos engineering
**Progress**: 4 of 4 modules toward Brown Belt (100% complete!)

---

## 🎓 Brown Belt Assessment

### 🏆 You've Completed All Brown Belt Modules!

- ✅ Module 13: Observability with uFawkesObs
- ✅ Module 14: DORA Metrics Deep Dive
- ✅ Module 15: SLIs, SLOs, and Error Budgets
- ✅ Module 16: Advanced Incident Management

**Next**: **Brown Belt Assessment** (2 hours)

- Deploy 2 additional applications (different languages)
- Written exam (30 questions covering modules 13-16)
- Practical troubleshooting scenario
- Passing score: 80%

**Get Ready**: Review all 4 modules, practice labs, schedule exam.

---

## 🎓 Brown Belt Certification

### Exam Format
- 50 multiple choice questions
- 4 hands-on challenges (90 min)
- 85% passing score
- 3-hour time limit

### Hands-on Challenges
1. Build observability stack for new service
2. Configure DORA metrics pipeline
3. Define SLIs/SLOs/error budgets for new service
4. Incident response simulation (MTTR target: < 30 min)

---

### 🎉 Congratulations on Completing Brown Belt!

You've mastered:
- ✅ Observability fundamentals (metrics, logs, traces)
- ✅ DORA metrics automation and analysis
- ✅ SLI/SLO definition and error budget management
- ✅ Advanced incident response and management
- ✅ Blameless postmortem facilitation
- ✅ Chaos engineering for proactive reliability

**Share your achievement**:
- LinkedIn: "Just earned my Brown Belt in Platform Engineering from Fawkes Dojo!"
- Twitter: "Just completed Brown Belt at Fawkes Dojo! 🎉"
- GitHub: Add badge to your profile

**Next Milestone**: Black Belt - Platform Architecture & Leadership

---

## 📚 Additional Resources

### Books
- *Site Reliability Engineering* - Google (free online)
- *The Site Reliability Workbook* - Google
- *Observability Engineering* - Charity Majors et al.
- *Chaos Engineering* - Casey Rosenthal

### Tools & Platforms
- [Chaos Mesh](https://chaos-mesh.org/) - Kubernetes chaos engineering
- [Gremlin](https://www.gremlin.com/) - Chaos engineering platform
- [PagerDuty](https://www.pagerduty.com/) - Incident management
- [Blameless](https://www.blameless.com/) - SRE platform

### Learning Resources
- [Google SRE Books](https://sre.google/books/)
- [Chaos Engineering Principles](https://principlesofchaos.org/)
- [Postmortem Culture](https://sre.google/sre-book/postmortem-culture/)
- [VOID Report](https://void.report/) - Postmortem database

### Community
- [GitHub Discussions](https://github.com/paruff/uFawkesDojo/discussions) - `#dojo-brown-belt`
- Share your certification achievement!
- Help others in `#dojo-white-belt` / `#dojo-yellow-belt`

---

## 🎉 Brown Belt Complete - Congratulations, SRE Practitioner! 🎉

---

### Appendix A: Incident Response Cheat Sheet

#### Severity Assessment (< 1 min):
```
SEV0: Complete outage + data loss
SEV1: Complete outage OR revenue impact
SEV2: Major feature broken
SEV3: Minor degradation
SEV4: Cosmetic issue
```

#### Initial Response (< 5 min):
```
1. Acknowledge alert
2. Assess severity
3. Create war room
4. Assemble team
5. Post initial notification
6. Begin investigation
```

#### Communication Cadence:
```
SEV0/1: Every 15 minutes
SEV2:   Every 30 minutes
SEV3:   Every hour
```

#### Key Commands:
```bash
# Check recent deployments
kubectl rollout history deployment/SERVICE

# View logs
kubectl logs -l app=SERVICE --tail=100

# Rollback
kubectl rollout undo deployment/SERVICE

# Scale
kubectl scale deployment/SERVICE --replicas=10

# Check metrics
curl prometheus:9090/api/v1/query?query=...
```

---

### Appendix B: Postmortem Template (Condensed)

```markdown
# Postmortem: [TITLE]

**Date**: YYYY-MM-DD
**Duration**: X minutes
**Severity**: SEVX
**Impact**: [User/Business impact]

## Timeline

[Key events with timestamps]

## Root Cause

[Primary cause + contributing factors]

## What Went Well ✅
[Positive aspects]

## What Went Wrong ❌
[Areas for improvement]

## Action Items

| Action | Owner | Deadline | Status |
| ------ | ----- | -------- | ------ |
| ...    | ...   | ...      | ...    |

## Lessons Learned
[Key takeaways]
```

---

### Appendix C: Chaos Engineering Safety Checklist

```markdown
## Pre-Flight Checklist

- [ ] Hypothesis clearly defined
- [ ] Expected outcome documented
- [ ] Success criteria established
- [ ] Blast radius minimized (% of traffic/instances)
- [ ] Monitoring in place to observe impact
- [ ] Rollback plan ready
- [ ] Team notified and ready to respond
- [ ] Off-peak hours selected (if applicable)
- [ ] Executive approval (for production experiments)
- [ ] Customer communication plan (if needed)

## During Experiment

- [ ] Monitor metrics in real-time
- [ ] Team ready to abort if needed
- [ ] Document observations
- [ ] Communicate status

## Post-Experiment

- [ ] Validate hypothesis (confirmed/rejected)
- [ ] Document findings
- [ ] Identify improvements
- [ ] Share learnings with team
```

---

**🎉 Congratulations on completing Brown Belt!**

You've achieved mastery in observability, SRE practices, and incident management. You're now equipped to run highly reliable services at scale.

**Ready for Black Belt?** Module 17: Platform Architecture & Design awaits! 🚀

---

**Ready for Black Belt?** Module 17: Platform Architecture & Design awaits! 🚀
