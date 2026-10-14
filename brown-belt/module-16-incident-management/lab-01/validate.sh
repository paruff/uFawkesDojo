#!/bin/bash
# =============================================================================
# Script: validate.sh
# Purpose: Validate Brown Belt Module 16 Lab 01 completion criteria
# Usage:   Run from uFawkesDojo repo root:
#            bash brown-belt/module-16-incident-management/lab-01/validate.sh
# Exit Codes: 0=all checks passed, 1=one or more checks failed
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROMETHEUS_URL="${PROMETHEUS_URL:-http://localhost:9090}"
GRAFANA_URL="${GRAFANA_URL:-http://localhost:3000}"
LOKI_URL="${LOKI_URL:-http://localhost:3100}"
TEMPO_URL="${TEMPO_URL:-http://localhost:3200}"
ALERTMANAGER_URL="${ALERTMANAGER_URL:-http://localhost:9093}"
OTEL_URL="${OTEL_URL:-http://localhost:8888}"
UF_OBS_DIR="${UF_OBS_DIR:-$HOME/dojo-labs/uFawkesObs}"

# --stack-only: the nightly Live Acceptance tier (#73). Runs the checks that
# need only the stack and skips the one that needs the student's own artifact
# (the postmortem). It is not a pass for the lab: the success text says so.
STACK_ONLY=false
if [ "${1:-}" = "--stack-only" ]; then
  STACK_ONLY=true
elif [ -n "${1:-}" ]; then
  echo "unknown argument: $1 (only --stack-only is accepted)" >&2
  exit 2
fi

# Test results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# =============================================================================
# Helper Functions
# =============================================================================

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

check_command() {
  command -v "$1" > /dev/null 2>&1
}

# =============================================================================
# Check Functions
# =============================================================================

