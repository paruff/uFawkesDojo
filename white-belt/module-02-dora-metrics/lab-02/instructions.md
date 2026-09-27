# Lab 02: Trace a Delivery Event from a Real Pipeline

**Module**: White Belt — Module 2: DORA Metrics
**Estimated Time**: 25 minutes
**Difficulty**: Beginner (Lab 01 recommended, not required)
**Runs against**: [uFawkesAI](https://github.com/paruff/uFawkesAI) (a git checkout and its public CI runs) — no Docker, no Kubernetes

**Source:** uFawkesAI `docs/ai-sdlc/dora-events/` @ `09886a8`
(exercise = plan.md › Verification Strategy; rubric = spec.md › Acceptance Criteria —
see uFawkesAI [`docs/ai-sdlc/dojo-handoff.md`](https://github.com/paruff/uFawkesAI/blob/main/docs/ai-sdlc/dojo-handoff.md))

---

## Why this lab exists

In Lab 01 you sent a deployment event to uFawkesDORA by hand with `curl`.
Real pipelines don't do that by hand. uFawkesAI's CI emits **delivery
events** on every successful run, and those events carry two things a hand-made
event can't: how many **AI agent tokens** went into the change, and the PR's
**cycle time** (first commit → merge). This lab has you trace those events
from a real, public pipeline run back to the code that produced them.

## Objectives

By the end of this lab you will have:

1. Proven the event emitter's behaviour with its own test suite (event shape,
   token/cycle-time maths, schema validity, OTLP export)
2. Downloaded the delivery events a real uFawkesAI pipeline run produced
3. Emitted your own `job-finish` event for a real merged PR
4. Explained where `agent_tokens` and `cycle_time_seconds` come from

## Prerequisites

**Tools required**: `git`, `bash`, `jq`, the GitHub CLI `gh` (logged in —
check with `gh auth status`), and a `python3` that has the `jsonschema`
module.

```bash
# Is jsonschema available? (prints a version, or an error)
python3 -c 'import importlib.metadata as m; print(m.version("jsonschema"))'
```

If that errors, install it into a private environment. With
[uv](https://docs.astral.sh/uv/) (no pip or venv package needed):

```bash
uv venv ~/.venvs/dojo && uv pip install --python ~/.venvs/dojo jsonschema
export PYTHON=~/.venvs/dojo/bin/python   # use this Python for the rest of the lab
```

Watch out on Debian/Ubuntu: plain `pip install jsonschema` fails when the
system Python has no pip, and `python3 -m venv` fails until the
`python3-venv` package is installed ("ensurepip is not available").

```bash
export LAB_DIR=~/dojo-delivery-events
mkdir -p "$LAB_DIR" && cd "$LAB_DIR"
git clone https://github.com/paruff/uFawkesAI.git
cd uFawkesAI
```

---

## Step 0 — Worked example: read the chain first (5 minutes)

Everything in this lab was specified before it was built. Skim, in order:

1. `docs/ai-sdlc/dora-events/intent.md` — why delivery events exist
2. `docs/ai-sdlc/dora-events/spec.md` — its five **Acceptance Criteria**
   (AC-01…AC-05). These are this lab's grading rubric.
3. `docs/ai-sdlc/dora-events/plan.md` — its **Verification Strategy**
   table. Each row is one step below.

## Step 1 — AC-01 to AC-04: run the emitter's own proof (5 minutes)

The plan proves AC-01 to AC-04 with one test script. Run it:

```bash
PYTHON="${PYTHON:-python3}" bash scripts/test-emit-dora-event.sh
```

You should see four sections and a final line like:

```
== Event shape (dora-log.sh fields) ==
  ✅ job-start: one line of JSON
  ...
== deploy-marker dora_event vs uFawkesObs deployment-event.schema.json ==
  ✅ dora_event is a valid uFawkesDORA deployment event
  ✅ dora_event carries cycle-time inputs and AI flag
== OTLP/HTTP export to /v1/logs ==
  ✅ POSTed to /v1/logs with custom header
  ...
ALL 21 CHECKS PASSED
```

If instead you see `FAIL: python3 has no jsonschema module`, go back to the
Prerequisites.

> **Retrieval question:** the test serves GitHub API answers from a fake
> `gh`. Why is that better than calling the real API in a test — and what
> does it *not* prove?

## Step 2 — AC-05: download a real pipeline's events (5 minutes)

Every successful uFawkesAI CI run uploads its events as an artifact named
`dora-events`. Download the one from the run that shipped this feature
to `main`:

```bash
gh run download 36314948159 -R paruff/uFawkesAI -n dora-events -D "$LAB_DIR/artifact"
jq -c '{event, status, tokens: .agent_tokens.output, cycle: .pr.cycle_time_seconds}' \
  "$LAB_DIR/artifact/dora-events.jsonl"
```

Actual output from that run:

```
{"event":"job-start","status":null,"tokens":null,"cycle":null}
{"event":"job-finish","status":"success","tokens":44415,"cycle":257}
{"event":"deploy-marker","status":"success","tokens":44415,"cycle":257}
```

Three events: the pipeline started, it finished (with delivery metadata),
and — because this was a push to `main` — a **deploy-marker**. Look at
the deploy-marker's `dora_event`:

```bash
jq '.dora_event' <(grep deploy-marker "$LAB_DIR/artifact/dora-events.jsonl")
```

That object is exactly what Lab 01 had you `curl` by hand — here the
pipeline built it, including `first_commit_at` and `pr_merged_at`.

> **Retrieval question:** `tokens` is 44415 in both `job-finish` and
> `deploy-marker`. Where in the git history did that number come from?
> (Hint: `git log -1 --format=%B 0a5735d`.)

## Step 3 — Emit your own event for a real PR (5 minutes)

The same script runs outside CI. Point it at a merged PR and write the
event to a file:

```bash
export GITHUB_REPOSITORY=paruff/uFawkesAI   # outside CI the script can't infer this
DORA_EVENTS_FILE="$LAB_DIR/my-events.jsonl" \
  bash scripts/emit-dora-event.sh job-finish --step my-run --pr 84 \
  | jq -c '{event, repo, pr: .pr.number, cycle: .pr.cycle_time_seconds, tokens: .agent_tokens.output}'
```

Actual output:

```
{"event":"job-finish","repo":"paruff/uFawkesAI","pr":84,"cycle":257,"tokens":44415}
```

Now try it **without** `GITHUB_REPOSITORY` and compare the `repo` and `pr`
fields. Keep your successful event in `my-events.jsonl` — the grader reads it.

> **Retrieval question:** what does `cycle_time_seconds` measure for a PR
> that isn't merged yet?

## Step 4 — Grade yourself (1 minute)

From your uFawkesAI checkout:

```bash
bash /path/to/uFawkesDojo/white-belt/module-02-dora-metrics/lab-02/validate.sh
```

It runs one check per acceptance criterion (AC-01…AC-05) and exits 0 only
if all pass.

---

## What you learned

- A delivery event is one JSON line; the same line reaches Loki (via
  uFawkesObs) and carries a uFawkesDORA deployment event inside it.
- Agent token usage is **committed** (an `Agent-Tokens:` footer), which is
  why CI can see it.
- Cycle time is computed, not reported: first commit → merge, from the PR.

## Found a problem?

This lab was generated from a uFawkesAI feature. If you got stuck, that is
feedback about the feature, not just the lab — tell your facilitator; it
becomes a `dojo-feedback.md` in uFawkesAI and, from there, the next
`intent.md`.
