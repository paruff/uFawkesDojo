# AGENTS.md

## Purpose

uFawkesDojo is the belt-level, hands-on platform engineering curriculum
extracted from [fawkes](https://github.com/paruff/fawkes). Progress through
White → Yellow → Green → Brown → Black belt modules, each with labs and
assessments.

## Layout

- `modules/<belt>/` — belt module docs (`module-01-what-is-idp.md`, etc.)
- `labs/` — lab automation, driven by `labs/fawkes-cli.py`
- `assessments/` — belt certification exams
- `white-belt/module-01-what-is-idp/` — first module's labs (top-level)
- `README.md` — canonical index of belts, labs, and assessments

## Conventions

- Markdown is linted in CI (`.github/workflows/markdown-lint.yml`).
  `.markdownlint.json` disables most rules (MD013, MD024, MD029, MD033,
  MD035, MD036, MD040, …) — keep new docs in the same permissive style.
- Filenames may contain spaces and colons; quote them in shell commands.
- Keep tooling state out of git: `.omo/`, `.serena/`, `.claude/` are ignored.
