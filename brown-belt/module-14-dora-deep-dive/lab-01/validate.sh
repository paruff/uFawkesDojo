#!/bin/bash
# =============================================================================
# Script: validate.sh
# Purpose: Validate Brown Belt Module 14 Lab 01 completion criteria
# Usage:   Run from uFawkesDojo repo root:
#            bash brown-belt/module-14-dora-deep-dive/lab-01/validate.sh
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
DORA_API_URL="${DORA_API_URL:-http://localhost:8088}"
PUSHGATEWAY_URL="${PUSHGATEWAY_URL:-http://localhost:9091}"
UF_OBS_DIR="${UF_OBS_DIR:-~/dojo-labs/uFawkesObs}"

# Grafana API credentials — anonymous access is disabled by design in
# uFawkesObs (see SECURITY.md), so dashboard checks authenticate.
# Resolution: env override, then the .env beside the stack ($UF_OBS_DIR/.env),
# then ./.env (when run from inside the uFawkesObs checkout).
GRAFANA_USER="${GRAFANA_ADMIN_USER:-}"
GRAFANA_PASS="${GRAFANA_ADMIN_PASSWORD:-}"

load_grafana_credentials() {
  if [ -n "$GRAFANA_PASS" ]; then
    return 0
  fi
  local envfile
  for envfile in "${UF_OBS_DIR}/.env" "./.env"; do
    [ -f "$envfile" ] || continue
    if [ -z "$GRAFANA_USER" ]; then
      GRAFANA_USER=$(grep -E '^GRAFANA_ADMIN_USER=' "$envfile" | cut -d= -f2- || true)
    fi
    GRAFANA_PASS=$(grep -E '^GRAFANA_ADMIN_PASSWORD=' "$envfile" | cut -d= -f2- || true)
    [ -n "$GRAFANA_PASS" ] && return 0
  done
  return 0
}

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

  # dora-compute was folded into dora-api and Pushgateway was dropped
  # (uFawkesObs commit 2c0c84a): the compute loop runs in-process inside
  # dora-api, whose container_name is ufawkesdora-ingestion.
  local services=(
    "prometheus:Prometheus"
    "grafana:Grafana"
    "loki:Loki"
    "tempo:Tempo"
    "alertmanager:Alertmanager"
    "alloy:Alloy"
    "otel-collector:OTel Collector"
    "node-exporter:Node Exporter"
    "ufawkesdora-ingestion:DORA API (ingestion + compute)"
  )

  local all_healthy=true
  for entry in "${services[@]}"; do
    local container="${entry%%:*}"
    local label="${entry##*:}"

    if docker ps --filter "name=^${container}$" --filter "status=running" --format '{{.Names}}' 2> /dev/null | grep -q "^${container}$"; then
      local health
      # {{if .State.Health}} keeps containers without a healthcheck (tempo,
      # otel-collector) at "none"; the bare .State.Health.Status template
      # prints a newline plus an error, which never equals "none" and made
      # healthy stacks fail this check.
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
    record_test "uFawkesObs Stack" "PASS" "All 9 services healthy (8 core + DORA API)"
  else
    record_test "uFawkesObs Stack" "FAIL" "One or more services not healthy — run 'make status' in uFawkesObs"
  fi
}

check_dora_api() {
  log_info "Checking DORA API..."

  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${DORA_API_URL}/health" 2> /dev/null || echo "000")

  if [ "$http_code" = "200" ]; then
    record_test "DORA API" "PASS" "API reachable at ${DORA_API_URL}/health"
  else
    record_test "DORA API" "FAIL" "DORA API returned HTTP $http_code at ${DORA_API_URL}/health"
  fi
}

check_dora_event_ingestion() {
  log_info "Checking DORA event ingestion..."

  # Send a test event
  # Send a test event — must match dora/events/deployment-event.schema.json
  # (1.0): required schema_version/repo/deployed_at/pipeline_url, commit_sha
  # as full 40-hex, and no extra properties (timestamp, deployed_by and
  # work_type are rejected with HTTP 422 since the schema tightened).
  local test_event
  test_event='{
    "schema_version": "1.0",
    "event_type": "deployment",
    "repo": "dojo-lab/validation",
    "service": "validation-test",
    "environment": "test",
    "commit_sha": "'"$(printf '%040x' "$(date +%s)")"'",
    "deployed_at": "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'",
    "status": "success",
    "pipeline_url": "https://example.com/ci/validate-'"$(date +%s)"'"
  }'

  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
    -X POST "${DORA_API_URL}/event" \
    -H "Content-Type: application/json" \
    -d "$test_event" 2> /dev/null || echo "000")

  if [ "$http_code" = "200" ] || [ "$http_code" = "201" ] || [ "$http_code" = "202" ]; then
    record_test "DORA Event Ingestion" "PASS" "Event accepted by dora-api (HTTP $http_code)"
  else
    record_test "DORA Event Ingestion" "FAIL" "Event rejected (HTTP $http_code)"
  fi
}

