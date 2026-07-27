#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
python3 - <<'PY'
import sys, json
from pathlib import Path
try:
    import yaml
except ImportError:
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "pyyaml", "-q"])
    import yaml

failed = []
checked = 0
for p in sorted(Path(".").rglob("*")):
    if ".git" in p.parts:
        continue
    if p.suffix.lower() in {".yml", ".yaml"}:
        checked += 1
        try:
            list(yaml.safe_load_all(p.read_text(encoding="utf-8", errors="replace")))
        except Exception as e:
            failed.append(f"YAML {p}: {e}")
    elif p.suffix.lower() == ".json":
        checked += 1
        try:
            json.loads(p.read_text(encoding="utf-8", errors="replace"))
        except Exception as e:
            failed.append(f"JSON {p}: {e}")
print(f"checked={checked}")
if failed:
    print("\n".join(failed))
    sys.exit(1)
print("yaml/json ok")
PY
