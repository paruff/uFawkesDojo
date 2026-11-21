#!/usr/bin/env bash
# scripts/run-devx-labs.sh — the student half of White Belt 1, 3 and 4, scripted,
# then each lab's validate.sh. Needs a running uFawkesDevX stack (the labs'
# Step 1-2) with a checkout at $UFDEVX_DIR (default ~/dojo-labs/uFawkesDevX), and
# docker, jq, curl, cookiecutter. The nightly runs it (live-acceptance.yml).
#
# It repeats the commands in the three instructions.md files, so change them
# together. Browser-only steps and Module 1 Step 6 (needs the `coder` CLI) are
# not covered; validate.sh does not check them either.
set -euo pipefail

UFDEVX_DIR="${UFDEVX_DIR:-$HOME/dojo-labs/uFawkesDevX}"
GATEWAY_URL="${GATEWAY_URL:-http://localhost:8000}"
export UFDEVX_DIR GATEWAY_URL
DOJO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
YQ=(docker run --rm -i mikefarah/yq:4)

post() { curl -sf -X POST "${GATEWAY_URL}/api/score/specs" -H "Content-Type: application/json" -d @-; }
scaffold() { # <Name> <slug>
  (cd "$UFDEVX_DIR" && rm -rf "$2" && cookiecutter templates/python-flask-app --no-input \
    project_name="$1" project_slug="$2" language="python" registry_namespace="dojo")
}
workload() { # <name> <image> -> YAML on stdout
  printf 'apiVersion: score.dev/v1b1\nmetadata:\n  name: %s\n  annotations:\n    dojo/lab: white-belt-03\ncontainers:\n  %s:\n    image: %s\n    variables:\n      PORT: "8080"\nservice:\n  ports:\n    www:\n      port: 8080\n      targetPort: 8080\n' "$1" "$1" "$2"
}

echo "== White Belt 1: scaffold hello-devx and register it"
scaffold "Hello DevX" hello-devx
"${YQ[@]}" -o=json '.metadata.annotations."dojo/lab" = "white-belt-01"' < "$UFDEVX_DIR/hello-devx/score.yaml" | post > /dev/null

echo "== White Belt 3: register, break, roll back; scaffold and register a second service"
workload hello-gitops ghcr.io/dojo/hello-gitops:latest | "${YQ[@]}" -o=json . | post > /dev/null
workload hello-gitops ghcr.io/dojo/hello-gitops:v2.0-broken | "${YQ[@]}" -o=json . | post > /dev/null
workload hello-gitops ghcr.io/dojo/hello-gitops:latest | "${YQ[@]}" -o=json . | post > /dev/null
scaffold "Hello Scaffolded" hello-scaffolded
"${YQ[@]}" -o=json '.metadata.annotations."dojo/lab" = "white-belt-03"' < "$UFDEVX_DIR/hello-scaffolded/score.yaml" | post > /dev/null

echo "== White Belt 4: scaffold, register, trigger the pipeline webhook, run the app's tests and health"
scaffold "My First App" my-first-app
"${YQ[@]}" -o=json '.metadata.annotations."dojo/lab" = "white-belt-04"' < "$UFDEVX_DIR/my-first-app/score.yaml" | post > /dev/null
curl -sf -X POST "${GATEWAY_URL}/webhooks/score/pipeline/trigger" -H "Content-Type: application/json" \
  -d '{"workload":"my-first-app","action":"deploy"}' > /dev/null
docker run --rm -v "$UFDEVX_DIR/my-first-app":/app -w /app python:3.12-slim sh -c \
  'pip install -q -r requirements.txt pytest && python -m pytest -q'
docker rm -f my-first-app > /dev/null 2>&1 || true
docker run -d --rm --name my-first-app -v "$UFDEVX_DIR/my-first-app":/app -w /app -p 8090:8080 python:3.12-slim sh -c \
  'pip install -q -r requirements.txt && python src/app.py' > /dev/null
trap 'docker rm -f my-first-app > /dev/null 2>&1 || true' EXIT
for _ in $(seq 1 30); do curl -sf http://localhost:8090/health && break || sleep 2; done
echo
[ "$(curl -sf http://localhost:8090/health | jq -r .status)" = "ok" ] || {
  echo "app /health is not ok" >&2
  exit 1
}

echo "== validate.sh for each lab"
fail=0
for lab in module-01-what-is-idp module-03-gitops-principles module-04-first-deployment; do
  bash "$DOJO_DIR/white-belt/$lab/lab-01/validate.sh" || fail=1
done
exit "$fail"
