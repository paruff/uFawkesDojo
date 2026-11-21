# Lab 01: Scaffold a Service Using the uFawkesDevX Golden Path Template

**Module**: White Belt — Module 1: What is an Internal Delivery Platform?
**Estimated Time**: 20 minutes
**Difficulty**: Beginner (basic Docker and command line knowledge required)
**Runs against**: [uFawkesDevX v1.2.0](https://github.com/paruff/uFawkesDevX/releases/tag/v1.2.0) (Docker Compose)

> **Run for real on 2026-11-21** against uFawkesDevX v1.2.0, Steps 1–5 and 7, on macOS with Colima and Docker. Step 6 (Coder template push) was not run: it needs the `coder` CLI, which this run did not have. The Coder server itself came up healthy.

---

## Objectives

By the end of this lab you will have:

1. Started the uFawkesDevX platform locally (no database to set up)
2. Explored the Backstage catalog and its pre-populated uFawkes plane components
3. Scaffolded a new service (`hello-devx`) using the Cookiecutter golden path template
4. Registered the service with the Score service API
5. Checked the Score service holds your spec

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
- `jq` — JSON processor
- Node.js 22 or 24 — `make build` bundles the Backstage backend on your machine first (Node 26 is not supported). If you don't have it, see the container alternative in Step 2
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
jq --version
node --version
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

Clone the pinned v1.2.0 release (never `main`). v1.2.0 needs no database of
your own: the Score service and Backstage keep SQLite files on Docker volumes,
and Coder runs its built-in Postgres.

```bash
# Work in a temporary directory separate from your uFawkesDojo checkout
mkdir -p ~/dojo-labs && cd ~/dojo-labs

# Clone uFawkesDevX at the pinned version this lab runs against
git clone --branch v1.2.0 https://github.com/paruff/uFawkesDevX.git
cd uFawkesDevX

# Create the shared Docker network
make network

# Copy the example env file
cp .env.example .env
```

### Configure `.env`

Two values need yours. Everything else keeps its default.

```bash
# Find the Docker socket's group ID as your containers see it (Coder needs it to manage
# workspace containers). This works on Linux, Docker Desktop and Colima.
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock alpine stat -c %g /var/run/docker.sock
# Example output: 991. Set that number in .env as DOCKER_GID=991

# Set CODER_ACCESS_URL to a LAN-reachable address (NOT localhost)
# Workspace containers need to dial back to the Coder server
# Linux: ip route get 1 | awk '{print $7; exit}'
# macOS: ipconfig getifaddr en0
# Then: CODER_ACCESS_URL=http://<your-lan-ip>:7080
```

| Variable | Value | Notes |
|----------|-------|-------|
| `DOCKER_GID` | Output of the `docker run ... stat` command above | e.g., `991` |
| `CODER_ACCESS_URL` | `http://<your-lan-ip>:7080` | **Not localhost** |

> ⚠️ **Critical**: `CODER_ACCESS_URL` must be a LAN IP (e.g., `192.168.1.42`), not `localhost` or `127.0.0.1`. Workspace agents run in separate containers and need to dial back to the Coder server. `localhost` inside a container resolves to itself, not the host.

> **Port 8000 busy?** The gateway publishes port 8000. If something else on your machine holds it, set `GATEWAY_PORT=8010` in `.env`, and use that port wherever this lab says `localhost:8000` (and `export GATEWAY_URL=http://localhost:8010` before Step 7).

---

## Step 2 — Build and Start uFawkesDevX (5 minutes)

```bash
# Build images and start the stack
make build && make up
```

`make build` first bundles the Backstage backend with Node 22 or 24. If your
Node is another version, build the bundle in a container instead, then run
`make build && make up` (it skips the bundle when one exists):

```bash
docker run --rm -v "$PWD/backstage:/w" -w /w node:24 sh -c \
  'node .yarn/releases/yarn-4.13.0.cjs install --immutable && node .yarn/releases/yarn-4.13.0.cjs tsc && node .yarn/releases/yarn-4.13.0.cjs build:backend'
```

The first build takes several minutes.

Wait for all services to report healthy:

```bash
make status
```

**Expected output** — all 5 services running and `(healthy)`:

```
NAME                        SERVICE          STATUS                    PORTS
developerd-backstage        backstage        Up 32 seconds (healthy)   0.0.0.0:7007->7007/tcp
developerd-coder            coder            Up 33 seconds (healthy)   0.0.0.0:7080->7080/tcp
developerd-gateway          gateway          Up 30 seconds (healthy)   0.0.0.0:8000->8000/tcp
developerd-plugin-manager   plugin-manager   Up 32 seconds (healthy)   0.0.0.0:8083->8083/tcp
developerd-score            score-service    Up 31 seconds (healthy)   0.0.0.0:8081-8082->8081-8082/tcp
```

If any service is not healthy, wait 30 seconds and re-run `make status`.
Check logs with `docker logs <container-name>` if stuck.

---

## Step 3 — Explore the Backstage Catalog (5 minutes)

Open Backstage in your browser: **http://localhost:7007** and click **Enter** to sign in as a guest.

### 3.1 Tour the Catalog (Worked Example)

1. Click **Catalog** in the left sidebar
2. Set the **Kind** filter to **System**. You should see **4 systems** pre-populated:
   - **developer-control-plane** (uFawkesDevX itself)
   - **ufawkes-pipe** (CI/CD plane)
   - **ufawkes-sec** (Security plane — merged into Pipe)
   - **ufawkes-obs** (Observability plane)

3. Set **Kind** to **Component**. You should see **3 components**: `plugin-manager`, `score-service`, `ufawkes-devx`
4. Click **score-service**
   - Notice the **APIs** tab showing `score-api`
   - This is the service that validates Score workload specs

5. Click on **plugin-manager**
   - This manages platform extensions and plugins

6. Click on **ufawkes-devx** (the component)
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

# Initialize Git repo (-b main: your git's default branch may be master)
git init -b main
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

The Score service validates the spec and registers the workload. Its API takes
**JSON**, not YAML, and a plugin on the service rejects any spec without
`metadata.annotations`. So convert `score.yaml` to JSON and add one annotation
on the way (`yq` runs in a container, nothing to install):

```bash
# From the hello-devx directory
cd ~/dojo-labs/uFawkesDevX/hello-devx

docker run --rm -i mikefarah/yq:4 -o=json '.metadata.annotations."dojo/lab" = "white-belt-01"' < score.yaml \
  | curl -s -X POST http://localhost:8000/api/score/specs \
      -H "Content-Type: application/json" -d @- | jq .
```

**Expected response**: HTTP 201 with the stored record: `id`, `name` (`hello-devx`),
your `spec`, `version` (`1`) and `status` (`validated`). There is no `spec_id` field.

Try breaking it: post `{"bad":1}` the same way and the service answers **HTTP 400**
with `Invalid Score specification`.

> **What just happened**: The Score service (via the API Gateway at port 8000)
> validated your spec against the `score.dev/v1b1` schema, stored it, and
> returned the record. It also tries to notify uFawkesPipe; with
> `PIPELINE_WEBHOOK_URL` unset in `.env` it skips that call.

### 5.3 Verify the registration

```bash
curl -s http://localhost:8000/api/score/specs/hello-devx | jq '{name, version, status}'
```

**Expected output**: `{"name": "hello-devx", "version": 1, "status": "validated"}`

> ✅ **Checkpoint**: The Score service holds your `hello-devx` spec.
>
> The service does **not** appear in the Backstage catalog at v1.2.0. Backstage
> reads `catalog-info.yaml` files from registered locations, and the Score
> service doesn't write to it. The catalog you toured in Step 3 is the worked example.

---

## Step 6 — Push the Coder Template (Optional, not run for real)

> This step was not run for the v1.2.0 check: it needs the `coder` CLI installed
> and logged in (`coder login $CODER_ACCESS_URL`), and the template's
> `main.tf` has `# VERIFY` comments a person must review first (see
> `docs/coder-guide.md` in uFawkesDevX). Treat it as a pointer, not a verified step.

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

[✓] Prerequisites: docker, docker compose, git, curl, jq, cookiecutter installed
[✓] Network: fawkes-net exists
[✓] uFawkesDevX Stack: all 5 services healthy (coder, backstage, score-service, plugin-manager, gateway)
[✓] Backstage Catalog: systems: developer-control-plane ufawkes-obs ufawkes-pipe ufawkes-sec
[✓] Gateway: reachable at http://localhost:8000
[✓] Coder: reachable at http://<your-lan-ip>:7080
[✓] Scaffolded Service: hello-devx has score.yaml and .fawkespipe.yml
[✓] Score registration: hello-devx is registered (version 1)

==========================================
Total Tests : 8
Passed      : 8
Failed      : 0

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
| `make build` fails in the Backstage bundle | Node isn't 22 or 24 | Use the `docker run ... node:24` command in Step 2 |
| `make up` fails: port is already allocated | Another service holds 7007, 7080 or 8000 | Stop it, or set `GATEWAY_PORT` in `.env` |
| Coder stuck on "Connecting..." | `CODER_ACCESS_URL` is `localhost` | Set to LAN IP in `.env`, run `make up` again |
| Backstage catalog calls return 401 | The API needs a token | `curl localhost:7007/api/auth/guest/refresh` returns a guest token; send it as `Authorization: Bearer` |
| `cookiecutter: command not found` | Cookiecutter not installed | `pip install cookiecutter` |
| Score service returns 400 `Invalid Score specification` | The body fails the `score.dev/v1b1` schema, or isn't JSON | Post JSON as in Step 5.2; check `details` in the response |
| Score service returns 400 `Plugin example-validator validation failed` | The spec has no `metadata.annotations` | Add an annotation, as in Step 5.2 |
| `make check-gid` fails with `No such file or directory` | Docker Desktop for Mac and Colima have no host `docker.sock` to read | Use the `docker run ... stat` command in Step 1 |

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

1. Which two services keep their data in SQLite on Docker volumes, and which one runs its own built-in Postgres?
2. Why must `CODER_ACCESS_URL` be a LAN IP, not `localhost`?
3. What does the Score service do with the `score.yaml` you POST to it?
4. Name two uFawkes planes that appear as Systems in the Backstage catalog.
5. What file tells Coder how to build the devcontainer workspace?

(Suggested answers: 1 = Score service and Backstage use SQLite, Coder runs built-in Postgres; 2 = workspace containers resolve localhost to themselves; 3 = validates against the score.dev/v1b1 schema, stores the spec, notifies the pipeline webhook if one is set; 4 = any two of ufawkes-pipe, ufawkes-obs, ufawkes-sec; 5 = .devcontainer/devcontainer.json)

---

➡️ **Next**: Return to [Module 1 README](../README.md), then continue to **Module 02: DORA Metrics**.
