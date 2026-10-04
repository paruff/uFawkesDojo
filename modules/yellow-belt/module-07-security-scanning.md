# Fawkes Dojo Module 7: Security Scanning & Quality Gates

> ⚠️ **This module teaches Jenkins-based security scanning (SonarQube, Trivy, secrets detection in Jenkins pipelines), which is replaced in Dojo 0.4 by uFawkesPipe (Woodpecker CI with Conftest/Rego policy checks, Trivy, Gitleaks, DefectDojo).**  
> The Yellow Belt security content is being migrated to uFawkesPipe's security scanning stack.  
> See [uFawkesPipe](https://github.com/paruff/uFawkesPipe) and the [Dojo 0.4 release plan](https://github.com/paruff/uFawkes.dev/blob/main/docs/ai-sdlc/suite-release/plan.md#phase-4--ufawkespipe-v200--dojo-04-gate-ac-pipe-01).

## 🎯 Module Overview

**Belt Level**: 🟡 Yellow Belt - CI/CD Mastery
**Module**: 3 of 4 (Yellow Belt)
**Duration**: 60 minutes
**Difficulty**: Intermediate
**Prerequisites**:

- Module 5 & 6 complete
- Understanding of CI/CD pipelines
- Basic security awareness
- Familiarity with code quality concepts

---

## 📚 Learning Objectives

By the end of this module, you will:

1. ✅ Understand "Shift Left on Security" principles
2. ✅ Implement static code analysis with SonarQube
3. ✅ Scan container images for vulnerabilities with Trivy
4. ✅ Detect secrets and sensitive data in code
5. ✅ Perform dependency scanning and SBOM generation
6. ✅ Configure quality gates that enforce standards
7. ✅ Integrate security scanning into Golden Path pipelines

**DORA Capabilities Addressed**:

- ✓ CD6: Shift Left on Security
- ✓ CD8: Test Data Management
- ✓ Security & Compliance Automation

---

## 📖 Part 1: Shift Left on Security

### The Traditional Security Approach (Shift Right)

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

### Shift Left on Security

```
[SECURITY SCAN] → Develop → [SECURITY SCAN] → Build → [SECURITY SCAN] → Deploy
      ↑                            ↑                         ↑
   IDE plugins            CI/CD Pipeline              Container scan
   Immediate feedback     Fast feedback (5 min)       Pre-deploy check
```

**Benefits**:

- ✅ Catch issues early (cheaper to fix)
- ✅ Developer ownership of security
- ✅ Automated enforcement
- ✅ Faster feedback loops
- ✅ Reduced security team bottleneck

### Cost of Finding Bugs by Stage

| Stage          | Cost to Fix | Time to Fix | Impact                             |
| -------------- | ----------- | ----------- | ---------------------------------- |
| **IDE/Dev**    | $1          | Minutes     | None                               |
| **CI/CD**      | $10         | Hours       | Blocks build                       |
| **QA/Test**    | $100        | Days        | Delays release                     |
| **Production** | $1,000+     | Weeks       | Customer impact, reputation damage |

**10x-100x cheaper to catch early!**

---

## 🏗️ Part 2: Static Application Security Testing (SAST)

### What is SAST?

**Static Analysis**: Analyze source code without executing it

**Detects**:

- Security vulnerabilities (SQL injection, XSS, etc.)
- Code quality issues (dead code, duplicates)
- Code smells (complex methods, poor structure)
- Technical debt
- Coverage gaps

### SonarQube in Fawkes

SonarQube is the SAST tool integrated into Fawkes platform.

**Key Features**:

- 30+ language support
- 5,000+ rules
- Quality gates
- Technical debt tracking
- Security hotspots
- Pull request decoration

**Architecture**:

```
┌────────────────────────────────────────┐
│         Jenkins Pipeline               │
│  ┌──────────────────────────────────┐  │
│  │  sonar-scanner                   │  │
│  │  • Analyzes code                 │  │
│  │  • Sends to SonarQube server     │  │
│  └──────────────┬───────────────────┘  │
└─────────────────┼──────────────────────┘
                  │
        ┌─────────▼──────────┐
        │  SonarQube Server  │
        │  • Stores results  │
        │  • Applies rules   │
        │  • Quality gates   │
        └─────────┬──────────┘
                  │
        ┌─────────▼──────────┐
        │  PostgreSQL DB     │
        │  • Historical data │
        └────────────────────┘
```

---

## 🛠️ Part 3: Hands-On Lab - Implementing Security Scanning

### Step 1: Add SonarQube to Pipeline

Update your Golden Path pipeline:

```groovy
// vars/goldenPathJava.groovy
stage('Code Analysis') {
    steps {
        container('maven') {
            withSonarQubeEnv('Fawkes-SonarQube') {
                sh '''
                    mvn sonar:sonar \
                        -Dsonar.projectKey=${JOB_NAME} \
                        -Dsonar.projectName="${JOB_NAME}" \
                        -Dsonar.projectVersion=${BUILD_NUMBER} \
                        -Dsonar.sources=src/main/java \
                        -Dsonar.tests=src/test/java \
                        -Dsonar.java.binaries=target/classes \
                        -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml
                '''
            }
        }
    }
}

stage('Quality Gate') {
    steps {
        timeout(time: 5, unit: 'MINUTES') {
            waitForQualityGate abortPipeline: true
        }
    }
}
```

### Step 2: Configure Quality Gate

**In SonarQube UI**:

1. Go to Quality Gates
2. Create new gate: "Fawkes Standard"
3. Add conditions:

```
Conditions:
├── Coverage < 80% → FAILED
├── Duplicated Lines (%) > 3% → FAILED
├── Maintainability Rating worse than A → FAILED
├── Reliability Rating worse than A → FAILED
├── Security Rating worse than A → FAILED
├── Security Hotspots Reviewed < 100% → FAILED
└── New Critical Issues > 0 → FAILED
```

4. Set as default gate

### Step 3: Add Container Scanning with Trivy

```groovy
stage('Container Security Scan') {
    steps {
        container('docker') {
            script {
                def imageName = "${env.DOCKER_IMAGE}"

                echo "🔒 Scanning image: ${imageName}"

                // Scan for vulnerabilities
                sh """
                    trivy image \
                        --severity HIGH,CRITICAL \
                        --exit-code 1 \
                        --no-progress \
                        --format json \
                        --output trivy-report.json \
                        ${imageName}
                """

                // Also generate human-readable report
                sh """
                    trivy image \
                        --severity HIGH,CRITICAL \
                        --format table \
                        ${imageName}
                """
            }
        }
    }
    post {
        always {
            archiveArtifacts artifacts: 'trivy-report.json',
                             allowEmptyArchive: true
        }
    }
}
```

### Step 4: Secret Scanning

```groovy
stage('Secret Detection') {
    steps {
        container('maven') {
            script {
                echo "🔍 Scanning for secrets..."

                // Install trufflehog
                sh '''
                    pip3 install trufflehog
                '''

                // Scan repository
                sh '''
                    trufflehog filesystem . \
                        --json \
                        --fail \
                        --no-update \
                        > trufflehog-report.json || true
                '''

                // Check results
                def report = readFile('trufflehog-report.json')
                if (report.trim()) {
                    error("🚨 Secrets detected in code! See trufflehog-report.json")
                }
            }
        }
    }
}
```

### Step 5: Dependency Scanning

```groovy
stage('Dependency Scan') {
    steps {
        container('maven') {
            script {
                echo "📦 Scanning dependencies..."

                // OWASP Dependency Check
                sh '''
                    mvn dependency-check:check \
                        -DfailBuildOnCVSS=7 \
                        -DsuppressionFile=dependency-check-suppressions.xml
                '''
            }
        }
    }
    post {
        always {
            publishHTML([
                allowMissing: false,
                alwaysLinkToLastBuild: true,
                keepAll: true,
                reportDir: 'target',
                reportFiles: 'dependency-check-report.html',
                reportName: 'Dependency Check Report'
            ])
        }
    }
}
```

---

## 📊 Part 4: Understanding Security Scan Results

### SonarQube Metrics Explained

**1. Bugs** 🐛

- Code that is demonstrably wrong
- Example: Null pointer dereference
- **Standard**: 0 bugs

**2. Vulnerabilities** 🔓

- Security-related issues
- Example: SQL injection risk
- **Standard**: 0 vulnerabilities

**3. Code Smells** 👃

- Maintainability issues
- Example: Method too complex
- **Standard**: < 5% code smells

**4. Security Hotspots** 🔥

- Security-sensitive code requiring review
- Example: Cryptographic operations
- **Standard**: 100% reviewed

**5. Coverage** 📊

- % of code covered by tests
- **Standard**: > 80%

**6. Duplications** ©️

- Duplicate code blocks
- **Standard**: < 3%

**7. Technical Debt** 💸

- Time to fix all issues
- **Standard**: < 5% debt ratio

### Trivy Severity Levels

| Severity     | CVSS Score | Action Required              |
| ------------ | ---------- | ---------------------------- |
| **CRITICAL** | 9.0-10.0   | Block deployment immediately |
| **HIGH**     | 7.0-8.9    | Fix within 7 days            |
| **MEDIUM**   | 4.0-6.9    | Fix within 30 days           |
| **LOW**      | 0.1-3.9    | Fix when convenient          |
| **UNKNOWN**  | N/A        | Investigate                  |

**Trivy Output Example**:

```
myapp:1.0 (alpine 3.18.0)
═══════════════════════════════════════
Total: 2 (HIGH: 1, CRITICAL: 1)

┌────────────────┬────────────────┬──────────┬───────────────────┐
│    Library     │ Vulnerability  │ Severity │  Installed Version │
├────────────────┼────────────────┼──────────┼───────────────────┤
│ openssl        │ CVE-2023-12345 │ CRITICAL │ 3.0.8-r0          │
│ curl           │ CVE-2023-67890 │ HIGH     │ 8.0.1-r0          │
└────────────────┴────────────────┴──────────┴───────────────────┘
```

---

## 🎯 Part 5: Configuring Quality Gates

### Quality Gate Philosophy

> **"Quality gates should prevent bad code from progressing, not punish developers"**

**Good Quality Gates**:

- ✅ Focus on new code (not legacy)
- ✅ Achievable standards
- ✅ Fast feedback (<5 min)
- ✅ Clear remediation steps

**Bad Quality Gates**:

- ❌ Unrealistic standards (100% coverage)
- ❌ Block on legacy debt
- ❌ Slow feedback (>30 min)
- ❌ Vague error messages

### Recommended Quality Gates by Stage

**Development (IDE/PR)**:

```yaml
gates:
  - New Bugs: 0
  - New Vulnerabilities: 0
  - New Code Coverage: > 80%
  - New Duplications: < 3%
```

**CI/CD (Main Branch)**:

```yaml
gates:
  - Overall Bugs: < 10
  - Overall Vulnerabilities: 0
  - Overall Coverage: > 70%
  - Security Hotspots Reviewed: 100%
  - Maintainability Rating: ≥ B
```

**Production (Release)**:

```yaml

```
