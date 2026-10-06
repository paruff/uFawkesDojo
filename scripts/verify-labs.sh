#!/usr/bin/env bash
# scripts/verify-labs.sh — local mirror of Live Acceptance (Nightly),
# .github/workflows/live-acceptance.yml: boot the real uFawkesObs stack the
# way the labs document it, wait for genuine health, run each stack-verified
# lab's own validate.sh against it, then tear down.
#
# The nine student-artifact labs (White 01/03/04, Yellow 05–08, Brown 15/16)
# are deliberately not wired here — same as CI: their self-checks verify
# artifacts only a completed lab produces (tracked in #73).
#
# Deviations from CI, both on purpose:
#   - the three up-dora labs share one stack instead of one stack each
#     (CI isolates so one lab cannot mask another; if that ever bites here
#     the groups can be split per-lab);
#   - teardown runs `down --remove-orphans` without CI's `-v`: this checkout
#     is persistent local state, not an ephemeral runner.
#
# Env: UF_OBS_DIR (stack checkout, default ~/dojo-labs/uFawkesObs),
#      STEADY_SECONDS (default 60, same as CI), GRAFANA_ADMIN_* (default:
#      sourced from the stack's .env, like CI's job-level env).
set -uo pipefail

DOJO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
UF_OBS_DIR="${UF_OBS_DIR:-$HOME/dojo-labs/uFawkesObs}"
STEADY_SECONDS="${STEADY_SECONDS:-60}"

# Same reason as CI's job env: short intervals so a lab that submits an
# event sees refreshed data within the run instead of waiting an hour.
export DORA_COMPUTE_INTERVAL_SECONDS="${DORA_COMPUTE_INTERVAL_SECONDS:-15}"
export OTEL_METRIC_EXPORT_INTERVAL="${OTEL_METRIC_EXPORT_INTERVAL:-5000}"

pass_count=0
fail_count=0
logs_captured=0

die() {
  echo "verify-labs: $*" >&2
  exit 1
}

stack_containers() {
  (cd "$UF_OBS_DIR" && docker compose --profile '*' ps -q 2> /dev/null) || true
}

teardown() {
  if [ -n "$(stack_containers)" ]; then
    echo "verify-labs: tearing down the stack in $UF_OBS_DIR"
    if ! (cd "$UF_OBS_DIR" && docker compose --profile '*' down --remove-orphans); then
      # Loud, non-fatal: like CI's teardown warning, it must not redden an
      # otherwise-green run — but it is never hidden.
      echo "verify-labs: WARNING: teardown failed — inspect 'docker compose --profile '*' ps' in $UF_OBS_DIR" >&2
    fi
  fi
}

capture_logs() {
  local log_dir="${TMPDIR:-/tmp}/verify-labs-$$"
  mkdir -p "$log_dir" || {
    echo "verify-labs: WARNING: cannot create $log_dir for stack logs" >&2
    return 0
  }
  if ! (cd "$UF_OBS_DIR" && docker compose --profile '*' logs --no-color --timestamps) \
    > "$log_dir/compose-logs.txt" 2>&1; then
    echo "verify-labs: WARNING: compose log capture failed (partial output in $log_dir/compose-logs.txt)" >&2
  fi
  echo "verify-labs: stack logs saved to $log_dir/compose-logs.txt"
}

on_exit() {
  teardown
}
trap on_exit EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

wait_for() { # name url — retry for up to 3 minutes, like CI
  local name="$1" url="$2" attempt
  for attempt in $(seq 1 90); do
    if curl -fsS --max-time 5 -o /dev/null "$url"; then
      echo "healthy: $name"
      return 0
    fi
    if ((attempt % 15 == 1)); then
      echo "waiting on $name (attempt $attempt)..."
    fi
    sleep 2
  done
  echo "NEVER HEALTHY: $name ($url)" >&2
  return 1
}

wait_healthy() { # expect_telemetry=true|false — the CI endpoint list
  local failed="" expect_telemetry="$1" name url
  while IFS='|' read -r name url; do
    wait_for "$name" "$url" || failed="${failed}${failed:+ }${name}"
  done << 'EOF'
Prometheus|http://localhost:9090/-/ready
Alertmanager|http://localhost:9093/-/healthy
Loki|http://localhost:3100/ready
Tempo|http://localhost:3200/ready
Grafana|http://localhost:3000/api/health
OTel Collector|http://localhost:8888/metrics
Alloy|http://localhost:12345/-/ready
DORA Ingestion API|http://localhost:8088/health
EOF
  if [ "$expect_telemetry" = "true" ]; then
    wait_for "Telemetry Generator" "http://localhost:5001/" || failed="${failed}${failed:+ }Telemetry Generator"
  fi
  if [ -n "$failed" ]; then
    echo "stack failed to become healthy: $failed" >&2
    return 1
  fi
  echo "all expected services healthy"
}

