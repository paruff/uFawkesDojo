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

check_alertmanager_alert() {
  log_info "Checking Alertmanager for active HighErrorRate alert..."

  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${ALERTMANAGER_URL}/api/v2/alerts" 2> /dev/null || echo "000")

  if [ "$http_code" = "200" ]; then
    local body
    body=$(curl -s --max-time 10 "${ALERTMANAGER_URL}/api/v2/alerts" 2> /dev/null || echo "[]")
    if echo "$body" | jq -e '.[] | select(.labels.alertname == "HighErrorRate" and .labels.severity == "sev1")' > /dev/null 2>&1; then
      record_test "Alertmanager Alert" "PASS" "HighErrorRate alert firing with severity=sev1"
    else
      record_test "Alertmanager Alert" "FAIL" "HighErrorRate alert not found or not firing"
    fi
  else
    record_test "Alertmanager Alert" "FAIL" "Alertmanager API returned HTTP $http_code"
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
    record_test "Grafana Datasources" "FAIL" "Grafana API returned HTTP $http_code"
  fi
}

check_loki_logs() {
  log_info "Checking Loki log queries..."

  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${LOKI_URL}/loki/api/v1/query?query={service%3D%22checkout-api%22}%20%7C%7C%20%22ERROR%22" 2> /dev/null || echo "000")

  if [ "$http_code" = "200" ]; then
    local body
    body=$(curl -s --max-time 10 "${LOKI_URL}/loki/api/v1/query?query={service%3D%22checkout-api%22}%20%7C%7C%20%22ERROR%22" 2> /dev/null || echo "")

    if echo "$body" | jq -e '.status == "success" and (.data.result | length > 0)' > /dev/null 2>&1; then
      record_test "Loki Error Logs" "PASS" "Found error logs for checkout-api in Loki"
    else
      record_test "Loki Error Logs" "FAIL" "No error logs found for checkout-api in Loki"
    fi
  else
    record_test "Loki Error Logs" "FAIL" "Loki API returned HTTP $http_code"
  fi
}

check_tempo_traces() {
  log_info "Checking Tempo trace queries..."

  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${TEMPO_URL}/api/search?q={service.name%3D%22checkout-api%22}" 2> /dev/null || echo "000")

  if [ "$http_code" = "200" ]; then
    local body
    body=$(curl -s --max-time 10 "${TEMPO_URL}/api/search?q={service.name%3D%22checkout-api%22}" 2> /dev/null || echo "")

    if echo "$body" | jq -e '.traces | length > 0' > /dev/null 2>&1; then
      record_test "Tempo Traces" "PASS" "Found traces for checkout-api in Tempo"
    else
      record_test "Tempo Traces" "FAIL" "No traces found for checkout-api in Tempo"
    fi
  else
    record_test "Tempo Traces" "FAIL" "Tempo API returned HTTP $http_code"
  fi
}

