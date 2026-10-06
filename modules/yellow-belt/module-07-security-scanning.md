# Module 7: Security Scanning & Quality Gates with uFawkesPipe

**Belt Level**: 🟡 Yellow Belt
**Duration**: 60 minutes
**Prerequisites**: Module 5 & 6 complete, uFawkesPipe v2.0.0 running
**DORA Capabilities**: Shift Left on Security (CD6), Security & Compliance Automation

---

## 1. Learning Objectives (3 minutes)

### What You'll Learn

By the end of this module, you will be able to:

- ✅ Understand "Shift Left on Security" principles and how uFawkesPipe implements them
- ✅ Implement Static Application Security Testing (SAST) with SonarQube + Trivy + Bandit
- ✅ Scan container images for vulnerabilities with Trivy
- ✅ Detect secrets and sensitive data with Gitleaks
- ✅ Perform dependency scanning with Trivy and OSV-Scanner
- ✅ Configure quality gates that enforce security standards
- ✅ Integrate security findings with DefectDojo
- ✅ Configure Dynamic Application Security Testing (DAST) with OWASP ZAP

### Why It Matters

**The Problem: Shift Right Security**

```
Traditional workflow (Shift Right):
Develop → Build → Test → Deploy → [SECURITY SCAN] → Production
                                    ↑
                              Find issues AFTER deployment
                              Expensive to fix
                              Delays release
```

**The Solution: Shift Left on Security**

```
uFawkesPipe Security-First Pipeline (Shift Left):
[SECURITY SCAN] → Develop → [SECURITY SCAN] → Build → [SECURITY SCAN] → Deploy
     ↑                           ↑                        ↑
  IDE plugins              CI/CD Pipeline            Pre-deploy check
 Immediate feedback       Fast feedback (5 min)       Pre-deploy check
```

**Cost of Finding Bugs by Stage**

| Stage          | Cost to Fix | Time to Fix | Impact                             |
| -------------- | ----------- | ----------- | ---------------------------------- |
| **IDE/Dev**    | $1          | Minutes     | None                               |
| **CI/CD**      | $10         | Hours       | Blocks build                       |
| **QA/Test**    | $100        | Days        | Delays release                     |
| **Production** | $1,000+     | Weeks       | Customer impact, reputation damage |

**10x-100x cheaper to catch early!**

### Success Criteria

You've mastered this module when you can:

- Explain Shift Left principles and how uFawkesPipe implements them
- Configure SAST with SonarQube, Trivy, and Bandit
- Configure container image scanning with Trivy
- Configure secret detection with Gitleaks
- Configure dependency scanning with Trivy/OSV-Scanner
- Configure quality gates with SonarQube
- Integrate findings with DefectDojo
- Configure DAST with OWASP ZAP

---

## 2. Theory & Concepts (25 minutes)

### 📺 Video: Shift Left Security with uFawkesPipe (10 minutes) — *not produced yet*

> **[VIDEO PLACEHOLDER]** > **Script Summary** *(video not produced)*:
>
> - Opening: Show the cost of finding bugs at each stage
> - Shift Left definition: Move security earlier in the pipeline
> - uFawkesPipe tour: Security stages (secrets-scan → vuln-scan-fs → vuln-scan-image)
> - Demo: Configure SAST, dependency scan, image scan in `.fawkespipe.yml`
> - Show DefectDojo integration for centralized findings
> - Show DAST configuration for running applications
> - Closing: "Security built into every pipeline, not bolted on"

### Shift Left on Security

**Traditional Security (Shift Right)**:

```
Develop → Build → Test → Deploy → [SECURITY SCAN] → Production
                                    ↑
                              Find issues AFTER deployment
                              Expensive to fix
                              Delays release
```

**Problems**:
- Security as afterthought
- Issues found late, expensive to fix
- Security team bottleneck
- Slow feedback (days/weeks)

**Shift Left with uFawkesPipe**:

```
uFawkesPipe Security-First Pipeline:
[SECRETS SCAN] → [SAST/DEPENDENCY SCAN] → [BUILD] → [IMAGE SCAN] → [DAST] → Deploy
     ↑                    ↑                    ↑                ↑
  Pre-commit           CI Pipeline         CI Pipeline      Staging
```

