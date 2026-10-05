# Lab 01: Scaffold a Service Using the uFawkesDevX Golden Path Template

**Module**: White Belt — Module 1: What is an Internal Delivery Platform?
**Estimated Time**: 20 minutes
**Difficulty**: Beginner (basic Docker and command line knowledge required)
**Runs against**: [uFawkesDevX v1.0.1](https://github.com/paruff/uFawkesDevX/releases/tag/v1.0.1) (Docker Compose)

---

## Objectives

By the end of this lab you will have:

1. Started the uFawkesDevX platform locally with a self-contained PostgreSQL
2. Explored the Backstage catalog and its pre-populated uFawkes plane components
3. Scaffolded a new service (`hello-devx`) using the Cookiecutter golden path template
4. Registered the service in the Backstage catalog via the Score service API
5. Verified the service appears in Backstage with its TechDocs

---

## Why This Lab Uses uFawkesDevX

This lab runs against **uFawkesDevX** — the Developer Experience plane of the uFawkes
suite — because it provides a complete, working IDP in Docker Compose with no
Kubernetes cluster required. You get:

- **Backstage** developer portal with service catalog and scaffolding
- **Coder** cloud IDE for ephemeral devcontainer workspaces
- **Score Service** for workload specification validation and pipeline triggering
- **Golden Path Templates** (Cookiecutter) that scaffold production-ready services

This is the same platform the uFawkes suite uses internally, just at a scale
that runs on your laptop.

---

## Prerequisites

**Tools required** (install before starting):

- `docker` and `docker compose` (v2+) — [Docker Desktop](https://www.docker.com/products/docker-desktop/) includes both
- `git` — version control
- `curl` — HTTP client
- `python3` and `pip` — for Cookiecutter
- `cookiecutter` — `pip install cookiecutter`

**Verify prerequisites**:

```bash
docker --version
docker compose version
git --version
curl --version
python3 --version
cookiecutter --version
```

---

## Step 0 — Read the Theory First (if you haven't)

This lab assumes you've read the [Module 1 theory](../README.md#theory-summary-15-minutes)
up through "uFawkesDevX Platform Architecture". You should be able to name the
three characteristics of an IDP and identify the uFawkesDevX components before starting.

---

## Step 1 — Clone uFawkesDevX and Prepare Environment (5 minutes)

Clone the pinned v1.0.1 release (never `main`) and set up the required PostgreSQL
database and Docker network.

```bash
# Work in a temporary directory separate from your uFawkesDojo checkout
mkdir -p ~/dojo-labs && cd ~/dojo-labs

# Clone uFawkesDevX at the pinned version this lab runs against
git clone --branch v1.0.1 https://github.com/paruff/uFawkesDevX.git
cd uFawkesDevX

# Create the shared Docker network
make network
```

### Start a Local PostgreSQL Container

uFawkesDevX v1.0.1 requires an external PostgreSQL reachable as `postgres:5432`
on the `fawkes-net` network. Since uFawkesRes (the former shared resource plane)
is deprecated, we'll run a temporary Postgres container for this lab.

```bash
# Start PostgreSQL on fawkes-net with required databases
docker run -d \
  --name dojo-postgres \
  --network fawkes-net \
  --network-alias postgres \
  -e POSTGRES_PASSWORD=changeme \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_DB=postgres \
  postgres:16-alpine

# Wait for Postgres to be ready, then create the three databases uFawkesDevX needs
sleep 5
docker exec -i dojo-postgres psql -U postgres <<'SQL'
CREATE DATABASE coder;
CREATE USER coder WITH PASSWORD 'changeme';
GRANT ALL PRIVILEGES ON DATABASE coder TO coder;

CREATE DATABASE backstage;
CREATE USER backstage WITH PASSWORD 'changeme';
GRANT ALL PRIVILEGES ON DATABASE backstage TO backstage;

CREATE DATABASE score;
CREATE USER score WITH PASSWORD 'changeme';
GRANT ALL PRIVILEGES ON DATABASE score TO score;
SQL

echo "PostgreSQL ready with coder, backstage, and score databases"
```

### Configure `.env` for uFawkesDevX

```bash
# Copy the example env file
cp .env.example .env

# Find your Docker socket GID (needed for Coder to manage workspace containers)
make check-gid
# Example output: "Your Docker GID is: 999"
# Copy that number and set it in .env as DOCKER_GID=999

# Set CODER_ACCESS_URL to a LAN-reachable address (NOT localhost)
# Workspace containers need to dial back to the Coder server
# Linux: ip route get 1 | awk '{print $7; exit}'
# macOS: ipconfig getifaddr en0
# Then: CODER_ACCESS_URL=http://<your-lan-ip>:7080

# Set database passwords to match what we created above
# BACKSTAGE_DB_PASSWORD=changeme
# CODER_DB_PASSWORD=changeme
# POSTGRES_PASSWORD=changeme
# POSTGRES_USER=postgres
```

**Edit `.env` now** with your values. Required variables:

| Variable | Value | Notes |
|----------|-------|-------|
| `DOCKER_GID` | Output from `make check-gid` | e.g., `999` |
| `CODER_ACCESS_URL` | `http://<your-lan-ip>:7080` | **Not localhost** |
| `POSTGRES_USER` | `postgres` | |
| `POSTGRES_PASSWORD` | `changeme` | |
| `BACKSTAGE_DB_PASSWORD` | `changeme` | |
| `CODER_DB_PASSWORD` | `changeme` | |

> ⚠️ **Critical**: `CODER_ACCESS_URL` must be a LAN IP (e.g., `192.168.1.42`), not `localhost` or `127.0.0.1`. Workspace agents run in separate containers and need to dial back to the Coder server. `localhost` inside a container resolves to itself, not the host.

---

## Step 2 — Build and Start uFawkesDevX (5 minutes)

```bash
# Build images and start the stack
make build && make up
```

Wait for all services to report healthy:

```bash
make status
```

**Expected output** — all 5 services running:

```
NAME                       STATUS
developerd-coder           Up (healthy)
developerd-backstage       Up (healthy)
developerd-score           Up (healthy)
developerd-plugin-manager  Up (healthy)
developerd-gateway         Up (healthy)
```

If any service is not healthy, wait 30 seconds and re-run `make status`.
Check logs with `docker logs <container-name>` if stuck.

---

## Step 3 — Explore the Backstage Catalog (5 minutes)

Open Backstage in your browser: **http://localhost:7007**

### 3.1 Tour the Catalog (Worked Example)

1. Click **Catalog** in the left sidebar
2. You should see **5 systems** pre-populated:
   - **Developer Control Plane** (uFawkesDevX itself)
   - **uFawkesPipe** (CI/CD plane)
   - **uFawkesSec** (Security plane — merged into Pipe)
   - **uFawkesRes** (Resource plane — marked deprecated)
   - **uFawkesObs** (Observability plane)

3. Click on **Developer Control Plane** → **Components**
4. Find and click **score-service**
   - Notice the **APIs** tab showing `score-api` and `score-webhooks`
   - This is the service that validates Score workload specs

5. Click on **plugin-manager**
   - This manages platform extensions and plugins

6. Click on **uFawkesDevX** (the component)
   - This represents the DevX plane as a whole

> ✅ **Checkpoint**: You should be able to navigate to each system and component
> in the catalog before moving on. This catalog is a **worked example** — it
> shows you what a populated Backstage catalog looks like before you add your
> own service.

---

## Step 4 — Scaffold a Golden Path Service (5 minutes)

Now you'll create your own service using the Cookiecutter golden path template.
This is the "first deployment" experience — going from zero to a registered,
observable service in minutes.

```bash
# From your uFawkesDevX checkout directory:
cd ~/dojo-labs/uFawkesDevX

# Scaffold a new Python Flask service
cookiecutter templates/python-flask-app --no-input \
  project_name="Hello DevX" \
  project_slug="hello-devx" \
  language="python" \
  registry_namespace="dojo"
```

**Expected output** — a new directory `hello-devx/` created with:

```
hello-devx/
├── .devcontainer/
│   └── devcontainer.json    # Pinned Python 3.12 devcontainer
├── src/
│   └── app.py               # Flask app with /health endpoint
├── tests/
│   └── test_app.py          # Basic pytest
├── .fawkespipe.yml          # uFawkesPipe CI/CD contract
├── score.yaml               # Score workload spec (score.dev/v1b1)
├── Dockerfile               # Container build
├── requirements.txt         # Python deps
└── README.md
```

### Examine the Generated Files

```bash
# Look at the Score spec — this is what the Score service validates
cat hello-devx/score.yaml

# Look at the CI/CD contract
cat hello-devx/.fawkespipe.yml

# Look at the devcontainer — this is what Coder will use
cat hello-devx/.devcontainer/devcontainer.json
```

> **Key insight**: The golden path template gives you a **complete, production-ready
> starting point** — devcontainer for Coder, Score spec for the platform, CI/CD
> contract for uFawkesPipe, Dockerfile, tests, and README. All in one command.

---

## Step 5 — Register the Service in Backstage (5 minutes)

You have two options to register the service. We'll use the Score service API
since that's the platform's intended workflow.

### 5.1 Push to a Git Repository (Required for Score Service)

The Score service expects a Git repository. For this lab, we'll initialize a
local Git repo and push to a temporary GitHub repo (or use a local file:// URL
if you prefer).

**Option A: Quick local Git repo (simplest for lab)**

```bash
cd ~/dojo-labs/uFawkesDevX/hello-devx

# Initialize Git repo
git init
git add .
git commit -m "Initial commit: hello-devx golden path scaffold"

# Create a bare repo to act as "remote"
cd ..
git clone --bare hello-devx hello-devx.git
cd hello-devx
git remote add origin ../hello-devx.git
git push -u origin main
```

**Option B: Push to GitHub (if you have a GitHub account)**

```bash
# Create a new repo on GitHub named "hello-devx", then:
cd ~/dojo-labs/uFawkesDevX/hello-devx
git init
git add .
git commit -m "Initial commit: hello-devx golden path scaffold"
git branch -M main
git remote add origin https://github.com/<your-username>/hello-devx.git
git push -u origin main
```

### 5.2 Register via Score Service API

The Score service validates the `score.yaml` and registers the workload.

```bash
# From the hello-devx directory
cd ~/dojo-labs/uFawkesDevX/hello-devx

# Submit the Score spec to the Score service
curl -s -X POST http://localhost:8000/api/score/specs \
  -H "Content-Type: application/json" \
  -d @score.yaml | jq .
```

**Expected response**: JSON with the validated spec and a `spec_id`.

> **What just happened**: The Score service (via the API Gateway at port 8000)
> validated your `score.yaml` against the `score.dev/v1b1` schema, stored it,
> and returned a spec ID. In a real platform, this would also trigger the
> uFawkesPipe pipeline via the webhook.

### 5.3 Verify in Backstage

1. Refresh the Backstage Catalog page (or wait ~30 seconds for auto-refresh)
2. Search for `hello-devx` in the catalog search bar
3. Click on the `hello-devx` component
4. You should see:
   - **Overview** tab with description
   - **APIs** tab (if Score spec registered APIs)
   - **TechDocs** tab (README rendered as documentation)

> ✅ **Checkpoint**: Your `hello-devx` service appears in the Backstage catalog
> with its TechDocs rendered. This is the "first deployment" — from template
> to cataloged service in under 5 minutes.

---

## Step 6 — Push the Coder Template (Optional but Recommended)

To complete the developer experience loop, push the devcontainer template
to Coder so developers can open workspaces instantly.

```bash
# From uFawkesDevX root
cd ~/dojo-labs/uFawkesDevX

# Push the devcontainer-docker template to Coder
make coder-push-template
```

Then in Coder UI (`CODER_ACCESS_URL`):
1. Click **New workspace**
2. Select **devcontainer-docker** template
3. Enter your `hello-devx` Git repo URL
4. Launch — you'll be in a devcontainer with Python 3.12, pre-installed deps,
   and the Flask app ready to run

---

## Step 7 — Run the Validation Script

The validation script checks all completion criteria automatically:

```bash
# From your uFawkesDojo checkout (not uFawkesDevX)
cd /path/to/uFawkesDojo
bash white-belt/module-01-what-is-idp/lab-01/validate.sh
```

**Expected output** (all checks pass):

```
[INFO] Starting White Belt Module 01 Lab 01 validation...

[✓] Prerequisites: docker, docker compose, git, curl, cookiecutter installed
[✓] PostgreSQL: dojo-postgres container running with coder, backstage, score databases
[✓] Network: fawkes-net exists
[✓] uFawkesDevX Stack: all 5 services healthy (coder, backstage, score-service, plugin-manager, gateway)
[✓] Backstage Catalog: API reachable at http://localhost:7007
[✓] Score Service: API reachable at http://localhost:8000/api/score
[✓] Coder: API reachable at CODER_ACCESS_URL
[✓] Scaffolded Service: hello-devx registered in Backstage catalog

==========================================
Total Tests: 9
Passed: 9
Failed: 0

[✓] All tests passed! ✅

🎉 Congratulations! You have completed White Belt Module 1 Lab 01.
   Your service is scaffolded, validated, and cataloged.
   Move on to Module 02: DORA Metrics.
```

---

## Clean Up

When you are done with the lab, remove the resources:

```bash
# Stop uFawkesDevX
cd ~/dojo-labs/uFawkesDevX
make down

# Stop and remove PostgreSQL
docker stop dojo-postgres && docker rm dojo-postgres

# Remove the Docker network
docker network rm fawkes-net

# Optional: remove the lab directory
rm -rf ~/dojo-labs
```

---

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| `docker: command not found` | Docker not installed | Install Docker Desktop |
| `make network` fails: network exists | Previous lab didn't clean up | `docker network rm fawkes-net && make network` |
| Postgres connection refused | Postgres not ready | Wait 10s, check `docker logs dojo-postgres` |
| Coder stuck on "Connecting..." | `CODER_ACCESS_URL` is `localhost` | Set to LAN IP in `.env`, run `make up` again |
| Backstage crash-loops | Database not created | Verify `coder`, `backstage`, `score` DBs exist in Postgres |
| `cookiecutter: command not found` | Cookiecutter not installed | `pip install cookiecutter` |
| Score service returns 422 | `score.yaml` invalid | Check `cat score.yaml` for syntax errors |
| Service not in Backstage catalog | Registration failed or catalog not refreshed | Check Score service logs, refresh Backstage catalog |
| `make check-gid` fails | Docker not running | Start Docker Desktop |

---

## Reference: What You Built

```
hello-devx/
├── .devcontainer/devcontainer.json   → Coder workspace definition
├── score.yaml                        → Score workload spec (validated by Score service)
├── .fawkespipe.yml                   → uFawkesPipe CI/CD contract
├── Dockerfile                        → Container image build
├── src/app.py                        → Flask app with /health endpoint
├── tests/test_app.py                 → Pytest suite
├── requirements.txt                  → Python dependencies
└── README.md                         → TechDocs source
```

Study these files to understand the uFawkesDevX golden path pattern. In later
modules you'll create your own templates and extend the platform.

---

## Retrieval Check (Answer Without Looking Back)

Write your answers down — the act of writing (not just thinking) strengthens retention.

1. What three databases must exist in PostgreSQL for uFawkesDevX to start?
2. Why must `CODER_ACCESS_URL` be a LAN IP, not `localhost`?
3. What does the Score service do with the `score.yaml` you POST to it?
4. Name two uFawkes planes that appear as Systems in the Backstage catalog.
5. What file tells Coder how to build the devcontainer workspace?

(Suggested answers: 1 = coder, backstage, score; 2 = workspace containers resolve localhost to themselves; 3 = validates against score.dev/v1b1 schema, stores spec, triggers pipeline webhook; 4 = uFawkesPipe, uFawkesObs, uFawkesSec, uFawkesRes; 5 = .devcontainer/devcontainer.json)

---

➡️ **Next**: Return to [Module 1 README](../README.md), then continue to **Module 02: DORA Metrics**.
