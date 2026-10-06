# Module 2: DORA Metrics - The North Star

**Belt Level**: 🥋 White Belt
**Duration**: 60 minutes
**Prerequisites**: Module 1 completed
**DORA Capabilities**: Monitoring and Observability, Continuous Delivery

---

## 1. Learning Objectives (3 minutes)

### What You'll Learn

By the end of this module, you will be able to:

- ✅ Explain the five DORA metrics and why they predict software delivery performance
- ✅ Differentiate between Elite, High, Medium, and Low performers using data
- ✅ Calculate each DORA metric for your team
- ✅ Interpret DORA metrics dashboards and identify improvement opportunities
- ✅ Understand how Fawkes automates DORA metrics collection
- ✅ Articulate the business impact of improving these metrics

### Why It Matters

**The Research**: The DORA (DevOps Research and Assessment) team spent 9 years studying 32,000+ organizations to answer one question:

> _"What separates high-performing software teams from everyone else?"_

**The Discovery**: A small set of delivery metrics predicts organizational performance better than activity measures. Organizations that excel at these metrics are:

- **2x more likely** to exceed profitability goals
- **2x more likely** to exceed productivity goals
- **2x more likely** to exceed customer satisfaction goals
- **50% more likely** to have higher market share

> **Current model**: DORA uses five software delivery performance metrics.
> **Deployment Rework Rate** joined the model to measure unplanned deployments
> made in response to production incidents. The metrics are grouped into
> throughput (Deployment Frequency, Change Lead Time, and Failed Deployment
> Recovery Time) and instability (Change Fail Rate and Deployment Rework Rate).
> See [DORA's metrics guide](https://dora.dev/guides/dora-metrics/) for the
> current definitions.

**Your Opportunity**: These aren't vanity metrics—they're **predictive indicators** of success. Understanding and improving them is literally your competitive advantage.

### Success Criteria

You've mastered this module when you can:

- Explain each metric to a non-technical executive in business terms
- Look at a DORA dashboard and immediately spot problems
- Calculate metrics for your own team
- Recommend specific improvements based on metric trends
- Understand how platform engineering improves all five metrics

---

## 2. Theory & Concepts (15 minutes)

### 📺 Video: The DORA Metrics Explained (7 minutes) — _not built yet_

> **[VIDEO PLACEHOLDER]** > **See detailed script in supporting document** _(video not produced)_

### The Five DORA Metrics

DORA identifies five metrics that matter most for software delivery performance:

#### 1. 🚀 Deployment Frequency (DF)

**Definition**: How often does your organization deploy code to production?

**Why It Matters**: Deployment frequency is a proxy for **batch size**. Small, frequent deployments mean:

- Lower risk (less can go wrong)
- Faster feedback (find problems sooner)
- Faster time to market (features reach customers quickly)
- Better team morale (see your work in production)

**Performance Levels**:

- **Elite**: Multiple deployments per day (on-demand)
- **High**: Between once per day and once per week
- **Medium**: Between once per week and once per month
- **Low**: Between once per month and once every six months

**Example**:

- **Low Performer**: "We deploy every 2 months during maintenance windows"
- **Elite Performer**: "We deploy 50+ times per day automatically"

**How Fawkes Tracks It**: Every ArgoCD sync to production is recorded as a deployment event.

---

#### 2. ⏱️ Lead Time for Changes (LT)

**Definition**: How long does it take for a commit to go from version control to running in production?

**Why It Matters**: Lead time measures **efficiency**. Short lead times mean:

- Faster feature delivery to customers
- Quicker response to market changes
- Reduced work-in-progress inventory
- Higher developer satisfaction

**Performance Levels**:

- **Elite**: Less than one hour
- **High**: Between one day and one week
- **Medium**: Between one month and six months
- **Low**: More than six months

**Example**:

- **Low Performer**: "I wrote this code 3 months ago. Still waiting for QA approval."
- **Elite Performer**: "I committed code 20 minutes ago. It's already in production."

**How Fawkes Tracks It**: Measures time from Git commit to successful ArgoCD sync in production.

**Important**: This is NOT "time to write code." It's "time code sits waiting" in your process.

---

#### 3. 🔧 Time to Restore Service (MTTR)

**Definition**: How long does it take to restore service when an incident occurs?

**Why It Matters**: MTTR measures **resilience**. Fast recovery means:

- Less customer impact from incidents
- Lower stress for on-call engineers
- Better SLAs and reliability
- Confidence to move fast (you can recover quickly)

**Performance Levels**:

- **Elite**: Less than one hour
- **High**: Less than one day
- **Medium**: Between one day and one week
- **Low**: More than one week

**Example**:

- **Low Performer**: "Production is down. We need a 5-hour emergency change board meeting."
- **Elite Performer**: "Production issue detected. Automatic rollback completed in 4 minutes."

**How Fawkes Tracks It**: Measures time from incident creation (Alertmanager) to resolution (successful deployment or rollback).

---

#### 4. ❌ Change Failure Rate (CFR)

**Definition**: What percentage of deployments cause failures in production?

**Why It Matters**: CFR measures **quality**. Low failure rates mean:

- Sustainable velocity (not breaking things constantly)
- Lower operational burden
- Better customer experience
- More time for feature development (less firefighting)

**Performance Levels**:

- **Elite**: 0-15%
- **High**: 16-30%
- **Medium**: 16-30%
- **Low**: 16-30%

**Note**: 2023 research collapsed High/Medium/Low into same range. Elite performers stand out with <15%.

**Example**:

- **Low Performer**: "Every Friday deployment requires weekend hotfixes."
- **Elite Performer**: "We deploy 100 times per week with 5% failure rate."

**How Fawkes Tracks It**: Compares successful deployments to failed deployments (rollbacks, incidents within 24 hours of deploy).

**Important**: Some failure is expected and healthy! 0% might mean you're too risk-averse.

---

#### 5. ♻️ Deployment Rework Rate (DRR)

**Definition**: What percentage of deployments are unplanned work performed in
response to a production incident?

**Why It Matters**: DRR exposes delivery capacity spent repairing production
problems. A lower rate means:

- More deployment capacity goes toward planned customer value
- Incidents create less follow-up work
- Teams can distinguish planned delivery from recovery work

**Example**: A team makes 50 deployments in a month. Five are unplanned fixes
for production incidents, so its Deployment Rework Rate is 10%.

**How Fawkes Tracks It**: Marks incident-driven deployments and divides them by
all deployments in the same period.

---

### The Performance Spectrum

The legacy performance bands below cover the established benchmarked measures.
Track Deployment Rework Rate alongside them and aim for a downward trend.

| Performance | Deployment Freq          | Lead Time          | MTTR           | Change Fail Rate |
| ----------- | ------------------------ | ------------------ | -------------- | ---------------- |
| **Elite**   | On-demand (multiple/day) | < 1 hour           | < 1 hour       | 0-15%            |
| **High**    | 1/day - 1/week           | 1 day - 1 week     | < 1 day        | 16-30%           |
| **Medium**  | 1/week - 1/month         | 1 week - 1 month   | 1 day - 1 week | 16-30%           |
| **Low**     | 1/month - 6/months       | 1 month - 6 months | > 1 week       | 16-30%           |

**Key Insight**: Elite performers are **417x faster** at deploying and **6,570x faster** at going from commit to production than low performers!

---

### Why These Five Metrics?

#### They Balance Speed and Stability

**Speed Metrics**:

- Deployment Frequency
- Lead Time for Changes

**Stability Metrics**:

- Failed Deployment Recovery Time
- Change Failure Rate
- Deployment Rework Rate

You can't optimize for speed alone (you'll break everything) or stability alone (you'll move too slowly). High-performing teams improve throughput and stability together.

#### They're Predictive, Not Descriptive

These metrics don't just describe performance—they **predict business outcomes**:

- **Profitability**: Teams with high DORA metrics are 2x more likely to exceed profitability targets
- **Market Share**: 50% more likely to have higher market share
- **Productivity**: 2x more likely to exceed productivity goals
- **Customer Satisfaction**: 2x more likely to have happy customers

#### They Focus on Outcomes, Not Activities

Bad metrics: Lines of code written, hours worked, tickets closed
Good metrics (DORA): How fast you deliver value and how reliably

---

### The Business Case for DORA Metrics

#### Scenario: Legacy Bank vs. Digital Startup

**Legacy Bank** (Low Performer):

- Deploys every 3 months
- Lead time: 4 months from idea to production
- MTTR: 3 days (requires emergency change approval)
- CFR: 25% (1 in 4 releases has issues)

**Impact**:

- New credit card feature takes 1 year to launch (competitors launch in 6 weeks)
- When mobile app crashes, customers can't access accounts for 3 days
- Developer turnover: 35% annually (frustration with slow process)

**Digital Startup** (Elite Performer):

- Deploys 20x per day
- Lead time: 2 hours from commit to production
- MTTR: 15 minutes (automated rollback)
- CFR: 8% (rigorous testing catches issues)

**Impact**:

- New feature ideas tested with customers within days
- Production incidents resolved in minutes, not days
- Developer retention: 95% (engineers love working there)

**Result**: Startup captures 30% market share in 2 years despite having 1/100th the resources.

---

### How Platform Engineering Improves DORA Metrics

A well-designed platform (like Fawkes) directly improves all five metrics:

#### Deployment Frequency ↑

- **Automation**: CI/CD pipelines remove manual deployment steps
- **Self-Service**: Teams deploy when ready, no waiting for tickets
- **Reduced Fear**: Good testing and rollback make deployments safe

#### Lead Time ↓

- **Automated Testing**: No waiting for manual QA
- **Fast Pipelines**: Optimized builds complete in minutes
- **Simplified Process**: Golden paths remove decision paralysis

#### MTTR ↓

- **Observability**: Know immediately when things break
- **Quick Rollback**: Automated rollback via GitOps
- **Runbooks**: Standardized incident response

#### Change Failure Rate ↓

- **Quality Gates**: Automated security scanning, testing
- **Consistent Patterns**: Golden paths reduce errors
- **Progressive Delivery**: Canary deployments catch issues early

#### Deployment Rework Rate ↓

- **Incident Correlation**: Connect repair deployments to the incidents that caused them
- **Root-Cause Learning**: Feed recurring failure patterns back into platform guardrails
- **Planned Recovery**: Standardize rollback and remediation paths so fixes require less rework

**The Platform Advantage**: Manual processes hit scaling limits. Platforms enable teams to improve metrics continuously.

---

### Common Misconceptions

#### ❌ "We can't measure that in our organization"

**Reality**: If you deploy software, you can measure these metrics. Start simple with manual tracking if needed.

#### ❌ "Our industry is different; this doesn't apply"

**Reality**: DORA research spans every industry from finance to gaming to healthcare. The metrics apply universally.

#### ❌ "We need to slow down to improve quality"

**Reality**: Elite performers deploy MORE frequently AND have LOWER change failure rates. Speed and stability go together.

#### ❌ "Our legacy systems prevent us from improving"

**Reality**: Legacy systems are a constraint, not an excuse. Many elite performers maintain legacy systems.

#### ❌ "Leadership only cares about features, not metrics"

**Reality**: These metrics predict revenue, market share, and profitability. Leadership should care.

#### ❌ "100% success rate is the goal"

**Reality**: Some failure is healthy. Elite performers have 8-15% CFR because they're taking appropriate risks.

---

### How Fawkes Automates DORA Metrics

Fawkes collects DORA metrics automatically from your CI/CD pipeline:

```
Developer commits code
    ↓
Git webhook triggers CI pipeline
    ↓ (Lead Time measurement starts)
CI builds, tests, packages
    ↓
Artifact pushed to Harbor registry
    ↓
ArgoCD detects new image version
    ↓
ArgoCD syncs to Kubernetes (Deployment event recorded)
    ↓ (Lead Time measurement ends)
Prometheus records metrics
    ↓
Grafana dashboard updates in real-time
    ↓
Alertmanager detects any incidents
    ↓ (MTTR measurement if incident occurs)
```

**Data Sources**:

- **Git**: Commit timestamps (lead time start)
- **CI** (Tekton on Fawkes, Woodpecker on uFawkesPipe): Build results (quality signals)
- **ArgoCD**: Deployment events (DF, lead time end, CFR)
- **Prometheus/Alertmanager**: Incident detection and resolution (MTTR)

**No Manual Work Required**: Metrics update automatically with every deployment.

---

## 3. Demonstration (10 minutes)

### 📺 Video: Navigating Fawkes DORA Dashboards (10 minutes) — _not built yet_

> **[VIDEO PLACEHOLDER]** > **See detailed script in supporting document** _(video not produced)_

### Key Takeaways from Demo

1. **Real-Time Updates**: Metrics update with every deployment
2. **Multiple Views**: Team-level, service-level, and organization-level dashboards
3. **Drill-Down Capability**: Click any metric to see underlying data
4. **Trend Analysis**: Compare current period to previous periods
5. **Actionable Insights**: Dashboard highlights improvement opportunities

---

## 4. Hands-On Lab (20 minutes)

> **Update (2026)**: This section previously described a simulated,
> LMS-provisioned lab ("click Start Lab", auto-graded submissions,
> fictional Team Alpha/Bravo/Charlie sample data). That environment was
> never built. It has been replaced with a real lab that runs against
> [uFawkesObs](https://github.com/paruff/uFawkesObs)'s actual,
> self-contained DORA pipeline — you send real events over HTTP and watch
> real dashboard panels respond.

➡️ **[Lab 01: See DORA Metrics Live in Grafana](../../white-belt/module-02-dora-metrics/lab-01/instructions.md)**

In this lab you will:

- Start uFawkesObs's Docker Compose stack (`make up-dora` — no Kubernetes
  required)
- Tour the already-built `DORA Overview` and `DORA Metrics` Grafana
  dashboards as a worked example
- Send a real deployment event via `curl` and watch Deployment Frequency
  move within about a minute
- Send a failed deployment and watch Change Failure Rate respond
- Answer retrieval-practice questions to check your own understanding

**Time Estimate**: 20 minutes
**Difficulty**: Beginner
**Validation**: `bash lab-01/validate.sh` (script-checked, not manually graded)

---

## 5. Knowledge Check (5 minutes)

### Quiz: DORA Metrics Mastery

**Instructions**: Answer all 10 questions. You need 8/10 (80%) to pass. Unlimited attempts allowed.

#### Question 1

**Which metric measures "how often" you deploy to production?**

- [x] A) Deployment Frequency
- [ ] B) Lead Time for Changes
- [ ] C) Mean Time to Restore
- [ ] D) Change Failure Rate