**Benefits**:
- ✅ Catch issues early (cheaper to fix)
- ✅ Developer ownership of security
- ✅ Automated enforcement
- ✅ Faster feedback loops
- ✅ Reduced security team bottleneck

### uFawkesPipe Security Architecture

uFawkesPipe implements security as **first-class pipeline stages** in the standard pipeline:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    uFawkesPipe Security Pipeline                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐                 │
│  │   validate   │───▶│     test     │───▶│   security   │                 │
│  │  (lint-yaml, │    │(unit, integ, │    │(secrets-scan,│                 │
│  │   lint-shell)│    │ contract)    │    │vuln-scan-fs, │                 │
│  └──────────────┘    │ contract)    │    │vuln-scan-img)│                 │
│         │            └──────────────┘    └──────┬───────┘                 │
│         │                                       │                           │
│         ▼                                       ▼                           │
│  ┌──────────────────────────────────────────────────────────────┐         │
│  │                    build (CNB)                                │         │
│  └──────────────────────────────────────────────────────────────┘         │
│         │                                                               │
│         ▼                                                               │
│  ┌──────────────────────────────────────────────────────────────┐         │
│  │              publish (DefectDojo upload)                      │         │
│  └──────────────────────────────────────────────────────────────┘         │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Security Stages in uFawkesPipe

| Stage | Purpose | Tools | Trigger |
|-------|---------|-------|---------|
| **secrets-scan** | Secret/credential detection | Gitleaks | Every push |
| **vuln-scan-fs** | Filesystem vulnerability scan | Trivy | Every push |
| **vuln-scan-image** | Container image scan | Trivy | Main branch only |
| **sast** | Static Application Security Testing | SonarQube, Trivy, Bandit | Every push |
| **dependency_scan** | Dependency vulnerability scan | Trivy / OSV-Scanner | Every push |
| **image_scan** | Container image scan | Trivy | Main branch only |
| **dast** | Dynamic App Security Testing | OWASP ZAP | Manual/Staging |
| **defectdojo** | Findings aggregation | DefectDojo API | Main branch only |

---

## 3. SAST — Static Application Security Testing (10 minutes)

### What is SAST?

**Static Application Security Testing (SAST)** analyzes source code without executing it to find security vulnerabilities, code quality issues, and technical debt.

**Detects**:
- Security vulnerabilities (SQL injection, XSS, path traversal)
- Code quality issues (dead code, duplicates, complexity)
- Security hotspots (crypto usage, hardcoded credentials)
- Technical debt and maintainability issues
- Code coverage gaps

### uFawkesPipe SAST Implementation

uFawkesPipe's `sast` stage runs multiple scanners in parallel:

```yaml
stages:
  sast:
    enabled: true
    sonarqube:
      enabled: true
      projectKey: my-app
      sources: src/
      exclusions: "**/test/**,**/tests/**"
      qualityGate: true
    trivy:
      enabled: true
      severity: HIGH,CRITICAL
    bandit:
      enabled: true
      severity: MEDIUM
      confidence: MEDIUM
```

### SAST Tools in uFawkesPipe

| Tool | Purpose | Language Support |
|------|---------|------------------|
| **SonarQube** | Code quality + security analysis | 30+ languages |
| **Trivy (fs)** | Filesystem vulnerability scan | All (via filesystem) |
| **Bandit** | Python security linting | Python |
| **SpotBugs** | Java static analysis | Java |
| **golangci-lint** | Go static analysis | Go |
| **ESLint/TSLint** | JS/TS static analysis | JavaScript/TypeScript |

### SonarQube Quality Gates

SonarQube quality gates enforce standards before code progresses:

```yaml
sast:
  sonarqube:
    enabled: true
    projectKey: my-app
    sources: src/
    exclusions: "**/test/**,**/tests/**"
    qualityGate: true  # Wait for quality gate result
```

**Recommended Quality Gate Conditions**:

