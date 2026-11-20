# Lab 01: Build Your Golden Path Pipeline

**Module**: Yellow Belt — Module 6: Golden Path Pipelines
**Estimated Time**: about 30 minutes (an estimate, not timed; a first run pulls container images)
**Difficulty**: Intermediate (Module 5 complete required)
**Runs against**: uFawkesPipe v2.0.0 and uFawkesDevX v1.0.1 (Docker Compose)

> **Last run for real**: 2026-11-20, every step below, against uFawkesPipe v2.0.0 (Woodpecker 3.20.1) and uFawkesDevX v1.0.1. Where the platform behaves differently from what you might expect, the step says so.

---

## Objectives

By the end of this lab you will have:

1. Read the golden-path contracts of the `python-fawkes-path` and `java-fawkes-path` repos
2. Scaffolded a Python Flask app and written its `.fawkespipe.yml` contract
3. Generated a `.woodpecker.yml` from the contract, pushed it to GitHub and activated the repo
4. Run the pipeline and seen which steps run in parallel
5. Read per-step timings from the Woodpecker API and compared repeat runs

---

## Prerequisites

This lab continues [Module 5](../../module-05-ci-fundamentals/lab-01/instructions.md). Follow its **Prerequisites** section to set up the tools, the GitHub OAuth App, the `uFawkesPipe` and `uFawkesDevX` checkouts, `.env`, the stack, and your `WOODPECKER_TOKEN`. Two things from there matter here:

- Start only the two services this lab needs: `docker compose -f compose.yaml up -d woodpecker-server woodpecker-agent`.
- Never stop the stack with `make down` (it runs `down -v` and deletes your Woodpecker login and repo activations). Use `docker compose -f compose.yaml stop`.

Verify the stack and your token:

```bash
export WP=http://localhost:8000        # your Woodpecker URL (8001 if you moved the port)
export WOODPECKER_TOKEN='eyJ...'       # Personal Access Token from the Woodpecker UI
curl -s -H "Authorization: Bearer $WOODPECKER_TOKEN" $WP/api/user | jq .login
```

**Expected**: your GitHub login. A `401` means the token is wrong or stale.

---

## Step 0 — Read the Theory First (if you haven't)

This lab assumes you've read the [Module 6 theory](../README.md#theory-summary-20-minutes).

---

## Step 1 — Read the Golden Path Contracts (4 minutes)

The golden-path templates are example repos, each with a `.fawkespipe.yml` contract and the `.woodpecker.yml` generated from it:

