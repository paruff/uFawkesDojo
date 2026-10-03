# Module 2: DORA Metrics — Measuring Delivery Performance

**Belt Level**: 🥋 White Belt
**Estimated Time**: 60 minutes (40 min theory + 20 min hands-on lab)
**Prerequisites**: Module 1 completed. No Grafana or DORA experience assumed.
**DORA Capability**: Monitoring and Observability, Continuous Delivery

---

## Theory

Full theory content — the Four (now Five) Key Metrics, performance levels,
the business case, and common misconceptions — lives in
[`modules/white-belt/module-02-dora-metrics.md`](../../modules/white-belt/module-02-dora-metrics.md).
Read that first; this page is the lab launcher.

## Module Structure

| Section | Time   | Description                                                |
| ------- | ------ | ------------------------------------------------------------ |
| Theory  | 40 min | The DORA key metrics, performance levels, business case      |
| Lab 01  | 20 min | Watch real DORA metrics move live in Grafana (uFawkesObs)    |
| Lab 02  | 25 min | Trace delivery events from a real pipeline (uFawkesAI)       |

---

## Lab

➡️ **[Lab 01: See DORA Metrics Live in Grafana](lab-01/instructions.md)**

➡️ **[Lab 02: Trace a Delivery Event from a Real Pipeline](lab-02/instructions.md)**

Unlike Module 1's lab (which runs against the Kubernetes-based `fawkes`
platform), this lab runs against **uFawkesObs** — the Docker Compose
observability plane — because that's where a real, working DORA pipeline
already exists today. You'll start the stack, send one real deployment
event, and watch the Deployment Frequency panel move within about a
minute. No Kubernetes required.

**Validation**: `bash lab-01/validate.sh` (run from inside your local
`uFawkesObs` checkout — see the lab for the exact path)

---

## Success Criteria

You have mastered this module when you can:

- Explain each DORA key metric to a non-technical colleague in one sentence
- Look at the `dora-overview` and `dora-metrics` Grafana dashboards and say
  what each panel means
- Explain what a "deployment event" is and how it reaches a dashboard
- Say what changed in the DORA model in 2025 (four keys → five)

---

## Next Steps

After completing this module, proceed to:

➡️ **Module 3: GitOps Principles**

For the deep-dive version of this material (metric correlation, building a
collector from scratch, benchmarking, presenting to leadership), see
**Brown Belt Module 14: DORA Metrics Deep Dive** once you've completed the
Green Belt modules.