| Condition | Threshold | Scope |
|-----------|-----------|-------|
| Coverage | > 80% | New code |
| Duplicated Lines | < 3% | New code |
| Maintainability Rating | ≥ A | New code |
| Reliability Rating | ≥ A | New code |
| Security Rating | ≥ A | New code |
| Security Hotspots Reviewed | 100% | New code |
| New Critical Issues | 0 | New code |
| New High Issues | 0 | New code |

### Bandit for Python

Bandit finds common security issues in Python code:

```yaml
sast:
  bandit:
    enabled: true
    severity: MEDIUM
    confidence: MEDIUM
```

**Common Bandit Findings**:
- Hardcoded passwords/secrets
- SQL injection vulnerabilities
- Use of insecure functions (eval, pickle)
- Insecure crypto (MD5, SHA1)
- Shell injection vulnerabilities

---

## 4. Dependency Scanning (5 minutes)

### What is Dependency Scanning?

Scans application dependencies (libraries, packages) for known vulnerabilities (CVEs).

### uFawkesPipe Dependency Scan

```yaml
stages:
  dependency_scan:
    enabled: true
    tools:
      - trivy
    fail_on: HIGH
```

**Tools Available**:
- **Trivy** (default): Scans lockfiles, package manifests for CVEs
- **OSV-Scanner** (optional): CVEs + license allowlist

**OSV-Scanner Example** (for license compliance):

```yaml
dependency_scan:
  enabled: true
  tools:
    - osv-scanner
  licenses:
    - MIT
    - Apache-2.0
```

### Output Reports

Both tools write machine-readable reports to `artifacts/security/`:
- **Trivy**: `trivy-repo.json` → DefectDojo `Trivy Scan`
- **OSV-Scanner**: `osv.json` → DefectDojo `OSV Scan`

---

## 5. Container Image Scanning (5 minutes)

### What is Image Scanning?

Scans the built container image for vulnerabilities in base image, installed packages, and application dependencies.

### uFawkesPipe Image Scan

```yaml
stages:
  image_scan:
    enabled: true
    tools:
      - trivy
    severity: HIGH,CRITICAL
    fail_on: CRITICAL
```

**Key Features**:
- Runs only on `main` branch (configured in pipeline)
- Scans base image, installed packages, application layer
- Fails build on CRITICAL vulnerabilities
- Generates `trivy-image.json` for DefectDojo

### Trivy Severity Levels

| Severity | CVSS Score | Action |
|----------|------------|--------|
| **CRITICAL** | 9.0-10.0 | Block deployment immediately |
| **HIGH** | 7.0-8.9 | Fix within 7 days |
| **MEDIUM** | 4.0-6.9 | Fix within 30 days |
| **LOW** | 0.1-3.9 | Fix when convenient |

---

## 6. Secret Detection (5 minutes)

### What is Secret Detection?

Scans codebase for hardcoded secrets, API keys, passwords, tokens, and other sensitive data.

### uFawkesPipe Secret Detection

```yaml
stages:
  security:
    # secrets-scan is part of security stage
    # runs Gitleaks on every push
```

**Gitleaks** is the secret detection tool:
- Scans all files for secrets, API keys, credentials
- Configured via `.gitleaks.toml` with allowlist for test fixtures
- Runs in pre-commit, Woodpecker CI, and GitHub Actions
- **Hard gate**: Any detected secret fails the pipeline immediately

**Configuration** (`.gitleaks.toml`):
```toml
[allowlist]
description = "Test fixtures and placeholders"
paths = [
  "(?i)test",
  "(?i)fixture",
  "(?i)mock"
]
regexes = [
  "test.*secret",
  "placeholder",
  "example"
]
```

---

## 7. Container Security & DAST (5 minutes)

### Dynamic Application Security Testing (DAST)

DAST actively scans a running application for vulnerabilities.

```yaml
stages:
  dast:
    enabled: false  # Enable for staging environments
    tool: zap
    target_url: http://my-app:8000
    rules: "Default Policy"
    fail_on: HIGH
    timeout: 300
```

**Requirements**:
- Application must be running and accessible
- Typically runs in staging/integration environment
- Runs after deployment to staging

**OWASP ZAP** is the default DAST tool:
- Active scanning against running endpoints
- Finds runtime vulnerabilities (XSS, SQLi, auth bypass)
- Configurable policies and rules

---

