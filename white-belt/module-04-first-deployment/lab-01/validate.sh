#!/bin/bash
# Validate White Belt Module 04 Lab 01 (uFawkesDevX v1.2.0).
# Usage: bash white-belt/module-04-first-deployment/lab-01/validate.sh   (from the uFawkesDojo root)
# Exit: 0 = all checks passed, 1 = one or more failed.
set -euo pipefail
# shellcheck source=../../devx-lib.sh
source "$(dirname "$0")/../../devx-lib.sh"

# The pipeline webhook records a run per trigger; the lab's Step 3 makes one.
check_pipeline_run() {
  local n
  n=$(curl -s --max-time 10 "${SCORE_API_URL}/pipelines/my-first-app" 2> /dev/null | jq -r '.pipelines | length' 2> /dev/null || echo 0)
  if [ "${n:-0}" -ge 1 ]; then
    record_test "Pipeline Trigger" "PASS" "my-first-app has ${n} recorded pipeline run(s)"
  else
    record_test "Pipeline Trigger" "FAIL" "no pipeline run for my-first-app: redo the trigger in Step 3"
  fi
}

log_info "Starting White Belt Module 04 Lab 01 validation..."
check_prerequisites
check_stack
check_catalog
check_scaffold my-first-app
check_spec my-first-app "Score Spec Submit"
check_pipeline_run

print_summary "White Belt Module 04 Lab 01"
