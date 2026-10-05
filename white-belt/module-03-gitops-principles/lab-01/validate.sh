#!/bin/bash
# =============================================================================
# Script: validate.sh
# Purpose: Validate White Belt Module 03 Lab 01 completion criteria
# Usage:   Run from uFawkesDojo repo root:
#            bash white-belt/module-03-gitops-principles/lab-01/validate.sh
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
BACKSTAGE_URL="${BACKSTAGE_URL:-http://localhost:7007}"
SCORE_API_URL="${SCORE_API_URL:-http://localhost:8000/api/score}"
GATEWAY_URL="${GATEWAY_URL:-http://localhost:8000}"
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
  for cmd in curl jq git cookiecutter; do
    if ! check_command "$cmd"; then
      missing+=("$cmd")
    fi
  done

  if [ ${#missing[@]} -eq 0 ]; then
    record_test "Prerequisites" "PASS" "curl, jq, git, cookiecutter installed"
  else
    record_test "Prerequisites" "FAIL" "Missing: ${missing[*]} — install jq (brew/apt), pip install cookiecutter"
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
    local body
    body=$(curl -s --max-time 10 "${BACKSTAGE_URL}/api/catalog/entities" 2> /dev/null || echo "[]")
    if echo "$body" | grep -q "hello-devx\|hello-gitops"; then
      record_test "Backstage Catalog" "PASS" "API reachable with lab services registered"
    else
      record_test "Backstage Catalog" "PASS" "API reachable at ${BACKSTAGE_URL} (services may still be loading)"
    fi
  else
    record_test "Backstage Catalog" "FAIL" "Backstage API returned HTTP $http_code at ${BACKSTAGE_URL}/api/catalog/entities"
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

check_service_registration() {
  log_info "Checking Score API spec submission..."

  local timestamp
  timestamp=$(date +%s)
  local test_spec
  test_spec='{"apiVersion":"score.dev/v1b1","metadata":{"name":"validation-test-'${timestamp}'"},"containers":{"validation-test":{"image":"test:latest","variables":{"PORT":"8080"}}},"service":{"ports":{"www":{"port":8080,"targetPort":8080}}}}'

  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
    -X POST "${SCORE_API_URL}/specs" \
    -H "Content-Type: application/json" \
    -d "$test_spec" 2> /dev/null || echo "000")

  if [ "$http_code" = "200" ] || [ "$http_code" = "201" ]; then
    record_test "Score Spec Submit" "PASS" "Score API accepts and validates specs (HTTP $http_code)"
  else
    record_test "Score Spec Submit" "FAIL" "Score API returned HTTP $http_code for spec submission"
  fi
}

check_scaffolded_service() {
  log_info "Checking scaffolded service in Backstage catalog..."

  # Check for either hello-gitops or hello-scaffolded
  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
    "${BACKSTAGE_URL}/api/catalog/entities?filter=kind=Component&filter=metadata.name=hello-gitops" 2> /dev/null || echo "000")

  if [ "$http_code" = "200" ]; then
    local body
    body=$(curl -s --max-time 10 "${BACKSTAGE_URL}/api/catalog/entities?filter=kind=Component&filter=metadata.name=hello-gitops" 2> /dev/null || echo "[]")
    if echo "$body" | grep -q "hello-gitops"; then
      record_test "Direct API Registration" "PASS" "hello-gitops found in Backstage catalog"
    else
      record_test "Direct API Registration" "FAIL" "hello-gitops not found — check Score API submission and catalog refresh"
    fi
  else
    record_test "Direct API Registration" "FAIL" "Catalog query returned HTTP $http_code"
  fi

  # Also check for hello-scaffolded
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
    "${BACKSTAGE_URL}/api/catalog/entities?filter=kind=Component&filter=metadata.name=hello-scaffolded" 2> /dev/null || echo "000")

  if [ "$http_code" = "200" ]; then
    body=$(curl -s --max-time 10 "${BACKSTAGE_URL}/api/catalog/entities?filter=kind=Component&filter=metadata.name=hello-scaffolded" 2> /dev/null || echo "[]")
    if echo "$body" | grep -q "hello-scaffolded"; then
      record_test "Scaffolder Registration" "PASS" "hello-scaffolded found in Backstage catalog"
    else
      record_test "Scaffolder Registration" "FAIL" "hello-scaffolded not found — check Cookiecutter + Score API steps"
    fi
  else
    record_test "Scaffolder Registration" "FAIL" "Catalog query returned HTTP $http_code"
  fi
}

check_rollback_pattern() {
  log_info "Checking rollback pattern (spec re-submission)..."

  # Submit a spec, then re-submit it (simulating rollback)
  local timestamp
  timestamp=$(date +%s)
  local test_spec
  test_spec='{"apiVersion":"score.dev/v1b1","metadata":{"name":"rollback-test-'${timestamp}'"},"containers":{"rollback-test":{"image":"test:rollback","variables":{"PORT":"8080"}}},"service":{"ports":{"www":{"port":8080,"targetPort":8080}}}}'

  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
    -X POST "${SCORE_API_URL}/specs" \
    -H "Content-Type: application/json" \
    -d "$test_spec" 2> /dev/null || echo "000")

  if [ "$http_code" = "200" ] || [ "$http_code" = "201" ]; then
    # Re-submit same spec (simulating rollback)
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
      -X POST "${SCORE_API_URL}/specs" \
      -H "Content-Type: application/json" \
      -d "$test_spec" 2> /dev/null || echo "000")

    if [ "$http_code" = "200" ] || [ "$http_code" = "201" ]; then
      record_test "Rollback Pattern" "PASS" "Spec re-submission works (simulates git revert + re-submit)"
    else
      record_test "Rollback Pattern" "FAIL" "Re-submission returned HTTP $http_code"
    fi
  else
    record_test "Rollback Pattern" "FAIL" "Initial submission returned HTTP $http_code"
  fi
}

print_summary() {
  echo ""
  echo "=========================================="
  echo "White Belt Module 03 Lab 01 — Results"
  echo "=========================================="
  echo "Total Tests : $TOTAL_TESTS"
  echo "Passed      : $PASSED_TESTS"
  echo "Failed      : $FAILED_TESTS"
  echo ""

  if [ "$FAILED_TESTS" -eq 0 ]; then
    log_success "All tests passed! ✅"
    echo ""
    echo "🎉 Congratulations! You've completed White Belt Module 3 Lab 01."
    echo "   You've experienced GitOps: spec → validate → trigger → catalog → rollback."
    echo "   Move on to Module 04: Your First Deployment."
    return 0
  else
    log_error "Some tests failed! ❌"
    echo ""
    echo "Please review the failures above. Common fixes:"
    echo "  - Run 'make status' in uFawkesDevX if services aren't healthy"
    echo "  - Ensure Score service is running: docker logs developerd-score"
    echo "  - Re-run Score API submission steps from lab instructions"
    echo "  - See lab-01/instructions.md Troubleshooting for more"
    return 1
  fi
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
  log_info "Starting White Belt Module 03 Lab 01 validation..."
  log_info "uFawkesDevX dir: $UFDEVX_DIR"
  log_info "Backstage URL  : $BACKSTAGE_URL"
  log_info "Score API URL  : $SCORE_API_URL"
  log_info "Gateway URL    : $GATEWAY_URL"
  echo ""

  check_prerequisites
  check_ufdevx_services
  check_backstage_catalog
  check_score_service
  check_service_registration
  check_scaffolded_service
  check_rollback_pattern

  print_summary
}

main "$@"
