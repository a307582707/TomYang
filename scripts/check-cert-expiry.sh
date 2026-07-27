#!/usr/bin/env bash
# Check PEM certificate NotAfter if present under given dirs.
# This repo ships CSR JSON only by default — exits 0 with a note when no PEMs found.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
DAYS_WARN="${DAYS_WARN:-30}"
mapfile -t pems < <(find k8s -type f \( -name '*.pem' -o -name '*.crt' \) ! -path '*/testdata/*' 2>/dev/null || true)
if [[ ${#pems[@]} -eq 0 ]]; then
  echo "no PEM/CRT certificates in k8s/; CSR JSON under k8s/pki/ is not an issued cert"
  echo "cert expiry check skipped"
  exit 0
fi
fail=0
now=$(date +%s)
for f in "${pems[@]}"; do
  end=$(openssl x509 -enddate -noout -in "$f" 2>/dev/null | cut -d= -f2 || true)
  [[ -z "$end" ]] && { echo "unreadable $f"; fail=1; continue; }
  end_s=$(date -d "$end" +%s)
  left=$(( (end_s - now) / 86400 ))
  echo "$f days_left=$left not_after=$end"
  if (( left < DAYS_WARN )); then
    echo "WARN expire soon: $f" >&2
    fail=1
  fi
done
exit "$fail"
