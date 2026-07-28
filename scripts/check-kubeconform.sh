#!/usr/bin/env bash
# Task 83 — kubeconform schema validation for examples/current ONLY.
# Historical k8s/ is intentionally out of scope (see check-deprecated-api.sh).
# Placeholders: render with scripts/testdata/kubeconform/dummy-placeholders.env before validate.
# Override: KUBECONFORM_VERSION=1.29.0 KUBECONFORM_BIN=/path/to/kubeconform
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

TARGET="${KUBECONFORM_TARGET:-examples/current}"
K8S_VERSION="${KUBECONFORM_VERSION:-1.29.0}"
DUMMY_ENV="${KUBECONFORM_DUMMY_ENV:-$ROOT/scripts/testdata/kubeconform/dummy-placeholders.env}"
SKIP_LIST="${KUBECONFORM_SKIP_LIST:-$ROOT/scripts/testdata/kubeconform/skip-schema-check.txt}"
KUBECONFORM_BIN="${KUBECONFORM_BIN:-kubeconform}"

if [[ ! -d "$TARGET" ]]; then
  echo "kubeconform: missing scan root $TARGET"
  exit 1
fi

if ! command -v "$KUBECONFORM_BIN" >/dev/null 2>&1; then
  echo "kubeconform: binary not found ($KUBECONFORM_BIN)"
  exit 1
fi

echo "kubeconform_scan_root=$TARGET"
echo "kubeconform_kubernetes_version=$K8S_VERSION"
echo "kubeconform_placeholder_policy=render_with_dummy_env"

mapfile -t FILES < <(find "$TARGET" -type f \( -name '*.yml' -o -name '*.yaml' \) | sort)
if [[ ${#FILES[@]} -eq 0 ]]; then
  echo "kubeconform: no YAML manifests under $TARGET"
  exit 1
fi

TMPDIR="$(mktemp -d "${TMPDIR:-/tmp}/kubeconform.XXXXXX")"
trap 'rm -rf "$TMPDIR"' EXIT

SKIP_SET=""
if [[ -f "$SKIP_LIST" ]]; then
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"
    line="$(echo "$line" | xargs)"
    [[ -z "$line" ]] && continue
    SKIP_SET+=$'\n'"$line"
  done < "$SKIP_LIST"
fi

python3 - "$ROOT" "$DUMMY_ENV" "$TMPDIR" "$SKIP_SET" "${FILES[@]}" <<'PY'
import re, sys
from pathlib import Path

root = Path(sys.argv[1]).resolve()
dummy_env = Path(sys.argv[2])
out_dir = Path(sys.argv[3])
skip_blob = sys.argv[4]
files = [Path(f).resolve() for f in sys.argv[5:]]

skip = {s.strip() for s in skip_blob.splitlines() if s.strip()}

values = {}
if dummy_env.is_file():
    for line in dummy_env.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if "=" not in line:
            continue
        k, v = line.split("=", 1)
        values[k.strip()] = v.strip()

ph_re = re.compile(r"\{\{\s*([A-Z0-9_]+)\s*\}\}")

def render(text: str) -> tuple[str, list[str]]:
    missing = []

    def repl(m):
        key = m.group(1)
        if key in values:
            return values[key]
        missing.append(key)
        return f"dummy-{key.lower().replace('_', '-')}"

    return ph_re.sub(repl, text), missing

rendered = []
skipped = []
excluded = []
for src in files:
    rel = src.relative_to(root)
    rel_s = str(rel)
    if rel.name in {"kustomization.yml", "kustomization.yaml"}:
        excluded.append(rel_s)
        continue
    if rel_s in skip or rel.as_posix() in skip:
        excluded.append(rel_s)
        continue
    text = src.read_text(encoding="utf-8", errors="replace")
    body, missing = render(text)
    if missing:
        print(f"kubeconform_render_warn {rel}: filled unknown placeholders {sorted(set(missing))}")
    if "apiVersion:" not in body:
        skipped.append(str(rel))
        continue
    dst = out_dir / rel
    dst.parent.mkdir(parents=True, exist_ok=True)
    dst.write_text(body, encoding="utf-8")
    rendered.append(str(rel))

print(f"kubeconform_files_rendered={len(rendered)}")
print(f"kubeconform_files_skipped_no_apiVersion={len(skipped)}")
print(f"kubeconform_files_excluded_missing_schema={len(excluded)}")
for s in skipped:
    print(f"kubeconform_skip {s}")
for s in excluded:
    print(f"kubeconform_exclude {s}")
PY

RENDER_ROOT="$TMPDIR/$TARGET"
if [[ ! -d "$RENDER_ROOT" ]]; then
  echo "kubeconform: render dir missing ($RENDER_ROOT)"
  exit 1
fi

FAIL=0
while IFS= read -r line; do
  rel="${line#${TMPDIR}/}"
  if ! "$KUBECONFORM_BIN" -kubernetes-version "$K8S_VERSION" -summary -output text "$line"; then
    echo "kubeconform FAIL file=$rel"
    FAIL=1
  else
    echo "kubeconform OK file=$rel"
  fi
done < <(find "$RENDER_ROOT" -type f \( -name '*.yml' -o -name '*.yaml' \) | sort)

if [[ "$FAIL" -ne 0 ]]; then
  echo "kubeconform: schema validation failed for one or more manifests under $TARGET"
  echo "hint: fix apiVersion/kind/field names; placeholders are rendered via $DUMMY_ENV"
  exit 1
fi

echo "kubeconform: all rendered manifests valid for Kubernetes $K8S_VERSION"