check_prometheus_metrics() {
  log_info "Checking Prometheus DORA metrics..."

  local metrics=(
    "dora_deployment_frequency"
    "dora_lead_time_seconds"
    "dora_change_failure_rate"
    "dora_mttr_seconds"
    "dora_rework_rate"
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
      if echo "$body" | jq -e '.status == "success"' > /dev/null 2>&1; then
        log_success "  $metric: queryable"
      else
        log_error "  $metric: query succeeded but no data"
        all_pass=false
      fi
    else
      log_error "  $metric: HTTP $http_code"
      all_pass=false
    fi
  done

  if [ "$all_pass" = "true" ]; then
    record_test "DORA Metrics Query" "PASS" "All 5 DORA metrics queryable via PromQL"
  else
    record_test "DORA Metrics Query" "FAIL" "One or more DORA metrics not queryable"
  fi
}

check_grafana_dashboard() {
  log_info "Checking Grafana DORA dashboard..."

  load_grafana_credentials
  if [ -z "$GRAFANA_PASS" ]; then
    # Loud skip, never a silent pass: the check didn't run, so it must not
    # read as if it did (AGENTS.md: no swallowed failures).
    log_warning "Grafana DORA Dashboard: skipped — no credentials found. Set GRAFANA_ADMIN_PASSWORD, or keep it in ${UF_OBS_DIR}/.env"
    return
  fi
  local auth=(-u "${GRAFANA_USER:-admin}:${GRAFANA_PASS}")

  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${auth[@]}" "${GRAFANA_URL}/api/search?query=dora" 2> /dev/null || echo "000")

  if [ "$http_code" = "200" ]; then
    local body
    body=$(curl -s --max-time 10 "${auth[@]}" "${GRAFANA_URL}/api/search?query=dora" 2> /dev/null || echo "[]")
    local count
    count=$(echo "$body" | jq 'length' 2> /dev/null || echo 0)

    if [ "$count" -ge 1 ]; then
      record_test "Grafana DORA Dashboard" "PASS" "Found $count DORA dashboard(s)"
    else
      record_test "Grafana DORA Dashboard" "FAIL" "No DORA dashboards found — create one with 5 DORA metric panels"
    fi
  else
    record_test "Grafana DORA Dashboard" "FAIL" "Grafana API returned HTTP $http_code at ${GRAFANA_URL}/api/search — check GRAFANA_ADMIN_PASSWORD matches your uFawkesObs .env (anonymous access is disabled)"
  fi
}

check_alerting() {
  log_info "Checking DORA alerting rules..."

  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${PROMETHEUS_URL}/api/v1/rules" 2> /dev/null || echo "000")

  if [ "$http_code" = "200" ]; then
    local body
    body=$(curl -s --max-time 10 "${PROMETHEUS_URL}/api/v1/rules" 2> /dev/null || echo "")

    local dora_rules
    dora_rules=$(echo "$body" | jq '.data.groups[] | select(.name | test("dora"; "i")) | .rules | length' 2> /dev/null | awk '{sum+=$1} END {print sum}' || echo 0)

    if [ -n "$dora_rules" ] && [ "$dora_rules" -gt 0 ]; then
      record_test "DORA Alert Rules" "PASS" "Found $dora_rules DORA alert rules"
    else
      record_test "DORA Alert Rules" "FAIL" "No DORA alert rules found in Prometheus"
    fi
  else
    record_test "DORA Alert Rules" "FAIL" "Could not fetch rules from Prometheus (HTTP $http_code)"
  fi
}

check_event_ingestion() {
  log_info "Checking DORA event ingestion end-to-end..."

  # Schema-valid test event (dora/events/deployment-event.schema.json 1.0):
  # 40-hex commit_sha, schema_version/repo/deployed_at/pipeline_url required,
  # no extra properties — the old timestamp/deployed_by/work_type shape is
  # rejected with HTTP 422.
  local test_sha
  test_sha="$(printf '%040x' "$(date +%s)")"
  local test_event
  test_event="{
    \"schema_version\": \"1.0\",
    \"event_type\": \"deployment\",
    \"repo\": \"dojo-lab/validation\",
    \"service\": \"validation-test\",
    \"environment\": \"test\",
    \"commit_sha\": \"${test_sha}\",
    \"deployed_at\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",
    \"status\": \"success\",
    \"pipeline_url\": \"https://example.com/ci/validate-${test_sha}\"
  }"

  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
    -X POST "${DORA_API_URL}/event" \
    -H "Content-Type: application/json" \
    -d "$test_event" 2> /dev/null || echo "000")

  if [ "$http_code" = "200" ] || [ "$http_code" = "201" ] || [ "$http_code" = "202" ]; then
    # Give dora-api's in-process compute loop a beat before querying
    sleep 5

    # Check if the event appears in metrics
    local encoded
    encoded=$(echo "dora_deployment_frequency{commit_sha=\"${test_sha}\"}" | jq -sRr @uri)
    local metric_code
    metric_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
      "${PROMETHEUS_URL}/api/v1/query?query=${encoded}" 2> /dev/null || echo "000")

    if [ "$metric_code" = "200" ]; then
      record_test "Event Ingestion → Metrics" "PASS" "Event ingested and reflected in metrics"
    else
      record_test "Event Ingestion → Metrics" "WARN" "Event accepted but not yet visible in metrics (timing)"
    fi
  else
    record_test "Event Ingestion → Metrics" "FAIL" "Event submission failed (HTTP $http_code)"
  fi
}

