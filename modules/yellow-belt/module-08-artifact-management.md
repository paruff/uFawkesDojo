# Module 8: Artifact Management with uFawkesPipe

**Belt Level**: 🟡 Yellow Belt
**Duration**: 60 minutes
**Prerequisites**: Module 5, 6, 7 complete, uFawkesPipe v2.0.0 running
**DORA Capabilities**: Artifact Traceability, Deployment Automation, Release Management

---

## 1. Learning Objectives (3 minutes)

### What You'll Learn

By the end of this module, you will be able to:

- ✅ Understand the role of artifact registries in CI/CD and how uFawkesPipe implements artifact management
- ✅ Configure artifact build, tagging, and push using uFawkesPipe's `.fawkespipe.yml` contract
- ✅ Configure container image scanning with Trivy via uFawkesPipe's `image_scan` stage
- ✅ Configure artifact retention policies via `advanced.artifacts.retention`
- ✅ Implement artifact promotion across environments using uFawkesPipe's `deploy` stage
- ✅ Understand artifact signing and verification in uFawkesPipe
- ✅ Monitor artifact metrics using Woodpecker UI and Prometheus/Grafana

### Why It Matters

**The Problem: Ad-Hoc Artifact Storage**

```
Without proper artifact management:
Team A: Stores Docker images on local machines
Team B: Uses random Docker Hub accounts
Team C: Rebuilds from source every time
Team D: No idea which version is in production

Result:
❌ Can't reproduce builds
❌ Can't rollback reliably
❌ No audit trail
❌ Security vulnerabilities untracked
❌ Storage costs out of control
```

**The Solution: Centralized Artifact Management with uFawkesPipe**

```
                    ┌─────────────────────┐
                    │   uFawkesPipe CI/CD  │
                    │  (Woodpecker CI)     │
                    └──────────┬──────────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
        ┌─────▼────┐    ┌─────▼────┐    ┌─────▼────┐
        │   Dev    │    │ Staging  │    │  Prod    │
        │ myapp:   │    │ myapp:   │    │ myapp:   │
        │ build-42 │    │ v1.2.3   │    │ v1.2.3   │
        └──────────┘    └──────────┘    └──────────┘
```

**Benefits**:
- ✅ Single source of truth via `.fawkespipe.yml` contract
- ✅ Immutable artifacts built via Cloud Native Buildpacks
- ✅ Complete audit trail via Woodpecker + DefectDojo
- ✅ Security scanning integrated (Trivy + Gitleaks)
- ✅ Efficient storage with CNB layer caching
- ✅ Artifact promotion via `deploy` stage
- ✅ Retention policies via `advanced.artifacts.retention`

### Success Criteria

You've mastered this module when you can:

- Explain artifact management principles and how uFawkesPipe implements them
- Configure artifact build, tagging, and push via `.fawkespipe.yml`
- Configure container image scanning with Trivy
- Configure artifact retention policies
- Implement artifact promotion across environments
- Monitor artifact metrics using Woodpecker UI and Prometheus/Grafana

---

## 2. Theory & Concepts (25 minutes)

### 📺 Video: Artifact Management with uFawkesPipe (10 minutes) — *not produced yet*

> **[VIDEO PLACEHOLDER]** > **Script Summary** *(video not produced)*:
>
> - Opening: Show the problem with ad-hoc artifact storage
> - Artifact management definition: Centralized, immutable, traceable
> - uFawkesPipe tour: `.fawkespipe.yml` contract, `push` stage, `image_scan`, `deploy`
> - Demo: Configure artifact build → scan → push → promote
> - Show retention policies and artifact metrics
> - Closing: "Artifacts as first-class citizens in your pipeline"

### The uFawkesPipe Artifact Management Model

