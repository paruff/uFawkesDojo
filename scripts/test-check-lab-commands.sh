#!/usr/bin/env bash
# scripts/test-check-lab-commands.sh — offline test for check-lab-commands.sh --targets.
# Caller: SUITES in scripts/run-unit-tests.sh. Writes nothing outside a temp dir.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fail=0

printf '%s\n' '.PHONY: up' 'up: ## start' '	docker compose up' 'up-security:' 'VAR := x' 'a.b-c:' > "$tmp/Makefile"
got=$(scripts/check-lab-commands.sh --targets "$tmp/Makefile" | tr '\n' ' ')
want="a.b-c up up-security "
if [[ "$got" == "$want" ]]; then echo "ok   lists targets, not .PHONY or variables"; else
  echo "FAIL targets: want '$want' got '$got'" >&2
  fail=1
fi
exit "$fail"
