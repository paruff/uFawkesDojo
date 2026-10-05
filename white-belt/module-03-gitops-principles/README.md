# Module 3: GitOps Principles with uFawkesDevX

**Belt Level**: 🥋 White Belt
**Estimated Time**: 60 minutes (20 min theory + 10 min architecture + 10 min DORA + 15 min lab + 5 min quiz)
**Prerequisites**: Module 1 & 2 completed, Docker basics, uFawkesDevX v1.0.1 running
**DORA Capability**: Continuous Delivery, Deployment Pipeline

---

## Learning Objectives

By the end of this module, you will be able to:

- ✅ Define GitOps and explain its four core principles (Declarative, Versioned, Pulled, Reconciled)
- ✅ Differentiate between push-based and pull-based deployment models
- ✅ Explain how the Score service provides GitOps-like workload validation and pipeline triggering
- ✅ Describe how Backstage catalog serves as the source of truth for services
- ✅ Understand how uFawkesDevX implements GitOps principles without Kubernetes/ArgoCD
- ✅ Make a GitOps-driven service change using the Score API and Backstage Scaffolder
- ✅ Perform a rollback by reverting a Score workload spec

---

## Module Structure

| Section       | Time   | Description                                            |
| ------------- | ------ | ------------------------------------------------------ |
| Theory        | 20 min | GitOps principles, push vs pull, uFawkesDevX mapping  |
| Architecture  | 10 min | Score service, Backstage catalog, golden paths        |
| DORA Metrics  | 10 min | How GitOps improves all five DORA metrics             |
| Lab 01        | 15 min | Score API registration, Scaffolder, rollback practice |
| Quiz          | 5 min  | 10-question knowledge check                           |

---

## Theory Summary (20 minutes)

### What is GitOps?

**GitOps** is a paradigm where the desired state of your system is declared in Git, and automated agents continuously ensure the actual state matches that declaration.

**Traditional (Imperative)**:
```bash
kubectl apply -f deployment.yaml
kubectl set image deployment/myapp myapp=v2.0
```

**GitOps (Declarative)**:
```yaml
# In Git: score.yaml
apiVersion: score.dev/v1b1
metadata:
  name: my-service
containers:
  my-service:
    image: ghcr.io/myorg/my-service:v2.0
```

### Four Principles of GitOps

| Principle | uFawkesDevX Implementation |
|-----------|---------------------------|
| **Declarative** | Score spec (`score.yaml`) declares WHAT, not HOW |
| **Versioned & Immutable** | Specs in Git + Backstage catalog with full history |
| **Pulled Automatically** | Score Service pulls/validates specs, triggers pipeline |
| **Continuously Reconciled** | Score monitors drift, reports OutOfSync in Backstage |

### uFawkesDevX GitOps Architecture

```
Git Repository (score.yaml)
         ↑
         │ Submit spec
         │
    Score Service (Validator + Trigger)
         │
         ├─→ Validates against score.dev/v1b1
         ├─→ Triggers uFawkesPipe webhook
         └─→ Updates Backstage Catalog
         │
         ▼
    uFawkesPipe (Build → Test → Deploy)
         │
         ▼
    Deployed Service
         │
         ▼
    Backstage Catalog ← Source of Truth
```

---

## Lab

➡️ **[Lab 01: GitOps Workflow with Score Service](lab-01/instructions.md)**

This lab walks you through:
1. Exploring the Backstage catalog (source of truth)
2. Registering a new service via Score API
3. Creating a service using Backstage Scaffolder
4. Observing the GitOps-like workflow
5. Practicing rollback via spec revert

**Runs against**: [uFawkesDevX v1.0.1](https://github.com/paruff/uFawkesDevX/releases/tag/v1.0.1) (Docker Compose)

**Prerequisites**: Module 1 lab completed (uFawkesDevX running)

**Validation**: `bash white-belt/module-03-gitops-principles/lab-01/validate.sh`

---

## Success Criteria

You have mastered this module when you can:

- Explain the four GitOps principles and how uFawkesDevX implements each
- Navigate the Backstage catalog and identify the source of truth
- Register a service via Score API and verify it in Backstage
- Use Scaffolder to create a service and observe pipeline trigger
- Perform a rollback by reverting a score.yaml and re-submitting

---

## Next Steps

After completing this module, proceed to:

➡️ **Module 04: Your First Deployment — End-to-End**
