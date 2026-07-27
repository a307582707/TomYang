#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail=0
while IFS= read -r line; do
  echo "$line"
  fail=1
done < <(git grep -nE 'admin:admin|BEGIN RSA PRIVATE KEY|BEGIN OPENSSH PRIVATE KEY|github_pat_[0-9A-Za-z_]{20,}|ghp_[0-9A-Za-z]{20,}' -- ':!.env' ':!docs/**' ':!**/*.md' ':!**/TASK*.md' 2>/dev/null || true)
if [[ "$fail" -eq 1 ]]; then
  echo "Potential secrets found" >&2
  exit 1
fi
echo "secrets scan ok"
