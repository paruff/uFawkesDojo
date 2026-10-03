#!/bin/bash
# =============================================================================
# Script: validate.sh
# Purpose: Validate White Belt Module 02 Lab 02 — one check per acceptance
#          criterion of uFawkesAI docs/ai-sdlc/dora-events/spec.md
#          (AC-01…AC-05; rubric = spec, per uFawkesAI docs/ai-sdlc/dojo-handoff.md)
# Usage:   Run from inside your uFawkesAI checkout:
#            bash /path/to/uFawkesDojo/white-belt/module-02-dora-metrics/lab-02/validate.sh
#          Env: LAB_DIR (default ~/dojo-delivery-events), PYTHON (default python3)
# Exit Codes: 0=all checks passed, 1=one or more checks failed
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

LAB_DIR="${LAB_DIR:-$HOME/dojo-delivery-events}"
PYTHON="${PYTHON:-python3}"
EVENTS="$LAB_DIR/my-events.jsonl"
ARTIFACT="$LAB_DIR/artifact/dora-events.jsonl"

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

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

# Runs a check command; a check that can't run is a FAIL with the reason
# printed — never silently skipped.
check() { # check <AC> <pass message> <fail message> <command...>
  local ac="$1" ok_msg="$2" fail_msg="$3" out
  shift 3
  if out="$("$@" 2>&1)"; then
    record_test "$ac" "PASS" "$ok_msg"
  else
    record_test "$ac" "FAIL" "$fail_msg"
    [ -z "$out" ] || echo "$out" | tail -5 | sed 's/^/      /'
  fi
}

log_info "Checking prerequisites..."
if [ ! -f scripts/emit-dora-event.sh ]; then
  log_error "Run this from your uFawkesAI checkout (scripts/emit-dora-event.sh not found)"
  exit 1
fi
for tool in jq gh "$PYTHON"; do
  command -v "$tool" >/dev/null 2>&1 || { log_error "$tool not found — see Prerequisites"; exit 1; }
done

log_info "Grading against uFawkesAI docs/ai-sdlc/dora-events/spec.md..."

# AC-01: Events are single-line JSON with dora-log.sh's fields
check "AC-01" "your events are single-line JSON with dora-log.sh's fields" \
  "no valid event in $EVENTS — redo Step 3" \
  jq -se 'length > 0 and all(.[]; has("@timestamp") and has("level") and has("logger")
    and has("message") and has("pipeline") and has("repo") and has("step"))' "$EVENTS"

# AC-02: agent_tokens and PR cycle time are present for a real PR
check "AC-02" "your job-finish carries agent_tokens and a PR cycle time" \
  "job-finish in $EVENTS has no agent_tokens/pr.cycle_time_seconds — set GITHUB_REPOSITORY and use --pr (Step 3)" \
  jq -se 'any(.[]; .event == "job-finish" and (.agent_tokens | type) == "object"
    and (.pr.cycle_time_seconds | type) == "number" and .repo != "unknown")' "$EVENTS"

# AC-03: the pipeline's deploy-marker dora_event validates against uFawkesObs's schema
validate_schema() {
  grep '"deploy-marker"' "$ARTIFACT" | head -1 | jq '.dora_event' >"$LAB_DIR/.dora_event.json"
  "$PYTHON" - scripts/testdata/ufawkesobs-deployment-event.schema.json "$LAB_DIR/.dora_event.json" <<'PY'
import json, sys
from jsonschema import Draft7Validator, FormatChecker
schema, event = (json.load(open(p)) for p in sys.argv[1:3])
errors = list(Draft7Validator(schema, format_checker=FormatChecker()).iter_errors(event))
for e in errors:
    print(f"{list(e.path)}: {e.message}")
sys.exit(1 if errors else 0)
PY
}
check "AC-03" "the real deploy-marker's dora_event is a valid uFawkesDORA deployment event" \
  "dora_event from $ARTIFACT failed schema validation (or the artifact/jsonschema is missing)" \
  validate_schema

# AC-04: OTLP export works in your environment (the emitter's own proof)
check "AC-04" "the emitter's test suite passes here, including the OTLP export checks" \
  "scripts/test-emit-dora-event.sh failed — redo Step 1" \
  env PYTHON="$PYTHON" bash scripts/test-emit-dora-event.sh

# AC-05: a real pipeline run produced ingestible events with tokens + cycle time
check "AC-05" "a real pipeline run's artifact has job-start, job-finish and a deploy-marker with tokens + cycle time" \
  "$ARTIFACT is missing or incomplete — redo Step 2" \
  jq -se '([.[].event] | index("job-start") != null and index("job-finish") != null)
    and any(.[]; .event == "deploy-marker" and .repo == "paruff/uFawkesAI"
      and (.agent_tokens.output // 0) > 0 and (.pr.cycle_time_seconds | type) == "number")' "$ARTIFACT"

echo
log_info "Results: ${PASSED_TESTS}/${TOTAL_TESTS} checks passed"
if [ "$FAILED_TESTS" -gt 0 ]; then
  log_error "Lab 02 not complete — fix the failed checks above and re-run"
  exit 1
fi
log_success "Lab 02 complete — every acceptance criterion verified"
