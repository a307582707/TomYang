#!/usr/bin/env bash
# Report unquoted {{ }} that break YAML; allow quoted placeholders in manifests.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
python3 - <<'PY'
import re, sys
from pathlib import Path
try:
    import yaml
except ImportError:
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "pyyaml", "-q"])
    import yaml
failed=[]
for p in Path("k8s").rglob("*"):
    if p.suffix.lower() not in {".yml",".yaml"}: continue
    text=p.read_text(encoding="utf-8", errors="replace")
    try:
        list(yaml.safe_load_all(text))
    except Exception as e:
        failed.append(f"{p}: unparseable ({e})")
if failed:
    print("\n".join(failed)); sys.exit(1)
print("placeholders parseable (quoted or absent)")
PY
