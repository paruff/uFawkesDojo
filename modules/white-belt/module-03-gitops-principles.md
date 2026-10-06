# Module 3: GitOps Principles with uFawkesDevX

**Belt Level**: 🥋 White Belt
**Duration**: 60 minutes
**Prerequisites**: Module 1 & 2 completed, Docker basics, uFawkesDevX v1.0.1 running
**DORA Capabilities**: Continuous Delivery, Deployment Pipeline

---

## 1. Learning Objectives (3 minutes)

### What You'll Learn

By the end of this module, you will be able to:

- ✅ Define GitOps and explain its four core principles (Declarative, Versioned, Pulled, Reconciled)
- ✅ Differentiate between push-based and pull-based deployment models
- ✅ Explain how the Score service provides GitOps-like workload validation and pipeline triggering
- ✅ Describe how Backstage catalog serves as the source of truth for services
- ✅ Understand how uFawkesDevX implements GitOps principles without Kubernetes/ArgoCD
- ✅ Make a GitOps-driven service change using the Score API and Backstage Scaffolder

### Why It Matters

GitOps is a fundamental practice in modern platform engineering:

- **Netflix** deploys 1000+ times per day using GitOps
- **Weaveworks** reported 2x faster deployments with GitOps
- **DORA research** shows GitOps supports improvement across all five delivery metrics
- **90% of cloud-native teams** use or plan to use GitOps (CNCF Survey 2024)

Understanding GitOps is essential for elite delivery performance — and uFawkesDevX brings these principles to your laptop via Docker Compose.

### Success Criteria

You've mastered this module when you can:

- Explain the four GitOps principles and how uFawkesDevX implements them
- Navigate the Backstage catalog as the source of truth
- Register a new service via the Score API and verify it appears in Backstage
- Use the Scaffolder to create a service and understand the pipeline trigger
- Perform a rollback by reverting a Score workload spec

---

## 2. Theory & Concepts (20 minutes)

### 📺 Video: GitOps Principles in uFawkesDevX (8 minutes) — *not produced yet*

> **[VIDEO PLACEHOLDER]** > **Script Summary** *(video not produced)*:
>
> - Opening: Show the problem with manual deployments (drift, no audit trail, slow)
> - GitOps definition: Declarative state in Git, automated reconciliation
> - uFawkesDevX architecture: Score service validates specs, Backstage catalog is source of truth
> - Demo: Register service via Score API → triggers pipeline → appears in Backstage
> - Show rollback: Update spec → revert via Score API
> - Closing: "GitOps without the cluster complexity"

### The Traditional Way: Imperative Operations

**Before GitOps**, deployments were imperative (manual commands):

```bash
# Deployment by running commands
kubectl apply -f deployment.yaml
kubectl set image deployment/myapp myapp=v2.0
kubectl scale deployment/myapp --replicas=5
helm upgrade myapp ./chart --set image.tag=v2.0
terraform apply
```

**Problems**:

- ❌ **No audit trail** - Who made what change, when, and why?
- ❌ **Configuration drift** - Production differs from documented state
- ❌ **No rollback** - Can't easily revert to previous working state
- ❌ **Knowledge silos** - Only certain people know how to deploy
- ❌ **Error-prone** - Manual commands = human mistakes
- ❌ **No code review** - Infrastructure changes not peer-reviewed

### The uFawkesDevX Way: Declarative Workload Specs

**With uFawkesDevX**, you declare desired state as a Score workload spec:

```yaml
# score.yaml - Declarative workload specification
apiVersion: score.dev/v1b1
metadata:
  name: my-service
containers:
  my-service:
    image: ghcr.io/myorg/my-service:latest
    variables:
      PORT: "8080"
service:
  ports:
    www:
      port: 8080
      targetPort: 8080
```

**Score Service** continuously:
1. **Validates** specs against schema when submitted
2. **Triggers** pipeline via webhook to uFawkesPipe
3. **Stores** spec as source of truth in Backstage catalog
4. **Reconciles** by detecting drift between spec and deployed state

**Benefits**:
- ✅ **Complete audit trail** - Every spec change is a Git commit
- ✅ **No drift** - Score service detects and reports differences
- ✅ **Easy rollback** - Revert spec in Git → re-submit
- ✅ **Knowledge sharing** - Backstage catalog documents everything
- ✅ **Reliable** - Automation eliminates human error
- ✅ **Code review** - All changes via pull requests on specs

### Four Principles of GitOps (Applied to uFawkesDevX)

The **OpenGitOps** working group defines four core principles. Here's how uFawkesDevX implements each:

#### 1. Declarative

