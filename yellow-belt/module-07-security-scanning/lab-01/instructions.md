# Lab 01: Security Scanning with uFawkesPipe

**Module**: Yellow Belt — Module 7: Security Scanning & Quality Gates
**Estimated Time**: 15 minutes
**Difficulty**: Intermediate (Modules 5 & 6 complete required)
**Runs against**: [uFawkesPipe v2.0.0](https://github.com/paruff/uFawkesPipe/releases/tag/v2.0.0) (Docker Compose)

---

## Objectives

By the end of this lab you will have:

1. Explored uFawkesPipe's security stages in the Woodpecker UI
2. Configured SAST with SonarQube + Trivy + Bandit for a sample application
3. Configured dependency scanning and container image scanning
4. Enabled secret detection with Gitleaks
5. Integrated security findings with DefectDojo
6. Configured and tested quality gates

---

## Why This Lab Uses uFawkesPipe

This lab runs against **uFawkesPipe v2.0.0** — the CI/CD plane of the Fawkes IDP — because it provides a complete security scanning pipeline in Docker Compose:

- **SonarQube** — SAST and code quality gates
- **Trivy** — Vulnerability scanning (filesystem + container images)
- **Gitleaks** — Secret detection (hard gate)
- **Bandit** — Python security linting
- **OWASP ZAP** — Dynamic Application Security Testing
- **DefectDojo** — Centralized findings management
- **Woodpecker CI** — Pipeline orchestration

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

**Required**: Modules 5 & 6 completed (understand CI workflow and golden paths with uFawkesPipe)

**Tools required** (already installed from previous modules):
- `curl` — HTTP client
- `jq` — JSON processor
- `git` — version control
- `cookiecutter` — `pip install cookiecutter`

---

## Step 0 — Read the Theory First (if you haven't)

This lab assumes you've read the [Module 7 theory](../README.md#theory-summary-25-minutes) up through "Complete Security Configuration Example". You should be able to name the security stages and identify the key uFawkesPipe security components.

---

## Step 1 — Explore Security Stages (Worked Example) (3 minutes)

### 1.1 Access Woodpecker UI

Open **http://localhost:8000** in your browser.

1. Click **"Sign in with GitHub"** (OAuth)
2. Navigate to **Repositories** → find **uFawkesPipe** (the platform's own repo)
3. Click on the latest **pipeline run**

### 1.2 Examine Security Stages

1. Click on the **security** stage
2. Observe the sequential steps:
   - **secrets-scan** — Gitleaks secret detection (hard gate!)
   - **vuln-scan-fs** — Trivy filesystem scan
   - **vuln-scan-image** — Trivy container image scan (main branch only)

3. Click on **sast** stage:
   - **sonarqube-analysis** — SonarQube SAST
   - **trivy-fs-scan** — Trivy filesystem scan
   - **bandit-scan** — Bandit Python linting

> ✅ **Checkpoint**: You can identify all security stages in the Woodpecker pipeline and understand their purpose.

---

## Step 2 — Scaffold and Configure Security Pipeline (5 minutes)

### 2.1 Scaffold a Sample Application

```bash
# Work in a temporary directory
mkdir -p ~/dojo-labs/security-lab && cd ~/dojo-labs/security-lab

# Scaffold a Python Flask app using uFawkesDevX template
# (Requires uFawkesDevX v1.0.1 from White Belt Module 1)
cd ~/dojo-labs/uFawkesDevX
cookiecutter templates/python-flask-app --no-input \
  project_name="My Secure App" \
  project_slug="my-secure-app" \
  language="python" \
  registry_namespace="dojo"
```

### 2.2 Examine and Customize Security Configuration

```bash
cd ~/dojo-labs/uFawkesDevX/my-secure-app

# Examine the generated .fawkespipe.yml
cat .fawkespipe.yml
```

### 2.3 Enhance Security Configuration

```bash
# Create an enhanced security configuration
cat > .fawkespipe.yml <<'EOF'
# uFawkesPipe Security-First Pipeline Contract
app:
  name: my-secure-app
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
    name: my-secure-app
    tags:
      - "${GIT_COMMIT_SHORT}"
      - "latest"

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
      projectKey: my-secure-app
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
EOF
```

### 2.4 Verify the Contract

```bash
# Validate the contract syntax
python3 -c "import yaml; yaml.safe_load(open('.fawkespipe.yml'))" && echo "YAML valid"
```

> ✅ **Checkpoint**: Your security-enhanced `.fawkespipe.yml` is ready.

---

## Step 3 — Push to Git and Watch Security Pipeline (4 minutes)

### 3.1 Initialize Git Repository

```bash
cd ~/dojo-labs/uFawkesDevX/my-secure-app

# Initialize Git
git init
git add .
git commit -m "Initial commit: Security-first Python Flask app"

# Create a bare remote (local Git server simulation)
cd ..
git clone --bare my-secure-app my-secure-app.git
cd my-secure-app
git remote add origin ../my-secure-app.git
git push -u origin main
```

### 3.2 Push to GitHub (Alternative)

If you have a GitHub account, push to a real repository:

```bash
# Create repo on GitHub named "my-secure-app", then:
cd ~/dojo-labs/uFawkesDevX/my-secure-app
git remote add origin https://github.com/<your-username>/my-secure-app.git
git branch -M main
git push -u origin main
```

### 3.3 Activate Repository in Woodpecker

1. Open **http://localhost:8000** (Woodpecker UI)
2. Click **Repositories** in the sidebar
3. Click **Add Repository** (or "Activate" if already listed)
4. Find your `my-secure-app` repository
5. Click **Activate**
6. Woodpecker will:
   - Detect `.woodpecker.yml` (generated from `.fawkespipe.yml`)
   - Register webhook with GitHub
   - Show repository as "Active"

### 3.3 Trigger Pipeline

```bash
cd ~/dojo-labs/uFawkesDevX/my-secure-app

# Make a small change to trigger pipeline
echo "# My Secure App" > README.md
git add README.md
git commit -m "Add README"
git push origin main
```

### 3.4 Watch Security Pipeline Execute

1. Open **http://localhost:8000** → Repositories → `my-secure-app`
2. Click the **pipeline run** (should show "Running" or "Pending")
3. Click the **build number** (e.g., #1)

**Watch the security stages execute**:

| Stage | Steps | Expected Time |
|-------|-------|---------------|
| **validate** | `init` → `lint-yaml` + `lint-shell` | ~30s |
| **test** | `unit-tests` + `integration-tests` + `contract-tests` | ~2-3 min |
| **security** | `secrets-scan` → `vuln-scan-fs` → `vuln-scan-image` | ~1-2 min |
| **sast** | `sonarqube-analysis` + `trivy-fs-scan` + `bandit-scan` | ~2-3 min |
| **dependency_scan** | `dep-scan` | ~1 min |
| **build** | `build-image` (CNB) | ~2-4 min |
| **image_scan** | `image-scan` | ~1 min |
| **publish** | `upload-defectdojo` | ~30s |

**Click each security step** to see real-time logs:
- `secrets-scan`: Gitleaks output (hard gate!)
- `vuln-scan-fs`: Trivy filesystem vulnerabilities
- `vuln-scan-image`: Trivy image vulnerabilities
- `sonarqube-analysis`: SonarQube quality gate
- `trivy-fs-scan`: Trivy filesystem scan
- `bandit-scan`: Bandit Python security linting

> ✅ **Checkpoint**: Pipeline completes with all security stages passing (green).

---

## Step 4 — Examine Security Findings (2 minutes)

### 4.1 View Trivy Scan Results

1. In the pipeline run, click **vuln-scan-fs** step
2. Scroll to see Trivy output:
   - **Filesystem vulnerabilities** found in source code
   - Severity breakdown: CRITICAL, HIGH, MEDIUM, LOW

2. Check **vuln-scan-image** (only runs on `main` branch):
   - Container image vulnerabilities
   - Base image CVEs

### 4.2 Check Gitleaks (Secrets Scan)

1. Click **secrets-scan** step
2. Should show: **No secrets found** (or list if any)
3. This is the **hard gate** — any secret fails the pipeline!

### 4.3 Check SonarQube Quality Gate

1. Open **http://localhost:9000** (SonarQube)
2. Login: `admin` / password from uFawkesPipe `.env`
3. Find project: `my-secure-app`
3. View:
   - **Quality Gate**: Passed/Failed
   - **Coverage**: From pytest XML report
   - **Security Hotspots**: Require review

### 4.4 Check DefectDojo Integration

1. Open **http://localhost:8080** (DefectDojo)
2. Login with superuser credentials
3. Navigate to **Engagements** → **CI-Engagement**
3. You should see findings from:
   - **Trivy Scan** (filesystem + image)
   - **Bandit Scan** (Python security)
   - **ZAP Scan** (if DAST enabled)

> ✅ **Checkpoint**: You can locate and interpret security findings across all tools.

---

## Step 5 — Practice Quality Gate Enforcement (2 minutes)

### 5.1 Introduce a Quality Gate Failure

```bash
cd ~/dojo-labs/uFawkesDevX/my-secure-app

# Reduce coverage threshold to trigger failure
sed -i 's/threshold: 80/threshold: 95/' .fawkespipe.yml

git add .fawkespipe.yml
git commit -m "Increase coverage threshold to 95%"
git push origin main
```

### 5.2 Watch Quality Gate Fail

1. Watch pipeline in Woodpecker UI
2. **test** stage will fail (coverage below 95%)
3. Subsequent stages may still run or be skipped
4. Click the failing **unit-tests** step to see coverage report

### 5.3 Fix and Recover

```bash
# Fix the threshold back to achievable level
sed -i 's/threshold: 95/threshold: 80/' .fawkespipe.yml

git add .fawkespipe.yml
git commit -m "Fix coverage threshold to 80%"
git push origin main
```

### 5.4 Watch Recovery

1. New pipeline run triggers automatically
2. Watch **test** stage pass (green)
3. Quality gate passes, pipeline completes successfully

> ✅ **Checkpoint**: You've experienced the quality gate feedback loop.

---

## Step 6 — Run the Validation Script

```bash
# From your uFawkesDojo checkout
cd /path/to/uFawkesDojo
bash yellow-belt/module-07-security-scanning/lab-01/validate.sh
```

**Expected output** (all checks pass):

```
[INFO] Starting Yellow Belt Module 07 Lab 01 validation...

[✓] Prerequisites: curl, jq, git, cookiecutter installed
[✓] uFawkesPipe Stack: all 6 services healthy (woodpecker, sonarqube, portainer, trivy, defectdojo)
[✓] Woodpecker API: reachable at http://localhost:8000
[✓] SonarQube API: reachable at http://localhost:9000
[✓] DefectDojo API: reachable at http://localhost:8080
[✓] Security Stages: all security steps executed
[✓] Quality Gates: Quality gate enforcement verified
[✓] DefectDojo Integration: Findings uploaded successfully

==========================================
Total Tests: 7
Passed: 7
Failed: 0

[✓] All tests passed! ✅

🎉 Congratulations! You've completed Yellow Belt Module 7 Lab 01.
   You've configured a complete security pipeline with SAST, image scanning,
   secret detection, dependency scanning, and DefectDojo integration.
   Move on to Module 08: Artifact Management.
```

---

## Clean Up

```bash
# Remove local repos (optional)
rm -rf ~/dojo-labs/security-lab
rm -rf ~/dojo-labs/my-secure-app.git

# Stop uFawkesPipe when done (optional)
cd ~/dojo-labs/uFawkesPipe
make down
```

---

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| SonarQube won't start | `vm.max_map_count` too low | `sudo sysctl -w vm.max_map_count=262144` |
| Pipeline fails at `secrets-scan` | Gitleaks found secret | Check `.gitleaks.toml` allowlist, remove secret |
| Pipeline fails at `image_scan` | CRITICAL vulnerabilities in base image | Use updated base image, or adjust `fail_on` |
| DefectDojo upload fails | API token missing | Check Woodpecker secret `defectdojo_api_token` |
| SonarQube quality gate fails | Coverage/quality below threshold | Fix code or adjust quality gate |

---

## Retrieval Check (Answer Without Looking Back)

Write your answers down — the act of writing (not just thinking) strengthens retention.

1. What are the three security sub-stages in uFawkesPipe's `security` stage?
2. Which tool provides SAST in uFawkesPipe?
3. What does `sast.sonarqube.qualityGate: true` do?
4. How does uFawkesPipe detect hardcoded secrets?
5. What does `stages.image_scan.fail_on: CRITICAL` do?

(Suggested answers: 1 = secrets-scan, vuln-scan-fs, vuln-scan-image; 2 = SonarQube (+ Trivy, Bandit); 3 = Waits for SonarQube quality gate result before continuing; 4 = Gitleaks (hard gate); 5 = Fails the build if CRITICAL vulnerabilities found)

---

## Reference: What You Configured

| File | Purpose |
|------|---------|
| `.fawkespipe.yml` | Complete security pipeline contract |
| `.woodpecker.yml` | Generated Woodpecker pipeline |
| `src/app.py` | Flask app with `/health` endpoint |
| `tests/test_app.py` | Pytest suite |
| `.gitleaks.toml` | Secret detection allowlist |
| `.devcontainer/devcontainer.json` | Coder workspace definition |

You've now configured a complete security-first pipeline with SAST, image scanning, secret detection, dependency scanning, quality gates, and DefectDojo integration — the foundation for secure, compliant CI/CD!

---

➡️ **Next**: Return to [Module 7 README](../README.md), then continue to **Module 08: Artifact Management**.
