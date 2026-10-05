# Module 4: Your First Deployment with uFawkesDevX

**Belt Level**: 🥋 White Belt
**Estimated Time**: 60 minutes (15 min theory + 10 min demo + 20 min lab + 5 min quiz + 5 min reflection)
**Prerequisites**: Modules 1, 2, 3 completed, uFawkesDevX v1.0.1 running
**DORA Capability**: Continuous Delivery, Deployment Automation

---

## Learning Objectives

By the end of this module, you will be able to:

- ✅ Create a service using the Backstage Scaffolder and a golden path template
- ✅ Navigate the deployment workflow: Score spec → validation → pipeline trigger → catalog update
- ✅ Monitor deployment progress through Backstage, Score Service, and uFawkesPipe
- ✅ Verify application health and accessibility in Coder workspace
- ✅ Understand how DORA metrics are captured via Score Service + uFawkesPipe
- ✅ Troubleshoot common deployment issues in the uFawkesDevX stack

---

## Module Structure

| Section       | Time   | Description                                            |
| ------------- | ------ | ------------------------------------------------------ |
| Theory        | 15 min | uFawkesDevX deployment workflow, golden paths          |
| Demo          | 10 min | Platform tour (video placeholder)                      |
| Lab 01        | 20 min | Scaffolder → Score API → uFawkesPipe → Coder          |
| Quiz          | 5 min  | 10-question knowledge check                           |
| Reflection    | 5 min  | Connect learnings to your work                        |

---

## Theory Summary (15 minutes)

### The uFawkesDevX Deployment Workflow

```
Scaffolder → Score Spec → Score Service → uFawkesPipe → Coder Workspace
  (Template)   (Git)       (Validate)      (Woodpecker)    (Devcontainer)
```

### Four Stages of Deployment

| Stage | Component | Purpose |
|-------|-----------|---------|
| 1. Create | Backstage Scaffolder | Runs Cookiecutter template, creates Git repo, registers in Backstage |
| 2. Spec | Score Service | Validates score.yaml, stores in catalog, triggers pipeline webhook |
| 3. Build | uFawkesPipe (Woodpecker) | Lint → Test → Build (CNB) → Push → Deploy |
| 4. Develop | Coder | Provisions devcontainer workspace from `.devcontainer/devcontainer.json` |

### Golden Path Templates

| Template | Language | Framework |
|----------|----------|-----------|
| `python-flask-app` | Python 3.12 | Flask |
| `java-spring-app` | Java 21 | Spring Boot |
| `node-express-app` | Node.js 20 | Express |
| `go-http-app` | Go 1.22 | net/http |

Each template includes: `score.yaml`, `.fawkespipe.yml`, `.devcontainer/`, `Dockerfile`, `tests/`, `README.md`

---

## Lab

➡️ **[Lab 01: Your First Deployment with uFawkesDevX](lab-01/instructions.md)**

This lab walks you through:
1. Creating a service from a golden path template via Backstage Scaffolder
2. Submitting the Score spec and watching pipeline execution
3. Opening the service in a Coder workspace
4. Verifying the application health

**Runs against**: [uFawkesDevX v1.0.1](https://github.com/paruff/uFawkesDevX/releases/tag/v1.0.1) (Docker Compose)

**Prerequisites**: Module 1 lab completed (uFawkesDevX running), Module 3 completed

**Validation**: `bash white-belt/module-04-first-deployment/lab-01/validate.sh`

---

## Success Criteria

You have mastered this module when you can:

- Create a service end-to-end using the Scaffolder
- Explain each stage of the uFawkesDevX deployment workflow
- Find and interpret deployment status across Backstage, Score API, and uFawkesPipe
- Identify when a deployment succeeded or failed
- Access your deployed application in a Coder workspace

---

## Next Steps

After completing this module, proceed to:

➡️ **White Belt Assessment** — Deploy 2 additional applications, written exam, troubleshooting scenario