**Explanation**: **Deployment Frequency** measures how often deployments occur.

---

#### Question 2

**An elite performer's Lead Time for Changes is:**

- [x] A) Less than one hour
- [ ] B) Between one day and one week
- [ ] C) Less than one day
- [ ] D) Between one hour and one day

**Explanation**: Elite performers have lead times **less than one hour** from commit to production.

---

#### Question 3

**What does MTTR stand for?**

- [ ] A) Mean Time To Release
- [ ] B) Mean Time To Recover
- [x] C) Mean Time To Restore (Service)
- [ ] D) Mean Time To Rollback

**Explanation**: MTTR is **Mean Time To Restore Service**—how long it takes to recover from incidents.

---

#### Question 4

**Elite performers have a Change Failure Rate of:**

- [x] A) 0-15%
- [ ] B) 16-30%
- [ ] C) Less than 5%
- [ ] D) 31-45%

**Explanation**: Elite performers maintain a CFR of **0-15%**, significantly better than other performers.

---

#### Question 5

**What does Deployment Rework Rate measure?**

- [ ] A) Deployments that fail before reaching production
- [x] B) Unplanned deployments made in response to production incidents
- [ ] C) Code changes requested during review
- [ ] D) Time spent refactoring planned features

**Explanation**: Deployment Rework Rate is the percentage of deployments that
are unplanned responses to production incidents.

