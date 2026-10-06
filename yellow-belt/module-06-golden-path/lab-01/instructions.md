# Lab 01: Build Your Golden Path Pipeline

**Module**: Yellow Belt — Module 6: Golden Path Pipelines
**Estimated Time**: 10 minutes
**Difficulty**: Intermediate (Module 5 completion required)
**Runs against**: uFawkesPipe v2.0.0 (not released yet) (Docker Compose)

> **Written ahead of its stack, not yet run for real.** uFawkesPipe v2.0.0 has not been released, so no one has run every step of this lab against it. Treat the steps and the expected output as unverified. See the [audit](../../../docs/ai-sdlc/compose-curriculum/audit-2026-10-06.md).

---

## Objectives

By the end of this lab you will have:

1. Explored uFawkesPipe's built-in golden path templates
2. Created a customized `.fawkespipe.yml` for a Python Flask application
3. Configured pipeline optimization (parallel stages, caching, resource tuning)
4. Pushed the configuration to Git, activated the repository in Woodpecker
5. Watched the pipeline execute through all stages with optimization
6. Measured build performance and practiced optimization

---

## Why This Lab Uses uFawkesPipe

This lab runs against **uFawkesPipe v2.0.0** — the CI/CD plane of the Fawkes IDP — because it provides a complete CI/CD platform with Golden Path templates in Docker Compose:

- **Golden Path Templates**: Pre-built `.fawkespipe.yml` examples for Python, Java, Node.js, Go
- **Woodpecker CI**: Lightweight, YAML-driven CI/CD with GitHub OAuth
- **CNB Builder**: Cloud Native Buildpacks for OCI images without Dockerfiles
- **Security-First Pipeline**: Gitleaks, Trivy, SonarQube integrated
- **Performance Metrics**: Woodpecker UI + Prometheus/Grafana for build time tracking

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

**Required**: Module 5 completed (understand CI workflow with uFawkesPipe)

**Tools required** (already installed from previous modules):
- `curl` — HTTP client
- `jq` — JSON processor
- `git` — version control
- `cookiecutter` — `pip install cookiecutter`

---

## Step 0 — Read the Theory First (if you haven't)

This lab assumes you've read the [Module 6 theory](../README.md#theory-summary-20-minutes) up through "Golden Path Templates by Language". You should be able to name the standard pipeline stages and identify the golden path templates.

---

## Step 1 — Explore Golden Path Templates (Worked Example) (2 minutes)

### 1.1 Examine Built-in Templates

```bash
# Check uFawkesPipe's examples directory
cd ~/dojo-labs/uFawkesPipe
ls examples/
```

**Expected output**:
```
.fawkespipe-go.yml
.fawkespipe-java-maven.yml
.fawkespipe-nodejs-express.yml
.fawkespipe-python-flask.yml
.fawkespipe.yml.example
```

### 1.2 Examine Python Flask Template

```bash
cat examples/.fawkespipe-python-flask.yml
```

**Key observations**:
- `app` section: name, type, language, version
- `build` section: CNB builder, image registry, tags
- `stages`: lint, test, sast, dependency_scan, build, image_scan, push
- `advanced`: timeout, parallel, workspace cleanup

> ✅ **Checkpoint**: You can identify the template structure and key sections.

---

## Step 2 — Scaffold and Customize a Golden Path Pipeline (3 minutes)

### 2.1 Scaffold a Python Flask App

```bash
# Work in a temporary directory
mkdir -p ~/dojo-labs/golden-path-lab && cd ~/dojo-labs/golden-path-lab

# Scaffold a Python Flask app using uFawkesDevX template
# (Requires uFawkesDevX v1.0.1 from White Belt Module 1)
cd ~/dojo-labs/uFawkesDevX
cookiecutter templates/python-flask-app --no-input \
  project_name="My Golden Path App" \
  project_slug="my-golden-path-app" \
  language="python" \
  registry_namespace="dojo"
```

### 2.2 Customize the Pipeline Contract

```bash
cd ~/dojo-labs/uFawkesDevX/my-golden-path-app

# Examine the generated .fawkespipe.yml
cat .fawkespipe.yml
```

