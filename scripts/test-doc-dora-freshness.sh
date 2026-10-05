#!/usr/bin/env bash
# scripts/test-doc-dora-freshness.sh — fail if retired DORA service names
# reappear in current-state docs.
#
# Retired by uFawkesObs ADR-007 (compute folded into dora-api): there is no
# `dora-compute` container and no Pushgateway — dora-api computes in-process
# and Prometheus scrapes dora-api:8088/metrics. Docs that still teach the old
# topology send students to containers that do not exist.
#
# Exclusion: lab `instructions.md` files. Their stale references are
# inventoried line-by-line in issue #72 and remediated there; the exclusion
# is printed below, never silent. Everything else is checked.
set -uo pipefail

cd "$(dirname "$0")/.." || exit 1

pattern='dora-compute|[Pp]ushgateway|otel-collector-dora'

matches="$(grep -rniE "$pattern" \
  --include='*.md' \
  --exclude-dir=.git --exclude-dir=.omo --exclude-dir=.serena \
  --exclude-dir=.claude --exclude-dir=.opencode --exclude-dir=node_modules \
  . 2> /dev/null | grep -v 'instructions\.md' || true)"

if [ -n "$matches" ]; then
  echo "FAIL: retired DORA service reference(s) in current-state docs:"
  printf '%s\n' "$matches"
  echo
  echo "dora-compute / pushgateway / otel-collector-dora do not exist on the"
  echo "stack (dora profile = dora-api only; pull model, job_name=dora-api)."
  echo "Lab instructions.md files are excluded (tracked in issue #72)."
  exit 1
fi

echo "✅ doc-dora-freshness: no retired DORA service references in current-state docs (instructions.md excluded, tracked in #72)"
