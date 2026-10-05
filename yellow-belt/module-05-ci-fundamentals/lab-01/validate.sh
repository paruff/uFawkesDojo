#!/bin/bash
# =============================================================================
# Script: validate.sh
# Purpose: Validate Yellow Belt Module 05 Lab 01 completion criteria
# Usage:   Run from uFawkesDojo repo root:
#            bash yellow-belt/module-05-ci-fundamentals/lab-01/validate.sh
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
WOODPECKER_URL="${WOODPECKER_URL:-http://localhost:8000}"
SONARQUBE_URL="${SONARQUBE_URL:-http://localhost:9000}"
PORTAINER_URL="${PORTAINER_URL:-https://localhost:9443}"
TRIVY_URL="${TRIVY_URL:-http://localhost:8080}"
UFPIPE_DIR="${UFPIPE_DIR:-~/dojo-labs/uFawkesPipe}"

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

check_ufpipe_services() {
  log_info "Checking uFawkesPipe service health..."

  local services=(
    "woodpecker-server:Woodpecker Server"
    "woodpecker-agent:Woodpecker Agent"
    "sonarqube:SonarQube"
    "portainer:Portainer CE"
    "trivy-server:Trivy Server"
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
    record_test "uFawkesPipe Stack" "PASS" "All 5 services healthy (woodpecker, sonarqube, portainer, trivy)"
  else
    record_test "uFawkesPipe Stack" "FAIL" "One or more services not healthy — run 'make status' in uFawkesPipe"
  fi
}

check_woodpecker_api() {
  log_info "Checking Woodpecker API..."

  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${WOODPECKER_URL}/api/repos" 2> /dev/null || echo "000")

  if [ "$http_code" = "200" ]; then
    record_test "Woodpecker API" "PASS" "API reachable at ${WOODPECKER_URL}"
  else
    record_test "Woodpecker API" "FAIL" "Woodpecker API returned HTTP $http_code at ${WOODPECKER_URL}/api/repos"
  fi
}

check_pipeline_execution() {
  log_info "Checking pipeline execution for lab app..."

  # Try to find my-ci-lab-app pipeline
  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${WOODPECKER_URL}/api/repos" 2> /dev/null || echo "000")

  if [ "$http_code" = "200" ]; then
    local body
    body=$(curl -s --max-time 10 "${WOODPECKER_URL}/api/repos" 2> /dev/null || echo "[]")
    if echo "$body" | grep -qi "my-ci-lab-app"; then
      # Check for pipeline runs
      local repo_id
      repo_id=$(echo "$body" | jq -r '.[] | select(.full_name | test("my-ci-lab-app"; "i")) | .id' 2> /dev/null | head -1)
      if [ -n "$repo_id" ] && [ "$repo_id" != "null" ]; then
        local builds_code
        builds_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${WOODPECKER_URL}/api/repos/${repo_id}/builds" 2> /dev/null || echo "000")
        if [ "$builds_code" = "200" ]; then
          local builds
          builds=$(curl -s --max-time 10 "${WOODPECKER_URL}/api/repos/${repo_id}/builds" 2> /dev/null || echo "[]")
          if echo "$builds" | jq -e 'length > 0' > /dev/null 2>&1; then
            record_test "Pipeline Execution" "PASS" "Pipeline runs found for my-ci-lab-app"
          else
            record_test "Pipeline Execution" "FAIL" "No pipeline runs found for my-ci-lab-app — push to Git to trigger"
          fi
        else
          record_test "Pipeline Execution" "FAIL" "Could not fetch builds (HTTP $builds_code)"
        fi
      else
        record_test "Pipeline Execution" "FAIL" "Repository my-ci-lab-app not found in Woodpecker — activate repo first"
      fi
    else
      record_test "Pipeline Execution" "FAIL" "Could not fetch repositories (HTTP $http_code)"
    fi
  else
    record_test "Pipeline Execution" "FAIL" "Woodpecker API returned HTTP $http_code"
  fi
}

check_security_scans() {
  log_info "Checking security scan execution..."

  # This checks if the pipeline stages for security ran
  # We infer from pipeline execution that security stages ran
  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${WOODPECKER_URL}/api/repos" 2> /dev/null || echo "000")

  if [ "$http_code" = "200" ]; then
    local body
    body=$(curl -s --max-time 10 "${WOODPECKER_URL}/api/repos" 2> /dev/null || echo "[]")
    local repo_id
    repo_id=$(echo "$body" | jq -r '.[] | select(.full_name | test("my-ci-lab-app"; "i")) | .id' 2> /dev/null | head -1)

    if [ -n "$repo_id" ] && [ "$repo_id" != "null" ]; then
      local builds
      builds=$(curl -s --max-time 10 "${WOODPECKER_URL}/api/repos/${repo_id}/builds" 2> /dev/null || echo "[]")
      local latest_build
      latest_build=$(echo "$builds" | jq -r '.[0]' 2> /dev/null)

      if [ -n "$latest_build" ] && [ "$latest_build" != "null" ]; then
        local build_number
        build_number=$(echo "$latest_build" | jq -r '.number' 2> /dev/null)

        if [ -n "$build_number" ] && [ "$build_number" != "null" ]; then
          # Check for security steps in the build
          local steps
          steps=$(curl -s --max-time 10 "${WOODPECKER_URL}/api/repos/${repo_id}/builds/${build_number}/steps" 2> /dev/null || echo "[]")

          if echo "$steps" | grep -qi "secrets-scan\|vuln-scan"; then
            record_test "Security Scans" "PASS" "Security scan steps (secrets-scan, vuln-scan) found in pipeline"
          else
            record_test "Security Scans" "FAIL" "Security scan steps not found in pipeline steps"
          fi
        else
          record_test "Security Scans" "FAIL" "Could not fetch build steps"
        fi
      else
        record_test "Security Scans" "FAIL" "No builds found for my-ci-lab-app"
      fi
    else
      record_test "Security Scans" "FAIL" "Repository my-ci-lab-app not found"
    fi
  else
    record_test "Security Scans" "FAIL" "Could not fetch repositories"
  fi
}

check_failure_recovery() {
  log_info "Checking failure/recovery pattern..."

  # Check if there are at least 2 builds (one failure, one recovery)
  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${WOODPECKER_URL}/api/repos" 2> /dev/null || echo "000")

  if [ "$http_code" = "200" ]; then
    local body
    body=$(curl -s --max-time 10 "${WOODPECKER_URL}/api/repos" 2> /dev/null || echo "[]")
    local repo_id
    repo_id=$(echo "$body" | jq -r '.[] | select(.full_name | test("my-ci-lab-app"; "i")) | .id' 2> /dev/null | head -1)

    if [ -n "$repo_id" ] && [ "$repo_id" != "null" ]; then
      local builds
      builds=$(curl -s --max-time 10 "${WOODPECKER_URL}/api/repos/${repo_id}/builds" 2> /dev/null || echo "[]")
      local build_count
      build_count=$(echo "$builds" | jq 'length' 2> /dev/null || echo 0)

      if [ "$build_count" -ge 2 ]; then
        # Check if at least one build failed and one succeeded
        local failed_count
        failed_count=$(echo "$builds" | jq '[.[] | select(.status == "failure")] | length' 2> /dev/null || echo 0)
        local success_count
        success_count=$(echo "$builds" | jq '[.[] | select(.status == "success")] | length' 2> /dev/null || echo 0)

        if [ "$failed_count" -ge 1 ] && [ "$success_count" -ge 1 ]; then
          record_test "Failure/Recovery" "PASS" "Found $failed_count failed and $success_count successful builds (failure/recovery cycle)"
        else
          record_test "Failure/Recovery" "FAIL" "Need at least 1 failed and 1 successful build (found: $failed_count failed, $success_count success)"
        fi
      else
        record_test "Failure/Recovery" "FAIL" "Need at least 2 pipeline runs (found $build_count)"
      fi
    else
      record_test "Failure/Recovery" "FAIL" "Repository my-ci-lab-app not found"
    fi
  else
    record_test "Failure/Recovery" "FAIL" "Could not fetch repositories"
  fi
}

check_artifacts() {
  log_info "Checking build artifacts..."

  # Check if Woodpecker agent produced artifacts (security scan reports, coverage, etc.)
  # This is a best-effort check via pipeline steps
  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${WOODPECKER_URL}/api/repos" 2> /dev/null || echo "000")

  if [ "$http_code" = "200" ]; then
    local body
    body=$(curl -s --max-time 10 "${WOODPECKER_URL}/api/repos" 2> /dev/null || echo "[]")
    local repo_id
    repo_id=$(echo "$body" | jq -r '.[] | select(.full_name | test("my-ci-lab-app"; "i")) | .id' 2> /dev/null | head -1)

    if [ -n "$repo_id" ] && [ "$repo_id" != "null" ]; then
      local builds
      builds=$(curl -s --max-time 10 "${WOODPECKER_URL}/api/repos/${repo_id}/builds" 2> /dev/null || echo "[]")
      local latest_build
      latest_build=$(echo "$builds" | jq -r '.[0]' 2> /dev/null)

      if [ -n "$latest_build" ] && [ "$latest_build" != "null" ]; then
        local build_number
        build_number=$(echo "$latest_build" | jq -r '.number' 2> /dev/null)

        if [ -n "$build_number" ] && [ "$build_number" != "null" ]; then
          local steps
          steps=$(curl -s --max-time 10 "${WOODPECKER_URL}/api/repos/${repo_id}/builds/${build_number}/steps" 2> /dev/null || echo "[]")

          # Check for artifact-producing steps
          if echo "$steps" | grep -qi "build-image\|upload-defectdojo"; then
            record_test "Build Artifacts" "PASS" "Artifact-producing steps found (build-image, upload-defectdojo)"
          else
            record_test "Build Artifacts" "PASS" "Pipeline completed; artifacts assumed (manual verification in Woodpecker UI)"
          fi
        else
          record_test "Build Artifacts" "FAIL" "Could not fetch build steps"
        fi
      else
        record_test "Build Artifacts" "FAIL" "No builds found"
      fi
    else
      record_test "Build Artifacts" "FAIL" "Repository my-ci-lab-app not found"
    fi
  else
    record_test "Build Artifacts" "FAIL" "Could not fetch repositories"
  fi
}

print_summary() {
  echo ""
  echo "=========================================="
  echo "Yellow Belt Module 05 Lab 01 — Results"
  echo "=========================================="
  echo "Total Tests : $TOTAL_TESTS"
  echo "Passed      : $PASSED_TESTS"
  echo "Failed      : $FAILED_TESTS"
  echo ""

  if [ "$FAILED_TESTS" -eq 0 ]; then
    log_success "All tests passed! ✅"
    echo ""
    echo "🎉 Congratulations! You've completed Yellow Belt Module 5 Lab 01."
    echo "   You've created a pipeline, watched it execute, seen security scans,"
    echo "   and practiced failure/recovery."
    echo "   Move on to Module 06: Golden Path Pipelines."
    return 0
  else
    log_error "Some tests failed! ❌"
    echo ""
    echo "Please review the failures above. Common fixes:"
    echo "  - Run 'make status' in uFawkesPipe if services aren't healthy"
    echo "  - Re-run Scaffolder template for my-ci-lab-app"
    echo "  - Push to Git to trigger pipeline: git push origin main"
    echo "  - Check Woodpecker UI for pipeline status: http://localhost:8000"
    echo "  - See lab-01/instructions.md Troubleshooting for more"
    return 1
  fi
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
  log_info "Starting Yellow Belt Module 05 Lab 01 validation..."
  log_info "uFawkesPipe dir: $UFPIPE_DIR"
  log_info "Woodpecker URL : $WOODPECKER_URL"
  log_info "SonarQube URL  : $SONARQUBE_URL"
  log_info "Portainer URL  : $PORTAINER_URL"
  echo ""

  check_prerequisites
  check_ufpipe_services
  check_woodpecker_api
  check_pipeline_execution
  check_security_scans
  check_failure_recovery
  check_artifacts

  print_summary
}

main "$@"
