# Lab 01: GitOps Workflow with Score Service

**Module**: White Belt — Module 3: GitOps Principles
**Estimated Time**: 15 minutes
**Difficulty**: Beginner (Module 1 completion required)
**Runs against**: [uFawkesDevX v1.0.1](https://github.com/paruff/uFawkesDevX/releases/tag/v1.0.1) (Docker Compose)

---

## Objectives

By the end of this lab you will have:

1. Explored the Backstage catalog as the source of truth
2. Registered a new service via the Score API
3. Created a service using the Backstage Scaffolder
4. Observed the GitOps-like workflow (spec → validation → pipeline trigger → catalog update)
5. Practiced rollback by reverting a Score workload spec

---

## Why This Lab Uses uFawkesDevX

This lab runs against **uFawkesDevX** — the Developer Experience plane — because it provides a complete GitOps workflow in Docker Compose:

- **Score Service** validates workload specs and triggers pipelines (like ArgoCD but for Score specs)
- **Backstage Catalog** serves as the source of truth (like Git repository state)
- **Scaffolder** creates services from templates (GitOps-ready from the start)
- **No Kubernetes required** — runs on your laptop

This demonstrates GitOps principles without the cluster complexity.

---

## Prerequisites

**Required**: uFawkesDevX v1.0.1 running from Module 1

```bash
# Verify your stack is still running
cd ~/dojo-labs/uFawkesDevX
make status
```

**Expected**: All 5 services healthy (coder, backstage, score-service, plugin-manager, gateway)

**Tools required** (already installed from Module 1):
- `curl` — HTTP client
- `jq` — JSON processor (install: `brew install jq` or `apt install jq`)
- `git` — version control
- `cookiecutter` — `pip install cookiecutter`

---

## Step 0 — Read the Theory First (if you haven't)

This lab assumes you've read the [Module 3 theory](../README.md#theory-summary-20-minutes)
up through "uFawkesDevX GitOps Architecture". You should be able to name the
four GitOps principles and identify the uFawkesDevX components that implement them.

---

## Step 1 — Explore the Backstage Catalog (3 minutes)

Open Backstage in your browser: **http://localhost:7007**

### 1.1 Tour the Catalog (Worked Example)

1. Click **Catalog** in the left sidebar
2. Click **Components** tab
3. You should see your `hello-devx` service from Module 1
4. Click on `hello-devx`
5. Observe:
   - **Overview** tab: Description, owner, links
   - **APIs** tab: Any APIs provided (Score API, etc.)
   - **TechDocs** tab: Your README rendered as documentation

> ✅ **Checkpoint**: You can navigate to your Module 1 service in the catalog.
> This catalog is the **source of truth** — like "Git state" in traditional GitOps.

### 1.2 Check Score Service in Catalog

1. Search for `score-service` in the catalog
2. Click on it
3. Check the **APIs** tab — you should see:
   - `score-api` — REST API for spec management
   - `score-webhooks` — Pipeline trigger webhooks

This is the **GitOps engine** — it validates specs and triggers pipelines.

---

## Step 2 — Register a Service via Score API (5 minutes)

Now you'll register a new service by submitting a Score workload spec directly to the Score API.

### 2.1 Create a Score Spec

```bash
# Work in a temporary directory
mkdir -p ~/dojo-labs/gitops-lab && cd ~/dojo-labs/gitops-lab

# Create a Score workload spec for a new service
cat > hello-gitops.yaml <<'EOF'
apiVersion: score.dev/v1b1
metadata:
  name: hello-gitops
containers:
  hello-gitops:
    image: ghcr.io/dojo/hello-gitops:latest
    variables:
      PORT: "8080"
service:
  ports:
    www:
      port: 8080
      targetPort: 8080
EOF

# Verify the spec
cat hello-gitops.yaml
```

### 2.2 Submit to Score Service

```bash
# Submit the spec to Score Service via API Gateway
curl -s -X POST http://localhost:8000/api/score/specs \
  -H "Content-Type: application/json" \
  -d @hello-gitops.yaml | jq .
```

**Expected response**: JSON with the validated spec and a `spec_id`.

```json
{
  "spec_id": "abc123...",
  "metadata": {
    "name": "hello-gitops"
  },
  "containers": {
    "hello-gitops": {
      "image": "ghcr.io/dojo/hello-gitops:latest",
      "variables": { "PORT": "8080" }
    }
  },
  "service": { ... }
}
```

> **What just happened**: The Score Service validated your `score.yaml` against
> the `score.dev/v1b1` schema, stored it, and returned a spec ID. In a real
> platform, this would also trigger the uFawkesPipe pipeline via webhook.

### 2.3 Verify in Backstage

1. Refresh the Backstage Catalog page (or wait ~30 seconds for auto-refresh)
2. Search for `hello-gitops`
3. Click on the component
3. You should see it registered with the spec metadata

> ✅ **Checkpoint**: Your `hello-gitops` service appears in the Backstage catalog
> without using the Scaffolder — direct API submission. This is like "Git push → ArgoCD sync".

---

## Step 3 — Create Service with Scaffolder (5 minutes)

Now you'll use the Backstage Scaffolder to create a new service from a template.
This is the **developer self-service** path — golden path template → registered service.

### 3.1 Access Scaffolder

1. In Backstage, click **Create** in the left sidebar
2. You should see available templates:
   - **Deploy Score Workload** (from uFawkesDevX catalog template)
   - Any other templates registered

### 3.2 Run the Template

If the "Deploy Score Workload" template is available:

1. Click **Deploy Score Workload**
2. Fill in:
   - **Workload Name**: `hello-scaffolded`
   - **Description**: `Scaffolded service for GitOps lab`
   - **Container Image**: `ghcr.io/dojo/hello-scaffolded:latest`
   - **Replicas**: `1`
   - **Port**: `8080`
3. Click **Review** → **Create**

If the template is not available (Scaffolder not fully configured), skip to the
alternative below.

### 3.3 Alternative: Cookiecutter + Score API

If Scaffolder template isn't available, create via Cookiecutter and register:

```bash
# Scaffold using Cookiecutter (same as Module 1)
cd ~/dojo-labs/uFawkesDevX
cookiecutter templates/python-flask-app --no-input \
  project_name="Hello Scaffolded" \
  project_slug="hello-scaffolded" \
  language="python" \
  registry_namespace="dojo"

# Register the generated score.yaml via Score API
cd ~/dojo-labs/uFawkesDevX/hello-scaffolded
curl -s -X POST http://localhost:8000/api/score/specs \
  -H "Content-Type: application/json" \
  -d @score.yaml | jq .
```

### 3.4 Verify in Backstage

1. Refresh Backstage Catalog
2. Search for `hello-scaffolded`
3. Verify it appears with:
   - **TechDocs** tab showing README
   - **APIs** tab (if Score spec registered APIs)

> ✅ **Checkpoint**: Your scaffolded service appears in Backstage with TechDocs.
> This is the **golden path** — template → spec → catalog in minutes.

---

## Step 4 — Practice Rollback (2 minutes)

GitOps rollback = `git revert` on spec + re-submit. Let's practice.

### 4.1 Simulate a "Bad" Deployment

```bash
# Update the hello-gitops spec with a "bad" image tag
cat > hello-gitops-bad.yaml <<'EOF'
apiVersion: score.dev/v1b1
metadata:
  name: hello-gitops
containers:
  hello-gitops:
    image: ghcr.io/dojo/hello-gitops:v2.0-broken  # Broken version!
    variables:
      PORT: "8080"
service:
  ports:
    www:
      port: 8080
      targetPort: 8080
EOF

# Submit the bad spec
curl -s -X POST http://localhost:8000/api/score/specs \
  -H "Content-Type: application/json" \
  -d @hello-gitops-bad.yaml | jq .

# In real GitOps: this would trigger pipeline → deploy broken version
# Backstage would show the new spec version
```

### 4.2 Perform Rollback

```bash
# Rollback: Revert to the previous (good) spec
# In real GitOps: git revert HEAD
# Here: just re-submit the original good spec
curl -s -X POST http://localhost:8000/api/score/specs \
  -H "Content-Type: application/json" \
  -d @hello-gitops.yaml | jq .

# In real GitOps: pipeline deploys v1.0 again
# Backstage shows rollback
```

> ✅ **Checkpoint**: You've practiced the GitOps rollback pattern —
> revert spec in Git → re-submit → pipeline deploys previous version.
> **MTTR: seconds, not minutes.**

---

## Step 5 — Run the Validation Script

```bash
# From your uFawkesDojo checkout
cd /path/to/uFawkesDojo
bash white-belt/module-03-gitops-principles/lab-01/validate.sh
```

**Expected output** (all checks pass):

```
[INFO] Starting White Belt Module 03 Lab 01 validation...

[✓] Prerequisites: curl, jq, git, cookiecutter installed
[✓] uFawkesDevX Stack: all 5 services healthy
[✓] Backstage Catalog: API reachable
[✓] Score Service: API reachable and validates specs
[✓] Service Registration: hello-gitops registered via Score API
[✓] Scaffolder Service: hello-scaffolded registered
[✓] Rollback Pattern: Spec re-submission works

==========================================
Total Tests: 7
Passed: 7
Failed: 0

[✓] All tests passed! ✅

🎉 Congratulations! You've completed White Belt Module 3 Lab 01.
   You've experienced GitOps: spec → validate → trigger → catalog → rollback.
   Move on to Module 04: Your First Deployment.
```

---

## Clean Up

When you are done with the lab, remove the test services from Backstage
(optional — they don't consume significant resources):

```bash
# No cleanup required for API-registered specs
# They remain in Backstage catalog until manually removed
# Or just leave them for reference
```

---

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| `curl: (7) Failed to connect` on port 8000 | Score service not healthy | Run `make status` in uFawkesDevX, check `developerd-score` |
| `422` response from Score API | Spec doesn't match schema | Check `score.yaml` syntax, validate against score.dev/v1b1 |
| Service not in Backstage catalog | Catalog not refreshed | Wait 30s, or refresh browser; check Score service logs |
| `jq: command not found` | jq not installed | `brew install jq` (macOS) or `apt install jq` (Linux) |
| Cookiecutter template fails | Template not found | Ensure you're in uFawkesDevX root directory |

---

## Retrieval Check (Answer Without Looking Back)

Write your answers down — the act of writing (not just thinking) strengthens retention.

1. What are the four GitOps principles?
2. In uFawkesDevX, which component validates the Score spec?
3. What triggers the uFawkesPipe pipeline?
4. How do you rollback a service in uFawkesDevX GitOps?
5. What serves as the "source of truth" in uFawkesDevX?

(Suggested answers: 1 = Declarative, Versioned, Pulled, Reconciled; 2 = Score Service; 3 = Score Service webhook after validation; 4 = git revert score.yaml + re-submit to Score API; 5 = Backstage Catalog)

---

## Reference: What You Used

| Component | Role in GitOps |
|-----------|----------------|
| **Score Service** | Validates spec, triggers pipeline, updates catalog |
| **Backstage Catalog** | Source of truth — stores spec metadata |
| **Scaffolder** | Self-service: template → registered service |
| **Score Spec (`score.yaml`)** | Declarative desired state |
| **uFawkesPipe** | Build/test/deploy pipeline (triggered by Score) |

Study the `hello-gitops.yaml` and `score.yaml` from scaffolded service to
understand the GitOps pattern. In Module 4 you'll do the full lifecycle.

---

➡️ **Next**: Return to [Module 3 README](../README.md), then continue to **Module 04: Your First Deployment**.
