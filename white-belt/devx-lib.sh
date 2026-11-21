#!/bin/bash
# Shared checks for the three uFawkesDevX labs (White Belt 1, 3, 4). Sourced by
# each lab's validate.sh; not run on its own. Pinned stack: uFawkesDevX v1.2.0.
#
# Env overrides: GATEWAY_URL, BACKSTAGE_URL, CODER_URL, UFDEVX_DIR.

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

BACKSTAGE_URL="${BACKSTAGE_URL:-http://localhost:7007}"
GATEWAY_URL="${GATEWAY_URL:-http://localhost:8000}"
SCORE_API_URL="${SCORE_API_URL:-${GATEWAY_URL}/api/score}"
CODER_URL="${CODER_URL:-}"
UFDEVX_DIR="${UFDEVX_DIR:-$HOME/dojo-labs/uFawkesDevX}"

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }

record_test() {
  local name="$1" status="$2" message="$3"
  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  if [ "$status" = "PASS" ]; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
    log_success "$name: $message"
  else
    FAILED_TESTS=$((FAILED_TESTS + 1))
    log_error "$name: $message"
  fi
}

check_prerequisites() {
  log_info "Checking prerequisites..."
  local missing=() cmd
  for cmd in docker git curl jq cookiecutter; do
    command -v "$cmd" > /dev/null 2>&1 || missing+=("$cmd")
  done
  docker compose version > /dev/null 2>&1 || missing+=("docker compose")
  if [ ${#missing[@]} -eq 0 ]; then
    record_test "Prerequisites" "PASS" "docker, docker compose, git, curl, jq, cookiecutter installed"
  else
    record_test "Prerequisites" "FAIL" "Missing: ${missing[*]} (cookiecutter: pip install cookiecutter)"
  fi
}

check_network() {
  if docker network inspect fawkes-net > /dev/null 2>&1; then
    record_test "Network" "PASS" "fawkes-net exists"
  else
    record_test "Network" "FAIL" "fawkes-net not found: run 'make network' in uFawkesDevX"
  fi
}

check_stack() {
  log_info "Checking uFawkesDevX service health..."
  local all_healthy=true container health
  for container in developerd-coder developerd-backstage developerd-score developerd-plugin-manager developerd-gateway; do
    health=$(docker inspect --format '{{.State.Health.Status}}' "$container" 2> /dev/null || echo "missing")
    if [ "$health" = "healthy" ]; then
      log_success "  $container: healthy"
    else
      log_error "  $container: $health"
      all_healthy=false
    fi
  done
  if [ "$all_healthy" = "true" ]; then
    record_test "uFawkesDevX Stack" "PASS" "all 5 services healthy (coder, backstage, score-service, plugin-manager, gateway)"
  else
    record_test "uFawkesDevX Stack" "FAIL" "a service is not healthy: run 'make status' in uFawkesDevX"
  fi
}

# Backstage answers 401 without a token; the lab runs in guest mode, so take a guest token.
check_catalog() {
  log_info "Checking Backstage catalog API..."
  local token systems
  token=$(curl -s --max-time 10 "${BACKSTAGE_URL}/api/auth/guest/refresh" | jq -r '.backstageIdentity.token // empty' 2> /dev/null)
  if [ -z "$token" ]; then
    record_test "Backstage Catalog" "FAIL" "no guest token from ${BACKSTAGE_URL}/api/auth/guest/refresh: is Backstage up?"
    return
  fi
  systems=$(curl -s --max-time 10 -H "Authorization: Bearer $token" "${BACKSTAGE_URL}/api/catalog/entities?filter=kind=System" | jq -r '.[].metadata.name' 2> /dev/null | tr '\n' ' ')
  if [[ "$systems" == *developer-control-plane* ]]; then
    record_test "Backstage Catalog" "PASS" "systems: ${systems}"
  else
    record_test "Backstage Catalog" "FAIL" "developer-control-plane not in the catalog (got: ${systems:-none})"
  fi
}

check_gateway() {
  local code
  code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${GATEWAY_URL}/health" 2> /dev/null || echo "000")
  if [ "$code" = "200" ]; then
    record_test "Gateway" "PASS" "reachable at ${GATEWAY_URL}"
  else
    record_test "Gateway" "FAIL" "HTTP $code at ${GATEWAY_URL}/health (does another service hold port 8000? set GATEWAY_PORT in .env)"
  fi
}

check_coder() {
  if [ -z "$CODER_URL" ] && [ -f "${UFDEVX_DIR}/.env" ]; then
    CODER_URL=$(grep -E '^CODER_ACCESS_URL=' "${UFDEVX_DIR}/.env" | cut -d= -f2- | tr -d '"' || true)
  fi
  if [ -z "$CODER_URL" ]; then
    record_test "Coder" "FAIL" "CODER_ACCESS_URL not set in ${UFDEVX_DIR}/.env"
    return
  fi
  local code
  code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "${CODER_URL}/healthz" 2> /dev/null || echo "000")
  if [ "$code" = "200" ]; then
    record_test "Coder" "PASS" "reachable at ${CODER_URL}"
  else
    record_test "Coder" "FAIL" "HTTP $code at ${CODER_URL}/healthz"
  fi
}

# check_spec <name> [<label>]: the Score service holds a validated spec called <name>.
check_spec() {
  local name="$1" label="${2:-Score spec $1}" body
  body=$(curl -s --max-time 10 "${SCORE_API_URL}/specs/${name}" 2> /dev/null || true)
  if [ "$(jq -r '.status // empty' <<< "$body" 2> /dev/null)" = "validated" ]; then
    record_test "$label" "PASS" "${name} is registered (version $(jq -r .version <<< "$body"))"
  else
    record_test "$label" "FAIL" "${name} not registered in the Score service: re-run the Score API step"
  fi
}

# check_scaffold <dir>: cookiecutter output exists under the uFawkesDevX checkout.
check_scaffold() {
  if [ -f "${UFDEVX_DIR}/$1/score.yaml" ] && [ -f "${UFDEVX_DIR}/$1/.fawkespipe.yml" ]; then
    record_test "Scaffolded Service" "PASS" "$1 has score.yaml and .fawkespipe.yml"
  else
    record_test "Scaffolded Service" "FAIL" "${UFDEVX_DIR}/$1 not found: re-run the cookiecutter step"
  fi
}

print_summary() { # <title>
  echo ""
  echo "=========================================="
  echo "$1 — Results"
  echo "=========================================="
  echo "Total Tests : $TOTAL_TESTS"
  echo "Passed      : $PASSED_TESTS"
  echo "Failed      : $FAILED_TESTS"
  echo ""
  if [ "$FAILED_TESTS" -eq 0 ]; then
    log_success "All tests passed! ✅"
    return 0
  fi
  log_error "Some tests failed! ❌ See the lab's Troubleshooting table."
  return 1
}
