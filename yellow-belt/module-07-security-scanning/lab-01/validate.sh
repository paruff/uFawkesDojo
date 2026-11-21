#!/bin/bash
# =============================================================================
# Script: validate.sh
# Purpose: Validate Yellow Belt Module 07 Lab 01 completion criteria
# Usage:   WOODPECKER_TOKEN=<token> bash yellow-belt/module-07-security-scanning/lab-01/validate.sh
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
LAB_REPO="${LAB_REPO:-my-secure-app}"

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

# The gate worked if some run failed at dependency-scan (test skipped), and a later run succeeded.
check_gate() {
  need_repo "Gate Failed" || return
  need_pipelines "Gate Failed" || return
  local nums num body ok failed_at=""
  if ! nums=$(echo "$PIPELINES" | jq -r 'sort_by(.number) | .[].number'); then
    record_test "Gate Failed" "FAIL" "unexpected pipelines data (jq error above)"
    return
  fi
  for num in $nums; do
    if ! body=$(api "/repos/${REPO_ID}/pipelines/${num}"); then
      record_test "Gate Failed" "FAIL" "could not read pipeline #${num} (reason above)"
      return
    fi
    if ! ok=$(echo "$body" | jq -r '
      [.workflows[]?.children[]?] as $s
      | ([$s[] | select(.name == "dependency-scan")][0].state) as $d
      | ([$s[] | select(.name == "test")][0].state) as $t
      | ($d == "failure" and $t == "skipped")'); then
      record_test "Gate Failed" "FAIL" "unexpected pipeline #${num} data (jq error above)"
      return
    fi
    if [ "$ok" = "true" ]; then
      failed_at="$num"
      break
    fi
  done
  if [ -z "$failed_at" ]; then
    record_test "Gate Failed" "FAIL" "no run failed at dependency-scan with test skipped: add the vulnerable dependency and run (Step 3)"
    return
  fi
  record_test "Gate Failed" "PASS" "dependency-scan failed and test was skipped in pipeline #${failed_at}"
  if echo "$PIPELINES" | jq -e --argjson f "$failed_at" '[.[] | select(.status == "success" and .number > $f)] | length >= 1' > /dev/null; then
    record_test "Gate Recovered" "PASS" "a successful run came after failed pipeline #${failed_at}"
  else
    record_test "Gate Recovered" "FAIL" "no successful run after pipeline #${failed_at}: fix the finding and run again (Step 4)"
  fi
}

# sast succeeded in some run.
check_sast() {
  need_repo "SAST" || return
  need_pipelines "SAST" || return
  local num body
  for num in $(echo "$PIPELINES" | jq -r 'sort_by(.number) | .[].number'); do
    if ! body=$(api "/repos/${REPO_ID}/pipelines/${num}"); then
      record_test "SAST" "FAIL" "could not read pipeline #${num} (reason above)"
      return
    fi
    if echo "$body" | jq -e '[.workflows[]?.children[]? | select(.name == "sast" and .state == "success")] | length >= 1' > /dev/null; then
      record_test "SAST" "PASS" "sast succeeded in pipeline #${num}"
      return
    fi
  done
  record_test "SAST" "FAIL" "no run where sast succeeded (Step 6)"
}

# build succeeded and image-scan executed (it fails on a stock python base image, so either result counts).
check_image_scan() {
  need_repo "Image Scan" || return
  need_pipelines "Image Scan" || return
  local num body
  for num in $(echo "$PIPELINES" | jq -r 'sort_by(.number) | .[].number'); do
    if ! body=$(api "/repos/${REPO_ID}/pipelines/${num}"); then
      record_test "Image Scan" "FAIL" "could not read pipeline #${num} (reason above)"
      return
    fi
    if echo "$body" | jq -e '[.workflows[]?.children[]?] as $s
        | ([$s[] | select(.name == "build" and .state == "success")] | length >= 1)
          and ([$s[] | select(.name == "image-scan" and (.state == "success" or .state == "failure"))] | length >= 1)' > /dev/null; then
      record_test "Image Scan" "PASS" "build succeeded and image-scan ran in pipeline #${num}"
      return
    fi
  done
  record_test "Image Scan" "FAIL" "no run where build succeeded and image-scan ran (Step 7)"
}

# dast executed (it fails in v2.0.0 even when ZAP runs, so either result counts).
check_dast() {
  need_repo "DAST" || return
  need_pipelines "DAST" || return
  local num body
  for num in $(echo "$PIPELINES" | jq -r 'sort_by(.number) | .[].number'); do
    if ! body=$(api "/repos/${REPO_ID}/pipelines/${num}"); then
      record_test "DAST" "FAIL" "could not read pipeline #${num} (reason above)"
      return
    fi
    if echo "$body" | jq -e '[.workflows[]?.children[]? | select(.name == "dast" and .error == null and (.state == "success" or .state == "failure"))] | length >= 1' > /dev/null; then
      record_test "DAST" "PASS" "dast step ran in pipeline #${num}"
      return
    fi
  done
  record_test "DAST" "FAIL" "no run where the dast step ran (Step 9)"
}

# The upload step succeeded. This does not prove findings arrived: check DefectDojo (Step 10).
check_defectdojo() {
  need_repo "DefectDojo Upload" || return
  need_pipelines "DefectDojo Upload" || return
  local num body
  for num in $(echo "$PIPELINES" | jq -r 'sort_by(.number) | .[].number'); do
    if ! body=$(api "/repos/${REPO_ID}/pipelines/${num}"); then
      record_test "DefectDojo Upload" "FAIL" "could not read pipeline #${num} (reason above)"
      return
    fi
    if echo "$body" | jq -e '[.workflows[]?.children[]? | select(.name == "defectdojo-upload" and .state == "success")] | length >= 1' > /dev/null; then
      record_test "DefectDojo Upload" "PASS" "defectdojo-upload succeeded in pipeline #${num} (confirm the findings in DefectDojo)"
      return
    fi
  done
  record_test "DefectDojo Upload" "FAIL" "no run where defectdojo-upload succeeded (Step 10)"
}

print_summary() {
  echo ""
  echo "=========================================="
  echo "Yellow Belt Module 07 Lab 01 — Results"
  echo "=========================================="
  echo "Total Tests : $TOTAL_TESTS"
  echo "Passed      : $PASSED_TESTS"
  echo "Failed      : $FAILED_TESTS"
  echo ""
  if [ "$FAILED_TESTS" -eq 0 ]; then
    log_success "All tests passed!"
    echo "Move on to Module 08: Artifact Management."
    return 0
  fi
  log_error "Some tests failed."
  echo "See lab-01/instructions.md (Troubleshooting) for fixes."
  return 1
}

main() {
  log_info "Starting Yellow Belt Module 07 Lab 01 validation..."
  log_info "Woodpecker URL: ${WOODPECKER_URL}   Lab repo: ${LAB_REPO}"
  echo ""
  check_prerequisites
  check_stack
  check_api_auth
  check_repo_active
  check_pipeline_success
  check_gate
  check_sast
  check_image_scan
  check_dast
  check_defectdojo
  print_summary
}

main "$@"
