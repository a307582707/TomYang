#!/usr/bin/env bash
# Fixture-based tests for scripts/check-*.sh
# Uses only fictional credentials under scripts/testdata/.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
TD="$ROOT/scripts/testdata"

pass=0
fail=0
ok() { echo "PASS $1"; pass=$((pass+1)); }
ko() { echo "FAIL $1 — $2"; fail=$((fail+1)); }

yaml_ok() { python3 -c 'import sys,yaml; list(yaml.safe_load_all(open(sys.argv[1])))' "$1"; }

# --- YAML ---
if yaml_ok "$TD/yaml/good.yml"; then ok "yaml_good"; else ko "yaml_good" "should parse"; fi
if yaml_ok "$TD/yaml/bad.yml" 2>/dev/null; then ko "yaml_bad" "should reject"; else ok "yaml_bad"; fi

# --- placeholders ---
if yaml_ok "$TD/placeholders/quoted.yml"; then ok "placeholder_quoted"; else ko "placeholder_quoted" "should parse"; fi
if yaml_ok "$TD/placeholders/unquoted.yml" 2>/dev/null; then ko "placeholder_unquoted" "should reject"; else ok "placeholder_unquoted"; fi

# --- secrets pattern (assembled; no contiguous secret literals in this file) ---
RSA_BEGIN="BEGIN RSA ""PRIVATE KEY"
SSH_BEGIN="BEGIN OPENSSH ""PRIVATE KEY"
PAT_ADMIN='admin'':''admin'
PATTERN="${PAT_ADMIN}|${RSA_BEGIN}|${SSH_BEGIN}|ghp_[0-9A-Za-z]{20,}|github_pat_[0-9A-Za-z_]{20,}"

grep -nE "$PATTERN" "$TD/secrets/bad_token/leak.env.sample" >/dev/null && ok "secret_fake_ghp" || ko "secret_fake_ghp" "miss"
grep -nE "$PATTERN" "$TD/secrets/bad_token/haproxy-default.sample" >/dev/null && ok "secret_fake_admin" || ko "secret_fake_admin" "miss"
grep -nE "$PATTERN" "$TD/secrets/bad_key/id_rsa.sample" >/dev/null && ok "secret_fake_rsa" || ko "secret_fake_rsa" "miss"
grep -nE "$PATTERN" "$TD/secrets/clean/ok.env.sample" >/dev/null && ko "secret_clean" "false positive" || ok "secret_clean"

if bash scripts/check-secrets.sh >/tmp/secrets-scan.out 2>&1; then ok "secrets_scanner_repo"; else ko "secrets_scanner_repo" "$(cat /tmp/secrets-scan.out)"; fi

grep -nE "$PATTERN" scripts/check-secrets.sh >/dev/null && ko "secrets_self_match_detector" "false positive" || ok "secrets_self_match_detector"
grep -nE "$PATTERN" scripts/test-check-secrets.sh >/dev/null && ko "secrets_self_match_unit" "false positive" || ok "secrets_self_match_unit"
grep -nE "$PATTERN" scripts/test-static-checks.sh >/dev/null && ko "secrets_self_match_suite" "false positive" || ok "secrets_self_match_suite"

# --- markdown links (fixture-local) ---
if python3 -c '
import re
from pathlib import Path
root = Path("scripts/testdata/markdown")
link_re = re.compile(r"\[([^\]]+)\]\(([^)]+)\)")
md = root / "good.md"
miss = []
for m in link_re.finditer(md.read_text(encoding="utf-8")):
    url = m.group(2).strip()
    if url.startswith(("http", "#", "mailto:")): continue
    path = url.split("#")[0]
    if path and not (md.parent / path).exists(): miss.append(url)
raise SystemExit(1 if miss else 0)
'; then ok "markdown_good_link"; else ko "markdown_good_link" "unexpected miss"; fi

if python3 -c '
import re
from pathlib import Path
root = Path("scripts/testdata/markdown")
link_re = re.compile(r"\[([^\]]+)\]\(([^)]+)\)")
md = root / "bad.md"
miss = []
for m in link_re.finditer(md.read_text(encoding="utf-8")):
    url = m.group(2).strip()
    path = url.split("#")[0]
    if path and not (md.parent / path).exists(): miss.append(url)
raise SystemExit(0 if miss else 1)
'; then ok "markdown_bad_link"; else ko "markdown_bad_link" "should detect broken"; fi

# --- deprecated API ---
if rg -n 'apiVersion:\s*extensions/v1beta1' "$TD/deprecated/old.yml" >/dev/null; then ok "deprecated_api_old"; else ko "deprecated_api_old" "miss"; fi
if rg -n 'apiVersion:\s*extensions/v1beta1' "$TD/deprecated/new.yml" >/dev/null; then ko "deprecated_api_new" "false positive"; else ok "deprecated_api_new"; fi

# --- shell syntax ---
bash -n "$TD/shell/good.sh" && ok "shell_good" || ko "shell_good" "bash -n failed"
if bash -n "$TD/shell/bad.sh" 2>/dev/null; then ko "shell_bad" "should fail bash -n"; else ok "shell_bad"; fi

echo "summary pass=$pass fail=$fail"
[[ "$fail" -eq 0 ]]
