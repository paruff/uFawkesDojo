# Changelog

All notable changes to uFawkesDojo will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Dojo `0.2` ships with uFawkesAI `v2.0.0`; `0.3`–`0.6` each add
the labs for the stack released alongside them.

## [0.2.1](https://github.com/paruff/uFawkesDojo/compare/0.2.0...v0.2.1) (2026-10-09)


### Fixed

* **lab:** correct post-0.2.0 review findings ([#92](https://github.com/paruff/uFawkesDojo/issues/92)) ([f336519](https://github.com/paruff/uFawkesDojo/commit/f336519d7e7fb10edb84d71e36b5395ffa7ccfd4))
* **release:** add missing release-please-config.json; drop dangling labels ([#100](https://github.com/paruff/uFawkesDojo/issues/100)) ([d7d59e3](https://github.com/paruff/uFawkesDojo/commit/d7d59e33f286390e84737642c5a46c13911418cd))
* **release:** correct manifest to 0.2.0; repair issue-form schema ([#101](https://github.com/paruff/uFawkesDojo/issues/101)) ([95a6845](https://github.com/paruff/uFawkesDojo/commit/95a6845adb547a5c1fe2bbc358611d97453d524a))


### Docs

* **changelog:** add Keep a Changelog header and Unreleased section ([#97](https://github.com/paruff/uFawkesDojo/issues/97)) ([4a0ba2f](https://github.com/paruff/uFawkesDojo/commit/4a0ba2f210f9ab516edebb9e63a01d4a6dd99f15))
* **governance:** add CODE_OF_CONDUCT, SECURITY.md, expand FUNDING.yml ([#95](https://github.com/paruff/uFawkesDojo/issues/95)) ([5c2e04f](https://github.com/paruff/uFawkesDojo/commit/5c2e04fdad3c9fc5c1a8777c5c49df7dff409974))
* **issue-templates:** add bug_report, feature, security templates ([#99](https://github.com/paruff/uFawkesDojo/issues/99)) ([b9ff6a7](https://github.com/paruff/uFawkesDojo/commit/b9ff6a7ebf91eaf60a532d3845968a1a405c224e))
* **pr-template:** update standardized PR template ([#98](https://github.com/paruff/uFawkesDojo/issues/98)) ([c5c780d](https://github.com/paruff/uFawkesDojo/commit/c5c780dfbee71446ec6a8ae14a972adf7d5aa115))

## [Unreleased]

### Added

- Governance baseline (CODE_OF_CONDUCT, SECURITY.md, expanded FUNDING.yml)
- release-please workflow automation

All notable changes to uFawkesDojo are recorded here. Versions follow the
suite release plan: Dojo `0.2` ships with uFawkesAI `v2.0.0`, and `0.3`–`0.6`
each add the labs for the stack released alongside them.

## [0.2.0] - 2026-10-07

Accurate curriculum, and a real "Start here" lab on uFawkesAI `v2.0.0`.

### Added

- White Belt Module 0, "From vibe coding to agentic engineering", and its
  "Start here" lab: clone uFawkesAI `v2.0.0`, open its devcontainer
  (`fawkes-space:2.0.0`), find the six harness components and write one
  intent → spec → plan chain. A `validate.sh` checks it (14 checks).
- `start-here-live.yml`: runs every step of the "Start here" lab verbatim on a
  clean runner, devcontainer included, on each change to the lab and nightly.
- Nightly live acceptance (`live-acceptance.yml`): boots a real uFawkesObs
  stack and runs the self-checks of White Belt Module 2 labs 01–02 and Brown
  Belt 13–14.
- Module authoring guide items 9–17: cumulative spaced retrieval,
  interleaving, fading, calibration, self-regulation, correctives, one
  mastery bar, feedback that says where to go next, and diagrams beside the
  text. Each cites its source; the PR template links the guide.
- Green Belt Modules 9–12: "why Kubernetes now" framing and Tekton
  references.

### Changed

- DORA is taught as five metrics everywhere. Retired CI tooling, unbuilt labs,
  videos and community links are removed or labeled, and the suite's
  AC-DOJO-01 accuracy check passes.
- Labs pin a released stack tag. White Belt Module 2 lab-01 runs on uFawkesObs
  `v1.0.6-rc.1` and Brown Belt Module 13 lab-01 on `v1.1.0-rc.1`, both run for
  real. Eleven labs written ahead of their stacks say "not yet run for real".
- Lab instructions describe today's uFawkesObs: `dora-api` computes the DORA
  metrics itself and serves them to Prometheus, and deployment events use
  schema 1.0.
- The devcontainer uses the shared `fawkes-space:2.0.0` CDE, pinned by digest.
- Email moved to `ufawkes.dev`, and the site is served at `dojo.ufawkes.dev`.

### Removed

- `labs/fawkes-cli.py` and `labs/setup.py`, a CLI prototype that imported a
  module that never existed.
