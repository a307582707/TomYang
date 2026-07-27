#!/usr/bin/env bash
# Task 63 — Modern schema/baseline checks for examples/current ONLY.
# Does NOT scan k8s/ or k8s/archived/ for modern failures.
# Hard fail: extensions/v1beta1 (and other beta apps APIs), image :latest
# Warn (default): missing runAsNonRoot, resources.requests, probes on Deployments
# MODERN_EXAMPLES_STRICT=1 → warnings become failures
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
TARGET="examples/current"
STRICT="${MODERN_EXAMPLES_STRICT:-0}"

if [[ ! -d "$TARGET" ]]; then
  echo "missing $TARGET"
  exit 1
fi

echo "modern_examples_scan_root=$TARGET"

# Fast path: forbidden apiVersions / :latest image tags
bad_api=$(rg -n --glob '*.yml' --glob '*.yaml' \
  'apiVersion:\s*(extensions/v1beta1|apps/v1beta1|apps/v1beta2)' \
  "$TARGET" || true)
if [[ -n "$bad_api" ]]; then
  echo "FAIL deprecated/forbidden apiVersion in examples/current:"
  printf '%s\n' "$bad_api"
  exit 1
fi

latest=$(rg -n --glob '*.yml' --glob '*.yaml' \
  'image:\s*["'\'']?[^"'\'']*:latest(["'\'']|\s|$)' \
  "$TARGET" || true)
if [[ -n "$latest" ]]; then
  echo "FAIL floating image tag :latest in examples/current:"
  printf '%s\n' "$latest"
  exit 1
fi

python3 - "$TARGET" "$STRICT" <<'PY'
import re, sys, pathlib
root = pathlib.Path(sys.argv[1])
strict = sys.argv[2] == "1"
errors = 0
warns = 0

def warn(msg):
    global warns
    warns += 1
    print(f"WARN {msg}")

def err(msg):
    global errors
    errors += 1
    print(f"FAIL {msg}")

for path in sorted(root.rglob("*")):
    if path.suffix.lower() not in {".yml", ".yaml"}:
        continue
    text = path.read_text(encoding="utf-8", errors="replace")
    docs = re.split(r"^---\s*$", text, flags=re.M)
    for i, doc in enumerate(docs):
        if not doc.strip():
            continue
        kind_m = re.search(r"^kind:\s*(\S+)", doc, re.M)
        api_m = re.search(r"^apiVersion:\s*(\S+)", doc, re.M)
        if not kind_m or not api_m:
            continue
        kind, api = kind_m.group(1), api_m.group(1)
        loc = f"{path}#doc{i}"

        if kind == "Deployment":
            if api != "apps/v1":
                err(f"{loc}: Deployment apiVersion must be apps/v1 (got {api})")
            if not re.search(r"runAsNonRoot:\s*true", doc):
                warn(f"{loc}: Deployment missing securityContext runAsNonRoot: true")
            if not re.search(r"requests:", doc):
                warn(f"{loc}: Deployment missing resources.requests")
            if not (re.search(r"readinessProbe:", doc) and re.search(r"livenessProbe:", doc)):
                warn(f"{loc}: Deployment missing readinessProbe and/or livenessProbe")
        if kind == "Ingress":
            if api != "networking.k8s.io/v1":
                err(f"{loc}: Ingress apiVersion must be networking.k8s.io/v1 (got {api})")
        if kind == "NetworkPolicy":
            if api != "networking.k8s.io/v1":
                err(f"{loc}: NetworkPolicy apiVersion must be networking.k8s.io/v1 (got {api})")

        for im in re.finditer(r"^\s*image:\s*['\"]?([^'\"\s]+)", doc, re.M):
            img = im.group(1)
            if img.endswith(":latest") or re.search(r"/latest$", img):
                err(f"{loc}: floating tag forbidden: {img}")

print(f"modern_examples_warns={warns}")
print(f"modern_examples_errors={errors}")
if errors:
    sys.exit(1)
if warns and strict:
    print("MODERN_EXAMPLES_STRICT=1 → warnings are failures")
    sys.exit(1)
print("modern examples check ok (k8s/ and k8s/archived/ not subject to this layer)")
PY

echo "note: historical layer for k8s/ remains warn-oriented via check-deprecated-api.sh"