## 8. DefectDojo Integration (5 minutes)

### What is DefectDojo?

DefectDojo is a security findings management platform that aggregates findings from multiple scanners into a centralized dashboard.

### uFawkesPipe DefectDojo Integration

```yaml
stages:
  defectdojo:
    enabled: true
    url: http://defectdojo:8080
    engagement_name: CI-Engagement
```

**Requires Woodpecker secret**: `defectdojo_api_token`

### Report Mapping

| Report | Produced by | DefectDojo `scan_type` |
|--------|-------------|------------------------|
| `trivy-repo.json` | `dependency_scan` (trivy) | `Trivy Scan` |
| `trivy-image.json` | `image_scan` | `Trivy Scan` |
| `bandit.json` | `sast` (bandit) | `Bandit Scan` |
| `zap-baseline.xml` | `dast` | `ZAP Scan` |
| `zap-api.xml` | `dast` | `ZAP Scan` |
| `osv.json` | `dependency_scan` (osv-scanner) | `OSV Scan` |

**Key Features**:
- Each report uploaded independently
- Non-blocking — upload failure doesn't fail build
- Runs only on `push` to `main`

---

## 9. Quality Gates (5 minutes)

### Quality Gate Philosophy

> **"Quality gates should prevent bad code from progressing, not punish developers"**

### uFawkesPipe Quality Gates

Quality gates are enforced at multiple points:

1. **Gitleaks** (Hard gate) — Fails pipeline on any secret
2. **SonarQube Quality Gate** — Blocks on quality gate failure
3. **Trivy Severity Thresholds** — Fails on CRITICAL/HIGH findings
4. **Coverage Threshold** — Fails if coverage below threshold

### Configuring Quality Gates in `.fawkespipe.yml`

```yaml
stages:
  sast:
    sonarqube:
      qualityGate: true  # Wait for SonarQube quality gate
    trivy:
      severity: HIGH,CRITICAL
  test:
    coverage:
      threshold: 80
  image_scan:
    fail_on: CRITICAL
  dependency_scan:
    fail_on: HIGH
```

### Quality Gate Levels

| Stage | Gate | Action on Failure |
|-------|------|-------------------|
| **Development (PR)** | New code only | Block merge |
| **CI/CD (Main)** | New + overall | Block deployment |
| **Production** | All + manual approval | Manual approval required |

---

## 10. Complete Security Configuration Example

Here's a complete security-focused `.fawkespipe.yml`:

```yaml
app:
  name: secure-app
  type: service
  language: python
  version: 1.0.0

build:
  builder: cnb
  cnb:
    builder: paketobuildpacks/builder:base
    env:
      BP_CPYTHON_VERSION: "3.11"
  image:
    registry: docker.io
    namespace: myorg
    name: secure-app
    tags:
      - "${GIT_COMMIT_SHORT}"
      - "latest"

stages:
  lint:
    enabled: true
    commands:
      - language: python
        cmd: ruff check src/ && black --check src/
    dockerfile:
      enabled: true

  test:
    enabled: true
    commands:
      - language: python
        cmd: pytest tests/ --cov=src --cov-report=xml
    coverage:
      enabled: true
      threshold: 80
      report: coverage.xml

  sast:
    enabled: true
    sonarqube:
      enabled: true
      projectKey: secure-app
      sources: src/
      qualityGate: true
    trivy:
      enabled: true
      severity: HIGH,CRITICAL
    bandit:
      enabled: true
      severity: MEDIUM

  dependency_scan:
    enabled: true
    tools:
      - trivy
    fail_on: HIGH

  build:
    enabled: true

  image_scan:
    enabled: true
    severity: CRITICAL
    fail_on: CRITICAL

  dast:
    enabled: false  # Enable for staging
    tool: zap
    target_url: http://staging-app:8000

  defectdojo:
    enabled: true
    url: http://defectdojo:8080
    engagement_name: CI-Engagement

  push:
    enabled: true
    registries:
      - docker.io

advanced:
  timeout: 30
  parallel:
    enabled: true
  workspace:
    cleanup: true
```

---

## 11. Hands-On Lab (15 minutes)

### Lab Overview

