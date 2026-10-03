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
repo. Link to it; don't copy it here.

- The action colour (buttons, links, focus rings) is Indigo `#4f46e5`.
- Orange (Flame `#f06300`) is for marks and large graphics only. Green means
  pass or live, never decoration.
- Text must meet 4.5:1 contrast. `#16a34a` on white is 3.30:1 and fails.
- If this repo needs a value the reference does not have, propose it in
  uFawkes.dev rather than adding a local one.
