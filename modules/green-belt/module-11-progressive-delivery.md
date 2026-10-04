# Fawkes Dojo Module 11: Progressive Delivery

## 🎯 Module Overview

**Belt Level**: 🟢 Green Belt - GitOps & Deployment
**Module**: 3 of 4 (Green Belt)
**Duration**: 60 minutes
**Difficulty**: Advanced
**Prerequisites**:

- Module 9 & 10 complete
- Understanding of canary deployments
- Familiarity with Prometheus metrics
- Basic knowledge of automated analysis

---

## 📚 Learning Objectives

By the end of this module, you will:

1. ✅ Understand progressive delivery vs continuous delivery
2. ✅ Implement automated canary analysis with metrics
3. ✅ Configure Argo Rollouts for progressive deployment
4. ✅ Set up automatic promotion and rollback based on metrics
5. ✅ Use analysis templates for decision-making
6. ✅ Implement traffic shaping and weighted routing
7. ✅ Monitor and visualize progressive rollouts

**DORA Capabilities Addressed**:

- ✓ CD2: Automate deployment process (fully automated)
- ✓ Team Experimentation
- ✓ Monitoring and Observability (deployment metrics)

---

## 📖 Part 1: What is Progressive Delivery?

### Continuous Delivery vs Progressive Delivery

**Continuous Delivery**:

```
Code → Build → Test → Deploy to Production
                              ↓
                    All users get new version
                    Hope it works! 🤞
```

**Progressive Delivery**:

```
Code → Build → Test → Deploy to 5% users
                              ↓
                        Analyze metrics
                              ↓
                     Healthy? → Deploy to 25%
                              ↓
                        Analyze metrics
                              ↓
                     Healthy? → Deploy to 50%
                              ↓
                        Analyze metrics
                              ↓
                     Healthy? → Deploy to 100%

                     Unhealthy? → Automatic Rollback ✅
```

### Key Differences

| Aspect         | Continuous Delivery       | Progressive Delivery   |
| -------------- | ------------------------- | ---------------------- |
| **Deployment** | All-at-once               | Gradual, phased        |
| **Risk**       | High (all users affected) | Low (small % affected) |
| **Rollback**   | Manual, reactive          | Automated, proactive   |
| **Analysis**   | Post-deployment           | During deployment      |
| **Decision**   | Human judgment            | Metrics-driven         |
| **Speed**      | Fast (minutes)            | Controlled (hours)     |

### Progressive Delivery Components

```
┌─────────────────────────────────────────────────────┐
│         Progressive Delivery System                  │
├─────────────────────────────────────────────────────┤
│                                                      │
│  ┌──────────────────────────────────────────────┐  │
│  │     Traffic Management                       │  │
│  │  • Istio / Nginx / Traefik                  │  │
│  │  • Weighted routing (5% → 25% → 50% → 100%)│  │
│  └────────────────┬─────────────────────────────┘  │
│                   │                                  │
│  ┌────────────────▼─────────────────────────────┐  │
│  │     Metrics Collection                       │  │
│  │  • Prometheus (error rate, latency, etc.)   │  │
│  │  • Custom business metrics                  │  │
│  └────────────────┬─────────────────────────────┘  │
│                   │                                  │
│  ┌────────────────▼─────────────────────────────┐  │
│  │     Analysis Engine                          │  │
│  │  • Argo Rollouts / Flagger                  │  │
│  │  • Compares baseline vs canary              │  │
│  │  • Automated decision: promote or rollback  │  │
│  └────────────────┬─────────────────────────────┘  │
│                   │                                  │
│  ┌────────────────▼─────────────────────────────┐  │
│  │     Notification & Observability             │  │
│  │  • Slack / PagerDuty alerts                 │  │
│  │  • Grafana dashboards                       │  │
│  └──────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
```

---

## 🎯 Part 2: Argo Rollouts

### What is Argo Rollouts?

Argo Rollouts is a Kubernetes controller that provides advanced deployment strategies with automated analysis.

**Key Features**:

- 🎯 Canary deployments with traffic shaping
- 🔵🟢 Blue-Green deployments
- 📊 Automated metric analysis
- ⏸️ Manual approval gates
- 🔄 Automatic rollback on failure
- 📈 Integration with Prometheus, Datadog, etc.

### Installing Argo Rollouts

```bash
# Install Argo Rollouts controller
kubectl create namespace argo-rollouts
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml

# Install kubectl plugin
curl -LO https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-amd64
chmod +x kubectl-argo-rollouts-linux-amd64
sudo mv kubectl-argo-rollouts-linux-amd64 /usr/local/bin/kubectl-argo-rollouts

# Verify installation
kubectl argo rollouts version
```

---

## 🛠️ Part 3: Hands-On Lab - Progressive Canary — *not built yet*

### Step 1: Deploy Baseline Application

Create `rollout.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: myapp
spec:
  ports:
    - port: 80
      targetPort: 8080
      protocol: TCP
      name: http
  selector:
    app: myapp
---
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: myapp
spec:
  replicas: 5
  strategy:
    canary:
      steps:
        - setWeight: 20 # Step 1: 20% traffic to canary
        - pause: { duration: 2m } # Wait 2 minutes
        - setWeight: 40 # Step 2: 40% traffic
        - pause: { duration: 2m }
        - setWeight: 60 # Step 3: 60% traffic
        - pause: { duration: 2m }
        - setWeight: 80 # Step 4: 80% traffic
        - pause: { duration: 2m }
      # Step 5: 100% (automatic)
  revisionHistoryLimit: 2
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
        - name: myapp
          image: argoproj/rollouts-demo:blue
          ports:
            - name: http
              containerPort: 8080
              protocol: TCP
          resources:
            requests:
              memory: 32Mi
              cpu: 5m
```

Deploy:

```bash
kubectl apply -f rollout.yaml

# Check status
kubectl argo rollouts get rollout myapp --watch
```

### Step 2: Update to Trigger Rollout

```bash
# Update image to new version
kubectl argo rollouts set image myapp myapp=argoproj/rollouts-demo:yellow

# Watch the progressive rollout
kubectl argo rollouts get rollout myapp --watch
```

**Expected Output**:

```
Name:            myapp
Namespace:       default
Status:          ॥ Paused
Message:         CanaryPauseStep
Strategy:        Canary
  Step:          1/8
  SetWeight:     20
  ActualWeight:  20
Images:          argoproj/rollouts-demo:blue (stable)
                 argoproj/rollouts-demo:yellow (canary)
Replicas:
  Desired:       5
  Current:       6
  Updated:       1
  Ready:         6
  Available:     6

NAME                           KIND        STATUS     AGE  INFO
⟳ myapp                        Rollout     ॥ Paused   5m
├──# revision:2
│  └──⧉ myapp-789746c88d       ReplicaSet  ✔ Healthy  30s  canary
│     └──□ myapp-789746c88d-x  Pod         ✔ Running  30s  ready:1/1
└──# revision:1
   └──⧉ myapp-6c5c5d8f9b       ReplicaSet  ✔ Healthy  5m   stable
      ├──□ myapp-6c5c5d8f9b-a  Pod         ✔ Running  5m   ready:1/1
      ├──□ myapp-6c5c5d8f9b-b  Pod         ✔ Running  5m   ready:1/1
      ├──□ myapp-6c5c5d8f9b-c  Pod         ✔ Running  5m   ready:1/1
      └──□ myapp-6c5c5d8f9b-d  Pod         ✔ Running  5m   ready:1/1
```

### Step 3: Manual Promotion

```bash
# Promote to next step
kubectl argo rollouts promote myapp

# Or skip all pauses and go to 100%
kubectl argo rollouts promote myapp --full
```

### Step 4: Rollback if Issues

```bash
# Abort rollout and revert to stable
kubectl argo rollouts abort myapp

# Or undo to previous revision
kubectl argo rollouts undo myapp
```

---

## 📊 Part 4: Automated Analysis

### Analysis Templates

