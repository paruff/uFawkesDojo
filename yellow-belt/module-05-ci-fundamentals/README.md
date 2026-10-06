# Module 5: CI Fundamentals with uFawkesPipe

**Belt Level**: 🟡 Yellow Belt
**Estimated Time**: 60 minutes (20 min theory + 10 min architecture + 5 min security + 20 min lab + 5 min quiz)
**Prerequisites**: White Belt complete, Docker basics, Git workflows
**DORA Capability**: Continuous Integration (CD3)

---

## Learning Objectives

By the end of this module, you will be able to:

- ✅ Explain the principles and benefits of Continuous Integration
- ✅ Understand uFawkesPipe architecture and Woodpecker CI core concepts
- ✅ Create your first `.fawkespipe.yml` pipeline contract
- ✅ Configure pipeline stages: lint, test, security, build
- ✅ Implement security scanning (SAST, dependency scan, image scan)
- ✅ Understand how CI improves DORA metrics
- ✅ Troubleshoot common CI pipeline failures in Woodpecker

---

## Module Structure

| Section    | Time   | Description                                         |
| ---------- | ------ | --------------------------------------------------- |
| Theory     | 20 min | CI principles, uFawkesPipe architecture            |
| Architecture | 10 min | Woodpecker, SonarQube, Trivy, Gitleaks components  |
| Security   | 5 min  | Security-first pipeline stages                     |
| Lab 01     | 20 min | Create pipeline, watch execution, security scans   |
| Quiz       | 5 min  | 10-question knowledge check                        |

---

## Theory Summary (20 minutes)

### What is Continuous Integration?

**Continuous Integration (CI)** is the practice of merging all developers' working copies to a shared mainline several times a day, with each merge verified by an automated build and test process.

### Core CI Principles

1. **Maintain a Single Source Repository**
2. **Automate the Build**
3. **Make Your Build Self-Testing**
4. **Everyone Commits to Mainline Daily**
5. **Every Commit Builds on Integration Machine**
6. **Keep the Build Fast** (<10 min target)
7. **Test in Clone of Production Environment**
8. **Make it Easy to Get Latest Deliverables**
9. **Everyone Can See What's Happening**
10. **Automate Deployment**

### uFawkesPipe Architecture

| Component | Role |
|-----------|------|
| **Woodpecker Server** | Orchestrates pipelines, GitHub OAuth, Web UI |
| **Woodpecker Agent** | Executes pipeline steps in Docker containers |
| **SonarQube** | SAST, code quality gates |
| **Trivy** | Vulnerability scanning (fs + image) |
| **Gitleaks** | Secret detection (hard gate) |
| **Portainer CE** | Container management (CD) |
| **CNB Builder** | Cloud Native Buildpacks for OCI images |

### Pipeline Stages

| # | Stage | Steps |
|---|-------|-------|
| 1 | **validate** | `init` → `lint-yaml` + `lint-shell` |
| 2 | **test** | `unit-tests` + `integration-tests` + `contract-tests` |
| 3 | **security** | `secrets-scan` → `vuln-scan-fs` → `vuln-scan-image` |
| 4 | **build** | `build-image` (CNB) |
| 5 | **publish** | `upload-defectdojo` |
| 6 | **deploy** | `notify-obs` |

---

## Lab

➡️ **[Lab 01: Your First Pipeline with uFawkesPipe](lab-01/instructions.md)**

This lab walks you through:
1. Exploring Woodpecker CI UI (worked example)
2. Creating `.fawkespipe.yml` for a sample app
3. Pushing to Git, activating repo in Woodpecker
4. Watching pipeline execute through all stages
5. Examining security scan results
6. Practicing failure/recovery cycle

**Runs against**: uFawkesPipe v2.0.0 (not released yet) (Docker Compose)

> **Written ahead of its stack, not yet run for real.** uFawkesPipe v2.0.0 has not been released, so no one has run every step of this lab against it. Treat the steps and the expected output as unverified. See the [audit](../../docs/ai-sdlc/compose-curriculum/audit-2026-10-06.md).

**Validation**: `bash yellow-belt/module-05-ci-fundamentals/lab-01/validate.sh`

---

## Success Criteria

You have mastered this module when you can:

- Explain CI principles and how uFawkesPipe implements them
- Create a `.fawkespipe.yml` from scratch for any application
- Configure all standard pipeline stages (lint, test, security, build)
- Debug a failed pipeline in Woodpecker UI
- Explain how CI improves each DORA metric

---

## Next Steps

After completing this module, proceed to:

➡️ **Module 06: Golden Path Pipelines — Reusable Templates & Optimization**
