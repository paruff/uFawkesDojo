# Intent

## Purpose

uFawkesDojo is the belt-level, hands-on platform engineering curriculum
extracted from [fawkes](https://github.com/paruff/fawkes) (the core Fawkes
IDP platform). It teaches platform engineering by having learners build and
operate a real, production-like platform — not by reading about one.

Learners progress through five belt levels (White → Yellow → Green → Brown →
Black), each covering a slice of the 24 DORA capabilities, each with hands-on
labs and a certification assessment.

## Audience

Engineers learning Internal Delivery Platform (IDP) practices: platform
engineers, DevOps engineers moving into platform roles, and SREs — spanning
from "no platform experience" (start at White Belt) to experienced platform
engineers filling specific skill gaps (jump to Black Belt topics).

## What's real today vs. aspirational

This distinction matters more here than in most repos, because the repo's
own `content-integrity.yml` CI gate exists specifically to keep aspirational
content out of shipped lessons ("no lab step may be described unless it has
been run, for real").

**Real, shipped, and load-bearing:**
- The 20 belt module docs under `modules/<belt>/`.
- Per-lab `instructions.md` files (e.g.
  `white-belt/module-01-what-is-idp/lab-01/instructions.md`) — plain kubectl
  steps against a real cluster, run for real.
- `dojo.ufawkes.dev`, a static GitHub Pages site (`index.html` +
  `lesson.html`) that lists the belt curriculum and renders each module's
  markdown in place, on-domain.
- CI: markdown lint, commit-message lint, and the content-integrity
  placeholder gate.

**Prototype, not yet real:**
- `labs/fawkes-cli.py` and `labs/setup.py` — a sketched-out packaged CLI
  (`fawkes lab start`, `fawkes assessment validate`, etc.) that imports a
  `lab_automation` module which doesn't exist anywhere. Marked with a
  `STATUS: PROTOTYPE` note in both files as of 2026-09-27. Don't remove that
  note without actually making the code run.
- Anything in `onboarding.html` describing `fawkes secret set`, `fawkes`
  CLI commands, etc. — these describe the platform CLI's target UX, not a
  currently runnable tool in this repo.

## Non-goals

- This repo does not host the platform itself — that's `fawkes`. uFawkesDojo
  is the learning-plane layer on top of it.
- Not a general DevOps course — scope is specifically the Fawkes IDP and its
  golden paths, tied to the 24 DORA capabilities.
- Not a replacement for `fawkes-cli` if/when that's built for real — this
  repo's prototype is a sketch, not the source of truth for that CLI's design.

## Open questions (business/product — not inferable from the repo)

These aren't answered anywhere in code or docs; they're flagged here rather
than guessed at:
- Whether `labs/fawkes-cli.py` is still wanted (build it for real) or dead
  weight to delete once confirmed unused.
- Certification recognition/verification mechanics referenced on the site
  (badges, LinkedIn, employer recognition) — no implementation exists yet.
- Platform Engineering University co-branding terms mentioned on the live
  site — external partnership details, not tracked in this repo.

## Related repos

Part of the Fawkes IDP family: `fawkes` (core platform) · `uFawkesPipe`
(CI/CD) · `uFawkesObs` (observability) · `uFawkes.dev` (marketing site).
