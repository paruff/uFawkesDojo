# Lab 01: Start Here — Your First Intent → Spec → Plan Cycle

**Module**: White Belt — Module 0: From Vibe Coding to Agentic Engineering
**Estimated Time**: about 45 minutes in two sessions (an estimate: the first image download is about 3 GB and depends on your connection)
**Difficulty**: Beginner (you need `git` and Docker, not Kubernetes)
**Prerequisites**: Read the [Module 0 primer](../../../modules/white-belt/module-00-vibe-coding-to-agentic.md)
**Runs against**: [uFawkesAI `v2.0.0`](https://github.com/paruff/uFawkesAI/releases/tag/v2.0.0) and its sandbox image `ghcr.io/paruff/fawkes-space:2.0.0`.

---

## Before you start (3 minutes)

**Recall** — answer in your own words, without looking back at the primer:

1. What separates vibe coding from agentic engineering?
2. Name three of the six maturity stages.

**Predict** — write down how many minutes you think this lab will take you. You'll compare at the end.

## What this lab does

You will clone a pinned copy of the uFawkesAI template, start its devcontainer (the sandbox your agent works in), find the six parts of an agent harness, and write one intent → spec → plan chain. A script then checks your work.

```
intent.md  →  spec.md  →  plan.md  →  code
 (why)        (what must be true)   (how, and how you will prove it)
```

The diagram shows the three documents you write, left to right. Each answers the question under it and points back at the one before.

**Plan your sessions**: Session A is Steps 1–3 (about 20 minutes). Stop there if you need to and come back tomorrow. Session B is Steps 4–6 (about 25 minutes). Progress: 0 of 6 steps done.

**Tools required**: `git`, `docker`, and the [devcontainer CLI](https://github.com/devcontainers/cli) (`npm install -g @devcontainers/cli`).

---

## Step 1 — Clone the pinned template (3 minutes)

```bash
mkdir -p ~/dojo-labs && cd ~/dojo-labs
export AI_TAG=v2.0.0
git clone -c advice.detachedHead=false --depth 1 --branch "$AI_TAG" \
  https://github.com/paruff/uFawkesAI.git my-first-ai-sdlc
cd my-first-ai-sdlc
```

**Expected output**:

```
Cloning into 'my-first-ai-sdlc'...
```

Make it your own repo, with its own history:

```bash
rm -rf .git
git init -q -b main
git add -A
git commit -q -m "chore: start from uFawkesAI ${AI_TAG}"
git log --oneline
```

**Expected output**: one line, `<hash> chore: start from uFawkesAI v2.0.0`.

**What just happened**: you pinned your starting point to a released tag, not to `main`, so the next person who runs this lab gets the same files you did.

---

## Step 2 — Check the sandbox pin, then open it (7 minutes)

The devcontainer's `image` line decides which sandbox you get. Look at it:

```bash
grep '"image"' .devcontainer/devcontainer.json
```

**Expected output**:

```
  "image": "ghcr.io/paruff/fawkes-space:2.0.0",
```

The tag `2.0.0` matches the template tag you cloned. A tag like `:latest` moves whenever a new image is published, so your sandbox could change under you without any change in your repo. If you ever see `:latest` here, change it to a version before you go on. `validate.sh` checks this line.

Start the sandbox, then run the template's setup inside it:

```bash
devcontainer up --workspace-folder .
devcontainer exec --workspace-folder . ./scripts/setup.sh
```

**Expected output** (the first `up` also downloads the image, about 3 GB):

```
Container started
Running the postCreateCommand from devcontainer.json...
uFawkesAI devcontainer ready — all tools pre-installed
{"outcome":"success", ...
```

and, from `setup.sh`, ending with `✅  Setup complete!`.

**What just happened**: you started the **sandbox** part of the harness. Your agent (and you) now work inside a container whose tools are fixed by the image tag. `setup.sh` also deleted a `.template` marker file, so `git status` shows it as removed. That is expected.

> This lab was run with the devcontainer CLI. VS Code's "Reopen in Container" reads the same `devcontainer.json`, but that path was not run for this lab.

---

## Step 3 — Find the six harness components (8 minutes)

The [AI-Native SDLC Playbook](https://claude.com/blog/the-ai-native-sdlc-playbook) names six parts of an agent harness. The template provides one file for each. Check that each exists, from inside the sandbox:

```bash
devcontainer exec --workspace-folder . bash -lc '
for f in AGENTS.md .mcp.json .devcontainer/devcontainer.json \
         docs/MODEL_ROUTING_GUIDE.md .pre-commit-config.yaml scripts/emit-dora-event.sh; do
  [ -e "$f" ] && echo "ok  $f" || echo "MISSING $f"
done
ls .agents/agents'
```

**Expected output**:

```
ok  AGENTS.md
ok  .mcp.json
ok  .devcontainer/devcontainer.json
ok  docs/MODEL_ROUTING_GUIDE.md
ok  .pre-commit-config.yaml
ok  scripts/emit-dora-event.sh
builder.md
operator.md
planner.md
verifier.md
```

| Harness component | The file you just found | What it does for an agent |
|---|---|---|
| Instructions | `AGENTS.md` | what your agent reads first, every session |
| Tools / MCP | `.mcp.json` | which tools the agent may call |
| Sandbox | `.devcontainer/devcontainer.json` | where the agent runs (Step 2) |
| Orchestration | `.agents/agents/` | four roles: planner, builder, verifier, operator |
| Hooks | `.pre-commit-config.yaml` | checks that run before a commit lands |
| Observability | `scripts/emit-dora-event.sh` | emits delivery events you can see in uFawkesObs |

**Retrieval check** — answer before you open the answer: *which component would stop an agent from committing a secret, and how?*

<details>
<summary>Answer</summary>
<b>Hooks.</b> <code>.pre-commit-config.yaml</code> runs Gitleaks on every commit, and <code>scripts/hooks/pre-commit-secret-scan.sh</code> is the shared secret gate the agents' own harnesses call.
</details>

**Stop here if you want to end Session A.** Progress: 3 of 6 steps done.

---

## Step 4 — Write one intent → spec → plan chain (15 minutes)

First study a finished chain. The template ships one for its own release, in `docs/ai-sdlc/v2.0.0/`. Read these three parts:

- `intent.md` → **Problem** and **Desired Outcome**: what hurts, and what "fixed" looks like. It names no solution.
- `spec.md` → **Requirements**: each is `**REQ-001 — a short title.**` followed by what must be true.
- `plan.md` → **Verification Strategy**: a table with one row per requirement and a command that proves it.

Now write your own for a small feature. If you have no idea, use the greeting script below. This is a **full worked example**: later belts fade it into open problems.

```bash
mkdir -p docs/ai-sdlc/first-feature && cd docs/ai-sdlc/first-feature

cat > intent.md <<'EOF'
# Intent — A greeting script

## Problem

New contributors have no quick way to check that their devcontainer works.
They find out something is broken only after a slow first build.

## Desired Outcome

Running one script prints a greeting that names the current user and the
tool versions the repo needs, so a contributor knows in a second that their
environment is healthy.

## Out of Scope

Installing tools, fixing a broken environment, or running on Windows.
EOF

cat > spec.md <<'EOF'
# Specification — A greeting script

**Traces to:** [`intent.md`](intent.md)

## Requirements

**REQ-001 — Greets the user.** `scripts/hello.sh` prints `Hello, <user>`,
where `<user>` is the output of `whoami`.

**REQ-002 — Reports tool versions.** The script prints the installed `git`
and `node` versions, one per line, and exits non-zero if either is missing.
EOF

cat > plan.md <<'EOF'
# Plan — A greeting script

**Traces to:** [`spec.md`](spec.md)

## Task order

1. Write `scripts/hello.sh` with the greeting (REQ-001).
2. Add the version lines and the missing-tool exit code (REQ-002).

## Verification Strategy

| REQ | Check |
|---|---|
| REQ-001 | `bash scripts/hello.sh \| head -1` prints `Hello, ` followed by `whoami` |
| REQ-002 | `bash scripts/hello.sh` prints a `git` and a `node` line; `PATH=/nonexistent bash scripts/hello.sh` exits non-zero |
EOF

cd ../../..
git add -A
git commit -q -m "docs: first-feature intent, spec and plan"
```

You can write these by hand, or ask your agent to draft `spec.md` and `plan.md` from your `intent.md` and then edit them. The check below looks at the documents, not at who wrote them. You do not build the script in this lab.

Run the template's own chain check:

```bash
base=$(git rev-list --max-parents=0 HEAD | tail -1)
bash scripts/check-artifact-chain.sh "$base"
```

**Expected output** ends with:

```
✅ docs/ai-sdlc/first-feature/spec.md ← docs/ai-sdlc/first-feature/intent.md
...
✅ Artifact chain intact
```

It prints one `✅` line per spec in the repo, including the ones the template ships. The rule it enforces: every `spec.md` has an `intent.md` committed next to it.

**What just happened**: you wrote the plan *before* any code, with a way to prove each requirement. That is the habit this curriculum teaches: when an agent writes the code, the spec and the Verification Strategy are what you review it against.

---

## Step 5 — Run the validation script (2 minutes)

From your uFawkesDojo checkout:

```bash
bash white-belt/module-00-vibe-coding-to-agentic/lab-01/validate.sh ~/dojo-labs/my-first-ai-sdlc
```

**Expected output**: 14 checks, each `[✓]`, ending:

```
Total Tests: 14
Passed: 14
Failed: 0
[✓] All tests passed! ✅
```

If a line shows `[✗]`, it names the step to go back to. Fix that, then re-run. The re-run is a retest on the same checks, not a new attempt you wait for.

---

## Step 6 — Compare, then tell us how it went (3 minutes)

Compare your prediction from the start with your real time. If they differ by a lot, note why. Then save three answers in `docs/ai-sdlc/first-feature/lab-notes.md`:

1. **Ease** (1–5): how easy was it to get from Step 1 to a passing Step 5?
2. **Confidence** (1–5): how confident are you that you could do the next chain without this page?
3. **Would you recommend this lab** to a colleague? (yes / no, and one sentence why)

Also write where you got stuck, if anywhere. If something in the template itself was wrong or missing, open an issue in [uFawkesAI](https://github.com/paruff/uFawkesAI/issues) or ask in the [Q&A](https://github.com/paruff/uFawkesDojo/discussions/categories/q-a). This step is a self-report, so `validate.sh` does not check it.

Progress: 6 of 6 steps done.

---

## Clean up

```bash
docker ps -aq --filter "label=devcontainer.local_folder=$HOME/dojo-labs/my-first-ai-sdlc" | xargs -r docker rm -f
```

This removes the sandbox container. Your repo stays in `~/dojo-labs/my-first-ai-sdlc`; delete it when you are done.

## Troubleshooting

| Symptom | Cause and fix |
|---|---|
| `devcontainer: command not found` | Install the CLI: `npm install -g @devcontainers/cli` |
| `invalid mount config … bind source path does not exist` | Docker cannot see the folder you cloned into. Clone under your home directory (`~/dojo-labs`), not a temp folder |
| `[✗] CDE image is not pinned` | The `image` line was changed. Restore it with `git checkout -- .devcontainer/devcontainer.json` (Step 2) |
| `[✗] … is missing` for a harness component | You deleted or moved it. Restore it with `git checkout -- <file>`, or re-clone (Step 1) |
| `[✗] plan.md's Verification Strategy has no row for: REQ-00N` | Add a table row for that requirement in `plan.md`, with a command that proves it |
| `fatal: Remote branch … not found in upstream origin` on clone | The tag name is wrong. Check `echo $AI_TAG`, and the [releases page](https://github.com/paruff/uFawkesAI/releases) |

## What you learned

- A template pinned to a release tag gives everyone the same starting point.
- The sandbox image tag decides what your agent can run: pin it.
- An agent harness has six parts, and you can find each one as a file.
- A spec's requirements and a plan's Verification Strategy are how you check an agent's work, so write them before the code.

**Next**: [Module 1: What is an Internal Delivery Platform?](../../../modules/white-belt/module-01-what-is-idp.md)