check_prometheus_metrics() {
  log_info "Checking Prometheus metrics for checkout-api..."

  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${PROMETHEUS_URL}/api/v1/query?query=rate(http_requests_total{service%3D%22checkout-api%22%5D%5B5m%5D)" 2> /dev/null || echo "000")

  if [ "$http_code" = "200" ]; then
    record_test "Prometheus Metrics" "PASS" "Prometheus metrics queryable for checkout-api"
  else
    record_test "Prometheus Metrics" "FAIL" "Prometheus metrics query returned HTTP $http_code"
  fi
}

check_alertmanager_alert() {
  log_info "Checking Alertmanager for HighErrorRate alert..."

  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${ALERTMANAGER_URL}/api/v2/alerts" 2> /dev/null || echo "000")

  if [ "$http_code" = "200" ]; then
    local body
    body=$(curl -s --max-time 10 "${ALERTMANAGER_URL}/api/v2/alerts" 2> /dev/null || echo "[]")

    if echo "$body" | jq -e '.[] | select(.labels.alertname == "HighErrorRate" and .labels.severity == "sev1")' > /dev/null 2>&1; then
      record_test "Alertmanager HighErrorRate" "PASS" "HighErrorRate alert firing with severity=sev1"
    else
      record_test "Alertmanager HighErrorRate" "FAIL" "HighErrorRate alert not found or not firing"
    fi
  else
    record_test "Alertmanager HighErrorRate" "FAIL" "Alertmanager API returned HTTP $http_code"
  fi
}

check_grafana_dashboard() {
  log_info "Checking Grafana for incident dashboard..."

  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${GRAFANA_URL}/api/search?query=incident" 2> /dev/null || echo "000")

  if [ "$http_code" = "200" ]; then
    local body
    body=$(curl -s --max-time 10 "${GRAFANA_URL}/api/search?query=incident" 2> /dev/null || echo "[]")
    local count
    count=$(echo "$body" | jq 'length' 2> /dev/null || echo 0)

    if [ "$count" -ge 1 ]; then
      record_test "Grafana Incident Dashboard" "PASS" "Found $count incident dashboard(s)"
    else
      record_test "Grafana Incident Dashboard" "FAIL" "No incident dashboards found — create one per lab"
    fi
  else
    record_test "Grafana Incident Dashboard" "FAIL" "Grafana API returned HTTP $http_code"
  fi
}

check_postmortem_exists() {
  log_info "Checking for postmortem document..."

  local pm_file
  pm_file=$(ls -t ~/dojo-labs/postmortem-*.md 2> /dev/null | head -1)

  if [ -n "$pm_file" ] && [ -f "$pm_file" ]; then

    if [ -n "$pm_file" ] && [ -f "$pm_file" ]; then
      local content
      content=$(cat "$pm_file")

      local sections=0
      for section in "Timeline" "Root Cause" "What Went Well" "What Went Wrong" "Action Items" "Lessons Learned"; do
        if echo "$content" | grep -qi "$section"; then
          sections=$((sections + 1))
        fi
      done

      if [ "$sections" -ge 4 ]; then
        record_test "Postmortem Document" "PASS" "Postmortem exists with $sections/6 required sections"
      else
        record_test "Postmortem Document" "FAIL" "Postmortem missing required sections (found $sections/6)"
      fi
    else
      record_test "Postmortem Document" "FAIL" "Postmortem file not found"
    fi
  else
    record_test "Postmortem Document" "FAIL" "No postmortem file found in ~/dojo-labs/"
  fi
}

check_promql_queries() {
  log_info "Testing PromQL queries for incident analysis..."

  local queries=(
    "rate(http_requests_total{service=\"checkout-api\",status=~\"5..\"}[5m])"
    "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{service=\"checkout-api\"}[5m]))"
    "sum(rate(http_requests_total{service=\"checkout-api\",status=~\"5..\"}[5m]))/sum(rate(http_requests_total{service=\"checkout-api\"}[5m]))"
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
    record_test "PromQL Queries" "PASS" "All incident analysis PromQL queries successful"
  else
    record_test "PromQL Queries" "FAIL" "One or more PromQL queries failed"
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
    echo "🎉 Congratulations! You've completed Brown Belt Module 16 Lab 01."
    echo "   You've executed a full incident response lifecycle with uFawkesObs."
    echo "   Brown Belt Complete! 🎉"
    return 0
  else
    log_error "Some tests failed! ❌"
    echo ""
    echo "Please review the failures above. Common fixes:"
    echo "  - Run 'make status' in uFawkesObs if services aren't healthy"
    echo "  - Trigger test alert: curl -X POST http://localhost:9093/api/v2/alerts ..."
    echo "  - Check Grafana dashboards: http://localhost:3000"
    echo "  - Check Loki/Tempo/Prometheus: docker compose logs <service>"
    echo "  - See lab-01/instructions.md Troubleshooting for more"
    return 1
  fi
}

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
  check_alertmanager_alert
  check_grafana_datasources
  check_loki_logs
  check_tempo_traces
  check_prometheus_metrics
  check_alertmanager_alert
  check_grafana_dashboard
  check_postmortem_exists
  check_promql_queries

  print_summary
}

main "$@"
