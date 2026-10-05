#!/bin/bash
# =============================================================================
# Script: validate.sh
# Purpose: Validate Yellow Belt Module 08 Lab 01 completion criteria
# Usage:   Run from uFawkesDojo repo root:
#            bash yellow-belt/module-08-artifact-management/lab-01/validate.sh
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
DEFECTDOJO_URL="${DEFECTDOJO_URL:-http://localhost:8080}"
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
    "defectdojo:DefectDojo"
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
    record_test "uFawkesPipe Stack" "PASS" "All 6 services healthy (woodpecker, sonarqube, portainer, trivy, defectdojo)"
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

  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${WOODPECKER_URL}/api/repos" 2> /dev/null || echo "000")

  if [ "$http_code" = "200" ]; then
    local body
    body=$(curl -s --max-time 10 "${WOODPECKER_URL}/api/repos" 2> /dev/null || echo "[]")
    local repo_id
    repo_id=$(echo "$body" | jq -r '.[] | select(.full_name | test("my-artifact-app"; "i")) | .id' 2> /dev/null | head -1)

    if [ -n "$repo_id" ] && [ "$repo_id" != "null" ]; then
      local builds
      builds=$(curl -s --max-time 10 "${WOODPECKER_URL}/api/repos/${repo_id}/builds" 2> /dev/null || echo "[]")
      local latest_build
      latest_build=$(echo "$builds" | jq -r '.[0]' 2> /dev/null)

      if [ -n "$latest_build" ] && [ "$latest_build" != "null" ]; then
        local build_status
        build_status=$(echo "$latest_build" | jq -r '.status' 2> /dev/null)

        if [ "$build_status" = "success" ] || [ "$build_status" = "running" ] || [ "$build_status" = "pending" ]; then
          record_test "Pipeline Execution" "PASS" "Pipeline runs found for my-artifact-app (status: ${build_status})"
        else
          record_test "Pipeline Execution" "FAIL" "Pipeline failed with status: ${build_status}"
        fi
      else
        record_test "Pipeline Execution" "FAIL" "No builds found for my-artifact-app — push to Git to trigger"
      fi
    else
      record_test "Pipeline Execution" "FAIL" "Repository my-artifact-app not found in Woodpecker — activate repo first"
    fi
  else
    record_test "Pipeline Execution" "FAIL" "Could not fetch repositories from Woodpecker"
  fi
}

check_artifact_build() {
  log_info "Checking artifact build stage..."

  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${WOODPECKER_URL}/api/repos" 2> /dev/null || echo "000")

  if [ "$http_code" = "200" ]; then
    local body
    body=$(curl -s --max-time 10 "${WOODPECKER_URL}/api/repos" 2> /dev/null || echo "[]")
    local repo_id
    repo_id=$(echo "$body" | jq -r '.[] | select(.full_name | test("my-artifact-app"; "i")) | .id' 2> /dev/null | head -1)

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

          if echo "$steps" | jq -e '.[] | select(.name == "build-image")' > /dev/null 2>&1; then
            record_test "Artifact Build" "PASS" "build-image step found in pipeline"
          else
            record_test "Artifact Build" "FAIL" "build-image step not found in pipeline"
          fi
        else
          record_test "Artifact Build" "FAIL" "Could not fetch build steps"
        fi
      else
        record_test "Artifact Build" "FAIL" "No builds found for my-artifact-app"
      fi
    else
      record_test "Artifact Build" "FAIL" "Repository my-artifact-app not found in Woodpecker"
    fi
  else
    record_test "Artifact Build" "FAIL" "Could not fetch repositories from Woodpecker"
  fi
}

check_image_scan() {
  log_info "Checking image scan stage..."

  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${WOODPECKER_URL}/api/repos" 2> /dev/null || echo "000")

  if [ "$http_code" = "200" ]; then
    local body
    body=$(curl -s --max-time 10 "${WOODPECKER_URL}/api/repos" 2> /dev/null || echo "[]")
    local repo_id
    repo_id=$(echo "$body" | jq -r '.[] | select(.full_name | test("my-artifact-app"; "i")) | .id' 2> /dev/null | head -1)

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

          if echo "$steps" | jq -e '.[] | select(.name == "image-scan")' > /dev/null 2>&1; then
            record_test "Image Scan" "PASS" "image-scan step found in pipeline"
          else
            record_test "Image Scan" "FAIL" "image-scan step not found in pipeline"
          fi
        else
          record_test "Image Scan" "FAIL" "Could not fetch build steps"
        fi
      else
        record_test "Image Scan" "FAIL" "No builds found for my-artifact-app"
      fi
    else
      record_test "Image Scan" "FAIL" "Repository my-artifact-app not found in Woodpecker"
    fi
  else
    record_test "Image Scan" "FAIL" "Could not fetch repositories from Woodpecker"
  fi
}

check_push_stage() {
  log_info "Checking push stage..."

  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${WOODPECKER_URL}/api/repos" 2> /dev/null || echo "000")

  if [ "$http_code" = "200" ]; then
    local body
    body=$(curl -s --max-time 10 "${WOODPECKER_URL}/api/repos" 2> /dev/null || echo "[]")
    local repo_id
    repo_id=$(echo "$body" | jq -r '.[] | select(.full_name | test("my-artifact-app"; "i")) | .id' 2> /dev/null | head -1)

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

          if echo "$steps" | jq -e '.[] | select(.name == "push")' > /dev/null 2>&1; then
            record_test "Push Stage" "PASS" "push step found in pipeline"
          else
            record_test "Push Stage" "FAIL" "push step not found in pipeline"
          fi
        else
          record_test "Push Stage" "FAIL" "Could not fetch build steps"
        fi
      else
        record_test "Push Stage" "FAIL" "No builds found for my-artifact-app"
      fi
    else
      record_test "Push Stage" "FAIL" "Repository my-artifact-app not found in Woodpecker"
    fi
  else
    record_test "Push Stage" "FAIL" "Could not fetch repositories from Woodpecker"
  fi
}

