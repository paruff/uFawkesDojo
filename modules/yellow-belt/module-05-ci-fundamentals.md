# Module 5: CI Fundamentals with uFawkesPipe

**Belt Level**: 🟡 Yellow Belt
**Duration**: 60 minutes
**Prerequisites**: White Belt complete, Docker basics, Git workflows
**DORA Capabilities**: Continuous Integration (CD3)

---

## 1. Learning Objectives (3 minutes)

### What You'll Learn

By the end of this module, you will be able to:

- ✅ Explain the principles and benefits of Continuous Integration
- ✅ Understand uFawkesPipe architecture and Woodpecker CI core concepts
- ✅ Create your first `.fawkespipe.yml` pipeline contract
- ✅ Configure pipeline stages: lint, test, security, build
- ✅ Implement security scanning (SAST, dependency scan, image scan)
- ✅ Understand how CI improves DORA metrics
- ✅ Troubleshoot common CI pipeline failures in Woodpecker

### Why It Matters

Continuous Integration is the foundation of modern software delivery:

- **Integration Hell Prevention**: Integrate early, integrate often
- **Fast Feedback**: Know within minutes if your change breaks something
- **Quality Gates**: Automated checks before code reaches production
- **DORA Impact**: Teams with CI are 2x more likely to be high performers

According to DORA research, elite performers compared to low performers:
- Deploy **973 times more frequently**
- Have **6,570 times faster** lead time for changes
- Have **3 times lower** change failure rate

### Success Criteria

You've mastered this module when you can:

- Explain CI principles and how uFawkesPipe implements them
- Create a `.fawkespipe.yml` from scratch for any application
- Configure all standard pipeline stages (lint, test, security, build)
- Debug a failed pipeline in Woodpecker UI
- Explain how CI improves each DORA metric

---

## 2. Theory & Concepts (20 minutes)

### 📺 Video: CI Fundamentals with uFawkesPipe (8 minutes) — *not produced yet*

> **[VIDEO PLACEHOLDER]** > **Script Summary** *(video not produced)*:
>
> - Opening: Show the problem with manual integration (merge conflicts, broken builds)
> - CI definition: Automated build+test on every commit
> - uFawkesPipe tour: Woodpecker CI, SonarQube, Trivy, Gitleaks
> - Demo: Create `.fawkespipe.yml` → push → watch pipeline in Woodpecker
> - Show security scans: Gitleaks, Trivy, SonarQube
> - Closing: "From commit to validated artifact in minutes"

### What is Continuous Integration?

**Continuous Integration (CI)** is the practice of merging all developers' working copies to a shared mainline several times a day, with each merge verified by an automated build and test process.

**The Problem: Integration Hell**

```
Traditional workflow (without CI):
Developer A: 2 weeks → commit → merge conflicts
Developer B: 2 weeks → commit → broken tests
Developer C: 2 weeks → commit → missing dependencies
                    ↓
            Integration Day (Friday) → Weekend fixing
```

**The Solution: Continuous Integration**

```
CI workflow:
Developer A: commits 5x/day → automated build+test → immediate feedback
Developer B: commits 5x/day → automated build+test → immediate feedback
                    ↓
            Always in releasable state
```

### Core CI Principles

1. **Maintain a Single Source Repository** — All code in version control
2. **Automate the Build** — One command builds everything, no manual steps
3. **Make Your Build Self-Testing** — Automated unit/integration tests
4. **Everyone Commits to Mainline Daily** — Small, frequent commits
5. **Every Commit Builds on Integration Machine** — Clean environment every time
6. **Keep the Build Fast** — Target: <10 minutes
7. **Test in Clone of Production Environment** — Containers for consistency
8. **Make it Easy to Get Latest Deliverables** — Artifacts automatically published
9. **Everyone Can See What's Happening** — Visible build status, notifications
10. **Automate Deployment** — Continuous Delivery is the next step

### How CI Improves DORA Metrics

| DORA Metric | CI Impact | Elite Performance |
|-------------|-----------|-------------------|
| **Deployment Frequency** | Enables multiple deploys/day with confidence | Multiple per day |
| **Lead Time for Changes** | Reduces commit-to-deploy from hours to minutes | <1 hour |
| **Change Failure Rate** | Catches bugs before production | 0-15% |
| **Mean Time to Restore** | Small changes = easier rollback | <1 hour |

**Research shows**: Teams with CI are 2x more likely to be high performers on DORA metrics.

