# Module 4: Your First Deployment with uFawkesDevX

**Belt Level**: 🥋 White Belt
**Duration**: 60 minutes
**Prerequisites**: Modules 1, 2, and 3 completed, uFawkesDevX v1.0.1 running
**DORA Capabilities**: Continuous Delivery, Deployment Automation

---

## 1. Learning Objectives (3 minutes)

### What You'll Learn

By the end of this module, you will be able to:

- ✅ Create a service using the Backstage Scaffolder and a golden path template
- ✅ Navigate the deployment workflow: Score spec → validation → pipeline trigger → catalog update
- ✅ Monitor deployment progress through Backstage, Score Service, and uFawkesPipe
- ✅ Verify application health and accessibility in Coder workspace
- ✅ Understand how DORA metrics are captured via Score Service + uFawkesPipe
- ✅ Troubleshoot common deployment issues in the uFawkesDevX stack

### Why It Matters

**The Milestone**: This is the moment you've been building toward—your first end-to-end deployment on the uFawkesDevX platform.

**Real-World Impact**: According to DORA research, organizations that master deployment automation:

- Deploy **973 times more frequently** than low performers
- Have **6,570 times faster** lead time for changes
- Have **3 times lower** change failure rate

**Your Journey**: In the next hour, you'll experience what elite performers do dozens of times per day—safely deploying code with full observability, all running in Docker Compose on your laptop.

### Success Criteria

You've mastered this module when you can:

- Create a service end-to-end using the Scaffolder
- Explain each stage of the uFawkesDevX deployment workflow
- Find and interpret deployment status across Backstage, Score API, and uFawkesPipe
- Identify when a deployment succeeded or failed
- Access your deployed application in a Coder workspace

---

## 2. Theory & Concepts (15 minutes)

### 📺 Video: The uFawkesDevX Deployment Workflow (7 minutes) — *not produced yet*

> **[VIDEO PLACEHOLDER]** > **Script Summary** *(video not produced)*:
>
> - Opening: Show the full deployment workflow diagram
> - Scaffolder → Score spec → validation → uFawkesPipe webhook → Coder workspace
> - Each stage explained with real-time visualization
> - Observability: Where to find logs and metrics at each stage
> - DORA metrics: How they're automatically captured
> - Closing: "From template to running app in minutes, not months"

### The uFawkesDevX Deployment Workflow

When you deploy on uFawkesDevX, your code flows through a streamlined pipeline:

```
Developer → Scaffolder → Score Spec → Score Service → uFawkesPipe → Coder Workspace → 🎉
   You       (Backstage)   (Git)        (Validate)      (Woodpecker)   (Devcontainer)  Live!
```

Let's break down each stage:

#### Stage 1: Create from Template (Backstage Scaffolder)

**What Happens**: You use the Backstage Scaffolder to generate a new service from a golden path template.

**Behind the Scenes**:
- Scaffolder runs Cookiecutter template (e.g., `python-flask-app`)
- Generates: `score.yaml`, `.fawkespipe.yml`, `.devcontainer/`, `Dockerfile`, tests, `README.md`
- Creates Git repository with the scaffolded code
- Opens the new component in Backstage catalog

**Your Role**: Fill in template parameters (name, description, owner, image registry)

**Time**: < 2 minutes

---

#### Stage 2: Workload Spec Submission (Score Service)

**What Happens**: The scaffolded `score.yaml` is submitted to the Score Service for validation and registration.

**Behind the Scenes**:
- Score Service validates `score.yaml` against `score.dev/v1b1` schema
- Stores spec in Backstage catalog as source of truth
- Triggers uFawkesPipe webhook with workload metadata
- Returns spec ID for tracking

**Your Role**: Submit spec via Score API (automated in Scaffolder template, or manual `curl`)

**Time**: < 30 seconds

**Success Indicators**:
- ✅ Spec validation passes
- ✅ Spec ID returned
- ✅ Component appears in Backstage catalog

---

#### Stage 3: CI/CD Pipeline (uFawkesPipe / Woodpecker)

**What Happens**: uFawkesPipe (Woodpecker CI) runs the pipeline defined in `.fawkespipe.yml`.

**Behind the Scenes**:
1. **Lint**: Runs language-appropriate linter (ruff for Python, etc.)
2. **Test**: Executes unit tests
3. **Build**: Creates container image using Cloud Native Buildpacks (CNB)
4. **Push**: Uploads image to registry (ghcr.io by default)
5. **Deploy**: Updates deployment target (in full platform, this would be Kubernetes)

