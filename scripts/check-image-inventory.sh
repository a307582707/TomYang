#!/usr/bin/env bash
# Task 102 — Regenerate image inventory and verify outputs exist.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

JSON="${IMAGE_INVENTORY_JSON:-docs/audits/image-inventory.json}"
CSV="${IMAGE_INVENTORY_CSV:-docs/audits/image-inventory.csv}"

bash scripts/generate-image-inventory.sh

if [[ ! -s "$JSON" ]]; then
  echo "FAIL missing or empty $JSON"
  exit 1
fi

if [[ ! -s "$CSV" ]]; then
  echo "FAIL missing or empty $CSV"
  exit 1
fi

python3 - "$JSON" <<'PY'
import json, sys
path = sys.argv[1]
data = json.load(open(path, encoding="utf-8"))
required = {"path", "image", "tag", "digest", "eol_risk", "source"}
entries = data.get("entries") or []
if not entries:
    raise SystemExit("FAIL no inventory entries")
for i, row in enumerate(entries):
    missing = required - set(row)
    if missing:
        raise SystemExit(f"FAIL entry {i} missing fields: {sorted(missing)}")
    digest = row.get("digest", "")
    if digest and digest != "unknown" and not digest.startswith("sha256:"):
        raise SystemExit(f"FAIL entry {i} digest must be sha256:* or unknown/empty, got {digest!r}")
print(f"image_inventory_check_ok entries={len(entries)}")
PY

echo "image inventory check ok"