---

## 3. uFawkesPipe Architecture (10 minutes)

uFawkesPipe is the CI/CD plane of the Fawkes IDP, built on **Woodpecker CI** — a lightweight, YAML-driven CI/CD platform with GitHub OAuth.

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    uFawkesPipe Platform                      │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌────────────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ Woodpecker Server  │  │  SonarQube   │  │  Portainer   │  │
│  │ + Agent            │  │   (SAST)     │  │   CE (CD)    │  │
│  │                    │  │              │  │              │  │
│  │  - Pipeline YAML   │  │  - Quality   │  │  - Stacks    │  │
│  │  - GitHub OAuth    │  │    Gates     │  │  - Secrets   │  │
│  │  - CLI triggers    │  │  - Coverage  │  │  - Volumes   │  │
│  └────────────────────┘  └──────────────┘  └──────────────┘  │
│         │                          │                │      │
│         └──────────────────────────┴────────────────┘      │
│                           │                                 │
│                  ┌────────▼────────┐                        │
│                  │  CNB Builder    │                        │
│                  │  (Buildpacks)   │                        │
│                  └────────┬────────┘                        │
│                           │                                 │
│                           ▼                                 │
│                  ┌─────────────────┐                        │
│                  │   Docker        │                        │
│                  │   Registry      │                        │
│                  └─────────────────┘                        │
└─────────────────────────────────────────────────────────────┘
```

### Key Components

| Component | Role |
|-----------|------|
| **Woodpecker Server** | Orchestrates pipelines, serves UI, manages GitHub OAuth |
| **Woodpecker Agent** | Executes pipeline steps in Docker containers |
| **SonarQube** | Static Application Security Testing (SAST), code quality gates |
| **Trivy** | Vulnerability scanning (filesystem + container images) |
| **Gitleaks** | Secret detection (hard gate in pipeline) |
| **Portainer CE** | Container management UI (CD operations) |
| **CNB Builder** | Cloud Native Buildpacks for OCI images without Dockerfiles |

### Pipeline Flow

Every pipeline in uFawkesPipe follows standardized stages (from `.fawkespipe.yml`):

| # | Stage | Steps | Parallel | Branch Gate |
|---|-------|-------|----------|-------------|
| 1 | **validate** | `init` → `lint-yaml` + `lint-shell` | Yes (lint) | None |
| 2 | **test** | `unit-tests` + `integration-tests` + `contract-tests` | Yes | None |
| 3 | **security** | `secrets-scan` → `vuln-scan-fs` → `vuln-scan-image` | Sequential | `vuln-scan-image`: main only |
| 4 | **build** | `build-image` | — | main only |
| 5 | **publish** | `upload-defectdojo` | — | main only |
| 6 | **deploy** | `notify-obs` | — | main only |

### The `.fawkespipe.yml` Contract

Applications define their pipeline behavior via `.fawkespipe.yml` at the repo root:

```yaml
app:
  name: my-app
  type: service
  language: python
  version: 1.0.0

build:
  builder: cnb
  cnb:
    builder: paketobuildpacks/builder:base
    env:
      BP_CPYTHON_VERSION: "3.11"
  image:
    registry: docker.io
    namespace: myorg
    name: my-app
    tags:
      - "${GIT_COMMIT_SHORT}"
      - "latest"

stages:
  lint:
    enabled: true
    commands:
      - language: python
        cmd: ruff check src/ && black --check src/

  test:
    enabled: true
    commands:
      - language: python
        cmd: pytest tests/ --cov=src --cov-report=xml
    coverage:
      enabled: true
      threshold: 75

  sast:
    enabled: true
    sonarqube:
      enabled: true
      qualityGate: true
    trivy:
      enabled: true

  dependency_scan:
    enabled: true
    tools:
      - trivy
    fail_on: HIGH

  build:
    enabled: true

  image_scan:
    enabled: true
    severity: CRITICAL
    fail_on: CRITICAL

  push:
    enabled: true

advanced:
  timeout: 30
  workspace:
    cleanup: true