**Your Role**: Monitor pipeline in Woodpecker UI or via Score Service webhook status

**Time**: 3-8 minutes (depending on project size)

**Success Indicators**:
- ✅ All tests pass
- ✅ No critical security vulnerabilities
- ✅ Container image tagged with commit SHA
- ✅ Image pushed to registry

---

#### Stage 4: Development Workspace (Coder)

**What Happens**: Coder provisions a devcontainer workspace from the scaffolded repository.

**Behind the Scenes**:
- Coder reads `.devcontainer/devcontainer.json` from the repo
- Builds/starts container with pinned Python 3.12 image
- Mounts workspace volume, installs dependencies
- Provides VS Code web IDE or SSH access

**Your Role**: Open workspace in browser or VS Code, verify application runs

**Time**: 1-3 minutes for first start

**Success Indicators**:
- ✅ Workspace status: "Running"
- ✅ Application starts on localhost:8080
- ✅ Health endpoint returns 200 OK

---

#### Stage 5: Observability & DORA Metrics

Every deployment automatically updates your DORA metrics:

**Deployment Frequency**:
- Incremented when uFawkesPipe pipeline completes successfully
- Visible in Backstage catalog or uFawkesPipe UI

**Lead Time for Changes**:
- Start: Git commit timestamp (when Scaffolder creates repo)
- End: Pipeline completion timestamp
- Calculated automatically

**Change Failure Rate**:
- If pipeline fails or rollback needed within 24 hours → counted as failure
- Visible as percentage in Backstage/uFawkesPipe

**Mean Time to Restore (MTTR)**:
- Start: Pipeline failure timestamp
- End: Successful re-run timestamp
- Only measured if failure occurs

**No Manual Work Required**: The platform captures everything automatically via Score Service + uFawkesPipe integration.

---

### Golden Path Templates

uFawkesDevX provides **golden path templates**—pre-configured application scaffolds that include everything you need:

**What's Included**:
- ✅ Application code structure
- ✅ `score.yaml` — Score workload spec (declarative desired state)
- ✅ `.fawkespipe.yml` — uFawkesPipe CI/CD contract
- ✅ `.devcontainer/devcontainer.json` — Coder workspace definition
- ✅ `Dockerfile` — Container image build
- ✅ `README.md` — Documentation (renders as TechDocs in Backstage)
- ✅ `tests/` — Automated testing setup

**Available Templates** (in uFawkesDevX v1.0.1):
| Template | Language | Framework |
|----------|----------|-----------|
| `python-flask-app` | Python 3.12 | Flask |
| `java-spring-app` | Java 21 | Spring Boot |
| `node-express-app` | Node.js 20 | Express |
| `go-http-app` | Go 1.22 | net/http |

**Why Golden Paths?**
- **Consistency**: Every app follows the same patterns
- **Best Practices**: Security, testing, monitoring built-in
- **Speed**: Start from working example, customize as needed
- **Learning**: See how the pieces fit together

---

### Common Deployment Patterns

#### Pattern 1: Scaffolder → Score API → Pipeline (MVP)

```
Scaffolder → Score API → uFawkesPipe → Coder Workspace
```

**When to Use**: Learning, prototyping, small teams
**Risk Level**: Low (all in Docker Compose)

#### Pattern 2: Manual Score Spec → Pipeline

```
Write score.yaml → curl Score API → uFawkesPipe → Coder
```

**When to Use**: Custom services not from template, migration
**Risk Level**: Low

#### Pattern 3: Full Platform (Production)

```
Scaffolder → Score API → uFawkesPipe → Kubernetes (via ArgoCD)
```

**When to Use**: Production deployment, multi-environment
**Risk Level**: Managed by platform team

**uFawkesDevX MVP**: Uses Pattern 1 by default — all local, no cluster needed.

---

### Troubleshooting: Where to Look

**Scaffolder Template Fails**:
- **Where**: Backstage Scaffolder logs, or task progress UI
- **How**: Click on task in Scaffolder → view logs
- **Common Issues**: Template not found, parameter validation failed, Git push failed

**Score API Returns 422**:
- **Where**: Score Service logs (`docker logs developerd-score`)
- **How**: Check request body against `score.dev/v1b1` schema
- **Common Issues**: Missing required fields, invalid YAML, schema violation

**Pipeline Fails in uFawkesPipe**:
- **Where**: Woodpecker UI (port 8000) → pipeline logs
- **How**: Click on pipeline run → view stage logs
- **Common Issues**: Test failures, linter errors, Docker build errors, registry auth

