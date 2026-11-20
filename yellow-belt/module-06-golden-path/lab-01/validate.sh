#!/bin/bash
# =============================================================================
# Script: validate.sh
# Purpose: Validate Yellow Belt Module 06 Lab 01 completion criteria
# Usage:   WOODPECKER_TOKEN=<token> bash yellow-belt/module-06-golden-path/lab-01/validate.sh
#          WOODPECKER_URL defaults to http://localhost:8000; set it to match
#          WOODPECKER_UI_PORT in uFawkesPipe's .env if you changed the port.
# Exit Codes: 0=all checks passed, 1=one or more checks failed
#
# A check that cannot run (server down, bad token, unexpected response) says so
# and why; it never reports that as "you have not done the step".
# =============================================================================

set -uo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

WOODPECKER_URL="${WOODPECKER_URL:-http://localhost:8000}"
WOODPECKER_TOKEN="${WOODPECKER_TOKEN:-}"
LAB_REPO="${LAB_REPO:-my-golden-path-app}"

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
REPO_ID=""
PIPELINES=""

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

# GET <path> from the Woodpecker API. Prints the body on HTTP 200. On any other
# outcome it prints why to stderr and returns 1, so callers can report the cause.
api() {
  local out code
  if ! out=$(curl -sS --max-time 15 -w '\n%{http_code}' -H "Authorization: Bearer ${WOODPECKER_TOKEN}" "${WOODPECKER_URL}/api$1"); then
    echo "API call failed: GET $1 (curl error above)" >&2
    return 1
  fi
  code="${out##*$'\n'}"
  if [ "$code" != "200" ]; then
    echo "API call failed: GET $1 returned HTTP ${code} (401 = stale or wrong token)" >&2
    return 1
  fi
  printf '%s' "${out%$'\n'*}"
}

# Record a FAIL and return 1 unless the lab repo was found by check_repo_active.
need_repo() {
  [ -n "$REPO_ID" ] && return 0
  record_test "$1" "FAIL" "skipped: ${LAB_REPO} was not found active (see Repo Activated)"
  return 1
}

