# Spec: Integrate the uFawkes Compose Suite into the Belt Curriculum

**Status:** Draft
**Revision:** 1
**Prepared for:** @paruff
**Approval required before risky work:** Yes — this proposes rewriting
published, live curriculum content (all 20 modules link from
dojo.ufawkes.dev today). No module content changes until the open
decisions below are resolved, and no target stack gets lab content
written against it until it's actually been run for real (see
Verification Status below — none of the three have been, yet).

## Revision Log

| Rev | Date | Changed criteria | Reason |
| --- | --- | --- | --- |
| 1 | 2026-09-27 | — | Initial draft, per request to review uFawkesObs/Pipe/DevX and propose an integration plan |

## Goal

Learners reach a working, hands-on IDP lab in Module 1 without first
provisioning a Kubernetes cluster, by teaching the uFawkes Compose stacks
(Obs/Pipe/DevX) as the White/Yellow Belt substrate, and reserving Fawkes
(Kubernetes) as an explicit, later "graduation" tier — matching the
sequencing the uFawkes suite's own docs already describe, rather than the
curriculum's current Kubernetes-from-Module-1 assumption.

## Context

### Discovered facts (verified 2026-09-27 by reading each repo's own docs)

**Current curriculum state:**
- All 20 modules (`modules/<belt>/*.md`) are Fawkes/Kubernetes-based.
  `white-belt/module-01-what-is-idp/lab-01/instructions.md` — the very
  first lab a learner does — opens with `kubectl rollout status`,
  `kubectl port-forward`, `kubectl get application ... -n argocd`.
- `modules/yellow-belt/module-05-ci-fundamentals.md` teaches Jenkins
  specifically: architecture diagrams, `kubectl port-forward -n jenkins`,
  Jenkinsfile syntax (confirmed by direct read, lines 154–364).
- `docs/module-authoring-guide.md` (this repo) already flags "Jenkins →
  Tekton" as a known in-flight rename (per issue #11) — **that's now also
  stale**: the actual current `uFawkesPipe` repo is Woodpecker CI
  (`.woodpecker.yml`, `ci-pipeline.yml` workflow) per its own README, not
  Tekton. Neither the shipped module nor the tracked "fix" matches what
  the suite actually runs today.
