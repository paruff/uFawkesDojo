#!/bin/bash
# =============================================================================
# Script: validate.sh
# Purpose: Validate Brown Belt Module 13 Lab 01 completion criteria
# Usage:   Run from uFawkesDojo repo root:
#            bash brown-belt/module-13-observability/lab-01/validate.sh
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
    record_test "uFawkesObs Stack" "PASS" "All 8 services healthy (prometheus, grafana, loki, tempo, alertmanager, alloy, otel-collector, node-exporter)"
  else
    record_test "uFawkesObs Stack" "FAIL" "One or more services not healthy — run 'make status' in uFawkesObs"
  fi
}

check_grafana_datasources() {
  log_info "Checking Grafana datasources..."

  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${GRAFANA_URL}/api/datasources" 2> /dev/null || echo "000")

  if [ "$http_code" = "200" ]; then
    local body
    body=$(curl -s --max-time 10 "${GRAFANA_URL}/api/datasources" 2> /dev/null || echo "[]")

    local required=("Prometheus" "Loki" "Tempo" "Alertmanager")
    local missing=()

    for ds in "${required[@]}"; do
      if ! echo "$body" | jq -e ".[] | select(.name == \"$ds\")" > /dev/null 2>&1; then
        missing+=("$ds")
      fi
    done

    if [ ${#missing[@]} -eq 0 ]; then
      record_test "Grafana Datasources" "PASS" "All 4 required datasources configured (Prometheus, Loki, Tempo, Alertmanager)"
    else
      record_test "Grafana Datasources" "FAIL" "Missing datasources: ${missing[*]}"
    fi
  else
    record_test "Grafana Datasources" "FAIL" "Grafana API returned HTTP $http_code at ${GRAFANA_URL}/api/datasources"
  fi
}

check_prometheus_metrics() {
  log_info "Checking Prometheus metrics query..."

  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${PROMETHEUS_URL}/api/v1/query?query=up" 2> /dev/null || echo "000")

  if [ "$http_code" = "200" ]; then
    local body
    body=$(curl -s --max-time 10 "${PROMETHEUS_URL}/api/v1/query?query=up" 2> /dev/null || echo "")

    if echo "$body" | jq -e '.status == "success"' > /dev/null 2>&1; then
      local count
      count=$(echo "$body" | jq '.data.result | length' 2> /dev/null || echo 0)
      record_test "Prometheus Metrics" "PASS" "Query successful, $count targets found"
    else
      record_test "Prometheus Metrics" "FAIL" "Query failed or returned error"
    fi
  else
    record_test "Prometheus Metrics" "FAIL" "Prometheus API returned HTTP $http_code"
  fi
}

check_loki_logs() {
  log_info "Checking Loki log queries..."

  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${LOKI_URL}/loki/api/v1/query?query={compose_project%21%3D%22%22}" 2> /dev/null || echo "000")

  if [ "$http_code" = "200" ]; then
    local body
    body=$(curl -s --max-time 10 "${LOKI_URL}/loki/api/v1/query?query={compose_project%21%3D%22%22}" 2> /dev/null || echo "")

    if echo "$body" | jq -e '.status == "success"' > /dev/null 2>&1; then
      record_test "Loki Logs" "PASS" "LogQL query successful"
    else
      record_test "Loki Logs" "FAIL" "LogQL query failed or returned error"
    fi
  else
    record_test "Loki Logs" "FAIL" "Loki API returned HTTP $http_code"
  fi
}

check_tempo_traces() {
  log_info "Checking Tempo trace queries..."

  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${TEMPO_URL}/api/search?q={service.name%3D%22telemetry-generator%22}" 2> /dev/null || echo "000")

  if [ "$http_code" = "200" ]; then
    local body
    body=$(curl -s --max-time 10 "${TEMPO_URL}/api/search?q={service.name%3D%22telemetry-generator%22}" 2> /dev/null || echo "")

    if echo "$body" | jq -e '.traces | length > 0' > /dev/null 2>&1; then
      record_test "Tempo Traces" "PASS" "Found traces for telemetry-generator"
    else
      record_test "Tempo Traces" "FAIL" "No traces found for telemetry-generator"
    fi
  else
    record_test "Tempo Traces" "FAIL" "Tempo API returned HTTP $http_code"
  fi
}

check_alerting() {
  log_info "Checking alerting configuration..."

  # Check Prometheus rules loaded
  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${PROMETHEUS_URL}/api/v1/rules" 2> /dev/null || echo "000")

  if [ "$http_code" = "200" ]; then
    local body
    body=$(curl -s --max-time 10 "${PROMETHEUS_URL}/api/v1/rules" 2> /dev/null || echo "")

    local rule_count
    rule_count=$(echo "$body" | jq '.data.groups[].rules | length' 2> /dev/null | awk '{sum+=$1} END {print sum}')

    if [ -n "$rule_count" ] && [ "$rule_count" -gt 0 ]; then
      record_test "Prometheus Rules" "PASS" "Found $rule_count alerting rules loaded"
    else
      record_test "Prometheus Rules" "FAIL" "No alerting rules found"
    fi
  else
    record_test "Prometheus Rules" "FAIL" "Could not fetch rules from Prometheus"
  fi

  # Check Alertmanager
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${ALERTMANAGER_URL}/api/v2/status" 2> /dev/null || echo "000")

  if [ "$http_code" = "200" ]; then
    record_test "Alertmanager" "PASS" "Alertmanager API reachable"
  else
    record_test "Alertmanager" "FAIL" "Alertmanager returned HTTP $http_code"
  fi
}

check_dora_profile() {
  log_info "Checking DORA metrics profile..."

  # Check if DORA services are running
  local dora_services=(
    "dora-api:DORA API"
    "dora-compute:DORA Compute"
    "pushgateway:Pushgateway"
  )

  local all_healthy=true
  for entry in "${dora_services[@]}"; do
    local container="${entry%%:*}"
    local label="${entry##*:}"

    if docker ps --filter "name=^${container}$" --filter "status=running" --format '{{.Names}}' 2> /dev/null | grep -q "^${container}$"; then
      log_success "  $label ($container): running"
    else
      log_warning "  $label ($container): not running (DORA profile may not be enabled)"
      all_healthy=false
    fi
  done

  if [ "$all_healthy" = "true" ]; then
    # Try to query DORA API
    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "http://localhost:8088/health" 2> /dev/null || echo "000")

    if [ "$http_code" = "200" ]; then
      record_test "DORA Profile" "PASS" "DORA services running and API healthy"
    else
      record_test "DORA Profile" "WARN" "DORA services running but API health check failed (HTTP $http_code)"
    fi
  else
    record_test "DORA Profile" "FAIL" "DORA services not running — enable with 'make up-dora'"
  fi
}

check_promql_query() {
  log_info "Testing PromQL query capability..."

  local test_queries=(
    "up"
    "rate(container_cpu_usage_seconds_total[5m])"
    "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))"
  )

  local all_pass=true
  for query in "${test_queries[@]}"; do
    local encoded
    encoded=$(echo "$query" | jq -sRr @uri)
    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${PROMETHEUS_URL}/api/v1/query?query=${encoded}" 2> /dev/null || echo "000")

    if [ "$http_code" = "200" ]; then
      log_success "  Query OK: $query"
    else
      log_error "  Query FAILED: $query (HTTP $http_code)"
      all_pass=false
    fi
  done

  if [ "$all_pass" = "true" ]; then
    record_test "PromQL Queries" "PASS" "All test PromQL queries successful"
  else
    record_test "PromQL Queries" "FAIL" "One or more PromQL queries failed"
  fi
}

check_logql_query() {
  log_info "Testing LogQL query capability..."

  local test_queries=(
    '{compose_project!=""}'
    '{compose_project!=""} |= "ERROR"'
    '{compose_project!=""} | json | level="error"'
  )

  local all_pass=true
  for query in "${test_queries[@]}"; do
    local encoded
    encoded=$(echo "$query" | jq -sRr @uri)
    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${LOKI_URL}/loki/api/v1/query?query=${encoded}" 2> /dev/null || echo "000")

    if [ "$http_code" = "200" ]; then
      log_success "  LogQL OK: $query"
    else
      log_error "  LogQL FAILED: $query (HTTP $http_code)"
      all_pass=false
    fi
  done

  if [ "$all_pass" = "true" ]; then
    record_test "LogQL Queries" "PASS" "All test LogQL queries successful"
  else
    record_test "LogQL Queries" "FAIL" "One or more LogQL queries failed"
  fi
}

check_traceql_query() {
  log_info "Testing TraceQL query capability..."

  local query='{service.name="telemetry-generator"}'
  local encoded
  encoded=$(echo "$query" | jq -sRr @uri)
  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${TEMPO_URL}/api/search?q=${encoded}" 2> /dev/null || echo "000")

  if [ "$http_code" = "200" ]; then
    record_test "TraceQL Query" "PASS" "TraceQL query successful"
  else
    record_test "TraceQL Query" "FAIL" "TraceQL query returned HTTP $http_code"
  fi
}

print_summary() {
  echo ""
  echo "=========================================="
  echo "Brown Belt Module 13 Lab 01 — Results"
  echo "=========================================="
  echo "Total Tests : $TOTAL_TESTS"
  echo "Passed      : $PASSED_TESTS"
  echo "Failed      : $FAILED_TESTS"
  echo ""

  if [ "$FAILED_TESTS" -eq 0 ]; then
    log_success "All tests passed! ✅"
    echo ""
    echo "🎉 Congratulations! You've completed Brown Belt Module 13 Lab 01."
    echo "   You've deployed a full observability stack and explored all three pillars."
    echo "   Move on to Module 14: DORA Deep Dive."
    return 0
  else
    log_error "Some tests failed! ❌"
    echo ""
    echo "Please review the failures above. Common fixes:"
    echo "  - Run 'make status' in uFawkesObs if services aren't healthy"
    echo "  - Check service logs: docker compose logs <service>"
    echo "  - Verify .env has correct GRAFANA_ADMIN_PASSWORD"
    echo "  - Ensure ports 3000, 9090, 3100, 3200, 9093, 9096, 4317, 4318 are free"
    echo "  - See lab-01/instructions.md Troubleshooting for more"
    return 1
  fi
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
  log_info "Starting Brown Belt Module 13 Lab 01 validation..."
  log_info "uFawkesObs dir: $UF_OBS_DIR"
  log_info "Prometheus URL : $PROMETHEUS_URL"
  log_info "Grafana URL    : $GRAFANA_URL"
  log_info "Loki URL       : $LOKI_URL"
  log_info "Tempo URL      : $TEMPO_URL"
  log_info "Alertmanager   : $ALERTMANAGER_URL"
  log_info "OTel Collector : $OTEL_URL"
  echo ""

  check_prerequisites
  check_ufobs_services
  check_grafana_datasources
  check_prometheus_metrics
  check_loki_logs
  check_tempo_traces
  check_alerting
  check_dora_profile
  check_promql_query
  check_logql_query
  check_traceql_query

  print_summary
}

main "$@"
