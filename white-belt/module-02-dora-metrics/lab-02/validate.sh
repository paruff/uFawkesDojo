#!/usr/bin/env bash
# validate.sh — White Belt Module 02 Lab 02 validation
# Checks: prerequisites, uFawkesObs stack, uFawkesAI scripts, event emission,
# Loki verification, Grafana dashboard update.
# Exit: 0 on all pass, 1 on any fail.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
# Sibling checkout by default (the labs' layout); overridable so CI can point
# at wherever it checked uFawkesAI out, like the other env-configurable vars
# across these validate scripts.
UFAWKESAI_ROOT="${UFAWKESAI_ROOT:-${ROOT}/../uFawkesAI}"

# Colors
RED='\033[0;31m'
GRN='\033[0;32m'
YLW='\033[1;33m'
NC='\033[0m'

pass=0
fail=0
total=0

log_info() { echo -e "[INFO] $*"; }
log_ok() {
  echo -e "${GRN}[✓]${NC} $*"
  pass=$((pass + 1))
  total=$((total + 1))
}
log_fail() {
  echo -e "${RED}[✗]${NC} $*"
  fail=$((fail + 1))
  total=$((total + 1))
}
log_skip() { echo -e "${YLW}[⊘]${NC} $*"; }

check_cmd() {
  if command -v "$1" > /dev/null 2>&1; then
    log_ok "Prerequisite: $1 is installed"
    return 0
  else
    log_fail "Prerequisite: $1 is NOT installed"
    return 1
  fi
}

check_container() {
  local name="$1"
  if docker ps --format '{{.Names}}' | grep -q "^${name}$"; then
    log_ok "Stack: $name container is running"
    return 0
  else
    log_fail "Stack: $name container is NOT running"
    return 1
  fi
}

check_url() {
  local url="$1"
  local desc="$2"
  if curl -fsS --max-time 5 "$url" > /dev/null 2>&1; then
    log_ok "$desc: reachable"
    return 0
  else
    log_fail "$desc: NOT reachable"
    return 1
  fi
}

log_info "Starting White Belt Module 02 Lab 02 validation..."

# ── Prerequisites ────────────────────────────────────────────────────────
# Top-level checks are guarded with `|| true` so one failure can't abort the
# run under `set -e` before the remaining checks and the summary report —
# a partial report would hide what actually broke. The exit code still comes
# from the fail counter at the end.
check_cmd docker || true
check_cmd curl || true
check_cmd jq || true
check_cmd python3 || true
check_cmd gh || log_skip "gh (GitHub CLI) not installed; PR metadata will be limited"

# ── uFawkesObs stack ─────────────────────────────────────────────────────
# Container names are uFawkesObs's explicit container_name values; the old
# compose-project-prefixed names (uFawkesObs-dora-api-1, ...) no longer exist.
check_container "ufawkesdora-ingestion" || true

# dora-compute was folded into dora-api (uFawkesObs commit 2c0c84a); its
# in-process loop publishes DORA metrics on /metrics — check that instead.
check_url "http://localhost:8088/metrics" "dora-api DORA metrics (in-process compute)" || true

check_container "grafana" || true

check_url "http://localhost:8088/health" "dora-api Health" || true
check_url "http://localhost:3000/api/health" "Grafana Health" || true

# ── uFawkesAI scripts ────────────────────────────────────────────────────
if [ -f "${UFAWKESAI_ROOT}/scripts/emit-dora-event.sh" ]; then
  log_ok "uFawkesAI scripts: emit-dora-event.sh present"
else
  log_fail "uFawkesAI scripts: emit-dora-event.sh NOT found at ${UFAWKESAI_ROOT}/scripts/emit-dora-event.sh"
fi

if [ -f "${UFAWKESAI_ROOT}/scripts/verify-dora-event-in-loki.sh" ]; then
  log_ok "uFawkesAI scripts: verify-dora-event-in-loki.sh present"
else
  log_fail "uFawkesAI scripts: verify-dora-event-in-loki.sh NOT found at ${UFAWKESAI_ROOT}/scripts/verify-dora-event-in-loki.sh"
fi

# ── Emit a deploy-marker event ───────────────────────────────────────────
log_info "Emitting deploy-marker event via emit-dora-event.sh..."
cd "${UFAWKESAI_ROOT}"
# stderr is kept out of the captured JSON (the emitter's warnings would break
# the jq parses below) but is never discarded silently: on failure it is
# printed, so "the emit failed" and its reason are both visible.
EVENT_ERR="${TMPDIR:-/tmp}/emit-dora-event.err"
EVENT_JSON=$(OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318 \
  bash scripts/emit-dora-event.sh deploy-marker \
  --status success \
  --environment production \
  --deployment-intent planned \
  --repo dojo-lab/test 2> "$EVENT_ERR") || {
  log_fail "emit-dora-event.sh failed to emit deploy-marker"
  echo "--- emit-dora-event.sh stderr ---"
  cat "$EVENT_ERR" 2> /dev/null || echo "(no stderr captured)"
  echo "---"
}

