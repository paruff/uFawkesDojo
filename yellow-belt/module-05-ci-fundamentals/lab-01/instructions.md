# Lab 01: Your First Pipeline with uFawkesPipe

**Module**: Yellow Belt — Module 5: CI Fundamentals
**Estimated Time**: about 45 minutes (an estimate, not timed; the first run pulls container images)
**Difficulty**: Intermediate (White Belt complete required)
**Runs against**: uFawkesPipe v2.0.0 and uFawkesDevX v1.0.1 (Docker Compose)

> **Last run for real**: 2026-11-20, every step below, against uFawkesPipe v2.0.0 (Woodpecker 3.20.1) and uFawkesDevX v1.0.1. Where the platform behaves differently from what you might expect, the step says so.

---

## Objectives

By the end of this lab you will have:

1. Started the uFawkesPipe Woodpecker stack and signed in with GitHub
2. Scaffolded a Python Flask app and edited its `.fawkespipe.yml` pipeline contract
3. Generated a `.woodpecker.yml` from the contract, pushed it to GitHub and activated the repo
4. Watched a pipeline run `lint`, `test` and a Trivy `dependency-scan`
5. Read the scan step's output
6. Broken a test, watched the pipeline fail, and fixed it

---

## Prerequisites

**Tools**: `docker` (with Compose), `curl`, `jq`, `git`, `gh` (logged in), `cookiecutter` (`pip install cookiecutter`).

**A GitHub OAuth App** (Woodpecker signs you in with it). At github.com/settings/developers → OAuth Apps → New OAuth App:

- Homepage URL: `http://localhost:8000`
- Authorization callback URL: `http://localhost:8000/authorize`

If port 8000 is taken on your machine (a Docker container or an `ssh` tunnel often holds it), pick another port, say 8001, and use it everywhere below, including both URLs above and `WOODPECKER_UI_PORT`/`WOODPECKER_HOST` in `.env`.

**Checkouts** (clone the tags this lab was run against):

```bash
mkdir -p ~/dojo-labs && cd ~/dojo-labs
git clone --branch v2.0.0 --depth 1 https://github.com/paruff/uFawkesPipe.git
git clone --branch v1.0.1 --depth 1 https://github.com/paruff/uFawkesDevX.git
```

**Configure and start uFawkesPipe**:

```bash
cd ~/dojo-labs/uFawkesPipe
cp .env.example .env
# Edit .env:
#   WOODPECKER_GITHUB_CLIENT / WOODPECKER_GITHUB_SECRET  from your OAuth App
#   WOODPECKER_AGENT_SECRET                              openssl rand -hex 32
#   WOODPECKER_HOST and WOODPECKER_UI_PORT               only if you changed the port
#   WOODPECKER_EXPERT_WEBHOOK_HOST=https://woodpecker-lab.example.com
docker compose -f compose.yaml up -d woodpecker-server woodpecker-agent
```

Two things to know about that last `.env` line and the start command:

- **Webhooks.** GitHub refuses to create the webhook Woodpecker needs when its URL is `localhost` or empty (`422 ... url is missing a scheme` / `isn't reachable over the public Internet`). The stack leaves `WOODPECKER_EXPERT_WEBHOOK_HOST` empty, so activating a repo fails until you set it. A placeholder public URL, as above, lets activation succeed; GitHub's webhook deliveries then fail, which this lab does not need because you start builds yourself through the API. For push-triggered builds, put a real tunnel URL there instead.
- **Only two services are needed.** The scaffolded pipeline uses just the Woodpecker server and agent. SonarQube, Portainer and Trivy server are optional here. `make up` starts all five.

**Never run `make down` to stop the stack.** It runs `docker compose down -v` and deletes the volumes, including your Woodpecker user and repo activations. Use `docker compose -f compose.yaml stop` instead.

**Sign in and get an API token**:

1. Open `http://localhost:8000` (or your port) and click **Sign in with github.com**.
2. Click your avatar → **User settings** → **Personal Access Token** and copy the whole string. It starts with `eyJ`.
3. Export it in your shell. Do not paste it into files or chat:

