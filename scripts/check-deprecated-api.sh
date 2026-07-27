#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
# Warn-only inventory by default; set STRICT_DEPRECATED=1 to fail
out=$(rg -n "apiVersion:\s*(extensions/v1beta1|apps/v1beta1|apps/v1beta2|rbac\.authorization\.k8s\.io/v1beta1)" k8s || true)
count=$(printf '%s\n' "$out" | grep -c . || true)
echo "deprecated_api_matches=$count"
if [[ "${STRICT_DEPRECATED:-0}" == "1" && "$count" -gt 0 ]]; then
  printf '%s\n' "$out"
  exit 1
fi
printf '%s\n' "$out" | head -40
echo "deprecated api scan done (warn-only unless STRICT_DEPRECATED=1)"
