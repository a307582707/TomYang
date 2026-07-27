#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
# Ensure README referenced top-level paths exist
for p in k8s k8s/archived wiki README.md pull.sh examples/current; do
  [[ -e "$p" ]] || { echo "missing $p"; exit 1; }
done
for p in CODEOWNERS .github/CODEOWNERS docs/CODEOWNERS-matrix.md CONTRIBUTING.md; do
  [[ -e "$p" ]] || { echo "missing $p"; exit 1; }
done
# CONTRIBUTING must not link only to missing owners
if rg -q '\]\(\.\/CODEOWNERS\)' CONTRIBUTING.md && [[ ! -f CODEOWNERS ]]; then
  echo "CONTRIBUTING links CODEOWNERS but file missing"; exit 1
fi
echo "repo path refs ok"
