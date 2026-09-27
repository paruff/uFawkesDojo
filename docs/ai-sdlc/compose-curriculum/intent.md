# Intent: Teach the uFawkes Compose Suite First

**Owner:** @paruff | **Created:** 2026-09-27 | **Status:** Draft
**Chain:** `intent.md` → [`spec.md`](spec.md) → [`plan.md`](plan.md)
**Suite plan:** [uFawkes.dev `docs/ai-sdlc/suite-release/`](https://github.com/paruff/uFawkes.dev/tree/main/docs/ai-sdlc/suite-release)

## Problem

The curriculum assumes a Kubernetes cluster from Module 1:
`white-belt/module-01-what-is-idp/lab-01/instructions.md` opens with
`kubectl rollout status`. That's a high barrier for a beginner track, and
parts of the content are stale:

- Yellow Belt teaches Jenkins, but Fawkes has dropped Jenkins for Tekton,
  and uFawkesPipe (the Compose CI plane) is Woodpecker.
- Several modules still say DORA has four key metrics; there are now five.

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

1. **What uFawkesDevX uses for Postgres now that uFawkesRes is
   deprecated.** It blocks White Belt only, and is tracked as
   paruff/uFawkesDevX#55 and the suite plan's AC-DEVX-01.
2. **Whether rewritten modules keep their current paths** (an in-place
   rewrite) **or become new modules with the old ones deprecated.** See
   `spec.md` R3.
3. **What certification becomes.** The suggested direction is a
   self-attested completion tied to a real capstone, with no badge
   infrastructure (per the module-authoring guide: badges support
   competence, they don't replace it). Open Badges would come later, and
   only if demand justifies it. This isn't approved yet.