- `docs/module-authoring-guide.md` also sets binding instructional-design
  rules this spec must respect: worked-example-before-practice, ≤5 min
  theory before hands-on, task-first (not a feature tour), one open-response
  retrieval question per module, an explicit spacing boundary for modules
  over ~90 minutes (Brown Belt Module 13 already runs 3–4 hours), feedback
  must be real today (script exit code / dashboard change / HTTP response,
  not "will be auto-graded" for a grader that doesn't exist), and badges
  support competence rather than replacing it. Above all: **no lab step
  may be described unless it has been run, for real** — which is exactly
  why this spec stops short of writing any lab content itself.

**The uFawkes suite (all read directly from each repo's README/docs,
2026-09-27 — none of these were run in this session; see Verification
Status below):**

| Stack | What it is (per its own README) | Maps to belt content |
| --- | --- | --- |
| `uFawkesObs` | Compose: OTel, Prometheus, Loki, Tempo, Alertmanager, Grafana. `make up`. Explicitly "the Compose-tier stepping stone you run until Kubernetes earns its operational cost" (its own `docs/fawkes-migration.md`, decided 2026-09-02). | Brown Belt (Observability, SLIs/SLOs) — and arguably White Belt's "view DORA metrics" objective |
| `uFawkesPipe` | Compose: Woodpecker CI (with GitHub OAuth), SonarQube SAST, Trivy, Gitleaks, CNB buildpacks, DefectDojo, Infisical (merged former `uFawkesSec`). Standardized `.fawkespipe.yml` pipeline contract. | Yellow Belt (CI fundamentals, security scanning, artifact management) — directly, replacing the Jenkins-in-k8s content |
| `uFawkesDevX` | Compose: Coder (cloud IDE), Backstage (catalog/scaffolding), Score service (workload validation), Cookiecutter golden-path templates. Its README states Postgres for Coder/Backstage comes from `uFawkesRes`, not itself. | White Belt (Backstage portal navigation, golden-path first deployment) |
| `uFawkesRes` | Compose: Traefik ingress, Authelia SSO, Postgres, Valkey — shared backing services. | Infrastructure only, not directly taught |
| `fawkes` | Kubernetes-native IDP: ArgoCD, Jenkins (per its own docs — see the "unverified" caveats in `uFawkesObs`'s own migration notes on this point), ~24 DORA capabilities. Positioned by the suite's own docs as the **graduation target**, not a suite-tier peer. | Green Belt (GitOps/ArgoCD) onward — the natural seam, since progressive delivery and multi-cluster patterns are inherently Kubernetes-native |

**A cross-repo inconsistency worth flagging, not silently resolving:**
`uFawkesObs`'s README states `uFawkesRes` was retired 2026-08-18 (merged
into Obs/Pipe). `uFawkesDevX`'s architecture doc — updated 2026-09-14,
*after* that date — still shows `uFawkesRes` as a live dependency for
Postgres, and its README says so explicitly ("Postgres is not run in this
repo... connect to the shared Postgres instance owned by uFawkesRes").
`uFawkesRes`'s own README carries no retirement notice and still describes
itself as the active resource plane. This repo can't resolve that from the
outside; it affects which stack Dojo labs should tell learners to run
alongside `uFawkesDevX` for shared Postgres/SSO, so it's an open decision
below rather than a guess.

### Verification status (read this before trusting the table above as lab-ready)

None of `uFawkesObs`, `uFawkesPipe`, or `uFawkesDevX` were actually brought
up in this session — everything above comes from reading each repo's
README and linked docs, not from running `make up` and observing real
output. That's an appropriate amount of rigor for *choosing a direction*,
but it is explicitly **not** enough to write lab content against, per this
repo's own rule that no lab step gets described until it's been run for
real. Before AC-002 (below) can be attempted, someone needs to actually
`git clone` + `make init && make up` each target stack and confirm it
comes up cleanly, including the `uFawkesDevX` → `uFawkesRes` dependency
this spec flagged as disputed. Treat every specific claim above (that
Woodpecker needs a GitHub OAuth app, that Postgres comes from `uFawkesRes`)
as "stated in the README," not "observed working."

### Product/business constraints (from you, this conversation — not inferred from code)

- `labs/fawkes-cli.py`/`labs/setup.py`: over-engineered, removed (done —
  see the companion commit on this branch). Each stack's own `make`
  interface is the interface; no wrapping CLI is wanted.
- Certification claims on the live site are not implemented; you asked for
  suggestions (see Decisions below).
- Platform Engineering University co-branding is idea-stage, not a
  confirmed partnership.
- "Consider the length of each module and the direction" — module timing
  is an explicit input to this spec, not an afterthought.

### Assumptions (unverified, flagged for confirmation)

- The three Compose stacks are stable enough to teach against for the
  belts proposed below — plausible from their docs, not yet confirmed by
  an actual run (see Verification status above).
- Learners have Docker + Compose available but not necessarily a
  Kubernetes cluster — this is the entire premise of the barrier-reduction
  argument; if your actual learner population already has cluster access
  by default, the barrier this spec removes may not matter as much.

## Scope

**In scope for this spec:** analysis, decision points, and a phased plan.
**Out of scope for this spec:** actually rewriting module content, and
actually running the target stacks — those are the next steps this spec
hands off to, gated on the open decisions and verification step below.

## Risk Review

| Risk area | Applies? | Handling |
| --- | --- | --- |
| Compatibility (published links) | Yes | `dojo.ufawkes.dev` links to every module by path via `lesson.html?src=...`. Restructuring module numbering/paths breaks existing bookmarks/shared links. Mitigate: keep module filenames stable where content is reworked in place; only introduce new paths for genuinely new modules, and redirect/retire old ones explicitly rather than silently deleting. |
| External dependency staleness | Yes | The suite's own cross-repo docs disagree (uFawkesRes). Don't commit lab content to a stack relationship until that's resolved (see Decisions). |
| Unverified claims | Yes | Nothing in the belt→stack mapping has been run for real yet (see Verification status). Treat the mapping as a proposed direction, not a confirmed lab plan, until someone actually brings each stack up. |
| Content-integrity gate scope | Yes | `content-integrity.yml` only checks `modules/**/*.md`, `white-belt/**/*.md`, `labs/**/*.md` for placeholder markers. Any new Compose-based lab content must still be run for real before merge — the gate doesn't enforce this for non-`.md` lab assets (e.g. a `docker-compose.override.yml` a lab tells learners to apply). |
| Scope creep | Yes | Green Belt (GitOps/ArgoCD) has no clean Compose analog — resist the urge to force one; it's the natural graduation seam, not a gap to paper over. |

## Decisions

**Decided (from this conversation):**
- Delete `labs/fawkes-cli.py`/`labs/setup.py` rather than build them out — done.
- Certification: no verifiable-badge infrastructure yet. Recommended
  direction — a lightweight, self-attested completion artifact tied to a
  real capstone (per the module-authoring guide's own rule: badges support
  competence, they don't replace it), not a verification platform. If
  demand later justifies it, Open Badges (an existing open standard with
  native LinkedIn support) over inventing a bespoke one — reuse before
  build. Until either exists, recommend softening "employer recognized"
  language on the live site to avoid the same overclaiming pattern the
  `fawkes-cli.py` prototype had.
- Platform Engineering University: idea-stage only. No implementation
  implied; flag if site copy overstates it.

**Open, blocking module rewrites until resolved:**
1. Resolve the `uFawkesRes` status question (retired per uFawkesObs vs.
   live dependency per uFawkesDevX) directly in those repos, or at minimum
   decide which answer Dojo should assume — this determines whether White
   Belt labs tell learners to bring up `uFawkesRes` alongside `uFawkesDevX`.
2. Confirm the belt→stack mapping proposed below before any module is
   rewritten (see Proposed Direction).
3. Decide whether restructured modules keep their current numbers/paths
   (in-place rewrite) or become new modules alongside the old ones
   (additive, with old ones marked deprecated) — affects the compatibility
   risk above.
4. Actually run each target stack for real (see Verification status) —
   this is a precondition for AC-002, not a nice-to-have.

## Proposed Direction

| Belt | Today | Proposed | Why |
| --- | --- | --- | --- |
| White | Fawkes/k8s from Module 1 | `uFawkesDevX` (Backstage catalog, golden-path Cookiecutter template as "first deployment") + `uFawkesRes` for backing services | Removes the Kubernetes barrier from the very first lab; Backstage catalog browsing and a Cookiecutter-scaffolded deploy are a closer match to "no platform experience" than `kubectl port-forward` |
| Yellow | Fawkes Jenkins-in-k8s (stale even against its own tracked replacement) | `uFawkesPipe` (Woodpecker, `.fawkespipe.yml` contract, Gitleaks/Trivy/SonarQube, DefectDojo) | Directly fixes the Jenkins→Tekton→(actually Woodpecker) drift by teaching what's actually running; Compose-tier setup |
| Green | Fawkes ArgoCD | **Unchanged — becomes the explicit graduation belt.** Open with "why Kubernetes now" (the operational-cost framing `uFawkesObs`'s own docs use), then teach ArgoCD/progressive delivery for real | No clean Compose analog for GitOps/canary patterns; this is where graduating to Fawkes earns its keep, not a gap to force-fit |
| Brown | Fawkes in-cluster observability | `uFawkesObs` for SLIs/SLOs/dashboards, then a short **graduation delta** lab covering what changes moving to Fawkes (Loki→OpenSearch is a real rewrite per `uFawkesObs`'s own migration notes, not a config tweak) | Reuses real portability findings already written in `uFawkesObs/docs/fawkes-migration.md` instead of re-deriving them |
| Black | Fawkes multi-tenancy/zero-trust/multi-cloud | Unchanged | Inherently advanced/Kubernetes-native; this is the tier where full platform ownership is the point |

### Module length implications

Compose stacks are pitched by their own docs as fast to start (`make up`
in roughly a minute per their marketing copy — not yet independently
confirmed, see Verification status); a full cluster + ArgoCD sync cycle is
generally slower, though that hasn't been measured here either. This
doesn't shorten the nominal 60-minute module budget on its own, but it's
likely to change where the 60 minutes goes: less time waiting on
infrastructure, more available for the worked-example-then-practice
pattern the authoring guide already requires — that shift should be
measured during rewrite, not assumed. Two concrete implications to
verify, not assert:
- `uFawkesPipe`'s README lists GitHub OAuth as part of its setup — Yellow
  Belt's real first-run cost may be registering that OAuth app, not stack
  startup. Budget real time for it and give it a worked example once
  someone's actually run it, rather than describing it from the README.
- Brown Belt Module 13's existing 3–4 hour length (already flagged as an
  outlier in the authoring guide) is worth re-measuring once its lab
  content targets `uFawkesObs` instead of in-cluster Fawkes — it may
  shrink, but that's a measurement to make during rewrite, not an
  assumption to bake into this spec.

## Acceptance Criteria (Phase 1: decisions + one pilot module, not a full rewrite)

### AC-001: uFawkesRes status is resolved before any White Belt content changes

- **Scenario:** Before Phase 2 (module rewriting) starts
- **Action:** You confirm (in either the uFawkesObs/uFawkesDevX repos or
  here) whether Dojo should teach `uFawkesRes` as a required companion
  stack for `uFawkesDevX`
- **Expected:** A single, unambiguous answer recorded in this file's
  Decisions section
- **Verification:** Manual — this is a maintainer decision, not testable
- **Priority:** Required (blocks Phase 2)

### AC-002: One pilot module (White Belt Module 4, "Your First Deployment") is rewritten against uFawkesDevX and run for real

- **Scenario:** `uFawkesDevX` (+ resolved `uFawkesRes` dependency) actually
  brought up locally and confirmed working (not just read about — see
  Verification status)
- **Action:** Follow the rewritten lab instructions start to finish as a
  first-time learner would
- **Expected:** A golden-path Cookiecutter template is scaffolded and
  deployed via the stack, with real command output pasted into the lab
  (per the authoring guide's core rule), in under the module's stated
  time budget
- **Must not:** Reference any command, UI flow, or output that wasn't
  actually run during authoring
- **Verification:** Manual dry-run by you or another human, plus the
  existing `content-integrity.yml` gate on the modified `.md`
- **Priority:** Required — this is the proof-of-concept the rest of the
  rewrite depends on

### AC-003: Existing published lesson links keep working

- **Scenario:** A learner has `dojo.ufawkes.dev/lesson.html?src=modules/white-belt/module-04-first-deployment.md` bookmarked from before the rewrite
- **Action:** Load that URL after the rewrite ships
- **Expected:** The link resolves to the rewritten content at the same
  path (in-place rewrite), or to an explicit redirect/deprecation notice
  if the path changed
- **Must not:** 404 silently
- **Verification:** Manual check post-deploy
- **Priority:** Required

## Verification Plan

| Criterion | Verification evidence | Status |
| --- | --- | --- |
| AC-001 | Decision recorded in this file | Pending |
| AC-002 | Dry-run transcript + content-integrity CI pass | Pending |
| AC-003 | Manual link check on dojo.ufawkes.dev | Pending |

## Phased Rollout (after AC-001–003 are met)

1. Rewrite remaining White Belt modules against `uFawkesDevX`/`uFawkesRes`.
2. Rewrite Yellow Belt against `uFawkesPipe`, budgeting real time for the
   GitHub OAuth setup step.
3. Add the Green Belt "graduation" framing (why Kubernetes now) without
   changing its existing ArgoCD lab content.
4. Rewrite Brown Belt's SLI/SLO/dashboard content against `uFawkesObs`,
   re-measuring Module 13's length; add the graduation-delta lab using
   `uFawkesObs/docs/fawkes-migration.md`'s existing findings.
5. Leave Black Belt as-is.
6. Update `README.md`'s belt summary line and `intent.md`'s Direction
   section to reflect the completed state at each phase.