```bash
export WP=http://localhost:8000        # your Woodpecker URL
export WOODPECKER_TOKEN='eyJ...'       # the token you copied
curl -s -H "Authorization: Bearer $WOODPECKER_TOKEN" $WP/api/user | jq .login
```

**Expected**: your GitHub login. A `401` means the token is wrong or stale: **Reset token** logs you out, so sign in again and copy the new one.

---

## Step 0 — Read the Theory First (if you haven't)

This lab assumes you've read the [Module 5 theory](../README.md#theory-summary-20-minutes) up through "uFawkesPipe Architecture".

---

## Step 1 — Explore Woodpecker CI (3 minutes)

Open `$WP` in your browser. The **Repositories** list is empty until Step 3. To see what a mature pipeline looks like, read uFawkesPipe's own `.woodpecker.yml`:

```bash
grep -n '^  - name:\|^- name:' ~/dojo-labs/uFawkesPipe/.woodpecker.yml
```

It defines 16 steps, from `init`, `lint-yaml`, `lint-shell` and `validate-agents` through `unit-tests`, `integration-tests`, `contract-tests`, `secrets-scan`, `vuln-scan-fs`, `vuln-scan-image`, `policy-check`, `build-image`, `generate-sbom` and `sign-image`, to `upload-defectdojo` and `notify-obs`. Your app's generated pipeline is much smaller; you choose its stages in the contract.

> ✅ **Checkpoint**: you can name the kinds of steps a uFawkesPipe pipeline can contain.

---

## Step 2 — Scaffold the App and Edit Its Contract (8 minutes)

### 2.1 Scaffold

```bash
cd ~/dojo-labs/uFawkesDevX
cookiecutter templates/python-flask-app --no-input \
  project_name="My CI Lab App" \
  project_slug="my-ci-lab-app" \
  language="python" \
  registry_namespace="dojo"
cd my-ci-lab-app && ls -a
```

You get `.fawkespipe.yml`, `Dockerfile`, `requirements.txt`, `score.yaml`, `src/app.py` (with `/` and `/health` returning `{"status": "ok"}`), `tests/test_app.py` and `.devcontainer/`.

The generated `.fawkespipe.yml` enables only two stages, `lint` (`ruff check .`) and `test` (`pytest`). It generates no `.woodpecker.yml`.

### 2.2 Make the contract runnable

Both commands run in a bare `python:3.12-slim` image, where `ruff` and the app's dependencies are not installed, and a bare `pytest` cannot import `src`. Edit the two `cmd:` lines and add a scan stage so the contract reads:

```yaml
stages:
  lint:
    enabled: true
    commands:
      - language: python
        cmd: pip install -q ruff && ruff check .
  test:
    enabled: true
    commands:
      - language: python
        cmd: pip install -q -r requirements.txt pytest && python -m pytest
  dependency_scan:
    enabled: true
    tools:
      - trivy
```

(Leave the `app:`, `build:` and `image:` sections above `stages:` as generated.)

### 2.3 Generate the Woodpecker pipeline

```bash
cd ~/dojo-labs/uFawkesPipe
make generate-pipeline \
  FILE=$HOME/dojo-labs/uFawkesDevX/my-ci-lab-app/.fawkespipe.yml \
  OUTPUT=$HOME/dojo-labs/uFawkesDevX/my-ci-lab-app/.woodpecker.yml
cat $HOME/dojo-labs/uFawkesDevX/my-ci-lab-app/.woodpecker.yml
```

**Expected**: three steps, `lint`, `test` (after `lint`) and `dependency-scan` (image `aquasec/trivy`).

> ✅ **Checkpoint**: the app has a runnable `.fawkespipe.yml` and a generated `.woodpecker.yml`.

---

## Step 3 — Push to GitHub and Activate in Woodpecker (5 minutes)