### 2.3 Customize for Golden Path Optimization

```bash
# Create an optimized version with parallel execution and caching
cat > .fawkespipe.yml <<'EOF'
# uFawkesPipe Golden Path — Optimized Python Flask
app:
  name: my-golden-path-app
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
    name: my-golden-path-app
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
      projectKey: my-golden-path-app
      sources: src/
      qualityGate: true
    trivy:
      enabled: true
      severity: HIGH,CRITICAL

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
  timeout: 25
  parallel:
    enabled: true
  workspace:
    cleanup: true
  artifacts:
    paths:
      - coverage.xml
      - htmlcov/
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

> ✅ **Checkpoint**: Your optimized `.fawkespipe.yml` is ready with parallel execution, caching config, and resource tuning.

---

## Step 3 — Push to Git and Activate in Woodpecker (2 minutes)

### 3.1 Initialize Git Repository

```bash
cd ~/dojo-labs/uFawkesDevX/my-golden-path-app

# Initialize Git
git init
git add .
git commit -m "Initial commit: Golden Path optimized Python Flask app"

# Create a bare remote (local Git server simulation)
cd ..
git clone --bare my-golden-path-app my-golden-path-app.git
cd my-golden-path-app
git remote add origin ../my-golden-path-app.git
git push -u origin main
```

### 3.2 Push to GitHub (Alternative)

If you have a GitHub account, push to a real repository:

```bash
# Create repo on GitHub named "my-golden-path-app", then:
cd ~/dojo-labs/uFawkesDevX/my-golden-path-app
git remote add origin https://github.com/<your-username>/my-golden-path-app.git
git branch -M main
git push -u origin main
```

### 3.3 Activate Repository in Woodpecker

1. Open **http://localhost:8000** (Woodpecker UI)
2. Click **Repositories** in the sidebar
3. Click **Add Repository** (or "Activate" if already listed)
4. Find your `my-golden-path-app` repository
5. Click **Activate**
6. Woodpecker will:
   - Detect `.woodpecker.yml` (generated from `.fawkespipe.yml`)
   - Register webhook with GitHub
   - Show repository as "Active"

> ✅ **Checkpoint**: Repository activated in Woodpecker, ready for pipeline runs.

---

## Step 4 — Watch Optimized Pipeline Execute (2 minutes)

### 4.1 Trigger the Pipeline

```bash
cd ~/dojo-labs/uFawkesDevX/my-golden-path-app

# Make a small change to trigger pipeline
echo "# My Golden Path App" > README.md
git add README.md
git commit -m "Add README"
git push origin main
```

### 4.2 Watch Pipeline Execute

1. Open **http://localhost:8000** → Repositories → `my-golden-path-app`
2. Click the **pipeline run** (should show "Running" or "Pending")
3. Click the **build number** (e.g., #1)

**Watch the optimized stages execute**:

| Stage | Steps | Parallel? | Expected Time |
|-------|-------|-----------|---------------|
| **validate** | `init` → `lint-yaml` + `lint-shell` | ✅ Yes | ~30s |
| **test** | `unit-tests` + `integration-tests` + `contract-tests` | ✅ Yes | ~2-3 min |
| **security** | `secrets-scan` → `vuln-scan-fs` → `vuln-scan-image` | Sequential | ~1-2 min |
| **build** | `build-image` (CNB cached) | — | ~1-2 min (cached) |
| **publish** | `upload-defectdojo` | — | ~30s |
| **deploy** | `notify-obs` | — | ~10s |

**Key observations**:
- `lint-yaml` and `lint-shell` run in **parallel**
- `unit-tests`, `integration-tests`, `contract-tests` run in **parallel**
- `build-image` uses **CNB cache** (faster on subsequent runs)

> ✅ **Checkpoint**: Pipeline completes with parallel stages visible. Note the total build time.

---

## Step 5 — Measure and Optimize Build Performance (2 minutes)

### 5.1 Record Baseline Build Time

1. In Woodpecker UI, click on the completed build
2. Note the **total duration** and **per-stage duration**
3. Record: Total time = ___ minutes

### 5.2 Observe Caching Effect

```bash
# Make another small change to trigger second build
cd ~/dojo-labs/uFawkesDevX/my-golden-path-app
echo "# Update" >> README.md
git add README.md
git commit -m "Trigger second build for caching test"
git push origin main
```

1. Watch the second pipeline run
2. Note the **build-image stage duration** — should be faster due to CNB cache
3. Record: Second build total time = ___ minutes
4. **Cache improvement** = (First - Second) / First × 100 = ___%

### 5.3 View Performance in Woodpecker UI

1. In Woodpecker, go to the repository page
2. Click on the **Builds** tab
3. Compare build durations across runs
4. Observe stage-level timing

> ✅ **Checkpoint**: You've measured baseline and cached build times, observed parallel execution.

---

## Step 6 — Run the Validation Script

```bash
# From your uFawkesDojo checkout
cd /path/to/uFawkesDojo
bash yellow-belt/module-06-golden-path/lab-01/validate.sh
```

**Expected output** (all checks pass):

```
[INFO] Starting Yellow Belt Module 06 Lab 01 validation...

