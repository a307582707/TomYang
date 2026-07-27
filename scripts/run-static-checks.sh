#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
bash scripts/check-yaml-json.sh
bash scripts/check-shell.sh
bash scripts/check-secrets.sh
bash scripts/check-placeholders.sh
bash scripts/check-deprecated-api.sh
bash scripts/check-markdown-links.sh
bash scripts/check-trailing-whitespace.sh
bash scripts/check-repo-path-refs.sh
echo "ALL STATIC CHECKS PASSED"