uFawkesPipe treats artifacts as **first-class citizens** in the CI/CD pipeline. Instead of a separate registry like Harbor, artifacts are managed directly through the pipeline contract:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    uFawkesPipe Artifact Lifecycle                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐                 │
│  │   BUILD      │───▶│   SCAN       │───▶│   PUSH       │                 │
│  │  (CNB)       │    │ (Trivy)      │    │ (Registry)   │                 │
│  └──────────────┘    └──────────────┘    └──────┬───────┘                 │
│                                                  │                           │
│                                                  ▼                           │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │                    PROMOTE (deploy stage)                            │  │
│  │  dev → staging → production  (same artifact, different tags)        │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                  │                           │
│                                                  ▼                           │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │                    RETENTION (advanced.artifacts.retention)          │  │
│  │  Policies: dev=10, staging=30, prod=forever, semver=365 days        │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Artifact Management via `.fawkespipe.yml`

The `.fawkespipe.yml` contract is the **single source of truth** for artifact management:

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
      - "${GIT_BRANCH}"
      - "latest"

stages:
  # ... lint, test, sast, dependency_scan, build ...

  image_scan:
    enabled: true
    severity: CRITICAL
    fail_on: CRITICAL

  push:
    enabled: true
    registries:
      - docker.io
      - ghcr.io

  deploy:
    enabled: true
    target: docker
    port: 8080
    network: ufawkespipe_default

advanced:
  timeout: 30
  artifacts:
    paths:
      - coverage.xml
      - htmlcov/
      - artifacts/security/
    retention: 30
  workspace:
    cleanup: true
```

### Key Artifact Management Concepts in uFawkesPipe

| Concept | uFawkesPipe Implementation |
|---------|----------------------------|
| **Registry** | `build.image.registry` + `stages.push.registries` |
| **Tagging** | `build.image.tags` with CI variables |
| **Scanning** | `stages.image_scan` (Trivy) |
| **Promotion** | `stages.deploy` with target environments |
| **Retention** | `advanced.artifacts.retention` (days) |
| **Artifacts** | `advanced.artifacts.paths` + `retention` |

---

## 3. Building & Pushing Artifacts (10 minutes)

### The `build` Section

The `build` section defines how your artifact is created:

```yaml
build:
  builder: cnb                    # or 'docker'
  cnb:
    builder: paketobuildpacks/builder:base
    buildpacks: []                # auto-detect
    env:
      BP_CPYTHON_VERSION: "3.11"
  image:
    registry: docker.io
    namespace: myorg
    name: my-app
    tags:
      - "${GIT_COMMIT_SHORT}"     # Immutable: build-42-abc1234
      - "${GIT_BRANCH}"           # branch-based: main, feature-auth
      - "latest"                  # moving target
```

**Tag Variables Available**:
| Variable | Description |
|----------|-------------|
| `${GIT_COMMIT_SHORT}` | 7-char Git commit SHA |
| `${GIT_BRANCH}` | Sanitized branch name |
| `${GIT_TAG}` | Git tag (if available) |
| `${CI_PIPELINE_NUMBER}` | Pipeline run number |

### The `push` Stage

```yaml
stages:
  push:
    enabled: true
    registries:
      - docker.io
      - ghcr.io
```

**Authentication**: Requires Woodpecker secrets for each registry:
- `docker.io`: `DOCKERHUB_USERNAME`, `DOCKERHUB_PASSWORD`
- `ghcr.io`: `GHCR_USERNAME`, `GHCR_TOKEN`

---

## 4. Security Scanning (10 minutes)

### Image Scanning Stage

```yaml
stages:
  image_scan:
    enabled: true
    tools:
      - trivy
    severity: HIGH,CRITICAL
    fail_on: CRITICAL
```

**Features**:
- Runs on `main` branch only (configurable)
- Scans base image, installed packages, application layer
- Fails build on CRITICAL vulnerabilities by default
- Generates `trivy-image.json` for DefectDojo integration

### Image Scan Output

```
myapp:v1.2.3 (alpine 3.18.0)
═══════════════════════════════════════
Total: 2 (HIGH: 1, CRITICAL: 1)

┌────────────────┬────────────────┬──────────┬───────────────────┐
│    Library     │ Vulnerability  │ Severity │ Installed Version │
├────────────────┼────────────────┼──────────┼───────────────────┤
│ openssl        │ CVE-2023-12345 │ CRITICAL │ 3.0.8-r0          │
│ curl           │ CVE-2023-67890 │ HIGH     │ 8.0.1-r0          │
└────────────────┴────────────────┴──────────┴───────────────────┘
```

---

## 5. Artifact Retention (5 minutes)

### Retention Configuration

```yaml
advanced:
  artifacts:
    paths:
      - coverage.xml
      - htmlcov/
      - artifacts/security/
    retention: 30