Woodpecker here uses GitHub as its forge, so the repo must be on GitHub. A local bare repo will not work.

```bash
cd ~/dojo-labs/uFawkesDevX/my-ci-lab-app
git init -b main
git add . && git commit -m "Initial commit: scaffolded Python Flask app"
gh repo create my-ci-lab-app --private --source=. --remote=origin --push
```

Activate it (the API call is the same thing the UI's **Add Repository** button does):

```bash
RID=$(gh api repos/$(gh api user --jq .login)/my-ci-lab-app --jq .id)
curl -s -X POST -H "Authorization: Bearer $WOODPECKER_TOKEN" "$WP/api/repos?forge_remote_id=$RID" | jq '{id, full_name, active}'
```

Then look up Woodpecker's own id for the repo (it differs from GitHub's) for the API calls below:

```bash
WPID=$(curl -s -H "Authorization: Bearer $WOODPECKER_TOKEN" "$WP/api/repos/lookup/$(gh api user --jq .login)/my-ci-lab-app" | jq .id)
echo $WPID
```

**Expected**: `active: true` and a repo `id` (1 on a fresh stack). A `500 could not create webhook in forge` means `WOODPECKER_EXPERT_WEBHOOK_HOST` is empty or `localhost`; fix `.env` and recreate the server (`docker compose -f compose.yaml up -d woodpecker-server`, then `docker compose -f compose.yaml restart woodpecker-agent`; the agent loses its connection when the server is recreated).

> ✅ **Checkpoint**: the repo shows as active in the Woodpecker UI.

---

## Step 4 — Run Your First Pipeline (5 minutes)

Start a run on `main` and open it in the UI:

```bash
curl -s -X POST -H "Authorization: Bearer $WOODPECKER_TOKEN" -H 'Content-Type: application/json' \
  -d '{"branch":"main"}' "$WP/api/repos/$WPID/pipelines" | jq '{number, status}'
```

In the UI open the repo → the run, and click each step for its log. Steps: `clone`, `lint`, `dependency-scan`, `test`. The first run pulls the Python and Trivy images and downloads Trivy's vulnerability database, so it takes a few minutes; later runs are faster.

> ✅ **Checkpoint**: the run finishes green (`success`).

---

## Step 5 — Read the Scan Result (2 minutes)

Click the **dependency-scan** step. Trivy scans the repo's files (`requirements.txt`) for known vulnerabilities in dependencies and fails the step on any finding (`--exit-code 1`). The JSON report is written to `artifacts/security/trivy-repo.json` inside the build workspace; it is not kept after the run.

Gitleaks (secrets), SonarQube (SAST) and image scanning are not part of this scaffold's pipeline. They appear in uFawkesPipe's own pipeline (Step 1) and in [Module 7: Security Scanning](../../module-07-security-scanning/README.md).

> ✅ **Checkpoint**: you can find the Trivy step and say what makes it fail.

---

## Step 6 — Practice Failure & Recovery (5 minutes)

### 6.1 Break a test

Make the test expect a status the app never returns:

```bash
cd ~/dojo-labs/uFawkesDevX/my-ci-lab-app
sed -i.bak 's/{"status": "ok"}/{"status": "healthy"}/' tests/test_app.py && rm tests/test_app.py.bak
git add tests/test_app.py && git commit -m "test: expect a status the app does not return" && git push origin main
curl -s -X POST -H "Authorization: Bearer $WOODPECKER_TOKEN" -H 'Content-Type: application/json' \
  -d '{"branch":"main"}' "$WP/api/repos/$WPID/pipelines" | jq .number
```

### 6.2 Watch it fail

The run ends `failure` in the **test** step, with `lint` green. Open the step log:

```
FAILED tests/test_app.py::test_health_returns_ok - AssertionError: assert {'status': 'ok'} == {'status': 'healthy'}
```

> Don't "break" it with `assert 1 == 2` or an unused `import pytest`. The `lint` step runs first and ruff rejects both, so the pipeline fails at `lint` and the test never runs.

