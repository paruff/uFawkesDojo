# Module 6: Golden Path Pipelines with uFawkesPipe

**Belt Level**: 🟡 Yellow Belt
**Duration**: 60 minutes
**Prerequisites**: Module 5 (CI Fundamentals) complete, uFawkesPipe v2.0.0 running
**DORA Capabilities**: Continuous Integration (CD3, CD4), Deployment Pipeline

---

## 1. Learning Objectives (3 minutes)

### What You'll Learn

By the end of this module, you will be able to:

- ✅ Understand the "Golden Path" concept and how uFawkesPipe implements it via `.fawkespipe.yml` templates
- ✅ Create and customize `.fawkespipe.yml` pipeline contracts for different application types
- ✅ Configure pipeline stages (lint, test, security, build) with language-specific commands
- ✅ Implement pipeline optimization: parallel execution, build caching, incremental builds
- ✅ Configure resource optimization and build time measurement
- ✅ Measure and improve pipeline performance using Woodpecker UI and metrics
- ✅ Use golden path templates for Java, Python, Node.js, and Go applications

### Why It Matters

**The Problem: Pipeline Proliferation**

Without Golden Paths:

```
Team A: Creates Python pipeline (50 lines)
Team B: Creates Python pipeline (48 lines, slightly different)
Team C: Creates Python pipeline (52 lines, more differences)
Team D: Creates Java pipeline from scratch
Team E: Copies Team A's pipeline, modifies it

Result:
- 50 similar but different pipeline configs
- Security update needed → Update 50 pipelines manually
- New best practice → Adoption takes months
- No consistency across teams
- High maintenance burden
```

**The Golden Path Solution**

> **"The easiest path should also be the best path"**

```
Golden Path Template (Python)
      ↓
Maintained by Platform Team
      ↓
Used by 50 teams
      ↓
Update once → All teams benefit
      ↓
Consistency + Best Practices Built-In
```

**Golden Path Characteristics in uFawkesPipe**:

1. **Opinionated**: Embeds best practices by default via `.fawkespipe.yml`
2. **Easy to Use**: 10-20 lines to get started with a template
3. **Batteries Included**: Security, testing, quality gates built-in
4. **Customizable**: Escape hatches for edge cases via `advanced` config
5. **Self-Service**: Teams use templates without platform team help
6. **Maintained**: Platform team keeps templates updated

### Success Criteria

You've mastered this module when you can:

- Explain the Golden Path concept and how uFawkesPipe implements it
- Create a `.fawkespipe.yml` from a template for any application type
- Configure pipeline stages with language-specific commands
- Implement optimization: parallel stages, caching, resource tuning
- Measure and improve pipeline performance
- Use golden path templates for Java, Python, Node.js, and Go

---

## 2. Theory & Concepts (20 minutes)

### 📺 Video: Golden Paths in uFawkesPipe (8 minutes) — *not produced yet*

> **[VIDEO PLACEHOLDER]** > **Script Summary** *(video not produced)*:
>
> - Opening: Show the problem with pipeline proliferation (50 different configs)
> - Golden Path definition: Opinionated templates with best practices built-in
> - uFawkesPipe tour: `.fawkespipe.yml` contract, templates, Woodpecker stages
> - Demo: Create `.fawkespipe.yml` from template → customize → pipeline runs
> - Show optimization: parallel stages, caching, resource tuning
> - Closing: "From 200-line Jenkinsfile to 20-line contract"

### What is a Golden Path in uFawkesPipe?

A **Golden Path** in uFawkesPipe is a pre-configured `.fawkespipe.yml` template that embeds platform best practices. Teams customize a template instead of writing pipeline configuration from scratch.

**Traditional (Write from Scratch)**:

```yaml
# 100+ lines of Woodpecker pipeline YAML
steps:
  - name: lint-yaml
    image: alpine:3.20
    commands:
      - yamllint .
  - name: lint-shell
    image: alpine:3.20
    commands:
      - shellcheck scripts/*.sh
  - name: unit-tests
    image: python:3.11
    commands:
      - pytest tests/
  # ... 50 more lines
```