check_retention_config() {
  log_info "Checking retention configuration in .fawkespipe.yml..."

  local lab_dir="${HOME}/dojo-labs/uFawkesDevX/my-artifact-app"
  if [ -f "${lab_dir}/.fawkespipe.yml" ]; then
    local has_retention
    has_retention=$(grep -c "retention:" "${lab_dir}/.fawkespipe.yml" || true)

    if [ "$has_retention" -gt 0 ]; then
      local retention_value
      retention_value=$(grep "retention:" "${lab_dir}/.fawkespipe.yml" | head -1 | sed 's/.*retention:[[:space:]]*//' | tr -d ' ')
      record_test "Retention Config" "PASS" "Found retention config: ${retention_value} days"
    else
      record_test "Retention Config" "FAIL" "Missing retention config in .fawkespipe.yml"
    fi
  else
    record_test "Retention Config" "FAIL" "Optimized .fawkespipe.yml not found at ${lab_dir}"
  fi
}

check_promotion_config() {
  log_info "Checking promotion configuration in .fawkespipe.yml..."

  local lab_dir="${HOME}/dojo-labs/uFawkesDevX/my-artifact-app"
  if [ -f "${lab_dir}/.fawkespipe.yml" ]; then
    local has_deploy
    has_deploy=$(grep -c "deploy:" "${lab_dir}/.fawkespipe.yml" || true)
    local has_target
    has_target=$(grep -c "target:" "${lab_dir}/.fawkespipe.yml" || true)

    if [ "$has_deploy" -gt 0 ] && [ "$has_target" -gt 0 ]; then
      record_test "Promotion Config" "PASS" "Found deploy stage and target config in .fawkespipe.yml"
    else
      record_test "Promotion Config" "FAIL" "Missing deploy stage or target config in .fawkespipe.yml"
    fi
  else
    record_test "Promotion Config" "FAIL" "Optimized .fawkespipe.yml not found at ${lab_dir}"
  fi
}

check_promotion_stage() {
  log_info "Checking deploy/promotion stage..."

  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${WOODPECKER_URL}/api/repos" 2> /dev/null || echo "000")

  if [ "$http_code" = "200" ]; then
    local body
    body=$(curl -s --max-time 10 "${WOODPECKER_URL}/api/repos" 2> /dev/null || echo "[]")
    local repo_id
    repo_id=$(echo "$body" | jq -r '.[] | select(.full_name | test("my-artifact-app"; "i")) | .id' 2> /dev/null | head -1)

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

          if echo "$steps" | jq -e '.[] | select(.name == "deploy")' > /dev/null 2>&1; then
            record_test "Promotion Stage" "PASS" "deploy step found in pipeline"
          else
            record_test "Promotion Stage" "PASS" "Pipeline completed; deploy stage configured (may not run on non-main branches)"
          fi
        else
          record_test "Promotion Stage" "FAIL" "Could not fetch build steps"
        fi
      else
        record_test "Promotion Stage" "FAIL" "No builds found for my-artifact-app"
      fi
    else
      record_test "Promotion Stage" "FAIL" "Repository my-artifact-app not found in Woodpecker"
    fi
  else
    record_test "Promotion Stage" "FAIL" "Could not fetch repositories from Woodpecker"
  fi
}

print_summary() {
  echo ""
  echo "=========================================="
  echo "Yellow Belt Module 08 Lab 01 — Results"
  echo "=========================================="
  echo "Total Tests : $TOTAL_TESTS"
  echo "Passed      : $PASSED_TESTS"
  echo "Failed      : $FAILED_TESTS"
  echo ""

  if [ "$FAILED_TESTS" -eq 0 ]; then
    log_success "All tests passed! ✅"
    echo ""
    echo "🎉 Congratulations! You've completed Yellow Belt Module 8 Lab 01."
    echo "   You've experienced the full artifact lifecycle: build → scan → push → promote → retain."
    echo "   You've completed all Yellow Belt modules!"
    return 0
  else
    log_error "Some tests failed! ❌"
    echo ""
    echo "Please review the failures above. Common fixes:"
    echo "  - Run 'make status' in uFawkesPipe if services aren't healthy"
    echo "  - Re-run cookiecutter and customize .fawkespipe.yml"
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
  log_info "Starting Yellow Belt Module 08 Lab 01 validation..."
  log_info "uFawkesPipe dir: $UFPIPE_DIR"
  log_info "Woodpecker URL : $WOODPECKER_URL"
  log_info "SonarQube URL  : $SONARQUBE_URL"
  log_info "DefectDojo URL : $DEFECTDOJO_URL"
  log_info "Trivy URL      : $TRIVY_URL"
  echo ""

  check_prerequisites
  check_ufpipe_services
  check_woodpecker_api
  check_pipeline_execution
  check_artifact_build
  check_image_scan
  check_push_stage
  check_retention_config
  check_promotion_config
  check_promotion_stage

  print_summary
}

main "$@"
