# Lab 01: Make Security Findings Fail the Pipeline

**Module**: Yellow Belt — Module 7: Security Scanning & Quality Gates
**Estimated Time**: about 25 minutes (an estimate, not timed; a first run pulls container images and Trivy's vulnerability database)
**Difficulty**: Intermediate (Modules 5 & 6 complete required)
**Runs against**: uFawkesPipe v2.0.0 and uFawkesDevX v1.0.1 (Docker Compose)

> **Last run for real**: 2026-11-20, every step below, against uFawkesPipe v2.0.0 (Woodpecker 3.20.1) and uFawkesDevX v1.0.1.
>
> **Scope.** Steps 1-5 run `dependency_scan` (Trivy). Steps 6-10 run `sast` (SonarQube), `image_scan`, Bandit, `dast` (OWASP ZAP) and the `defectdojo` upload. v2.0.0 does not work out of the box for any of Steps 6-10: each step lists the defects we hit and the workaround that got it running. The `dast` step still ends red (Step 9 says why) and the Trivy and Bandit options inside `sast` do not work (Step 6). uFawkesPipe has no separate Gitleaks stage; Trivy's filesystem scan also looks for secrets (Step 4). Steps 6-10 need a Docker VM with about 6 GB of RAM and a lot of patience; on a laptop already under load the runs were very slow, and starting SonarQube, ZAP and DefectDojo at the same time overloaded ours.

---

## Objectives

By the end of this lab you will have:

1. Written a contract that enables a Trivy `dependency_scan` stage and generated its pipeline
2. Run it green, then made it fail by adding a dependency with a known CVE
3. Found out which CVE failed the build (the log does not say)
4. Made the same stage fail on a planted secret
5. Fixed both findings and watched the pipeline recover
6. Run SonarQube SAST from the pipeline, and learn what v2.0.0 needs from you to make it work
7. Build an image in the pipeline and scan it

---

## Prerequisites

This lab continues [Module 5](../../module-05-ci-fundamentals/lab-01/instructions.md) and [Module 6](../../module-06-golden-path/lab-01/instructions.md). Use their **Prerequisites** (tools, GitHub OAuth App, `uFawkesPipe` and `uFawkesDevX` checkouts, `.env`, `WOODPECKER_TOKEN`). Start only `docker compose -f compose.yaml up -d woodpecker-server woodpecker-agent`, and never stop the stack with `make down` (it runs `down -v`).

```bash
export WP=http://localhost:8000        # your Woodpecker URL (check WOODPECKER_UI_PORT in .env)
export WOODPECKER_TOKEN='eyJ...'
curl -s -H "Authorization: Bearer $WOODPECKER_TOKEN" $WP/api/user | jq .login
```

**Expected**: your GitHub login.

---

## Step 1 — Read the Security Stages (3 minutes)

```bash
cd ~/dojo-labs/uFawkesPipe
sed -n '/^STAGE_ORDER/,/^)/p' scripts/generate_woodpecker_yml.py
grep -n 'trivy\|osv-scanner\|bandit\|sonar-scanner\|zap-' scripts/generate_woodpecker_yml.py | head -20
```

The security-related stages are `sast`, `dependency_scan`, `image_scan`, `dast` and `defectdojo`. Each becomes one Woodpecker step. There is no `secrets-scan` or `vuln-scan-fs` stage: those names in older copies of this lab do not exist in v2.0.0. Each scan step runs its tool with `--exit-code 1` (or the tool's default), so **a finding fails the step; that is the quality gate**.

The golden-path template repos from [Module 6](../../module-06-golden-path/lab-01/instructions.md) show the difference. `paruff/java-fawkes-path` enables `dependency_scan`, `build` and `image_scan` (steps `dependency-scan`, `build`, `image-scan`), so a team that copies it gets scanning for free. `paruff/python-fawkes-path` enables only `build` and `notify_obs`, so it has **no** security scan. This lab builds the Python app's scanning by hand; we did not run either template repo's pipeline.

> ✅ **Checkpoint**: you can say which stages scan and what makes them fail.

---

## Step 2 — Scaffold, Write the Contract, Run Green (7 minutes)

```bash
cd ~/dojo-labs/uFawkesDevX
cookiecutter templates/python-flask-app --no-input \
  project_name="My Secure App" project_slug="my-secure-app" \
  language="python" registry_namespace="dojo"
cd my-secure-app
```

Replace everything from `stages:` down in `.fawkespipe.yml` with:

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

Generate the pipeline, push, and activate (same calls as Module 6):

```bash
cd ~/dojo-labs/uFawkesPipe
make generate-pipeline \
  FILE=$HOME/dojo-labs/uFawkesDevX/my-secure-app/.fawkespipe.yml \
  OUTPUT=$HOME/dojo-labs/uFawkesDevX/my-secure-app/.woodpecker.yml
cd ~/dojo-labs/uFawkesDevX/my-secure-app
git init -b main && git add . && git commit -m "Initial commit: scaffolded Python Flask app"
gh repo create my-secure-app --private --source=. --remote=origin --push
RID=$(gh api repos/$(gh api user --jq .login)/my-secure-app --jq .id)
curl -s -X POST -H "Authorization: Bearer $WOODPECKER_TOKEN" "$WP/api/repos?forge_remote_id=$RID" | jq '{id, active}'
WPID=$(curl -s -H "Authorization: Bearer $WOODPECKER_TOKEN" "$WP/api/repos/lookup/$(gh api user --jq .login)/my-secure-app" | jq .id)
```

Define a helper that starts a run, waits, and prints each step's state (use it for every run below):

```bash
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
build 1: success
  clone             success
  lint              success
  dependency-scan   success
  test              success
```

The generated `dependency-scan` step is `trivy fs --exit-code 1 --format json --output artifacts/security/trivy-repo.json .` in `aquasec/trivy:latest`.

> ✅ **Checkpoint**: a green run with a `dependency-scan` step.

---

## Step 3 — Add a Vulnerable Dependency and Watch the Gate Fail (5 minutes)

```bash
cd ~/dojo-labs/uFawkesDevX/my-secure-app
echo "requests==2.19.0" >> requirements.txt
git commit -am "Add old requests" && git push origin main
run
```

**What we got**:

```
build 2: failure
  clone             success
  lint              success
  dependency-scan   failure
  test              skipped
```

`test` never ran: it waits for both `lint` and `dependency-scan` (Module 6), so one failed scan stops the pipeline.

**The log does not name the CVE.** The step writes its findings to `artifacts/security/trivy-repo.json` inside the workspace and prints only Trivy's progress, ending at `[pip] Detecting vulnerabilities...`. To see the finding, run the same scan yourself:

```bash
docker run --rm -v "$PWD":/src -w /src aquasec/trivy:latest fs --quiet --severity HIGH,CRITICAL --format table .
```

**What we got**: `requests 2.19.0`, `CVE-2018-18074` (HIGH), fixed in `2.20.0`. Note the pipeline gates on **every** severity (it sets no `--severity`), so a LOW finding fails it too; the table above filters to HIGH and CRITICAL only to keep the output short.

> ✅ **Checkpoint**: you can name the CVE and the version that fixes it.

---

## Step 4 — Plant a Secret and Watch the Same Stage Fail (4 minutes)

Now remove the bad dependency but add a fake credential:

```bash
python3 - <<'PY'
lines = [l for l in open('requirements.txt') if not l.startswith('requests')]
open('requirements.txt', 'w').writelines(lines)
PY
# The key is assembled at runtime so this document itself holds no secret-shaped string
python3 - <<'PY'
key_id = "AKIA" + "IOSFODNN7REALKEY"
secret = "wJalrXUtnFEMI/K7MDENG/" + "bPxRfiCYEXAMPLEKEY"
open('src/config.py', 'w').write(f'AWS_ACCESS_KEY_ID = "{key_id}"\nAWS_SECRET_ACCESS_KEY = "{secret}"\n')
PY
git add -A && git commit -m "Drop requests, add config" && git push origin main
run
docker run --rm -v "$PWD":/src -w /src aquasec/trivy:latest fs --quiet --scanners secret --format table .
```

**What we got**: build 5 failed at `dependency-scan` again, and the local scan lists `src/config.py` with 1 secret. So the stage you enabled for dependencies also gates on secrets, because Trivy's filesystem scan includes its secret scanner by default. It is not a dedicated Gitleaks gate, and it only sees files in the commit being built.

> ✅ **Checkpoint**: a red run caused by a secret, not a CVE.

---

## Step 5 — Fix and Recover (3 minutes)

```bash
git rm src/config.py
git commit -m "Remove secret" && git push origin main
run
```

**What we got**: `build 6: success`, all steps green.

**The secret is still in Git history** (the commit that added it) and on GitHub. Removing the file turned the pipeline green; it did not un-leak the credential. A real secret must be **revoked and rotated**; rewriting history is not enough.

> ✅ **Checkpoint**: you have a red run followed by a green run, and can say why green is not enough for a leaked secret.

---

## Step 6 — Add SAST with SonarQube (about 20 minutes of setup)

The generated `sast` step runs `sonar-scanner`. v2.0.0 does not wire it up for you; we hit four problems, in this order.

**6.1 Give Docker more memory and start SonarQube.** SonarQube did not fit in a 2 GB VM. With Colima: `docker compose -f compose.yaml stop && colima stop && colima start --cpu 4 --memory 6`. Then `docker compose -f compose.yaml up -d woodpecker-server woodpecker-agent sonarqube`. SonarQube is at `http://localhost:9001` (the compose file maps it there, not 9000). Change the default `admin`/`admin` password, create a project and a token:

```bash
curl -s -u admin:admin -X POST localhost:9001/api/users/change_password \
  --data-urlencode login=admin --data-urlencode previousPassword=admin --data-urlencode "password=<new>"
curl -s -u admin:<new> -X POST localhost:9001/api/projects/create -d project=my-secure-app -d name=my-secure-app
export SONAR_LAB_TOKEN=$(curl -s -u admin:<new> -X POST localhost:9001/api/user_tokens/generate \
  -d name=lab -d type=GLOBAL_ANALYSIS_TOKEN | jq -r .token)
```

**6.2 Enable `sast` in the contract** (SonarQube only; see 6.5 for why Trivy and Bandit are off) and add a `sonar-project.properties`:

```yaml
  sast:
    enabled: true
    sonarqube:
      enabled: true
      qualityGate: false
    trivy:
      enabled: false
    bandit:
      enabled: false
```

```
sonar.projectKey=my-secure-app
sonar.sources=src
sonar.host.url=http://host.docker.internal:9001
```

**6.3 Problem 1: the step sources a script your repo does not have.** The first run fails with `/drone/src/scripts/otel-trace.sh: No such file or directory`. The generated step sources it from the workspace, and Woodpecker 3's default workspace is not `/drone/src`. Fix both: copy the script into your repo and set the workspace at the top of the generated `.woodpecker.yml` (the generator does not write one, so **regenerating removes it; add it again each time**):

```bash
mkdir -p scripts && cp ~/dojo-labs/uFawkesPipe/scripts/otel-trace.sh scripts/
printf 'workspace:\n  base: /drone\n  path: src\n\n' | cat - .woodpecker.yml > w.yml && mv w.yml .woodpecker.yml
```

**6.4 Problem 2: the step has no credentials.** The next failure is `Not authorized. Analyzing this project requires authentication`. The generated step declares no environment, and `SONARQUBE_URL`, `SONARQUBE_PROJECT_KEY` and the token must reach it somehow. Woodpecker's server setting `WOODPECKER_ENVIRONMENT` injects variables into every step. Use a compose override file (outside the repo) on the **server** (it is ignored on the agent):

```yaml
services:
  woodpecker-server:
    environment:
      - WOODPECKER_ENVIRONMENT=SONARQUBE_URL:http://host.docker.internal:9001,SONARQUBE_PROJECT_KEY:my-secure-app,SONAR_HOST_URL:http://host.docker.internal:9001,SONAR_TOKEN:${SONAR_LAB_TOKEN},SONARQUBE_TOKEN:${SONAR_LAB_TOKEN}
```

`docker compose -f compose.yaml -f override.yaml up -d woodpecker-server`. **Every pipeline step on this server can now read the token**: this is a lab shortcut, not something to copy to a shared server.

**6.5 Problem 3: the quality-gate loop never ends, and Problem 4: Trivy and Bandit are missing.** With `qualityGate: true` the step polls `/api/qualitygates/project`, which is not a SonarQube endpoint (`Unknown url`), prints `Quality gate status: PENDING` forever and has no timeout. We cancelled that run after more than ten minutes. That is why the contract above sets `qualityGate: false`. Read the gate yourself:

```bash
curl -s -u "$SONAR_LAB_TOKEN:" "localhost:9001/api/qualitygates/project_status?projectKey=my-secure-app" | jq .projectStatus.status
```

With `trivy` and `bandit` enabled, the next failure is `trivy: command not found`: the step runs in `sonarsource/sonar-scanner-cli`, which has neither tool. That is why they are off. Trivy's filesystem scan still runs in `dependency_scan`; Bandit has no working route in v2.0.0.

**What we got** (run with `lint`, `sast`, `dependency-scan`): `sast  success`, with `ANALYSIS SUCCESSFUL` in its log and the project visible at `http://localhost:9001/dashboard?id=my-secure-app`.

> ✅ **Checkpoint**: a run where `sast` succeeded and SonarQube shows your project.

---

## Step 7 — Build and Scan the Image (about 10 minutes)

Switch the contract to the Docker builder (the default `cnb` builder pushes to a registry, which this lab does not set up), name the image, and enable `build` and `image_scan`:

```yaml
build:
  builder: docker
  docker:
    dockerfile: Dockerfile
    context: .
  image:
    namespace: dojo
    name: my-secure-app
```

```yaml
  build:
    enabled: true
  image_scan:
    enabled: true
```

The generated `build` step runs `docker build` and `image-scan` runs `trivy image` on the same name, but neither step has a Docker socket. Mount it into every step from the agent, in the same override style:

```yaml
services:
  woodpecker-agent:
    environment:
      - WOODPECKER_BACKEND_DOCKER_VOLUMES=maven-cache:/root/.m2,/var/run/docker.sock:/var/run/docker.sock
```

Trivy then finds the image in the local Docker daemon, so nothing is pushed. **This gives every step control of your Docker daemon; use it only for this lab.** Regenerate (and re-add the workspace block from 6.3), push and run.

**What we got**: `build  success`, `image-scan  failure`. Running Trivy yourself shows why: the image has **234 vulnerabilities, 51 of them HIGH or CRITICAL, all in the Debian base layer** (`python:3.12-slim`); Flask and its dependencies had none.

```bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image --severity HIGH,CRITICAL dojo/my-secure-app
```

The gate has no `--severity`, so any finding fails it. You would fix this by changing the base image or accepting the risk in the contract, not by editing the app. We did not make `image-scan` pass.

> ✅ **Checkpoint**: `build` green and `image-scan` red, and you can say the CVEs come from the base image.

---

## Step 8 — Bandit Through the Lint Command (5 minutes)

The `sast` step cannot run Bandit (Step 6.5), but the `lint` stage runs any command you give it. Change the Python lint command in the contract:

```yaml
        cmd: pip install -q ruff bandit && ruff check . && bandit -r src/ --severity-level medium --confidence-level medium
```

Regenerate (re-add the workspace block from 6.3), push and run.

**What we got**: `lint  failure`. Bandit reported `B104 hardcoded_bind_all_interfaces` (Medium) at `src/app.py:19`, in the **scaffolded** app: `app.run(host="0.0.0.0", ...)`. Binding every interface is what you want inside a container, so suppress it with a reason instead of changing the code:

```python
app.run(host="0.0.0.0", port=int(os.environ.get("PORT", "8080")))  # nosec B104 - bind all interfaces is intended inside the container
```

Push and run again: `lint  success`.

> ✅ **Checkpoint**: a red `lint` from a Bandit finding, then green after a justified `# nosec`.

---

## Step 9 — DAST with OWASP ZAP (about 20 minutes)

DAST needs a running target. Start the image from Step 7 and point the contract at it:

```bash
docker run -d --name my-secure-app -p 8080:8080 dojo/my-secure-app
curl -s localhost:8080/health   # {"status":"ok"}
```

```yaml
  dast:
    enabled: true
    tool: zap
    target_url: http://host.docker.internal:8080
    timeout: 120
```

The generated step runs `zap-baseline.py` and then `zap-api-scan.py` against `<target>/openapi.json`, in `zaproxy/zap-stable`. Three problems, in the order we hit them:

1. **First pull fails** with `failed to Lchown` while extracting a layer, or the step ends with `No such image`. Run `docker pull zaproxy/zap-stable:latest` yourself (about 1 GB) and run again.
2. **`source: not found`** at the top of the log. The step's shell is `dash`, which has no `source`, so the OpenTelemetry span helper never loads. This did not stop the scan; ignore it.
3. **`A file based option has been specified but the directory '/zap/wrk' is not mounted`**, followed by ZAP's usage text. The step passes `-r` and `-x` report paths but never mounts `/zap/wrk`, and ZAP runs as a non-root user. Two changes get it going. Hand-edit the generated `dast` step (regenerating removes this):

```yaml
- name: dast
  image: zaproxy/zap-stable:latest
  backend_options:
    docker:
      user: root
```

and add a `/zap/wrk` volume to the agent, next to the Docker socket from Step 7: `WOODPECKER_BACKEND_DOCKER_VOLUMES=maven-cache:/root/.m2,/var/run/docker.sock:/var/run/docker.sock,zapwrk:/zap/wrk`.

**What we got**: ZAP runs. The baseline scan found missing security headers (`X-Content-Type-Options`, `Content-Security-Policy`, `Permissions-Policy`) and a `Server` header that leaks the version; the API scan found no `/openapi.json` (404). The step still ends `failure`: the log's last line is `ERROR [Errno 2] No such file or directory: '/zap/wrk/artifacts/security/zap-api.html'`, because the generated `mkdir -p artifacts/security` creates the directory in the workspace, not in `/zap/wrk`. So even a green DAST would leave its reports in a Docker volume where the DefectDojo step cannot find them. **We did not get a green `dast` step.** `-I` (the default `fail_on: HIGH`) only stops warnings failing it.

Stop the target when you are done: `docker rm -f my-secure-app`.

> ✅ **Checkpoint**: you have seen ZAP run in the pipeline and can name the findings and why the step still fails.

---

## Step 10 — Upload Findings to DefectDojo (about 30 minutes)

The `defectdojo` stage runs `curl` against DefectDojo's `import-scan` API for each report file it finds in `artifacts/security/`. DefectDojo's compose profile did not work out of the box either; we fixed five things before the first upload.

1. **Postgres 18 refuses to start** with the compose file's mount at `/var/lib/postgresql/data`. Override it in an extra compose file:

```yaml
services:
  postgres:
    volumes: !override
      - postgres-data:/var/lib/postgresql
  defectdojo-nginx:
    environment:
      DD_UWSGI_HOST: defectdojo
```

The second entry fixes problem 2: nginx exited with `host not found in upstream "uwsgi:3031"` because the service is called `defectdojo`, not `uwsgi`.

2. **Start it** (stop SonarQube first to save memory; the UI listens on port 8080, so stop the Step 9 target too):

```bash
cd ~/dojo-labs/uFawkesPipe
docker compose -f compose.yaml stop sonarqube
docker compose -f compose.yaml -f dd-override.yaml --profile security up -d \
  postgres valkey defectdojo defectdojo-nginx defectdojo-celery-beat defectdojo-celery-worker
```

3. **Nothing initialises the database** (no initializer service): `/login` returns HTTP 500 until you run the migrations, create an admin user and API token, and load the reference data. Without the fixtures, every upload fails with `Development_Environment matching query does not exist`:

```bash
docker exec defectdojo python3 manage.py migrate
docker exec defectdojo python3 manage.py loaddata system_settings initial_banner_conf product_type test_type \
  development_environment benchmark_type benchmark_category benchmark_requirement language_type \
  objects_review regulation initial_surveys role
docker exec -e PW='<admin password>' defectdojo python3 manage.py shell -c "
import os
from django.contrib.auth import get_user_model
from rest_framework.authtoken.models import Token
u,_=get_user_model().objects.get_or_create(username='admin',defaults={'is_superuser':True,'is_staff':True})
u.is_superuser=True; u.is_staff=True; u.set_password(os.environ['PW']); u.save()
print(Token.objects.get_or_create(user=u)[0].key)"
```

The `DOJO_API_TOKEN` in uFawkesPipe's `.env` does not match a token you create this way.

4. **Create the product and engagement the step names.** `import-scan` by name needs both to exist:

```bash
export DD_TOKEN=<the token printed above>
curl -s -H "Authorization: Token $DD_TOKEN" -H 'Content-Type: application/json' -d '{"name":"dojo-lab"}' localhost:8080/api/v2/product_types/
curl -s -H "Authorization: Token $DD_TOKEN" -H 'Content-Type: application/json' \
  -d '{"name":"my-secure-app","description":"lab","prod_type":1}' localhost:8080/api/v2/products/
curl -s -H "Authorization: Token $DD_TOKEN" -H 'Content-Type: application/json' \
  -d '{"name":"CI-Engagement","product":1,"target_start":"2026-11-21","target_end":"2026-12-31","engagement_type":"CI/CD","status":"In Progress"}' \
  localhost:8080/api/v2/engagements/
```

5. **Give Woodpecker the token** as a repo secret named `defectdojo_api_token` (Woodpecker UI: repo Settings, Secrets; events `push` and `manual`).

Now the contract, with `dependency_scan` and `defectdojo` enabled and the URL set (the default `http://defectdojo:8080` is not reachable from a step container):

```yaml
  defectdojo:
    enabled: true
    url: http://host.docker.internal:8080
    engagement_name: CI-Engagement
```

Add `requests==2.19.0` to `requirements.txt` again so there is something to upload. Two hand edits to the generated `.woodpecker.yml` (regenerating removes both): `failure: ignore` on `dependency-scan` (a failed scan otherwise skips every later step), and widen the upload step's `when` so it runs for the lab's API-started runs and after a failed scan:

```yaml
  when:
    event: [push, manual]
    branch: main
    status: [success, failure]
```

Push, run, then **ask DefectDojo, not the pipeline**:

```bash
curl -s -H "Authorization: Token $DD_TOKEN" localhost:8080/api/v2/tests/ | jq '.count'
curl -s -H "Authorization: Token $DD_TOKEN" "localhost:8080/api/v2/findings/?limit=5" | jq -r '.results[] | "\(.severity) \(.title)"'
```

**What we got**: `build 24: success` with `dependency-scan  failure` and `defectdojo-upload  success`, and a second Trivy Scan test in DefectDojo. The five findings were `High CVE-2018-18074 Requests 2.19.0` and four `Medium` CVEs on the same package.

**The upload step reports `success` even when nothing arrived.** Every `curl` ends in `|| true`, and our first run showed `success` while DefectDojo had zero findings (Problem 3: missing fixtures). Always check DefectDojo itself.

> ✅ **Checkpoint**: DefectDojo shows the Trivy findings for `my-secure-app`, and you can say why the pipeline's green upload step proves nothing on its own.

---

## Step 11 — Run the Validation Script

```bash
cd /path/to/uFawkesDojo
WOODPECKER_URL=$WP bash yellow-belt/module-07-security-scanning/lab-01/validate.sh
```

It reads `WOODPECKER_TOKEN` from your shell. **Expected**: 11 checks, all `[✓]`: prerequisites, stack running, API token accepted, repo activated, a successful run, a run where `dependency-scan` failed and `test` was skipped, a successful run after it, a run where `sast` succeeded, a run where `build` succeeded and `image-scan` ran, a run where `dast` ran, and a run where `defectdojo-upload` succeeded. It does not check Bandit or what is inside DefectDojo; use Steps 8 and 10 for those.

---

## Clean Up

```bash
cd ~/dojo-labs/uFawkesPipe && docker compose -f compose.yaml stop   # not make down
gh repo delete my-secure-app --yes
rm -rf ~/dojo-labs/uFawkesDevX/my-secure-app
docker image rm dojo/my-secure-app
docker compose -f compose.yaml --profile security stop   # DefectDojo, if started
```

---

## Troubleshooting

| Problem | Cause | Fix |
|---|---|---|
| `/api/user` returns 401 | Token stale or mistyped | Copy the current token again |
| `dependency-scan` fails but the log shows no finding | Findings go to `artifacts/security/trivy-repo.json`, not the log | Run Trivy locally (Step 3) |
| `dependency-scan` is red and you removed the CVE | A secret (or a LOW finding) still trips it | Run Trivy locally with no `--severity` and no `--scanners` filter |
| First run is slow | Pulls images and Trivy's ~135 MB vulnerability database | Wait; later runs are faster |
| `sed -i` fails on macOS | BSD `sed` needs `-i ''` | Use the Python snippet in Step 4 |
| SAST step prints `PENDING` forever | Quality-gate loop polls a non-existent endpoint | Cancel the run; set `qualityGate: false` (Step 6.5) |
| `sast`: `/drone/src/scripts/otel-trace.sh: No such file` | Script missing and default workspace differs | Step 6.3 |
| `sast`: `Not authorized` | No token reaches the step | Step 6.4 |
| `sast`: `trivy`/`bandit: command not found` | `sonar-scanner-cli` image lacks them | Disable both (Step 6.5) |
| `build`: cannot connect to the Docker daemon | No socket in the step | Mount it from the agent (Step 7) |
| `dast`: `/zap/wrk is not mounted` | Generated step has no `/zap/wrk` volume | Step 9 |
| DefectDojo `/login` returns 500 | Database not initialised | Step 10, problem 3 |
| `defectdojo-upload` is green but DefectDojo is empty | Each `curl` ends in `\|\| true` | Run the `import-scan` call by hand and read the error; check fixtures, product and engagement |
| Run stays `pending` | Agent lost its connection | `docker compose -f compose.yaml restart woodpecker-agent`, run again |

---

## Retrieval Check (Answer Without Looking Back)

1. What makes a scan step fail the pipeline?
2. Why was `test` skipped in Step 3?
3. Where do the findings go, and how did you read them?
4. Which stage caught the planted secret, and what else does that mean about it?
5. Why is deleting the file not enough for a real leaked secret?
6. Why did the quality-gate polling loop never end, and how do you read the gate instead?
7. Where did the 51 HIGH/CRITICAL image findings come from?
8. Why can a green `defectdojo-upload` step still mean no findings were uploaded?

---

## Retrieval Check Answers

1. The tool exits non-zero (`trivy fs --exit-code 1`), and Woodpecker marks the step failed
2. It depends on both `lint` and `dependency-scan`, and one failed
3. A JSON file in the workspace (`artifacts/security/trivy-repo.json`); run Trivy locally to read them
4. `dependency-scan`, because Trivy's filesystem scan includes secret scanning; it is not a separate Gitleaks gate
5. The secret stays in Git history; it must be revoked and rotated
6. It polls `/api/qualitygates/project`, which does not exist, so the status stays `PENDING`; read `/api/qualitygates/project_status` yourself
7. The Debian base image (`python:3.12-slim`), not the app or its Python dependencies
8. Each upload `curl` ends in `|| true`, so a failed import is swallowed; check DefectDojo itself

---

## Reference: What You Built

| File | Purpose |
|------|---------|
| `.fawkespipe.yml` | Contract: lint, test, dependency scan |
| `.woodpecker.yml` | Generated pipeline; regenerate after editing the contract |
| `requirements.txt` | Where the vulnerable dependency was added and removed |

➡️ **Next**: Return to [Module 7 README](../README.md), then continue to **Module 08: Artifact Management**.
