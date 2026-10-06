#!/usr/bin/env bash
# validate.sh — White Belt Module 00 Lab 01 ("Start here") validation
# Checks: your repo, the pinned CDE image, the six harness components, and one
# intent -> spec -> plan chain. Every failure line says what to do next.
# Usage: validate.sh [path-to-your-repo]   (default: ~/dojo-labs/my-first-ai-sdlc)
# Exit: 0 on all pass, 1 on any fail.

set -uo pipefail

LAB_DIR="${1:-${LAB_DIR:-${HOME}/dojo-labs/my-first-ai-sdlc}}"
FEATURE="docs/ai-sdlc/first-feature"

RED='\033[0;31m'
GRN='\033[0;32m'
NC='\033[0m'

pass=0
fail=0
total=0

log_ok() {
  echo -e "${GRN}[✓]${NC} $*"
  pass=$((pass + 1))
  total=$((total + 1))
}
log_fail() {
  echo -e "${RED}[✗]${NC} $*"
  fail=$((fail + 1))
  total=$((total + 1))
}

summary() {
  echo
  echo "=========================================="
  echo "Total Tests: ${total}"
  echo "Passed: ${pass}"
  echo "Failed: ${fail}"
  echo "=========================================="
  if [ "${fail}" -eq 0 ]; then
    echo -e "${GRN}[✓] All tests passed! ✅${NC}"
    echo
    echo "You ran one intent → spec → plan cycle on a pinned template."
    echo "Next: write your time and three answers in Step 6, then Module 1."
    exit 0
  fi
  echo -e "${RED}[✗] Some tests failed. Each [✗] line says what to do next.${NC}"
  exit 1
}

# ── 1. Your repo ─────────────────────────────────────────────────────────
if ! command -v git > /dev/null 2>&1; then
  log_fail "git is not installed → install git, then re-run"
  summary
fi
if [ ! -d "${LAB_DIR}/.git" ]; then
  log_fail "No git repo at ${LAB_DIR} → do Step 1, or pass your path: ./validate.sh /path/to/repo"
  summary
fi
log_ok "Your repo exists at ${LAB_DIR}"
cd "${LAB_DIR}" || exit 1

# ── 2. Pinned CDE image ──────────────────────────────────────────────────
image="$(grep -E '^\s*"image"' .devcontainer/devcontainer.json 2> /dev/null | head -1)"
if echo "${image}" | grep -qE 'ghcr\.io/paruff/fawkes-space:2\.0\.0(-rc\.[0-9]+)?(@sha256:[0-9a-f]{64})?"'; then
  log_ok "CDE image is pinned: $(echo "${image}" | sed -E 's/.*"image": *"([^"]+)".*/\1/')"
else
  log_fail "CDE image is not pinned to fawkes-space 2.0.0 (found: ${image:-no image line}) → Step 2: edit .devcontainer/devcontainer.json"
fi

# ── 3. Six harness components ────────────────────────────────────────────
check_component() {
  local name="$1" file="$2"
  if [ -e "${file}" ]; then
    log_ok "Harness component — ${name}: ${file}"
  else
    log_fail "Harness component — ${name}: ${file} is missing → Step 3: re-clone, or restore it with git checkout -- ${file}"
  fi
}
check_component "Instructions" "AGENTS.md"
check_component "Tools / MCP" ".mcp.json"
check_component "Sandbox" ".devcontainer/devcontainer.json"
check_component "Orchestration" ".agents/agents/planner.md"
check_component "Hooks" ".pre-commit-config.yaml"
check_component "Observability" "scripts/emit-dora-event.sh"

# ── 4. One intent -> spec -> plan chain ──────────────────────────────────
missing_files=""
need_heading() {
  local file="$1" heading="$2"
  if [ ! -f "${FEATURE}/${file}" ]; then
    case "${missing_files}" in
      *" ${file}"*) ;; # already reported once
      *)
        log_fail "${FEATURE}/${file} is missing → Step 4: write it (see the worked example in docs/ai-sdlc/v2.0.0/)"
        missing_files="${missing_files} ${file}"
        ;;
    esac
  elif grep -qE "^## ${heading}\s*$" "${FEATURE}/${file}"; then
    log_ok "${file} has a '## ${heading}' section"
  else
    log_fail "${file} has no '## ${heading}' heading → Step 4: add it, as in docs/ai-sdlc/v2.0.0/${file}"
  fi
}
need_heading intent.md "Problem"
need_heading intent.md "Desired Outcome"
need_heading spec.md "Requirements"
need_heading plan.md "Verification Strategy"

if [ -f "${FEATURE}/spec.md" ] && [ -f "${FEATURE}/plan.md" ]; then
  reqs="$(grep -oE 'REQ-[0-9]+' "${FEATURE}/spec.md" | sort -u)"
  if [ -z "${reqs}" ]; then
    log_fail "spec.md names no requirement ids → Step 4: write each requirement as **REQ-001 — what it must do.**"
  else
    strategy="$(sed -n '/^## Verification Strategy/,$p' "${FEATURE}/plan.md")"
    missing=""
    for r in ${reqs}; do
      echo "${strategy}" | grep -q "${r}" || missing="${missing} ${r}"
    done
    if [ -z "${missing}" ]; then
      log_ok "Every requirement in spec.md has a row in the plan's Verification Strategy"
    else
      log_fail "plan.md's Verification Strategy has no row for:${missing} → Step 4: add one row per requirement, with a command that proves it"
    fi
  fi
fi

# ── 5. The template's own chain check (intent must exist before spec) ────
if [ -x scripts/check-artifact-chain.sh ]; then
  base="$(git rev-list --max-parents=0 HEAD | tail -1)"
  if chain_out="$(bash scripts/check-artifact-chain.sh "${base}" 2>&1)"; then
    log_ok "scripts/check-artifact-chain.sh: artifact chain intact"
  else
    log_fail "scripts/check-artifact-chain.sh failed → Step 4: every spec.md needs an intent.md next to it, committed. Output:"
    while IFS= read -r line; do echo "        ${line}"; done <<< "${chain_out}"
  fi
else
  log_fail "scripts/check-artifact-chain.sh not found → Step 1: re-clone the template"
fi

summary
