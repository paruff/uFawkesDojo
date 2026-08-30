#!/bin/bash
# =============================================================================
# Script: validate.sh
# Purpose: Validate White Belt Module 02 Lab 01 completion criteria
# Usage:   Run from inside a local uFawkesObs checkout (so a sibling ./.env
#          can be read for Grafana credentials):
#            bash /path/to/uFawkesDojo/white-belt/module-02-dora-metrics/lab-01/validate.sh
# Exit Codes: 0=all checks passed, 1=one or more checks failed
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DORA_API_URL="${DORA_API_URL:-http://localhost:8088}"
GRAFANA_URL="${GRAFANA_URL:-http://localhost:3000}"

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[!]${NC} $1"; }

record_test() {
  local test_name="$1" status="$2" message="$3"
  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  if [ "$status" = "PASS" ]; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
    log_success "$test_name: $message"
  else
    FAILED_TESTS=$((FAILED_TESTS + 1))
    log_error "$test_name: $message"
  fi
}

check_prerequisites() {
  log_info "Checking prerequisites..."
  if command -v docker >/dev/null 2>&1 && command -v curl >/dev/null 2>&1; then
    record_test "Prerequisites" "PASS" "docker and curl are installed"
  else
    record_test "Prerequisites" "FAIL" \
      "docker and/or curl not found — install Docker Desktop"
  fi
}

check_container_running() {
  local label="$1" container_name="$2"
  if docker ps --filter "name=^${container_name}\$" --filter "status=running" \
      --format '{{.Names}}' 2>/dev/null | grep -q "^${container_name}\$"; then
    record_test "Stack" "PASS" "$label container ($container_name) is running"
  else
    record_test "Stack" "FAIL" \
      "$label container ($container_name) is not running — run: make up-dora"
  fi
}

check_dora_api_health() {
  log_info "Checking dora-api health..."
  local body http_code
  http_code=$(curl -s -o /tmp/dora-health-body -w "%{http_code}" \
    --max-time 5 "${DORA_API_URL}/health" 2>/dev/null || echo "000")
  body=$(cat /tmp/dora-health-body 2>/dev/null || echo "")
  rm -f /tmp/dora-health-body

  if [ "$http_code" = "200" ] && echo "$body" | grep -q "queue_depth"; then
    record_test "dora-api Health" "PASS" "reachable at ${DORA_API_URL}, response: $body"
  else
    record_test "dora-api Health" "FAIL" \
      "dora-api returned HTTP $http_code at ${DORA_API_URL}/health (expected 200 with queue_depth)"
  fi
}

check_grafana_health() {
  log_info "Checking Grafana health..."
  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" \
    --max-time 5 "${GRAFANA_URL}/api/health" 2>/dev/null || echo "000")

  if [ "$http_code" = "200" ]; then
    record_test "Grafana Health" "PASS" "reachable at ${GRAFANA_URL}"
  else
    record_test "Grafana Health" "FAIL" \
      "Grafana returned HTTP $http_code at ${GRAFANA_URL}/api/health — ensure 'make up-dora' finished"
  fi
}

# Dashboard checks need Grafana auth (anonymous access is disabled by
# design in uFawkesObs — see SECURITY.md). Read credentials from a
# sibling .env if this script is run from inside the uFawkesObs checkout,
# as the lab instructions direct. If .env can't be found, skip these two
# checks with a loud warning rather than silently reporting them as
# passed — per this repo's own AGENTS.md rule against swallowed failures.
load_grafana_credentials() {
  if [ -f "./.env" ]; then
    GRAFANA_USER=$(grep -E '^GRAFANA_ADMIN_USER=' ./.env | cut -d= -f2- || true)
    GRAFANA_PASS=$(grep -E '^GRAFANA_ADMIN_PASSWORD=' ./.env | cut -d= -f2- || true)
  fi
  GRAFANA_USER="${GRAFANA_USER:-}"
  GRAFANA_PASS="${GRAFANA_PASS:-}"
}

check_dashboard() {
  local label="$1" uid="$2"

  if [ -z "$GRAFANA_USER" ] || [ -z "$GRAFANA_PASS" ]; then
    log_warning "$label Dashboard: skipped — no ./.env found with Grafana credentials. Run this script from inside your uFawkesObs checkout (see instructions.md Step 5)."
    return
  fi

  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 \
    -u "${GRAFANA_USER}:${GRAFANA_PASS}" \
    "${GRAFANA_URL}/api/dashboards/uid/${uid}" 2>/dev/null || echo "000")

  if [ "$http_code" = "200" ]; then
    record_test "$label Dashboard" "PASS" "reachable via Grafana API (uid=${uid})"
  else
    record_test "$label Dashboard" "FAIL" \
      "Grafana API returned HTTP $http_code for uid=${uid} — check credentials and that provisioning succeeded"
  fi
}

print_summary() {
  echo ""
  echo "=========================================="
  echo "White Belt Module 02 Lab 01 — Results"
  echo "=========================================="
  echo "Total Tests : $TOTAL_TESTS"
  echo "Passed      : $PASSED_TESTS"
  echo "Failed      : $FAILED_TESTS"
  echo ""

  if [ "$FAILED_TESTS" -eq 0 ]; then
    log_success "All tests passed! ✅"
    echo ""
    echo "🎉 Congratulations! You've completed White Belt Module 2 Lab 01."
    echo "   You've seen real DORA metrics move because of events you sent yourself."
    echo "   Move on to Module 03: GitOps Principles."
    return 0
  else
    log_error "Some tests failed! ❌"
    echo ""
    echo "Please review the failures above. Common fixes:"
    echo "  - Run 'make up-dora' from your uFawkesObs checkout if the stack isn't up"
    echo "  - Run this script from inside that checkout so ./.env can be read"
    echo "  - See lab-01/instructions.md Troubleshooting for more"
    return 1
  fi
}

main() {
  log_info "Starting White Belt Module 02 Lab 01 validation..."
  log_info "dora-api URL : $DORA_API_URL"
  log_info "Grafana URL  : $GRAFANA_URL"
  echo ""

  check_prerequisites
  check_container_running "dora-api" "ufawkesdora-ingestion"
  check_container_running "dora-compute" "ufawkesdora-compute"
  check_container_running "grafana" "grafana"
  check_dora_api_health
  check_grafana_health

  load_grafana_credentials
  check_dashboard "DORA Overview" "ufawkesobs-dora-overview"
  check_dashboard "DORA Metrics" "ufawkesobs-dora-metrics"

  print_summary
}

main "$@"