check_prerequisites() {
  log_info "Checking prerequisites..."

  local missing=()
  for cmd in curl jq git make docker; do
    if ! check_command "$cmd"; then
      missing+=("$cmd")
    fi
  done

  if [ ${#missing[@]} -eq 0 ]; then
    record_test "Prerequisites" "PASS" "curl, jq, git, make, docker installed"
  else
    record_test "Prerequisites" "FAIL" "Missing: ${missing[*]} — install missing tools"
  fi
}

check_ufobs_services() {
  log_info "Checking uFawkesObs service health..."

  local services=(
    "prometheus:Prometheus"
    "grafana:Grafana"
    "loki:Loki"
    "tempo:Tempo"
    "alertmanager:Alertmanager"
    "alloy:Alloy"
    "otel-collector:OTel Collector"
    "node-exporter:Node Exporter"
  )

  local all_healthy=true
  for entry in "${services[@]}"; do
    local container="${entry%%:*}"
    local label="${entry##*:}"

    if docker ps --filter "name=^${container}$" --filter "status=running" --format '{{.Names}}' 2> /dev/null | grep -q "^${container}$"; then
      local health
      health=$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "${container}" 2> /dev/null || echo "none")
      if [ "$health" = "healthy" ] || [ "$health" = "none" ]; then
        log_success "  $label ($container): running${health:+ (health: $health)}"
      else
        log_error "  $label ($container): health=$health"
        all_healthy=false
      fi
    else
      log_error "  $label ($container): not running"
      all_healthy=false
    fi
  done

  if [ "$all_healthy" = "true" ]; then
    record_test "uFawkesObs Stack" "PASS" "All 8 core services healthy"
  else
    record_test "uFawkesObs Stack" "FAIL" "One or more services not healthy — run 'make status' in uFawkesObs"
  fi
}

check_alert_pipeline() {
  log_info "Checking the alert pipeline (the ServiceDown rule and Alertmanager)..."

  local rules am_code
  rules=$(curl -s --max-time 10 "${PROMETHEUS_URL}/api/v1/rules?type=alert" 2>&1 | jq -r '.data.groups[].rules[].name' 2>&1 || true)
  am_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${ALERTMANAGER_URL}/api/v2/status" 2>&1 || echo "000")

  if echo "$rules" | grep -qx "ServiceDown" && [ "$am_code" = "200" ]; then
    record_test "Alert Pipeline" "PASS" "ServiceDown rule is loaded and Alertmanager answers"
  else
    record_test "Alert Pipeline" "FAIL" "ServiceDown loaded? $(echo "$rules" | grep -cx ServiceDown); Alertmanager HTTP $am_code"
  fi
}

check_grafana_datasources() {
  log_info "Checking Grafana datasources..."

  local user pass obs_dir body
  user="${GRAFANA_USER:-admin}"
  pass="${GRAFANA_PASSWORD:-}"
  obs_dir="${UF_OBS_DIR/#\~/$HOME}"
  if [ -z "$pass" ] && [ -f "$obs_dir/.env" ]; then
    pass=$(grep -E '^GRAFANA_ADMIN_PASSWORD=' "$obs_dir/.env" | cut -d= -f2- || true)
  fi
  if [ -z "$pass" ]; then
    record_test "Grafana Datasources" "FAIL" "No Grafana password: set GRAFANA_PASSWORD, or point UF_OBS_DIR at your uFawkesObs checkout"
    return
  fi

  body=$(curl -s --max-time 10 -u "${user}:${pass}" "${GRAFANA_URL}/api/datasources" 2>&1 || true)
  local missing=()
  for ds in Prometheus Loki Tempo Alertmanager; do
    echo "$body" | jq -e ".[] | select(.name == \"$ds\")" > /dev/null 2>&1 || missing+=("$ds")
  done

  if [ ${#missing[@]} -eq 0 ]; then
    record_test "Grafana Datasources" "PASS" "Prometheus, Loki, Tempo and Alertmanager are configured"
  else
    record_test "Grafana Datasources" "FAIL" "Missing datasources: ${missing[*]}"
  fi
}

check_loki_logs() {
  log_info "Checking Loki holds the node-exporter container's logs..."

  local count
  count=$(curl -s --max-time 15 -G "${LOKI_URL}/loki/api/v1/query" \
    --data-urlencode 'query=sum(count_over_time({container="/node-exporter"}[24h]))' 2>&1 \
    | jq -r '.data.result[0].value[1] // 0' 2>&1 || echo 0)

  if [ "${count%%.*}" -gt 0 ] 2> /dev/null; then
    record_test "Loki Logs" "PASS" "$count node-exporter log lines in the last 24h"
  else
    record_test "Loki Logs" "FAIL" "No node-exporter logs in Loki (got '${count}') — is Alloy running? docker compose logs alloy"
  fi
}

check_tempo_reachable() {
  log_info "Checking Tempo answers a trace search..."

  local code
  code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${TEMPO_URL}/api/search?limit=1" 2>&1 || echo "000")

  if [ "$code" = "200" ]; then
    record_test "Tempo" "PASS" "trace search answers (it may well return no traces: see Step 3.3)"
  else
    record_test "Tempo" "FAIL" "Tempo search returned HTTP $code"
  fi
}

check_service_restored() {
  log_info "Checking the node-exporter scrape target is back up..."

  local up
  up=$(curl -s --max-time 10 -G "${PROMETHEUS_URL}/api/v1/query" --data-urlencode 'query=up{job="node-exporter"}' 2>&1 \
    | jq -r '.data.result[0].value[1] // empty' 2>&1 || true)

  if [ "$up" = "1" ]; then
    record_test "Service Restored" "PASS" "up{job=\"node-exporter\"} = 1"
  else
    record_test "Service Restored" "FAIL" "up{job=\"node-exporter\"} = '${up}' — finish Step 4 (docker compose start node-exporter)"
  fi
}

check_postmortem_exists() {
  log_info "Checking for the postmortem document..."

  local pm_file
  pm_file=$(ls -t ~/dojo-labs/postmortem-*.md 2> /dev/null | head -1 || true)

  if [ -z "$pm_file" ] || [ ! -f "$pm_file" ]; then
    record_test "Postmortem Document" "FAIL" "No postmortem file found in ~/dojo-labs/ (Step 5)"
    return
  fi

  local sections=0 section
  for section in "Timeline" "Root Cause" "What Went Well" "What Went Wrong" "Action Items" "Lessons Learned"; do
    if grep -qi "$section" "$pm_file"; then
      sections=$((sections + 1))
    fi
  done

  local leftovers
  leftovers=$(grep -c '<fill in' "$pm_file" || true)

  if [ "$sections" -eq 6 ] && [ "$leftovers" -eq 0 ]; then
    record_test "Postmortem Document" "PASS" "$(basename "$pm_file") has all 6 sections and no '<fill in' placeholders left"
  else
    record_test "Postmortem Document" "FAIL" "$(basename "$pm_file"): $sections/6 sections, $leftovers '<fill in' placeholders left"
  fi
}

print_summary() {
  echo ""
  echo "=========================================="
  echo "Brown Belt Module 16 Lab 01 — Results"
  echo "=========================================="
  echo "Total Tests : $TOTAL_TESTS"
  echo "Passed      : $PASSED_TESTS"
  echo "Failed      : $FAILED_TESTS"
  echo ""

  if [ "$FAILED_TESTS" -eq 0 ]; then
    log_success "All tests passed! ✅"
    echo ""
    if [ "$STACK_ONLY" = "true" ]; then
      echo "Stack-only tier passed. The postmortem was not checked, so this is not a lab pass."
      return 0
    fi
    echo "🎉 Congratulations! You've completed Brown Belt Module 16 Lab 01."
    echo "   You've executed a full incident response lifecycle with uFawkesObs."
    echo "   Brown Belt Complete! 🎉"
    return 0
  else
    log_error "Some tests failed! ❌"
    echo ""
    echo "Please review the failures above. Common fixes:"
    echo "  - Run 'make status' in uFawkesObs if services aren't healthy"
    echo "  - Finish the incident: restart what you stopped (Step 4) and write the postmortem (Step 5)"
    echo "  - Check Grafana dashboards: http://localhost:3000"
    echo "  - Check Loki/Tempo/Prometheus: docker compose logs <service>"
    echo "  - See lab-01/instructions.md Troubleshooting for more"
    return 1
  fi
}

# =============================================================================
# =============================================================================
# Main Execution
# =============================================================================

main() {
  log_info "Starting Brown Belt Module 16 Lab 01 validation..."
  log_info "uFawkesObs dir: $UF_OBS_DIR"
  log_info "Prometheus URL : $PROMETHEUS_URL"
  log_info "Grafana URL    : $GRAFANA_URL"
  log_info "Loki URL       : $LOKI_URL"
  log_info "Tempo URL      : $TEMPO_URL"
  log_info "Alertmanager   : $ALERTMANAGER_URL"
  echo ""

  check_prerequisites
  check_ufobs_services
  check_alert_pipeline
  check_grafana_datasources
  check_loki_logs
  check_tempo_reachable
  check_service_restored
  if [ "$STACK_ONLY" = "true" ]; then
    log_info "Skipping the postmortem check (--stack-only)"
  else
    check_postmortem_exists
  fi

  print_summary
}

main "$@"