```

**Retention Policies by Tag Pattern**:

```yaml
# In uFawkesPipe, retention is global (days) + can be extended via Woodpecker
advanced:
  artifacts:
    paths:
      - artifacts/
      - coverage.xml
    retention: 30  # Global default: 30 days
```

**Tag-based retention** (via Woodpecker/registry):
| Tag Pattern | Retention | Rationale |
|-------------|-----------|-----------|
| `production` | Forever | Production releases kept forever |
| `staging` | 30 days | Staging artifacts auto-expire |
| `dev-*` | 7 days | Dev builds auto-expire |
| `v*.*.*` | 365 days | Semantic versions kept 1 year |
| `latest` / untagged | 7 days | Cleanup untagged images |

---

## 6. Artifact Promotion (10 minutes)

### The `deploy` Stage

```yaml
stages:
  deploy:
    enabled: true
    target: docker              # docker, compose, ssh
    port: 8080
    network: ufawkespipe_default

kubernetes:
  enabled: false
  cluster: production
  namespace: my-app
  manifests:
    path: k8s/
    files:
      - deployment.yaml
      - service.yaml
```

### Promotion Strategies

**1. Tag-based Promotion (Docker)**:
```bash
# Promote dev → staging
docker pull myorg/myapp:build-42-abc1234
docker tag myorg/myapp:build-42-abc1234 myorg/myapp:staging
docker push myorg/myapp:staging
```

**2. GitOps Promotion (Kubernetes)**:
```yaml
kubernetes:
  enabled: true
  cluster: production
  namespace: my-app
  manifests:
    path: k8s/
    files:
      - deployment.yaml
      - service.yaml
```

**3. Manual Approval Gate** (via Woodpecker):
```yaml
# In .fawkespipe.yml - approval is manual in Woodpecker UI
deploy:
  enabled: true
  target: kubernetes
  # Requires manual approval in Woodpecker UI before deploy
```

### Promotion Best Practices

| Principle | Implementation |
|-----------|----------------|
| **Same Artifact** | Never rebuild — promote same image with new tag |
| **Immutable Tags** | Use immutable tags (build-42-abc123) for traceability |
| **Environment Tags** | Use env-specific tags: `dev`, `staging`, `production` |
| **SemVer for Releases** | Tag releases with `v1.2.3` |
| **GitOps Sync** | ArgoCD/Flux syncs manifests to cluster |

---

## 6. Artifact Signing & Verification (5 minutes)

### Cosign Integration

```yaml
stages:
  sign:
    enabled: false  # Enable when Cosign keys configured
    # Requires COSIGN_KEY and COSIGN_PASSWORD secrets
```

**Key Generation** (one-time):
```bash
cosign generate-key-pair
# Creates: cosign.key (private) and cosign.pub (public)
```

**Sign in Pipeline**:
```yaml
# In .fawkespipe.yml (when supported)
stages:
  sign:
    enabled: true
    # Requires COSIGN_KEY and COSIGN_PASSWORD secrets
```

**Verification**:
```bash
cosign verify \
    --key cosign.pub \
    ghcr.io/myorg/myapp:v1.2.3
```

---

## 7. Monitoring & Metrics (5 minutes)

### Key Artifact Metrics

```promql
# Artifact publish rate
rate(artifacts_published_total[5m])

# Artifact size distribution
avg(artifact_size_bytes) by (repository)

# Pull count by artifact
sum(artifact_pulls_total) by (repository, tag)

# Storage usage by project
sum(storage_used_bytes) by (project)

# Vulnerability count by severity
sum(vulnerabilities_total) by (severity, repository)

