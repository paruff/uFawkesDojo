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

The curriculum today is built mostly against `fawkes` (Kubernetes,
ArgoCD, and Jenkins historically — Fawkes has since dropped Jenkins for
Tekton). The exception is Module 2's DORA lab, which already runs on
uFawkesObs (#10). The Kubernetes assumption starts at Module 1 —
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

Direction: teach the Compose-tier uFawkes stacks first, and treat
Fawkes/Kubernetes as a later "graduation" belt (Green Belt onward). That
means a lower barrier to entry, faster lab setup, and no cluster
required. Labs follow the suite's release order, each pinned to a
released stack version:

1. uFawkesObs content after its v1.0.0
2. uFawkesPipe → Yellow Belt after its v2.0.0
3. uFawkesDevX → White Belt after its v0.1.0

The feature chain is
[`docs/ai-sdlc/compose-curriculum/`](docs/ai-sdlc/compose-curriculum/)
(intent → spec → plan). The suite-wide plan lives in
[uFawkes.dev `docs/ai-sdlc/suite-release/`](https://github.com/paruff/uFawkes.dev/tree/main/docs/ai-sdlc/suite-release),
and live status in the
[uFawkes Suite Release Project](https://github.com/users/paruff/projects/7).

## What's real today vs. aspirational

This distinction matters more here than in most repos, because the repo's
own `content-integrity.yml` CI gate exists specifically to keep aspirational
content out of shipped lessons ("no lab step may be described unless it has
been run, for real").

**Real, shipped, and load-bearing:**
- The 20 belt module docs under `modules/<belt>/`. They are mostly
  Fawkes/Kubernetes-based; see Direction above for why that's changing.
- Two runnable labs, each run for real:
  - `white-belt/module-01-what-is-idp/lab-01/` — kubectl steps against a
    real cluster.
  - `white-belt/module-02-dora-metrics/lab-01/` — runs on uFawkesObs
    (Compose). It clones `main` unpinned; the pin comes after v1.0.0.

  The other 18 modules are theory only, with no executable lab.
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
- Certification badges and verification: not built. The live site marks
  them as planned (see Decisions below).
- The vision doc's "Implementation Roadmap"
  (`Fawkes Dojo: Immersive Learning Architecture.md`): Backstage plugin,
  auto-provisioned labs, auto-validation, progress tracking. None of it is
  built, and it is superseded by the Compose-first direction above.

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
- CI tooling: Jenkins is dropped from Fawkes entirely, replaced by Tekton
  (Fawkes-internal change). `uFawkesPipe` was always Woodpecker — a
  separate fact, not the resolution of that rename. Both mean Yellow Belt
  Module 5's Jenkins content is stale, regardless of which plane it
  targets.
- `uFawkesRes` is deprecated (confirmed). Dojo will not teach it or send
  learners to run it.
- Labs follow the suite release order (Obs → Pipe → DevX), each pinned to
  a released stack version, never `main`.
- The live site describes only what exists today. Certification and the
  PEU partnership appear only as "planned."

**Open, needs your call (see spec for detail):**
- Certification/badge mechanics: not implemented, and no longer claimed
  on the site. Suggested direction —
  a lightweight, self-attested completion artifact tied to a real capstone
  (build/operate something end-to-end), not a verifiable-badge platform,
  per the module-authoring guide's own rule 7 ("badges support competence,
  they don't replace it"). Building real badge infrastructure is a much
  bigger lift than the curriculum content itself; recommend deferring it
  until belt completion numbers justify it.
- What `uFawkesDevX` now uses for Postgres/Coder-DB/Backstage-DB, now that
  its documented `uFawkesRes` dependency is confirmed stale — that repo's
  own docs need their own fix, and Dojo's White Belt setup steps can't be
  written concretely until this is answered.

## Related repos

The uFawkes suite, per the ecosystem site's roadmap and each repo's own
README (cross-checked 2026-09-27):

- `fawkes` — Kubernetes-native IDP (ArgoCD, Tekton); the graduation target,
  not a suite-tier peer.
- `uFawkesObs` — observability plane (Compose: OTel, Prometheus, Loki,
  Tempo, Grafana).
- `uFawkesPipe` — CI/CD + security plane (Compose: Woodpecker, SonarQube,
  Trivy, Gitleaks, DefectDojo, Infisical — merged former `uFawkesSec`).
- `uFawkesDevX` — developer experience plane (Compose: Coder, Backstage,
  Score service, golden-path Cookiecutter templates). Its own docs still
  reference the now-deprecated `uFawkesRes` for Postgres — stale, see
  Decisions.
- `uFawkesRes` — deprecated. Formerly the resource plane (Postgres, Valkey,
  Traefik, Authelia).
- `uFawkesAI` — not a suite plane; an `AGENTS.md` scaffolding template used
  to build the others.
- `uFawkes.dev` — the suite's marketing/ecosystem site.
