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
| **secrets-scan** | Secret/credential detection | Gitleaks |
| **vuln-scan-fs** | Filesystem vulnerability scan | Trivy |
| **vuln-scan-image** | Container image scan | Trivy |
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
1. Exploring security stages in Woodpecker
2. Configuring SAST with SonarQube + Trivy + Bandit
4. Configuring dependency and image scanning
5. Enabling secret detection with Gitleaks
5. Integrating with DefectDojo
6. Practicing quality gate enforcement

**Runs against**: uFawkesPipe v2.0.0 (not released yet) (Docker Compose)

> **Written ahead of its stack, not yet run for real.** uFawkesPipe v2.0.0 has not been released, so no one has run every step of this lab against it. Treat the steps and the expected output as unverified. See the [audit](../../docs/ai-sdlc/compose-curriculum/audit-2026-10-06.md).

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
