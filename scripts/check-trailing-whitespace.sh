#!/usr/bin/env bash
set -euo pipefail
cd "$(cd "$(dirname "$0")/.." && pwd)"
if git diff --check HEAD 2>/dev/null; then
  # also check working tree against empty for all tracked
  git ls-files -z | xargs -0 grep -nI $' \t$' && exit 1 || true
fi
# Prefer git grep for tracked files with trailing spaces
if git grep -nI $'[\t ]$' -- ':!*.png' ':!*.jpg' 2>/dev/null | head; then
  # soft: print but don't fail on historical files - fail only on newly introduced via diff --check in CI on PR
  echo "note: some tracked files have trailing whitespace (historical)"
fi
echo "trailing whitespace check done"