---

#### Question 6

**Your team deploys once per month. What performance level is this?**

- [ ] A) Elite
- [ ] B) High
- [x] C) Medium
- [ ] D) Low

**Explanation**: Once per month is **Medium** performance (between once per week and once per month).

---

#### Question 7

**Lead Time for Changes measures:**

- [ ] A) Time spent writing code
- [x] B) Time from commit to production
- [ ] C) Time in code review
- [ ] D) Time spent in planning

**Explanation**: Lead time is **commit to production**—how long code waits in your process.

---

#### Question 8

**Why do DORA metrics matter to business leaders?**

- [ ] A) They're required for compliance
- [x] B) They predict profitability, market share, and customer satisfaction
- [ ] C) They make engineers look good
- [ ] D) They're easy to game

**Explanation**: DORA metrics are **predictive of business outcomes**—2x more likely to exceed profitability goals, etc.

---

#### Question 9

**A team has 20 deployments and 5 failures in a month. What's their CFR?**

- [ ] A) 5%
- [ ] B) 15%
- [x] C) 25%
- [ ] D) 50%

**Explanation**: CFR = (5 failures / 20 deploys) × 100 = **25%**

---

#### Question 10

**How does a platform like Fawkes improve DORA metrics?**

- [ ] A) By forcing teams to deploy more frequently
- [ ] B) By hiding failure metrics
- [x] C) By automating pipelines, testing, and providing fast feedback
- [ ] D) By reducing the number of engineers needed

