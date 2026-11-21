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
- ✅ Read which steps of a generated pipeline run in parallel, and why
- ✅ Measure pipeline performance from the Woodpecker API and UI
- ✅ Use golden path templates for Java, Python, Node.js, and Go applications

---

## Module Structure

| Section       | Time   | Description                                         |
| ------------- | ------ | --------------------------------------------------- |
| Theory        | 20 min | Golden Path concept, uFawkesPipe implementation     |
| Architecture  | 10 min | Pipeline stages, `.fawkespipe.yml` contract         |
| Optimization  | 10 min | Parallel steps and measuring step timings           |
| Templates     | 10 min | Language-specific golden path examples              |
| Lab 01        | 30 min | Write a contract, run the pipeline, measure timings |

---

## Theory Summary (20 minutes)

### What is a Golden Path?

A **Golden Path** is an opinionated template that makes the easy path also the best path — best practices built-in.

### uFawkesPipe Implementation

- **Contract**: `.fawkespipe.yml` defines pipeline behavior
- **Validation**: `scripts/generate_woodpecker_yml.py` validates and generates pipeline
- **Stages**: a contract enables stages (`lint`, `test`, `sast`, `dependency_scan`, `build`, `image_scan`, `dast`, `defectdojo`, `push`, `deploy`, `notify_obs`); each enabled stage becomes one Woodpecker step
- **Templates**: Python, Java, Node.js, Go examples in `examples/`

### Pipeline Steps

The generator emits one step per enabled stage, in this order: `lint`, `test` (after `lint`), `sast`, `dependency-scan`, `build`, `image-scan`, `dast`, `defectdojo`, `push`, `deploy`, `notify-obs`. Steps with no `depends_on` start together, which is where parallelism comes from. `advanced.timeout` becomes a comment only, and `advanced.parallel` is ignored.

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
1. Reading the `python-fawkes-path` and `java-fawkes-path` golden-path contracts
2. Writing a `.fawkespipe.yml` for a scaffolded Python Flask app and generating its `.woodpecker.yml`
3. Pushing to GitHub and activating the repo in Woodpecker
4. Running the pipeline and seeing which steps run in parallel
5. Reading per-step timings from the Woodpecker API and comparing repeat runs

**Runs against**: uFawkesPipe v2.0.0 and uFawkesDevX v1.2.0 (Docker Compose)

**Prerequisites**: Module 5 completed, uFawkesPipe running

**Validation**: `bash yellow-belt/module-06-golden-path/lab-01/validate.sh`

---

## Success Criteria

You have mastered this module when you can:

- Explain the Golden Path concept and how uFawkesPipe implements it
- Create a `.fawkespipe.yml` from a template for any application type
- Configure pipeline stages with language-specific commands
- Read which steps run in parallel and measure step timings
- Use golden path templates for Java, Python, Node.js, and Go

---

## Next Steps

After completing this module, proceed to:

➡️ **Module 07: Security Scanning & Quality Gates**
