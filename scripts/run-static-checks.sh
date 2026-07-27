#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
bash scripts/check-yaml-json.sh
bash scripts/check-shell.sh
bash scripts/check-secrets.sh
bash scripts/test-check-secrets.sh
bash scripts/test-static-checks.sh
bash scripts/check-placeholders.sh
bash scripts/check-deprecated-api.sh
bash scripts/check-markdown-links.sh
bash scripts/check-trailing-whitespace.sh
bash scripts/check-repo-path-refs.sh
bash scripts/check-archived-isolation.sh
bash scripts/check-doc-quality.sh
bash scripts/check-modern-examples.sh
echo "ALL STATIC CHECKS PASSED"