[✓] Prerequisites: curl, jq, git, cookiecutter installed
[✓] uFawkesPipe Stack: all 5 services healthy
[✓] Woodpecker API: reachable at http://localhost:8000
[✓] Pipeline Run: my-golden-path-app pipeline completed successfully
[✓] Parallel Execution: lint-yaml and lint-shell ran in parallel
[✓] Build Caching: Second build faster than first (CNB cache)
[✓] Performance Measured: Build time recorded and compared

==========================================
Total Tests: 7
Passed: 7
Failed: 0

[✓] All tests passed! ✅

🎉 Congratulations! You've completed Yellow Belt Module 6 Lab 01.
   You've built an optimized Golden Path pipeline with parallel execution
   and build caching. Move on to Module 07: Security & Quality Gates.
```

---

## Clean Up

```bash
# Remove local repos (optional)
rm -rf ~/dojo-labs/golden-path-lab
rm -rf ~/dojo-labs/my-golden-path-app.git

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
| Pipeline fails at `secrets-scan` | Gitleaks found secret | Check `.gitleaks.toml` allowlist, remove secret |
| Pipeline fails at `build-image` | CNB builder issue | Check Docker access, `docker ps` |
| Build not faster on second run | Cache not working | Check `pack_cache` volume, `docker volume ls` |

---

## Retrieval Check (Answer Without Looking Back)

Write your answers down — the act of writing (not just thinking) strengthens retention.

1. What file defines the Golden Path pipeline contract in uFawkesPipe?
2. How do you enable parallel execution in a pipeline?
3. How does CNB caching work between builds?
4. What does `advanced.parallel.enabled: true` do?
5. Where can you find build performance metrics in Woodpecker?

(Suggested answers: 1 = .fawkespipe.yml; 2 = advanced.parallel.enabled: true; 3 = CNB caches buildpack layers between builds; 4 = enables parallel execution for compatible stages; 5 = Woodpecker UI build details, Prometheus/Grafana)

---

## Reference: What You Built

| File | Purpose |
|------|---------|
| `.fawkespipe.yml` | Optimized Golden Path contract (parallel, caching, resources) |
| `.woodpecker.yml` | Generated Woodpecker pipeline (from .fawkespipe.yml) |
| `src/app.py` | Flask app with `/health` endpoint |
| `tests/test_app.py` | Pytest suite |
| `.devcontainer/devcontainer.json` | Coder workspace definition |

You've now built an optimized Golden Path pipeline with parallel execution, build caching, and performance measurement — the foundation for scalable, maintainable CI/CD!

---

## Retrieval Check Answers

1. **Contract file**: `.fawkespipe.yml`
2. **Parallel execution**: `advanced.parallel.enabled: true`
3. **CNB caching**: Caches buildpack layers between builds
4. **Parallel config**: Enables parallel execution for compatible stages
5. **Metrics**: Woodpecker UI build details, Prometheus/Grafana

---

➡️ **Next**: Return to [Module 6 README](../README.md), then continue to **Module 07: Security Scanning & Quality Gates**.
