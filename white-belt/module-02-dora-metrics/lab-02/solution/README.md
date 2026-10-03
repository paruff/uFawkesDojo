# Lab 02 — Worked example

This is the feature the lab exercises, as uFawkesAI's plan built it
(`docs/ai-sdlc/dora-events/plan.md` › Implementation Sequence):

1. `.env.example` gains the emitter variables (`OTEL_EXPORTER_OTLP_ENDPOINT`,
   `OTEL_SERVICE_NAME`, `OTEL_EXPORTER_OTLP_HEADERS`, `DORA_ENVIRONMENT`).
2. `scripts/emit-dora-event.sh` builds each event with `jq`, looks up the PR
   through the GitHub API (`gh`), and writes to stdout, an optional file, and
   OTLP/HTTP `/v1/logs`. `scripts/agent-usage.sh` turns an agent session's
   real token usage into an `Agent-Tokens:` commit footer.
3. `scripts/test-emit-dora-event.sh` proves AC-01…AC-04 offline, against a
   verbatim copy of uFawkesObs's `deployment-event.schema.json`.
4. CI (`ci-quality.yml` › `📡 Delivery Events`) runs after every successful
   pipeline and uploads the events as the `dora-events` artifact (AC-05).

`example-dora-events.jsonl` is the real artifact from
[run 36314948159](https://github.com/paruff/uFawkesAI/actions/runs/36314948159)
(the push that shipped the feature to `main`) — the file Step 2 downloads.