### 6.3 Fix and recover

```bash
git revert --no-edit HEAD && git push origin main
curl -s -X POST -H "Authorization: Bearer $WOODPECKER_TOKEN" -H 'Content-Type: application/json' \
  -d '{"branch":"main"}' "$WP/api/repos/$WPID/pipelines" | jq .number
```

**Expected**: the new run is green.

> ✅ **Checkpoint**: you've seen a red run and a green run for the same repo, the core CI feedback loop.

---

## Step 7 — Run the Validation Script

```bash
cd /path/to/uFawkesDojo
WOODPECKER_URL=$WP bash yellow-belt/module-05-ci-fundamentals/lab-01/validate.sh
```

It reads `WOODPECKER_TOKEN` from your shell. **Expected**: 7 checks, all `[✓]`: prerequisites, stack running, API token accepted, repo activated, a successful run, a passing `dependency-scan` step, and a failed run followed by a successful one.

---

## Clean Up

```bash
# Stop the stack, keeping its data (do NOT use make down: it deletes volumes)
cd ~/dojo-labs/uFawkesPipe && docker compose -f compose.yaml stop

# Delete the lab repo from GitHub (needs the delete_repo scope, or use the repo's Settings page)
gh repo delete my-ci-lab-app --yes
rm -rf ~/dojo-labs/uFawkesDevX/my-ci-lab-app
```

---

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| `/api/user` returns 401 | Token stale, mistyped, or copied before a **Reset token** | Sign in again, copy the current token, `export` it again |
| `500 could not create webhook in forge` | `WOODPECKER_EXPERT_WEBHOOK_HOST` empty or `localhost` | Set a public URL in `.env`, recreate the server, restart the agent |
| Run stays `pending`/`running`, agent logs `queue: task expired` or `grpc ... Unavailable` | Agent lost its connection to the server | `docker compose -f compose.yaml restart woodpecker-agent`, then start a new run |
| `lint` fails: `ruff: not found` | Contract has no install step | Use the Step 2.2 commands |
| `test` fails: `No module named 'src'` | Bare `pytest` does not add the repo root to the import path | Use `python -m pytest` |
| Port 8000 already allocated | Another container or `ssh` tunnel holds it | Set `WOODPECKER_UI_PORT`/`WOODPECKER_HOST` in `.env` and use that port in the OAuth App |
| Woodpecker data and login vanished | `make down` ran `down -v` | Sign in again and re-activate; stop with `docker compose ... stop` in future |
| Docker commands hang on Colima | Daemon stalled under load | `colima restart`, then bring up only the server and agent |

---

## Retrieval Check (Answer Without Looking Back)

Write your answers down — the act of writing (not just thinking) strengthens retention.

1. What file defines the pipeline contract for an application?
2. Which command turns the contract into a Woodpecker pipeline?
3. Which step fails a build when a dependency has a known vulnerability?
4. Why does a lint failure hide a test failure?
5. How does uFawkesPipe build container images by default?

---

## Retrieval Check Answers

1. `.fawkespipe.yml`
2. `make generate-pipeline` in uFawkesPipe (it writes `.woodpecker.yml`)
3. `dependency-scan` (Trivy, `--exit-code 1`)
4. `test` depends on `lint`, so when `lint` fails the `test` step is skipped
5. Cloud Native Buildpacks (the `build:` section of the contract; this lab does not enable the build stage)

---

## Reference: What You Built

| File | Purpose |
|------|---------|
| `.fawkespipe.yml` | Pipeline contract (lint, test, dependency scan) |
| `.woodpecker.yml` | Generated Woodpecker pipeline; regenerate it after editing the contract |
| `src/app.py` | Flask app with `/` and `/health` |
| `tests/test_app.py` | Pytest suite |
| `Dockerfile`, `score.yaml` | Present in the scaffold; not used by this lab's pipeline |

➡️ **Next**: Return to [Module 5 README](../README.md), then continue to **Module 06: Golden Path Pipelines**.
