# Module 8: Artifact Management with uFawkesPipe

**Belt Level**: 🟡 Yellow Belt
**Estimated Time**: 60 minutes of theory and quiz plus about 25 minutes of lab (estimates, not timed)
**Prerequisites**: Module 5, 6, 7 complete, uFawkesPipe v2.0.0 running
**DORA Capability**: Artifact Traceability, Deployment Automation, Release Management

---

## Learning Objectives

By the end of this module, you will be able to:

- ✅ Understand artifact management principles and how uFawkesPipe implements them
- ✅ Configure artifact build, tagging, and push via `.fawkespipe.yml`
- ✅ Configure container image scanning with Trivy
- ✅ Know that retention policies are not implemented by v2.0.0 (the contract field is ignored)
- ✅ Know that promotion is manual re-tagging in v2.0.0; no stage does it
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
| Lab 01        | 25 min | Build → scan → push, plus the generated deploy step and what the generator ignores |
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
Build → Scan (Trivy) → Push (Registry) → Deploy (as generated; promotion and retention are not implemented in v2.0.0)
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
1. Building an image in the pipeline and pushing it to a local registry
2. Watching the `image_scan` (Trivy) gate stop the push
3. Reading what the registry actually holds after a push
4. Seeing the generated `deploy` step fail, and fixing it by hand
5. Checking which contract fields (retention, promotion, signing, `kubernetes`) the generator ignores

**Runs against**: uFawkesPipe v2.0.0 (Docker Compose), last run for real on 2026-11-21 with a local registry. The lab covers build, image scan, push and the generated deploy step; v2.0.0 does not implement retention, promotion, signing or the `kubernetes` section (see the lab's Scope note).

**Prerequisites**: Module 7 completed, uFawkesPipe running

**Validation**: `bash yellow-belt/module-08-artifact-management/lab-01/validate.sh`

---

## Success Criteria

You have mastered this module when you can:

- Explain artifact management principles and how uFawkesPipe implements them
- Configure artifact build, tagging, and push via `.fawkespipe.yml`
- Configure container image scanning with Trivy
- Know which artifact features v2.0.0 does not implement (retention)
- Promote artifacts by re-tagging by hand (no stage does it)
- Monitor artifact metrics using Woodpecker UI and Prometheus/Grafana

---

## Next Steps

After completing this module, proceed to:

➡️ **Yellow Belt Assessment** — Deploy 2 additional applications, written exam, troubleshooting scenario
