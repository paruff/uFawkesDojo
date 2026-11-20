# Lab 01: Make Security Findings Fail the Pipeline

**Module**: Yellow Belt — Module 7: Security Scanning & Quality Gates
**Estimated Time**: about 25 minutes (an estimate, not timed; a first run pulls container images and Trivy's vulnerability database)
**Difficulty**: Intermediate (Modules 5 & 6 complete required)
**Runs against**: uFawkesPipe v2.0.0 and uFawkesDevX v1.0.1 (Docker Compose)

> **Last run for real**: 2026-11-20, every step below, against uFawkesPipe v2.0.0 (Woodpecker 3.20.1) and uFawkesDevX v1.0.1.
>
> **Scope.** This lab runs the one security stage that needs no extra services: `dependency_scan` (Trivy). We did **not** run `sast` (SonarQube, Bandit), `image_scan`, `dast` or `defectdojo`: they need SonarQube, a container registry login, a deployed target or DefectDojo, and the Docker VM we used has 2 GB of RAM, too little for SonarQube and DefectDojo. The module's theory describes them; treat that part as unrun. uFawkesPipe has no separate Gitleaks stage; Trivy's filesystem scan also looks for secrets (Step 4).

---

## Objectives

By the end of this lab you will have:

1. Written a contract that enables a Trivy `dependency_scan` stage and generated its pipeline
2. Run it green, then made it fail by adding a dependency with a known CVE
3. Found out which CVE failed the build (the log does not say)
4. Made the same stage fail on a planted secret
5. Fixed both findings and watched the pipeline recover

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

## Step 6 — Run the Validation Script

```bash
cd /path/to/uFawkesDojo
WOODPECKER_URL=$WP bash yellow-belt/module-07-security-scanning/lab-01/validate.sh
```

It reads `WOODPECKER_TOKEN` from your shell. **Expected**: 7 checks, all `[✓]`: prerequisites, stack running, API token accepted, repo activated, a successful run, a run where `dependency-scan` failed and `test` was skipped, and a successful run after it.

---

## Clean Up

```bash
cd ~/dojo-labs/uFawkesPipe && docker compose -f compose.yaml stop   # not make down
gh repo delete my-secure-app --yes
rm -rf ~/dojo-labs/uFawkesDevX/my-secure-app
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
| Run stays `pending` | Agent lost its connection | `docker compose -f compose.yaml restart woodpecker-agent`, run again |

---

## Retrieval Check (Answer Without Looking Back)

1. What makes a scan step fail the pipeline?
2. Why was `test` skipped in Step 3?
3. Where do the findings go, and how did you read them?
4. Which stage caught the planted secret, and what else does that mean about it?
5. Why is deleting the file not enough for a real leaked secret?

---

## Retrieval Check Answers

1. The tool exits non-zero (`trivy fs --exit-code 1`), and Woodpecker marks the step failed
2. It depends on both `lint` and `dependency-scan`, and one failed
3. A JSON file in the workspace (`artifacts/security/trivy-repo.json`); run Trivy locally to read them
4. `dependency-scan`, because Trivy's filesystem scan includes secret scanning; it is not a separate Gitleaks gate
5. The secret stays in Git history; it must be revoked and rotated

---

## Reference: What You Built

| File | Purpose |
|------|---------|
| `.fawkespipe.yml` | Contract: lint, test, dependency scan |
| `.woodpecker.yml` | Generated pipeline; regenerate after editing the contract |
| `requirements.txt` | Where the vulnerable dependency was added and removed |

➡️ **Next**: Return to [Module 7 README](../README.md), then continue to **Module 08: Artifact Management**.
