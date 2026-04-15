#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

subject=""
body_file=""
pass_args=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --subject)
      subject="${2:-}"
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

if [[ -z "$subject" ]]; then
  echo "Usage: scripts/git-commit-with-models.sh --subject \"subject\" [--body body.md] [extra git commit args]" >&2
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  echo "git is required." >&2
  exit 1
fi

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

if [[ -n "$body_file" ]]; then
  cat "$body_file" > "$tmp"
  printf '\n\n' >> "$tmp"
fi

"$ROOT/scripts/models-for-pr.sh" >> "$tmp"

git commit "${pass_args[@]}" -m "$subject" -m "$(cat "$tmp")"
