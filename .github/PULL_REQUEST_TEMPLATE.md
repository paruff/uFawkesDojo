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
- [ ] **Cumulative, spaced retrieval**: module opens with 2–3 recall
      questions from *earlier* modules, not only the current one
- [ ] **Interleaving**: Green+ belt modules mix problem types; White/Yellow
      may block on one tool at a time
- [ ] **Faded worked examples**: White = full, Yellow/Green = partial,
      Brown/Black = open problems
- [ ] **Calibration prompt**: learners predict result/time before lab,
      compare after (counters illusion of competence)
- [ ] **Self-regulation supports**: per-sub-session time estimates, "plan
      your sessions" prompt at belt start, visible progress (done/next)
- [ ] **Corrective loop**: a failed check points each missed item to the
      section that teaches it, then retests with different questions — no
      bare waiting period
- [ ] **Mastery bar**: the module ends with a check at 80% or higher, and
      Success Criteria states that bar up front
- [ ] **Where to next**: every validator failure line names its fix or
      Troubleshooting entry
- [ ] **Diagram**: at least one diagram beside the text it explains, with
      alt text

If any box can't be checked, say why in a comment rather than leaving it
unchecked silently — some modules have a good reason (e.g. a lab genuinely
blocked on infrastructure that doesn't exist yet, tracked in its own issue).

---

## Test plan

<!-- How did you verify this works? Paste real command output where relevant. -->
