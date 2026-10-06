# Lab 01: Your First Pipeline with uFawkesPipe

**Module**: Yellow Belt — Module 5: CI Fundamentals
**Estimated Time**: 20 minutes
**Difficulty**: Intermediate (White Belt complete required)
**Runs against**: uFawkesPipe v2.0.0 (not released yet) (Docker Compose)

> **Written ahead of its stack, not yet run for real.** uFawkesPipe v2.0.0 has not been released, so no one has run every step of this lab against it. Treat the steps and the expected output as unverified. See the [audit](../../../docs/ai-sdlc/compose-curriculum/audit-2026-10-06.md).

---

## Objectives

By the end of this lab you will have:

1. Explored the Woodpecker CI UI and examined the uFawkesPipe pipeline structure
2. Created a `.fawkespipe.yml` pipeline contract for a sample Python Flask application
3. Pushed the configuration to Git, activated the repository in Woodpecker
4. Watched the pipeline execute through all stages (validate → test → security → build)
5. Examined security scan results (Gitleaks, Trivy, SonarQube)
6. Practiced the failure/recovery cycle by introducing and fixing a test failure

---

## Why This Lab Uses uFawkesPipe

This lab runs against **uFawkesPipe v2.0.0** — the CI/CD plane of the Fawkes IDP — because it provides a complete, working CI/CD platform in Docker Compose:

- **Woodpecker CI** — Lightweight, YAML-driven CI/CD with GitHub OAuth
- **SonarQube** — SAST and code quality gates
- **Trivy** — Vulnerability scanning (filesystem + container images)
- **Gitleaks** — Secret detection (hard gate)
- **Portainer CE** — Container management for CD operations
- **CNB Builder** — Cloud Native Buildpacks for OCI images without Dockerfiles

No Kubernetes required — runs entirely in Docker Compose on your laptop.

---

## Prerequisites

**Required**: uFawkesPipe v2.0.0 running locally

```bash
# Verify your stack is running
cd ~/dojo-labs/uFawkesPipe
make status
```

**Expected**: All services healthy (woodpecker-server, woodpecker-agent, sonarqube, portainer, trivy-server)

**Tools required** (already installed from White Belt):
- `curl` — HTTP client
- `jq` — JSON processor
- `git` — version control
- `cookiecutter` — `pip install cookiecutter`

---

## Step 0 — Read the Theory First (if you haven't)

This lab assumes you've read the [Module 5 theory](../README.md#theory-summary-20-minutes) up through "uFawkesPipe Architecture". You should be able to name the standard pipeline stages and identify the key uFawkesPipe components.

---

## Step 1 — Explore Woodpecker CI (Worked Example) (3 minutes)

### 1.1 Access Woodpecker UI

Open **http://localhost:8000** in your browser.

1. Click **"Sign in with GitHub"** (OAuth)
2. Authorize the Woodpecker application
3. You'll land on the **Repositories** dashboard

### 1.2 Explore the Platform

