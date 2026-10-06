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
**As of 2026-10-06 none of the Obs, Pipe or AI stacks has a stable release**
(newest: Obs `v1.0.6-rc.1`, Pipe `v1.11.1-beta.1`, AI `v2.0.0-rc.3`), and
uFawkesDevX is at stable `v1.0.1`. Labs written ahead of a release are marked
"not yet run for real" until they are verified against a tag that exists (see
the audit below).

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
  uFawkesAI `v2.0.0-rc.3` (pre-release pin), 14/14, run verbatim end to end.
- `white-belt/module-02-dora-metrics/lab-01/` — on uFawkesObs `v1.0.6-rc.1`
  (pre-release pin), re-run in #79.
- A nightly live acceptance run (`live-acceptance.yml`) boots a real uFawkesObs
  stack and runs the self-checks of Module 2 labs 01 and 02 and Brown Belt
  13 and 14. It tests the stack's default branch and runs `validate.sh`, not
  the instructions' steps.

**Written, but not yet run for real** (11 labs; see the audit):
- White Belt 1, 3 and 4 on uFawkesDevX `v1.0.1`. The tag exists, but it cannot build
  its Backstage image (uFawkesDevX#98), so these labs cannot run yet.
- Yellow Belt 5–8 on a uFawkesPipe `v2.0.0` that does not exist yet.
- Brown Belt 13–16 on a uFawkesObs `v1.0.0` that does not exist yet.

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
- Labs may ship pinned to a labeled pre-release (rc or beta) tag, and Dojo 0.2
  may ship on uFawkesAI `v2.0.0-rc.3` (owner decision, 2026-10-06). The lab's
  header says "pre-release", and it is re-pinned when the stable tag ships.
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
