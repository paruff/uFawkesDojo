#!/usr/bin/env bash
# scripts/check-lab-pins.sh — AC-006 and AC-007 for the labs' stack pins.
#
#   check-lab-pins.sh --print <instructions.md> <Repo>
#       Print the tag the lab's "Runs against" line pins <Repo> (e.g. uFawkesObs)
#       to. Exit 1, saying so, if the lab pins none. The nightly checks out this
#       exact ref (AC-007), so it tests what the lab tells students to run.
#
#   check-lab-pins.sh [root]
#       For every lab under [root] (default: repo root), check that each tag its
#       "Runs against" line names exists upstream (AC-006). Needs the network.
#       A lab that labels itself "not released yet" or "not yet run for real" is
#       a warning, not a failure: it says in plain words that its pin is ahead
#       of its stack.
#
# Exit 0 = every named tag exists (or is honestly labelled). Exit 1 = a lab names
# a tag that does not exist and does not say so.
set -uo pipefail

TAG_RE='v[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9.]+)?'

runs_against() { grep -m1 '^\*\*Runs against\*\*' "$1" || true; }

# repo+tag pairs on a "Runs against" line: "uFawkesObs `v1.1.0-rc.1`" or "uFawkesDevX v1.0.1"
pairs() {
  grep -oE "uFawkes[A-Za-z]+[^A-Za-z0-9]{1,3}${TAG_RE}" <<< "$1" \
    | sed -E "s/^(uFawkes[A-Za-z]+)[^A-Za-z0-9]+(${TAG_RE})\$/\\1 \\2/"
}

if [[ "${1:-}" == "--print" ]]; then
  file="${2:?usage: --print <instructions.md> <Repo>}"
  repo="${3:?usage: --print <instructions.md> <Repo>}"
  tag=$(pairs "$(runs_against "$file")" | awk -v r="$repo" '$1 == r {print $2; exit}')
  if [[ -z "$tag" ]]; then
    echo "check-lab-pins: $file pins no tag for $repo on its 'Runs against' line" >&2
    exit 1
  fi
  echo "$tag"
  exit 0
fi

root="${1:-$(dirname "$0")/..}"
failed=0
while IFS= read -r file; do
  line=$(runs_against "$file")
  [[ -n "$line" ]] || continue
  labelled=0
  grep -qiE 'not released yet|not yet run for real' "$file" && labelled=1
  while read -r repo tag; do
    [[ -n "$repo" ]] || continue
    if git ls-remote --exit-code --tags "https://github.com/paruff/${repo}.git" "refs/tags/${tag}" > /dev/null 2>&1; then
      echo "ok    $file: $repo $tag"
    elif [[ "$labelled" -eq 1 ]]; then
      echo "warn  $file: $repo $tag does not exist (the lab says so)"
    else
      echo "FAIL  $file: $repo $tag does not exist upstream and the lab does not say so" >&2
      failed=1
    fi
  done < <(pairs "$line")
done < <(find "$root" -path '*/lab-*/instructions.md' -not -path '*/node_modules/*' | sort)

exit "$failed"
