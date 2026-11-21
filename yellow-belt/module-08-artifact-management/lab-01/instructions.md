# Lab 01: Build, Scan and Push an Image with uFawkesPipe

**Module**: Yellow Belt — Module 8: Artifact Management
**Estimated Time**: about 25 minutes (an estimate, not timed)
**Difficulty**: Intermediate (Modules 5-7 complete required)
**Runs against**: uFawkesPipe v2.0.0 (Docker Compose)

> **Last run for real**: 2026-11-21, against uFawkesPipe v2.0.0 (Woodpecker 3.20.1) and uFawkesDevX v1.0.1, with a local `registry:2` container instead of Docker Hub. The agent needed the Docker socket mounted (Step 1); this is not a run of an unmodified release.
>
> **Scope.** v2.0.0 turns `build`, `image_scan`, `push` and `deploy` into pipeline steps, and that is all this lab runs. It does **not** implement the module's retention policies, tag-pattern retention, artifact promotion, Cosign signing or the `kubernetes` section: the generator ignores them (Step 5 shows how to check). The `deploy` step does not work as generated (Step 4).

---

## Objectives

By the end of this lab you will have:

1. Built an image in the pipeline and pushed it to a registry you control
2. Watched the `image_scan` gate stop the pipeline before `push`
3. Pushed after disabling the gate, and read what the registry actually holds
4. Seen the generated `deploy` step fail, and why
5. Checked which contract fields the generator really turns into steps

---

## Prerequisites

This lab continues [Module 5](../../module-05-ci-fundamentals/lab-01/instructions.md), [Module 6](../../module-06-golden-path/lab-01/instructions.md) and [Module 7](../../module-07-security-scanning/lab-01/instructions.md). Use their **Prerequisites** (tools, GitHub OAuth App, `uFawkesPipe` and `uFawkesDevX` checkouts, `.env`, `WOODPECKER_TOKEN`). Never stop the stack with `make down` (it runs `down -v`).

```bash
git -C ~/dojo-labs/uFawkesPipe describe --tags   # must print v2.0.0
export WP=http://localhost:8000        # your Woodpecker URL (check WOODPECKER_UI_PORT in .env)
export WOODPECKER_TOKEN='eyJ...'
curl -s -H "Authorization: Bearer $WOODPECKER_TOKEN" $WP/api/user | jq .login
```

**Expected**: your GitHub login.

---

## Step 1 — A Registry and Docker Access (5 minutes)

The default `cnb` builder runs `pack build --publish` and needs `registry_username` and `registry_password` secrets for Docker Hub. To keep the lab self-contained, use the `docker` builder and a throwaway local registry:

```bash
docker run -d --name lab-registry -p 5001:5000 registry:2
curl -s localhost:5001/v2/_catalog     # {"repositories":[]}
```

(Port 5001 because macOS uses 5000.) The generated `build` and `push` steps run `docker build` and `docker push` in `docker:24-cli`, which has no Docker socket. Mount it into every step from the agent, with an override file kept outside the repos:

```yaml
services:
  woodpecker-agent:
    environment:
      - WOODPECKER_BACKEND_DOCKER_VOLUMES=/var/run/docker.sock:/var/run/docker.sock
```

```bash
cd ~/dojo-labs/uFawkesPipe
docker compose -f compose.yaml -f /path/to/override.yaml up -d woodpecker-agent
```

