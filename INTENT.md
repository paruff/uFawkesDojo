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

## Direction (as of 2026-10-06)

Teach the Compose-tier uFawkes stacks first, and treat Fawkes/Kubernetes as a
later "graduation" belt (Green Belt onward). That means a lower barrier to
entry, faster lab setup, and no cluster required. uFawkesObs's own migration
notes state the intended sequencing: **"Fawkes replaces uFawkesObs
wholesale... uFawkesObs is the Compose-tier stepping stone you run until
Kubernetes earns its operational cost."**

Labs follow the suite's release order and pin a released stack tag, never
`main`: uFawkesAI (Dojo 0.2), then uFawkesObs, uFawkesPipe and uFawkesDevX.
uFawkesAI tagged `v2.0.0` on 2026-10-07 (with `fawkes-space:2.0.0`).
**As of 2026-11-21** the stable tags the labs pin are uFawkesObs `v1.0.1`,
uFawkesPipe `v2.0.1` and uFawkesDevX `v1.2.0`. Labs written ahead of a release
are marked "not yet run for real" until they are verified against a tag that
exists (see the audit below).

The feature chain is
[`docs/ai-sdlc/compose-curriculum/`](docs/ai-sdlc/compose-curriculum/)
(intent → spec → plan), with the current state in
[`audit-2026-10-06.md`](docs/ai-sdlc/compose-curriculum/audit-2026-10-06.md).
The suite-wide plan lives in
[uFawkes.dev `docs/ai-sdlc/suite-release/`](https://github.com/paruff/uFawkes.dev/tree/main/docs/ai-sdlc/suite-release),
and live status in the
[uFawkes Suite Release Project](https://github.com/users/paruff/projects/7).

## What's real today vs. aspirational

This distinction matters more here than in most repos, because the repo's
own `content-integrity.yml` CI gate exists specifically to keep aspirational
content out of shipped lessons ("no lab step may be described unless it has
been run, for real").

**Run for real, with evidence:**
- `white-belt/module-00-vibe-coding-to-agentic/lab-01/` ("Start here") — on
  uFawkesAI `v2.0.0`, 14/14, run verbatim end to end, devcontainer included,
  by `start-here-live.yml` on every change to the lab and nightly.
- `white-belt/module-02-dora-metrics/lab-01/` — on uFawkesObs `v1.1.0-rc.1`
  (pre-release pin), re-run in #79.
- `brown-belt/module-13-observability/lab-01/` — on uFawkesObs
  `v1.1.0-rc.1` (pre-release pin), run verbatim end to end in #86.
- `brown-belt/module-13-observability/` to `module-16-incident-management/`
  (`lab-01` each) — on uFawkesObs `v1.0.1` (stable), run on 2026-11-10 through
  the stack's APIs; Grafana's browser-only clicks were not exercised.
- `white-belt/module-01-what-is-idp/`, `module-03-gitops-principles/` and
  `module-04-first-deployment/` (`lab-01` each) — on uFawkesDevX `v1.2.0`,
  run on 2026-11-21 (no database to set up). Not run: Module 1 Step 6 (needs
  the `coder` CLI). Module 3's Backstage Scaffolder template fails on `v1.2.0`
  (no `http:post` action) and is documented as such; Module 4 uses Cookiecutter,
  the Score API and a local container instead of the Scaffolder, Woodpecker and
  Coder.
- `yellow-belt/module-05-ci-fundamentals/` to `module-08-artifact-management/`
  (`lab-01` each) — on uFawkesPipe `v2.0.0`, run on 2026-11-20 and 2026-11-21.
  Several steps needed workarounds that the labs list; it is not a run of an
  unmodified release. They pin uFawkesDevX `v1.2.0` for the `python-flask-app` template: it
  differs from `v1.0.1` by one comment, and the scaffold and pipeline-generation
  steps were re-run on `v1.2.0` with identical output (the pipeline runs were not).
- A nightly live acceptance run (`live-acceptance.yml`) boots a real uFawkesObs
  stack and runs the self-checks of Module 2 labs 01 and 02 and Brown Belt
  13 and 14 in full, and Brown Belt 15 and 16 as `validate.sh --stack-only`:
  the stack, and for BB15 the metric its SLIs use, but not the rules, alerts,
  dashboard or postmortem a student creates. A stack-only pass is not a lab
  pass. It runs `validate.sh`, not the instructions' steps. A second job boots
  uFawkesDevX at the tag Lab 1 pins, scripts the student half of White Belt 1, 3
  and 4 (`scripts/run-devx-labs.sh`) and runs their `validate.sh`. Yellow Belt
  5-8 are not covered: they target uFawkesPipe and verify student artifacts, so
  they cannot pass on a clean runner without scripting the whole lab (#73).
  A lab-commands check (`scripts/check-lab-commands.sh`, AC-008) also fails the
  nightly when a lab names a `make` target or `localhost` port its pinned tag
  does not define.

**Other real content:**
- The 20 belt module docs under `modules/<belt>/`. Green Belt has its "why
  Kubernetes now" framing and Tekton references.
- `dojo.ufawkes.dev`, a static GitHub Pages site (`index.html` +
  `lesson.html`) that renders each module's markdown on-domain.
- CI: markdown lint, commit-message lint, the content-integrity placeholder
  gate, the artifact-chain check and pre-commit.

**Removed as over-engineered (2026-09-27):**
- `labs/fawkes-cli.py` and `labs/setup.py` — a sketched-out packaged CLI
  that imported a `lab_automation` module which never existed. Deleted
  rather than built out: each uFawkes stack already ships its own
  Makefile-driven interface (`make up`, `make init`), so a wrapping CLI
  duplicated an interface that already exists per-stack.

**Prototype, not yet real:**
- `onboarding.html`: a prototype page, now labeled as one. It describes
  `fawkes` CLI commands, Mattermost channels and videos that are not built.
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
- Labs may ship pinned to a labeled pre-release (rc or beta) tag (owner
  decision, 2026-10-06). Dojo `0.2` shipped on the stable uFawkesAI `v2.0.0`
  once it was tagged (2026-10-07); the "Start here" lab is re-pinned and
  re-run, verbatim in CI, by `start-here-live.yml`.
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
- What `uFawkesDevX` uses for Postgres/Coder-DB/Backstage-DB now that
  `uFawkesRes` is deprecated. DevX has shipped stable `v1.0.0` and `v1.0.1`,
  but its decision issue (uFawkesDevX#57) is still open. Decide whether it
  still gates White Belt, or update the plan to match what shipped.

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
