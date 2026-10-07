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

- [White Belt](modules/white-belt/module-00-vibe-coding-to-agentic.md) — **Module 0: From Vibe Coding to Agentic Engineering** (entry primer, ≤10 min, cites AI-Native SDLC Playbook) → [Module 1: IDP fundamentals](modules/white-belt/module-01-what-is-idp.md) → [Module 2: DORA metrics](modules/white-belt/module-02-dora-metrics.md) → [Module 3: GitOps principles](modules/white-belt/module-03-gitops-principles.md) → [Module 4: First deployment](modules/white-belt/module-04-first-deployment.md)
- [Yellow Belt](modules/yellow-belt/module-05-ci-fundamentals.md) — CI fundamentals, golden paths, security scanning, artifact management
- [Green Belt](modules/green-belt/module-09-gitops-argocd.md) — GitOps/ArgoCD, deployment strategies, progressive delivery, rollback
- [Brown Belt](modules/brown-belt/module-13-observability.md) — Observability, DORA deep-dive, SLIs/SLOs, incident management
- [Black Belt](modules/black-belt/module-17-platform-product.md) — Platform-as-product, multi-tenancy, zero-trust security, multi-cloud

## Labs

Each module's hands-on lab is a per-lab `instructions.md`:

- **White Belt Module 0 — Start here**: uFawkesAI template + devcontainer (`v2.0.0`) — one intent → spec → plan cycle
  [`white-belt/module-00-vibe-coding-to-agentic/lab-01/instructions.md`](white-belt/module-00-vibe-coding-to-agentic/lab-01/instructions.md)
- **White Belt Module 1**: uFawkesDevX (Docker Compose) — scaffold a service via golden path Cookiecutter template
  [`white-belt/module-01-what-is-idp/lab-01/instructions.md`](white-belt/module-01-what-is-idp/lab-01/instructions.md)
- **White Belt Module 2**: uFawkesObs (Docker Compose) — send events to live DORA dashboard
  [`white-belt/module-02-dora-metrics/lab-01/instructions.md`](white-belt/module-02-dora-metrics/lab-01/instructions.md)
- **Modules 3-4**: Kubernetes-based (transitional — to be migrated)

There is no wrapping CLI — a prior `labs/fawkes-cli.py` prototype was removed as unnecessary (each `make up`/`make init`-driven uFawkes stack already has its own interface); see [`INTENT.md`](INTENT.md) for current direction.

## Assessments

Belt certification exams live in [`assessments/`](assessments/).

## Related repos

Part of the [Fawkes IDP family](https://github.com/paruff/fawkes):
[fawkes](https://github.com/paruff/fawkes) (core platform) ·
[uFawkesPipe](https://github.com/paruff/uFawkesPipe) (CI/CD) ·
[uFawkesObs](https://github.com/paruff/uFawkesObs) (observability) ·
[uFawkes.dev](https://github.com/paruff/uFawkes.dev) (marketing site)

## Design and brand

This repo follows the shared Fawkes and uFawkes design reference:
[DESIGN.md](https://github.com/paruff/uFawkes.dev/blob/main/DESIGN.md), with tokens at <https://ufawkes.dev/design/tokens.json>. It is owned by
[uFawkes.dev](https://github.com/paruff/uFawkes.dev).
