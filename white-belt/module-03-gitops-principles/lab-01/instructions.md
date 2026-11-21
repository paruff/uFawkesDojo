# Lab 01: GitOps Workflow with Score Service

**Module**: White Belt — Module 3: GitOps Principles
**Estimated Time**: 15 minutes
**Difficulty**: Beginner (Module 1 completion required)
**Runs against**: [uFawkesDevX v1.2.0](https://github.com/paruff/uFawkesDevX/releases/tag/v1.2.0) (Docker Compose)

> **Run for real on 2026-11-21** against uFawkesDevX v1.2.0 (the Module 1 stack). The Backstage Scaffolder template **fails** on v1.2.0 (Step 3.1); the Cookiecutter path in Step 3.2 is the one that works.

---

## Objectives

By the end of this lab you will have:

1. Explored the Backstage catalog and the Score service's spec store
2. Registered a new service via the Score API
3. Created a service with Cookiecutter and registered it
4. Observed the GitOps-like workflow (spec → validation → versioned store)
5. Practiced rollback by reverting a Score workload spec

---

## Why This Lab Uses uFawkesDevX

This lab runs against **uFawkesDevX** — the Developer Experience plane — because it provides a complete GitOps workflow in Docker Compose:

- **Score Service** validates workload specs and triggers pipelines (like ArgoCD but for Score specs)
- **Score spec store** keeps every spec with a version number (like Git history)
- **Golden-path templates** create services that are GitOps-ready from the start
- **No Kubernetes required** — runs on your laptop

This demonstrates GitOps principles without the cluster complexity.

---

## Prerequisites

**Required**: uFawkesDevX v1.2.0 running from Module 1

```bash
# Verify your stack is still running
cd ~/dojo-labs/uFawkesDevX
make status
```

**Expected**: All 5 services healthy (coder, backstage, score-service, plugin-manager, gateway)

**Tools required** (already installed from Module 1):
- `curl` — HTTP client
- `jq` — JSON processor (install: `brew install jq` or `apt install jq`)
- `docker` — runs `yq` in a container to convert YAML specs to JSON
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

1. Sign in as a guest and click **Catalog** in the left sidebar
2. Set **Kind** to **Component**
3. You should see `plugin-manager`, `score-service` and `ufawkes-devx`. Your `hello-devx` service from Module 1 is **not** there: the Score service doesn't write to the catalog
4. Click on `ufawkes-devx`
5. Observe:
   - **Overview** tab: Description, owner, links

> ✅ **Checkpoint**: You can navigate the catalog. It describes the platform's own
> parts; the specs you submit live in the Score service (Step 2).

### 1.2 Check Score Service in Catalog

1. Click on `score-service`
2. Check the **APIs** tab — you should see `score-api` (REST API for spec management)

This is the **GitOps engine** — it validates specs and keeps every version.

### 1.3 List the specs the Score service holds

```bash
curl -s http://localhost:8000/api/score/specs | jq '.specs[] | {name, version, status}'
```

**Expected output**: `hello-devx` at version 1 or 2 from Module 1 (it is the only one on a fresh stack).

---

## Step 2 — Register a Service via Score API (5 minutes)

Now you'll register a new service by submitting a Score workload spec directly to the Score API.

### 2.1 Create a Score Spec

```bash
# Work in a temporary directory
mkdir -p ~/dojo-labs/gitops-lab && cd ~/dojo-labs/gitops-lab

# Create a Score workload spec for a new service
# (the Score service rejects a spec without metadata.annotations)
cat > hello-gitops.yaml <<'EOF'
apiVersion: score.dev/v1b1
metadata:
  name: hello-gitops
  annotations:
    dojo/lab: white-belt-03
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

The API takes JSON, so define a small helper that converts a YAML spec with
`yq` (in a container) and posts it. Define it once in this shell:

```bash
submit() {
  docker run --rm -i mikefarah/yq:4 -o=json . < "$1" \
    | curl -s -X POST http://localhost:8000/api/score/specs \
        -H "Content-Type: application/json" -d @- | jq .
}

# Submit the spec to Score Service via API Gateway
submit hello-gitops.yaml
```

**Expected response**: HTTP 201 and JSON with `id`, `name`, your `spec`,
`version` (`1`) and `status` (`validated`). There is no `spec_id` field.

```json
{
  "id": 2,
  "name": "hello-gitops",
  "spec": { "apiVersion": "score.dev/v1b1", "metadata": { "name": "hello-gitops", "annotations": { "dojo/lab": "white-belt-03" } }, "...": "..." },
  "version": 1,
  "status": "validated",
  "composeGenerated": true
}
```

> **What just happened**: The Score Service validated your spec against
> the `score.dev/v1b1` schema and stored it as version 1. Posting the same name
> again bumps the version. With `PIPELINE_WEBHOOK_URL` unset it does not call uFawkesPipe.

### 2.3 Verify the registration

```bash
curl -s http://localhost:8000/api/score/specs/hello-gitops | jq '{name, version, status}'
```

> ✅ **Checkpoint**: `hello-gitops` is at version 1, `validated`. This is direct
> API submission: "Git push → ArgoCD sync" in spirit.

---

## Step 3 — Create a Service from a Golden Path Template (5 minutes)

Now you'll create a service from the golden path template and register it.
This is the **developer self-service** path.

### 3.1 The Backstage Scaffolder (does not work on v1.2.0)

The catalog has a **Deploy Score Workload** template (**Create** in the left
sidebar). Running it fails on v1.2.0: the template's steps use the `http:post`
action, which this Backstage doesn't register, so the task ends with
`Template action with ID 'http:post' is not registered`. Don't spend time on it;
use the Cookiecutter path below.

### 3.2 Cookiecutter + Score API

Create the service with Cookiecutter and register it:

```bash
# Scaffold using Cookiecutter (same as Module 1)
cd ~/dojo-labs/uFawkesDevX
cookiecutter templates/python-flask-app --no-input \
  project_name="Hello Scaffolded" \
  project_slug="hello-scaffolded" \
  language="python" \
  registry_namespace="dojo"

# Register the generated score.yaml via Score API. The template's spec has no
# annotations yet, so add one while converting (same idea as `submit` above).
cd ~/dojo-labs/uFawkesDevX/hello-scaffolded
docker run --rm -i mikefarah/yq:4 -o=json '.metadata.annotations."dojo/lab" = "white-belt-03"' < score.yaml \
  | curl -s -X POST http://localhost:8000/api/score/specs \
      -H "Content-Type: application/json" -d @- | jq '{name, version, status}'
```

### 3.3 Verify the registration

```bash
curl -s http://localhost:8000/api/score/specs | jq '.specs[].name'
```

**Expected output**: `"hello-devx"`, `"hello-gitops"` and `"hello-scaffolded"`.

> ✅ **Checkpoint**: Your scaffolded service is registered. This is the **golden
> path**: template → spec → registered in minutes.

---

## Step 4 — Practice Rollback (2 minutes)

GitOps rollback = `git revert` on spec + re-submit. Let's practice.

### 4.1 Simulate a "Bad" Deployment

```bash
# Update the hello-gitops spec with a "bad" image tag
cd ~/dojo-labs/gitops-lab
cat > hello-gitops-bad.yaml <<'EOF'
apiVersion: score.dev/v1b1
metadata:
  name: hello-gitops
  annotations:
    dojo/lab: white-belt-03
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

# Submit the bad spec (needs the submit helper from Step 2.2)
submit hello-gitops-bad.yaml | jq '{name, version}'

# Expected: version 2. In real GitOps this would trigger a pipeline and deploy the broken version
```

### 4.2 Perform Rollback

```bash
# Rollback: Revert to the previous (good) spec
# In real GitOps: git revert HEAD
# Here: just re-submit the original good spec
submit hello-gitops.yaml | jq '{name, version}'

# Expected: version 3, with the good image again. Check it:
curl -s http://localhost:8000/api/score/specs/hello-gitops | jq '.spec.containers["hello-gitops"].image'
# Expected: "ghcr.io/dojo/hello-gitops:latest"

# In real GitOps: the pipeline deploys the good version again
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

[✓] Prerequisites: docker, docker compose, git, curl, jq, cookiecutter installed
[✓] uFawkesDevX Stack: all 5 services healthy (coder, backstage, score-service, plugin-manager, gateway)
[✓] Backstage Catalog: systems: developer-control-plane ufawkes-obs ufawkes-pipe ufawkes-sec
[✓] Gateway: reachable at http://localhost:8000
[✓] Direct API Registration: hello-gitops is registered (version 3)
[✓] Rollback Pattern: hello-gitops is back on :latest at version 3
[✓] Scaffolded Service: hello-scaffolded has score.yaml and .fawkespipe.yml
[✓] Cookiecutter Registration: hello-scaffolded is registered (version 1)

==========================================
Total Tests : 8
Passed      : 8
Failed      : 0

[✓] All tests passed! ✅

🎉 Congratulations! You've completed White Belt Module 3 Lab 01.
   You've experienced GitOps: spec → validate → trigger → catalog → rollback.
   Move on to Module 04: Your First Deployment.
```

---

## Clean Up

When you are done with the lab, remove the test specs from the Score service
(optional — they don't consume significant resources):

```bash
for n in hello-gitops hello-scaffolded; do curl -s -X DELETE http://localhost:8000/api/score/specs/$n; done
```

---

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| `curl: (7) Failed to connect` on port 8000 | Score service not healthy | Run `make status` in uFawkesDevX, check `developerd-score` |
| `400` `Invalid Score specification` | Spec doesn't match the schema, or the body isn't JSON | Check `details` in the response; post through `submit` |
| `400` `Plugin example-validator validation failed` | No `metadata.annotations` | Add an annotation, as in Step 2.1 |
| Scaffolder task fails on `http:post` | The template needs an action v1.2.0 doesn't register | Use Cookiecutter (Step 3.2) |
| `jq: command not found` | jq not installed | `brew install jq` (macOS) or `apt install jq` (Linux) |
| Cookiecutter template fails | Template not found | Ensure you're in uFawkesDevX root directory |
| `submit: command not found` | New shell | Define `submit` again (Step 2.2) |

---

## Retrieval Check (Answer Without Looking Back)

Write your answers down — the act of writing (not just thinking) strengthens retention.

1. What are the four GitOps principles?
2. In uFawkesDevX, which component validates the Score spec?
3. What does the Score service do on a second POST of the same spec name?
4. How do you rollback a service in uFawkesDevX GitOps?
5. Where does the Score service keep each version of a spec?

(Suggested answers: 1 = Declarative, Versioned, Pulled, Reconciled; 2 = Score Service; 3 = it stores a new version (version 2) of the spec; 4 = git revert score.yaml + re-submit to Score API; 5 = in its own SQLite store, read back through `/api/score/specs/<name>`)

---

## Reference: What You Used

| Component | Role in GitOps |
|-----------|----------------|
| **Score Service** | Validates spec, stores each version, notifies a pipeline webhook if one is set |
| **Backstage Catalog** | Describes the platform's own components and APIs |
| **Cookiecutter template** | Self-service: template → registered service |
| **Score Spec (`score.yaml`)** | Declarative desired state |
| **uFawkesPipe** | Build/test/deploy pipeline (triggered by Score) |

Study the `hello-gitops.yaml` and `score.yaml` from scaffolded service to
understand the GitOps pattern. In Module 4 you'll do the full lifecycle.

---

➡️ **Next**: Return to [Module 3 README](../README.md), then continue to **Module 04: Your First Deployment**.