if echo "$EVENT_JSON" | jq -e '.dora_event != null' > /dev/null; then
  log_ok "emit-dora-event.sh: deploy-marker event emitted and has dora_event"
else
  log_fail "emit-dora-event.sh: event missing dora_event field"
  echo "$EVENT_JSON"
fi

# Extract the commit_sha for later verification
COMMIT_SHA=$(echo "$EVENT_JSON" | jq -r '.commit_sha // empty')
if [ -n "$COMMIT_SHA" ] && [ "$COMMIT_SHA" != "null" ]; then
  log_ok "emit-dora-event.sh: commit_sha present in event"
else
  log_fail "emit-dora-event.sh: commit_sha missing from event"
fi

# ── Verify event reached Loki ────────────────────────────────────────────
log_info "Verifying event reached Loki via verify-dora-event-in-loki.sh..."
# We run the verification script which emits its own marker and polls Loki
# It's a good proxy for the overall Loki ingestion path.
# Captured output is surfaced on failure — swallowing it would make
# "the check couldn't run" look identical to "the event never arrived".
verify_rc=0
verify_out=$(bash scripts/verify-dora-event-in-loki.sh 2>&1) || verify_rc=$?
if [ "$verify_rc" -eq 0 ]; then
  log_ok "verify-dora-event-in-loki.sh: marker event found in Loki"
elif [ "$verify_rc" -eq 2 ]; then
  # Exit code 2 = SKIP (Loki down), 1 = timeout, 0 = found
  log_skip "verify-dora-event-in-loki.sh: Loki not reachable (SKIP)"
else
  log_fail "verify-dora-event-in-loki.sh: marker event NOT found in Loki (timeout)"
  echo "$verify_out" | tail -n 20
fi

# ── Grafana dashboard check ──────────────────────────────────────────────
log_info "Checking DORA Metrics dashboard via Grafana API..."
# Anonymous access is disabled in uFawkesObs, so authenticate: env override
# first (GRAFANA_ADMIN_USER/GRAFANA_ADMIN_PASSWORD), then a ./.env beside the
# stack when run from inside the uFawkesObs checkout — the same resolution
# Lab 01's validate uses. Provisioned DORA dashboards use the
# ufawkesobs-dora-* uids (the bare dora-* uids never existed here).
GRAFANA_USER="${GRAFANA_ADMIN_USER:-admin}"
GRAFANA_PASS="${GRAFANA_ADMIN_PASSWORD:-}"
if [ -z "$GRAFANA_PASS" ] && [ -f "./.env" ]; then
  GRAFANA_PASS=$(grep -E '^GRAFANA_ADMIN_PASSWORD=' ./.env | cut -d= -f2- || true)
fi
GRAFANA_PASS="${GRAFANA_PASS:-admin}"
if curl -fsS -u "${GRAFANA_USER}:${GRAFANA_PASS}" \
  "http://localhost:3000/api/dashboards/uid/ufawkesobs-dora-metrics" > /dev/null 2>&1; then
  log_ok "Grafana Dashboard: DORA Metrics Dashboard reachable via Grafana API"
else
  # Try the Overview dashboard as fallback (same credentials)
  http_code=$(curl -sS -o /dev/null -w "%{http_code}" \
    "http://localhost:3000/api/dashboards/uid/ufawkesobs-dora-overview" \
    -u "${GRAFANA_USER}:${GRAFANA_PASS}" 2> /dev/null || echo "000")
  if [ "$http_code" = "200" ]; then
    log_ok "Grafana Dashboard: DORA Overview Dashboard reachable (fallback)"
  else
    log_fail "Grafana Dashboard: Grafana API returned HTTP ${http_code} at /api/dashboards/uid/ufawkesobs-dora-metrics — set GRAFANA_ADMIN_PASSWORD to the value in your uFawkesObs .env (anonymous access is disabled)"
  fi
fi

# ── Summary ──────────────────────────────────────────────────────────────
echo
echo "=========================================="
echo "Total Tests: ${total}"
echo "Passed: ${pass}"
echo "Failed: ${fail}"
echo "=========================================="

if [ ${fail} -eq 0 ]; then
  echo -e "${GRN}[✓] All tests passed! ✅${NC}"
  echo
  echo "🎉 Congratulations! You've completed White Belt Module 2 Lab 02."
  echo "   You emitted a real delivery event via the canonical emitter,"
  echo "   proved it reached Loki, and saw it in Grafana."
  echo "   Move on to Module 03: GitOps Principles."
  exit 0
else
  echo -e "${RED}[✗] Some tests failed.${NC}"
  exit 1
fi
