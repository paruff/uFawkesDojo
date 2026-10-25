# REVIEW.md

Apply the suite rules in [uFawkesAI REVIEW.md](https://github.com/paruff/uFawkesAI/blob/main/REVIEW.md):
severity, what to flag (verification, validation, security), what to skip, the
output and the board move. This file adds only what is specific to this repo.

## Checks the PR must paste

- `pre-commit run --all-files`
- `make verify-labs`
- `npx @google/design.md@0.4.0 lint DESIGN.md` when `DESIGN.md` changes: 0 errors, 0 warnings

## UI

The three pages follow [`DESIGN.md`](DESIGN.md).
