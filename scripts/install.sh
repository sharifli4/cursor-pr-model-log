#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="${1:-$(pwd)}"

HOOK_CMD=".cursor/hooks/log-model-usage.sh"
HOOKS_JSON="$TARGET/.cursor/hooks.json"
GITIGNORE="$TARGET/.gitignore"

if [[ ! -d "$TARGET" ]]; then
  echo "Target directory does not exist: $TARGET" >&2
  exit 1
fi

mkdir -p "$TARGET/.cursor/hooks" "$TARGET/scripts"

install -m 755 "$ROOT/.cursor/hooks/log-model-usage.sh" "$TARGET/.cursor/hooks/log-model-usage.sh"
install -m 755 "$ROOT/scripts/models-for-pr.sh" "$TARGET/scripts/models-for-pr.sh"
install -m 755 "$ROOT/scripts/pr-body-with-models.sh" "$TARGET/scripts/pr-body-with-models.sh"
install -m 755 "$ROOT/scripts/gh-pr-create-with-models.sh" "$TARGET/scripts/gh-pr-create-with-models.sh"

if [[ -f "$HOOKS_JSON" ]]; then
  if command -v jq >/dev/null 2>&1; then
    tmp="$(mktemp)"
    jq --arg cmd "$HOOK_CMD" '
      def add_event($name):
        .hooks[$name] = (
          (.hooks[$name] // [])
          | if any(.command == $cmd) then . else . + [{"command": $cmd}] end
        );
      .
      | .version = 1
      | .hooks = (.hooks // {})
      | add_event("beforeSubmitPrompt")
      | add_event("stop")
      | add_event("afterAgentResponse")
    ' "$HOOKS_JSON" > "$tmp"
    mv "$tmp" "$HOOKS_JSON"
  else
    echo "jq is required to merge existing $HOOKS_JSON safely." >&2
    exit 1
  fi
else
  cat > "$HOOKS_JSON" <<'EOF'
{
  "version": 1,
  "hooks": {
    "beforeSubmitPrompt": [
      {
        "command": ".cursor/hooks/log-model-usage.sh"
      }
    ],
    "stop": [
      {
        "command": ".cursor/hooks/log-model-usage.sh"
      }
    ],
    "afterAgentResponse": [
      {
        "command": ".cursor/hooks/log-model-usage.sh"
      }
    ]
  }
}
EOF
fi

touch "$GITIGNORE"
if ! grep -qxF ".cursor/model-usage.jsonl" "$GITIGNORE"; then
  printf '\n.cursor/model-usage.jsonl\n' >> "$GITIGNORE"
fi

echo "Installed in: $TARGET"
echo "Next steps:"
echo "  1) Restart Cursor or reload hooks"
echo "  2) Run: $TARGET/scripts/models-for-pr.sh"
echo "  3) Or run: $TARGET/scripts/gh-pr-create-with-models.sh --title \"Your title\" --body body.md"
