#!/usr/bin/env bash
set -euo pipefail
MSG_FILE="$1"
MSG=$(cat "$MSG_FILE")
if [[ "$MSG" =~ ^(fixup!|squash!|merge ) ]]; then
  exit 0
fi
if [[ ! "$MSG" =~ ^(feat|fix|docs|style|refactor|test|chore|ci|perf|build|revert)(\(.+\))?: .{1,72}$ ]]; then
  echo "ERROR: Commit message does not match Conventional Commits format" >&2
  echo "Expected: <type>(<scope>): <subject>" >&2
  echo "Got: $MSG" >&2
  exit 1
fi