# Record a FAIL and return 1 unless check_pipeline_success fetched the pipeline list.
need_pipelines() {
  [ -n "$PIPELINES" ] && return 0
  record_test "$1" "FAIL" "skipped: the pipeline list could not be read (see Pipeline Success)"
  return 1
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
  local running bad=()
  for svc in woodpecker-server woodpecker-agent; do
    if ! running=$(docker ps --filter "label=com.docker.compose.service=${svc}" --filter "status=running" --format '{{.Names}}'); then
      record_test "Stack" "FAIL" "could not query Docker (error above); is the Docker daemon running?"
      return
    fi
    [ -n "$running" ] || bad+=("$svc")
  done
  if [ ${#bad[@]} -eq 0 ]; then
    record_test "Stack" "PASS" "woodpecker-server and woodpecker-agent are running"
  else
    record_test "Stack" "FAIL" "Not running: ${bad[*]} — run: docker compose -f compose.yaml up -d woodpecker-server woodpecker-agent (in uFawkesPipe)"
  fi
}

check_api_auth() {
  if [ -z "$WOODPECKER_TOKEN" ]; then
    record_test "Woodpecker API" "FAIL" "WOODPECKER_TOKEN is not set (Woodpecker UI → avatar → User settings → Personal Access Token)"
    return
  fi
  if api "/user" > /dev/null; then
    record_test "Woodpecker API" "PASS" "token accepted at ${WOODPECKER_URL}"
  else
    record_test "Woodpecker API" "FAIL" "GET /api/user failed at ${WOODPECKER_URL} (reason above)"
  fi
}

check_repo_active() {
  local body
  if ! body=$(api "/user/repos?all=true"); then
    record_test "Repo Activated" "FAIL" "could not list repos (reason above)"
    return
  fi
  if ! REPO_ID=$(echo "$body" | jq -r --arg n "$LAB_REPO" '[.[] | select(.name == $n and .active == true)][0].id // empty'); then
    REPO_ID=""
    record_test "Repo Activated" "FAIL" "unexpected response from /api/user/repos (jq error above)"
    return
  fi
  if [ -n "$REPO_ID" ]; then
    record_test "Repo Activated" "PASS" "${LAB_REPO} is active in Woodpecker (id ${REPO_ID})"
  else
    record_test "Repo Activated" "FAIL" "${LAB_REPO} not found or not active — activate it (Step 3)"
  fi
}

check_pipeline_success() {
  need_repo "Pipeline Success" || return
  local body n
  if ! body=$(api "/repos/${REPO_ID}/pipelines?perPage=50"); then
    record_test "Pipeline Success" "FAIL" "could not list pipelines (reason above)"
    return
  fi
  PIPELINES="$body"
  if ! n=$(echo "$PIPELINES" | jq '[.[] | select(.status == "success")] | length'); then
    record_test "Pipeline Success" "FAIL" "unexpected pipelines response (jq error above)"
    return
  fi
  if [ "$n" -ge 1 ]; then
    record_test "Pipeline Success" "PASS" "${n} successful pipeline run(s)"
  else
    record_test "Pipeline Success" "FAIL" "no successful pipeline run — trigger one (Step 4)"
  fi
}

check_parallel() {
  need_repo "Parallel Execution" || return
  need_pipelines "Parallel Execution" || return
  local nums num body ok
  if ! nums=$(echo "$PIPELINES" | jq -r '[.[] | select(.status == "success")] | .[].number'); then
    record_test "Parallel Execution" "FAIL" "unexpected pipelines data (jq error above)"
    return
  fi
  for num in $nums; do
    if ! body=$(api "/repos/${REPO_ID}/pipelines/${num}"); then
      record_test "Parallel Execution" "FAIL" "could not read pipeline #${num} (reason above)"
      return
    fi
    # lint and dependency-scan have no dependency on each other: their time windows must overlap.
    if ! ok=$(echo "$body" | jq -r '
      [.workflows[]?.children[]?] as $s
      | ([$s[] | select(.name == "lint")][0]) as $a
      | ([$s[] | select(.name == "dependency-scan")][0]) as $b
      | if $a == null or $b == null then false
        else ($a.started < $b.finished and $b.started < $a.finished) end'); then
      record_test "Parallel Execution" "FAIL" "unexpected pipeline #${num} data (jq error above)"
      return
    fi
    if [ "$ok" = "true" ]; then
      record_test "Parallel Execution" "PASS" "lint and dependency-scan overlapped in pipeline #${num}"
      return
    fi
  done
  record_test "Parallel Execution" "FAIL" "no successful pipeline has overlapping lint and dependency-scan steps (Step 4; enable both stages in the contract)"
}

check_performance_measured() {
  need_repo "Performance Measured" || return
  need_pipelines "Performance Measured" || return
  local n times
  if ! n=$(echo "$PIPELINES" | jq '[.[] | select(.status == "success")] | length'); then
    record_test "Performance Measured" "FAIL" "unexpected pipelines response (jq error above)"
    return
  fi
  if [ "$n" -lt 2 ]; then
    record_test "Performance Measured" "FAIL" "need at least 2 successful runs to compare durations (Step 5); found ${n}"
    return
  fi
  if ! times=$(echo "$PIPELINES" | jq -r '[.[] | select(.status == "success")] | sort_by(.number) | map("#\(.number)=\(.finished - .started)s") | join(" ")'); then
    record_test "Performance Measured" "FAIL" "could not compute durations (jq error above)"
    return
  fi
  record_test "Performance Measured" "PASS" "${n} successful runs, durations: ${times}"
}

print_summary() {
  echo ""
  echo "=========================================="
  echo "Yellow Belt Module 06 Lab 01 — Results"
  echo "=========================================="
  echo "Total Tests : $TOTAL_TESTS"
  echo "Passed      : $PASSED_TESTS"
  echo "Failed      : $FAILED_TESTS"
  echo ""
  if [ "$FAILED_TESTS" -eq 0 ]; then
    log_success "All tests passed!"
    echo "Move on to Module 07: Security Scanning."
    return 0
  fi
  log_error "Some tests failed."
  echo "See lab-01/instructions.md (Troubleshooting) for fixes."
  return 1
}

main() {
  log_info "Starting Yellow Belt Module 06 Lab 01 validation..."
  log_info "Woodpecker URL: ${WOODPECKER_URL}   Lab repo: ${LAB_REPO}"
  echo ""
  check_prerequisites
  check_stack
  check_api_auth
  check_repo_active
  check_pipeline_success
  check_parallel
  check_performance_measured
  print_summary
}

main "$@"