1. **Repositories tab** — Lists all activated repositories
2. Click on **uFawkesPipe** (the platform's own repo) if activated
3. Observe the pipeline structure:
   - **Pipeline name**: uFawkesPipe
   - **Branches**: main, etc.
   - **Status**: Last build status
4. Click on a **pipeline run** to see:
   - **Steps**: init, lint-yaml, lint-shell, unit-tests, etc.
   - **Logs**: Click any step to see real-time output
   - **Duration**: Per-step timing

### 1.3 Examine the Pipeline Definition

1. In the uFawkesPipe repository (GitHub), open `.woodpecker.yml`
2. Notice the **standard stages**:
   - `validate` → `init`, `lint-yaml`, `lint-shell`
   - `test` → `unit-tests`, `integration-tests`, `contract-tests`
   - `security` → `secrets-scan`, `vuln-scan-fs`, `vuln-scan-image`
   - `build` → `build-image`
   - `publish` → `upload-defectdojo`
   - `deploy` → `notify-obs`

> ✅ **Checkpoint**: You can navigate Woodpecker UI and understand the standard uFawkesPipe pipeline structure.

---

## Step 2 — Scaffold a Sample Application (5 minutes)

### 2.1 Use the Golden Path Template

```bash
# Work in a temporary directory
mkdir -p ~/dojo-labs/ci-lab && cd ~/dojo-labs/ci-lab

# Scaffold a Python Flask app using uFawkesDevX template
# (Requires uFawkesDevX v1.0.1 from White Belt Module 1)
cd ~/dojo-labs/uFawkesDevX
cookiecutter templates/python-flask-app --no-input \
  project_name="My CI Lab App" \
  project_slug="my-ci-lab-app" \
  language="python" \
  registry_namespace="dojo"
```

### 2.2 Examine the Generated Files

```bash
cd ~/dojo-labs/uFawkesDevX/my-ci-lab-app

# Check the pipeline contract
cat .fawkespipe.yml

# Check the application code
cat src/app.py

# Check tests
cat tests/test_app.py

# Check the devcontainer
cat .devcontainer/devcontainer.json
```

**Key observations**:
- `.fawkespipe.yml` defines the pipeline contract
- `src/app.py` has a `/health` endpoint
- `tests/test_app.py` has basic pytest tests
- `.devcontainer/devcontainer.json` pins Python 3.12

> ✅ **Checkpoint**: You have a scaffolded Python Flask app with a complete `.fawkespipe.yml`.

---

## Step 3 — Push to Git and Activate in Woodpecker (5 minutes)

### 3.1 Initialize Git Repository

```bash
cd ~/dojo-labs/uFawkesDevX/my-ci-lab-app

# Initialize Git
git init
git add .
git commit -m "Initial commit: scaffolded Python Flask app"

# Create a bare remote (local Git server simulation)
cd ..
git clone --bare my-ci-lab-app my-ci-lab-app.git
cd my-ci-lab-app
git remote add origin ../my-ci-lab-app.git
git push -u origin main
```

### 3.2 Push to GitHub (Alternative)

If you have a GitHub account, push to a real repository:

```bash
# Create repo on GitHub named "my-ci-lab-app", then:
cd ~/dojo-labs/uFawkesDevX/my-ci-lab-app
git remote add origin https://github.com/<your-username>/my-ci-lab-app.git
git branch -M main
git push -u origin main
```

### 3.3 Activate Repository in Woodpecker

1. Open **http://localhost:8000** (Woodpecker UI)
2. Click **Repositories** in the sidebar
3. Click **Add Repository** (or "Activate" if already listed)
4. Find your `my-ci-lab-app` repository
5. Click **Activate**
6. Woodpecker will:
   - Detect `.woodpecker.yml` (generated from `.fawkespipe.yml`)
   - Register webhook with GitHub
   - Show repository as "Active"

> ✅ **Checkpoint**: Repository activated in Woodpecker, ready for pipeline runs.

---

## Step 4 — Watch Your First Pipeline Run (5 minutes)

### 4.1 Trigger the Pipeline

```bash
# Make a small change to trigger pipeline
cd ~/dojo-labs/uFawkesDevX/my-ci-lab-app
echo "# CI Lab App" > README.md
git add README.md
git commit -m "Add README"
git push origin main
```

### 4.2 Watch Pipeline Execute

1. Open **http://localhost:8000** → Repositories → `my-ci-lab-app`
2. Click the **pipeline run** (should show "Running" or "Pending")
3. Click the **build number** (e.g., #1)

**Watch the stages execute**:

| Stage | Steps | Expected Time |
|-------|-------|---------------|
| **validate** | `init` → `lint-yaml` + `lint-shell` | ~30s |
| **test** | `unit-tests` + `integration-tests` + `contract-tests` | ~2-3 min |
| **security** | `secrets-scan` → `vuln-scan-fs` → `vuln-scan-image` | ~1-2 min |
| **build** | `build-image` (CNB) | ~2-4 min |
| **publish** | `upload-defectdojo` | ~30s |
| **deploy** | `notify-obs` | ~10s |

**Click each step** to see real-time logs:
- `lint-yaml`: yamllint on compose/woodpecker files
- `lint-shell`: ShellCheck on scripts
- `unit-tests`: pytest with coverage
- `secrets-scan`: Gitleaks (hard gate!)
- `vuln-scan-fs`: Trivy filesystem scan
- `build-image`: CNB building image

> ✅ **Checkpoint**: Pipeline completes successfully (all green). Total time ~5-10 minutes.

---

## Step 5 — Examine Security Scan Results (2 minutes)

### 5.1 View Trivy Scan Results

1. In the pipeline run, click **vuln-scan-fs** step
2. Scroll to see Trivy output:
   - **Filesystem vulnerabilities** found in source code
   - Severity breakdown: CRITICAL, HIGH, MEDIUM, LOW
3. Check **vuln-scan-image** (only runs on `main` branch):
   - Container image vulnerabilities
   - Base image CVEs

### 5.2 Check Gitleaks (Secrets Scan)

1. Click **secrets-scan** step
2. Should show: **No secrets found** (or list if any)
3. This is the **hard gate** — any secret fails the pipeline!

### 5.3 Check SonarQube (Optional)

1. Open **http://localhost:9000** (SonarQube)
2. Login: `admin` / password from uFawkesPipe `.env`
3. Find project: `flask-api` (or your app name)
3. View:
   - **Quality Gate**: Passed/Failed
   - **Code Smells**, **Bugs**, **Vulnerabilities**
   - **Coverage**: From pytest XML report

> ✅ **Checkpoint**: You can locate and interpret security scan results.

---

## Step 6 — Practice Failure & Recovery (3 minutes)

### 6.1 Introduce a Test Failure

```bash
cd ~/dojo-labs/uFawkesDevX/my-ci-lab-app

# Break a test
cat > tests/test_app.py <<'EOF'
import pytest
from src.app import app

def test_health_endpoint():
    client = app.test_client()
    response = client.get('/health')
    assert response.status_code == 200
    assert response.json['status'] == 'healthy'

def test_failing_test():
    """This test will fail intentionally"""
    assert 1 == 2, "This is an intentional failure"
EOF

git add tests/test_app.py
git commit -m "Introduce failing test"
git push origin main
```

### 6.2 Watch Pipeline Fail

1. Watch pipeline in Woodpecker UI
2. **test** stage will fail (red)
3. Subsequent stages (security, build) may still run or be skipped depending on configuration
4. Click the failing **unit-tests** step to see:
   ```
   AssertionError: assert 1 == 2
   ```

### 6.3 Fix and Recover

```bash
# Fix the test
cat > tests/test_app.py <<'EOF'
import pytest
from src.app import app

def test_health_endpoint():
    client = app.test_client()
    response = client.get('/health')
    assert response.status_code == 200
    assert response.json['status'] == 'healthy'

def test_home_endpoint():
    client = app.test_client()
    response = client.get('/')
    assert response.status_code == 200
EOF

git add tests/test_app.py
git commit -m "Fix failing test"
git push origin main
```

### 6.4 Watch Recovery

1. New pipeline run triggers automatically
2. Watch **test** stage pass (green)
3. Pipeline completes successfully

> ✅ **Checkpoint**: You've experienced the failure/recovery cycle — the core CI feedback loop.

---

## Step 7 — Run the Validation Script

```bash
# From your uFawkesDojo checkout
cd /path/to/uFawkesDojo
bash yellow-belt/module-05-ci-fundamentals/lab-01/validate.sh
```

**Expected output** (all checks pass):

```
[INFO] Starting Yellow Belt Module 05 Lab 01 validation...

[✓] Prerequisites: curl, jq, git, cookiecutter installed
[✓] uFawkesPipe Stack: all services healthy (woodpecker, sonarqube, portainer, trivy)
[✓] Woodpecker API: reachable at http://localhost:8000
[✓] Pipeline Run: my-ci-lab-app pipeline completed successfully
[✓] Security Scans: Gitleaks, Trivy scans executed
[✓] Failure/Recovery: Test failure introduced and recovered
[✓] Artifacts: Build artifacts generated

==========================================
Total Tests: 7
Passed: 7
Failed: 0

[✓] All tests passed! ✅

🎉 Congratulations! You've completed Yellow Belt Module 5 Lab 01.
   You've created a pipeline, watched it execute, seen security scans,
   and practiced failure/recovery.
   Move on to Module 06: Golden Path Pipelines.
```

---

## Clean Up

```bash
# Remove local repos (optional)
rm -rf ~/dojo-labs/ci-lab
rm -rf ~/dojo-labs/my-ci-lab-app.git

# Stop uFawkesPipe when done (optional)
cd ~/dojo-labs/uFawkesPipe
make down
```

---

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| Woodpecker won't start | Port 8000 in use / OAuth config | `lsof -i :8000`, check `.env` for OAuth keys |
| Pipeline stuck "Pending" | Agent not connected | `docker logs woodpecker-agent`, check `WOODPECKER_AGENT` config |
| SonarQube won't start | `vm.max_map_count` too low | `sudo sysctl -w vm.max_map_count=262144` |
| Pipeline fails at `secrets-scan` | Gitleaks found secret | Check `.gitleaks.toml` allowlist, remove secret |
| Pipeline fails at `build-image` | CNB builder issue | Check Docker access, `docker ps` |
| Woodpecker webhook fails | GitHub can't reach Woodpecker | Check `WOODPECKER_HOST` in `.env`, verify OAuth app callback URL |

---

## Retrieval Check (Answer Without Looking Back)

Write your answers down — the act of writing (not just thinking) strengthens retention.

1. What are the 6 standard stages in uFawkesPipe pipeline?
2. What file defines the pipeline contract for an application?
3. Which security tool acts as a hard gate?
4. How does uFawkesPipe build container images by default?
5. What does the `dependency_scan` stage do?

(Suggested answers: 1 = validate, test, security, build, publish, deploy; 2 = .fawkespipe.yml; 3 = Gitleaks; 4 = Cloud Native Buildpacks; 5 = Scans application dependencies for vulnerabilities)

---

## Reference: What You Built

| File | Purpose |
|------|---------|
| `.fawkespipe.yml` | Pipeline contract (lint, test, security, build, push) |
| `.woodpecker.yml` | Generated Woodpecker pipeline (from .fawkespipe.yml) |
| `src/app.py` | Flask app with `/health` endpoint |
| `tests/test_app.py` | Pytest suite |
| `.devcontainer/devcontainer.json` | Coder workspace definition |
| `Dockerfile` | CNB-based container build (not used directly) |

You've now experienced the complete uFawkesPipe CI workflow — from code push through security scans to validated artifact. This is the foundation for all your future pipelines!

---

## Retrieval Check Answers

1. **Stages**: validate, test, security, build, publish, deploy
2. **Contract file**: `.fawkespipe.yml` (translated to `.woodpecker.yml`)
3. **Hard gate**: Gitleaks (secret detection)
4. **Build method**: Cloud Native Buildpacks (CNB)
5. **Dependency scan**: Scans app dependencies for known vulnerabilities

---

➡️ **Next**: Return to [Module 5 README](../README.md), then continue to **Module 06: Golden Path Pipelines**.