**Coder Workspace Won't Start**:
- **Where**: Coder UI → workspace logs
- **How**: Check `CODER_ACCESS_URL` is LAN IP (not localhost)
- **Common Issues**: Docker socket GID mismatch, devcontainer build failed

**Application Not Responding in Workspace**:
- **Where**: Workspace terminal → `curl localhost:8080/health`
- **How**: Check application logs in workspace terminal
- **Common Issues**: Port mismatch (score.yaml says 8080, app listens on 5000), missing dependencies

---

## 3. Demonstration (10 minutes)

### 📺 Video: Deploying the Sample Application (10 minutes) — *not produced yet*

> **[VIDEO PLACEHOLDER]** > **Script** *(video not produced)*: Instructor performs a complete deployment showing:
>
> **Part 1: Create from Template (2 min)**
> - Open Backstage
> - Click "Create" → "Choose a template"
> - Select "Python Flask App" template
> - Fill in details: name, description, repository
> - Click "Create"
> - Show generated repository in GitHub
>
> **Part 2: Score Spec Validation (1 min)**
> - Show Score API validating the spec
> - Show spec ID returned
> - Show component in Backstage catalog
>
> **Part 3: Pipeline Execution (3 min)**
> - Open Woodpecker UI
> - Watch pipeline stages: lint → test → build → push
> - Show build logs for each stage
> - Highlight test results
>
> **Part 4: Coder Workspace (2 min)**
> - Open Coder UI
> - Create workspace from new repo
> - Show VS Code web IDE
> - Run `curl localhost:8080/health`
>
> **Part 5: Observe Metrics (2 min)**
> - Open Backstage catalog
> - Show component with TechDocs
> - Point out DORA metrics

### Key Takeaways from Demo

1. **It's Fast**: From template creation to running app in ~10 minutes
2. **It's Automated**: You choose template, platform handles the rest
3. **It's Observable**: Every stage visible in appropriate tool
4. **It's Safe**: Multiple quality gates (lint, test, build)
5. **It's Measurable**: DORA metrics update automatically
6. **No Cluster Needed**: Runs entirely in Docker Compose

---

## 4. Hands-On Lab (20 minutes)

### Lab Overview

You'll deploy your first application on uFawkesDevX using a golden path template, monitor its progress through the pipeline, and verify it's running successfully in a Coder workspace.

**Time Estimate**: 20 minutes
**Difficulty**: Beginner (Modules 1-3 complete)
**Auto-Graded**: Yes
**Points**: 100

### Lab Environment

**Prerequisites**:
- ✅ uFawkesDevX v1.0.1 running from Module 1
- ✅ Module 3 completed (understand GitOps workflow with Score Service)
- ✅ Your `hello-devx` and `hello-gitops` services from Modules 1-3 registered

When you start this lab, you'll have:
- Backstage at http://localhost:7007
- Score Service at http://localhost:8000/api/score
- uFawkesPipe (Woodpecker) at http://localhost:8000
- Coder at your `CODER_ACCESS_URL`

**Environment will be available as long as you keep the containers running.**

### Lab Instructions

➡️ **[Lab 01: Your First Deployment with uFawkesDevX](white-belt/module-04-first-deployment/lab-01/instructions.md)**

This lab walks you through creating a service from a golden path template, submitting the Score spec, watching the pipeline execute, and verifying the app in a Coder workspace.

**Validation**: `bash white-belt/module-04-first-deployment/lab-01/validate.sh`

---

## 5. Knowledge Check (5 minutes)

### Quiz: First Deployment Mastery with uFawkesDevX

**Instructions**: Answer all 10 questions. You need 8/10 (80%) to pass. Unlimited attempts allowed.

#### Question 1

**What triggers the uFawkesPipe pipeline in the uFawkesDevX platform?**

- [ ] A) Manual button click in Backstage
- [ ] B) Git webhook when code is pushed
- [x] C) Score Service webhook after spec validation
- [ ] D) Coder workspace creation

**Explanation**: When you submit a `score.yaml` to the **Score Service**, it validates the spec and then POSTs to the uFawkesPipe webhook to trigger the build/test/deploy pipeline.

---

#### Question 2

**In uFawkesDevX, which component validates the Score workload spec?**

- [ ] A) Backstage
- [ ] B) Coder
- [x] C) Score Service
- [ ] D) Plugin Manager

**Explanation**: The **Score Service** validates `score.yaml` against the `score.dev/v1b1` schema, stores the spec, and triggers the pipeline.

---

#### Question 3

**What is the role of the `.fawkespipe.yml` file in a golden path template?**

