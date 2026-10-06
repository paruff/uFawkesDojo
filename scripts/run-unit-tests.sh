#!/usr/bin/env bash
# scripts/run-unit-tests.sh — run every offline test suite in this repo.
#
# One entry point so pre-commit, preflight, and CI run exactly the same set.
# Previously each suite was invoked ad hoc, and three of the four were wired
# to nothing at all.
#
# All five suites are offline and dependency-free: they stub `gh`, bind an
# ephemeral loopback port, and use vendored fixtures. That is what makes them
# safe to run on every commit — a test that needs the network or a pip install
# is a test whose result depends on the machine, not the code.
#
# Exit 0 = every suite passed. Exit 1 = at least one failed.
set -uo pipefail

cd "$(dirname "$0")/.." || exit 1

SUITES=(
  scripts/test-check-secret-detection.sh
  scripts/test-emit-dora-event.sh
  scripts/test-artifact-chain.sh
  scripts/test-dojo-feedback-intent.sh
  scripts/test-doc-dora-freshness.sh
)

failed=0

# Parity: every scripts/test-*.sh must be registered in SUITES above — a
# suite that exists but is never listed would never run, and the summary
# would still read "all passed".
for candidate in scripts/test-*.sh; do
  [[ -e "$candidate" ]] || continue
  listed=0
  for suite in "${SUITES[@]}"; do
    if [[ "$suite" == "$candidate" ]]; then listed=1; fi
  done
  if [[ "$listed" -eq 0 ]]; then
    echo "run-unit-tests: $candidate exists but is not registered in SUITES" >&2
    failed=1
  fi
done

results=()

for suite in "${SUITES[@]}"; do
  name="$(basename "$suite" .sh)"
  if [[ ! -f "$suite" ]]; then
    results+=("MISSING  $name")
    failed=1
    continue
  fi
  if out="$(bash "$suite" 2>&1)"; then
    last="$(printf '%s\n' "$out" | grep -E '✅|passed|PASSED|BEHAVED' | tail -1 | sed 's/^[[:space:]]*//')"
    results+=("PASS     $name — ${last:-ok}")
  else
    results+=("FAIL     $name")
    failed=1
    printf '\n─── %s failed ───\n%s\n\n' "$name" "$out" >&2
  fi
done

echo "Unit test suites (${#SUITES[@]}):"
for line in "${results[@]}"; do
  echo "  $line"
done

if [[ "$failed" -ne 0 ]]; then
  echo
  echo "run-unit-tests: FAILED" >&2
  exit 1
fi

echo "run-unit-tests: all ${#SUITES[@]} suites passed."
