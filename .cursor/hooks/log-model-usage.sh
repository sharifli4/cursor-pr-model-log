#!/usr/bin/env bash
set -euo pipefail

command -v jq >/dev/null 2>&1 || exit 0

raw=$(cat)
[[ -z "${raw// }" ]] && exit 0

line=$(echo "$raw" | jq -c --arg ts "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" '{
  ts: $ts,
  event: (.hook_event_name // "unknown"),
  model: (
    .model // .modelName // .model_id // .selectedModel // .activeModel
    // .providerModel // .modelKey // .agentModel // null
  ),
  conversation_id: (.conversation_id // null),
  generation_id: (.generation_id // null)
}')

while IFS= read -r root; do
  [[ -z "$root" ]] && continue
  dir="${root%/}/.cursor"
  mkdir -p "$dir"
  printf '%s\n' "$line" >> "${dir}/model-usage.jsonl"
done < <(echo "$raw" | jq -r '.workspace_roots[]? // empty')

if ! echo "$raw" | jq -e '.workspace_roots | length > 0' >/dev/null 2>&1; then
  dir=".cursor"
  mkdir -p "$dir"
  printf '%s\n' "$line" >> "${dir}/model-usage.jsonl"
fi

exit 0