**Definition**: System's desired state is expressed declaratively (what, not how).

**uFawkesDevX Example**:

```yaml
# Declarative (Score spec) - Describe WHAT you want
apiVersion: score.dev/v1b1
metadata:
  name: my-service
containers:
  my-service:
    image: ghcr.io/myorg/my-service:v2.0
    variables:
      PORT: "8080"
service:
  ports:
    www:
      port: 8080
      targetPort: 8080
```

**Why it matters**: Declarative is idempotent (submit multiple times = same result), easier to understand, and automation-friendly.

#### 2. Versioned and Immutable

**Definition**: Desired state is stored in Git, providing version history and immutability.

**uFawkesDevX Implementation**:
- Score specs stored in Backstage catalog (backed by PostgreSQL with full history)
- Git repository for each service contains `score.yaml`
- Every change has a commit SHA (immutable reference)
- Full history of who changed what, when, and why
- Rollback is just a `git revert` on the score.yaml

**Example**:

```bash
# View deployment history
git log score.yaml

# See what changed
git diff HEAD~1 score.yaml

# Rollback to previous version
git revert HEAD
# Re-submit to Score service
curl -X POST http://localhost:8000/api/score/specs -d @score.yaml
```

#### 3. Pulled Automatically

**Definition**: Software agents automatically pull desired state from Git (not pushed).

**Traditional Push Model** (CI/CD):

```
CI/CD System (Tekton/Woodpecker)
         │
         ↓ Push changes
         │ (when triggered)
         │
    Target Environment
```

**uFawkesDevX Pull Model** (Score Service):

```
Git Repository (source of truth)
         ↑
         │ Poll for changes / Webhook
         │
    Score Service
         │
         ├─→ Validates spec
         ├─→ Triggers uFawkesPipe webhook
         └─→ Updates Backstage catalog
```

**Why Pull is Better**:
- ✅ **More secure** - Target credentials not in CI/CD system
- ✅ **Self-healing** - Detects and reports drift automatically
- ✅ **Better failure handling** - Retries automatically
- ✅ **Audit trail** - All changes go through Git (no backdoors)

#### 4. Continuously Reconciled

**Definition**: Software agents continuously ensure actual state matches desired state.

**uFawkesDevX Reconciliation Loop**:

```
1. Score service receives spec submission
2. Validates against score.dev/v1b1 schema
3. Stores spec in Backstage catalog
4. Triggers uFawkesPipe pipeline via webhook
5. Pipeline builds, tests, deploys
6. Score service monitors deployment status
7. If drift detected (manual change, failure), reports in Backstage
8. User corrects by updating spec in Git → repeat
```

**Self-Healing Example**:

```bash
# Someone manually changes deployment in target environment
# Score service detects drift on next reconciliation
# Backstage shows: "OutOfSync - actual state differs from spec"
# User corrects by updating score.yaml and re-submitting
```

**Benefits**:
- Prevents configuration drift
- Recovers from manual mistakes automatically
- Ensures target always matches spec
- Reduces operational toil

---

## 3. GitOps and DORA Metrics (10 minutes)

### How GitOps Improves Deployment Frequency

**Deployment Frequency**: How often you deploy to production

**Without GitOps**:
- Manual deployments require coordination
- Fear of breaking production slows deploys
- Need specific people with access
- Result: Weekly or monthly deployments

**With uFawkesDevX GitOps**:
- Merge to main → Score API submission → automatic pipeline
- Git PR process provides confidence
- Any developer can submit spec (with approval)
- Result: Multiple deployments per day

**Example Flow**:

```bash
# Developer workflow
git checkout -b feature/new-endpoint
# Make changes to application code
# Update score.yaml with new image tag
git commit -m "Add new API endpoint"
git push origin feature/new-endpoint
# Create pull request
# After approval and merge to main:
# → Submit score.yaml to Score API
# → Score triggers uFawkesPipe webhook
# → Pipeline builds, tests, deploys
# → Backstage catalog updated
```

### How GitOps Reduces Lead Time for Changes

**Lead Time for Changes**: Time from commit to production

**Without GitOps**:
```
Commit → Wait for CI → Manual deployment steps → Production
         (10 min)      (30-60 min manual work)
Total: 40-70 minutes
```

**With uFawkesDevX GitOps**:
```
Commit → CI builds → Submit score.yaml → Score triggers pipeline → Production
         (10 min)    (1 min)             (2-5 min)
Total: 13-16 minutes
```

**Key Difference**: Elimination of manual deployment steps. The Score service + uFawkesPipe handles it all.

### How GitOps Lowers Change Failure Rate

**Change Failure Rate**: % of deployments causing failures

