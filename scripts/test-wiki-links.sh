#!/usr/bin/env bash
# Fixture tests for scripts/check-wiki-links.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

pass=0
fail=0
ok() { echo "PASS $1"; pass=$((pass+1)); }
ko() { echo "FAIL $1 — $2"; fail=$((fail+1)); }

if WIKI_FIXTURE_DIR=scripts/testdata/wiki-links/good \
  bash scripts/check-wiki-links.sh >/tmp/wiki-good.out 2>&1; then
  ok "wiki_links_good_fixture"
else
  ko "wiki_links_good_fixture" "$(tail -8 /tmp/wiki-good.out)"
fi

if WIKI_FIXTURE_DIR=scripts/testdata/wiki-links/good \
  bash scripts/check-wiki-links.sh 2>&1 | tee /tmp/wiki-good-scan.out | rg -q "wiki_pages=[5-9]"; then
  ok "wiki_links_parenthesis_archive_fixtures_present"
else
  ko "wiki_links_parenthesis_archive_fixtures_present" "$(rg 'wiki_pages=' /tmp/wiki-good-scan.out || echo 'missing wiki_pages line')"
fi

if WIKI_FIXTURE_DIR=scripts/testdata/wiki-links/bad \
  bash scripts/check-wiki-links.sh >/tmp/wiki-bad.out 2>&1; then
  ko "wiki_links_bad_fixture" "expected failure for broken link"
else
  if rg -q "WIKI_LINK_ERRORS|missing internal page|ERRORS:" /tmp/wiki-bad.out; then
    ok "wiki_links_bad_fixture"
  else
    ko "wiki_links_bad_fixture" "missing readable error: $(tail -5 /tmp/wiki-bad.out)"
  fi
fi

echo "wiki_links_test_summary pass=$pass fail=$fail"
[[ "$fail" -eq 0 ]]