run_group() { # name make_target expect_telemetry "run_from|lab_path"...
  local group_name="$1" make_target="$2" telemetry="$3" spec run_from path dir
  shift 3
  echo ""
  echo "=== group ${group_name}: make ${make_target} ==="
  (cd "$UF_OBS_DIR" && make "$make_target") \
    || die "stack boot failed (make ${make_target} in $UF_OBS_DIR)"
  wait_healthy "$telemetry" || die "stack never became healthy — not a pass for any lab"
  echo "steady state (${STEADY_SECONDS}s — telemetry export and metric computation)"
  sleep "$STEADY_SECONDS"
  for spec in "$@"; do
    run_from="${spec%%|*}"
    path="${spec#*|}"
    echo ""
    echo "--- lab: $path (run_from=$run_from) ---"
    dir="$DOJO_ROOT"
    if [ "$run_from" = "stack" ]; then
      dir="$UF_OBS_DIR"
    fi
    if (cd "$dir" && bash "$DOJO_ROOT/$path/validate.sh"); then
      echo "RESULT PASS: $path"
      pass_count=$((pass_count + 1))
    else
      echo "RESULT FAIL: $path" >&2
      fail_count=$((fail_count + 1))
      if [ "$logs_captured" -eq 0 ]; then
        capture_logs
        logs_captured=1
      fi
    fi
  done
}

# ── prechecks (before the teardown trap can touch anything) ──────────────
docker info > /dev/null 2>&1 \
  || die "docker is not reachable — start Docker Desktop first"
[ -f "$UF_OBS_DIR/Makefile" ] \
  || die "no uFawkesObs stack at $UF_OBS_DIR (override with UF_OBS_DIR=...)"
if [ -n "$(stack_containers)" ]; then
  die "a uFawkesObs stack is already running in $UF_OBS_DIR — run 'make -C $UF_OBS_DIR down' first; verify-labs boots its own"
fi
if [ ! -f "$UF_OBS_DIR/.env" ]; then
  echo "verify-labs: no .env in the stack checkout — creating it (cp .env.example .env, the flow the labs document)"
  cp "$UF_OBS_DIR/.env.example" "$UF_OBS_DIR/.env" \
    || die "cannot create $UF_OBS_DIR/.env"
fi
mkdir -p "$UF_OBS_DIR"/data/tempo "$UF_OBS_DIR"/data/loki \
  "$UF_OBS_DIR"/data/alloy "$UF_OBS_DIR"/data/prometheus \
  "$UF_OBS_DIR"/data/alertmanager "$UF_OBS_DIR"/data/grafana \
  "$UF_OBS_DIR"/data/dora

# Grafana creds, after .env exists: same source as CI's job-level env, but
# the user's real stack .env — no hardcoded password, and lab-02 (run_from
# dojo, no ./.env beside it) reads them from here.
export GRAFANA_ADMIN_USER="${GRAFANA_ADMIN_USER:-$(grep -E '^GRAFANA_ADMIN_USER=' "$UF_OBS_DIR/.env" | cut -d= -f2- || true)}"
export GRAFANA_ADMIN_PASSWORD="${GRAFANA_ADMIN_PASSWORD:-$(grep -E '^GRAFANA_ADMIN_PASSWORD=' "$UF_OBS_DIR/.env" | cut -d= -f2- || true)}"

echo "verify-labs: stack=$UF_OBS_DIR steady=${STEADY_SECONDS}s — the four stack-verified labs (the nightly's set)"

# The nightly's four, in nightly order. run_from=stack means validate.sh runs
# inside the checkout (it reads ./.env beside the stack); dojo means repo root.
run_group "up-dora" up-dora false \
  "stack|white-belt/module-02-dora-metrics/lab-01" \
  "dojo|white-belt/module-02-dora-metrics/lab-02" \
  "dojo|brown-belt/module-14-dora-deep-dive/lab-01"
run_group "up-full" up-full true \
  "dojo|brown-belt/module-13-observability/lab-01"

echo ""
if [ "$fail_count" -gt 0 ]; then
  echo "verify-labs: ${pass_count} passed, ${fail_count} FAILED" >&2
  exit 1
fi
echo "verify-labs: all ${pass_count} stack-verified labs passed"
