#!/usr/bin/env bash
set -euo pipefail
MSG_FILE="${1:-}"
if [[ -z "$MSG_FILE" ]]; then
  echo "ERROR: No commit message file provided" >&2
  exit 1
fi
MSG=$(cat "$MSG_FILE")
if [[ "$MSG" =~ ^(fixup!|squash!|merge ) ]]; then
  exit 0
fi
# Conventional Commits regex: type(scope): subject
# type: feat|fix|docs|style|refactor|test|chore|ci|perf|build|revert
# scope: optional, in parentheses
# subject: 1-72 chars
TYPE_REGEX='^(feat|fix|docs|style|refactor|test|chore|ci|perf|build|revert)'
SCOPE_REGEX='(\([^)]*\))?'
SUBJECT_REGEX=': .{1,72}$'
FULL_REGEX="${TYPE_REGEX}${SCOPE_REGEX}${SUBJECT_REGEX}"
if [[ ! "$MSG" =~ $FULL_REGEX ]]; then
  echo "ERROR: Commit message does not match Conventional Commits format" >&2
  echo "Expected: <type>(<scope>): <subject>" >&2
  echo "Got: $MSG" >&2
  exit 1
fi
