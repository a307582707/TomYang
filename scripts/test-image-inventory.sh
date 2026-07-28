#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

export IMAGE_INVENTORY_JSON="$TMP/inventory.json"
export IMAGE_INVENTORY_CSV="$TMP/inventory.csv"

bash scripts/check-image-inventory.sh

python3 - "$IMAGE_INVENTORY_JSON" <<'PY'
import json, sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
paths = {e["path"] for e in data["entries"]}
assert any(p.startswith("examples/current/") for p in paths), "expected examples/current entries"
assert any(p.startswith("k8s/") for p in paths), "expected k8s entries"
nginx = [e for e in data["entries"] if "nginx" in e.get("raw_ref", "") and "1.27.5" in e.get("raw_ref", "")]
assert nginx, "expected nginx:1.27.5 entry"
for e in nginx:
    if "@sha256:" in e.get("raw_ref", ""):
        assert e["digest"].startswith("sha256:"), "digest must be extracted when pinned"
print("test-image-inventory ok")
PY