- [ ] A) Defines the Coder workspace
- [x] B) Defines the uFawkesPipe CI/CD contract (lint, test, build, deploy stages)
- [ ] C) Configures the Score Service
- [ ] D) Sets up the Backstage catalog entity

**Explanation**: **`.fawkespipe.yml`** is the uFawkesPipe CI/CD contract that defines lint, test, build, and deploy stages for the pipeline.

---

#### Question 4

**What does the Backstage Scaffolder do when you create a new service?**

- [ ] A) Deploys to Kubernetes
- [x] B) Runs Cookiecutter template, creates Git repo, registers in Backstage
- [ ] C) Builds the Docker image
- [ ] D) Provisions a Coder workspace

**Explanation**: The **Scaffolder** runs the Cookiecutter template, creates a Git repository with the scaffolded code, and registers the component in Backstage catalog.

---

#### Question 5

**When is the "lead time for changes" measurement started in uFawkesDevX?**

- [x] A) When the Scaffolder creates the Git repository (first commit)
- [ ] B) When Score API receives the spec
- [ ] C) When uFawkesPipe pipeline starts
- [ ] D) When Coder workspace is ready

**Explanation**: Lead time starts at the **Git commit timestamp** (when Scaffolder initializes the repo) and ends when the pipeline completes.

---

#### Question 6

**What does the Score Service do after validating a spec?**

- [ ] A) Deploys to Kubernetes
- [ ] B) Starts a Coder workspace
- [x] C) Triggers uFawkesPipe webhook and updates Backstage catalog
- [ ] D) Runs the application tests

**Explanation**: After validation, the **Score Service** stores the spec in Backstage catalog, then POSTs to the uFawkesPipe webhook to trigger the CI/CD pipeline.

---

#### Question 7

**How do you verify your application is healthy after deployment in uFawkesDevX?**

- [ ] A) Check if uFawkesPipe pipeline succeeded
- [ ] B) Call the application's health endpoint in Coder workspace
- [ ] C) Look at component status in Backstage
- [x] D) All of the above

**Explanation**: You should verify **all three**: pipeline success, application health endpoint in Coder workspace, and component status in Backstage.

---

#### Question 8

**Where do you find logs if your pipeline fails in uFawkesDevX?**

- [ ] A) Score Service logs
- [ ] B) Backstage Scaffolder logs
- [x] C) Woodpecker (uFawkesPipe) UI → pipeline logs
- [ ] D) Coder workspace logs

**Explanation**: **Woodpecker UI** (uFawkesPipe) shows pipeline stage logs. Access at http://localhost:8000 or via Backstage links.

---

#### Question 9

**What does the `.devcontainer/devcontainer.json` file define?**

- [ ] A) The Score workload spec
- [ ] B) The uFawkesPipe pipeline stages
- [x] C) The Coder workspace container (image, features, post-create commands)
- [ ] D) The Backstage catalog entity

**Explanation**: The **devcontainer.json** defines how Coder builds the workspace container — base image, features (Docker-in-Docker), post-create commands, VS Code extensions.

---

#### Question 10

**Why does the same container image get promoted through stages in uFawkesDevX?**

- [ ] A) To save disk space
- [ ] B) To make builds faster
- [x] C) To ensure consistency—what you test is what you deploy
- [ ] D) It's a uFawkesDevX requirement, not a best practice

**Explanation**: **Immutable deployments** mean the exact same artifact (container image built by CNB) progresses through stages. You never rebuild for production—you promote the tested image.

---

### Quiz Results

**Score: X / 10**

- ✅ **Passed** (8+): Excellent! You understand the deployment workflow.
- ❌ **Not Yet** (<8): Review the theory section and try again.

**Incorrect answers?** Each question links back to the relevant section for review.

---

## 6. Reflection & Next Steps (5 minutes)

### What You Learned

Congratulations! 🎉 You've completed your first deployment on uFawkesDevX. Let's recap:

✅ **You now know**:
- The complete deployment workflow from template to running app
- How Scaffolder, Score Service, uFawkesPipe, and Coder work together
- Where to find logs, metrics, and status at each stage
- How DORA metrics are automatically captured
- What golden path templates provide

✅ **You can now**:
- Create services end-to-end using the Scaffolder
- Monitor deployment progress across Backstage, Score API, and uFawkesPipe
- Verify application health in a Coder workspace
- Interpret success/failure at each workflow stage

### How This Connects to Your Work

**For Developers**:
- You can now deploy code multiple times per day
- No more waiting for ops team to provision environments
- Immediate feedback on every change
- Full visibility into deployment status

