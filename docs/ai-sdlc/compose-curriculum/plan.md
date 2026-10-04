# Plan: Teach the uFawkes Compose Suite First

**Traces to:** [`spec.md`](spec.md) → [`intent.md`](intent.md)
**Status:** Draft | **Revision:** 2

Phases follow the suite release order. Each phase starts only after its
stack's release ships (spec R1). One module per PR, and every step is run
for real (spec R2). Live status is tracked in the
[uFawkes Suite Release Project](https://github.com/users/paruff/projects/7)
under Release = "Dojo compose", not in this file.

## Phase 0.2.1 — Accuracy pass (Dojo 0.2, before any stack lab)

1. Five DORA metrics everywhere (#19). Every module that still teaches
   Jenkins says so at the top and names the replacement module's release.
   Every lab, video or community link that doesn't exist is either removed
   or labeled "not built yet".
2. Extend the existing module-authoring guide (AC-DOJO-03).
3. Build the "Start here" uFawkesAI lab and run it for real.
4. Update `docs/ai-sdlc/compose-curriculum/plan.md` to this order, and align
   ufawkes.dev's learn guides (uFawkes.dev #67).
5. Release Dojo `0.2`. Announce with uFawkesAI follow-up: "now learn it".

## Phase 0.2.2 — uFawkesObs content (after uFawkesObs v1.0.0, Dojo 0.3)

1. **Pilot (AC-001):** pin `white-belt/module-02-dora-metrics/lab-01/`
   to `v1.0.0` and re-run it end to end, including `validate.sh`.
2. Brown Belt Modules 13–16 → uFawkesObs, one module per PR. Add an
   explicit spacing boundary to any module still over about 90 minutes.
3. Add the Brown Belt graduation-delta lab: what changes on Fawkes. Source
   it from `uFawkesObs/docs/fawkes-migration.md`.

## Phase 0.2.3 — uFawkesPipe → Yellow Belt (after uFawkesPipe v2.0.0, Dojo 0.4)

1. Modules 5–8 → uFawkesPipe (Woodpecker, the `.fawkespipe.yml`
   contract, security scanning, DefectDojo). This retires the Jenkins
   content.
2. Give the GitHub OAuth app registration its own worked example, timed
   from a real first run.

## Phase 0.2.4 — uFawkesDevX → White Belt (after uFawkesDevX v0.1.0 + AC-004, Dojo 0.5)

1. Modules 1, 3 and 4 → uFawkesDevX (Backstage catalog, a Cookiecutter
   golden path as "first deployment"). This replaces the kubectl-first
   Module 1 lab.

## Phase 0.2.5 — Green Belt graduation framing (no stack dependency, Dojo 0.6)

1. Add a "why Kubernetes now" opening to Modules 9–12.
2. Update CI references to Tekton. Keep the existing ArgoCD labs.

This phase can run any time, in parallel with 0.2.2–0.2.4.

## Every phase

- Check the published lesson links for moved or rewritten modules
  (AC-002).
- Update `README.md`'s belt summary and `INTENT.md`'s Direction section
  when a phase completes.

## Verification Strategy

| Criterion | Evidence | When |
|---|---|---|
| AC-001 | Real run transcript against uFawkesObs `v1.0.0` in the pilot PR, plus the `content-integrity.yml` pass | Phase 0.2.2 step 1 |
| AC-002 | Manual check of each changed module's `lesson.html?src=` URL after deploy | Every phase |
| AC-003 | `grep -rn "git clone" white-belt modules labs` shows `--branch vX.Y.Z` on every stack clone | Every lab PR |
| AC-004 | A link to uFawkesDevX's Postgres ADR in the Phase 0.2.4 PR | Phase 0.2.4 start |