# Spec: Teach the uFawkes Compose Suite First

**Traces to:** [`intent.md`](intent.md) | **Plan:** [`plan.md`](plan.md)
**Status:** Draft | **Revision:** 5
**Approval required before risky work:** Yes. This rewrites live curriculum
content that dojo.ufawkes.dev links to. No module changes until the stack
it targets is released, and every lab step is run for real first.

## Revision Log

| Rev | Date | Change | Reason |
|---|---|---|---|
| 1 | 2026-09-27 | Initial draft | Review of uFawkesObs/Pipe/DevX |
| 2 | 2026-09-27 | CI tooling facts; uFawkesRes resolved | Confirmed: Fawkes = Tekton, uFawkesPipe = Woodpecker, uFawkesRes deprecated |
| 3 | 2026-09-27 | Split into intent/spec/plan (uFawkesAI convention); pilot changed from "White Belt Module 4 on DevX" to "pin Module 2's existing uFawkesObs lab to v1.0.0"; corrected "all modules are Kubernetes-based" | Decided: labs follow suite release order (Obs → Pipe → DevX). Module 2's lab (#10) already runs on uFawkesObs. |
| 4 | 2026-10-04 | Added R6 and AC-005: rewritten modules pass the whole authoring-guide checklist | Review against mastery learning and Visible Learning: R5 bound only two of the guide's items, so a rewrite could meet every AC and skip retrieval, feedback and correctives |
| 5 | 2026-10-06 | Added R7, R8, AC-006, AC-007; belt table notes uFawkesDevX is released (`v1.0.1`) | [Audit](audit-2026-10-06.md): twelve labs were merged ahead of their stacks with no run evidence, eight naming tags that do not exist, and the nightly tests `main`, not the pinned tag |
| 5.1 | 2026-10-06 | R1 allows a labeled pre-release tag | Owner decision, 2026-10-06: pre-release pins are acceptable |

## Requirements

- **R1 — Pinned stacks.** Every lab states which stack version it runs
  against and clones that tag, never `main`. A pre-release tag (rc or beta) is allowed when the lab says
  "pre-release" in its header (owner decision, 2026-10-06). For example:
  `git clone --branch v1.0.0 https://github.com/paruff/uFawkesObs.git`.
- **R2 — Run for real.** Every lab step is run against the pinned version
  before merge, with real output pasted in. See
  [`docs/module-authoring-guide.md`](../../module-authoring-guide.md).
- **R3 — Stable links.** Every module URL published on dojo.ufawkes.dev
  (`lesson.html?src=...`) keeps resolving: either to rewritten content at
  the same path, or to an explicit deprecation note. It never 404s.
- **R4 — Kubernetes as graduation.** Fawkes/Kubernetes content starts at
  Green Belt, and is framed as "why Kubernetes now," not as a
  prerequisite.
- **R5 — Timing.** Modules follow the authoring guide's timing rules:
  - no more than about 5 minutes of theory before hands-on work;
  - an explicit spacing boundary if a module runs over about 90 minutes.

  Re-measure each module's length after its rewrite; don't carry the old
  estimates over.
- **R6 — Learning design.** Every rewritten module passes the whole
  [module-authoring guide](../../module-authoring-guide.md) checklist
  (items 1–17), not only the timing items in R5. That covers worked
  examples, retrieval, feedback that says where to go next, an 80% bar
  with a corrective loop, and diagrams. If an item can't be met, the PR
  says why.

- **R7 — Gate before merge.** A lab or module rewrite that targets a stack
  merges only through a pull request that pastes a real run of every step,
  and only once the stack tag it names exists. A lab written ahead of its
  stack may merge only if its header says "Written ahead of its stack, not
  yet run for real" and it names no release link that does not exist. It
  counts toward no release gate until it has been run for real.