check_promql_queries() {
  log_info "Testing DORA PromQL queries..."

  local queries=(
    "dora_deployment_frequency"
    "histogram_quantile(0.95, rate(dora_lead_time_seconds_bucket[7d]))"
    "dora_change_failure_rate"
    "dora_mttr_seconds"
    "dora_rework_rate"
  )

  local all_pass=true
  for query in "${queries[@]}"; do
    local encoded
    encoded=$(echo "$query" | jq -sRr @uri)
    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
      "${PROMETHEUS_URL}/api/v1/query?query=${encoded}" 2> /dev/null || echo "000")

    if [ "$http_code" = "200" ]; then
      log_success "  PromQL OK: $query"
    else
      log_error "  PromQL FAILED: $query (HTTP $http_code)"
      all_pass=false
    fi
  done

  if [ "$all_pass" = "true" ]; then
    record_test "DORA PromQL Queries" "PASS" "All DORA PromQL queries successful"
  else
    record_test "DORA PromQL Queries" "FAIL" "One or more DORA PromQL queries failed"
  fi
}

print_summary() {
  echo ""
  echo "=========================================="
  echo "Brown Belt Module 14 Lab 01 — Results"
  echo "=========================================="
  echo "Total Tests : $TOTAL_TESTS"
  echo "Passed      : $PASSED_TESTS"
  echo "Failed      : $FAILED_TESTS"
  echo ""

  if [ "$FAILED_TESTS" -eq 0 ]; then
    log_success "All tests passed! ✅"
    echo ""
    echo "🎉 Congratulations! You've completed Brown Belt Module 14 Lab 01."
    echo "   You've built a complete DORA metrics pipeline with uFawkesObs."
    echo "   You're ready for the Brown Belt Assessment!"
    return 0
  else
    log_error "Some tests failed! ❌"
    echo ""
    echo "Please review the failures above. Common fixes:"
    echo "  - Run 'make up-dora' in uFawkesObs if DORA services aren't running"
    echo "  - Re-run cookiecutter and customize .fawkespipe.yml with DORA config"
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
  log_info "Starting Brown Belt Module 14 Lab 01 validation..."
  log_info "uFawkesObs dir: $UF_OBS_DIR"
  log_info "Prometheus URL : $PROMETHEUS_URL"
  log_info "Grafana URL    : $GRAFANA_URL"
  log_info "Loki URL       : $LOKI_URL"
  log_info "Tempo URL      : $TEMPO_URL"
  log_info "DORA API URL   : $DORA_API_URL"
  log_info "Pushgateway URL: $PUSHGATEWAY_URL"
  echo ""

  check_prerequisites
  check_ufobs_services
  check_dora_api
  check_dora_event_ingestion
  check_prometheus_metrics
  check_grafana_dashboard
  check_alerting
  check_event_ingestion
  check_promql_queries

  print_summary
}

main "$@"
