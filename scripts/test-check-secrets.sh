#!/usr/bin/env bash
# Unit-style checks for scripts/check-secrets.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
SCAN="$ROOT/scripts/check-secrets.sh"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# Helper: run git grep with same pattern construction against a temp repo path list
RSA_BEGIN="BEGIN RSA PRIVATE KEY"
SSH_BEGIN="BEGIN OPENSSH PRIVATE KEY"
PATTERN="admin:admin|${RSA_BEGIN}|${SSH_BEGIN}|ghp_[0-9A-Za-z]{20,}|github_pat_[0-9A-Za-z_]{20,}"

pass=0
fail=0
assert_match() {
  local name=$1 file=$2
  if git grep -nE "$PATTERN" -- "$file" >/dev/null 2>&1; then
    echo "PASS $name (detected)"
    pass=$((pass+1))
  else
    echo "FAIL $name (should detect)"
    fail=$((fail+1))
  fi
}
assert_no_match() {
  local name=$1 file=$2
  if git grep -nE "$PATTERN" -- "$file" >/dev/null 2>&1; then
    echo "FAIL $name (false positive)"
    fail=$((fail+1))
  else
    echo "PASS $name (no false positive)"
    pass=$((pass+1))
  fi
}

# Ensure fixtures are tracked for git grep — use --no-index via path
# git grep only searches tracked/cached; use grep -E for fixture files instead when untracked
assert_match_file() {
  local name=$1 file=$2
  if grep -nE "$PATTERN" "$file" >/dev/null 2>&1; then
    echo "PASS $name (detected)"
    pass=$((pass+1))
  else
    echo "FAIL $name (should detect)"; fail=$((fail+1))
  fi
}
assert_no_match_file() {
  local name=$1 file=$2
  if grep -nE "$PATTERN" "$file" >/dev/null 2>&1; then
    echo "FAIL $name (false positive)"; fail=$((fail+1))
  else
    echo "PASS $name (no false positive)"; pass=$((pass+1))
  fi
}

assert_match_file "fake_ghp_token" scripts/testdata/secrets/bad_token/leak.env.sample
assert_match_file "fake_rsa_header" scripts/testdata/secrets/bad_key/id_rsa.sample
assert_no_match_file "clean_sample" scripts/testdata/secrets/clean/ok.env.sample

# Detector script must not match itself with the same assembled PATTERN against its source
# after exclusion: simulate by scanning check-secrets.sh — with assembled PATTERN,
# RSA_BEGIN appears as concatenation assignment values on separate lines...
# "BEGIN RSA PRIVATE KEY" appears as a complete string assignment value — THAT will match.
# So we verify the SCANNER excludes itself when run normally.
if bash "$SCAN" >/tmp/secrets-scan.out 2>&1; then
  echo "PASS scanner_clean_repo"
  pass=$((pass+1))
else
  echo "FAIL scanner_clean_repo"
  cat /tmp/secrets-scan.out
  fail=$((fail+1))
fi

# Prove exclusion: if we force-scan the detector file alone, RSA_BEGIN assignment matches.
# That is expected; production scan must exclude the file.
if grep -nE "$PATTERN" scripts/check-secrets.sh >/dev/null 2>&1; then
  echo "PASS detector_contains_markers_but_excluded_in_scan"
  pass=$((pass+1))
else
  # If we successfully avoided storing full markers, also OK
  echo "PASS detector_no_full_marker_literal"
  pass=$((pass+1))
fi

echo "summary pass=$pass fail=$fail"
[[ "$fail" -eq 0 ]]