- [`paruff/python-fawkes-path`](https://github.com/paruff/python-fawkes-path) (Python, FastAPI)
- [`paruff/java-fawkes-path`](https://github.com/paruff/java-fawkes-path) (Java, Spring Boot)

A JavaScript template is planned but does not exist yet.

```bash
cd ~/dojo-labs
git clone --depth 1 https://github.com/paruff/python-fawkes-path.git
git clone --depth 1 https://github.com/paruff/java-fawkes-path.git
for r in python java; do
  echo "== $r"
  sed -n '/^stages:/,$p' $r-fawkes-path/.fawkespipe.yml
  grep -E '^- name:' $r-fawkes-path/.woodpecker.yml
done
```

**What you'll see**:

- `python-fawkes-path` enables only `build` and `notify_obs`, so its generated pipeline has steps `build` and `notify-obs`.
- `java-fawkes-path` enables `test`, `dependency_scan`, `build` and `image_scan`, with `advanced.timeout: 20`. Its pipeline has steps `test`, `dependency-scan`, `build` and `image-scan`.

A contract names stages; `make generate-pipeline` turns each enabled stage into one Woodpecker step. The stage list is the golden path, so a team gets the same steps in the same order by copying a contract instead of writing pipeline YAML. For the full list of stages, read `STAGE_ORDER` in `uFawkesPipe/scripts/generate_woodpecker_yml.py`.

uFawkesPipe's `examples/` directory also has contracts for Python, Java, Node.js and Go (`.fawkespipe-python-flask.yml`, `.fawkespipe-java-maven.yml`, `.fawkespipe-nodejs-express.yml`, `.fawkespipe-go.yml`). They enable `sast`, `build`, `image_scan` and `push`, which need SonarQube and registry credentials this lab does not set up. They come back in [Module 7](../../module-07-security-scanning/README.md).

> ✅ **Checkpoint**: you can say which stages a contract enables and which steps they generate.

---

## Step 2 — Scaffold the App and Write Its Contract (6 minutes)

### 2.1 Scaffold

```bash
cd ~/dojo-labs/uFawkesDevX
cookiecutter templates/python-flask-app --no-input \
  project_name="My Golden Path App" \
  project_slug="my-golden-path-app" \
  language="python" \
  registry_namespace="dojo"
cd my-golden-path-app && ls -a
```

The generated `.fawkespipe.yml` enables only `lint` (`ruff check .`) and `test` (`pytest`). Both commands fail in a bare `python:3.12-slim` image: `ruff` and the app's dependencies are not installed, and a bare `pytest` cannot import `src`.

### 2.2 Write the contract

Replace everything from `stages:` down with this (keep the `app:`, `build:` and `image:` sections above it):

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

> **There is no `parallel`, `cache` or resource setting in the contract.** The generator reads `advanced.timeout` only to write a comment (Woodpecker CE has no per-pipeline timeout field; see `docs/KNOWN_LIMITATIONS.md` L-005 in uFawkesPipe), and ignores `advanced.parallel`. Parallelism comes from the step dependencies the generator writes, which Step 4 shows.

### 2.3 Generate the Woodpecker pipeline

```bash
cd ~/dojo-labs/uFawkesPipe
make generate-pipeline \
  FILE=$HOME/dojo-labs/uFawkesDevX/my-golden-path-app/.fawkespipe.yml \
  OUTPUT=$HOME/dojo-labs/uFawkesDevX/my-golden-path-app/.woodpecker.yml
cat $HOME/dojo-labs/uFawkesDevX/my-golden-path-app/.woodpecker.yml
```

**Expected**: three steps. `lint` and `dependency-scan` (image `aquasec/trivy`) have no `depends_on`; `test` has `depends_on: [lint]`.

> ✅ **Checkpoint**: the app has a runnable `.fawkespipe.yml` and a generated `.woodpecker.yml`.

---

## Step 3 — Push to GitHub and Activate in Woodpecker (5 minutes)

Woodpecker here uses GitHub as its forge, so the repo must be on GitHub.

```bash
cd ~/dojo-labs/uFawkesDevX/my-golden-path-app
git init -b main
git add . && git commit -m "Initial commit: scaffolded Python Flask app"
gh repo create my-golden-path-app --private --source=. --remote=origin --push
```

Activate it (the same call the UI's **Add Repository** button makes) and look up Woodpecker's own id for it:

```bash
RID=$(gh api repos/$(gh api user --jq .login)/my-golden-path-app --jq .id)
curl -s -X POST -H "Authorization: Bearer $WOODPECKER_TOKEN" "$WP/api/repos?forge_remote_id=$RID" | jq '{id, full_name, active}'
WPID=$(curl -s -H "Authorization: Bearer $WOODPECKER_TOKEN" "$WP/api/repos/lookup/$(gh api user --jq .login)/my-golden-path-app" | jq .id)
echo $WPID
```

**Expected**: `active: true` and a repo `id` (`2` if you kept Module 5's lab repo). A `500 could not create webhook in forge` means `WOODPECKER_EXPERT_WEBHOOK_HOST` in `.env` is empty or `localhost`; see Module 5's Prerequisites.

> ✅ **Checkpoint**: the repo shows as active in the Woodpecker UI.

---

## Step 4 — Run the Pipeline and See the Parallel Steps (6 minutes)

Start a run on `main`. Builds are started through the API because this lab's webhook URL is a placeholder:

```bash
curl -s -X POST -H "Authorization: Bearer $WOODPECKER_TOKEN" -H 'Content-Type: application/json' \
  -d '{"branch":"main"}' "$WP/api/repos/$WPID/pipelines" | jq '{number, status}'
```

When the run finishes (a few seconds to a few minutes), print each step's start offset and duration. Replace `1` with your build number:

```bash
N=1
curl -s -H "Authorization: Bearer $WOODPECKER_TOKEN" "$WP/api/repos/$WPID/pipelines/$N" | jq -r '
  .started as $s
  | "build \(.number): \(.status), total \(.finished - .started)s",
    (.workflows[0].children[] | "  \(.name)\t\(.state)\tstart +\(.started - $s)s\tdur \(.finished - .started)s")'
```

**What we got** (the second run on a warm machine, Docker images already pulled):

```
build 2: success, total 26s
  clone             success  start +1s   dur 3s
  lint              success  start +4s   dur 8s
  dependency-scan   success  start +4s   dur 12s
  test              success  start +16s  dur 9s
```

- `lint` and `dependency-scan` **start at the same second**. Neither depends on the other, so Woodpecker runs them in parallel. This is the parallelism a golden path gives you: you enable stages, the generator wires the dependencies.
- `test` starts only when **both** have finished (+16s is when `dependency-scan` ended), not when `lint` ended at +12s. Total time is roughly `clone + the slower of lint and dependency-scan + test`.
- Your first run may be slower: it pulls the Python and Trivy images and Trivy's vulnerability database.

> ✅ **Checkpoint**: you can point at two steps that overlapped in your run's timings.

---

## Step 5 — Compare Repeat Runs (4 minutes)

Start two more runs and print their timings with the Step 4 command (change `N`):

```bash
for i in 1 2; do
  curl -s -X POST -H "Authorization: Bearer $WOODPECKER_TOKEN" -H 'Content-Type: application/json' \
    -d '{"branch":"main"}' "$WP/api/repos/$WPID/pipelines" | jq .number
done
```

**What we got** (builds 1, 2, 3 on a machine that had already pulled the images in Module 5):

| Build | Total | `dependency-scan` | Others |
|---|---|---|---|
| #1 | 30s | 16s | lint 8s, test 9s |
| #2 | 26s | 12s | lint 8s, test 9s |
| #3 | 25s | 12s | lint 7s, test 9s |

Your numbers will differ. The pattern to look for is that the scan step gets faster after the first run and `lint` and `test` do not.

**This pipeline has no build cache.** `lint` and `test` run `pip install` from scratch every time (about the same duration each run), and the generated pipeline does not set up any dependency or build cache. We did not isolate why `dependency-scan` sped up (Trivy's vulnerability-database cache is the likely cause); on a machine that has never pulled the images, expect the first run to also pay for the image pulls. The Cloud Native Buildpacks cache is only relevant when the `build` stage is enabled, which this lab does not do. To make `lint`/`test` faster you would edit the contract's commands (for example, `pip install` against a pre-built image), which is a pipeline change you would then measure the same way.

In the Woodpecker UI, the repo page lists each run with its duration; click a run to see the per-step bars.

> ✅ **Checkpoint**: you have recorded timings for at least two successful runs and can say which step changed and why.

---

## Step 6 — Run the Validation Script

```bash
cd /path/to/uFawkesDojo
WOODPECKER_URL=$WP bash yellow-belt/module-06-golden-path/lab-01/validate.sh
```

It reads `WOODPECKER_TOKEN` from your shell. **Expected**: 7 checks, all `[✓]`: prerequisites, stack running, API token accepted, repo activated, a successful run, `lint` and `dependency-scan` overlapping in a run, and at least two successful runs to compare.

---

## Clean Up

```bash
# Stop the stack, keeping its data (do NOT use make down: it deletes volumes)
cd ~/dojo-labs/uFawkesPipe && docker compose -f compose.yaml stop

# Delete the lab repo from GitHub (needs the delete_repo scope, or use the repo's Settings page)
gh repo delete my-golden-path-app --yes
rm -rf ~/dojo-labs/uFawkesDevX/my-golden-path-app ~/dojo-labs/python-fawkes-path ~/dojo-labs/java-fawkes-path
```

---

## Troubleshooting

| Problem | Cause | Fix |
|---|---|---|
| `/api/user` returns 401 | Token stale, mistyped, or copied before a **Reset token** | Sign in again, copy the current token, `export` it again |
| `500 could not create webhook in forge` | `WOODPECKER_EXPERT_WEBHOOK_HOST` empty or `localhost` | Set a public URL in `.env`, recreate the server, restart the agent |
| Run stays `pending`/`running` | Agent lost its connection to the server | `docker compose -f compose.yaml restart woodpecker-agent`, then start a new run |
| `lint` fails: `ruff: not found`, or `test` fails: `No module named 'src'` | Contract commands skip the install step or use bare `pytest` | Use the Step 2.2 commands |
| Contract has `advanced.parallel` but nothing changes | The generator ignores it | Remove it; parallelism comes from steps with no `depends_on` |
| Validation: `Parallel Execution` fails | `lint` or `dependency_scan` is not enabled in the contract, or the run predates the change | Enable both, regenerate, push, start a new run |
| Woodpecker data and login vanished | `make down` ran `down -v` | Sign in again and re-activate; stop with `docker compose ... stop` in future |

---

## Retrieval Check (Answer Without Looking Back)

Write your answers down — the act of writing (not just thinking) strengthens retention.

1. What file defines the golden-path pipeline contract?
2. Which command turns the contract into a Woodpecker pipeline?
3. Which two steps ran in parallel in your pipeline, and why?
4. Why did `test` not start as soon as `lint` finished?
5. Where do you read per-step timings from?

---

## Retrieval Check Answers

1. `.fawkespipe.yml`
2. `make generate-pipeline` in uFawkesPipe (it writes `.woodpecker.yml`)
3. `lint` and `dependency-scan`: neither has a `depends_on`, so Woodpecker starts them together
4. In our runs `test` started when the slower parallel step (`dependency-scan`) finished
5. The Woodpecker API (`/api/repos/<id>/pipelines/<n>`) or the run page in the UI

---

## Reference: What You Built

| File | Purpose |
|------|---------|
| `.fawkespipe.yml` | Pipeline contract (lint, test, dependency scan) |
| `.woodpecker.yml` | Generated Woodpecker pipeline; regenerate it after editing the contract |
| `src/app.py` | Flask app with `/` and `/health` |
| `tests/test_app.py` | Pytest suite |
| `Dockerfile`, `score.yaml` | Present in the scaffold; not used by this lab's pipeline |

➡️ **Next**: Return to [Module 6 README](../README.md), then continue to **Module 07: Security Scanning & Quality Gates**.
