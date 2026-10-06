# Plan: Teach the uFawkes Compose Suite First

**Traces to:** [`spec.md`](spec.md) → [`intent.md`](intent.md)
**Status:** Draft | **Revision:** 3 | **State as of:** 2026-10-06
**Evidence:** [`audit-2026-10-06.md`](audit-2026-10-06.md)

Phases follow the suite release order. Each phase starts only after its
stack's release ships (spec R1), one module per PR, and every step is run for
real (spec R2, R7). This file holds order and verification, not task status:
live status is on the
[uFawkes Suite Release Project](https://github.com/users/paruff/projects/7)
(Release = "Dojo 0.2" or "Dojo labs") and in the issues.

## Where each phase stands

| Phase | Stack release today | Content | Run for real |
|---|---|---|---|
| 0.2.1 Accuracy + "Start here" | uFawkesAI `v2.0.0-rc.3` (no `v2.0.0`) | Guide, PR template, Module 0 and its lab merged | "Start here" on `rc.3`; **AC-DOJO-01 fails** (24 lines) |
| 0.2.2 uFawkesObs | `v1.0.6-rc.1` (no `v1.0.0`) | Module 2 lab-01 re-run (#79); Brown Belt 13–16 written | Module 2 lab-01; M13/M14 `validate.sh` in the nightly only |
| 0.2.3 uFawkesPipe | `v1.11.1-beta.1` (no `v2.0.0`) | Yellow Belt 5–8 written against `v2.0.0` | none |
| 0.2.4 uFawkesDevX | `v1.0.1` (stable) | White Belt 1/3/4 written against `v1.0.1` | none; ADR (uFawkesDevX#57) open |
| 0.2.5 Green Belt framing | none needed | Done (Modules 9–12) | n/a |

"Written" means the lab files exist. It does not mean a learner can follow
them. Twelve labs were merged ahead of their stacks without a run (audit F1).

## Phase 0.2.0 — Verify and gate (now, before any announcement)

1. Merge #79 (Module 2 lab-01 on `v1.0.6-rc.1`).
2. **Make AC-DOJO-01 pass.** Run the suite's script
   (`uFawkes.dev/scripts/checks/ac-dojo-01.sh`) with `CHECK_DOJO_DIR` set to
   the branch. Fix the 22 remaining lines: the vision doc, quiz distractors, same-line
   qualifiers, `index.html`, and the dead `.pre-commit-config.yaml` path.
3. **Quarantine the twelve unverified labs** (spec R7): add the header
   "Written ahead of its stack, not yet run for real" and remove release links
   to tags that do not exist. Relabel #42–#53 as "written, awaiting
   verification".
4. **Protect `main`** and add CODEOWNERS (#20), so R7 is enforced and not
   only written down.
5. Add the AC-006 script (every named tag exists) to the nightly and to lab PRs.
6. Owner decisions recorded 2026-10-06: pre-release pins are allowed, and 0.2
   may ship on `rc.3`. Still open: whether uFawkesDevX#57 gates White Belt.

## Phase 0.2.1 — Accuracy pass and "Start here" (Dojo 0.2)

1. Five DORA metrics, retired Jenkins labeling, and removal or labeling of
   unbuilt labs, videos and links (AC-DOJO-01): content done in #76 and #78; the
   suite's check still fails (Phase 0.2.0 step 2).
2. Extend the authoring guide (AC-DOJO-03): done, items 1–17 (#63, #66).
3. "Start here" lab (AC-DOJO-02): built and run on `rc.3` (#77). Dojo 0.2 may
   ship on this pre-release pin (owner decision, 2026-10-06). **Remaining, after
   0.2:** re-pin to uFawkesAI `v2.0.0` and re-run when it ships (#37).
4. Align this plan and ufawkes.dev's learn guides: this revision; uFawkes.dev
   #67 is closed.
5. Release Dojo `0.2` once AC-DOJO-01 passes and AC-DOJO-02 is met on the
   `rc.3` pin. Announce with
   uFawkesAI's follow-up post: "now learn it".

## Phase 0.2.2 — uFawkesObs (Dojo 0.3, after Obs stable)

1. **Pilot (AC-001):** Module 2 lab-01 pinned and re-run: done on `rc.3` (#79).
   **Remaining:** re-pin to the stable tag and re-run (#41).
2. Brown Belt 13–16, written. **Remaining:** run each for real against the
   newest rc, one lab per PR, labeled pre-release; re-pin on the stable tag.
   Fix the stale service names and event-schema steps first (#72).
3. Brown Belt graduation-delta lab (what changes on Fawkes), sourced from
   `uFawkesObs/docs/fawkes-migration.md`. Not started.

## Phase 0.2.3 — uFawkesPipe (Dojo 0.4, after Pipe `v2.0.0`)

1. Yellow Belt 5–8, written against a `v2.0.0` that does not exist.
   **Remaining:** run each for real against the newest Pipe release, labeled
   pre-release; re-pin on `v2.0.0`.
2. Give the GitHub OAuth app registration its own worked example, timed from
   a real first run. Not started.

## Phase 0.2.4 — uFawkesDevX (Dojo 0.5)

1. White Belt 1, 3 and 4, written against `v1.0.1`, which exists.
   **Remaining:** run each for real. This is the first lab set that can be
   fully verified today. Module 4 also depends on uFawkesPipe, so its run waits
   on a Pipe release.
2. Record the Postgres decision (AC-004, uFawkesDevX#57) or amend the spec to
   say it no longer gates White Belt.

## Phase 0.2.5 — Green Belt graduation framing

Done: "why Kubernetes now" and Tekton references in Modules 9–12 (#53).

## Phase 0.2.6 — The nightly (spec R8)

The nightly live acceptance (#55) runs 4 of 14 labs.

1. Add a `stack_ref` per lab (the lab's pinned tag). Keep a `main` run as an
   advisory early warning (AC-007).
2. Add the "Start here" lab, which is self-contained.
3. Run each lab's deterministic instruction steps, not only `validate.sh`
   (the verbatim-block technique used for #77).
4. The nine labs that need student artifacts stay in #73.
5. In uFawkes.dev, correct the `live-checks.yml` purpose text from "every lab's
   `validate.sh`" to the real coverage.

## Every phase

- Check the published lesson links for moved or rewritten modules (AC-002).
- Update `README.md`'s belt summary and `INTENT.md` when a phase completes.
- Do not close an issue with a closing keyword in a commit; close it from
  the PR that has the run evidence.

## Verification Strategy

| Criterion | Evidence | When |
|---|---|---|
| AC-001 | Real run transcript against the Obs tag in the pilot PR, plus the `content-integrity.yml` pass | Phase 0.2.2 step 1 |
| AC-002 | Manual check of each changed module's `lesson.html?src=` URL after deploy | Every phase |
| AC-003 | `grep -rn "git clone" white-belt brown-belt yellow-belt modules labs` shows `--branch vX.Y.Z` on every stack clone | Every lab PR |
| AC-004 | A link to uFawkesDevX's Postgres ADR, or an amended spec | Phase 0.2.4 |
| AC-005 | Authoring-guide boxes in the PR template checked, or each gap explained | Every module PR |
| AC-006 | Script: every tag a lab names exists | Phase 0.2.0 step 5; nightly |
| AC-007 | The nightly's checkout ref equals the lab's pin | Phase 0.2.6 |
| AC-DOJO-01 (suite) | `bash scripts/checks/ac-dojo-01.sh` in uFawkes.dev exits 0 | Before the 0.2 release |