Define success criteria using metrics:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: success-rate
spec:
  args:
    - name: service-name
  metrics:
    - name: success-rate
      interval: 1m
      successCondition: result[0] >= 0.95
      failureLimit: 3
      provider:
        prometheus:
          address: http://prometheus:9090
          query: |
            sum(rate(
              http_requests_total{
                service="{{args.service-name}}",
                status!~"5.."
              }[5m]
            ))
            /
            sum(rate(
              http_requests_total{
                service="{{args.service-name}}"
              }[5m]
            ))
    - name: latency
      interval: 1m
      successCondition: result[0] <= 500
      failureLimit: 3
      provider:
        prometheus:
          address: http://prometheus:9090
          query: |
            histogram_quantile(0.95,
              sum(rate(
                http_request_duration_seconds_bucket{
                  service="{{args.service-name}}"
                }[5m]
              )) by (le)
            ) * 1000
```

### Integrating Analysis with Rollout

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: myapp
spec:
  replicas: 5
  strategy:
    canary:
      steps:
        - setWeight: 20
        - pause: { duration: 1m }
        - analysis:
            templates:
              - templateName: success-rate
            args:
              - name: service-name
                value: myapp
        - setWeight: 40
        - pause: { duration: 1m }
        - analysis:
            templates:
              - templateName: success-rate
            args:
              - name: service-name
                value: myapp
        - setWeight: 60
        - pause: { duration: 1m }
        - analysis:
            templates:
              - templateName: success-rate
            args:
              - name: service-name
                value: myapp
        - setWeight: 80
        - pause: { duration: 1m }
        - analysis:
            templates:
              - templateName: success-rate
            args:
              - name: service-name
                value: myapp
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
        - name: myapp
          image: myapp:v1.0
          ports:
            - containerPort: 8080
```

**How it works**:

1. Deploy 20% canary
2. Wait 1 minute
3. Run analysis (check success rate and latency)
4. If analysis passes → proceed to 40%
5. If analysis fails 3 times → automatic rollback
6. Repeat for each step

---

## 🎯 Part 5: Advanced Analysis Patterns

### Baseline vs Canary Comparison

Compare canary metrics against baseline:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: compare-baseline
spec:
  args:
    - name: service-name
    - name: baseline-hash
    - name: canary-hash
  metrics:
    - name: error-rate-comparison
      interval: 1m
      successCondition: result[0] <= 1.25 # Canary error rate < 125% of baseline
      failureLimit: 3
      provider:
        prometheus:
          address: http://prometheus:9090
          query: |
            (sum(rate(
              http_requests_total{
                service="{{args.service-name}}",
                version="{{args.canary-hash}}",
                status=~"5.."
              }[5m]
            )) or vector(0))
            /
            (sum(rate(
              http_requests_total{
                service="{{args.service-name}}",
                version="{{args.baseline-hash}}",
                status=~"5.."
              }[5m]
            )) or vector(0))
    - name: latency-comparison
      interval: 1m
      successCondition: result[0] <= 1.2 # Canary latency < 120% of baseline
      failureLimit: 3
      provider:
        prometheus:
          address: http://prometheus:9090
          query: |
            (histogram_quantile(0.95,
              sum(rate(
                http_request_duration_seconds_bucket{
                  service="{{args.service-name}}",
                  version="{{args.canary-hash}}"
                }[5m]
              )) by (le)
            ))
            /
            (histogram_quantile(0.95,
              sum(rate(
                http_request_duration_seconds_bucket{
                  service="{{args.service-name}}",
                  version="{{args.baseline-hash}}"
                }[5m]
              )) by (le)
            ))
```

### Custom Business Metrics

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: business-metrics
spec:
  args:
    - name: service-name
  metrics:
    - name: revenue-per-request
      interval: 2m
      successCondition: result[0] >= 0.95 # Revenue shouldn't drop >5%
      failureLimit: 2
      provider:
        prometheus:
          address: http://prometheus:9090
          query: |
            sum(rate(
              revenue_total{service="{{args.service-name}}"}[5m]
            ))
            /
            sum(rate(
              http_requests_total{service="{{args.service-name}}"}[5m]
            ))

    - name: conversion-rate
      interval: 2m
      successCondition: result[0] >= 0.02 # At least 2% conversion
      failureLimit: 2
      provider:
        prometheus:
          address: http://prometheus:9090
          query: |
            sum(rate(
              conversions_total{service="{{args.service-name}}"}[5m]
            ))
            /
            sum(rate(
              page_views_total{service="{{args.service-name}}"}[5m]
            ))
```