**Golden Path (Use Template)**:

```yaml
# 20 lines - customize and go!
app:
  name: my-app
  type: service
  language: python
  version: 1.0.0

build:
  builder: cnb
  cnb:
    builder: paketobuildpacks/builder:base
  image:
    registry: docker.io
    namespace: myorg
    name: my-app
    tags: ["${GIT_COMMIT_SHORT}", "latest"]

stages:
  lint:
    enabled: true
    commands:
      - language: python
        cmd: ruff check src/ && black --check src/

  test:
    enabled: true
    commands:
      - language: python
        cmd: pytest tests/ --cov=src --cov-report=xml
    coverage:
      threshold: 75

  sast:
    enabled: true
    sonarqube:
      qualityGate: true
    trivy:
      enabled: true

  dependency_scan:
    enabled: true
    tools: [trivy]
    fail_on: HIGH

  build:
    enabled: true

  image_scan:
    enabled: true
    severity: CRITICAL
    fail_on: CRITICAL

  push:
    enabled: true

advanced:
  timeout: 30
  parallel:
    enabled: true
  artifacts:
    retention: 30
```

**Result**: 90% less boilerplate, 100% best practices

### How uFawkesPipe Implements Golden Paths

uFawkesPipe provides Golden Paths through:

1. **Template Repository**: Pre-built `.fawkespipe.yml` examples in `examples/`
2. **Contract Validation**: `scripts/generate_woodpecker_yml.py` validates and generates pipeline
3. **Standard Stages**: All templates use the same stage structure
4. **Language Detection**: Templates for Python, Java, Node.js, Go
5. **Extensibility**: `advanced` section for customization without forking

---

## 3. uFawkesPipe Pipeline Architecture (10 minutes)

### Standard Pipeline Stages

Every pipeline in uFawkesPipe follows standardized stages (from `.fawkespipe.yml`):

| # | Stage | Steps | Parallel | Branch Gate |
|---|-------|-------|----------|-------------|
| 1 | **validate** | `init` → `lint-yaml` + `lint-shell` | Yes (lint) | None |
| 2 | **test** | `unit-tests` + `integration-tests` + `contract-tests` | Yes | None |
| 3 | **security** | `secrets-scan` → `vuln-scan-fs` → `vuln-scan-image` | Sequential | `vuln-scan-image`: main only |
| 4 | **build** | `build-image` | — | main only |
| 5 | **publish** | `upload-defectdojo` | — | main only |
| 6 | **deploy** | `notify-obs` | — | main only |

### The `.fawkespipe.yml` Contract

Applications define their pipeline behavior via `.fawkespipe.yml` at the repo root:

```yaml
app:
  name: my-app
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
    name: my-app
    tags: ["${GIT_COMMIT_SHORT}", "latest"]

stages:
  lint:
    enabled: true
    commands:
      - language: python
        cmd: ruff check src/ && black --check src/

  test:
    enabled: true
    commands:
      - language: python
        cmd: pytest tests/ --cov=src --cov-report=xml
    coverage:
      enabled: true
      threshold: 75

  sast:
    enabled: true
    sonarqube:
      enabled: true
      qualityGate: true
    trivy:
      enabled: true

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

  push:
    enabled: true

advanced:
  timeout: 30
  parallel:
    enabled: true
  artifacts:
    retention: 30
  workspace:
    cleanup: true
```

The `scripts/generate_woodpecker_yml.py` script translates `.fawkespipe.yml` into Woodpecker's native `.woodpecker.yml`.

### Golden Path Templates

uFawkesPipe provides Golden Paths through templates in `examples/`:

| Template | Language | Framework |
|----------|----------|-----------|
| `.fawkespipe-python-flask.yml` | Python 3.11 | Flask |
| `.fawkespipe-java-maven.yml` | Java 17 | Spring Boot |
| `.fawkespipe-nodejs-express.yml` | Node.js 20 | Express |
| `.fawkespipe-go.yml` | Go 1.22 | net/http |

