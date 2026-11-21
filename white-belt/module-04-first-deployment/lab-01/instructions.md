# Lab 01: Your First Deployment with uFawkesDevX

**Module**: White Belt — Module 4: Your First Deployment
**Estimated Time**: 20 minutes
**Difficulty**: Beginner (Modules 1-3 complete required)
**Runs against**: [uFawkesDevX v1.2.0](https://github.com/paruff/uFawkesDevX/releases/tag/v1.2.0) (Docker Compose)

> **Run for real on 2026-11-21** against uFawkesDevX v1.2.0 (the Module 1 stack). This lab no longer uses the Backstage Scaffolder (it fails on v1.2.0, see Module 3), a Woodpecker pipeline or a Coder workspace: none of them can be driven from this stack alone. The pipeline here is the Score service's trigger record; a real build runs in uFawkesPipe (Yellow Belt).

---

## Objectives

By the end of this lab you will have:

1. Created a new service (`my-first-app`) from the Python Flask golden path template
2. Registered its Score spec and triggered the pipeline webhook
3. Read the recorded pipeline run from the Score API
4. Ran the application's tests and checked its health endpoint in a container

---

## Why This Lab Uses uFawkesDevX

This lab runs against **uFawkesDevX** — the Developer Experience plane — because it provides a complete deployment workflow in Docker Compose:

- **Golden-path templates** (Cookiecutter) create services
- **Score Service** validates workload specs and records pipeline triggers
- **uFawkesPipe (Woodpecker)** runs the real CI/CD in its own stack: lint → test → build → push
- **No Kubernetes required** — runs on your laptop

This demonstrates the full deployment workflow without cluster complexity.

---

## Prerequisites

**Required**: uFawkesDevX v1.2.0 running from Module 1

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
- `docker` — runs `yq` and the app's container

---

## Step 0 — Read the Theory First (if you haven't)

This lab assumes you've read the [Module 4 theory](../README.md#theory-summary-15-minutes)
up through "Golden Path Templates". You should be able to name the four stages
of the uFawkesDevX deployment workflow and identify the components.

---

## Step 1 — Scaffold the Service (3 minutes)

```bash
cd ~/dojo-labs/uFawkesDevX

cookiecutter templates/python-flask-app --no-input \
  project_name="My First App" \
  project_slug="my-first-app" \
  language="python" \
  registry_namespace="dojo"

cd my-first-app
```

### Examine the key files

```bash
cat score.yaml                       # Score workload spec: declarative desired state
cat .fawkespipe.yml                  # uFawkesPipe CI/CD contract
cat .devcontainer/devcontainer.json  # Coder devcontainer definition
cat Dockerfile                       # Container build
cat src/app.py                       # Application code
cat tests/test_app.py                # Tests
head -30 README.md
```

**Key observations**:
- `score.yaml` declares the workload (containers, variables, service ports)
- `.fawkespipe.yml` defines `lint` and `test` stages, then a Cloud Native Buildpacks build (`paketobuildpacks/builder-jammy-base`) pushing to `ghcr.io/dojo/my-first-app`
- `src/app.py` serves `/` and `/health`

---

## Step 2 — Submit the Score Spec and Trigger the Pipeline (5 minutes)

### 2.1 Submit the spec

The Score API takes JSON, and a plugin rejects specs without
`metadata.annotations`, so convert `score.yaml` and add one on the way:

```bash
docker run --rm -i mikefarah/yq:4 -o=json '.metadata.annotations."dojo/lab" = "white-belt-04"' < score.yaml \
  | curl -s -X POST http://localhost:8000/api/score/specs \
      -H "Content-Type: application/json" -d @- | jq '{name, version, status}'
```

**Expected response**: `{"name": "my-first-app", "version": 1, "status": "validated"}`

### 2.2 Trigger the pipeline webhook

The Score service exposes a webhook the platform calls when a workload changes.
Call it yourself:

```bash
curl -s -X POST http://localhost:8000/webhooks/score/pipeline/trigger \
  -H "Content-Type: application/json" \
  -d '{"workload":"my-first-app","action":"deploy"}' | jq .
```

**Expected response**: HTTP 202 with `"message": "Pipeline triggered"` and a `pipelineRun` whose `status` is `running`.

### 2.3 Read the pipeline run

```bash
sleep 6
curl -s http://localhost:8000/api/score/pipelines/my-first-app | jq '.pipelines[] | {id, workload, action, status}'
```

**Expected output**: your run, `status` now `completed`.

> **What this is, and is not**: the Score service records the run and marks it
> completed after a few seconds. It does not build anything. The real pipeline
> (lint → test → build → push, as `.fawkespipe.yml` describes) runs in
> uFawkesPipe's Woodpecker, a separate stack you set up in Yellow Belt.

> ✅ **Checkpoint**: `my-first-app` is registered and has a recorded pipeline run.

---

## Step 3 — Run the App and Its Tests (5 minutes)

You'll do by hand what the pipeline's `test` stage and a workspace would do,
in a throwaway Python container.

### 3.1 Run the tests

```bash
cd ~/dojo-labs/uFawkesDevX/my-first-app
docker run --rm -v "$PWD":/app -w /app python:3.12-slim sh -c \
  'pip install -q -r requirements.txt pytest && python -m pytest -q'
```

**Expected output**: `2 passed`

### 3.2 Run the app and check its health

```bash
docker run -d --rm --name my-first-app -v "$PWD":/app -w /app -p 8090:8080 python:3.12-slim sh -c \
  'pip install -q -r requirements.txt && python src/app.py'

sleep 12
curl -s http://localhost:8090/health
```

**Expected response**: `{"status":"ok"}`

(Port 8090 avoids clashing with anything on 8080. The app listens on `PORT`, default 8080, inside the container.)

```bash
docker rm -f my-first-app
```

> ✅ **Checkpoint**: The app passes its tests and answers `/health`.
> The full workflow: Template → Spec → Pipeline trigger → Running app.

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

[✓] Prerequisites: docker, docker compose, git, curl, jq, cookiecutter installed
[✓] uFawkesDevX Stack: all 5 services healthy (coder, backstage, score-service, plugin-manager, gateway)
[✓] Backstage Catalog: systems: developer-control-plane ufawkes-obs ufawkes-pipe ufawkes-sec
[✓] Scaffolded Service: my-first-app has score.yaml and .fawkespipe.yml
[✓] Score Spec Submit: my-first-app is registered (version 1)
[✓] Pipeline Trigger: my-first-app has 1 recorded pipeline run(s)

==========================================
Total Tests : 6
Passed      : 6
Failed      : 0

[✓] All tests passed! ✅

🎉 Congratulations! You've completed White Belt Module 4 Lab 01.
   You've taken your first app from template to a registered, tested service.
   You're ready for the White Belt Assessment!
```

---

## Clean Up

When you are done with the lab:

```bash
# Remove the spec from the Score service (optional)
curl -s -X DELETE http://localhost:8000/api/score/specs/my-first-app

# Remove the scaffolded service (optional)
rm -rf ~/dojo-labs/uFawkesDevX/my-first-app
```

---

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| Score API returns 400 `Invalid Score specification` | Body fails the schema, or isn't JSON | Post through the `yq` pipe in Step 2.1; read `details` |
| Score API returns 400 `Plugin example-validator validation failed` | No `metadata.annotations` | Add the annotation as in Step 2.1 |
| `pipelines` list is empty | Trigger not sent, or wrong workload name | Redo Step 2.2 with `"workload":"my-first-app"` |
| `curl: (7)` on port 8090 | The app is still installing Flask | Wait 10 more seconds; `docker logs my-first-app` |
| `docker: port is already allocated` on 8090 | Another service holds it | Change the left side of `-p 8090:8080` |

---

## Retrieval Check (Answer Without Looking Back)

Write your answers down — the act of writing (not just thinking) strengthens retention.

1. What are the stages of the workflow you ran in this lab?
2. Which component validates the `score.yaml` and triggers the pipeline?
3. What does the `.fawkespipe.yml` file define?
4. Which file tells Coder how to build the workspace container?
5. Does the Score service build your image? What does?

(Suggested answers: 1 = template → Score spec → pipeline trigger → running app; 2 = Score Service; 3 = uFawkesPipe CI/CD contract (lint, test, build); 4 = .devcontainer/devcontainer.json; 5 = no, it only records the trigger; uFawkesPipe's Woodpecker builds)

---

## Reference: What You Built

| File | Purpose |
|------|---------|
| `score.yaml` | Score workload spec (declarative desired state) |
| `.fawkespipe.yml` | uFawkesPipe CI/CD contract |
| `.devcontainer/devcontainer.json` | Coder workspace definition (not exercised in this lab) |
| `Dockerfile` | CNB-based container build |
| `src/app.py` | Flask app with `/health` endpoint |
| `tests/test_app.py` | Pytest suite |
| `README.md` | TechDocs source |

You've now experienced the uFawkesDevX workflow from template to a registered, tested, running application. In Yellow Belt you'll run the real pipeline in uFawkesPipe.

---

➡️ **Next**: Return to [Module 4 README](../README.md), then prepare for the **White Belt Assessment**!
