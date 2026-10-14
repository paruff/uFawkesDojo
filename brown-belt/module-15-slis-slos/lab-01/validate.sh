#!/bin/bash
# =============================================================================
# Script: validate.sh
# Purpose: Validate Brown Belt Module 15 Lab 01 completion criteria
# Usage:   Run from uFawkesDojo repo root:
#            bash brown-belt/module-15-slis-slos/lab-01/validate.sh
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
ALERTMANAGER_URL="${ALERTMANAGER_URL:-http://localhost:9093}"
UF_OBS_DIR="${UF_OBS_DIR:-$HOME/dojo-labs/uFawkesObs}"

# --stack-only: the nightly Live Acceptance tier (#73). Checks the stack and
# the metric the lab's SLIs are built on, and skips everything the student
# creates (rules, alerts, dashboard). It is not a pass for the lab: the
# success text says so.
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
  for cmd in curl jq git make; do
    if ! check_command "$cmd"; then
      missing+=("$cmd")
    fi
  done

  if [ ${#missing[@]} -eq 0 ]; then
    record_test "Prerequisites" "PASS" "curl, jq, git, make installed"
  else
    record_test "Prerequisites" "FAIL" "Missing: ${missing[*]} — install jq (brew install jq / apt install jq)"
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

prom_value() {
  # First sample of an instant query, or empty. Logs the failure instead of hiding it.
  local out
  if ! out=$(curl -s --max-time 10 --data-urlencode "query=$1" "${PROMETHEUS_URL}/api/v1/query" 2>&1); then
    log_warning "Prometheus query failed to run: $1 ($out)"
    return 0
  fi
  echo "$out" | jq -r '.data.result[0].value[1] // empty' 2>&1 || log_warning "Could not parse the reply to: $1"
}

# The lab's SLIs are ratios of this Grafana metric; if the stack stops
# exporting it the lab cannot work, whatever the student writes.
check_sli_source_metric() {
  log_info "Checking the metric the SLIs are built on exists..."
  local n
  n=$(prom_value 'count(grafana_http_request_duration_seconds_count)')
  if [ -n "$n" ] && [ "${n%%.*}" -gt 0 ] 2> /dev/null; then
    record_test "SLI Source Metric" "PASS" "grafana_http_request_duration_seconds_count has $n series"
  else
    record_test "SLI Source Metric" "FAIL" "grafana_http_request_duration_seconds_count missing (got '${n}') — is Prometheus scraping Grafana?"
  fi
}

check_rules_loaded() {
  log_info "Checking the SLO rule groups are loaded in Prometheus..."

  local groups missing=()
  groups=$(curl -s --max-time 10 "${PROMETHEUS_URL}/api/v1/rules" 2>&1 | jq -r '.data.groups[].name' 2>&1 || true)
  for g in dojo-sli-recording dojo-slo-error-budget dojo-slo-alerts; do
    echo "$groups" | grep -qx "$g" || missing+=("$g")
  done

  if [ ${#missing[@]} -eq 0 ]; then
    record_test "SLO Rules" "PASS" "dojo-sli-recording, dojo-slo-error-budget and dojo-slo-alerts are loaded"
  else
    record_test "SLO Rules" "FAIL" "Missing rule groups: ${missing[*]} — is dojo-slo-rules.yml listed under rule_files, and did you reload Prometheus?"
  fi
}

check_sli_recording() {
  log_info "Checking the SLI recording rules produce values..."

  local avail latency
  avail=$(prom_value 'sli:grafana_api:availability:ratio_5m')
  latency=$(prom_value 'sli:grafana_api:latency_500ms:ratio_5m')

  if [ -n "$avail" ] && [ -n "$latency" ]; then
    record_test "SLI Recording" "PASS" "availability=$avail latency_500ms=$latency"
  else
    record_test "SLI Recording" "FAIL" "No SLI value yet — send traffic (Step 2.3) and wait about a minute"
  fi
}

check_error_budget() {
  log_info "Checking the error budget rules produce values..."

  local target burn
  target=$(prom_value 'slo:grafana_api:availability:target')
  burn=$(prom_value 'error_budget:grafana_api:availability:burn_rate_1h')

  if [ "$target" = "0.995" ] && [ -n "$burn" ]; then
    record_test "Error Budget" "PASS" "target=$target burn_rate_1h=$burn"
  else
    record_test "Error Budget" "FAIL" "target='${target}' burn_rate_1h='${burn}' — expected target 0.995 and a burn rate"
  fi
}

check_slo_alerts() {
  log_info "Checking the burn rate alerts are loaded..."

  local names
  names=$(curl -s --max-time 10 "${PROMETHEUS_URL}/api/v1/rules?type=alert" 2>&1 | jq -r '.data.groups[].rules[].name' 2>&1 || true)

  if echo "$names" | grep -qx "DojoAvailabilityFastBurn" && echo "$names" | grep -qx "DojoAvailabilitySlowBurn"; then
    record_test "SLO Alerts" "PASS" "DojoAvailabilityFastBurn and DojoAvailabilitySlowBurn are loaded"
  else
    record_test "SLO Alerts" "FAIL" "Burn rate alerts not found — check dojo-slo-rules.yml and reload Prometheus"
  fi
}

check_grafana_dashboard() {
  log_info "Checking the Grafana SLO dashboard..."

  local user pass body obs_dir
  user="${GRAFANA_USER:-admin}"
  pass="${GRAFANA_PASSWORD:-}"
  obs_dir="${UF_OBS_DIR/#\~/$HOME}"
  if [ -z "$pass" ] && [ -f "$obs_dir/.env" ]; then
    pass=$(grep -E '^GRAFANA_ADMIN_PASSWORD=' "$obs_dir/.env" | cut -d= -f2- || true)
  fi
  if [ -z "$pass" ]; then
    record_test "Grafana SLO Dashboard" "FAIL" "No Grafana password: set GRAFANA_PASSWORD, or point UF_OBS_DIR at your uFawkesObs checkout"
    return
  fi

  body=$(curl -s --max-time 10 -u "${user}:${pass}" "${GRAFANA_URL}/api/dashboards/uid/dojo-slo-grafana-api" 2>&1 || true)
  local panels
  panels=$(echo "$body" | jq -r '.dashboard.panels | length' 2>&1 || echo 0)

  if [ "$panels" = "6" ]; then
    record_test "Grafana SLO Dashboard" "PASS" "dojo-slo-grafana-api has 6 panels"
  else
    record_test "Grafana SLO Dashboard" "FAIL" "Dashboard dojo-slo-grafana-api not found with 6 panels (got '${panels}') — import it in Step 6"
  fi
}

print_summary() {
  echo ""
  echo "=========================================="
  echo "Brown Belt Module 15 Lab 01 — Results"
  echo "=========================================="
  echo "Total Tests : $TOTAL_TESTS"
  echo "Passed      : $PASSED_TESTS"
  echo "Failed      : $FAILED_TESTS"
  echo ""

  if [ "$FAILED_TESTS" -eq 0 ]; then
    log_success "All tests passed! ✅"
    echo ""
    if [ "$STACK_ONLY" = "true" ]; then
      echo "Stack-only tier passed. The student-created checks were not run, so this is not a lab pass."
      return 0
    fi
    echo "🎉 Congratulations! You've completed Brown Belt Module 15 Lab 01."
    echo "   You've implemented SLIs, SLOs, Error Budgets with uFawkesObs."
    echo "   You're ready for the Brown Belt Assessment!"
    return 0
  else
    log_error "Some tests failed! ❌"
    echo ""
    echo "Please review the failures above. Common fixes:"
    echo "  - Run 'make up' in uFawkesObs if services aren't healthy"
    echo "  - Confirm dojo-slo-rules.yml is listed under rule_files, then reload Prometheus"
    echo "  - Send traffic (Step 2.3) so the SLI rules have data"
    echo "  - Check Grafana dashboard: http://localhost:3000"
    echo "  - See lab-01/instructions.md Troubleshooting for more"
    return 1
  fi
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
  log_info "Starting Brown Belt Module 15 Lab 01 validation..."
  log_info "uFawkesObs dir: $UF_OBS_DIR"
  log_info "Prometheus URL : $PROMETHEUS_URL"
  log_info "Grafana URL    : $GRAFANA_URL"
  log_info "Alertmanager   : $ALERTMANAGER_URL"
  echo ""

  check_prerequisites
  check_ufobs_services
  check_sli_source_metric
  if [ "$STACK_ONLY" = "true" ]; then
    log_info "Skipping the rules, alerts and dashboard checks (--stack-only)"
  else
    check_rules_loaded
    check_sli_recording
    check_error_budget
    check_slo_alerts
    check_grafana_dashboard
  fi

  print_summary
}

main "$@"