**Without GitOps**:
- Manual commands prone to errors
- No code review of infrastructure changes
- Difficult to test changes before production
- Configuration drift introduces unknowns
- Result: 15-20% failure rate typical

**With uFawkesDevX GitOps**:
- Declarative specs easier to review in PR
- Pull requests catch errors before merge
- Can test in staging (identical Score workflow)
- No drift means fewer surprises
- Result: 3-5% failure rate achievable

**Safety Mechanisms**:
1. **Git History**: Every spec change reviewed and auditable
2. **Dry Run**: Score service shows validation results before triggering
3. **Progressive Pipeline**: uFawkesPipe stages (lint → test → build → deploy)
4. **Automatic Rollback**: Failed deployments can be reverted via `git revert` + re-submit

### How GitOps Improves Time to Restore Service

**Time to Restore Service**: Time to recover from failure

**Without GitOps**:
```
Incident detected → Find person with access → Figure out what changed →
Run commands to fix → Hope it works
Total: 30-60 minutes (or more)
```

**With uFawkesDevX GitOps**:
```
Incident detected → git revert HEAD → Submit spec → Pipeline deploys rollback
Total: 3-5 minutes
```

**Example**:

```bash
# Quick rollback
git log --oneline  # Find commit to revert to
git revert abc123  # Creates new commit that undoes abc123
git push           # CI/CD picks up revert

# Re-submit rolled-back spec
curl -X POST http://localhost:8000/api/score/specs -d @score.yaml
# Score triggers pipeline with previous version
# Service restored in minutes
```

---

## 4. uFawkesDevX GitOps Architecture (10 minutes)

### The Score Service as GitOps Engine

The **Score Service** is the heart of uFawkesDevX's GitOps implementation:

```
┌─────────────────────────────────────────────────────────────────────┐
│                         uFawkesDevX Stack                           │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐         │
│  │   Git Repo   │───▶│ Score Service│───▶│ uFawkesPipe  │         │
│  │  (score.yaml)│    │  (Validator) │    │  (Pipeline)  │         │
│  └──────────────┘    └──────┬───────┘    └──────┬───────┘         │
│                             │                   │                  │
│                             ▼                   ▼                  │
│                    ┌──────────────┐    ┌──────────────┐           │
│                    │  Backstage   │    │  Deployed    │           │
│                    │   Catalog    │    │  Service     │           │
│                    │ (Source of   │    │  (Actual     │           │
│                    │  Truth)      │    │   State)     │           │
│                    └──────────────┘    └──────────────┘           │
└─────────────────────────────────────────────────────────────────────┘
```

### Score Service Responsibilities

| Responsibility | Description |
|----------------|-------------|
| **Spec Validation** | Validates `score.yaml` against `score.dev/v1b1` schema |
| **Spec Storage** | Stores validated specs, serves via API |
| **Pipeline Trigger** | POSTs to uFawkesPipe webhook with workload info |
| **Catalog Sync** | Updates Backstage catalog with spec metadata |
| **Drift Detection** | Compares spec with deployed state (future) |

### Backstage Catalog as Source of Truth

The **Backstage Catalog** is the single source of truth for all services:

- Each registered service has a catalog entity
- Entity metadata includes: name, owner, type, lifecycle, APIs, spec reference
- TechDocs renders `README.md` and `score.yaml` as documentation
- Scaffolder creates new services from templates
- Search and discovery across all services

### Golden Path Templates

**Cookiecutter templates** provide pre-wired GitOps-ready services:

```
templates/python-flask-app/
├── {{cookiecutter.project_slug}}/
│   ├── .devcontainer/devcontainer.json
│   ├── score.yaml                 # ← Score workload spec
│   ├── .fawkespipe.yml            # ← uFawkesPipe CI/CD contract
│   ├── Dockerfile
│   ├── src/app.py
│   ├── tests/
│   └── README.md
```

Every scaffolded service includes:
- **Score spec** — declares desired state
- **Pipeline contract** — defines build/test/deploy stages
- **Devcontainer** — consistent development environment
- **Tests** — validates functionality

---

## 5. Hands-On Lab (15 minutes)

### Lab Overview

You'll use the running uFawkesDevX stack from Module 1 to:
1. Explore the Backstage catalog (source of truth)
2. Register a new service via the Score API
3. Create a service using the Backstage Scaffolder
4. Observe the GitOps-like workflow
5. Practice rollback by reverting a spec

**Time Estimate**: 15 minutes
**Difficulty**: Beginner (Module 1 completion required)
**Auto-Graded**: Yes
**Points**: 50

### Lab Environment

