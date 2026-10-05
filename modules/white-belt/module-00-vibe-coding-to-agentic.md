# Module 0: From Vibe Coding to Agentic Engineering

**Belt Level**: 🥋 White Belt
**Duration**: 10 minutes (theory) + Start-here lab
**Prerequisites**: None — this is the entry point
**DORA Capabilities**: AI Capability 1 — Clear and communicated AI stance

---

## 1. Learning Objectives (2 minutes)

### What You'll Learn

By the end of this primer, you will be able to:

- ✅ Distinguish **vibe coding** from **agentic engineering**
- ✅ Explain why vibe coding doesn't scale for team delivery
- ✅ Name the six maturity stages from the AI-Native SDLC Playbook
- ✅ Identify where the uFawkes suite fits in that maturity model
- ✅ Know your first step: the "Start here" lab on uFawkesAI `v2.0.0`

### Why It Matters

**The Problem**: Most developers start with *vibe coding* — prompt, accept, move on. No verification, no shared standards, no measurement. This works for prototypes. It **fails for team delivery**:
- Inconsistent AI use → unreviewable PRs, hidden quality variance
- No guardrails → security issues, technical debt, test gaps
- "It works" replaces "it's correct" → incidents from AI-introduced bugs
- No feedback loop → can't justify tooling cost or improve usage

**The Solution**: *Agentic engineering* treats AI as a capability to be engineered:
- Structured workflows (intent → spec → plan → execute → verify)
- Explicit guardrails (policy-as-code, automated checks, human gates)
- Measurable outcomes (DORA metrics track whether AI improves delivery)
- Observable agent behavior (telemetry on what agents do, decide, produce)
- Continuous improvement (eval-driven prompt/rule refinement)

### Success Criteria

You've mastered this primer when you can:
- Explain the difference between vibe coding and agentic engineering to a colleague
- Name the six maturity stages and identify where your team sits today
- Articulate why platform teams must build the platform that makes AI safe for the org
- Start the "Start here" lab with confidence

---

## 2. Theory & Concepts (8 minutes)

### The Paper: AI-Native SDLC Playbook

