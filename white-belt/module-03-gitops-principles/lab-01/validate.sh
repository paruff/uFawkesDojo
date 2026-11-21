#!/bin/bash
# Validate White Belt Module 03 Lab 01 (uFawkesDevX v1.2.0).
# Usage: bash white-belt/module-03-gitops-principles/lab-01/validate.sh   (from the uFawkesDojo root)
# Exit: 0 = all checks passed, 1 = one or more failed.
set -euo pipefail
# shellcheck source=../../devx-lib.sh
source "$(dirname "$0")/../../devx-lib.sh"

# The rollback step re-submits the good spec last, so its image must be :latest
# and the spec must be at version 3 or more (good, bad, good).
check_rollback() {
  local body
  body=$(curl -s --max-time 10 "${SCORE_API_URL}/specs/hello-gitops" 2> /dev/null || true)
  if [ "$(jq -r '.spec.containers["hello-gitops"].image // empty' <<< "$body" 2> /dev/null)" = "ghcr.io/dojo/hello-gitops:latest" ] \
    && [ "$(jq -r '.version // 0' <<< "$body" 2> /dev/null || echo 0)" -ge 3 ]; then
    record_test "Rollback Pattern" "PASS" "hello-gitops is back on :latest at version $(jq -r .version <<< "$body")"
  else
    record_test "Rollback Pattern" "FAIL" "hello-gitops should be on ghcr.io/dojo/hello-gitops:latest at version 3+: redo Step 4"
  fi
}

log_info "Starting White Belt Module 03 Lab 01 validation..."
check_prerequisites
check_stack
check_catalog
check_gateway
check_spec hello-gitops "Direct API Registration"
check_rollback
check_scaffold hello-scaffolded
check_spec hello-scaffolded "Cookiecutter Registration"

print_summary "White Belt Module 03 Lab 01"