You'll configure a complete security pipeline in uFawkesPipe:
1. Explore security stages in Woodpecker
2. Configure SAST with SonarQube + Trivy + Bandit
3. Configure dependency and image scanning
4. Enable secret detection with Gitleaks
5. Integrate with DefectDojo
6. Practice quality gate enforcement

**Time Estimate**: 15 minutes
**Difficulty**: Intermediate (Modules 5-6 complete)
**Auto-Graded**: Yes
**Points**: 100

➡️ **[Lab 01: Security Scanning with uFawkesPipe](yellow-belt/module-07-security-scanning/lab-01/instructions.md)**

This lab walks you through configuring all security stages, running a pipeline, and examining findings in DefectDojo.

**Validation**: `bash yellow-belt/module-07-security-scanning/lab-01/validate.sh`

---

## 12. Knowledge Check (5 minutes)

### Quiz: Security Scanning with uFawkesPipe

**Instructions**: Answer all 10 questions. You need 8/10 (80%) to pass. Unlimited attempts allowed.

#### Question 1

**What does "Shift Left on Security" mean?**

- [ ] A) Move security testing to production
- [x] B) Move security testing earlier in the development lifecycle
- [ ] C) Move security team to the left side of the org chart
- [ ] D) Reduce security budget

**Explanation**: Shift Left means moving security testing **earlier** in the development lifecycle — from production back to development and CI/CD.

---

#### Question 2

**In uFawkesPipe, which stage runs secret detection?**

- [ ] A) validate
- [ ] B) test
- [x] C) security (secrets-scan)
- [ ] D) build

**Explanation**: The **security** stage runs `secrets-scan` (Gitleaks) along with `vuln-scan-fs` and `vuln-scan-image`.

---

#### Question 3

**Which tool provides SAST in uFawkesPipe?**

- [ ] A) Gitleaks
- [ ] B) Woodpecker
- [x] C) SonarQube (with Trivy and Bandit)
- [ ] D) Portainer

**Explanation**: **SonarQube** is the primary SAST tool, augmented by Trivy filesystem scanning and Bandit for Python.

---

#### Question 4

**Which uFawkesPipe stage scans container images for vulnerabilities?**

- [ ] A) dependency_scan
- [ ] B) sast
- [x] C) image_scan
- [ ] D) dependency_scan

**Explanation**: The **image_scan** stage scans built container images for vulnerabilities using Trivy.

---

#### Question 5

**What does `sast.sonarqube.qualityGate: true` do?**

- [ ] A) Runs SonarQube analysis
- [x] B) Waits for SonarQube quality gate result before continuing
- [ ] C) Sets the quality gate threshold
- [ ] D) Disables SonarQube

**Explanation**: Setting `qualityGate: true` makes the pipeline **wait for the SonarQube quality gate result** and fails if the gate fails.

---

#### Question 6

**Which tool detects hardcoded secrets in uFawkesPipe?**

- [ ] A) Trivy
- [ ] B) SonarQube
- [x] C) Gitleaks
- [ ] D) Bandit

**Explanation**: **Gitleaks** is the secret detection tool that acts as a hard gate — any detected secret fails the pipeline immediately.

---

#### Question 6

**What does `stages.image_scan.fail_on: CRITICAL` do?**

- [ ] A) Scans only CRITICAL vulnerabilities
- [ ] B) Ignores CRITICAL vulnerabilities
- [x] C) Fails the build if CRITICAL vulnerabilities found
- [ ] D) Reports only CRITICAL vulnerabilities

**Explanation**: `fail_on: CRITICAL` sets the severity threshold — the build **fails** if any CRITICAL vulnerabilities are found in the container image.

---

#### Question 7

**How does uFawkesPipe integrate with DefectDojo?**

- [ ] A) Manual upload via UI
- [x] B) Automatic upload via API after security stages
- [ ] C) Email reports to DefectDojo
- [ ] D) Manual CSV import

**Explanation**: The `defectdojo` stage automatically uploads security reports (Trivy, Bandit, ZAP) to DefectDojo via API after security stages complete.

---

#### Question 8

**What does `stages.dependency_scan.tools: [osv-scanner]` enable?**

