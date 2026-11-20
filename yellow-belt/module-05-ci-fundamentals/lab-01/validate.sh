#!/bin/bash
# =============================================================================
# Script: validate.sh
# Purpose: Validate Yellow Belt Module 05 Lab 01 completion criteria
# Usage:   WOODPECKER_TOKEN=<token> bash yellow-belt/module-05-ci-fundamentals/lab-01/validate.sh
#          WOODPECKER_URL defaults to http://localhost:8000; set it to match
#          WOODPECKER_UI_PORT in uFawkesPipe's .env if you changed the port.
# Exit Codes: 0=all checks passed, 1=one or more checks failed
# =============================================================================

set -uo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

WOODPECKER_URL="${WOODPECKER_URL:-http://localhost:8000}"
WOODPECKER_TOKEN="${WOODPECKER_TOKEN:-}"
LAB_REPO="${LAB_REPO:-my-ci-lab-app}"

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
REPO_ID=""

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }

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

# GET <path> from the Woodpecker API with the token; prints the body.
# A failure is reported by the caller, never swallowed: curl's error text goes to stderr.
api() {
  curl -sS --max-time 15 -H "Authorization: Bearer ${WOODPECKER_TOKEN}" "${WOODPECKER_URL}/api$1"
}

check_prerequisites() {
  local missing=()
  for cmd in curl jq git cookiecutter docker; do
    command -v "$cmd" > /dev/null 2>&1 || missing+=("$cmd")
  done
  if [ ${#missing[@]} -eq 0 ]; then
    record_test "Prerequisites" "PASS" "curl, jq, git, cookiecutter, docker installed"
  else
    record_test "Prerequisites" "FAIL" "Missing: ${missing[*]}"
  fi
}

check_stack() {
  local bad=()
  for svc in woodpecker-server woodpecker-agent; do
    docker ps --filter "label=com.docker.compose.service=${svc}" --filter "status=running" --format '{{.Names}}' 2> /dev/null | grep -q . || bad+=("$svc")
  done
  if [ ${#bad[@]} -eq 0 ]; then
    record_test "Stack" "PASS" "woodpecker-server and woodpecker-agent are running"
  else
    record_test "Stack" "FAIL" "Not running: ${bad[*]} — run 'make up' in uFawkesPipe"
  fi
}

check_api_auth() {
  if [ -z "$WOODPECKER_TOKEN" ]; then
    record_test "Woodpecker API" "FAIL" "WOODPECKER_TOKEN is not set (Woodpecker UI → avatar → User settings → Personal Access Token)"
    return
  fi
  local code
  code=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 15 -H "Authorization: Bearer ${WOODPECKER_TOKEN}" "${WOODPECKER_URL}/api/user") || code="000"
  if [ "$code" = "200" ]; then
    record_test "Woodpecker API" "PASS" "token accepted at ${WOODPECKER_URL}"
  else
    record_test "Woodpecker API" "FAIL" "GET /api/user returned HTTP ${code} at ${WOODPECKER_URL} (401 = stale or wrong token)"
  fi
}

check_repo_active() {
  REPO_ID=$(api "/user/repos?all=true" 2> /dev/null | jq -r --arg n "$LAB_REPO" '[.[] | select(.name == $n and .active == true)][0].id // empty' 2> /dev/null)
  if [ -n "$REPO_ID" ]; then
    record_test "Repo Activated" "PASS" "${LAB_REPO} is active in Woodpecker (id ${REPO_ID})"
  else
    record_test "Repo Activated" "FAIL" "${LAB_REPO} not found or not active — activate it (Step 3)"
  fi
}

# Fills PIPELINES with the repo's pipelines (JSON array), or "[]".
load_pipelines() {
  PIPELINES=$(api "/repos/${REPO_ID}/pipelines?perPage=50" 2> /dev/null | jq -c 'if type == "array" then . else [] end' 2> /dev/null || echo '[]')
}

check_pipeline_success() {
  if [ -z "$REPO_ID" ]; then
    record_test "Pipeline Success" "FAIL" "no activated repo to inspect"
    return
  fi
  load_pipelines
  local n
  n=$(echo "$PIPELINES" | jq '[.[] | select(.status == "success")] | length')
  if [ "${n:-0}" -ge 1 ]; then
    record_test "Pipeline Success" "PASS" "${n} successful pipeline run(s)"
  else
    record_test "Pipeline Success" "FAIL" "no successful pipeline run — trigger one (Step 4)"
  fi
}

check_security_scan() {
  if [ -z "$REPO_ID" ]; then
    record_test "Security Scan" "FAIL" "no activated repo to inspect"
    return
  fi
  local num step
  for num in $(echo "$PIPELINES" | jq -r '[.[] | select(.status == "success")] | .[].number'); do
    step=$(api "/repos/${REPO_ID}/pipelines/${num}" 2> /dev/null | jq -r '[.workflows[]?.children[]? | select(.name == "dependency-scan" and .state == "success")] | length' 2> /dev/null)
    if [ "${step:-0}" -ge 1 ]; then
      record_test "Security Scan" "PASS" "dependency-scan (Trivy) step succeeded in pipeline #${num}"
      return
    fi
  done
  record_test "Security Scan" "FAIL" "no successful pipeline has a passing dependency-scan step (Step 5)"
}

check_failure_recovery() {
  if [ -z "$REPO_ID" ]; then
    record_test "Failure/Recovery" "FAIL" "no activated repo to inspect"
    return
  fi
  # A failed run followed later by a successful run.
  local ok
  ok=$(echo "$PIPELINES" | jq '
    ([.[] | select(.status == "failure") | .number] | min) as $f
    | if $f == null then false
      else ([.[] | select(.status == "success" and .number > $f)] | length) > 0 end')
  if [ "$ok" = "true" ]; then
    record_test "Failure/Recovery" "PASS" "a failed run was followed by a successful run"
  else
    record_test "Failure/Recovery" "FAIL" "need a failed run followed by a successful one (Step 6)"
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
    log_success "All tests passed!"
    echo "Move on to Module 06: Golden Path Pipelines."
    return 0
  fi
  log_error "Some tests failed."
  echo "See lab-01/instructions.md (Troubleshooting) for fixes."
  return 1
}

main() {
  log_info "Starting Yellow Belt Module 05 Lab 01 validation..."
  log_info "Woodpecker URL: ${WOODPECKER_URL}   Lab repo: ${LAB_REPO}"
  echo ""
  check_prerequisites
  check_stack
  check_api_auth
  check_repo_active
  check_pipeline_success
  check_security_scan
  check_failure_recovery
  print_summary
}

main "$@"
