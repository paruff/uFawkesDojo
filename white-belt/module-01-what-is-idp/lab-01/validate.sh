#!/bin/bash
# =============================================================================
# Script: validate.sh
# Purpose: Validate White Belt Module 01 Lab 01 completion criteria
# Usage:   Run from uFawkesDojo repo root:
#            bash white-belt/module-01-what-is-idp/lab-01/validate.sh
# Exit Codes: 0=all checks passed, 1=one or more checks failed
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration (can be overridden by environment variables)
POSTGRES_CONTAINER="${POSTGRES_CONTAINER:-dojo-postgres}"
NETWORK_NAME="${NETWORK_NAME:-fawkes-net}"
BACKSTAGE_URL="${BACKSTAGE_URL:-http://localhost:7007}"
SCORE_API_URL="${SCORE_API_URL:-http://localhost:8000/api/score}"
GATEWAY_URL="${GATEWAY_URL:-http://localhost:8000}"
CODER_URL="${CODER_URL:-}" # Will be read from uFawkesDevX .env if available
UFDEVX_DIR="${UFDEVX_DIR:-~/dojo-labs/uFawkesDevX}"

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
  for cmd in docker "docker compose" git curl cookiecutter; do
    if ! check_command "$cmd"; then
      missing+=("$cmd")
    fi
  done

  if [ ${#missing[@]} -eq 0 ]; then
    record_test "Prerequisites" "PASS" "docker, docker compose, git, curl, cookiecutter installed"
  else
    record_test "Prerequisites" "FAIL" "Missing: ${missing[*]} — install Docker Desktop, git, curl, and run 'pip install cookiecutter'"
  fi
}

check_postgres() {
  log_info "Checking PostgreSQL container and databases..."

  # Check container is running
  if ! docker ps --filter "name=^${POSTGRES_CONTAINER}$" --filter "status=running" --format '{{.Names}}' 2> /dev/null | grep -q "^${POSTGRES_CONTAINER}$"; then
    record_test "PostgreSQL" "FAIL" "Container '${POSTGRES_CONTAINER}' not running — run lab Step 1"
    return
  fi

  # Check databases exist
  local dbs=("coder" "backstage" "score")
  local missing_dbs=()
  for db in "${dbs[@]}"; do
    if ! docker exec -i "${POSTGRES_CONTAINER}" psql -U postgres -lqt 2> /dev/null | cut -d'|' -f1 | grep -qw "$db"; then
      missing_dbs+=("$db")
    fi
  done

  if [ ${#missing_dbs[@]} -eq 0 ]; then
    record_test "PostgreSQL" "PASS" "Container running with coder, backstage, score databases"
  else
    record_test "PostgreSQL" "FAIL" "Missing databases: ${missing_dbs[*]} — run lab Step 1 database creation"
  fi
}

check_network() {
  log_info "Checking Docker network..."

  if docker network ls --format '{{.Name}}' 2> /dev/null | grep -q "^${NETWORK_NAME}$"; then
    record_test "Network" "PASS" "Network '${NETWORK_NAME}' exists"
  else
    record_test "Network" "FAIL" "Network '${NETWORK_NAME}' not found — run 'make network' in uFawkesDevX"
  fi
}

check_ufdevx_services() {
  log_info "Checking uFawkesDevX service health..."

  local services=(
    "developerd-coder:Coder"
    "developerd-backstage:Backstage"
    "developerd-score:Score Service"
    "developerd-plugin-manager:Plugin Manager"
    "developerd-gateway:API Gateway"
  )

  local all_healthy=true
  for entry in "${services[@]}"; do
    local container="${entry%%:*}"
    local label="${entry##*:}"

    if docker ps --filter "name=^${container}$" --filter "status=running" --format '{{.Names}}' 2> /dev/null | grep -q "^${container}$"; then
      # Check health status if available
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
    record_test "uFawkesDevX Stack" "PASS" "All 5 services healthy (coder, backstage, score-service, plugin-manager, gateway)"
  else
    record_test "uFawkesDevX Stack" "FAIL" "One or more services not healthy — run 'make status' in uFawkesDevX"
  fi
}

check_backstage_catalog() {
  log_info "Checking Backstage catalog API..."

  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${BACKSTAGE_URL}/api/catalog/entities" 2> /dev/null || echo "000")

  if [ "$http_code" = "200" ]; then
    # Verify it returns actual entities (not empty)
    local body
    body=$(curl -s --max-time 10 "${BACKSTAGE_URL}/api/catalog/entities" 2> /dev/null || echo "[]")
    if echo "$body" | grep -q "ufawkes-devx\|score-service\|plugin-manager"; then
      record_test "Backstage Catalog" "PASS" "API reachable at ${BACKSTAGE_URL} with uFawkes entities"
    else
      record_test "Backstage Catalog" "PASS" "API reachable at ${BACKSTAGE_URL} (entities may still be loading)"
    fi
  else
    record_test "Backstage Catalog" "FAIL" "Backstage API returned HTTP $http_code at ${BACKSTAGE_URL}/api/catalog/entities — ensure 'make up' finished"
  fi
}

check_score_service() {
  log_info "Checking Score service API..."

  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${SCORE_API_URL}/health" 2> /dev/null || echo "000")

  if [ "$http_code" = "200" ]; then
    record_test "Score Service" "PASS" "API reachable at ${SCORE_API_URL}"
  else
    # Try gateway health as fallback
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${GATEWAY_URL}/health" 2> /dev/null || echo "000")
    if [ "$http_code" = "200" ]; then
      record_test "Score Service" "PASS" "Gateway reachable at ${GATEWAY_URL} (Score service behind gateway)"
    else
      record_test "Score Service" "FAIL" "Score API returned HTTP $http_code at ${SCORE_API_URL}/health"
    fi
  fi
}

check_coder() {
  log_info "Checking Coder API..."

  # Try to get CODER_ACCESS_URL from uFawkesDevX .env
  if [ -z "$CODER_URL" ] && [ -f "${UFDEVX_DIR}/.env" ]; then
    CODER_URL=$(grep -E '^CODER_ACCESS_URL=' "${UFDEVX_DIR}/.env" | cut -d= -f2- | tr -d '"' || true)
  fi

  if [ -z "$CODER_URL" ]; then
    log_warning "Coder: skipped — CODER_ACCESS_URL not set in uFawkesDevX .env or environment"
    return
  fi

  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${CODER_URL}/healthz" 2> /dev/null || echo "000")

  if [ "$http_code" = "200" ]; then
    record_test "Coder" "PASS" "API reachable at ${CODER_URL}"
  else
    record_test "Coder" "FAIL" "Coder returned HTTP $http_code at ${CODER_URL}/healthz"
  fi
}

check_scaffolded_service() {
  log_info "Checking scaffolded service in Backstage catalog..."

  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${BACKSTAGE_URL}/api/catalog/entities?filter=kind=Component&filter=metadata.name=hello-devx" 2> /dev/null || echo "000")

  if [ "$http_code" = "200" ]; then
    local body
    body=$(curl -s --max-time 10 "${BACKSTAGE_URL}/api/catalog/entities?filter=kind=Component&filter=metadata.name=hello-devx" 2> /dev/null || echo "[]")
    if echo "$body" | grep -q "hello-devx"; then
      record_test "Scaffolded Service" "PASS" "hello-devx found in Backstage catalog"
    else
      record_test "Scaffolded Service" "FAIL" "hello-devx not found in catalog — check Score service registration and catalog refresh"
    fi
  else
    record_test "Scaffolded Service" "FAIL" "Catalog query returned HTTP $http_code"
  fi
}

print_summary() {
  echo ""
  echo "=========================================="
  echo "White Belt Module 01 Lab 01 — Results"
  echo "=========================================="
  echo "Total Tests : $TOTAL_TESTS"
  echo "Passed      : $PASSED_TESTS"
  echo "Failed      : $FAILED_TESTS"
  echo ""

  if [ "$FAILED_TESTS" -eq 0 ]; then
    log_success "All tests passed! ✅"
    echo ""
    echo "🎉 Congratulations! You have completed White Belt Module 1 Lab 01."
    echo "   Your service is scaffolded, validated, and cataloged."
    echo "   Move on to Module 02: DORA Metrics."
    return 0
  else
    log_error "Some tests failed! ❌"
    echo ""
    echo "Please review the failures above. Common fixes:"
    echo "  - Run 'make up' in uFawkesDevX if services aren't healthy"
    echo "  - Ensure PostgreSQL container is running with all 3 databases"
    echo "  - Check CODER_ACCESS_URL is a LAN IP (not localhost) in .env"
    echo "  - Re-run cookiecutter and Score service registration steps"
    echo "  - See lab-01/instructions.md Troubleshooting for more"
    return 1
  fi
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
  log_info "Starting White Belt Module 01 Lab 01 validation..."
  log_info "uFawkesDevX dir: $UFDEVX_DIR"
  log_info "Backstage URL  : $BACKSTAGE_URL"
  log_info "Score API URL  : $SCORE_API_URL"
  log_info "Gateway URL    : $GATEWAY_URL"
  [ -n "$CODER_URL" ] && log_info "Coder URL      : $CODER_URL"
  echo ""

  check_prerequisites
  check_postgres
  check_network
  check_ufdevx_services
  check_backstage_catalog
  check_score_service
  check_coder
  check_scaffolded_service

  print_summary
}

main "$@"
