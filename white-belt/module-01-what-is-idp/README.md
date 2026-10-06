# Module 1: What is an Internal Delivery Platform?

**Belt Level**: 🥋 White Belt
**Estimated Time**: 60 minutes (15 min theory + 20 min hands-on lab + 5 min quiz + 5 min reflection + 10 min demo)
**Prerequisites**: Basic command line, Git, and Docker knowledge
**DORA Capability**: Continuous Delivery (introduction)

---

## Learning Objectives

By the end of this module, you will be able to:

- ✅ Define what an Internal Delivery Platform (IDP) is and explain its core components
- ✅ Articulate why organisations need IDPs using concrete DORA metrics
- ✅ Explain the "Platform as a Product" mindset and its benefits
- ✅ Navigate the uFawkesDevX platform (Backstage portal, Coder, Score service)
- ✅ Scaffold a new service using a golden-path Cookiecutter template
- ✅ Register a service in the Backstage catalog and verify it

---

## Module Structure

| Section   | Time   | Description                                              |
| --------- | ------ | -------------------------------------------------------- |
| Theory    | 15 min | What is an IDP, DORA metrics, Platform as a Product      |
| Demo      | 10 min | uFawkesDevX platform tour (video not produced)            |
| Lab 01    | 20 min | Start uFawkesDevX, explore catalog, scaffold service     |
| Quiz      | 5 min  | 10-question knowledge check                              |
| Reflection| 5 min  | Connect learnings to your work                           |

---

## Theory Summary (15 minutes)

### What is an Internal Delivery Platform?

An **Internal Delivery Platform (IDP)** is a curated set of tools, services, and
self-service capabilities that application teams use to deliver and manage their
software with minimal friction.

Think of it as **"paved roads for software delivery"** — just as cities build roads
so citizens do not have to navigate rough terrain, platforms build golden paths so
developers do not have to navigate infrastructure complexity.

#### The Three Characteristics of an IDP

1. **Self-Service** — developers provision resources and deploy without waiting for tickets
2. **Curated & Opinionated** — the platform team makes thoughtful tool and pattern decisions
3. **Built on Standards** — uses industry-standard tools to avoid vendor lock-in

### Why DORA Metrics Matter

According to the 2024 State of DevOps Report, elite performers compared to low performers:

- Deploy **973 times more frequently**
- Have a **6,570 times faster** lead time for changes
- Have a **3 times lower** change failure rate

An IDP is the mechanism that moves teams from low to elite performance by removing
toil, enforcing quality gates, and providing golden paths.

### The uFawkesDevX Platform Components

| Component                | Purpose                                                             |
| ------------------------ | ------------------------------------------------------------------- |
| **Backstage**            | Developer portal — service catalog, TechDocs, golden path scaffolder |
| **Coder**                | Cloud IDE — provisions ephemeral devcontainer workspaces            |
| **Score Service**        | Workload spec validation and pipeline triggering                    |
| **Plugin Manager**       | Platform extension and plugin management                            |
| **API Gateway**          | Unified entry point for all platform APIs                           |
| **Golden Path Templates**| Cookiecutter templates pre-wired with devcontainer, Score, CI/CD   |

---

## Lab

➡️ **[Lab 01: Scaffold a Service via Golden Path Template](lab-01/instructions.md)**

This lab walks you through starting the uFawkesDevX platform, exploring the Backstage
catalog, and scaffolding a new service (`hello-devx`) using the Fawkes golden path
template. You will register the service in Backstage and verify it appears in the
catalog with TechDocs.

**Runs against**: [uFawkesDevX v1.0.1](https://github.com/paruff/uFawkesDevX/releases/tag/v1.0.1) (Docker Compose), not `fawkes`/Kubernetes

> **Not yet run for real.** uFawkesDevX v1.0.1 exists, but no one has run every step of this lab against it. Treat the steps and the expected output as unverified. See the [audit](../../docs/ai-sdlc/compose-curriculum/audit-2026-10-06.md).

**Validation**: `bash white-belt/module-01-what-is-idp/lab-01/validate.sh`

---

## Success Criteria

You have mastered this module when you can:

- Explain to a colleague why your organisation needs a platform (in business terms)
- Navigate the uFawkesDevX Backstage portal and find a service's TechDocs
- Scaffold a new service using the golden path template and confirm it is registered
- Describe how the Score service validates workload specs and triggers pipelines

---

## Next Steps

After completing this module, proceed to:

➡️ **Module 02: DORA Metrics — Measuring Delivery Performance**