Each template includes:
- **App metadata** (name, type, language, version)
- **Build config** (CNB builder, image registry, tags)
- **Standard stages** (lint, test, sast, dependency_scan, build, image_scan, push)
- **Language-specific commands** for each stage
- **Optimization config** (parallel, caching, timeout)

---

## 4. Pipeline Optimization in uFawkesPipe (10 minutes)

### Technique 1: Parallel Execution

Run independent stages simultaneously:

```yaml
advanced:
  parallel:
    enabled: true
```

This enables parallel execution for stages that support it (lint steps, test steps).

**Example - Parallel Linting**:

```yaml
stages:
  lint:
    enabled: true
    commands:
      - language: python
        cmd: ruff check src/
      - language: python
        cmd: black --check src/
      - language: dockerfile
        cmd: hadolint Dockerfile
```

**Before**: 3 minutes (sequential)
**After**: 1 minute (parallel)
**Improvement**: 3x faster ⚡

### Technique 2: Build Caching

Cache dependencies between builds using CNB build cache:

```yaml
advanced:
  timeout: 30
  # CNB builder automatically caches layers
  # CNB buildpack layers cached between builds
```

**How it works**:
- CNB builder caches buildpack layers between builds
- Dependencies downloaded once, reused across builds
- Cache invalidated only when lockfiles change

**Before**: 2 minutes downloading dependencies every build
**After**: 10 seconds (cached)
**Improvement**: 12x faster on dependencies ⚡

### Technique 3: Resource Optimization

Right-size your build containers:

```yaml
advanced:
  timeout: 30
  # Resource limits applied to build containers
```

**Resource Profiles**:

```yaml
# Small builds (Python, Node.js)
resources:
  requests:
    memory: "512Mi"
    cpu: "500m"
  limits:
    memory: "1Gi"
    cpu: "1000m"

# Medium builds (Java, Go)
resources:
  requests:
    memory: "2Gi"
    cpu: "1000m"
  limits:
    memory: "4Gi"
    cpu: "2000m"

# Large builds
resources:
  requests:
    memory: "8Gi"
    cpu: "4000m"
  limits:
    memory: "16Gi"
    cpu: "8000m"
```

**Benefit**: Faster scheduling, lower costs, better resource utilization

### Technique 4: Incremental Builds (Advanced)

Configure stages to only run when needed:

```yaml
stages:
  test:
    enabled: true
    commands:
      - language: python
        cmd: pytest tests/ --cov=src --cov-report=xml
    # Only run on code changes (configured in Woodpecker)
```

Woodpecker supports conditional execution via `when` conditions in the generated `.woodpecker.yml`.

---

## 5. Golden Path Templates by Language (10 minutes)

### Python Flask Template

```yaml
# .fawkespipe.yml for Python Flask
app:
  name: flask-api
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
    name: flask-api
    tags:
      - "${GIT_COMMIT_SHORT}"
      - "latest"

stages:
  lint:
    enabled: true
    commands:
      - language: python
        cmd: |
          pip install pylint black flake8
          pylint src/ --fail-under=8.0
          black --check src/
          flake8 src/

  test:
    enabled: true
    commands:
      - language: python
        cmd: |
          pip install pytest pytest-cov
          pytest tests/ --cov=src --cov-report=xml --cov-report=html
    coverage:
      enabled: true
      threshold: 75
      report: coverage.xml

  sast:
    enabled: true
    sonarqube:
      enabled: true
      projectKey: flask-api
      sources: src/
      qualityGate: true
    trivy:
      enabled: true

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

  push:
    enabled: true

advanced:
  timeout: 30
  parallel:
    enabled: true
  workspace:
    cleanup: true
```

### Java Spring Boot Template

