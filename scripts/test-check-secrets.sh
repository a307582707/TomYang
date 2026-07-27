#!/usr/bin/env bash
# Unit-style checks for scripts/check-secrets.sh
# Uses only fictional credentials.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
SCAN="$ROOT/scripts/check-secrets.sh"

RSA_BEGIN="BEGIN RSA ""PRIVATE KEY"
SSH_BEGIN="BEGIN OPENSSH ""PRIVATE KEY"
PATTERN="admin:admin|${RSA_BEGIN}|${SSH_BEGIN}|ghp_[0-9A-Za-z]{20,}|github_pat_[0-9A-Za-z_]{20,}"

pass=0
fail=0
assert_match_file() {
  local name=$1 file=$2
  if grep -nE "$PATTERN" "$file" >/dev/null 2>&1; then
    echo "PASS $name (detected)"
    pass=$((pass+1))
  else
    echo "FAIL $name (should detect)"
    fail=$((fail+1))
  fi
}
assert_no_match_file() {
  local name=$1 file=$2
  if grep -nE "$PATTERN" "$file" >/dev/null 2>&1; then
    echo "FAIL $name (false positive)"
    fail=$((fail+1))
  else
    echo "PASS $name (no false positive)"
    pass=$((pass+1))
  fi
}

assert_match_file "fake_ghp_token" scripts/testdata/secrets/bad_token/leak.env.sample
assert_match_file "fake_rsa_header" scripts/testdata/secrets/bad_key/id_rsa.sample
assert_no_match_file "clean_sample" scripts/testdata/secrets/clean/ok.env.sample

# Detector + test harness must not false-positive when production scanner runs
if bash "$SCAN" >/tmp/secrets-scan.out 2>&1; then
  echo "PASS scanner_clean_repo"
  pass=$((pass+1))
else
  echo "FAIL scanner_clean_repo"
  cat /tmp/secrets-scan.out
  fail=$((fail+1))
fi

# Assembled pattern must still detect a real-looking header in fixtures
assert_no_match_file "detector_script_no_full_literal" scripts/check-secrets.sh
assert_no_match_file "test_script_no_full_literal" scripts/test-check-secrets.sh

echo "summary pass=$pass fail=$fail"
[[ "$fail" -eq 0 ]]
