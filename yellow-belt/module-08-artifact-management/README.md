# Module 8: Artifact Management with uFawkesPipe

**Belt Level**: 🟡 Yellow Belt
**Estimated Time**: 60 minutes (25 min theory + 10 min build/push + 10 min scanning + 5 min retention + 10 min promotion + 5 min lab + 5 min quiz)
**Prerequisites**: Module 5, 6, 7 complete, uFawkesPipe v2.0.0 running
**DORA Capability**: Artifact Traceability, Deployment Automation, Release Management

---

## Learning Objectives

By the end of this module, you will be able to:

- ✅ Understand artifact management principles and how uFawkesPipe implements them
- ✅ Configure artifact build, tagging, and push via `.fawkespipe.yml`
- ✅ Configure container image scanning with Trivy
- ✅ Configure artifact retention policies
- ✅ Implement artifact promotion across environments
- ✅ Monitor artifact metrics using Woodpecker UI and Prometheus/Grafana

---

## Module Structure

| Section       | Time   | Description                                         |
| ------------- | ------ | --------------------------------------------------- |
| Theory        | 25 min | Artifact management principles, uFawkesPipe model   |
| Build & Push  | 10 min | CNB build, tagging, registry push                   |
| Security      | 10 min | Image scanning, vulnerability thresholds            |
| Retention     | 5 min  | Artifact lifecycle and retention policies           |
| Promotion     | 10 min | Artifact promotion across environments              |
| Lab 01        | 10 min | Full artifact lifecycle: build → scan → push → promote |
| Quiz          | 5 min  | 10-question knowledge check                         |

---

## Theory Summary (25 minutes)

### What is Artifact Management?

**Artifact Management** is the practice of centrally storing, versioning, securing, and distributing build artifacts (container images, packages, binaries) throughout the software delivery lifecycle.

**Traditional (Ad-Hoc)**:
```
Team A: Local machine storage
Team B: Random Docker Hub accounts
Team C: Rebuild from source every time
```

**uFawkesPipe (Centralized)**:
```
Single Source of Truth (.fawkespipe.yml)
       ↓
Build (CNB) → Scan (Trivy) → Push (Registry) → Promote (Deploy)
       ↓
Retention Policies → Metrics & Monitoring
```

### uFawkesPipe Artifact Management Model

| Concept | uFawkesPipe Implementation |
|---------|----------------------------|
| **Registry** | `build.image.registry` + `stages.push.registries` |
| **Tagging** | `build.image.tags` with CI variables |
| **Scanning** | `stages.image_scan` (Trivy) |
| **Promotion** | `stages.deploy` with target environments |
| **Retention** | `advanced.artifacts.retention` (days) |
| **Artifacts** | `advanced.artifacts.paths` + `retention` |

### Pipeline Stages for Artifacts

| # | Stage | Artifact Action |
|---|-------|-----------------|
| 1 | **validate** | Initialize artifact directories |
| 2 | **test** | Run tests, generate coverage artifacts |
| 3 | **security** | `secrets-scan`, `vuln-scan-fs` |
| 4 | **sast** | SAST analysis (SonarQube, Trivy, Bandit) |
| 5 | **dependency_scan** | Dependency vulnerability scan |
| 5 | **build** | CNB build → OCI image |
| 6 | **image_scan** | Trivy container image scan |
| 7 | **push** | Push to configured registries |
| 8 | **deploy** | Promote to target environment |
| 9 | **publish** | Upload findings to DefectDojo |

---

## Lab

➡️ **[Lab 01: Artifact Lifecycle with uFawkesPipe](lab-01/instructions.md)**

This lab walks you through:
1. Configuring artifact build, tagging, and push via `.fawkespipe.yml`
4. Configuring image scanning with Trivy
4. Configuring artifact retention policies
5. Practicing artifact promotion across environments
6. Verifying artifact lifecycle

**Runs against**: uFawkesPipe v2.0.0 (not released yet) (Docker Compose)

> **Written ahead of its stack, not yet run for real.** uFawkesPipe v2.0.0 has not been released, so no one has run every step of this lab against it. Treat the steps and the expected output as unverified. See the [audit](../../docs/ai-sdlc/compose-curriculum/audit-2026-10-06.md).

**Prerequisites**: Module 7 completed, uFawkesPipe running

**Validation**: `bash yellow-belt/module-08-artifact-management/lab-01/validate.sh`

---

## Success Criteria

You have mastered this module when you can:

- Explain artifact management principles and how uFawkesPipe implements them
- Configure artifact build, tagging, and push via `.fawkespipe.yml`
- Configure container image scanning with Trivy
- Configure artifact retention policies
- Implement artifact promotion across environments
- Monitor artifact metrics using Woodpecker UI and Prometheus/Grafana

---

## Next Steps

After completing this module, proceed to:

➡️ **Yellow Belt Assessment** — Deploy 2 additional applications, written exam, troubleshooting scenario
