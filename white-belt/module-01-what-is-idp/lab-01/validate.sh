#!/bin/bash
# Validate White Belt Module 01 Lab 01 (uFawkesDevX v1.2.0).
# Usage: bash white-belt/module-01-what-is-idp/lab-01/validate.sh   (from the uFawkesDojo root)
# Exit: 0 = all checks passed, 1 = one or more failed.
set -euo pipefail
# shellcheck source=../../devx-lib.sh
source "$(dirname "$0")/../../devx-lib.sh"

log_info "Starting White Belt Module 01 Lab 01 validation..."
check_prerequisites
check_network
check_stack
check_catalog
check_gateway
check_coder
check_scaffold hello-devx
check_spec hello-devx "Score registration"

print_summary "White Belt Module 01 Lab 01"
