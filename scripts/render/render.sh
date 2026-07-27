#!/usr/bin/env bash
# Safe config renderer: templates + example env + sensitive env vars → .rendered/
# Never writes values back into templates.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

VARS_FILE="${VARS_FILE:-docs/placeholders/examples/vars.example.env}"
OUT_DIR="${OUT_DIR:-.rendered}"
SRC_DIRS=("${SRC_DIRS[@]:-k8s/master examples/current}")

mkdir -p "$OUT_DIR"
rm -rf "${OUT_DIR:?}/"*

# Load non-sensitive example file (KEY=VALUE), ignore comments
declare -A VARS=()
if [[ -f "$VARS_FILE" ]]; then
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    key="${line%%=*}"
    val="${line#*=}"
    VARS["$key"]="$val"
  done < "$VARS_FILE"
fi

# Sensitive keys only from environment
SENSITIVE_KEYS=(
  ENCRYPT_SECRET HAPROXY_STATS_USER HAPROXY_STATS_PASSWORD
  GRAFANA_ADMIN_USER GRAFANA_ADMIN_PASSWORD
  TOKEN_ID TOKEN_SECRET
  ALERTMANAGER_SLACK_API_URL ALERTMANAGER_SMTP_SMARTHOST ALERTMANAGER_SMTP_FROM
  ALERTMANAGER_SMTP_USER ALERTMANAGER_SMTP_PASSWORD ALERTMANAGER_SLACK_CHANNEL ALERTMANAGER_ALERT_EMAIL
)
for k in "${SENSITIVE_KEYS[@]}"; do
  if [[ -n "${!k:-}" ]]; then
    VARS["$k"]="${!k}"
  fi
done

replace_in_text() {
  local text="$1"
  local k v
  for k in "${!VARS[@]}"; do
    v="${VARS[$k]}"
    # mustache
    text="${text//\{\{ $k \}\}/$v}"
    text="${text//\{\{$k\}\}/$v}"
    # brace TOKEN style
    text="${text//\{$k\}/$v}"
  done
  printf '%s' "$text"
}

rendered=0
while IFS= read -r -d '' f; do
  rel="${f#./}"
  out="$OUT_DIR/$rel"
  mkdir -p "$(dirname "$out")"
  content=$(cat "$f")
  content=$(replace_in_text "$content")
  printf '%s' "$content" > "$out"
  rendered=$((rendered+1))
done < <(find "${SRC_DIRS[@]}" \( -name '*.yml' -o -name '*.yaml' -o -name '*.cfg' -o -name '*.conf' -o -name '*.service' -o -name '*.snippet' \) -print0 2>/dev/null)

echo "rendered_files=$rendered out=$OUT_DIR"

# leftover placeholders check (mustache or {TOKEN_*})
leftover=$(rg -n '\{\{[^}]+\}\}|\{TOKEN_[A-Z_]+\}|\{HOSTNAME\}|\{PUBLIC_IP\}' "$OUT_DIR" || true)
if [[ -n "$leftover" ]]; then
  echo "UNREPLACED_PLACEHOLDERS:" >&2
  echo "$leftover" >&2
  echo "render incomplete" >&2
  exit 2
fi

# syntax checks on rendered outputs
python3 - <<'PY'
import sys
from pathlib import Path
try:
  import yaml
except ImportError:
  import subprocess
  subprocess.check_call([sys.executable,'-m','pip','install','pyyaml','-q'])
  import yaml
root=Path('.rendered')
err=[]
for p in list(root.rglob('*.yml'))+list(root.rglob('*.yaml')):
  try:
    list(yaml.safe_load_all(p.read_text(encoding='utf-8')))
  except Exception as e:
    err.append(f'{p}: {e}')
if err:
  print('\n'.join(err)); sys.exit(1)
print('rendered yaml ok')
PY

# HAProxy / keepalived: basic brace balance / non-empty
if [[ -f "$OUT_DIR/k8s/master/etc/haproxy/haproxy.cfg" ]]; then
  grep -q 'frontend\|listen\|backend' "$OUT_DIR/k8s/master/etc/haproxy/haproxy.cfg"
  echo 'haproxy cfg structure ok'
fi
if [[ -f "$OUT_DIR/k8s/master/etc/keepalived/keepalived.conf" ]]; then
  grep -q 'vrrp_instance\|virtual_ipaddress' "$OUT_DIR/k8s/master/etc/keepalived/keepalived.conf"
  echo 'keepalived conf structure ok'
fi

# shell snippets if any
while IFS= read -r -d '' shf; do
  bash -n "$shf"
done < <(find "$OUT_DIR" -name '*.sh' -print0 2>/dev/null || true)

echo 'RENDER OK'
