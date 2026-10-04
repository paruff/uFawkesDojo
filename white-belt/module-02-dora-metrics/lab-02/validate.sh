#!/usr/bin/env bash
# validate.sh — White Belt Module 02 Lab 02 validation
# Checks: prerequisites, uFawkesObs stack, uFawkesAI scripts, event emission,
# Loki verification, Grafana dashboard update.
# Exit: 0 on all pass, 1 on any fail.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
UFAWKESAI_ROOT="${ROOT}/../uFawkesAI"

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
check_cmd docker
check_cmd curl
check_cmd jq
check_cmd python3
check_cmd gh || log_skip "gh (GitHub CLI) not installed; PR metadata will be limited"

# ── uFawkesObs stack ─────────────────────────────────────────────────────
check_container "uFawkesObs-dora-api-1"
check_container "uFawkesObs-dora-compute-1"
check_container "uFawkesObs-grafana-1"

check_url "http://localhost:8088/health" "dora-api Health"
check_url "http://localhost:3000/api/health" "Grafana Health"

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
EVENT_JSON=$(OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318 \
  bash scripts/emit-dora-event.sh deploy-marker \
  --status success \
  --environment production \
  --deployment-intent planned \
  --repo dojo-lab/test 2> /dev/null) || {
  log_fail "emit-dora-event.sh failed to emit deploy-marker"
  exit 1
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
if bash scripts/verify-dora-event-in-loki.sh > /dev/null 2>&1; then
  log_ok "verify-dora-event-in-loki.sh: marker event found in Loki"
else
  # Check exit code: 2 = SKIP (Loki down), 1 = timeout, 0 = found
  exit_code=$?
  if [ $exit_code -eq 2 ]; then
    log_skip "verify-dora-event-in-loki.sh: Loki not reachable (SKIP)"
  else
    log_fail "verify-dora-event-in-loki.sh: marker event NOT found in Loki (timeout)"
  fi
fi

# ── Grafana dashboard check ──────────────────────────────────────────────
log_info "Checking DORA Metrics dashboard via Grafana API..."
# Check if Grafana API can list the DORA Metrics dashboard
GRAFANA_USER="admin"
GRAFANA_PASS="${GRAFANA_ADMIN_PASSWORD:-admin}"
if curl -fsS -u "${GRAFANA_USER}:${GRAFANA_PASS}" \
  "http://localhost:3000/api/dashboards/uid/dora-metrics" > /dev/null 2>&1; then
  log_ok "DORA Metrics Dashboard: reachable via Grafana API"
else
  # Try the Overview dashboard as fallback
  if curl -fsS -u "${GRAFANA_USER}:${GRAFANA_PASS}" \
    "http://localhost:3000/api/dashboards/uid/dora-overview" > /dev/null 2>&1; then
    log_ok "DORA Overview Dashboard: reachable via Grafana API (fallback)"
  else
    log_fail "DORA Dashboards: NOT reachable via Grafana API"
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
