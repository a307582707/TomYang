#!/usr/bin/env bash
# Scan audited paths for obvious leaked credentials.
# Patterns are assembled so this file itself does not contain a full match.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Split markers so git-grep on this script does not self-match.
RSA_BEGIN="BEGIN RSA PRIVATE KEY"
SSH_BEGIN="BEGIN OPENSSH PRIVATE KEY"
PAT_ADMIN='admin:admin'
PAT_GHP='ghp_[0-9A-Za-z]{20,}'
PAT_PAT='github_pat_[0-9A-Za-z_]{20,}'
PATTERN="${PAT_ADMIN}|${RSA_BEGIN}|${SSH_BEGIN}|${PAT_GHP}|${PAT_PAT}"

# Only audit content/config dirs; exclude this detector and unit fixtures.
PATHSPECS=(
  'k8s'
  'examples'
  'scripts'
  ':(glob)*.sh'
  ':(glob)*.yml'
  ':(glob)*.yaml'
  ':(glob)*.json'
  ':(glob)*.cfg'
  ':(glob)*.conf'
  ':(glob)*.service'
  ':!scripts/check-secrets.sh'
  ':!scripts/testdata/**'
  ':!.env'
  ':!**/*.md'
)

fail=0
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  echo "$line"
  fail=1
done < <(git grep -nE "$PATTERN" -- "${PATHSPECS[@]}" 2>/dev/null || true)

if [[ "$fail" -eq 1 ]]; then
  echo "Potential secrets found" >&2
  exit 1
fi
echo "secrets scan ok"