- **R8 — The nightly tests what the lab teaches.** The nightly live
  acceptance checks out each lab's stack at the tag the lab pins, not the
  default branch. A run against `main` may be added as an advisory early
  warning. Where a lab's steps are deterministic, the nightly runs those
  steps as well as `validate.sh`, because `validate.sh` can pass while the
  taught flow is wrong (#72).

## Design

### Belt → stack mapping

| Belt | Today | Target | Why |
|---|---|---|---|
| White | Module 1 lab is kubectl; **Module 2 lab already on uFawkesObs** (#10) | uFawkesDevX (Backstage catalog, golden-path Cookiecutter "first deployment") for Modules 1/3/4; uFawkesDevX is released (`v1.0.1`). Module 2 stays on uFawkesObs, pinned. | Removes the cluster barrier from the first labs |
| Yellow | Jenkins-in-Fawkes (stale) | uFawkesPipe: Woodpecker, the `.fawkespipe.yml` contract, Gitleaks/Trivy/SonarQube, DefectDojo | Teaches what the Compose tier actually runs |
| Green | Fawkes ArgoCD | **Graduation belt.** Opens with why Kubernetes now, then ArgoCD and progressive delivery on Fawkes; CI references use Tekton. | GitOps and canary patterns have no clean Compose analog |
| Brown | Fawkes in-cluster observability | uFawkesObs for SLIs, SLOs and dashboards, plus a short graduation-delta lab on what changes on Fawkes (Loki → OpenSearch is a rewrite, per `uFawkesObs/docs/fawkes-migration.md`) | Reuses real portability findings |
| Black | Fawkes multi-tenancy, zero-trust, multi-cloud | Unchanged | Kubernetes-native by nature |

### Version pinning

Each lab's header carries a line like
`**Runs against**: [uFawkesObs v1.0.0](https://github.com/paruff/uFawkesObs/releases/tag/v1.0.0)`.
Its clone step uses the same tag. When a stack ships a new minor
version, bump labs deliberately, one PR per lab, and re-run each one. Never
float to `main`.

### Module length

Compose stacks start faster than a cluster plus an ArgoCD sync. That
shifts time within the nominal 60-minute module toward
worked-example-then-practice; it doesn't shrink the budget. Two things to
measure during rewrite rather than assume:

- Yellow Belt's real first-run cost may be uFawkesPipe's GitHub OAuth app
  registration, not stack startup.
- Brown Belt Module 13 (currently 3–4 hours) may shrink on uFawkesObs.

## Concerns

| Risk | Handling |
|---|---|
| A path change breaks published lesson links | R3; the choice of in-place rewrite vs. new modules is an open question in `intent.md` |
| A lab written against an unreleased or moving stack | R1 and R2. Each plan phase starts only after its stack's release. |
| uFawkesDevX's Postgres source is unknown (uFawkesRes deprecated) | White Belt Modules 1/3/4 are blocked until paruff/uFawkesDevX#55 and AC-DEVX-01 resolve it. Nothing earlier depends on it. |
| `content-integrity.yml` only scans `.md` files | Non-`.md` lab assets (compose overrides, scripts) still fall under R2 |
| Forcing a Compose analog for GitOps | Green Belt is the graduation seam by design |

## Acceptance Criteria

### AC-001: Module 2's lab is pinned to uFawkesObs v1.0.0 and re-run for real (pilot)

- **Scenario:** uFawkesObs v1.0.0 is released
- **Action:** Update `white-belt/module-02-dora-metrics/lab-01/` to
  clone `--branch v1.0.0` and name that version in its header. Then run
  the whole lab, including `validate.sh`, against the tag.
- **Expected:** Every step and the validator pass against v1.0.0. The
  output pasted into the lab matches that run.
- **Must not:** Clone `main`, or keep any output captured against an
  older version
- **Verification:** A real run transcript in the PR, plus the
  `content-integrity.yml` pass
- **Priority:** Required. This is the first release-order step and the
  pattern every later lab follows.

### AC-002: Published lesson links keep working

- **Scenario:** A bookmarked
  `dojo.ufawkes.dev/lesson.html?src=modules/.../module-NN-*.md` from
  before a rewrite
- **Expected:** It resolves to the rewritten content or to an explicit
  deprecation note
- **Must not:** 404 silently
- **Verification:** A manual link check after each deploy
- **Priority:** Required

### AC-003: No lab targets `main`

- **Expected:** `grep -rn "git clone" white-belt modules labs` shows a
  `--branch vX.Y.Z` on every uFawkes stack clone
- **Verification:** The grep, run in the PR that touches any lab
- **Priority:** Required

### AC-004: uFawkesDevX's Postgres source is known before the White Belt DevX rewrite

- **Scenario:** Before Modules 1/3/4 move to uFawkesDevX
- **Expected:** A decided, documented Postgres source (the ADR from
  uFawkesDevX AC-DEVX-01)
- **Verification:** A link to that ADR in the rewrite PR
- **Priority:** Required. It blocks only the White Belt phase.

### AC-005: Rewritten modules pass the authoring-guide checklist

- **Scenario:** A PR rewrites or adds a module or lab
- **Expected:** Every box in the PR template's authoring-guide section is
  checked, or has a stated reason in the PR
- **Must not:** Leave a box unchecked without saying why
- **Verification:** The PR template checklist, checked at review
- **Priority:** Required

### AC-006: Every release tag a lab names exists

- **Scenario:** Any lab whose "Runs against" line or clone command names a
  stack tag
- **Expected:** For each, `gh api repos/paruff/<stack>/git/refs/tags/<tag>`
  succeeds
- **Must not:** Link to a release page for a tag that does not exist
- **Verification:** A script over every `*/module-*/lab-*/instructions.md`,
  run in the nightly and in any lab PR
- **Priority:** Required. Today it fails for Brown Belt 13–16
  (`uFawkesObs v1.0.0`) and Yellow Belt 5–8 (`uFawkesPipe v2.0.0`).

### AC-007: The nightly checks out the tag the lab pins

- **Scenario:** A lab with a nightly entry
- **Expected:** The ref the nightly checks out for that lab's stack equals the
  tag in its "Runs against" line
- **Verification:** The nightly workflow reads the tag from the lab, or a
  check compares the two
- **Priority:** Required once R8 lands. Today the nightly checks out the
  stack's default branch for every lab.
