#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
# Ensure README referenced top-level paths exist
for p in k8s k8s/archived wiki README.md pull.sh examples/current; do
  [[ -e "$p" ]] || { echo "missing $p"; exit 1; }
done
echo "repo path refs ok"