**Prerequisites**: uFawkesDevX v1.0.1 running from Module 1
- ✅ Backstage at http://localhost:7007
- ✅ Score Service at http://localhost:8000/api/score
- ✅ Coder at CODER_ACCESS_URL
- ✅ Your `hello-devx` service from Module 1 already registered

➡️ **[Lab 01: GitOps Workflow with Score Service](white-belt/module-03-gitops-principles/lab-01/instructions.md)**

This lab walks you through using the Score API to register services, the Backstage Scaffolder to create new services, and practicing rollback — all demonstrating GitOps principles without Kubernetes.

**Validation**: `bash white-belt/module-03-gitops-principles/lab-01/validate.sh`

---

## 6. Knowledge Check (5 minutes)

### Quiz: GitOps Principles in uFawkesDevX

**Instructions**: Answer all 10 questions. You need 8/10 (80%) to pass. Unlimited attempts allowed.

#### Question 1

**What are the four principles of GitOps?**

- [ ] A) Declarative, Versioned, Pushed, Reconciled
- [x] B) Declarative, Versioned, Pulled, Reconciled
- [ ] C) Imperative, Versioned, Pulled, Reconciled
- [ ] D) Declarative, Mutable, Pulled, Reconciled

**Explanation**: The four OpenGitOps principles are: **Declarative**, **Versioned and Immutable**, **Pulled Automatically**, and **Continuously Reconciled**.

---

#### Question 2

**In uFawkesDevX, which component validates Score workload specs?**

- [ ] A) Backstage
- [ ] B) Coder
- [x] C) Score Service
- [ ] D) Plugin Manager

**Explanation**: The **Score Service** validates `score.yaml` against the `score.dev/v1b1` schema and stores the validated spec.

---

#### Question 3

**What is the key difference between GitOps (pull) and traditional CI/CD (push)?**

- [ ] A) Push is more secure
- [x] B) Pull model doesn't require cluster credentials in CI/CD
- [ ] C) Push model has self-healing
- [ ] D) Pull model requires manual intervention

**Explanation**: In the **pull model**, the agent (Score Service) runs inside the environment and pulls from Git — no cluster credentials needed in CI/CD. This is more secure and enables self-healing.

---

#### Question 4

**How does GitOps improve Lead Time for Changes?**

- [ ] A) By adding more manual approval steps
- [x] B) By eliminating manual deployment steps through automation
- [ ] C) By requiring more code reviews
- [ ] D) By slowing down the pipeline for safety

**Explanation**: GitOps reduces lead time by **eliminating manual steps** — merge to Git → automatic pipeline → production. Typical improvement: 40-70 min → 10-15 min.

---

#### Question 5

**In uFawkesDevX, what triggers the uFawkesPipe pipeline?**

- [ ] A) Backstage Scaffolder directly
- [ ] B) Coder workspace creation
- [x] C) Score Service webhook after spec validation
- [ ] D) Manual curl command

**Explanation**: The **Score Service** validates the spec, then POSTs to the uFawkesPipe webhook URL to trigger the build/test/deploy pipeline.

---

#### Question 6

**What serves as the "source of truth" in uFawkesDevX?**

- [ ] A) The Git repository alone
- [ ] B) The deployed containers
- [x] C) The Backstage Catalog (backed by Score Service specs)
- [ ] D) The uFawkesPipe pipeline

**Explanation**: The **Backstage Catalog** stores the validated Score specs and serves as the source of truth. It's the "Git" in GitOps for uFawkesDevX.

---

#### Question 7

**How do you rollback a service in uFawkesDevX GitOps?**

- [ ] A) `kubectl rollout undo`
- [ ] B) Manually edit the deployed container
- [x] C) `git revert` the score.yaml, then re-submit to Score API
- [ ] D) Delete and recreate the service in Backstage

**Explanation**: Rollback is a **Git operation** — `git revert` the spec commit, then re-submit the reverted `score.yaml` to the Score API. The pipeline deploys the previous version.

---

#### Question 8

**Which file in a golden path template declares the desired state for GitOps?**

- [ ] A) `.fawkespipe.yml`
- [ ] B) `Dockerfile`
- [x] C) `score.yaml`
- [ ] D) `.devcontainer/devcontainer.json`

**Explanation**: The **`score.yaml`** is the Score workload spec (score.dev/v1b1) that declares the desired state — containers, variables, services, resources.

---

#### Question 9

**What happens when Score Service detects drift between spec and deployed state?**

- [ ] A) Automatically fixes it without notification
- [ ] B) Deletes the service
- [x] C) Reports "OutOfSync" in Backstage catalog for user action
- [ ] C) Ignores it until next deployment

