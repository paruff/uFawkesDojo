# Module 7: Security Scanning & Quality Gates with uFawkesPipe

**Belt Level**: 🟡 Yellow Belt
**Estimated Time**: 60 minutes (25 min theory + 10 min SAST + 5 min dependency + 5 min image + 5 min secrets + 5 min DAST/DefectDojo + 5 min quality gates + 15 min lab)
**Prerequisites**: Module 5 & 6 complete, uFawkesPipe v2.0.0 running
**DORA Capability**: Shift Left on Security (CD6), Security & Compliance Automation

---

## Learning Objectives

By the end of this module, you will be able to:

- ✅ Understand "Shift Left on Security" principles and how uFawkesPipe implements them
- ✅ Implement Static Application Security Testing (SAST) with SonarQube + Trivy + Bandit
- ✅ Scan container images for vulnerabilities with Trivy
- ✅ Detect secrets and sensitive data with Gitleaks
- ✅ Perform dependency scanning with Trivy and OSV-Scanner
- ✅ Configure quality gates that enforce security standards
- ✅ Integrate security findings with DefectDojo
- ✅ Configure Dynamic Application Security Testing (DAST) with OWASP ZAP

---

## Module Structure

| Section       | Time   | Description                                         |
| ------------- | ------ | --------------------------------------------------- |
| Theory        | 25 min | Shift Left, uFawkesPipe security architecture      |
| SAST          | 10 min | SonarQube, Trivy, Bandit                           |
| Dependency    | 5 min  | Dependency vulnerability scanning                  |
| Image Scan    | 5 min  | Container image vulnerability scanning             |
| Secrets       | 5 min  | Secret detection with Gitleaks                     |
| DAST/DefectDojo | 5 min | DAST with OWASP ZAP, DefectDojo integration       |
| Quality Gates | 5 min  | Quality gate configuration                         |
| Lab 01        | 15 min | Configure security pipeline, examine findings      |

---

## Theory Summary (25 minutes)

### Shift Left on Security

**Shift Left** means moving security testing earlier in the development lifecycle:

```
Traditional (Shift Right):          uFawkesPipe (Shift Left):
Develop → Build → Test → [SCAN] →   [SCAN] → Develop → [SCAN] → Build → [SCAN] → Deploy
Deploy → Production                       ↑                    ↑
                                              │                    │
                                      IDE/CI/CD           Container Registry
```

### uFawkesPipe Security Stages

| Stage | Purpose | Tools |
|-------|---------|-------|
| **sast** | Static Application Security Testing | SonarQube, Trivy, Bandit |
| **dependency_scan** | Dependency vulnerability scan | Trivy / OSV-Scanner |
| **image_scan** | Container image scan | Trivy |
| **dast** | Dynamic App Security Testing | OWASP ZAP |
| **defectdojo** | Findings aggregation | DefectDojo API |

### Security Tools in uFawkesPipe

| Tool | Purpose |
|------|---------|
| **SonarQube** | SAST, code quality, quality gates |
| **Trivy** | Filesystem + image vulnerability scanning |
| **Bandit** | Python security linting |
| **Gitleaks** | Secret detection (hard gate) |
| **OSV-Scanner** | Dependency CVE + license scanning |
| **OWASP ZAP** | Dynamic Application Security Testing |
| **DefectDojo** | Centralized findings management |

---

## Lab

➡️ **[Lab 01: Security Scanning with uFawkesPipe](lab-01/instructions.md)**

This lab walks you through:
1. Reading the security stages in the generator
2. Running a Trivy `dependency_scan` pipeline green
3. Making it fail with a vulnerable dependency, then finding the CVE
4. Making the same stage fail on a planted secret
5. Fixing both and recovering
6. Adding SonarQube SAST and seeing what v2.0.0 needs from you
7. Building an image and scanning it
8. Gating on Bandit, running a ZAP scan, and uploading findings to DefectDojo

**Runs against**: uFawkesPipe v2.0.0 and uFawkesDevX v1.2.0 (Docker Compose)

> **Last run for real**: 2026-11-21, against uFawkesPipe v2.0.0. Every stage the lab covers was run: `dependency_scan`, `sast` (SonarQube), `build` plus `image_scan`, Bandit (through the lint command), `dast` (ZAP) and the `defectdojo` upload. None works out of the box in v2.0.0; the lab spells out each defect and workaround. Known gaps: Trivy and Bandit inside `sast` do not work, the `dast` step still ends red, and v2.0.0 has no Gitleaks stage. The theory sections have a correction banner but are otherwise unchanged. The Woodpecker runs used uFawkesDevX v1.0.1. The lab pins v1.2.0 now: its `python-flask-app` template differs from v1.0.1 by one comment in `src/app.py`, and Step 2's scaffold and pipeline generation were re-run on v1.2.0 (2026-11-21) with identical output. The pipeline runs themselves were not repeated on v1.2.0.

**Prerequisites**: Module 5 & 6 completed, uFawkesPipe running

**Validation**: `bash yellow-belt/module-07-security-scanning/lab-01/validate.sh`

---

## Success Criteria

You have mastered this module when you can:

- Explain Shift Left principles and how uFawkesPipe implements them
- Configure SAST with SonarQube, Trivy, and Bandit
- Configure container image scanning with Trivy
- Configure secret detection with Gitleaks
- Configure dependency scanning with Trivy/OSV-Scanner
- Configure quality gates with SonarQube
- Integrate findings with DefectDojo
- Configure DAST with OWASP ZAP

---

## Next Steps

After completing this module, proceed to:

➡️ **Module 08: Artifact Management**