```

The `scripts/generate_woodpecker_yml.py` script translates `.fawkespipe.yml` into Woodpecker's native `.woodpecker.yml` format.

---

## 4. Security-First Pipeline (5 minutes)

uFawkesPipe implements a security-first approach with multiple scanning layers:

### Secret Detection (Hard Gate)

**Gitleaks** — Single secret-scanning tool, runs on every commit/push:

- Scans all files for secrets, API keys, credentials
- Configured via `.gitleaks.toml` with allowlist for test fixtures
- Runs in pre-commit, Woodpecker CI, and GitHub Actions
- **Fails pipeline** if secrets detected

### Static Application Security Testing (SAST)

| Tool | Purpose |
|------|---------|
| **SonarQube** | Code quality + security vulnerability analysis |
| **Trivy** | Filesystem vulnerability scanning |
| **Bandit** | Python security linting (optional) |

### Dependency Scanning

- **Trivy** (default) — Filesystem + code vulnerability scanning
- **OSV-Scanner** (optional) — CVEs + license allowlist

### Container Security

- **Trivy Image Scan** — Container image vulnerability scanning (main branch only)
- **Cloud Native Buildpacks** — Build OCI images without Dockerfiles
- **Image Pinning** — All service images pinned (no `:latest`)

### DefectDojo Integration

- Automated upload of Gitleaks + Trivy results to DefectDojo API
- Non-blocking — scan ingestion failure doesn't fail the pipeline
- Centralized findings tracking across all repositories

---

## 5. Hands-On Lab (20 minutes)

### Lab Overview

You'll use the running uFawkesPipe stack to:
1. Explore Woodpecker CI UI and examine existing pipelines
2. Create a `.fawkespipe.yml` for a sample application
3. Push to Git, activate in Woodpecker, watch pipeline execute
4. Examine security scan results
5. Practice failure/recovery cycle

**Time Estimate**: 20 minutes
**Difficulty**: Intermediate (White Belt complete required)
**Auto-Graded**: Yes
**Points**: 100

### Lab Environment

**Prerequisites**: uFawkesPipe v2.0.0 running locally
- ✅ Woodpecker CI at http://localhost:8000
- ✅ SonarQube at http://localhost:9000
- ✅ Portainer CE at https://localhost:9443

➡️ **[Lab 01: Your First Pipeline with uFawkesPipe](yellow-belt/module-05-ci-fundamentals/lab-01/instructions.md)**

**Validation**: `bash yellow-belt/module-05-ci-fundamentals/lab-01/validate.sh`

---

## 6. Knowledge Check (5 minutes)

### Quiz: CI Fundamentals with uFawkesPipe

**Instructions**: Answer all 10 questions. You need 8/10 (80%) to pass. Unlimited attempts allowed.

#### Question 1

**What is the primary goal of Continuous Integration?**

- [ ] A) Deploy to production automatically
- [x] B) Integrate code changes frequently and catch issues early
- [ ] C) Write better documentation
- [ ] D) Reduce server costs

**Explanation**: CI is about **integrating code changes frequently** and catching issues early through automated builds and tests.

---

#### Question 2

**In uFawkesPipe, which component orchestrates pipelines?**

- [ ] A) SonarQube
- [ ] B) Portainer
- [x] C) Woodpecker Server
- [ ] D) Trivy

**Explanation**: **Woodpecker Server** orchestrates pipelines, serves the UI, manages GitHub OAuth, and schedules builds.

---

#### Question 3

**What file defines the pipeline contract in uFawkesPipe?**

- [ ] A) Makefile
- [ ] B) .woodpecker.yml
- [x] C) .fawkespipe.yml
- [ ] D) pipeline.yaml

**Explanation**: The **`.fawkespipe.yml`** is the standard pipeline contract. It's translated to `.woodpecker.yml` by `scripts/generate_woodpecker_yml.py`.

---

#### Question 4

**Which stage runs first in the uFawkesPipe pipeline?**

- [ ] A) test
- [ ] B) security
- [x] C) validate (lint-yaml, lint-shell)
- [ ] D) build

**Explanation**: The **validate** stage runs first, executing `init`, `lint-yaml`, and `lint-shell` in parallel.

---

#### Question 5

**What security tool acts as a hard gate in the pipeline?**

- [ ] A) SonarQube
- [ ] B) Trivy
- [x] C) Gitleaks
- [ ] D) Bandit

**Explanation**: **Gitleaks** is the single secret-scanning tool that acts as a hard gate — if secrets are detected, the pipeline fails immediately.

---

#### Question 6

**How does uFawkesPipe build container images by default?**

- [ ] A) Dockerfile with `docker build`
- [x] B) Cloud Native Buildpacks (CNB)
- [ ] C) Kaniko
- [ ] D) BuildKit

**Explanation**: uFawkesPipe uses **Cloud Native Buildpacks (CNB)** to build OCI-compliant container images without Dockerfiles, reducing attack surface.

---

#### Question 7

**What does the `dependency_scan` stage do in uFawkesPipe?**

- [ ] A) Scans container images for vulnerabilities
- [x] B) Scans application dependencies for known vulnerabilities
- [ ] C) Checks for hardcoded secrets
- [ ] D) Runs SonarQube analysis

**Explanation**: The **dependency_scan** stage scans application dependencies for known vulnerabilities using Trivy (default) or OSV-Scanner.

---

#### Question 8

**What happens when Gitleaks detects a secret in the pipeline?**

- [ ] A) Logs a warning and continues
- [ ] B) Uploads to DefectDojo
- [x] C) Fails the pipeline immediately
- [ ] D) Marks build as unstable

**Explanation**: Gitleaks acts as a **hard gate** — any detected secret fails the pipeline immediately. This prevents secrets from ever reaching the registry or production.

---

#### Question 9

**Which tool provides code quality gates in uFawkesPipe?**

- [ ] A) Trivy
- [ ] B) Gitleaks
- [x] C) SonarQube
- [ ] D) Portainer

**Explanation**: **SonarQube** provides code quality analysis and quality gates. The pipeline waits for the quality gate result before proceeding.

---

#### Question 10

**How does CI improve Lead Time for Changes?**

- [ ] A) By slowing down the build process
- [x] B) By eliminating manual steps between commit and deploy-ready artifact
- [ ] C) By requiring more approvals
- [ ] D) By running tests only on main branch

**Explanation**: CI reduces lead time by **eliminating manual steps** — commit → auto build → auto test → auto package → deploy-ready in minutes instead of hours.

---

### Quiz Results

**Score: X / 10**

- ✅ **Passed** (8+): Excellent! You understand CI with uFawkesPipe.
- ❌ **Not Yet** (<8): Review the theory section and try again.

**Incorrect answers?** Each question links back to the relevant section for review.

---

## 7. Reflection & Next Steps (5 minutes)

### What You Learned

✅ **You now know**:
- CI principles and how uFawkesPipe implements them
- Woodpecker CI architecture (server + agent)
- The `.fawkespipe.yml` pipeline contract
- Standard pipeline stages: validate → test → security → build → publish → deploy
- Security-first approach: Gitleaks, Trivy, SonarQube, DefectDojo
- How CI improves all DORA metrics

✅ **You can now**:
- Create a `.fawkespipe.yml` for any application
- Configure all standard pipeline stages
- Debug pipeline failures in Woodpecker UI
- Explain how CI improves DORA metrics

### How This Connects to Your Work

**For Developers**:
- You can now set up CI for any project in minutes
- No more "works on my machine" — consistent containerized builds
- Immediate feedback on every commit

**For Platform Engineers**:
- You understand the CI platform architecture
- You can help teams troubleshoot pipeline issues
- You see how security is built into every pipeline

**For Leaders**:
- You understand how CI enables high deployment frequency
- You see how security is automated, not bolted on
- You can articulate the business value of the CI platform

### Reflection Questions

1. **What surprised you most about uFawkesPipe vs. the retired Jenkins setup?**
2. **How does your current CI process compare?**
3. **What security scanning would you add to your pipelines?**
4. **Who on your team should go through this module?**

### Preview: Module 6

**Next Up: Golden Path Pipelines**

In Module 6, you'll learn:
- Creating reusable pipeline templates with shared libraries
- Pipeline optimization (parallel execution, caching)
- Custom pipeline contracts for different application types
- Quality gate configuration for your organization

**Time**: 60 minutes
**Prerequisites**: Module 5 complete ✅

---

## Module Completion

### ✅ You've Completed Module 5

**Next Steps**:
1. ✅ Mark this module complete in your Backstage profile
2. 📊 View your progress on the Dojo dashboard
3. 💬 Share your completion in [Show and tell](https://github.com/paruff/uFawkesDojo/discussions/categories/show-and-tell) (optional!)
4. ➡️ **Continue to Module 6** when ready

**Time Investment**: 60 minutes
**Skills Gained**: CI fundamentals, uFawkesPipe/Woodpecker, security scanning, pipeline contracts
**Progress**: 1 of 4 modules toward Yellow Belt (25% complete)

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
