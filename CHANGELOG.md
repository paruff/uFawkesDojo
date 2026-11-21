# Changelog

All notable changes to uFawkesDojo will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Dojo `0.2` ships with uFawkesAI `v2.0.0`; `0.3`–`0.6` each add
the labs for the stack released alongside them.

## [0.2.1](https://github.com/paruff/uFawkesDojo/compare/0.2.0...v0.2.1) (2026-11-21)


### Added

* **pages:** move the three pages to the suite tokens (D15) ([#119](https://github.com/paruff/uFawkesDojo/issues/119)) ([e151b9f](https://github.com/paruff/uFawkesDojo/commit/e151b9fb0a97001eefe9874b9e8840a6a9dc8d85))


### Fixed

* **grader:** graders fail closed, real metric names (AF-16 17 19 20) ([#129](https://github.com/paruff/uFawkesDojo/issues/129)) ([6394bc8](https://github.com/paruff/uFawkesDojo/commit/6394bc84b3a71eff0e5694417df77e903d9ffe82))
* **grader:** lab 02 .env and gh, brown belt HTTP 000 (AF-18 21 22 24 14) ([#130](https://github.com/paruff/uFawkesDojo/issues/130)) ([1328b83](https://github.com/paruff/uFawkesDojo/commit/1328b83bdb83b975a2062232073e8a603e8c323a))
* **lab:** correct post-0.2.0 review findings ([#92](https://github.com/paruff/uFawkesDojo/issues/92)) ([f336519](https://github.com/paruff/uFawkesDojo/commit/f336519d7e7fb10edb84d71e36b5395ffa7ccfd4))
* **lab:** pin Obs labs to v1.1.0-rc.1, run Modules 14-16 for real, guard the pins ([#106](https://github.com/paruff/uFawkesDojo/issues/106)) ([2f25ada](https://github.com/paruff/uFawkesDojo/commit/2f25adae9cc51cf2a8de10b401764eaec8bd5321))
* **lab:** re-pin Module 13 lab-01 to uFawkesObs v1.0.1 ([#115](https://github.com/paruff/uFawkesDojo/issues/115)) ([2f56c03](https://github.com/paruff/uFawkesDojo/commit/2f56c038919793d06fd4cb7a1bd38f5159f7fe53))
* **lab:** re-pin Module 14 lab-01 to uFawkesObs v1.0.1 ([#116](https://github.com/paruff/uFawkesDojo/issues/116)) ([12d5129](https://github.com/paruff/uFawkesDojo/commit/12d51295a6ac4558509502056dc106227465d8c2))
* **lab:** re-pin Module 15 lab-01 to uFawkesObs v1.0.1 ([#117](https://github.com/paruff/uFawkesDojo/issues/117)) ([1ee759e](https://github.com/paruff/uFawkesDojo/commit/1ee759e5ef59087240044a9693946b8419ed3b8d))
* **lab:** re-pin Module 16 lab-01 to uFawkesObs v1.0.1 ([#118](https://github.com/paruff/uFawkesDojo/issues/118)) ([10d3832](https://github.com/paruff/uFawkesDojo/commit/10d38322391093fbd68f655105d697edd0141b11))
* **lab:** re-pin Module 2 lab-01 to uFawkesObs v1.0.0 ([#107](https://github.com/paruff/uFawkesDojo/issues/107)) ([172c35c](https://github.com/paruff/uFawkesDojo/commit/172c35c8d56d64fa0995efb2675fe7e82cfabfcb))
* **labs:** count the labs' test-environment deploys in DORA gauges ([#145](https://github.com/paruff/uFawkesDojo/issues/145)) ([49ee8a7](https://github.com/paruff/uFawkesDojo/commit/49ee8a7dec47c3bed588e475e713566640548969))
* **labs:** match every lab to the release it pins ([#127](https://github.com/paruff/uFawkesDojo/issues/127)) ([#141](https://github.com/paruff/uFawkesDojo/issues/141)) ([18dbcce](https://github.com/paruff/uFawkesDojo/commit/18dbcce2b9ef8636f5f3598aac3e46430795ad20))
* **release:** add missing release-please-config.json; drop dangling labels ([#100](https://github.com/paruff/uFawkesDojo/issues/100)) ([d7d59e3](https://github.com/paruff/uFawkesDojo/commit/d7d59e33f286390e84737642c5a46c13911418cd))
* **release:** correct manifest to 0.2.0; repair issue-form schema ([#101](https://github.com/paruff/uFawkesDojo/issues/101)) ([95a6845](https://github.com/paruff/uFawkesDojo/commit/95a6845adb547a5c1fe2bbc358611d97453d524a))
* **yellow-belt:** pin the labs to uFawkesDevX v1.2.0 ([#127](https://github.com/paruff/uFawkesDojo/issues/127)) ([#142](https://github.com/paruff/uFawkesDojo/issues/142)) ([4147cde](https://github.com/paruff/uFawkesDojo/commit/4147cdeacb77af3e31f347a4c88e9f5048a916d4))


### Docs

* **agents:** import the learn and dojo-navigator skills and Dojo docs from uFawkesAI ([#110](https://github.com/paruff/uFawkesDojo/issues/110)) ([b6bc6fa](https://github.com/paruff/uFawkesDojo/commit/b6bc6faff79052185602c32515b5b9e6c9fd71a9))
* **changelog:** add Keep a Changelog header and Unreleased section ([#97](https://github.com/paruff/uFawkesDojo/issues/97)) ([4a0ba2f](https://github.com/paruff/uFawkesDojo/commit/4a0ba2f210f9ab516edebb9e63a01d4a6dd99f15))
* **design:** DESIGN.md, REVIEW.md and the Project 7 workflow ([#111](https://github.com/paruff/uFawkesDojo/issues/111)) ([5dec2aa](https://github.com/paruff/uFawkesDojo/commit/5dec2aa56b69870ea8b375474d61881e425f316d))
* **docs:** curriculum spec rev 6, AC-008 and current state ([#127](https://github.com/paruff/uFawkesDojo/issues/127)) ([#128](https://github.com/paruff/uFawkesDojo/issues/128)) ([c0bbcb1](https://github.com/paruff/uFawkesDojo/commit/c0bbcb13276ab7d8fabcc8804137fe22d1250b75))
* **docs:** interfaces, pipeline invariants and make commands ([#122](https://github.com/paruff/uFawkesDojo/issues/122)) ([09c58b9](https://github.com/paruff/uFawkesDojo/commit/09c58b9e35606f5f921653023d4a7365fa88bd6c))
* **governance:** add CODE_OF_CONDUCT, SECURITY.md, expand FUNDING.yml ([#95](https://github.com/paruff/uFawkesDojo/issues/95)) ([5c2e04f](https://github.com/paruff/uFawkesDojo/commit/5c2e04fdad3c9fc5c1a8777c5c49df7dff409974))
* **issue-templates:** add bug_report, feature, security templates ([#99](https://github.com/paruff/uFawkesDojo/issues/99)) ([b9ff6a7](https://github.com/paruff/uFawkesDojo/commit/b9ff6a7ebf91eaf60a532d3845968a1a405c224e))
* **lab:** Trivy and Bandit run in sast without being disabled ([#144](https://github.com/paruff/uFawkesDojo/issues/144)) ([52d3caf](https://github.com/paruff/uFawkesDojo/commit/52d3cafe4ff098abfa842786709f93dececc45a4))
* **pr-template:** update standardized PR template ([#98](https://github.com/paruff/uFawkesDojo/issues/98)) ([c5c780d](https://github.com/paruff/uFawkesDojo/commit/c5c780dfbee71446ec6a8ae14a972adf7d5aa115))
* **yellow-belt:** run Module 5 lab for real against uFawkesPipe v2.0.0 ([#136](https://github.com/paruff/uFawkesDojo/issues/136)) ([ccb0d6a](https://github.com/paruff/uFawkesDojo/commit/ccb0d6ae1406ba730baaf60bdc62ec187e482cea))
* **yellow-belt:** run Module 6 lab for real against uFawkesPipe v2.0.0 ([#138](https://github.com/paruff/uFawkesDojo/issues/138)) ([5c7035d](https://github.com/paruff/uFawkesDojo/commit/5c7035d52594a4388809ec1be25a1be5195b18ce))
* **yellow-belt:** run Module 7 lab for real against uFawkesPipe v2.0.0 ([#139](https://github.com/paruff/uFawkesDojo/issues/139)) ([24c900e](https://github.com/paruff/uFawkesDojo/commit/24c900e551b72d4918cebf0e63ae24d60cbfbaa0))
* **yellow-belt:** run Module 8 lab for real against uFawkesPipe v2.0.0 ([#140](https://github.com/paruff/uFawkesDojo/issues/140)) ([e3eea80](https://github.com/paruff/uFawkesDojo/commit/e3eea80ea1ac5b5c7a605749788e005d77d36dda))


### Chores

* **ci:** adopt Pipe v1.15.0-beta.1; add Pipeline Complete ([#181](https://github.com/paruff/uFawkesDojo/issues/181)) ([#102](https://github.com/paruff/uFawkesDojo/issues/102)) ([ffe3c9e](https://github.com/paruff/uFawkesDojo/commit/ffe3c9e3db959aefe93a5d1b873dc50c238caeed))
* **ci:** bump uFawkesPipe reusables to v1.16.0-beta.1 ([#105](https://github.com/paruff/uFawkesDojo/issues/105)) ([dab822d](https://github.com/paruff/uFawkesDojo/commit/dab822d927d7229916bce47a9502df614a5cdf68))
* **infra:** add make validate and make doctor ([#121](https://github.com/paruff/uFawkesDojo/issues/121)) ([#132](https://github.com/paruff/uFawkesDojo/issues/132)) ([bae64f6](https://github.com/paruff/uFawkesDojo/commit/bae64f6dec6697a2e0cc456f3e96376ba694acb3))
* **infra:** adopt the OpenCode shift-left plugin ([#153](https://github.com/paruff/uFawkesDojo/issues/153)) ([#104](https://github.com/paruff/uFawkesDojo/issues/104)) ([eb30336](https://github.com/paruff/uFawkesDojo/commit/eb303360b42807db7343495cc1a28aff85a38731))
* **labs:** pin the yellow-belt labs to uFawkesPipe v2.0.1 ([#143](https://github.com/paruff/uFawkesDojo/issues/143)) ([563b873](https://github.com/paruff/uFawkesDojo/commit/563b873c1e8a0af9c5e7e3671efc3eaaffdd8f31))

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
