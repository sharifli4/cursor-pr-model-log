#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

title=""
body_file=""
pass_args=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --title)
      title="${2:-}"
      shift 2
      ;;
    --body)
      body_file="${2:-}"
      shift 2
      ;;
    *)
      pass_args+=("$1")
      shift
      ;;
  esac
done

if [[ -z "$title" ]]; then
  echo "Usage: scripts/gh-pr-create-with-models.sh --title \"Title\" [--body body.md] [extra gh pr create args]" >&2
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "gh is required." >&2
  exit 1
fi

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

if [[ -n "$body_file" ]]; then
  "$ROOT/scripts/pr-body-with-models.sh" "$body_file" > "$tmp"
else
  "$ROOT/scripts/pr-body-with-models.sh" > "$tmp"
fi

gh pr create "${pass_args[@]}" --title "$title" --body-file "$tmp"
