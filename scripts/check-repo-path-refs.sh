#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
# Ensure README referenced top-level paths exist
for p in k8s wiki README.md pull.sh; do
  [[ -e "$p" ]] || { echo "missing $p"; exit 1; }
done
echo "repo path refs ok"
