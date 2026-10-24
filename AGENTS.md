# AGENTS.md

## Purpose

uFawkesDojo is the belt-level, hands-on platform engineering curriculum
extracted from [fawkes](https://github.com/paruff/fawkes). Progress through
White → Yellow → Green → Brown → Black belt modules, each with labs and
assessments.

## Layout

- `modules/<belt>/` — belt module docs (`module-01-what-is-idp.md`, etc.)
- `labs/` — per-lab instructions (e.g. `white-belt/module-01-what-is-idp/lab-01/instructions.md`)
  are the real, run-for-real lab flow today (plain kubectl steps, or
  `make up`/`make init` for uFawkes Compose stacks). There is no wrapping
  CLI — a `labs/fawkes-cli.py` prototype existed briefly and was removed
  (2026-09-27) as unneeded: each stack already has its own Makefile
  interface. See [`INTENT.md`](INTENT.md) for current direction and
  `docs/ai-sdlc/compose-curriculum/` for the in-progress curriculum
  integration plan.
- `assessments/` — belt certification exams
- `white-belt/module-01-what-is-idp/` — first module's labs (top-level)
- `README.md` — canonical index of belts, labs, and assessments

## Conventions

- Markdown is linted in CI (`.github/workflows/markdown-lint.yml`).
  `.markdownlint.json` disables most rules (MD013, MD024, MD029, MD033,
  MD035, MD036, MD040, …) — keep new docs in the same permissive style.
- Filenames may contain spaces and colons; quote them in shell commands.
- Keep tooling state out of git: `.omo/`, `.serena/`, `.claude/` are ignored.
- Commit messages follow Conventional Commits: `type(scope): description`
  (1-72 chars on the subject line). Types: `feat`, `fix`, `docs`, `style`,
  `refactor`, `test`, `chore`, `ci`, `perf`, `build`, `revert`. Scope is
  optional. Enforced locally via `scripts/commit-msg.sh` (run
  `pre-commit install --hook-type commit-msg` once) and in CI via
  `.github/workflows/commit-lint.yml` on every PR.
- Never swallow an exception in a lab check/validator without logging what
  broke — a silently-caught exception makes "the check failed to run" look
  identical to "the check ran and the student passed," which is worse than
  no check at all.
- The module-authoring guide's rule — "no lab step may be described unless
  it has been run, for real" — applies to code, not just markdown. Don't
  mark a prototype file's status as real/working without actually running
  it first.

## Design and brand

Fawkes and the uFawkes suite share one design reference, owned by
uFawkes.dev: [DESIGN.md](https://github.com/paruff/uFawkes.dev/blob/main/DESIGN.md) and the machine-readable tokens at
<https://ufawkes.dev/design/tokens.json>. Read it before changing colours, logos, fonts or UI copy in this
repo. This repo's own [`DESIGN.md`](DESIGN.md) applies it here, in the same
format (suite decision D11); change a token in uFawkes.dev first.

- Links, focus rings and secondary buttons are Indigo `#4f46e5`. The primary
  button is Flame `#f06300` with a Night `#061723` label (5.62:1).
- Orange (Flame) is for marks, large graphics and the primary button fill,
  never for text. Green means pass or live, never decoration.
- Text must meet 4.5:1 contrast. `#16a34a` on white is 3.30:1 and fails.
- If this repo needs a value the reference does not have, propose it in
  uFawkes.dev rather than adding a local one.

## Workflow: board, gates, review

- UI changes: read DESIGN.md first (tokens, components, do and don't)
- Reviewing a PR: apply REVIEW.md (what is Important, verification, validation, security)

Status lives only on [Project #7](https://github.com/users/paruff/projects/7):
no status labels, no ✅ in plans. Routing labels say who does the work, not its
state. Work traces to `docs/ai-sdlc/<feature>/` intent → spec → plan; plans link
issues, never list tasks. Statuses, Gate, lifecycle and owner decisions:
[the board rules](https://github.com/paruff/uFawkes.dev/blob/main/docs/ai-sdlc/suite-release/plan.md#the-board-statuses-gates-and-moves).

```bash
# 1. Next item for an agent (label: the routing label you run as, claude-code or opencode)
gh project item-list 7 --owner paruff --limit 300 --query 'status:"Ready for agent" is:open label:opencode' \
  --format json --jq '.items | sort_by(.priority // "P9", .content.number) | .[:1][] | "\(.content.repository)#\(.content.number) \(.title)"'
# 2. Waiting on a human, and which gate each waits on
gh project item-list 7 --owner paruff --limit 300 --query 'status:"Needs human" is:open' \
  --format json --jq '.items[] | "\(.gate // "-")\t\(.content.repository)#\(.content.number) \(.title)"'
# Move: "In Progress" before you start; "Needs human" plus Gate "PR review" when the PR is up
gh project item-edit 7 --owner paruff --url <issue url> --field Status --value "In Progress"
```
