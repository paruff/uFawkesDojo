# Module 6: Golden Path Pipelines with uFawkesPipe

**Belt Level**: 🟡 Yellow Belt
**Estimated Time**: 60 minutes (20 min theory + 10 min architecture + 10 min optimization + 10 min templates + 10 min lab)
**Prerequisites**: Module 5 completed, uFawkesPipe v2.0.0 running
**DORA Capability**: Continuous Integration (CD3, CD4), Deployment Pipeline

---

## Learning Objectives

By the end of this module, you will be able to:

- ✅ Understand the "Golden Path" concept and how uFawkesPipe implements it via `.fawkespipe.yml` templates
- ✅ Create and customize `.fawkespipe.yml` pipeline contracts for different application types
- ✅ Configure pipeline stages (lint, test, security, build) with language-specific commands
- ✅ Implement pipeline optimization: parallel execution, build caching, incremental builds
- ✅ Configure resource optimization and build time measurement
- ✅ Measure and improve pipeline performance using Woodpecker UI and metrics
- ✅ Use golden path templates for Java, Python, Node.js, and Go applications

---

## Module Structure

| Section       | Time   | Description                                         |
| ------------- | ------ | --------------------------------------------------- |
| Theory        | 20 min | Golden Path concept, uFawkesPipe implementation     |
| Architecture  | 10 min | Pipeline stages, `.fawkespipe.yml` contract         |
| Optimization  | 10 min | Parallel execution, caching, resource tuning        |
| Templates     | 10 min | Language-specific golden path examples              |
| Lab 01        | 10 min | Create optimized pipeline, measure performance      |

---

## Theory Summary (20 minutes)

### What is a Golden Path?

A **Golden Path** is an opinionated template that makes the easy path also the best path — best practices built-in.

### uFawkesPipe Implementation

- **Contract**: `.fawkespipe.yml` defines pipeline behavior
- **Validation**: `scripts/generate_woodpecker_yml.py` validates and generates pipeline
- **Standard Stages**: validate → test → security → build → publish → deploy
- **Templates**: Python, Java, Node.js, Go examples in `examples/`

### Pipeline Stages

| # | Stage | Steps |
|---|-------|-------|
| 1 | **validate** | `init` → `lint-yaml` + `lint-shell` |
| 2 | **test** | `unit-tests` + `integration-tests` + `contract-tests` |
| 3 | **security** | `secrets-scan` → `vuln-scan-fs` → `vuln-scan-image` |
| 4 | **build** | `build-image` (CNB) |
| 5 | **publish** | `upload-defectdojo` |
| 6 | **deploy** | `notify-obs` |

### Golden Path Templates

| Template | Language | Framework |
|----------|----------|-----------|
| `.fawkespipe-python-flask.yml` | Python 3.11 | Flask |
| `.fawkespipe-java-maven.yml` | Java 17 | Spring Boot |
| `.fawkespipe-nodejs-express.yml` | Node.js 20 | Express |
| `.fawkespipe-go.yml` | Go 1.22 | net/http |

---

## Lab

➡️ **[Lab 01: Build Your Golden Path Pipeline](lab-01/instructions.md)**

This lab walks you through:
1. Exploring uFawkesPipe's built-in golden path templates
2. Customizing a template for a Python Flask application
3. Configuring pipeline optimization (parallel, caching, resources)
4. Pushing to Git, watching pipeline execute in Woodpecker
6. Measuring and improving build performance

**Runs against**: uFawkesPipe v2.0.0 (not released yet) (Docker Compose)

> **Written ahead of its stack, not yet run for real.** uFawkesPipe v2.0.0 has not been released, so no one has run every step of this lab against it. Treat the steps and the expected output as unverified. See the [audit](../../docs/ai-sdlc/compose-curriculum/audit-2026-10-06.md).

**Prerequisites**: Module 5 completed, uFawkesPipe running

**Validation**: `bash yellow-belt/module-06-golden-path/lab-01/validate.sh`

---

## Success Criteria

You have mastered this module when you can:

- Explain the Golden Path concept and how uFawkesPipe implements it
- Create a `.fawkespipe.yml` from a template for any application type
- Configure pipeline stages with language-specific commands
- Implement optimization: parallel stages, caching, resource tuning
- Measure and improve pipeline performance using Woodpecker UI and metrics
- Use golden path templates for Java, Python, Node.js, and Go

---

## Next Steps

After completing this module, proceed to:

➡️ **Module 07: Security Scanning & Quality Gates**
