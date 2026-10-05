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
UF_OBS_DIR="${UF_OBS_DIR:-~/dojo-labs/uFawkesObs}"

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
    record_test "Prerequisites" "FAIL" "Missing: ${missing[*]} — install jq (brew/apt), pip install cookiecutter"
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
      health=$(docker inspect --format '{{.State.Health.Status}}' "${container}" 2> /dev/null || echo "none")
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

check_prometheus_rules() {
  log_info "Checking Prometheus recording/alert rules..."

  local rules=(
    "sli-recording:SLI Recording Rules"
    "slo-recording:SLO Recording Rules"
    "error-budget:Error Budget Rules"
    "slo-alerts:SLO Alert Rules"
  )

  local all_pass=true
  for entry in "${rules[@]}"; do
    local name="${entry%%:*}"
    local label="${entry##*:}"

    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${PROMETHEUS_URL}/api/v1/rules" 2> /dev/null || echo "000")

    if [ "$http_code" = "200" ]; then
      local body
      body=$(curl -s --max-time 10 "${PROMETHEUS_URL}/api/v1/rules" 2> /dev/null || echo "")
      if echo "$body" | jq -e ".data.groups[] | select(.name == \"${name}\")" > /dev/null 2>&1; then
        record_test "$label" "PASS" "${label} loaded in Prometheus"
      else
        record_test "$label" "FAIL" "${label} not found in Prometheus rules"
        all_pass=false
      fi
    else
      record_test "$label" "FAIL" "Prometheus rules API returned HTTP $http_code"
      all_pass=false
    fi
  done

  if [ "$all_pass" = "true" ]; then
    record_test "Prometheus Rules" "PASS" "All rule groups loaded"
  fi
}

check_sli_recording() {
  log_info "Checking SLI recording rules..."

  local slis=(
    "sli:availability:1h"
    "sli:availability:7d"
    "sli:availability:30d"
    "sli:latency_p95:1h"
    "sli:payment-api:latency_p95:7d"
    "sli:payment-api:error_rate:7d"
  )

  local all_pass=true
  for sli in "${slis[@]}"; do
    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${PROMETHEUS_URL}/api/v1/query?query=${sli}" 2> /dev/null || echo "000")

    if [ "$http_code" = "200" ]; then
      local body
      body=$(curl -s --max-time 10 "${PROMETHEUS_URL}/api/v1/query?query=${sli}" 2> /dev/null || echo "")
      if echo "$body" | jq -e '.status == "success" and (.data.result | length > 0)' > /dev/null 2>&1; then
        log_success "  SLI $sli: recording active"
      else
        log_error "  $sli: no data returned"
        all_pass=false
      fi
    else
      log_error "  $sli: HTTP $http_code"
      all_pass=false
    fi
  done

  if [ "$all_pass" = "true" ]; then
    record_test "SLI Recording" "PASS" "All SLI recording rules producing data"
  else
    record_test "SLI Recording" "FAIL" "One or more SLI recording rules not producing data"
  fi
}

check_slo_recording() {
  log_info "Checking SLO recording rules..."

  local slos=(
    "slo:availability:30d"
    "slo:payment-api:availability:30d"
    "slo:payment-api:latency_p95:7d"
    "slo:payment-api:error_rate:30d"
  )

  local all_pass=true
  for slo in "${slos[@]}"; do
    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${PROMETHEUS_URL}/api/v1/query?query=${slo}" 2> /dev/null || echo "000")

    if [ "$http_code" = "200" ]; then
      local body
      body=$(curl -s --max-time 10 "${PROMETHEUS_URL}/api/v1/query?query=${slo}" 2> /dev/null || echo "")
      local value
      value=$(echo "$body" | jq -r '.data.result[0].value[1]' 2> /dev/null || echo "")
      if [ -n "$value" ] && [ "$value" != "null" ]; then
        log_success "  $slo: value = $value"
      else
        log_warning "  $slo: no value (may be 0 if SLO violated)"
      fi
    else
      log_error "  $slo: HTTP $http_code"
      all_pass=false
    fi
  done

  if [ "$all_pass" = "true" ]; then
    record_test "SLO Recording" "PASS" "All SLO recording rules producing values"
  else
    record_test "SLO Recording" "FAIL" "One or more SLO recording rules not producing values"
  fi
}

