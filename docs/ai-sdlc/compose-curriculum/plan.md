# Plan: Teach the uFawkes Compose Suite First

**Traces to:** [`spec.md`](spec.md) → [`intent.md`](intent.md)
**Status:** Draft | **Revision:** 1

Phases follow the suite release order. Each phase starts only after its
stack's release ships (spec R1). One module per PR, and every step is run
for real (spec R2). Live status is tracked in the
[uFawkes Suite Release Project](https://github.com/users/paruff/projects/7)
under Release = "Dojo compose", not in this file.

## Phase A — uFawkesObs content (after uFawkesObs v1.0.0)

1. **Pilot (AC-001):** pin `white-belt/module-02-dora-metrics/lab-01/`
   to `v1.0.0` and re-run it end to end, including `validate.sh`.
2. Brown Belt Modules 13–16 → uFawkesObs, one module per PR. Add an
   explicit spacing boundary to any module still over about 90 minutes.
3. Add the Brown Belt graduation-delta lab: what changes on Fawkes. Source
   it from `uFawkesObs/docs/fawkes-migration.md`.

## Phase B — uFawkesPipe → Yellow Belt (after uFawkesPipe v2.0.0)

1. Modules 5–8 → uFawkesPipe (Woodpecker, the `.fawkespipe.yml`
   contract, security scanning, DefectDojo). This retires the Jenkins
   content.
2. Give the GitHub OAuth app registration its own worked example, timed
   from a real first run.

## Phase C — uFawkesDevX → White Belt (after uFawkesDevX v0.1.0 + AC-004)

1. Modules 1, 3 and 4 → uFawkesDevX (Backstage catalog, a Cookiecutter
   golden path as "first deployment"). This replaces the kubectl-first
   Module 1 lab.

## Phase D — Green Belt graduation framing (no stack dependency)

1. Add a "why Kubernetes now" opening to Modules 9–12.
2. Update CI references to Tekton. Keep the existing ArgoCD labs.

This phase can run any time, in parallel with A–C.

## Every phase

- Check the published lesson links for moved or rewritten modules
  (AC-002).
- Update `README.md`'s belt summary and `INTENT.md`'s Direction section
  when a phase completes.

## Verification Strategy

| Criterion | Evidence | When |
|---|---|---|
| AC-001 | Real run transcript against uFawkesObs `v1.0.0` in the pilot PR, plus the `content-integrity.yml` pass | Phase A step 1 |
| AC-002 | Manual check of each changed module's `lesson.html?src=` URL after deploy | Every phase |
| AC-003 | `grep -rn "git clone" white-belt modules labs` shows `--branch vX.Y.Z` on every stack clone | Every lab PR |
| AC-004 | A link to uFawkesDevX's Postgres ADR in the Phase C PR | Phase C start |