### External Analysis Providers

**Datadog**:

```yaml
metrics:
  - name: datadog-error-rate
    provider:
      datadog:
        apiVersion: v1
        interval: 5m
        query: |
          avg:trace.http.request.errors{service:{{args.service-name}}}
          .as_rate()
```

**New Relic**:

```yaml
metrics:
  - name: newrelic-apdex
    provider:
      newRelic:
        profile: my-newrelic-account
        query: |
          SELECT apdex(duration)
          FROM Transaction
          WHERE appName = '{{args.service-name}}'
```

**Custom Web API**:

```yaml
metrics:
  - name: custom-health-check
    provider:
      web:
        url: https://my-health-api.com/check?service={{args.service-name}}
        jsonPath: "{$.health.status}"
    successCondition: result == "healthy"
```

---

## 🌐 Part 6: Traffic Management

### Traffic Shaping with Istio

For precise traffic control:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: myapp
spec:
  replicas: 5
  strategy:
    canary:
      canaryService: myapp-canary
      stableService: myapp-stable
      trafficRouting:
        istio:
          virtualService:
            name: myapp
            routes:
              - primary
      steps:
        - setWeight: 10
        - pause: { duration: 2m }
        - setWeight: 20
        - pause: { duration: 2m }
        - setWeight: 30
        - pause: { duration: 2m }
        - setWeight: 50
        - pause: {} # Manual approval
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
        - name: myapp
          image: myapp:v2.0
---
apiVersion: v1
kind: Service
metadata:
  name: myapp-stable
spec:
  selector:
    app: myapp
  ports:
    - port: 80
      targetPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: myapp-canary
spec:
  selector:
    app: myapp
  ports:
    - port: 80
      targetPort: 8080
---
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: myapp
spec:
  hosts:
    - myapp
  http:
    - name: primary
      route:
        - destination:
            host: myapp-stable
          weight: 100
        - destination:
            host: myapp-canary
          weight: 0
```

**Argo Rollouts automatically updates weights in VirtualService!**

### Header-Based Routing

Route specific users to canary:

```yaml
strategy:
  canary:
    trafficRouting:
      istio:
        virtualService:
          name: myapp
    canaryMetadata:
      annotations:
        role: canary
    stableMetadata:
      annotations:
        role: stable
    steps:
      - setCanaryScale:
          weight: 25
      - setHeaderRoute:
          name: canary-by-header
          match:
            - headerName: X-Canary
              headerValue:
                exact: "true"
      - pause: {}
```

Now users with `X-Canary: true` header get canary version!

---

## 📈 Part 7: Observability and Monitoring

### Rollout Dashboard

Access Argo Rollouts dashboard:

```bash
kubectl argo rollouts dashboard

# Open browser to http://localhost:3100
```

**Dashboard shows**:

- Current rollout status
- Traffic weights
- Analysis results
- Pod health
- Rollout history

### Grafana Dashboard

Create custom Grafana dashboard:

```json
{
  "dashboard": {
    "title": "Progressive Delivery",
    "panels": [
      {
        "title": "Canary vs Stable Success Rate",
        "targets": [
          {
            "expr": "sum(rate(http_requests_total{version=\"canary\",status!~\"5..\"}[5m])) / sum(rate(http_requests_total{version=\"canary\"}[5m]))",
            "legendFormat": "Canary"
          },
          {
            "expr": "sum(rate(http_requests_total{version=\"stable\",status!~\"5..\"}[5m])) / sum(rate(http_requests_total{version=\"stable\"}[5m]))",
            "legendFormat": "Stable"
          }
        ]
      },
      {
        "title": "Rollout Progress",
        "targets": [
          {
            "expr": "argo_rollouts_info{rollout=\"myapp\"}"
          }
        ]
      },
      {
        "title": "Analysis Status",
        "targets": [
          {
            "expr": "argo_rollouts_analysis_run_phase{rollout=\"myapp\"}"
          }
        ]
      }
    ]
  }
}
```

### Prometheus Metrics

Argo Rollouts exposes metrics:

```promql
# Rollout phase (Progressing, Paused, Healthy, etc.)
argo_rollouts_info{namespace="default",rollout="myapp"}