# Artifact age
time() - artifact_push_timestamp_seconds
```

### Grafana Dashboard Panels

| Panel | Query | Visualization |
|-------|-------|---------------|
| Daily Publishes | `rate(artifacts_published_total[1d])` | Graph |
| Storage by Project | `sum(storage_used_bytes) by (project) / 1GB` | Pie |
| Top Pulled Images | `topk(10, sum(rate(pulls[7d])) by (repo))` | Table |
| Vulnerabilities | `sum(vulns) by (severity)` | Bar Gauge |

---

## 7. Hands-On Lab (15 minutes)

### Lab Overview

You'll use the running uFawkesPipe stack to:
1. Explore artifact management in Woodpecker
2. Create a `.fawkespipe.yml` with artifact build, scan, push, promotion
4. Configure image scanning and retention
5. Practice artifact promotion
6. Verify artifact lifecycle

**Time Estimate**: 15 minutes
**Difficulty**: Intermediate (Modules 5-7 complete)
**Auto-Graded**: Yes
**Points**: 100

### Lab Environment

**Prerequisites**:
- ✅ uFawkesPipe v2.0.0 running locally
- ✅ Module 7 completed (security pipeline)

➡️ **[Lab 01: Artifact Lifecycle with uFawkesPipe](yellow-belt/module-08-artifact-management/lab-01/instructions.md)**

This lab walks you through:
1. Configuring artifact build, tagging, and push
4. Configuring image scanning with Trivy
4. Configuring artifact retention policies
5. Practicing artifact promotion
6. Verifying artifact lifecycle

**Runs against**: [uFawkesPipe v2.0.0](https://github.com/paruff/uFawkesPipe/releases/tag/v2.0.0) (Docker Compose)

**Prerequisites**: Module 7 completed, uFawkesPipe running

**Validation**: `bash yellow-belt/module-08-artifact-management/lab-01/validate.sh`

---

## 8. Knowledge Check (5 minutes)

### Quiz: Artifact Management with uFawkesPipe

**Instructions**: Answer all 10 questions. You need 8/10 (80%) to pass. Unlimited attempts allowed.

#### Question 1

**What is the primary artifact contract file in uFawkesPipe?**

- [ ] A) Jenkinsfile
- [ ] B) .woodpecker.yml
- [x] C) .fawkespipe.yml
- [ ] D) Dockerfile

**Explanation**: The **`.fawkespipe.yml`** is the standard pipeline contract that defines artifact build, scan, push, and promotion behavior.

---

#### Question 2

**How does uFawkesPipe build container images by default?**

- [ ] A) Dockerfile with `docker build`
- [x] B) Cloud Native Buildpacks (CNB)
- [ ] C) Kaniko
- [ ] D) BuildKit

**Explanation**: uFawkesPipe uses **Cloud Native Buildpacks (CNB)** to build OCI-compliant container images without Dockerfiles, reducing attack surface.

---

#### Question 4

**What does `stages.image_scan.fail_on: CRITICAL` do?**

- [ ] A) Scans only CRITICAL vulnerabilities
- [ ] B) Ignores CRITICAL vulnerabilities
- [x] C) Fails the build if CRITICAL vulnerabilities found
- [ ] D) Reports only CRITICAL vulnerabilities

**Explanation**: `fail_on: CRITICAL` sets the severity threshold — the build **fails** if any CRITICAL vulnerabilities are found in the container image.

---

#### Question 5

**How does uFawkesPipe handle artifact retention?**

- [ ] A) Manual cleanup via Harbor UI
- [x] B) `advanced.artifacts.retention` in `.fawkespipe.yml`
- [ ] C) Manual Docker image pruning
- [ ] D) Kubernetes TTL controller

**Explanation**: uFawkesPipe uses **`advanced.artifacts.retention`** in the `.fawkespipe.yml` to configure artifact retention period (in days).

---

#### Question 6

**How does uFawkesPipe promote artifacts between environments?**

- [ ] A) Rebuild the image for each environment
- [ ] B) Copy files between Harbor projects
- [x] C) Use `deploy` stage to promote same artifact with new tag
- [ ] D) Rebuild with environment-specific config

**Explanation**: uFawkesPipe promotes the **same artifact** by re-tagging and pushing with environment-specific tags (e.g., `staging`, `production`), never rebuilding.

---

#### Question 7

**What does `stages.image_scan.fail_on: CRITICAL` do?**

- [ ] A) Scans only CRITICAL vulnerabilities
- [ ] B) Ignores CRITICAL vulnerabilities
- [x] C) Fails the build if CRITICAL vulnerabilities found
- [ ] D) Reports only CRITICAL vulnerabilities

**Explanation**: `fail_on: CRITICAL` sets the severity threshold — the build **fails** if any CRITICAL vulnerabilities are found in the container image.

---

#### Question 8

**What is the default artifact retention period in uFawkesPipe?**

- [ ] A) 7 days
- [ ] B) 30 days
- [ ] C) 90 days
- [x] D) Configurable via `advanced.artifacts.retention` (default 30 days)

**Explanation**: The default retention is **30 days** via `advanced.artifacts.retention: 30`, but is fully configurable.

---

#### Question 9

**How does uFawkesPipe handle artifact promotion to Kubernetes?**

- [ ] A) Direct kubectl apply
- [x] B) `kubernetes` section in `.fawkespipe.yml` with manifests or Helm
- [ ] C) Manual ArgoCD sync
- [ ] D) Helm install via pipeline step

**Explanation**: The `kubernetes` section in `.fawkespipe.yml` defines Kubernetes deployment configuration (manifests or Helm) for promotion.

---

#### Question 10

**What happens when `stages.image_scan.fail_on: CRITICAL` is set and a CRITICAL vulnerability is found?**

- [ ] A) Warning logged, pipeline continues
- [x] B) Pipeline fails immediately
- [ ] C) Only logs warning, continues
- [ ] D) Marks image as quarantined

**Explanation**: When `fail_on: CRITICAL` is set and a CRITICAL vulnerability is detected, the **pipeline fails immediately**, preventing the vulnerable image from being promoted.

---

### Quiz Results

**Score: X / 10**

- ✅ **Passed** (8+): Excellent! You understand artifact management with uFawkesPipe.
- ❌ **Not Yet** (<8): Review the theory section and try again.

**Incorrect answers?** Each question links back to the relevant section for review.

---

## 8. Reflection & Next Steps (5 minutes)

### What You Learned

✅ **You now know**:
- How uFawkesPipe manages artifacts via `.fawkespipe.yml`
- How to configure build, tagging, and push
- How to implement security scanning with Trivy
- How to configure artifact retention policies
- How to promote artifacts across environments
- How to monitor artifact metrics

✅ **You can now**:
- Create a complete artifact management pipeline in `.fawkespipe.yml`
- Configure security scanning and quality gates
- Implement artifact promotion across environments
- Configure retention policies for cost optimization

### How This Connects to Your Work

**For Developers**:
- Artifacts are immutable — build once, promote everywhere
- Consistent tagging strategy across all projects
- Security scanning built into every pipeline

**For Platform Engineers**:
- Centralized artifact management via pipeline contract
- Retention policies control storage costs
- DefectDojo integration for compliance

**For Leaders**:
- Immutable artifacts enable reliable rollbacks
- Full traceability from source to production
- Reduced storage costs via retention policies

### Reflection Questions

1. **What surprised you most about artifact management in uFawkesPipe?**
2. **How does your current artifact management compare?**
3. **What retention policy would work best for your team?**
4. **Who on your team should go through this module?**

---

## Module Completion

### ✅ You've Completed Module 8

**Next Steps**:
1. ✅ Mark this module complete in your Backstage profile
2. 📊 View your progress on the Dojo dashboard
3. 💬 Share your completion in [Show and tell](https://github.com/paruff/uFawkesDojo/discussions/categories/show-and-tell) (optional!)
4. 🎓 **Prepare for Yellow Belt Assessment!**

**Time Investment**: 60 minutes
**Skills Gained**: Artifact lifecycle, security scanning, retention, promotion, monitoring
**Progress**: 4 of 4 modules toward Yellow Belt (100% complete!)

---

## 🎓 Yellow Belt Assessment

**You've Completed All 4 Yellow Belt Modules!**

**Next Up: Yellow Belt Assessment (2 hours)**:

- Deploy 2 additional applications (different languages)
- Written exam (30 questions covering modules 5-8)
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
- Make sure you understand the full pipeline
- Be comfortable with troubleshooting

**When You're Ready**: Click "Start Yellow Belt Assessment" in your Dojo dashboard.

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
