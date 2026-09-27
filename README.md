# uFawkesDojo

[![Markdown Lint](https://github.com/paruff/uFawkesDojo/actions/workflows/markdown-lint.yml/badge.svg)](https://github.com/paruff/uFawkesDojo/actions/workflows/markdown-lint.yml)
[![Deploy Pages](https://github.com/paruff/uFawkesDojo/actions/workflows/pages.yml/badge.svg)](https://github.com/paruff/uFawkesDojo/actions/workflows/pages.yml)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

**Learning Plane — Fawkes IDP Family.** uFawkesDojo is the belt-level,
hands-on platform engineering curriculum extracted from
[fawkes](https://github.com/paruff/fawkes). Progress through White → Yellow
→ Green → Brown → Black belt modules, each with labs and assessments.

🌐 **[Live site](https://dojo.ufawkes.dev)** (also reachable at
[paruff.github.io/uFawkesDojo](https://paruff.github.io/uFawkesDojo/) until
DNS for the custom domain is confirmed — see `CNAME` and
[issue #11](https://github.com/paruff/uFawkesDojo/issues/11), Phase 6)

## Belt Modules

- [White Belt](modules/white-belt/module-01-what-is-idp.md) — IDP fundamentals, DORA metrics, GitOps principles, first deployment
- [Yellow Belt](modules/yellow-belt/module-05-ci-fundamentals.md) — CI fundamentals, golden paths, security scanning, artifact management
- [Green Belt](modules/green-belt/module-09-gitops-argocd.md) — GitOps/ArgoCD, deployment strategies, progressive delivery, rollback
- [Brown Belt](modules/brown-belt/module-13-observability.md) — Observability, DORA deep-dive, SLIs/SLOs, incident management
- [Black Belt](modules/black-belt/module-17-platform-product.md) — Platform-as-product, multi-tenancy, zero-trust security, multi-cloud

## Labs

Each module's hands-on lab is a per-lab `instructions.md` with plain kubectl
steps — see
[`white-belt/module-01-what-is-idp/lab-01/instructions.md`](white-belt/module-01-what-is-idp/lab-01/instructions.md)
for the first lab. [`labs/fawkes-cli.py`](labs/fawkes-cli.py) is an unbuilt
CLI prototype (see the STATUS note at the top of the file) — it does not
run today and is not part of the current lab flow.

## Assessments

Belt certification exams live in [`assessments/`](assessments/).

## Related repos

Part of the [Fawkes IDP family](https://github.com/paruff/fawkes):
[fawkes](https://github.com/paruff/fawkes) (core platform) ·
[uFawkesPipe](https://github.com/paruff/uFawkesPipe) (CI/CD) ·
[uFawkesObs](https://github.com/paruff/uFawkesObs) (observability) ·
[uFawkes.dev](https://github.com/paruff/uFawkes.dev) (marketing site)