# Current step
argo_rollouts_phase{namespace="default",rollout="myapp"}

# Analysis run results
argo_rollouts_analysis_run_metric_phase{
  namespace="default",
  rollout="myapp",
  metric="success-rate"
}

# Rollout duration
argo_rollouts_rollout_duration_seconds{namespace="default",rollout="myapp"}
```

---

## 💪 Part 8: Practical Exercise

### Exercise: Implement Full Progressive Delivery

**Objective**: Deploy with automated analysis and rollback

**Scenario**: You have a critical e-commerce application. Implement progressive delivery with:

1. 4-step canary (10% → 25% → 50% → 100%)
2. Automated analysis at each step
3. Check: error rate, latency, conversion rate
4. Automatic rollback if metrics degrade
5. Manual approval before 100%

**Requirements**:

1. Create Rollout with canary strategy
2. Define AnalysisTemplate with 3 metrics
3. Configure traffic routing (Istio or Nginx)
4. Integrate with Prometheus
5. Set up Slack notifications
6. Test rollback scenario

**Starter Template**:

```yaml
# rollout.yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: ecommerce-app
spec:
  replicas: 10
  strategy:
    canary:
      steps:
        - setWeight: 10
        - pause: { duration: 2m }
        - analysis:
            templates:
              - templateName: ecommerce-health
      # TODO: Add remaining steps
  # TODO: Complete configuration

---
# analysis-template.yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: ecommerce-health
spec:
  # TODO: Define metrics
  metrics:
    - name: error-rate
      # TODO: Configure Prometheus query
    - name: latency-p95
      # TODO: Configure Prometheus query
    - name: conversion-rate
      # TODO: Configure Prometheus query
