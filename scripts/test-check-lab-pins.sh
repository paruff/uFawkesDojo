#!/usr/bin/env bash
# scripts/test-check-lab-pins.sh — offline test for scripts/check-lab-pins.sh --print.
# Caller: SUITES in scripts/run-unit-tests.sh. Writes nothing outside a temp dir.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fail=0

expect() { # name, want, got
  if [[ "$2" == "$3" ]]; then echo "ok   $1"; else
    echo "FAIL $1: want '$2' got '$3'" >&2
    fail=1
  fi
}

printf '%s\n' '**Runs against**: [uFawkesObs `v1.1.0-rc.1`](https://github.com/paruff/uFawkesObs/releases/tag/v1.1.0-rc.1) (Docker Compose)' > "$tmp/a.md"
printf '%s\n' '**Runs against**: [uFawkesDevX v1.0.1](https://github.com/paruff/uFawkesDevX/releases/tag/v1.0.1) (Docker Compose)' > "$tmp/b.md"
printf '%s\n' '**Runs against**: uFawkesObs (Docker Compose) + uFawkesAI scripts' > "$tmp/c.md"
printf '%s\n' '**Runs against**: [uFawkesObs `v1.1.0-rc.1`](x) + [uFawkesAI `v2.0.0`](y)' > "$tmp/d.md"

expect "backticked pre-release tag" "v1.1.0-rc.1" "$(scripts/check-lab-pins.sh --print "$tmp/a.md" uFawkesObs)"
expect "plain stable tag" "v1.0.1" "$(scripts/check-lab-pins.sh --print "$tmp/b.md" uFawkesDevX)"
expect "picks the named repo from two" "v2.0.0" "$(scripts/check-lab-pins.sh --print "$tmp/d.md" uFawkesAI)"

if scripts/check-lab-pins.sh --print "$tmp/c.md" uFawkesObs > /dev/null 2>&1; then
  echo "FAIL an unpinned lab must exit non-zero" >&2
  fail=1
else
  echo "ok   unpinned lab exits non-zero"
fi

exit "$fail"
