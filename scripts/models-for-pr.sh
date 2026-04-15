#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOG="${1:-"$ROOT/.cursor/model-usage.jsonl"}"

if [[ ! -f "$LOG" ]]; then
  printf '%s\n' "### AI models (Cursor)"
  printf '%s\n' ""
  printf '%s\n' "_No log at \`$LOG\` yet — use the agent in this repo with hooks enabled._"
  exit 0
fi

command -v jq >/dev/null 2>&1 || {
  printf '%s\n' "### AI models (Cursor)"
  printf '%s\n' ""
  printf '%s\n' "_Install \`jq\` to generate this section from \`$LOG\`._"
  exit 0
}

jq -r -s --arg log "$LOG" '
  . as $rows
  | ($rows | length) as $events
  | ($rows
      | map(select(
          .model != null and (.model | type == "string") and (.model | test("^\\s*$") | not)
        ))
    ) as $named
  | ($named | length) as $with_model
  | "### AI models (Cursor)\n\n"
    + (if $with_model == 0 then
        ("_No model id in hook payloads yet (" + ($events | tostring)
          + " events logged in `" + $log
          + "`). If Cursor adds model fields to hooks, counts will appear here._")
      else
        ($named
          | group_by(.model)
          | map({m: .[0].model, c: length})
          | sort_by(-.c)
          | map("- **" + .m + "** — " + (.c | tostring) + " recorded turn(s)")
          | join("\n"))
      end)
' "$LOG"
