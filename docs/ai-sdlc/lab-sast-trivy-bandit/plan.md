# Plan: Module 7 lab-01 describes Trivy and Bandit running in `sast`

**Traces to:** uFawkesPipe#288

## Changes

1. `yellow-belt/module-07-security-scanning/lab-01/instructions.md`: Step 6.2
   no longer disables `trivy` and `bandit`; Step 6.5 and Step 8 explain that,
   with the #288 fix, they run as `sast-trivy` and `sast-bandit`, and that on
   v2.0.0 they must still be set to `enabled: false`.

## Verification Strategy

| Criterion                                  | Evidence                                              | How                                                          |
| ------------------------------------------ | ----------------------------------------------------- | ------------------------------------------------------------ |
| The PR obeys the artifact chain            | `Artifact Chain` check passes                         | `bash scripts/check-artifact-chain.sh origin/main HEAD`      |
| Markdown stays valid                       | markdownlint and pre-commit pass                      | `pre-commit run --files <changed>`                           |
| The lab text matches the pinned release    | The v2.0.0 caveat is stated where the fix is described | Read Steps 6.2, 6.5 and 8 against uFawkesPipe#288            |
