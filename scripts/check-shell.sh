#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
mapfile -t files < <(find . -type f -name '*.sh' ! -path './.git/*' ! -name '.git-askpass.sh' ! -name 'vsphere.sh')
# keep only scripts whose first non-empty line looks like a shebang text
text_files=()
for f in "${files[@]}"; do
  if head -c 2 "$f" | grep -q '#'; then
    text_files+=("$f")
  fi
done
if [[ ${#text_files[@]} -eq 0 ]]; then
  echo "no text shell scripts"; exit 0
fi
for f in "${text_files[@]}"; do
  bash -n "$f"
done
if command -v shellcheck >/dev/null 2>&1; then
  shellcheck -S error "${text_files[@]}"
else
  echo "shellcheck not installed; bash -n only"
fi
echo "shell ok (${#text_files[@]} files)"
