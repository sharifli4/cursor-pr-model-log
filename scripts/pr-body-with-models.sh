#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SECTION="$("$ROOT"/scripts/models-for-pr.sh)"

if [[ -n "${1:-}" ]]; then
  cat "$1"
  printf '\n\n'
fi
printf '%s\n' "$SECTION"