**Explanation**: Score Service reports drift in Backstage (shows "OutOfSync"). The **user** corrects by updating the spec in Git and re-submitting — this is the GitOps reconciliation loop.

---

#### Question 10

**Why should Score workload specs be in Git rather than only in Backstage?**

- [ ] A) Backstage doesn't persist data
- [x] B) Git provides version history, code review, and rollback capability
- [ ] C) Score Service requires Git
- [ ] D) Backstage catalog is read-only

**Explanation**: **Git provides version history, code review via PRs, and rollback via `git revert`** — these are core GitOps benefits. Backstage catalog reflects the Git state.

---

### Quiz Results

**Score: X / 10**

- ✅ **Passed** (8+): Great job! You're ready to move to the next section.
- ❌ **Not Yet** (<8): Review the content and try again. Focus on areas you missed.

**Incorrect answers?** Each question links back to the relevant section for review.

---

## 7. Reflection & Next Steps (5 minutes)

### What You Learned

Congratulations! 🎉 You've completed Module 3. Let's recap:

✅ **You now understand**:
- The four GitOps principles and how uFawkesDevX implements them
- How Score Service validates specs and triggers pipelines
- How Backstage catalog serves as the source of truth
- How GitOps improves all five DORA metrics
- The uFawkesDevX golden path template pattern

✅ **You can now**:
- Register a service via the Score API
- Create a service using the Backstage Scaffolder
- Verify the GitOps workflow in Backstage
- Perform a rollback by reverting a spec

### How This Connects to Your Work

**For Developers**:
- You now understand how to declare desired state instead of running commands
- You know where to find service specs (Backstage catalog)
- You can use golden path templates for consistent, GitOps-ready services

**For Platform Engineers**:
- You understand your role in maintaining the GitOps engine (Score service, pipelines)
- You know how to treat developers as customers with self-service GitOps
- You can articulate the value of the GitOps workflow to stakeholders

**For Leaders**:
- You can explain how GitOps accelerates delivery and reduces risk
- You understand the metrics that matter (DORA, deployment frequency, MTTR)
- You can make the case for platform investments in GitOps automation

### Reflection Questions

Take 2 minutes to think about:

1. **What surprised you most about GitOps in uFawkesDevX?**

    - Was there a concept that changed your perspective on deployments?

2. **How does your current deployment workflow compare?**

    - Are you using GitOps? Manual? CI/CD push? Somewhere in between?

3. **What would improve your deployment experience?**

    - If you could wave a magic wand, what would you change about how you deploy?

4. **Who could benefit from this knowledge?**

    - Think of 2-3 colleagues who should go through this module

### Additional Resources

**📚 Further Reading**:
- [OpenGitOps Principles](https://opengitops.dev/) - Official GitOps principles
- [Score Specification](https://score.dev/docs/reference/score-spec/) - Score workload spec reference
- [Backstage Catalog](https://backstage.io/docs/features/software-catalog/) - Catalog documentation
- [DORA Research](https://dora.dev) - Research behind DORA metrics

**🎥 Videos to Watch**:
- "What is GitOps?" by Weaveworks (10 min)
- "GitOps with ArgoCD" by TechWorld with Nana (20 min)
- "Score.dev Introduction" (15 min)

**💬 Community**:
- Ask questions in [GitHub Discussions](https://github.com/paruff/uFawkesDojo/discussions) ([Q&A](https://github.com/paruff/uFawkesDojo/discussions/categories/q-a))
- Share your "aha!" moments
- Help others who are just starting

### Preview: Module 4

**Next Up: Your First Deployment - End-to-End**

In Module 4, you'll bring everything together:

- Use Backstage Scaffolder to create a complete service
- Configure the full CI/CD pipeline via `.fawkespipe.yml`
- Deploy and observe the service in the target environment
- View DORA metrics for your deployment
- Practice the complete developer workflow

**Time**: 60 minutes
**Hands-On**: Full service lifecycle from template to production

**Get Ready**: Think about a service you'd like to create. What language? What framework?

---

## Module Completion

### ✅ You've Completed Module 3

**Next Steps**:

1. ✅ Mark this module complete in your Backstage profile
2. 📊 View your progress on the Dojo dashboard
3. 💬 Share your completion in [Show and tell](https://github.com/paruff/uFawkesDojo/discussions/categories/show-and-tell) (optional but encouraged!)
4. ➡️ **Continue to Module 4** when ready

**Time Investment**: 60 minutes
**Skills Gained**: GitOps principles, Score API, Backstage Scaffolder, rollback procedures
**Progress**: 3 of 4 modules toward White Belt (75% complete)

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
**Version**: 2.0