```

**Validation Criteria**:

- [ ] Rollout deploys progressively (10% → 25% → 50% → 100%)
- [ ] Analysis runs at each step
- [ ] Metrics collected from Prometheus
- [ ] Automatic promotion if healthy
- [ ] Automatic rollback if unhealthy
- [ ] Manual approval before 100%
- [ ] Slack notification on rollback
- [ ] Dashboard shows real-time status

---

## 🎓 Part 9: Knowledge Check

### Quiz Questions

1. **What's the main difference between CD and Progressive Delivery?**

   - [ ] Speed of deployment
   - [x] Automated analysis and gradual rollout
   - [ ] Number of environments
   - [ ] Cost

2. **What does Argo Rollouts use to make promotion decisions?**

   - [ ] Random selection
   - [ ] Time-based only
   - [x] Metrics analysis and success conditions
   - [ ] Manual approval only

3. **In an AnalysisTemplate, what is failureLimit?**

   - [ ] Maximum deployment failures allowed
   - [x] Number of times metric can fail before rollback
   - [ ] Timeout duration
   - [ ] Percentage threshold

4. **What happens if analysis fails during a canary rollout?**

   - [ ] Deployment pauses indefinitely
   - [ ] Continues to next step anyway
   - [x] Automatic rollback to stable version
   - [ ] Manual intervention required

5. **Which traffic management option provides most precise control?**

   - [ ] Kubernetes Service
   - [x] Istio VirtualService
   - [ ] NodePort
   - [ ] LoadBalancer

6. **What is the purpose of baseline vs canary comparison?**

   - [ ] Save costs
   - [x] Detect regressions by comparing versions
   - [ ] Speed up deployment
   - [ ] Reduce complexity

7. **When should you use manual approval gates?**

   - [ ] Every deployment
   - [ ] Never, always automate
   - [x] Before high-risk steps like 100% rollout
   - [ ] Only in development

8. **What metric provider can Argo Rollouts integrate with?**
   - [ ] Only Prometheus
   - [ ] Only Datadog
   - [ ] Only custom webhooks
   - [x] Multiple providers (Prometheus, Datadog, New Relic, etc.)

**Answers**: 1-B, 2-C, 3-B, 4-C, 5-B, 6-B, 7-C, 8-D

---

## 🎯 Part 10: Module Summary & Next Steps

### What You Learned

✅ **Progressive Delivery**: Automated, metrics-driven rollouts
✅ **Argo Rollouts**: Advanced Kubernetes deployment controller
✅ **Automated Analysis**: Decision-making based on metrics
✅ **Traffic Shaping**: Precise control with Istio/Nginx
✅ **Rollback Automation**: Automatic revert on failure
✅ **Observability**: Monitoring rollout health

### DORA Capabilities Achieved

- ✅ **CD2**: Fully automated deployment with safety
- ✅ **Team Experimentation**: Safe to test in production
- ✅ **Monitoring**: Deployment metrics integrated

### Key Takeaways

1. **Automate decisions** - Let metrics drive promotion/rollback
2. **Compare versions** - Baseline vs canary reveals regressions
3. **Start small** - 5-10% canary catches most issues
4. **Multiple metrics** - Error rate + latency + business metrics
5. **Manual gates for critical steps** - Humans approve 100% rollout

### Real-World Impact

"After implementing progressive delivery:

- **Bad deploy detection**: 30 minutes → 2 minutes
- **User impact from bad deploys**: 100% → 5%
- **Manual rollbacks**: 15 per month → 0 per month
- **Deployment confidence**: 70% → 98%
- **Mean time to detect issues**: 20 min → 2 min

We deploy to production during business hours without fear."

- *SRE Team, E-Commerce Platform*

---

## 📚 Additional Resources

### Documentation

- [Argo Rollouts](https://argoproj.github.io/argo-rollouts/)
- [Flagger](https://flagger.app/)
- [Progressive Delivery](https://www.split.io/glossary/progressive-delivery/)

### Tools

- [Argo Rollouts](https://github.com/argoproj/argo-rollouts)
- [Flagger](https://github.com/fluxcd/flagger)
- [Kayenta](https://github.com/spinnaker/kayenta) - Automated canary analysis

---

## 🏅 Module Completion

### Assessment Checklist

- [ ] **Conceptual Understanding**

  - [ ] Explain progressive delivery vs CD
  - [ ] Understand automated analysis
  - [ ] Know when to use manual gates

- [ ] **Practical Skills**

  - [ ] Configure Argo Rollouts
  - [ ] Create AnalysisTemplates
  - [ ] Integrate with Prometheus
  - [ ] Set up traffic management
  - [ ] Test automated rollback

- [ ] **Hands-On Lab**

  - [ ] Deploy with progressive rollout
  - [ ] Analysis runs successfully
  - [ ] Automatic promotion works
  - [ ] Automatic rollback works

- [ ] **Quiz**
  - [ ] Score 80% or higher (6/8 questions)

### Certification Credit

Upon completion, you earn:

- **5 points** toward Green Belt certification (75% complete)
- **Badge**: "Progressive Delivery Expert"
- **Skill Unlocked**: Automated Canary Analysis

---

## 🎖️ Green Belt Progress

```
Green Belt: GitOps & Deployment
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Module 9:  GitOps with ArgoCD     ████████░░░░ 25% ✓
Module 10: Deployment Strategies  ████████░░░░ 50% ✓
Module 11: Progressive Delivery   ████████░░░░ 75% ✓
Module 12: Rollback & Incident    ░░░░░░░░░░░░  0%
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Almost there!** One more module to Green Belt! 🎉

**Next Module Preview**: Module 12 - Rollback & Incident Response (Fast recovery, runbooks, postmortems)

---

**🎉 Congratulations!** You now know how to implement fully automated, metrics-driven progressive delivery!

**Ready for the final Green Belt module?** Let's learn incident response and rollback strategies! 🚀

---

*Fawkes Dojo - Where Platform Engineers Are Forged*
*Version 1.0 | Last Updated: October 2025*
*License: MIT | https://github.com/paruff/fawkes*
