# Lab 01: Artifact Lifecycle with uFawkesPipe

**Module**: Yellow Belt — Module 8: Artifact Management
**Estimated Time**: 10 minutes
**Difficulty**: Intermediate (Modules 5-7 complete required)
**Runs against**: [uFawkesPipe v2.0.0](https://github.com/paruff/uFawkesPipe/releases/tag/v2.0.0) (Docker Compose)

---

## Objectives

By the end of this lab you will have:

1. Explored uFawkesPipe's artifact management capabilities in Woodpecker UI
2. Created a customized `.fawkespipe.yml` with artifact build, scan, push, retention, and promotion
3. Pushed the configuration to Git, activated the repository in Woodpecker
4. Watched the pipeline execute through all artifact stages
5. Verified image scanning, retention configuration, and promotion configuration
6. Practiced the full artifact lifecycle: build → scan → push → promote → retain

---

## Why This Lab Uses uFawkesPipe

This lab runs against **uFawkesPipe v2.0.0** — the CI/CD plane of the Fawkes IDP — because it provides a complete artifact management pipeline in Docker Compose:

- **CNB Builder** — Cloud Native Buildpacks for OCI images without Dockerfiles
- **Trivy** — Vulnerability scanning (filesystem + container images)
- **Gitleaks** — Secret detection (hard gate)
- **Woodpecker CI** — Pipeline orchestration with artifact management
- **Prometheus/Grafana** — Build metrics and artifact metrics
- **DefectDojo** — Centralized findings management

No Kubernetes required — runs entirely in Docker Compose on your laptop.

---

## Prerequisites

**Required**: uFawkesPipe v2.0.0 running locally

```bash
# Verify your stack is running
cd ~/dojo-labs/uFawkesPipe
make status
```

**Expected**: All services healthy (woodpecker-server, woodpecker-agent, sonarqube, portainer, trivy-server, defectdojo)

**Required**: Modules 5, 6, 7 completed (understand CI workflow, golden paths, security pipeline)

**Tools required** (already installed from previous modules):
- `curl` — HTTP client
- `jq` — JSON processor
- `git` — version control
- `cookiecutter` — `pip install cookiecutter`

---

## Step 0 — Read the Theory First (if you haven't)

This lab assumes you've read the [Module 8 theory](../README.md#theory-summary-25-minutes) up through "Complete Artifact Management Example". You should be able to name the artifact-related stages and identify the key uFawkesPipe artifact management components.

---

## Step 1 — Explore Artifact Management in Woodpecker (Worked Example) (2 minutes)

### 1.1 Access Woodpecker UI

Open **http://localhost:8000** in your browser.

1. Click **"Sign in with GitHub"** (OAuth)
2. Navigate to **Repositories** → find **uFawkesPipe** (the platform's own repo)
3. Click on the latest **pipeline run**

### 1.2 Examine Artifact-Related Stages

1. Click on the **build** stage
   - Observe `build-image` step (CNB build)

2. Click on **image_scan** stage
   - Observe `image-scan` step (Trivy container scan)

3. Click on **push** stage
   - Observe `push` step (registry push)

4. Click on **deploy** stage
   - Observe `deploy` step (if enabled)

> ✅ **Checkpoint**: You can identify all artifact-related stages in the Woodpecker pipeline and understand their purpose.

---

## Step 2 — Scaffold and Customize Artifact Pipeline (3 minutes)

### 2.1 Scaffold a Sample Application

```bash
# Work in a temporary directory
mkdir -p ~/dojo-labs/artifact-lab && cd ~/dojo-labs/artifact-lab

# Scaffold a Python Flask app using uFawkesDevX template
# (Requires uFawkesDevX v1.0.1 from White Belt Module 1)
cd ~/dojo-labs/uFawkesDevX
cookiecutter templates/python-flask-app --no-input \
  project_name="My Artifact Lab App" \
  project_slug="my-artifact-app" \
  language="python" \
  registry_namespace="dojo"
```

### 2.2 Examine and Customize the Artifact Pipeline Contract

```bash
cd ~/dojo-labs/uFawkesDevX/my-artifact-app

# Examine the generated .fawkespipe.yml
cat .fawkespipe.yml
```

### 2.3 Customize for Full Artifact Lifecycle

```bash
# Create an enhanced artifact lifecycle configuration
cat > .fawkespipe.yml <<'EOF'
# uFawkesPipe Artifact Lifecycle Pipeline Contract
app:
  name: my-artifact-app
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
    namespace: dojo
    name: my-artifact-app
    tags:
      - "${GIT_COMMIT_SHORT}"      # Immutable: build-42-abc1234
      - "${GIT_BRANCH}"            # branch-based: main, feature-auth
      - "latest"                   # moving target

stages:
  lint:
    enabled: true
    commands:
      - language: python
        cmd: |
          pip install ruff black
          ruff check src/
          black --check src/
    dockerfile:
      enabled: true

  test:
    enabled: true
    commands:
      - language: python
        cmd: |
          pip install pytest pytest-cov
          pytest tests/ --cov=src --cov-report=xml --cov-report=html
    coverage:
      enabled: true
      threshold: 80
      report: coverage.xml

  sast:
    enabled: true
    sonarqube:
      enabled: true
      projectKey: my-artifact-app
      sources: src/
      qualityGate: true
    trivy:
      enabled: true
      severity: HIGH,CRITICAL
    bandit:
      enabled: true
      severity: MEDIUM
      confidence: MEDIUM

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

  dast:
    enabled: false  # Enable for staging environment
    tool: zap
    target_url: http://staging-app:8000

  defectdojo:
    enabled: true
    url: http://defectdojo:8080
    engagement_name: CI-Engagement

  push:
    enabled: true
    registries:
      - docker.io

  deploy:
    enabled: true
    target: docker
    port: 8080
    network: ufawkespipe_default

notifications:
  slack:
    enabled: false
    channel: "#ci-cd"
    events:
      - build_success
      - build_failure
      - deployment

advanced:
  timeout: 30
  parallel:
    enabled: true
  workspace:
    cleanup: true
  artifacts:
    paths:
      - coverage.xml
      - htmlcov/
      - artifacts/security/
    retention: 30
  workspace:
    cleanup: true
EOF
```

### 2.4 Verify the Contract

```bash
# Validate the contract syntax
python3 -c "import yaml; yaml.safe_load(open('.fawkespipe.yml'))" && echo "YAML valid"
```

> ✅ **Checkpoint**: Your artifact lifecycle `.fawkespipe.yml` is ready with build, scan, push, retention, and promotion configured.

---

## Step 3 — Push to Git and Watch Artifact Pipeline (3 minutes)

### 3.1 Initialize Git Repository

```bash
cd ~/dojo-labs/uFawkesDevX/my-artifact-app

# Initialize Git
git init
git add .
git commit -m "Initial commit: Artifact lifecycle Python Flask app"

# Create a bare remote (local Git server simulation)
cd ..
git clone --bare my-artifact-app my-artifact-app.git
cd my-artifact-app
git remote add origin ../my-artifact-app.git
git push -u origin main
```

### 3.2 Push to GitHub (Alternative)

If you have a GitHub account, push to a real repository:

```bash
# Create repo on GitHub named "my-artifact-app", then:
cd ~/dojo-labs/uFawkesDevX/my-artifact-app
git remote add origin https://github.com/<your-username>/my-artifact-app.git
git branch -M main
git push -u origin main
```

### 3.3 Activate Repository in Woodpecker

1. Open **http://localhost:8000** (Woodpecker UI)
2. Click **Repositories** in the sidebar
3. Click **Add Repository** (or "Activate" if already listed)
3. Find your `my-artifact-app` repository
4. Click **Activate**
5. Woodpecker will:
   - Detect `.woodpecker.yml` (generated from `.fawkespipe.yml`)
   - Register webhook with GitHub
   - Show repository as "Active"

### 3.3 Trigger Pipeline

```bash
cd ~/dojo-labs/uFawkesDevX/my-artifact-app

# Make a small change to trigger pipeline
echo "# My Artifact Lab App" > README.md
git add README.md
git commit -m "Add README"
git push origin main
```

### 3.2 Watch Artifact Pipeline Execute

1. Open **http://localhost:8000** → Repositories → `my-artifact-app`
2. Click the **pipeline run** (should show "Running" or "Pending")
3. Click the **build number** (e.g., #1)

**Watch the artifact-related stages execute**:

| Stage | Steps | Expected Time |
|-------|-------|---------------|
| **validate** | `init` → `lint-yaml` + `lint-shell` | ~30s |
| **test** | `unit-tests` + `integration-tests` + `contract-tests` | ~2-3 min |
| **security** | `secrets-scan` → `vuln-scan-fs` → `vuln-scan-image` | ~1-2 min |
| **sast** | `sonarqube-analysis` + `trivy-fs-scan` + `bandit-scan` | ~2-3 min |
| **dependency_scan** | `dep-scan` | ~1 min |
| **build** | `build-image` (CNB) | ~2-4 min |
| **image_scan** | `image-scan` | ~1 min |
| **push** | `push` | ~1 min |
| **deploy** | `deploy` | ~30s |

**Click each artifact step** to see real-time logs:
- `build-image`: CNB build with layer caching
- `image-scan`: Trivy container vulnerabilities
- `push`: Registry push logs

> ✅ **Checkpoint**: Pipeline completes with all artifact stages passing (green).

---

## Step 4 — Verify Artifact Lifecycle (2 minutes)

### 4.1 Verify Image Scan Results

1. In the pipeline run, click **image_scan** step
2. Scroll to see Trivy output:
   - **Container image vulnerabilities**
   - Severity breakdown: CRITICAL, HIGH, MEDIUM, LOW

### 4.2 Verify Push Stage

1. Click **push** step
2. Verify image pushed to registry:
   - Image tag visible in logs
   - Registry response shown

### 4.3 Verify Deploy Stage (if enabled)

1. Check **deploy** stage
2. Verify deployment target configured

> ✅ **Checkpoint**: You've verified the complete artifact lifecycle: build → scan → push → deploy.

---

## Step 5 — Verify Retention & Promotion Configuration (1 minute)

### 5.1 Check Retention Configuration

```bash
# Check the .fawkespipe.yml for retention config
cd ~/dojo-labs/uFawkesDevX/my-artifact-app
grep -A 5 "artifacts:" .fawkespipe.yml
```

**Expected output**:
```yaml
  artifacts:
    paths:
      - coverage.xml
      - htmlcov/
      - artifacts/security/
    retention: 30
```

### 5.2 Verify Promotion Configuration

```bash
# Check deploy stage config
grep -A 10 "deploy:" .fawkespipe.yml
```

**Expected output**:
```yaml
  deploy:
    enabled: true
    target: docker
    port: 8080
    network: ufawkespipe_default
```

> ✅ **Checkpoint**: Retention and promotion are correctly configured in `.fawkespipe.yml`.

---

## Step 6 — Run the Validation Script

```bash
# From your uFawkesDojo checkout
cd /path/to/uFawkesDojo
bash yellow-belt/module-08-artifact-management/lab-01/validate.sh
```

**Expected output** (all checks pass):

```
[INFO] Starting Yellow Belt Module 08 Lab 01 validation...

[✓] Prerequisites: curl, jq, git, cookiecutter installed
[✓] uFawkesPipe Stack: all 6 services healthy
[✓] Woodpecker API: reachable
[✓] Pipeline Run: my-artifact-app pipeline completed successfully
[✓] Artifact Build: build-image completed
[✓] Image Scan: Trivy scan executed
[✓] Push Stage: Image pushed to registry
[✓] Retention Config: 30-day retention configured
[✓] Promotion Config: Deploy stage configured

==========================================
Total Tests: 9
Passed: 9
Failed: 0

[✓] All tests passed! ✅

🎉 Congratulations! You've completed Yellow Belt Module 8 Lab 01.
   You've experienced the full artifact lifecycle: build → scan → push → promote → retain.
   You've completed all Yellow Belt modules!
```

---

## Clean Up

```bash
# Remove local repos (optional)
rm -rf ~/dojo-labs/artifact-lab
rm -rf ~/dojo-labs/my-artifact-app.git

# Stop uFawkesPipe when done (optional)
cd ~/dojo-labs/uFawkesPipe
make down
```

---

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| Pipeline fails at `image_scan` | CRITICAL vulnerabilities in base image | Use updated base image, or adjust `fail_on` |
| Pipeline fails at `push` | Registry auth / quota | Check Woodpecker secrets for registry credentials |
| CNB build fails | Docker access / builder image | Check Docker access, `docker ps` |
| Retention not working | Config not in `.fawkespipe.yml` | Add `advanced.artifacts.retention` |
| Deploy stage not running | `deploy.enabled: false` | Set `deploy.enabled: true` in `.fawkespipe.yml` |

---

## Retrieval Check (Answer Without Looking Back)

Write your answers down — the act of writing (not just thinking) strengthens retention.

1. What file defines the artifact lifecycle contract in uFawkesPipe?
2. Which stage builds the container image using CNB?
3. What does `stages.image_scan.fail_on: CRITICAL` do?
4. How do you configure artifact retention in uFawkesPipe?
5. How does uFawkesPipe promote artifacts between environments?

(Suggested answers: 1 = .fawkespipe.yml; 2 = build (build-image step); 3 = Fails build if CRITICAL vulnerabilities found; 4 = advanced.artifacts.retention in .fawkespipe.yml; 5 = deploy stage promotes same artifact with new tag)

---

## Reference: What You Built

| File | Purpose |
|------|---------|
| `.fawkespipe.yml` | Complete artifact lifecycle contract (build, scan, push, retain, promote) |
| `.woodpecker.yml` | Generated Woodpecker pipeline (from .fawkespipe.yml) |
| `src/app.py` | Flask app with `/health` endpoint |
| `tests/test_app.py` | Pytest suite |
| `.devcontainer/devcontainer.json` | Coder workspace definition |

You've now experienced the complete uFawkesPipe artifact lifecycle — from build through security scanning, pushing to registry, configuring retention, and setting up promotion. This is the foundation for reliable, traceable, and secure artifact management in your CI/CD pipelines!

---

➡️ **Next**: Return to [Module 8 README](../README.md), then prepare for the **Yellow Belt Assessment**!