This primer cites **[The AI-Native SDLC Playbook](https://claude.com/blog/the-ai-native-sdlc-playbook)** (Claxton, Anthropic, 2026-08-21).

> "Without both tests and evals, it's still vibe coding." — *AI-Native SDLC Playbook*

The playbook defines **six stages of maturity**:

| Stage | Focus | Key Practice | Where uFawkes Starts |
|-------|-------|--------------|----------------------|
| 1. **Ad-hoc** | Individual experimentation | Copilot, chat UI | ❌ Before uFawkes |
| 2. **Assisted** | Personal productivity | Prompt libraries, snippets | ❌ Before uFawkes |
| 3. **Automated** | Team workflows | Templates, CI integration | ✅ **uFawkesAI baseline** |
| 4. **Orchestrated** | Cross-cutting orchestration | Multi-agent pipelines, policy gates | ✅ uFawkesPipe + uFawkesObs |
| 5. **Governed** | Compliance & safety | Audit trails, approval gates | 🔜 fawkes (K8s) |
| 6. **Self-improving** | Continuous optimization | Eval-driven prompt/rule refinement | 🔜 fawkes (evals) |

> **Key insight**: Most teams are at Stage 1–2. The uFawkes suite targets **Stage 3–4** as the starting baseline for platform teams.

### Vibe Coding vs. Agentic Engineering: The Platform View

Platform engineers don't just *use* AI — they build the **platform that makes AI safe and effective for the whole organization**.

| Platform Responsibility | Vibe Coding Approach | Agentic Engineering Approach |
|-------------------------|----------------------|------------------------------|
| **CI/CD pipelines** | Manual AI-generated YAML | Golden-path templates with policy checks |
| **Code review** | Human reads AI output | Automated rule evaluation + human review |
| **Testing** | "AI wrote tests, good enough" | Mutation testing, contract tests, eval suites |
| **Observability** | None | Agent telemetry, DORA metrics, eval dashboards |
| **Security** | Post-hoc scanning | Shift-left policy-as-code (Rego/OPA) |
| **Onboarding** | "Figure it out" | Runnable "Start here" lab with validation |

### The uFawkes Suite: Built for Agentic Engineering

| Stack | Role in Agentic Engineering |
|-------|------------------------------|
| **uFawkesAI** | Template + devcontainer + agent harnesses (the "Start here" lab runs here) |
| **uFawkesObs** | Observability plane: metrics, logs, traces, DORA dashboards for AI workflows |
| **uFawkesPipe** | CI/CD + policy plane: Woodpecker, Conftest/Rego, DefectDojo, golden paths |
| **uFawkesDevX** | Developer experience: Backstage catalog, Coder workspaces, Cookiecutter golden paths |
| **fawkes** | Kubernetes-native graduation target (Tekton, ArgoCD, CloudNativePG) |

---

## 3. Your First Step: The "Start Here" Lab

The Dojo's entry-point lab (built on **uFawkesAI `v2.0.0`**) walks you through one complete **intent → spec → plan → execute → verify** cycle:

1. **Generate a repo** from the uFawkesAI template (pinned to `v2.0.0`)
2. **Open the devcontainer** — all tooling pre-installed (Claude Code, OpenCode, pre-commit, evals)
3. **Write an intent** for a small change
4. **Produce a spec** with acceptance criteria
5. **Create a plan** the planner accepts
6. **Execute** and run `make validate`
7. **Verify** the eval passes against `baseline.json`

> This is **agentic engineering in miniature**: structured, verified, measurable.

---

## 4. Retrieval Check (1 minute)

Answer without looking back:

1. What is the fundamental difference between vibe coding and agentic engineering?
2. Name the six maturity stages from the AI-Native SDLC Playbook.
3. Which stages does uFawkes target as its starting baseline?
4. What is the platform engineer's role in the shift to agentic engineering?

*(Suggested answers: 1 = vibe coding = ad-hoc, no verification; agentic engineering = structured workflows, guardrails, measurement. 2 = Ad-hoc, Assisted, Automated, Orchestrated, Governed, Self-improving. 3 = Stages 3–4 (Automated, Orchestrated). 4 = Build the platform that makes AI safe/effective for the org — golden paths, policy-as-code, observability.)*

---

## 5. Key Takeaways

1. **Vibe coding is Stage 1** — necessary for learning, insufficient for delivery
2. **Agentic engineering is Stages 3–4+** — structured workflows, guardrails, measurement
3. **The platform enables the shift** — golden paths, policy-as-code, observability
4. **DORA metrics are the scoreboard** — if AI doesn't move them, it's not working
5. **Start with the lab** — the "Start here" lab is your first calibrated step

---

## 6. Continue Learning

- **Next module**: [Module 1 — What is an Internal Delivery Platform?](../white-belt/module-01-what-is-idp.md) — the platform that makes agentic engineering possible
- **Next guide**: [DORA Primer](https://ufawkes.dev/learn/dora-primer.html) — the five metrics that measure whether agentic engineering works
- **Hands-on**: Run the [Dojo "Start here" lab](https://dojo.ufawkes.dev/lesson.html?src=white-belt/module-01-what-is-idp/lab-01/instructions.md) (published with Dojo 0.2)
- **Reference**: [The AI-Native SDLC Playbook](https://claude.com/blog/the-ai-native-sdlc-playbook) (Claxton, Anthropic, 2026-08-21)

---

## Module Footer

**Version**: 0.1.0 | **Last Updated**: 2026-10-05 | **Part of Dojo 0.2 release**
**Upstream citation**: Claxton, *The AI-Native SDLC Playbook*, Anthropic, 2026-08-21
**License**: CC-BY-4.0 — share and adapt with attribution
