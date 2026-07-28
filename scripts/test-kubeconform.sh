#!/usr/bin/env bash
# Fixture tests for scripts/check-kubeconform.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

KUBECONFORM_BIN="${KUBECONFORM_BIN:-kubeconform}"
if ! command -v "$KUBECONFORM_BIN" >/dev/null 2>&1; then
  echo "SKIP test-kubeconform: kubeconform binary not installed"
  exit 0
fi

pass=0
fail=0
ok() { echo "PASS $1"; pass=$((pass+1)); }
ko() { echo "FAIL $1 — $2"; fail=$((fail+1)); }

if KUBECONFORM_TARGET=scripts/testdata/kubeconform/good \
  KUBECONFORM_DUMMY_ENV=/dev/null \
  bash scripts/check-kubeconform.sh >/tmp/kc-good.out 2>&1; then
  ok "kubeconform_good_fixture"
else
  ko "kubeconform_good_fixture" "$(tail -5 /tmp/kc-good.out)"
fi

if KUBECONFORM_TARGET=scripts/testdata/kubeconform/bad \
  KUBECONFORM_DUMMY_ENV=/dev/null \
  bash scripts/check-kubeconform.sh >/tmp/kc-bad.out 2>&1; then
  ko "kubeconform_bad_fixture" "expected failure"
else
  ok "kubeconform_bad_fixture"
fi

echo "kubeconform_test_summary pass=$pass fail=$fail"
[[ "$fail" -eq 0 ]]
