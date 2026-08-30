## What does this PR do?

<!-- 1-3 sentence summary -->

---

## If this PR adds or substantially revises a module or lab

Check against [`docs/module-authoring-guide.md`](../docs/module-authoring-guide.md)
before requesting review:

- [ ] **Every lab step in this PR was run for real**, against real
      infrastructure, and the output shown is actual output (not a
      description of what an environment "will provision")
- [ ] Learners see a worked example before being asked to build their own
- [ ] Theory-before-practice blocks are short (~5-10 min), not front-loaded
- [ ] The module teaches only what's needed for its task, not a full
      feature tour
- [ ] At least one open-response retrieval question (not just
      multiple-choice recognition)
- [ ] If the module runs >90 minutes, it has an explicit spacing/stopping
      point
- [ ] Feedback in the lab is immediate and real today (script exit code,
      dashboard change, HTTP response) — not "will be auto-graded" for a
      grader that doesn't exist yet
- [ ] Currency check done: tool names, metric definitions, contact info,
      and any "Last Updated" footer are current (see
      [issue #11](https://github.com/paruff/uFawkesDojo/issues/11) for
      known in-flight changes: Jenkins → Tekton, `fawkes.io` → `ufawkes.dev`)

If any box can't be checked, say why in a comment rather than leaving it
unchecked silently — some modules have a good reason (e.g. a lab genuinely
blocked on infrastructure that doesn't exist yet, tracked in its own issue).

---

## Test plan

<!-- How did you verify this works? Paste real command output where relevant. -->