- [ ] A) Trivy filesystem scan
- [x] B) OSV-Scanner for CVEs + license compliance
- [ ] C) OWASP Dependency Check
- [ ] D) SonarQube dependency analysis

**Explanation**: OSV-Scanner provides CVE scanning **plus** license compliance checking with an allowlist.

---

#### Question 9

**What is the purpose of the `defectdojo` stage in uFawkesPipe?**

- [ ] A) Run DAST scans
- [x] B) Upload security findings to DefectDojo for centralized tracking
- [ ] C) Run quality gates
- [ ] D) Generate SBOM

**Explanation**: The `defectdojo` stage **uploads security findings** (Trivy, Bandit, ZAP reports) to DefectDojo for centralized findings tracking and management.

---

#### Question 10

**Which security scan runs only on the main branch in uFawkesPipe?**

- [ ] A) secrets-scan
- [ ] B) vuln-scan-fs
- [x] C) vuln-scan-image
- [ ] D) sast

**Explanation**: `vuln-scan-image` (container image scanning) runs **only on main branch** pushes, while other scans run on every push.

---

### Quiz Results

**Score: X / 10**

- ✅ **Passed** (8+): Excellent! You understand security scanning with uFawkesPipe.
- ❌ **Not Yet** (<8): Review the theory section and try again.

**Incorrect answers?** Each question links back to the relevant section for review.

---

## 13. Reflection & Next Steps (5 minutes)

### What You Learned

✅ **You now know**:
- Shift Left Security principles and uFawkesPipe's implementation
- How to configure SAST with SonarQube, Trivy, and Bandit
- How to scan container images with Trivy
- How to detect secrets with Gitleaks
- How to scan dependencies with Trivy/OSV-Scanner
- How to configure quality gates with SonarQube
- How to integrate findings with DefectDojo
- How to configure DAST with OWASP ZAP

✅ **You can now**:
- Configure a complete security pipeline in `.fawkespipe.yml`
- Interpret security scan results
- Enforce quality gates
- Integrate findings with DefectDojo

### How This Connects to Your Work

**For Developers**:
- Security is automated — no manual steps
- Fast feedback on every commit
- Security issues caught before they reach production

**For Platform Engineers**:
- Security is built into the platform, not bolted on
- Centralized findings in DefectDojo
- Consistent security across all teams

**For Leaders**:
- Security is automated and measurable
- Compliance evidence in DefectDojo
- Reduced risk and faster delivery

### Reflection Questions

1. **What surprised you most about security in uFawkesPipe?**
2. **How does your current security process compare?**
3. **What quality gate would you add for your team?**
4. **Who on your team should go through this module?**

### Preview: Module 8

**Next Up: Artifact Management**

In Module 8, you'll learn:
- Artifact repositories (Harbor, Nexus, Artifactory)
- Image promotion and signing
- SBOM generation and management
- Supply chain security (SLSA, in-toto)
- Artifact retention and cleanup policies

**Time**: 60 minutes
**Prerequisites**: Module 7 complete ✅

---

## Module Completion

### ✅ You've Completed Module 7

**Next Steps**:
1. ✅ Mark this module complete in your Backstage profile
2. 📊 View your progress on the Dojo dashboard
3. 💬 Share your completion in [Show and tell](https://github.com/paruff/uFawkesDojo/discussions/categories/show-and-tell) (optional!)
4. ➡️ **Continue to Module 8** when ready

**Time Investment**: 60 minutes
**Skills Gained**: Security scanning, SAST, DAST, quality gates, DefectDojo integration
**Progress**: 3 of 4 modules toward Yellow Belt (75% complete)

---

**Questions or Issues?**
- 💬 Ask in [GitHub Discussions](https://github.com/paruff/uFawkesDojo/discussions) ([Q&A](https://github.com/paruff/uFawkesDojo/discussions/categories/q-a))
- 📧 Email: dojo@ufawkes.dev
- 🐛 Report bugs: [GitHub Issues](https://github.com/paruff/fawkes/issues)

**Feedback?**
- Rate this module (takes 30 seconds)
- Suggest improvements
- Help us make the dojo better!

---

**Module Author**: Fawkes Learning Team
**Last Updated**: October 2026
**Version**: 2.0
