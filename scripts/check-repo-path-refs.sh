#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
for p in k8s k8s/archived wiki README.md pull.sh examples/current CODEOWNERS .github/CODEOWNERS docs/CODEOWNERS-matrix.md CONTRIBUTING.md SECURITY.md; do
  [[ -e "$p" ]] || { echo "missing $p"; exit 1; }
done
if ! cmp -s CODEOWNERS .github/CODEOWNERS; then
  echo "CODEOWNERS and .github/CODEOWNERS differ"; exit 1
fi
echo "repo path refs ok"
