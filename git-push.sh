#!/bin/bash
# 使用 .env 中的账号/token 推送到 GitHub
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1090
source "$ROOT_DIR/git-auth.sh"

ARGS=("$@")
if [[ ${#ARGS[@]} -eq 0 ]]; then
  ARGS=(origin HEAD)
fi

git -C "$ROOT_DIR" push "${ARGS[@]}"
echo "推送完成"
