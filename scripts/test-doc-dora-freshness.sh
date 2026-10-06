#!/usr/bin/env bash
# scripts/test-doc-dora-freshness.sh — fail if retired DORA service names
# reappear in current-state docs.
#
# Retired by uFawkesObs ADR-007 (compute folded into dora-api): there is no
# `dora-compute` container and no Pushgateway — dora-api computes in-process
# and Prometheus scrapes dora-api:8088/metrics. Docs that still teach the old
# topology send students to containers that do not exist. The pattern covers
# the separator variants too (`dora_compute`, `dora compute`), not just the
# hyphenated name.
#
# Exclusion: lab `instructions.md` files, matched by FILE NAME via grep's
# --exclude — never by the text of a line, so a finding cannot be hidden by
# prose that merely mentions the file. Their stale references are inventoried
# in issue #72, and every excluded file is printed on every run: an
# exclusion that isn't printed is indistinguishable from no exclusion at all.
#
# grep's exit status is honoured: 0 and 1 are match/no-match, 2 means the
# scan itself broke, which fails the check loudly. A guard that cannot run
# must never print a passing check.
set -uo pipefail

cd "$(dirname "$0")/.." || exit 1

pattern='dora[-_ ]compute|[Pp]ushgateway|otel-collector-dora'

if ! excluded_files="$(find . -name 'instructions.md' \
  -not -path './.git/*' -not -path './.omo/*' -not -path './.serena/*' \
  -not -path './.claude/*' -not -path './.opencode/*' \
  -not -path './node_modules/*' | sort)"; then
  echo "FAIL: doc-dora-freshness: cannot list the excluded files" >&2
  exit 1
fi

scan="$(grep -rniE "$pattern" \
  --include='*.md' --exclude='instructions.md' \
  --exclude-dir=.git --exclude-dir=.omo --exclude-dir=.serena \
  --exclude-dir=.claude --exclude-dir=.opencode --exclude-dir=node_modules \
  . 2>&1)"
rc=$?

if [ "$rc" -ge 2 ]; then
  echo "FAIL: doc-dora-freshness: the scan errored (grep exit $rc), not a pass:" >&2
  printf '%s\n' "$scan" >&2
  exit 1
fi

if [ -n "$scan" ]; then
  echo "FAIL: retired DORA service reference(s) in current-state docs:"
  printf '%s\n' "$scan"
  echo
  echo "dora-compute / pushgateway / otel-collector-dora do not exist on the"
  echo "stack (dora profile = dora-api only; pull model, job_name=dora-api)."
fi

echo "excluded by file name (student-facing lab steps, stale refs tracked in #72):"
printf '%s\n' "$excluded_files" | sed 's/^/  /'

if [ -n "$scan" ]; then
  exit 1
fi

echo "✅ doc-dora-freshness: no retired DORA service references in current-state docs"
exit 0