**Explanation**: Platforms improve metrics through **automation, quality gates, and fast feedback loops**—making the right things easy.

---

### Quiz Results

**Score: X / 10**

- ✅ **Passed** (8+): Excellent! You understand DORA metrics deeply.
- ❌ **Not Yet** (<8): Review the content and try again.

---

## 6. Reflection & Next Steps (5 minutes)

### What You Learned

Congratulations! 🎉 You've completed Module 2. Let's recap:

✅ **You now understand**:

- The five DORA metrics and what they measure
- Why these metrics predict business success
- How to calculate and interpret DORA metrics
- The difference between Elite and Low performers
- How Fawkes automates metrics collection

✅ **You can now**:

- Analyze DORA dashboards and spot issues
- Make data-driven recommendations for improvement
- Explain metrics to business stakeholders
- Use metrics to prioritize platform improvements

### How This Connects to Your Work

**For Developers**:

- You understand what "good" looks like (Elite benchmarks)
- You can advocate for improvements using data
- You know how to track your team's progress

**For Platform Engineers**:

- You can measure platform impact objectively
- You know which improvements matter most
- You can demonstrate ROI to leadership

**For Leaders**:

- You have a data-driven framework for investment decisions
- You can benchmark against industry standards
- You can track improvement over time

### Real-World Application Exercise

