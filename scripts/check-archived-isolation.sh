#!/usr/bin/env bash
# Fail if recommended install entry points advertise archived / dangerous manifests as install targets.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

ARCHIVED_MARKERS=(
  'k8s/archived/WeaveScope'
  'k8s/archived/dashboard'
  'k8s/archived/metrics-server'
  'k8s/archived/kube-dns'
  'k8s/archived/efk'
)

# Old live paths that must not be recommended for kubectl apply
FORBIDDEN_APPLY_PATHS=(
  'k8s/ExtraAddons/WeaveScope/'
  'k8s/ExtraAddons/dashboard/'
  'k8s/ExtraAddons/efk/'
  'k8s/addons/metrics-server/'
  'k8s/addons/Kubedns/'
  'k8s/addons/kube-dns/'  # stub OK if only README
  'anonymous-proxy-rbac'
)

ENTRY_FILES=(
  README.md
  docs/SSOT.md
  docs/MAINTENANCE.md
)

fail=0

if [[ ! -f k8s/archived/ARCHIVED.md ]]; then
  echo "missing k8s/archived/ARCHIVED.md" >&2
  fail=1
fi

for d in WeaveScope dashboard metrics-server efk kube-dns; do
  if [[ ! -d "k8s/archived/$d" ]]; then
    echo "missing archived dir k8s/archived/$d" >&2
    fail=1
  fi
done

# README must mention 禁止部署 / archived
if ! rg -q '禁止直接部署|k8s/archived' README.md; then
  echo "README.md must document archived / do-not-deploy policy" >&2
  fail=1
fi

# Recommended entry files must not contain kubectl apply pointing at old live dangerous paths
for f in "${ENTRY_FILES[@]}"; do
  [[ -f "$f" ]] || continue
  for p in "${FORBIDDEN_APPLY_PATHS[@]}"; do
    if rg -n "kubectl apply.*${p}|apply -f .*${p}" "$f" >/dev/null 2>&1; then
      echo "$f: forbids recommending apply of $p" >&2
      fail=1
    fi
  done
done

# examples/current must not vendor copies of archived dangerous stacks as "current"
if [[ -d examples/current ]]; then
  if rg -n 'WeaveScope|anonymous-proxy|deprecated-kubelet-completely-insecure' examples/current -g '!**/README.md' >/dev/null 2>&1; then
    # allow README to mention as counter-example
    if rg -n 'deprecated-kubelet-completely-insecure|anonymous-proxy-rbac' examples/current --glob '*.yml' --glob '*.yaml' >/dev/null 2>&1; then
      echo "examples/current must not include insecure archived manifests" >&2
      fail=1
    fi
  fi
fi

if [[ "$fail" -ne 0 ]]; then
  echo "archived isolation check failed" >&2
  exit 1
fi
echo "archived isolation ok"
