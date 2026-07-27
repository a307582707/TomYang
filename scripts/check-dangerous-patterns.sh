#!/usr/bin/env bash
# Fail if dangerous security patterns appear outside archived/ (or in recommended entry points).
# Marker strings are assembled so this script does not self-match secrets scanners.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail=0
PAT_ADMIN='admin'':''admin'
ARCHIVED_OK=0
if [[ -f k8s/archived/ARCHIVED.md ]]; then
  ARCHIVED_OK=1
fi

rg_search() {
  local pattern="$1"
  shift
  rg -n --glob '!**/testdata/**' --glob '!**/.git/**' "$pattern" "$@" 2>/dev/null || true
}

report_hit() {
  local label="$1"
  local line="$2"
  echo "dangerous-pattern [$label]: $line" >&2
  fail=1
}

LIVE_GLOBS=(
  --glob 'k8s/**/*.yml'
  --glob 'k8s/**/*.yaml'
  --glob 'k8s/**/*.cfg'
  --glob 'k8s/**/*.conf'
  --glob '!k8s/archived/**'
)

scan_live_pattern() {
  local label="$1"
  local pattern="$2"
  local line
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    report_hit "$label" "$line"
  done < <(rg_search "$pattern" "${LIVE_GLOBS[@]}")
}

scan_live_pattern 'system:anonymous' 'system:anonymous'
scan_live_pattern 'default-stats-auth' "$PAT_ADMIN"
scan_live_pattern 'docker.sock' 'docker\.sock'
scan_live_pattern 'readOnlyPort:10255' 'readOnlyPort:[[:space:]]*10255'
scan_live_pattern 'deprecated-kubelet-completely-insecure' 'deprecated-kubelet-completely-insecure'
scan_live_pattern 'cluster-admin' 'name:[[:space:]]*cluster-admin'

PRIV_ALLOW=(
  'k8s/master/manifests/keepalived.yml'
  'k8s/addons/calico/'
  'k8s/addons/flannel/'
  'k8s/addons/kube-proxy/'
)
is_priv_allowed() {
  local path="$1"
  local a
  for a in "${PRIV_ALLOW[@]}"; do
    case "$path" in
      "$a"*|"$a") return 0 ;;
    esac
  done
  return 1
}
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  path="${line%%:*}"
  if is_priv_allowed "$path"; then
    continue
  fi
  report_hit 'privileged: true' "$line"
done < <(rg_search 'privileged:[[:space:]]*true' "${LIVE_GLOBS[@]}")

EX_GLOBS=(
  --glob 'examples/current/**/*.yml'
  --glob 'examples/current/**/*.yaml'
)
scan_examples_pattern() {
  local label="$1"
  local pattern="$2"
  local line
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    report_hit "examples/$label" "$line"
  done < <(rg_search "$pattern" "${EX_GLOBS[@]}")
}
scan_examples_pattern 'system:anonymous' 'system:anonymous'
scan_examples_pattern 'cluster-admin' 'name:[[:space:]]*cluster-admin'
scan_examples_pattern 'default-stats-auth' "$PAT_ADMIN"
scan_examples_pattern 'docker.sock' 'docker\.sock'
scan_examples_pattern 'readOnlyPort:10255' 'readOnlyPort:[[:space:]]*10255'
scan_examples_pattern 'deprecated-kubelet-completely-insecure' 'deprecated-kubelet-completely-insecure'
scan_examples_pattern 'privileged: true' 'privileged:[[:space:]]*true'

ENTRY_FILES=(README.md docs/SSOT.md)
FORBIDDEN_APPLY=(
  'k8s/archived/'
  'anonymous-proxy'
  'deprecated-kubelet-completely-insecure'
  'docker.sock'
  "$PAT_ADMIN"
)
for f in "${ENTRY_FILES[@]}"; do
  [[ -f "$f" ]] || continue
  for p in "${FORBIDDEN_APPLY[@]}"; do
    if rg -n "kubectl apply.*${p}|apply -f .*${p}" "$f" >/dev/null 2>&1; then
      report_hit "entry-apply" "$f: recommends apply involving $p"
    fi
  done
done

if [[ -d k8s/archived && "$ARCHIVED_OK" -ne 1 ]]; then
  echo "k8s/archived/ present but ARCHIVED.md missing — dangerous patterns not exempt" >&2
  fail=1
fi

if [[ "$fail" -ne 0 ]]; then
  echo "dangerous patterns check failed" >&2
  exit 1
fi
echo "dangerous patterns ok"
