# Plan: Medium and Low audit findings (AF-14 18 21 22 24)

The suite integration harness in uFawkes.dev (`tests/suite-integration`) found
these bugs. Each finding and its stated fix is in
`AUDIT_FINDINGS.md` there. This repository's share:

- AF-18: lab 02 reads the `.env` beside the caller, not the one in uFawkesAI.
- AF-21: lab 02 treats `gh` as optional.
- AF-22: the brown belt grader prints `000` once for a refused connection.
- AF-24: lab 02 filters containers in docker, so a busy host cannot SIGPIPE it.
- AF-14: `deploy-marker` exits non-zero without a commit SHA or pipeline URL.

## Verification Strategy

- Each finding has a harness test that asserts the correct behaviour. The test
  failed before this change and passes after it.
- `make suite-integration-test` in uFawkes.dev, run with this branch checked
  out beside the other five repositories: all tests pass, no finding
  reproduction is left.
- Pre-commit passes on this branch.
