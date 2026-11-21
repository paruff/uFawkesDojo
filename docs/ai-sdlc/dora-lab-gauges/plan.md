# Plan: DORA gauges populate for the stack-verified labs

**Traces to:** paruff/uFawkesObs#739

## Changes

1. Have dora-api count `test` deploys as well as `production` ones, by setting
   its compute-environments variable in `scripts/verify-labs.sh` and
   `.github/workflows/_lab-acceptance.yml`. The labs post
   `environment: test` deploys and dora-api counts only `production` by
   default (uFawkesObs DC-05).
2. M14 lab-01 `validate.sh`: treat `dora_fdrt_p50_hours` as expected-empty, like
   lead time (the lab posts no failure then success).

## Verification Strategy

| Criterion                         | Evidence                                                        | How                                                              |
| --------------------------------- | --------------------------------------------------------------- | ---------------------------------------------------------------- |
| Gauges populate for a lab event   | `dora_deployment_frequency_per_week` returned by Prometheus     | `make up-dora` in uFawkesObs with the env set, POST a test event |
| Scripts stay valid                | shellcheck, shfmt, actionlint pass                              | `pre-commit run --files <changed>`                               |
| Nightly Live Acceptance recovers  | M02 lab-01 and M14 lab-01 pass                                  | The scheduled Live Acceptance run after merge                    |