```yaml
# .fawkespipe.yml for Java Spring Boot
app:
  name: spring-boot-api
  type: service
  language: java
  version: 1.0.0

build:
  builder: cnb
  cnb:
    builder: paketobuildpacks/builder:base
    env:
      BP_JVM_VERSION: "17"
      BP_MAVEN_BUILD_ARGUMENTS: "-DskipTests=true -Dmaven.javadoc.skip=true"
  image:
    registry: docker.io
    namespace: myorg
    name: spring-boot-api
    tags:
      - "${GIT_COMMIT_SHORT}"
      - "${GIT_BRANCH}"
      - "latest"

stages:
  lint:
    enabled: true
    commands:
      - language: java
        cmd: mvn checkstyle:check
    dockerfile:
      enabled: true

  test:
    enabled: true
    commands:
      - language: java
        cmd: mvn test
    coverage:
      enabled: true
      threshold: 80
      report: target/site/jacoco/jacoco.xml

  sast:
    enabled: true
    sonarqube:
      enabled: true
      projectKey: spring-boot-api
      sources: src/main/java
      exclusions: "**/test/**"
      qualityGate: true

  dependency_scan:
    enabled: true
    tools:
      - owasp-dependency-check
      - trivy
    fail_on: CRITICAL

  build:
    enabled: true

  image_scan:
    enabled: true
    severity: HIGH,CRITICAL
    fail_on: CRITICAL

  push:
    enabled: true

kubernetes:
  enabled: false
  namespace: production
  manifests:
    path: k8s/
    files:
      - deployment.yaml
      - service.yaml

advanced:
  timeout: 45
  workspace:
    cleanup: true
  artifacts:
    paths:
      - target/*.jar
    retention: 30
```

### Node.js Express Template

```yaml
# .fawkespipe.yml for Node.js Express
app:
  name: node-api
  type: service
  language: nodejs
  version: 1.0.0

build:
  builder: cnb
  cnb:
    builder: paketobuildpacks/builder:base
    env:
      BP_NODE_VERSION: "20"
  image:
    registry: docker.io
    namespace: myorg
    name: node-api
    tags:
      - "${GIT_COMMIT_SHORT}"
      - "latest"

stages:
  lint:
    enabled: true
    commands:
      - language: nodejs
        cmd: npm run lint

  test:
    enabled: true
    commands:
      - language: nodejs
        cmd: npm test -- --coverage
    coverage:
      enabled: true
      threshold: 80
      report: coverage/lcov.info

  sast:
    enabled: true
    sonarqube:
      enabled: true
      projectKey: node-api
      sources: src/
      qualityGate: true

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

  push:
    enabled: true

advanced:
  timeout: 30
  parallel:
    enabled: true
```

### Go Template

```yaml
# .fawkespipe.yml for Go HTTP service
app:
  name: go-api
  type: service
  language: go
  version: 1.0.0

build:
  builder: cnb
  cnb:
    builder: paketobuildpacks/builder:base
    env:
      BP_GO_VERSION: "1.22"
  image:
    registry: docker.io
    namespace: myorg
    name: go-api
    tags:
      - "${GIT_COMMIT_SHORT}"
      - "latest"

stages:
  lint:
    enabled: true
    commands:
      - language: go
        cmd: golangci-lint run

  test:
    enabled: true
    commands:
      - language: go
        cmd: go test -v -cover ./...
    coverage:
      enabled: true
      threshold: 75
      report: coverage.xml

  sast:
    enabled: true
    trivy:
      enabled: true

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

  push:
    enabled: true

advanced:
  timeout: 30
  parallel:
    enabled: true
```

---

## 6. Measuring Pipeline Performance (5 minutes)

### Build Time Metrics

Track and visualize build performance in Woodpecker UI and Grafana:

### Key Metrics to Track

```promql
# Average build time
avg(woodpecker_build_duration_seconds{job="my-app"})

# Build success rate
sum(rate(woodpecker_build_result{result="success"}[7d])) /
sum(rate(woodpecker_build_result[7d])) * 100

# Slowest pipeline stages
topk(5, avg(woodpecker_stage_duration_seconds) by (stage))

# Build time trend
rate(woodpecker_build_duration_seconds[1d])

# Cache hit rate (CNB)
rate(cnb_cache_hit_total[5m]) / rate(cnb_cache_request_total[5m])
```

### Woodpecker UI Metrics

In Woodpecker UI, you can view:
- Build duration per stage
- Success/failure rate per repository
- Stage-level timing
- Artifact sizes

---