check_error_budget() {
  log_info "Checking error budget calculations..."

  local metrics=(
    "error_budget:availability:remaining_percent:30d"
    "error_budget:availability:burn_rate_1h"
    "error_budget:payment-api:availability:remaining_percent:30d"
    "error_budget:payment-api:availability:burn_rate_1h"
  )

  local all_pass=true
  for metric in "${metrics[@]}"; do
    local encoded
    encoded=$(echo "$metric" | jq -sRr @uri)
    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${PROMETHEUS_URL}/api/v1/query?query=${encoded}" 2> /dev/null || echo "000")

    if [ "$http_code" = "200" ]; then
      local body
      body=$(curl -s --max-time 10 "${PROMETHEUS_URL}/api/v1/query?query=${encoded}" 2> /dev/null || echo "")
      if echo "$body" | jq -e '.status == "success" and (.data.result | length > 0)' > /dev/null 2>&1; then
        local value
        value=$(echo "$body" | jq -r '.data.result[0].value[1]' 2> /dev/null || echo "0")
        log_success "  $metric: $value"
      else
        log_error "  $metric: no data returned"
        all_pass=false
      fi
    else
      log_error "  $metric: HTTP $http_code"
      all_pass=false
    fi
  done

  if [ "$all_pass" = "true" ]; then
    record_test "Error Budget Metrics" "PASS" "All error budget metrics queryable"
  else
    record_test "Error Budget Metrics" "FAIL" "One or more error budget metrics not queryable"
  fi
}

check_slo_alerts() {
  log_info "Checking SLO alert rules..."

  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${PROMETHEUS_URL}/api/v1/rules" 2> /dev/null || echo "000")

  if [ "$http_code" = "200" ]; then
    local body
    body=$(curl -s --max-time 10 "${PROMETHEUS_URL}/api/v1/rules" 2> /dev/null || echo "")

    local slo_alerts
    slo_alerts=$(echo "$body" | jq '.data.groups[] | select(.name | test("slo|burn")) | .rules | length' 2> /dev/null | awk '{sum+=$1} END {print sum}' || echo 0)

    if [ -n "$slo_alerts" ] && [ "$slo_alerts" -gt 0 ]; then
      record_test "SLO Alert Rules" "PASS" "Found $slo_alerts SLO/burn rate alert rules"
    else
      record_test "SLO Alert Rules" "FAIL" "No SLO/burn rate alert rules found"
    fi
  else
    record_test "SLO Alert Rules" "FAIL" "Could not fetch rules from Prometheus (HTTP $http_code)"
  fi
}

check_grafana_dashboard() {
  log_info "Checking Grafana SLO dashboard..."

  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${GRAFANA_URL}/api/search?query=slo" 2> /dev/null || echo "000")

  if [ "$http_code" = "200" ]; then
    local body
    body=$(curl -s --max-time 10 "${GRAFANA_URL}/api/search?query=slo" 2> /dev/null || echo "[]")
    local count
    count=$(echo "$body" | jq 'length' 2> /dev/null || echo 0)

    if [ "$count" -ge 1 ]; then
      record_test "Grafana SLO Dashboard" "PASS" "Found $count SLO dashboard(s)"
    else
      record_test "Grafana SLO Dashboard" "FAIL" "No SLO dashboards found — import dashboard from lab"
    fi
  else
    record_test "Grafana SLO Dashboard" "FAIL" "Grafana API returned HTTP $http_code"
  fi
}

check_promql_queries() {
  log_info "Testing DORA/SLO PromQL queries..."

  local queries=(
    "sli:availability:30d"
    "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))"
    "dora_change_failure_rate"
    "dora_deployment_frequency"
    "dora_lead_time_seconds"
  )

  local all_pass=true
  for query in "${queries[@]}"; do
    local encoded
    encoded=$(echo "$query" | jq -sRr @uri)
    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${PROMETHEUS_URL}/api/v1/query?query=${encoded}" 2> /dev/null || echo "000")

    if [ "$http_code" = "200" ]; then
      log_success "  PromQL OK: $query"
    else
      log_error "  PromQL FAILED: $query (HTTP $http_code)"
      all_pass=false
    fi
  done

  if [ "$all_pass" = "true" ]; then
    record_test "PromQL Queries" "PASS" "All DORA/SLO PromQL queries successful"
  else
    record_test "PromQL Queries" "FAIL" "One or more PromQL queries failed"
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
    echo "🎉 Congratulations! You've completed Brown Belt Module 15 Lab 01."
    echo "   You've implemented SLIs, SLOs, Error Budgets with uFawkesObs."
    echo "   You're ready for the Brown Belt Assessment!"
    return 0
  else
    log_error "Some tests failed! ❌"
    echo ""
    echo "Please review the failures above. Common fixes:"
    echo "  - Run 'make up' in uFawkesObs if services aren't healthy"
    echo "  - Re-run cookiecutter and customize .fawkespipe.yml with SLO config"
    echo "  - Push to Git to trigger pipeline: git push origin main"
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
  check_prometheus_rules
  check_sli_recording
  check_slo_recording
  check_error_budget
  check_slo_alerts
  check_grafana_dashboard
  check_promql_queries

  print_summary
}

main "$@"
