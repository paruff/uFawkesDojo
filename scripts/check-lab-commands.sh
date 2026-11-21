#!/usr/bin/env bash
# scripts/check-lab-commands.sh — AC-008: what a lab names exists in the tag it pins.
#
#   check-lab-commands.sh [root]
#       For every lab under [root] (default: repo root) with a "Runs against"
#       line, clone each pinned stack tag (shallow) and check that every
#       `make <target>` and every `localhost:<port>` in the lab's
#       instructions.md exists there: the target in a Makefile, the port in a
#       compose file, Makefile or .env.example. Needs the network.
#       A lab that says "not yet run for real" is reported, not failed.
#
#   check-lab-commands.sh --targets <Makefile>     print its targets (testing)
#
# Exit 0 = every name resolves (or the lab is honestly labelled). Exit 1 = not.
# shortcut: reads text, not a parsed compose model; ports a student's own app
# opens must sit in a lab's "ports the learner creates" list below.
set -uo pipefail

TAG_RE='v[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9.]+)?'
# Ports a lab has the learner choose (their own app, or an alternative gateway port), not the stack's.
# shortcut: a flat allow-list, upgrade to a per-lab marker if it grows past a few.
LEARNER_PORTS=" 8080 3001 5001 8010 8090 "

targets() { grep -hoE '^[A-Za-z0-9_][A-Za-z0-9_.-]*:' "$1" 2> /dev/null | tr -d ':' | sort -u; }

if [[ "${1:-}" == "--targets" ]]; then
  targets "${2:?usage: --targets <Makefile>}"
  exit 0
fi

root="${1:-$(dirname "$0")/..}"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
failed=0

# clone_pin <Repo> <tag> -> dir (cached per repo+tag)
clone_pin() {
  local dir="$work/$1-$2"
  [[ -d "$dir" ]] || git clone -q --depth 1 --branch "$2" "https://github.com/paruff/$1.git" "$dir" 2> "$work/err" || {
    echo "check-lab-commands: cannot clone $1 $2: $(cat "$work/err")" >&2
    return 1
  }
  echo "$dir"
}

while IFS= read -r file; do
  line=$(grep -m1 '^\*\*Runs against\*\*' "$file" || true)
  [[ -n "$line" ]] || continue
  labelled=0
  grep -qiE 'not released yet|not yet run for real' "$file" && labelled=1

  dirs=()
  while read -r repo tag; do
    [[ -n "$repo" ]] || continue
    d=$(clone_pin "$repo" "$tag") || {
      failed=1
      continue
    }
    dirs+=("$d")
  done < <(grep -oE "uFawkes[A-Za-z]+[^A-Za-z0-9]{1,3}${TAG_RE}" <<< "$line" \
    | sed -E "s/^(uFawkes[A-Za-z]+)[^A-Za-z0-9]+(${TAG_RE})\$/\\1 \\2/")
  [[ ${#dirs[@]} -gt 0 ]] || continue

  all_targets=$(for d in "${dirs[@]}"; do targets "$d/Makefile"; done | sort -u)
  haystack=$(for d in "${dirs[@]}"; do
    find "$d" -maxdepth 3 \( -name 'docker-compose*.y*ml' -o -name 'compose*.y*ml' -o -name Makefile -o -name '.env.example' \) \
      -not -path '*/node_modules/*' -exec cat {} +
  done)

  missing=""
  # make targets: only commands (line start, backticks, after && or ;), never prose like "make it".
  while read -r t; do
    [[ -n "$t" ]] || continue
    grep -qx -- "$t" <<< "$all_targets" || missing+=" make:$t"
  done < <(grep -oE '(^[[:space:]]*(\$ )?|`|&& |; )make [a-z][A-Za-z0-9_.-]*' "$file" | awk '{print $NF}' | sort -u)

  while read -r p; do
    [[ -n "$p" ]] || continue
    [[ "$LEARNER_PORTS" == *" $p "* ]] && continue
    grep -qE "(^|[^0-9])${p}([^0-9]|\$)" <<< "$haystack" || missing+=" port:$p"
  done < <(grep -oE 'localhost:[0-9]{2,5}' "$file" | cut -d: -f2 | sort -u)

  if [[ -z "$missing" ]]; then
    echo "ok    $file"
  elif [[ "$labelled" -eq 1 ]]; then
    echo "warn  $file: not in the pinned tag:$missing (the lab says it is not yet run for real)"
  else
    echo "FAIL  $file: not in the pinned tag:$missing" >&2
    failed=1
  fi
done < <(find "$root" -path '*/lab-*/instructions.md' -not -path '*/node_modules/*' | sort)

exit "$failed"