## 7. Hands-On Lab (20 minutes)

### Lab Overview

You'll use the running uFawkesPipe stack to:
1. Explore built-in golden path templates
2. Create a customized `.fawkespipe.yml` for a Python Flask application
3. Configure pipeline stages with optimization settings
4. Push to Git, activate in Woodpecker, watch pipeline execute
5. Practice optimization: enable parallel, observe build time
6. Practice optimization: observe caching effect

**Time Estimate**: 20 minutes
**Difficulty**: Intermediate (Module 5 complete required)
**Auto-Graded**: Yes
**Points**: 100

### Lab Environment

**Prerequisites**: uFawkesPipe v2.0.0 running locally
- ✅ Woodpecker CI at http://localhost:8000
- ✅ SonarQube at http://localhost:9000
- ✅ Portainer CE at https://localhost:9443

➡️ **[Lab 01: Build Your Golden Path Pipeline](yellow-belt/module-06-golden-path/lab-01/instructions.md)**

This lab walks you through customizing a golden path template, configuring pipeline optimization, and measuring performance.

**Validation**: `bash yellow-belt/module-06-golden-path/lab-01/validate.sh`

---

## 7. Knowledge Check (5 minutes)

### Quiz: Golden Path Pipelines with uFawkesPipe

**Instructions**: Answer all 10 questions. You need 8/10 (80%) to pass. Unlimited attempts allowed.

#### Question 1

**What is a "Golden Path" in uFawkesPipe?**

- [ ] A) The fastest build configuration
- [x] B) An opinionated, easy-to-use template with best practices built-in
- [ ] C) A deployment strategy
- [ ] D) A security scanning tool

**Explanation**: A **Golden Path** is an opinionated template that makes the easy path also the best path — best practices built-in.

---

#### Question 2

**In uFawkesPipe, what file defines the pipeline contract?**

- [ ] A) Jenkinsfile
- [ ] B) .woodpecker.yml
- [x] C) .fawkespipe.yml
- [ ] D) pipeline.yaml

**Explanation**: The **`.fawkespipe.yml`** is the standard pipeline contract. It's translated to `.woodpecker.yml` by `scripts/generate_woodpecker_yml.py`.

---

#### Question 3

**How does uFawkesPipe enable parallel execution?**

- [ ] A) Run all stages in parallel
- [x] B) Set `advanced.parallel.enabled: true` in `.fawkespipe.yml`
- [ ] C) Use Jenkins parallel syntax
- [ ] D) Run multiple pipelines simultaneously

**Explanation**: Setting **`advanced.parallel.enabled: true`** enables parallel execution for compatible stages (lint steps, test steps).

---

#### Question 4

**How does uFawkesPipe cache dependencies between builds?**

- [ ] A) Uses a faster Maven mirror
- [x] B) CNB buildpack layers are cached between builds
- [ ] C) Downloads dependencies manually
- [ ] D) Skips dependency resolution

**Explanation**: **Cloud Native Buildpacks (CNB)** caches buildpack layers between builds. Dependencies downloaded once, reused across builds.

---

#### Question 5

**What does the `advanced.timeout` setting control?**

- [ ] A) Git clone timeout
- [x] B) Pipeline timeout in minutes
- [ ] C) Test timeout
- [ ] D) Docker pull timeout

**Explanation**: **`advanced.timeout`** sets the maximum pipeline runtime in minutes (default: 60).

---

#### Question 6

**Which stage in uFawkesPipe runs security scanning?**

- [ ] A) validate
- [ ] B) test
- [x] C) security
- [ ] D) build

**Explanation**: The **security** stage runs `secrets-scan` (Gitleaks), `vuln-scan-fs` (Trivy filesystem), and `vuln-scan-image` (Trivy image scan).

---

#### Question 7

**How do you customize a Golden Path template for your application?**

- [ ] A) Fork the template repository
- [x] B) Copy template, modify `.fawkespipe.yml` with your app details
- [ ] C) Write a new Jenkins Shared Library
- [ ] D) Create a new Woodpecker plugin

**Explanation**: Copy a template from `examples/`, customize `app`, `build`, `stages`, and `advanced` sections for your application.