**This gives every step control of your Docker daemon; use it only for this lab.** Because the image name starts with `localhost:5001`, the Docker daemon (which runs inside Colima's VM) treats it as insecure and pushes over plain HTTP.

> ✅ **Checkpoint**: the registry answers and the agent restarted.

---

## Step 2 — Build and Scan: the Gate Stops the Push (8 minutes)

```bash
cd ~/dojo-labs/uFawkesDevX
cookiecutter templates/python-flask-app --no-input \
  project_name="My Artifact App" project_slug="my-artifact-app" \
  language="python" registry_namespace="dojo"
cd my-artifact-app
```

Replace everything from `build:` down in `.fawkespipe.yml` (the scaffold has a top-level `image:` block that v2.0.0 does not read; the image name comes from `build.image`):

```yaml
build:
  builder: docker
  docker:
    dockerfile: Dockerfile
    context: .
  image:
    namespace: localhost:5001/dojo
    name: my-artifact-app
stages:
  build:
    enabled: true
  image_scan:
    enabled: true
  push:
    enabled: true
  deploy:
    enabled: true
    target: docker
    port: 8080
```

Generate, push and activate, then define `run` as in Module 7 (starts a run, waits, prints each step):

```bash
cd ~/dojo-labs/uFawkesPipe
make generate-pipeline \
  FILE=$HOME/dojo-labs/uFawkesDevX/my-artifact-app/.fawkespipe.yml \
  OUTPUT=$HOME/dojo-labs/uFawkesDevX/my-artifact-app/.woodpecker.yml
cd ~/dojo-labs/uFawkesDevX/my-artifact-app
git init -b main && git add . && git commit -m "Initial commit: scaffolded Python Flask app"
gh repo create my-artifact-app --private --source=. --remote=origin --push
RID=$(gh api repos/$(gh api user --jq .login)/my-artifact-app --jq .id)
curl -s -X POST -H "Authorization: Bearer $WOODPECKER_TOKEN" "$WP/api/repos?forge_remote_id=$RID" | jq '{id, active}'
WPID=$(curl -s -H "Authorization: Bearer $WOODPECKER_TOKEN" "$WP/api/repos/lookup/$(gh api user --jq .login)/my-artifact-app" | jq .id)
run() {
  n=$(curl -s -X POST -H "Authorization: Bearer $WOODPECKER_TOKEN" -H 'Content-Type: application/json' \
    -d '{"branch":"main"}' "$WP/api/repos/$WPID/pipelines" | jq .number)
  while :; do
    P=$(curl -s -H "Authorization: Bearer $WOODPECKER_TOKEN" "$WP/api/repos/$WPID/pipelines/$n")
    case $(echo "$P" | jq -r .status) in pending|running) sleep 8;; *) break;; esac
  done
  echo "$P" | jq -r '"build \(.number): \(.status)", (.workflows[0].children[] | "  \(.name)\t\(.state)")'
}
run
```

**What we got**:

```
build 1: failure
  clone       success
  build       success
  image-scan  failure
  push        skipped
```

The image is not in the registry (`curl -s localhost:5001/v2/_catalog` shows no repositories): `push` only runs after `image-scan` passes. The scan is `trivy image --exit-code 1` with no `--severity`, so any finding fails it. Run Trivy yourself to see what it found:

```bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image --quiet --severity HIGH,CRITICAL localhost:5001/dojo/my-artifact-app
```

**What we got**: 51 HIGH findings (and 79 LOW, 103 MEDIUM, 7 UNKNOWN) in the Debian layer of `python:3.12-slim`, none in the app. We tried `python:3.13-alpine`: it still had 5 HIGH, mostly vulnerable packages bundled inside pip. Fixing the base image is a moving target that depends on the day you run this, so the lab does not do it. `fail_on` and `severity` in the module's examples are not read by the generator either.

> ✅ **Checkpoint**: a run where `build` is green, `image-scan` is red and `push` is skipped.

---

## Step 3 — Push (5 minutes)

To reach `push`, disable the gate for this lab (a real team would fix or accept the findings instead):

```bash
cd ~/dojo-labs/uFawkesDevX/my-artifact-app
python3 - <<'PY'
t = open('.fawkespipe.yml').read().replace("  image_scan:\n    enabled: true", "  image_scan:\n    enabled: false")
open('.fawkespipe.yml', 'w').write(t)
PY
(cd ~/dojo-labs/uFawkesPipe && make generate-pipeline \
  FILE=$HOME/dojo-labs/uFawkesDevX/my-artifact-app/.fawkespipe.yml \
  OUTPUT=$HOME/dojo-labs/uFawkesDevX/my-artifact-app/.woodpecker.yml)
git commit -am "Disable image_scan to reach push" && git push origin main
run
```

**What we got**:

```
build 2: success
  clone  success
  build  success
  push   success
  (no deploy step shown)
```

**Ask the registry, not the pipeline:**

```bash
curl -s localhost:5001/v2/dojo/my-artifact-app/tags/list
```

**What we got**: `{"name":"dojo/my-artifact-app","tags":["latest"]}`. Only `latest`. The generated `build` runs `docker build -t localhost:5001/dojo/my-artifact-app` with no tag, and `push` pushes that same name, so there is **no commit-SHA tag**. The `tags:` list from the module (`${GIT_COMMIT_SHORT}`, `${GIT_BRANCH}`) is ignored for the `docker` builder. `latest` is a moving target: a second push replaces it, so you cannot tell which commit it holds.

> ✅ **Checkpoint**: the registry holds `dojo/my-artifact-app:latest`, and you can say why that is not a traceable artifact.

---

## Step 4 — The Generated Deploy Step (4 minutes)

`deploy` did not appear in build 2: it is generated with `when: event: push`, and the lab's runs started from the API have event `manual`. A push to GitHub would trigger it, but GitHub's webhook cannot reach `localhost`. To see the step run, widen the event by hand in `.woodpecker.yml` (regenerating removes this):

```yaml
  when:
    event: [push, manual]
    branch: main
```

```bash
git commit -am "Let deploy run on manual" && git push origin main
run
```

**What we got**: `build 3: failure` with `deploy  failure`. The log:

```
docker run -d --name $CI_REPO_NAME --network ufawkespipe_default -p 8080:8000 --restart unless-stopped  /my-artifact-app:0d4467e
docker: invalid reference format.
```

Three defects show here. The image reference is `${REGISTRY_USERNAME}/${CI_REPO_NAME}:${CI_COMMIT_SHA:0:7}`, but `REGISTRY_USERNAME` is not set in that step, so the name starts with `/`. The tag is the commit SHA, but `push` never pushed a SHA tag (Step 3). And `-p 8080:8000` maps to container port 8000 while the scaffolded app listens on 8080. This step is written for the `cnb` builder, where `pack build --publish` pushes `<user>/<repo>:<sha>`; it does not work with the `docker` builder.

> ✅ **Checkpoint**: you have seen `deploy` fail and can name the empty variable.

---

## Step 5 — What the Generator Ignores (2 minutes)

The module describes retention, promotion, signing and Kubernetes. Check each against the generator:

```bash
cd ~/dojo-labs/uFawkesPipe
sed -n '/^STAGE_ORDER/,/^)/p' scripts/generate_woodpecker_yml.py
grep -n 'retention\|cosign\|kubernetes\|sign' scripts/generate_woodpecker_yml.py
```

**What we got**: `STAGE_ORDER` has `lint, test, sast, dependency_scan, build, image_scan, dast, defectdojo, push, deploy, notify_obs`. The `grep` finds nothing for `retention`, `cosign` or `kubernetes`. So `advanced.artifacts.retention`, a `sign` stage and a `kubernetes:` section can be written in the contract and pass generation, but produce no step: nothing expires, signs or deploys to a cluster. Promotion by re-tagging (`docker tag` then `docker push`) is something you would do yourself; no stage does it.

The golden-path repos agree: `java-fawkes-path` enables `test`, `dependency_scan`, `build` and `image_scan` (`docker` builder, `${GIT_COMMIT_SHORT}` tag listed but not applied); `python-fawkes-path` enables only `build` and `notify_obs`. Neither has a `push` stage. We did not run their pipelines.

> ✅ **Checkpoint**: you can name which of retention, promotion, signing and Kubernetes v2.0.0 does not implement.

---

## Step 6 — Run the Validation Script

```bash
cd /path/to/uFawkesDojo
WOODPECKER_URL=$WP bash yellow-belt/module-08-artifact-management/lab-01/validate.sh
```

It reads `WOODPECKER_TOKEN` from your shell. **Expected**: 9 checks, all `[✓]`: prerequisites, stack running, API token accepted, repo activated, a successful run, a run where `build` succeeded, a run where `image-scan` failed and `push` was skipped, a run where `build` and `push` succeeded, and a tag in the registry (`REGISTRY_URL` defaults to `http://localhost:5001`). Nothing checks `deploy`, because it fails as generated.

---

## Clean Up

```bash
docker rm -f lab-registry
cd ~/dojo-labs/uFawkesPipe && docker compose -f compose.yaml up -d woodpecker-agent   # without the override: drops the socket mount
gh repo delete my-artifact-app --yes
rm -rf ~/dojo-labs/uFawkesDevX/my-artifact-app
docker image rm localhost:5001/dojo/my-artifact-app
```

---

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| `build`: cannot connect to the Docker daemon | No socket in the step | Mount it from the agent (Step 1) |
| `push`: `http: server gave HTTP response to HTTPS client` | Registry name is not `localhost` | Use `localhost:5001` in `build.image.namespace` (Step 2) |
| `image-scan` fails | Any finding fails it; base image CVEs | Step 2; fix the base image or disable the stage knowingly |
| `push` is skipped | An earlier step failed | Fix the earlier step |
| `deploy` does not appear | `when: event: push` excludes API runs | Step 4 |
| `deploy`: `invalid reference format` | `REGISTRY_USERNAME` empty, no SHA tag pushed | Step 4; deploy is for the `cnb` builder |
| Retention or signing "not working" | The generator has no such step | Step 5 |
| Run stays `pending` | Agent lost its connection | `docker compose -f compose.yaml restart woodpecker-agent`, run again |

---

## Retrieval Check (Answer Without Looking Back)

1. Why was `push` skipped in build 1?
2. Which tags did the registry hold after the push, and what does that say about traceability?
3. Why did you ask the registry rather than trust a green `push` step?
4. Where did the image-scan findings come from?
5. Name two things the module describes that v2.0.0 does not implement.

---

## Retrieval Check Answers

1. `image-scan` failed (Trivy found vulnerabilities, exit code 1), and `push` runs after it
2. Only `latest`; it moves with every push, so it does not identify a commit
3. A step can be green without proving the result you care about; the registry is the source of truth for what was pushed
4. The Debian base image (`python:3.12-slim`), not the app
5. Any two of: retention, promotion between environments, Cosign signing, the `kubernetes` section, tag lists for the `docker` builder

---

## Reference: What You Built

| File | Purpose |
|------|---------|
| `.fawkespipe.yml` | Contract: build, image scan, push, deploy |
| `.woodpecker.yml` | Generated pipeline; regenerate after editing the contract (hand edits are lost) |

➡️ **Next**: Return to [Module 8 README](../README.md), then prepare for the **Yellow Belt Assessment**.
