# Intent: Teach the uFawkes Compose Suite First

**Owner:** @paruff | **Created:** 2026-09-27 | **Updated:** 2026-10-06 | **Status:** Draft
**Chain:** `intent.md` → [`spec.md`](spec.md) → [`plan.md`](plan.md)
**Suite plan:** [uFawkes.dev `docs/ai-sdlc/suite-release/`](https://github.com/paruff/uFawkes.dev/tree/main/docs/ai-sdlc/suite-release)

## Problem

The curriculum assumes a Kubernetes cluster from Module 1:
`white-belt/module-01-what-is-idp/lab-01/instructions.md` opens with
`kubectl rollout status`. That's a high barrier for a beginner track, and
parts of the content are stale:

- Yellow Belt taught Jenkins, which Fawkes has replaced with Tekton, and
  uFawkesPipe (the Compose CI plane) is Woodpecker. Yellow Belt was rewritten
  for uFawkesPipe on 2026-10-05, ahead of any uFawkesPipe stable release.
- Several modules gave DORA as four metrics; the model now has five (fixed in
  the accuracy pass).

Meanwhile the uFawkes Compose stacks (uFawkesObs, uFawkesPipe,
uFawkesDevX) now exist, and they are explicitly positioned as the on-ramp
*before* Kubernetes. uFawkesObs's own migration notes call it "the
Compose-tier stepping stone you run until Kubernetes earns its operational
cost." And the pattern already works here: Module 2's DORA lab (#10) runs
on uFawkesObs with `make up-dora`, with no cluster needed. It clones
uFawkesObs's `main` branch unpinned, though.

## Goal

Learners do real, hands-on labs on the Compose stacks from their first
modules, without provisioning a cluster. Fawkes (Kubernetes) is taught
later as an explicit graduation step, once a learner needs what it adds.

## Decisions (from @paruff, 2026-09-27)

- **Labs follow the suite's release order.**
  1. uFawkesObs content first, right after its v1.0.0
  2. uFawkesPipe → Yellow Belt, after its v2.0.0
  3. uFawkesDevX → White Belt, after its v0.1.0
- **Every lab pins a released stack version, never `main`.**
- **No wrapping CLI.** `labs/fawkes-cli.py` was removed; each stack's
  `make` interface is the interface.
- **Certification is not implemented.** The site must not claim
  verifiable or employer-recognized badges.
- **The Platform Engineering University partnership is idea-stage.** The
  site must not present it as an active program.
- **Tooling facts:** Fawkes uses Tekton, uFawkesPipe uses Woodpecker, and
  uFawkesRes is deprecated.

## Assumptions

- Learners have Docker and Compose, but not necessarily a Kubernetes
  cluster. That's the whole barrier-reduction premise.

## Open questions

1. **What uFawkesDevX uses for Postgres now that uFawkesRes is deprecated.** Decided
   2026-10-06: SQLite for now (uFawkesDevX#57). It is not implemented in `v1.0.1`, which
   still needs an external Postgres and cannot build Backstage (uFawkesDevX#98).
2. **What certification becomes.** The suggested direction is a
   self-attested completion tied to a real capstone, with no badge
   infrastructure (per the module-authoring guide: badges support
   competence, they don't replace it). Open Badges would come later, and
   only if demand justifies it. This isn't approved yet.

Resolved on 2026-10-06 (owner): labs may pin a labeled pre-release (rc or beta)
tag, and Dojo 0.2 may ship on uFawkesAI `v2.0.0-rc.3`.

Resolved since 2026-09-27: rewritten modules keep their paths (in-place
rewrite), so published lesson links still resolve (spec R3).
