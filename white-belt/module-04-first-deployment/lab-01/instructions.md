# Lab 01: Your First Deployment with uFawkesDevX

**Module**: White Belt — Module 4: Your First Deployment
**Estimated Time**: 20 minutes
**Difficulty**: Beginner (Modules 1-3 complete required)
**Runs against**: [uFawkesDevX v1.0.1](https://github.com/paruff/uFawkesDevX/releases/tag/v1.0.1) (Docker Compose)

> **Not yet run for real.** uFawkesDevX v1.0.1 exists, but no one has run every step of this lab against it. Treat the steps and the expected output as unverified. See the [audit](../../../docs/ai-sdlc/compose-curriculum/audit-2026-10-06.md).

---

## Objectives

By the end of this lab you will have:

1. Created a new service (`my-first-app`) using the Backstage Scaffolder and Python Flask golden path template
2. Observed the Score Service validate the spec and trigger the uFawkesPipe pipeline
3. Monitored the pipeline execution in Woodpecker (uFawkesPipe) UI
4. Created a Coder workspace from the scaffolded repository
5. Verified the application responds to health checks in the workspace

---

## Why This Lab Uses uFawkesDevX

This lab runs against **uFawkesDevX** — the Developer Experience plane — because it provides a complete deployment workflow in Docker Compose:

- **Backstage Scaffolder** creates services from golden path templates
- **Score Service** validates workload specs and triggers pipelines
- **uFawkesPipe (Woodpecker)** runs CI/CD: lint → test → build → push
- **Coder** provisions devcontainer workspaces
- **No Kubernetes required** — runs on your laptop

This demonstrates the full deployment workflow without cluster complexity.

---

## Prerequisites

**Required**: uFawkesDevX v1.0.1 running from Module 1

```bash
# Verify your stack is still running
cd ~/dojo-labs/uFawkesDevX
make status
```

**Expected**: All 5 services healthy (coder, backstage, score-service, plugin-manager, gateway)

**Required**: Module 3 completed (understand GitOps workflow with Score Service)

**Tools required** (already installed from Module 1):
- `curl` — HTTP client
- `jq` — JSON processor
- `git` — version control
- `cookiecutter` — `pip install cookiecutter`

---

## Step 0 — Read the Theory First (if you haven't)

This lab assumes you've read the [Module 4 theory](../README.md#theory-summary-15-minutes)
up through "Golden Path Templates". You should be able to name the four stages
of the uFawkesDevX deployment workflow and identify the components.

---

## Step 1 — Create Service via Backstage Scaffolder (5 minutes)

### 1.1 Open Backstage

Navigate to **http://localhost:7007** in your browser.

### 1.2 Access the Scaffolder

1. Click **Create** in the left sidebar
2. You should see the **Deploy Score Workload** template (registered in uFawkesDevX catalog)
3. Click **Choose** on the template

### 1.3 Fill in Template Parameters

Fill in the form:

| Field | Value |
|-------|-------|
| **Workload Name** | `my-first-app` |
| **Description** | `My first deployment on uFawkesDevX` |
| **Container Image** | `ghcr.io/dojo/my-first-app` |
| **Replicas** | `1` |
| **Port** | `8080` |
| **CPU Limit** | `100m` |
| **Memory Limit** | `128Mi` |

### 1.4 Submit and Wait

1. Click **Review** → **Create**
2. Wait ~30 seconds for the template to execute
3. You'll see a progress indicator showing:
   - Template rendering (Cookiecutter)
   - Git repository initialization
   - Git push to local Git remote
   - Component registration in Backstage

### 1.5 Verify Component Created

1. When complete, click **Open in catalog**
2. You should see the `my-first-app` component page with:
   - **Overview** tab: description, owner
   - **TechDocs** tab: README rendered
   - **APIs** tab: (empty until Score spec submitted)

> ✅ **Checkpoint**: `my-first-app` appears in Backstage catalog with TechDocs.
> The Scaffolder created the Git repo and registered the component.

---

## Step 2 — Examine Generated Files (3 minutes)

### 2.1 Clone the Generated Repository

```bash
# The Scaffolder pushed to a local Git remote
# Find the repo URL from Backstage component page (GitHub link)
# Or check the Scaffolder task output for the repo URL

# For this lab, the repo was created locally:
cd ~/dojo-labs/uFawkesDevX

# Check if there's a local bare repo from Scaffolder
ls -la ~/dojo-labs/ | grep my-first-app

# If found, clone it:
git clone ~/dojo-labs/my-first-app.git
cd my-first-app
```

**Alternative**: If the Scaffolder created a GitHub repo, clone from there:
```bash
git clone https://github.com/<your-username>/my-first-app.git
cd my-first-app
```

### 2.2 Examine Key Files

```bash
# Score workload spec — declarative desired state
cat score.yaml

# uFawkesPipe CI/CD contract
cat .fawkespipe.yml

# Coder devcontainer definition
cat .devcontainer/devcontainer.json

# Container build (uses Cloud Native Buildpacks)
cat Dockerfile

# Application code
cat src/app.py

# Tests
cat tests/test_app.py

# Documentation (renders as TechDocs in Backstage)
head -30 README.md
```

**Key observations**:
- `score.yaml` declares the workload (containers, variables, service ports)
- `.fawkespipe.yml` defines lint → test → build stages
- `.devcontainer/devcontainer.json` pins Python 3.12 image with Docker-in-Docker
- `Dockerfile` uses CNB builder (paketobuildpacks/builder-jammy-base)

---

## Step 3 — Submit Score Spec and Watch Pipeline (5 minutes)

### 3.1 Submit Score Spec via API

The Scaffolder may have already submitted the spec. Let's verify and submit if needed:

```bash
# Submit the score.yaml to Score Service
cd ~/dojo-labs/my-first-app  # or wherever you cloned

curl -s -X POST http://localhost:8000/api/score/specs \
  -H "Content-Type: application/json" \
  -d @score.yaml | jq .
```

**Expected response**: JSON with `spec_id` and validated spec.

> **What happened**: Score Service validated `score.yaml` against `score.dev/v1b1`, stored it in Backstage catalog, and POSTed to uFawkesPipe webhook.

### 3.2 Watch Pipeline in Woodpecker (uFawkesPipe)

1. Open **http://localhost:8000** in your browser (Woodpecker UI)
2. You may need to log in with your Gitea/GitHub credentials
3. Find the `my-first-app` pipeline
4. Click on the latest run

**Watch the stages execute**:
1. **lint** → Runs ruff (Python linter)
2. **test** → Runs pytest
3. **build** → CNB creates container image
4. **push** → Pushes to ghcr.io/dojo/my-first-app

> ✅ **Checkpoint**: Pipeline shows green checkmarks for all stages.
> Total time: ~3-5 minutes.

### 3.3 Verify in Backstage

1. Refresh the `my-first-app` component page in Backstage
2. Check **TechDocs** tab — README should render
3. Check if any **APIs** tab shows registered endpoints

---

## Step 4 — Open in Coder Workspace (5 minutes)

### 4.1 Access Coder

Navigate to your `CODER_ACCESS_URL` (e.g., `http://192.168.1.42:7080`)

### 4.2 Create Workspace

1. Click **New workspace**
2. Select template: **devcontainer-docker** (pushed in Module 1)
3. **Repository URL**: Enter your `my-first-app` Git repo URL
   - Local: `file:///home/user/dojo-labs/my-first-app.git`
   - GitHub: `https://github.com/<user>/my-first-app.git`
4. Click **Create workspace**

### 4.3 Wait for Workspace to Start

1. Status will show: **Starting** → **Building** → **Running**
2. First build takes ~2-3 minutes (pulls base image, installs dependencies)
3. Subsequent starts are faster

### 4.4 Verify Application in Workspace

Once workspace is **Running**:

1. Click **Open in VS Code Web** (or use SSH)
2. In the terminal, run:
   ```bash
   # The app should auto-start via postCreateCommand
   # If not, start manually:
   python src/app.py &
   ```

3. Test health endpoint:
   ```bash
   curl -s http://localhost:8080/health
   ```

**Expected response**: `{"status":"healthy"}` or similar JSON

> ✅ **Checkpoint**: Application responds to health check in Coder workspace.
> The full workflow: Template → Spec → Pipeline → Workspace → Running App.

---

## Step 5 — Run the Validation Script

```bash
# From your uFawkesDojo checkout
cd /path/to/uFawkesDojo
bash white-belt/module-04-first-deployment/lab-01/validate.sh
```

**Expected output** (all checks pass):

```
[INFO] Starting White Belt Module 04 Lab 01 validation...

[✓] Prerequisites: curl, jq, git, cookiecutter installed
[✓] uFawkesDevX Stack: all 5 services healthy
[✓] Backstage Catalog: API reachable with my-first-app component
[✓] Score Service: Spec submission and validation works
[✓] uFawkesPipe: Pipeline executed for my-first-app
[✓] Coder: Workspace created and running for my-first-app
[✓] Application Health: Responds to /health in workspace

==========================================
Total Tests: 7
Passed: 7
Failed: 0

[✓] All tests passed! ✅

🎉 Congratulations! You've completed White Belt Module 4 Lab 01.
   You've deployed your first app: Scaffolder → Score → Pipeline → Coder.
   You're ready for the White Belt Assessment!
```

---

## Clean Up

When you are done with the lab:

```bash
# Stop Coder workspace (from Coder UI)
# Or let it auto-stop after inactivity

# Remove local repo (optional)
rm -rf ~/dojo-labs/my-first-app
rm -rf ~/dojo-labs/my-first-app.git
```

---

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| Scaffolder task fails | Template not found / Git push failed | Check Backstage task logs; ensure uFawkesDevX catalog has template |
| Score API returns 422 | Spec schema validation failed | Check `score.yaml` syntax; validate against score.dev/v1b1 |
| Pipeline stuck in Woodpecker | Build queue / runner issue | Check Woodpecker runner status; `docker logs woodpecker-server` |
| Coder workspace won't start | CODER_ACCESS_URL is localhost | Set to LAN IP in `.env`; `make up` again |
| App not responding in workspace | Port mismatch / app not started | Check `score.yaml` port matches app; run `python src/app.py` manually |
| Image push fails | Registry auth / quota | Check ghcr.io credentials in Woodpecker; verify namespace |

---

## Retrieval Check (Answer Without Looking Back)

Write your answers down — the act of writing (not just thinking) strengthens retention.

1. What are the four stages of the uFawkesDevX deployment workflow?
2. Which component validates the `score.yaml` and triggers the pipeline?
3. What does the `.fawkespipe.yml` file define?
4. How does Coder know how to build the workspace container?
5. Where do you view pipeline stage logs?

(Suggested answers: 1 = Scaffolder → Score → Pipeline → Coder; 2 = Score Service; 3 = uFawkesPipe CI/CD contract (lint, test, build, push); 4 = .devcontainer/devcontainer.json; 5 = Woodpecker UI at http://localhost:8000)

---

## Reference: What You Built

| File | Purpose |
|------|---------|
| `score.yaml` | Score workload spec (declarative desired state) |
| `.fawkespipe.yml` | uFawkesPipe CI/CD contract |
| `.devcontainer/devcontainer.json` | Coder workspace definition |
| `Dockerfile` | CNB-based container build |
| `src/app.py` | Flask app with `/health` endpoint |
| `tests/test_app.py` | Pytest suite |
| `README.md` | TechDocs source |

You've now experienced the complete uFawkesDevX workflow — from template to running application in a devcontainer workspace. This is the foundation for all your future deployments!

---

➡️ **Next**: Return to [Module 4 README](../README.md), then prepare for the **White Belt Assessment**!