---

#### Question 8

**What does `stages.test.coverage.threshold` control?**

- [ ] A) Number of tests to run
- [x] B) Minimum code coverage percentage required
- [ ] C) Test timeout
- [ ] D) Test parallelism

**Explanation**: **`coverage.threshold`** sets the minimum code coverage percentage (e.g., 80%). Pipeline fails if coverage is below threshold.

---

#### Question 9

**Which uFawkesPipe component builds container images?**

- [ ] A) Woodpecker Server
- [ ] B) SonarQube
- [x] C) CNB Builder (Cloud Native Buildpacks)
- [ ] D) Portainer

**Explanation**: **CNB Builder** (Cloud Native Buildpacks) builds OCI-compliant container images without Dockerfiles, using buildpacks.

---

#### Question 10

**How do you measure pipeline performance in uFawkesPipe?**

- [ ] A) Only check Woodpecker UI
- [x] B) Track build duration, success rate, stage timing in Woodpecker UI and Prometheus/Grafana
- [ ] C) Manually time each build
- [ ] D) Only measure total pipeline time

**Explanation**: Track **build duration, success rate, stage timing** in Woodpecker UI, and export metrics to Prometheus/Grafana for visualization.

---

### Quiz Results

**Score: X / 10**

- ✅ **Passed** (8+): Excellent! You understand Golden Paths with uFawkesPipe.
- ❌ **Not Yet** (<8): Review the theory section and try again.

**Incorrect answers?** Each question links back to the relevant section for review.

---

## 8. Reflection & Next Steps (5 minutes)

### What You Learned

✅ **You now know**:
- The Golden Path concept and how uFawkesPipe implements it via `.fawkespipe.yml`
- How to create and customize pipeline contracts for different languages
- How to configure pipeline stages with language-specific commands
- How to implement optimization: parallel execution, build caching, resource tuning
- How to measure and improve pipeline performance

✅ **You can now**:
- Create a `.fawkespipe.yml` from a template for any application
- Configure pipeline stages with language-specific commands
- Implement optimization: parallel stages, caching, resource tuning
- Measure and improve pipeline performance using Woodpecker UI and metrics

### How This Connects to Your Work

**For Developers**:
- You can now set up optimized CI for any project in minutes
- No more "works on my machine" — consistent containerized builds
- Immediate feedback on every commit with fast pipelines

**For Platform Engineers**:
- You understand how to maintain and evolve Golden Path templates
- You can help teams optimize their pipelines
- You see how standardization reduces maintenance burden

**For Leaders**:
- You understand how Golden Paths reduce maintenance by 90%+
- You see how optimization directly improves DORA metrics
- You can articulate the business value of pipeline standardization

### Reflection Questions

1. **What surprised you most about Golden Paths in uFawkesPipe?**
2. **How does your current pipeline configuration compare?**
3. **What optimization would have the biggest impact on your team?**
4. **Who on your team should go through this module?**

### Preview: Module 7

**Next Up: Security Scanning & Quality Gates**

In Module 7, you'll learn:
- Deep dive into SAST with SonarQube
- Dependency scanning with Trivy and OSV-Scanner
- Container image scanning
- DAST with OWASP ZAP
- DefectDojo integration for findings management
- Building security into every pipeline stage

**Time**: 60 minutes
**Prerequisites**: Module 6 complete ✅

---

## Module Completion

### ✅ You've Completed Module 6

**Next Steps**:

1. ✅ Mark this module complete in your Backstage profile
2. 📊 View your progress on the Dojo dashboard
3. 💬 Share your completion in `#dojo-achievements` (optional!)
4. ➡️ **Continue to Module 7** when ready

**Time Investment**: 60 minutes
**Skills Gained**: Golden Path templates, pipeline optimization, performance measurement
**Progress**: 2 of 4 modules toward Yellow Belt (50% complete)

---

**Questions or Issues?**
- 💬 Ask in [GitHub Discussions](https://github.com/paruff/uFawkesDojo/discussions) for `#dojo-yellow-belt`
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