**For Platform Engineers**:
- You understand how the golden path works
- You can help teams troubleshoot deployment issues
- You see how observability is built into the workflow

**For Leaders**:
- You've seen how automation enables high deployment frequency
- You understand how DORA metrics are captured automatically
- You can articulate the business value of the platform

### Real-World Application Exercise

**This Week, Try This**:

1. **Deploy a Real Feature**
   - Pick a small feature or bug fix from your backlog
   - Deploy it using the uFawkesDevX platform
   - Measure your lead time (commit to running app)

2. **Compare Before and After**
   - How long did deployments take before uFawkesDevX?
   - How long now?
   - Calculate time saved

3. **Share Your Experience**
   - Demo your deployed app to your team (5 min standup)
   - Show the DORA metrics in Backstage
   - Discuss: "What would we need to deploy 10x per day?"

### Reflection Questions

Take 2 minutes to think about:

1. **What surprised you most?**
   - Was the deployment faster or slower than expected?
   - Which part was easiest? Hardest?

2. **What would you change?**
   - If you could modify the golden path template, what would you add?
   - What additional automation would be helpful?

3. **What's your next deployment?**
   - What will you deploy next on uFawkesDevX?
   - Can you deploy to production confidently now?

4. **How does this compare to your current process?**
   - What manual steps does uFawkesDevX eliminate?
   - What new capabilities does it provide?

### Additional Resources

**📚 Further Reading**:
- [Score Specification](https://score.dev/docs/reference/score-spec/) - Score workload spec reference
- [uFawkesPipe Documentation](https://github.com/paruff/uFawkesPipe) - Woodpecker CI/CD contract
- [Coder Documentation](https://coder.com/docs) - Workspace provisioning
- [Backstage Scaffolder](https://backstage.io/docs/features/scaffolder/) - Template creation

**🎥 Videos to Watch**:
- "Advanced Deployment Patterns" (15 min)
- "Customizing Golden Path Templates" (20 min)
- "Coder Workspaces Deep Dive" (10 min)

**🛠️ Hands-On Practice**:
- Deploy the Java Spring template
- Deploy the Node.js Express template
- Deploy the Go HTTP template
- Customize a template (add database, change ports)
- Practice the full workflow: Scaffolder → Score → Pipeline → Coder

**💬 Community**:
- Share your first deployment in `#dojo-achievements`
- Help others in `#dojo-white-belt`
- Ask questions in daily office hours

### Preview: White Belt Assessment

**You've Completed All 4 White Belt Modules!**

Next up is the **White Belt Assessment** (2 hours):

- Deploy 2 additional applications (different languages)
- Written exam (30 questions covering modules 1-4)
- Practical troubleshooting scenario
- Passing score: 80%

**What You'll Need to Do**:
1. Deploy a Python application
2. Deploy a Java or Node.js application
3. Troubleshoot a broken deployment
4. Answer questions on platform concepts
5. Demonstrate DORA metrics knowledge

**Get Ready**:
- Review all 4 modules
- Practice deploying different templates
- Make sure you understand the full workflow
- Be comfortable with troubleshooting

**When You're Ready**: Click "Start White Belt Assessment" in your Dojo dashboard.

---

## Module Completion

### ✅ You've Completed Module 4

**Next Steps**:

1. ✅ Mark this module complete in your Backstage profile
2. 📊 View your progress on the Dojo dashboard
3. 💬 Share your first deployment in `#dojo-achievements`!
4. ➡️ **Prepare for White Belt Assessment** when ready

**Time Investment**: 60 minutes
**Skills Gained**: End-to-end deployment, workflow understanding, troubleshooting
**Progress**: 4 of 4 modules complete (100% - Ready for White Belt Assessment!)

**Deployment Count**: 1 🚀
**Lead Time**: ~10 minutes (from template to running app)
**DORA Metrics**: Automatically captured ✅

---

**Questions or Issues?**

- 💬 Ask in [GitHub Discussions](https://github.com/paruff/uFawkesDojo/discussions) for `#dojo-white-belt`
- 📧 Email: dojo@ufawkes.dev
- 🐛 Report bugs: [GitHub Issues](https://github.com/paruff/fawkes/issues)

**Feedback?**

- Rate this module (takes 30 seconds)
- What worked well? What could be better?
- Help us improve the learning experience!

---

**Module Author**: Fawkes Learning Team
**Last Updated**: October 2026
**Version**: 2.0

---

**🎉 Congratulations on your first deployment! You're well on your way to becoming a platform engineering expert.**