**This Week, Try This**:

1. **Measure Your Current State**

   - Track deployments for one week
   - Calculate your team's current DORA metrics
   - Be honest—no judgment, just data

2. **Identify One Improvement**

   - Pick the metric with the most room for improvement
   - Brainstorm 3 concrete actions to improve it
   - Estimate impact and effort

3. **Share Your Findings**
   - Present current state to your team (5 min standup)
   - Discuss: "What's our biggest bottleneck?"
   - Agree on one improvement to try

### Reflection Questions

Take 2 minutes to think about:

1. **Which metric surprised you most?**

   - Did your team's performance match your intuition?

2. **What's your team's biggest opportunity?**

   - Which metric, if improved, would have the most impact?

3. **What's blocking improvement?**

   - Technical debt? Process issues? Cultural resistance?

4. **Who needs to know this?**
   - Which leader should see your team's DORA metrics?

### Additional Resources

**📚 Further Reading**:

- [DORA State of DevOps Report](https://dora.dev/research) - Annual research findings
- [Accelerate Book](https://itrevolution.com/accelerate-book/) - The foundational research
- [DORA Quick Check](https://dora.dev/quickcheck/) - Assess your team in 5 minutes
- [Google Cloud DORA Resources](https://cloud.google.com/blog/products/devops-sre/the-2023-accelerate-state-of-devops-report-is-here) - Implementation guides

**🎥 Videos to Watch**:

- "DORA Metrics Explained" by Dr. Nicole Forsgren (15 min)
- "Why DORA Metrics Matter" by Gene Kim (20 min)
- "Implementing DORA Metrics" by Charity Majors (30 min)

**🛠️ Tools**:

- [Four Keys Project](https://github.com/dora-team/fourkeys) - Open source DORA metrics tool
- [Sleuth](https://www.sleuth.io/) - Commercial DORA tracking (Fawkes alternative)
- [LinearB](https://linearb.io/) - Engineering intelligence platform

**💬 Community**:

- Share your team's metrics (anonymously!) in [Show and tell](https://github.com/paruff/uFawkesDojo/discussions/categories/show-and-tell)
- Join the DORA community discussions
- Help others interpret their data

### Preview: Module 3

**Next Up: GitOps Principles**

In Module 3, you'll learn:

- What GitOps is and why it's transforming deployments
- Declarative infrastructure and desired state
- How ArgoCD implements GitOps
- Pull-based vs. push-based deployments
- Making your first GitOps change

**Time**: 60 minutes
**Hands-On**: Make a GitOps deployment using ArgoCD

**Get Ready**: Think about how your team currently deploys applications. Who has access? How is it documented? What could go wrong?

---

## Module Completion

### ✅ You've Completed Module 2

**Next Steps**:

1. ✅ Mark this module complete in your Backstage profile
2. 📊 View your progress on the Dojo dashboard
3. 💬 Share your DORA metrics insights in [Show and tell](https://github.com/paruff/uFawkesDojo/discussions/categories/show-and-tell)
4. ➡️ **Continue to Module 3** when ready

**Time Investment**: 60 minutes
**Skills Gained**: DORA metrics analysis, performance benchmarking
**Progress**: 2 of 4 modules toward White Belt (50% complete)

---

**Questions or Issues?**

- 💬 Ask in [GitHub Discussions](https://github.com/paruff/uFawkesDojo/discussions) ([Q&A](https://github.com/paruff/uFawkesDojo/discussions/categories/q-a))
- 📧 Email: dojo@ufawkes.dev
- 🐛 Report bugs: [GitHub Issues](https://github.com/paruff/fawkes/issues)

**Feedback?**

- Rate this module (takes 30 seconds)
- What worked well? What could be better?
- Help us improve the learning experience!

---

**Module Author**: Fawkes Learning Team
**Last Updated**: August 2026 — added the DORA five-metric update and
replaced the simulated Hands-On Lab with a real lab against uFawkesObs
**Version**: 1.1
**Based On**: DORA State of DevOps 2023 Report; five-metric update per
[dora.dev](https://dora.dev/guides/dora-metrics-four-keys/) (2025)
