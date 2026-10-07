#!/usr/bin/env bash
# run-lab-instructions.sh — run a lab's instructions.md verbatim.
#
# Extracts every ```bash block from the file, in order, and runs them in ONE
# bash process (so `cd` and `export` carry from step to step, as they do for a
# student typing them). Each block is echoed under the nearest "## " heading,
# so the output reads as a transcript of the lab.
#
# A block whose preceding prose says "From your uFawkesDojo checkout" runs
# after `cd "$DOJO_DIR"` (default: this repo's root), because that is where
# the instructions tell the student to be.
#
# Usage: run-lab-instructions.sh path/to/instructions.md
# Exit: the exit status of the first failing command (set -e), else 0.

set -euo pipefail

file="${1:?usage: run-lab-instructions.sh path/to/instructions.md}"
[ -f "${file}" ] || {
  echo "no such file: ${file}" >&2
  exit 2
}
DOJO_DIR="${DOJO_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
export DOJO_DIR

script="$(mktemp)"
trap 'rm -f "${script}"' EXIT

awk -v q="'" '
  /^## / && !inblock { heading = substr($0, 4) }
  /^```bash[[:space:]]*$/ && !inblock {
    inblock = 1; n++
    print "printf \"\\n=== %s (block " n ") ===\\n\" " q heading q
    if (from_dojo) print "cd \"$DOJO_DIR\""
    print "set -x"
    from_dojo = 0
    next
  }
  /^```[[:space:]]*$/ && inblock { inblock = 0; print "{ set +x; } 2>/dev/null"; next }
  inblock { print; next }
  /From your uFawkesDojo checkout/ { from_dojo = 1 }
' "${file}" > "${script}"

if ! grep -q '^set -x$' "${script}"; then
  echo "no \`\`\`bash blocks found in ${file}" >&2
  exit 2
fi

bash -euo pipefail "${script}"
