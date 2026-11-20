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

**Runs against**: uFawkesPipe v2.0.0 and uFawkesDevX v1.0.1 (Docker Compose)

> **Last run for real**: 2026-11-20, against uFawkesPipe v2.0.0. Only `dependency_scan` (Trivy) was run. SonarQube SAST, Bandit, image scanning, DAST, DefectDojo and a separate Gitleaks gate were **not** run (v2.0.0 has no Gitleaks stage; they need services and credentials the lab does not set up). The theory covers them; treat those parts as unrun.

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
