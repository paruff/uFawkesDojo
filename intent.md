# Intent

## Purpose

uFawkesDojo is the belt-level, hands-on platform engineering curriculum for
the uFawkes suite: a family of composable, Docker Compose-based platform
engineering stacks (`uFawkesObs`, `uFawkesPipe`, `uFawkesDevX`), with
[fawkes](https://github.com/paruff/fawkes) — the Kubernetes-native IDP — as
the graduation target once a team's scale justifies that operational cost.
It teaches platform engineering by having learners build and operate a
real platform — not by reading about one.

Learners progress through five belt levels (White → Yellow → Green → Brown →
Black), each covering a slice of the 24 DORA capabilities, each with hands-on
labs and a certification assessment.

## Direction (as of 2026-09-27)

The curriculum today (all 20 modules, all shipped labs) is built entirely
against `fawkes` (Kubernetes, ArgoCD, Jenkins) starting from Module 1 —
`white-belt/module-01-what-is-idp/lab-01/instructions.md` opens with
`kubectl rollout status`. That's a real, working lab, but it assumes a
Kubernetes cluster is already available, which is a high barrier for
Module 1 of a beginner track.

Since this repo's earlier content was written, three more uFawkes stacks
have shipped as Docker Compose ("zero to running in 60 seconds," per their
own docs), explicitly positioned as the on-ramp *before* Kubernetes:
`uFawkesObs` (observability), `uFawkesPipe` (CI/CD — Woodpecker-based, not
Jenkins), and `uFawkesDevX` (Backstage/Coder/golden-paths). uFawkesObs's own
migration notes state the intended sequencing directly: **"Fawkes replaces
uFawkesObs wholesale... uFawkesObs is the Compose-tier stepping stone you
run until Kubernetes earns its operational cost."**

Proposed direction: restructure the curriculum so White/Yellow Belt (and as
much of Green Belt as holds up) teach the Compose-tier uFawkes stacks —
lower barrier to entry, faster lab setup, no cluster required — and treat
Fawkes/Kubernetes explicitly as a later "graduation" track once a learner
needs what it adds. See `docs/uFawkes-suite-integration-spec.md` for the
full analysis, phased plan, and open decisions this requires before any
module gets rewritten.

## What's real today vs. aspirational

This distinction matters more here than in most repos, because the repo's
own `content-integrity.yml` CI gate exists specifically to keep aspirational
content out of shipped lessons ("no lab step may be described unless it has
been run, for real").

**Real, shipped, and load-bearing:**
- The 20 belt module docs under `modules/<belt>/` — currently all
  Fawkes/Kubernetes-based (see Direction above for why that's under review).
- Per-lab `instructions.md` files (e.g.
  `white-belt/module-01-what-is-idp/lab-01/instructions.md`) — plain kubectl
  steps against a real cluster, run for real.
- `dojo.ufawkes.dev`, a static GitHub Pages site (`index.html` +
  `lesson.html`) that lists the belt curriculum and renders each module's
  markdown in place, on-domain.
- CI: markdown lint, commit-message lint, and the content-integrity
  placeholder gate.

**Removed as over-engineered (2026-09-27):**
- `labs/fawkes-cli.py` and `labs/setup.py` — a sketched-out packaged CLI
  that imported a `lab_automation` module which never existed. Deleted
  rather than built out: each uFawkes stack already ships its own
  Makefile-driven interface (`make up`, `make init`), so a wrapping CLI
  duplicated an interface that already exists per-stack.

**Prototype, not yet real:**
- Anything in `onboarding.html` describing `fawkes secret set`, `fawkes`
  CLI commands, etc. — these describe the platform CLI's target UX, not a
  currently runnable tool in this repo.
- Certification badges/verification referenced on the live site (see
  Decisions below).

## Non-goals

- This repo does not host any platform itself — that's `fawkes` and the
  uFawkes stacks. uFawkesDojo is the learning-plane layer on top of them.
- Not a general DevOps course — scope is specifically the Fawkes/uFawkes IDP
  family and its golden paths, tied to the 24 DORA capabilities.
- Not a wrapping CLI or automation layer — each stack's own `make`/Woodpecker
  interface is the interface; the Dojo teaches it, it doesn't re-abstract it.

## Decisions and open questions

**Decided:**
- `labs/fawkes-cli.py` — over-engineered for what's needed, removed (see
  above), not rebuilt.
- Platform Engineering University co-branding, mentioned on the live site
  — still an idea, not a confirmed partnership. No implementation implied;
  revisit the site copy if it reads as more certain than that.

**Open, needs your call (see spec for detail):**
- Certification/badge mechanics: the live site promises verifiable badges
  and employer recognition, and none of that exists. Suggested direction —
  a lightweight, self-attested completion artifact tied to a real capstone
  (build/operate something end-to-end), not a verifiable-badge platform,
  per the module-authoring guide's own rule 7 ("badges support competence,
  they don't replace it"). Building real badge infrastructure is a much
  bigger lift than the curriculum content itself; recommend deferring it
  until belt completion numbers justify it.
- Whether to formally consolidate `uFawkesRes` — `uFawkesObs`'s README
  states it was retired 2026-08-18 (merged into Obs/Pipe), but
  `uFawkesDevX`'s architecture doc (updated 2026-09-14, after that date)
  still shows it as a live dependency for Postgres. This is a cross-repo
  inconsistency outside this repo's own docs — flagged here because it
  affects which stack Dojo labs should point at for shared Postgres/SSO.

## Related repos

The uFawkes suite, per the ecosystem site's roadmap and each repo's own
README (cross-checked 2026-09-27 — some repos disagree on `uFawkesRes`'s
status, see above):

- `fawkes` — Kubernetes-native IDP; the graduation target, not a suite-tier
  peer.
- `uFawkesObs` — observability plane (Compose: OTel, Prometheus, Loki,
  Tempo, Grafana).
- `uFawkesPipe` — CI/CD + security plane (Compose: Woodpecker, SonarQube,
  Trivy, Gitleaks, DefectDojo, Infisical — merged former `uFawkesSec`).
- `uFawkesDevX` — developer experience plane (Compose: Coder, Backstage,
  Score service, golden-path Cookiecutter templates).
- `uFawkesRes` — resource plane (Postgres, Valkey, Traefik, Authelia);
  status disputed across repos, see above.
- `uFawkesAI` — not a suite plane; an `AGENTS.md` scaffolding template used
  to build the others.
- `uFawkes.dev` — the suite's marketing/ecosystem site.
