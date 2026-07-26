#!/bin/bash
# 从 .env 加载 GitHub 凭据，验证是否能推送到 origin
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$ROOT_DIR/.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "缺少 $ENV_FILE，请先填写账号和 token"
  exit 1
fi

# shellcheck disable=SC1090
source "$ENV_FILE"

if [[ -z "${GITHUB_USER:-}" || -z "${GITHUB_TOKEN:-}" ]]; then
  echo "请在 .env 中填写 GITHUB_USER 和 GITHUB_TOKEN"
  exit 1
fi

# 保持 remote 为干净 HTTPS，不把 token 写入 .git/config
git -C "$ROOT_DIR" remote set-url origin "https://github.com/a307582707/TomYang.git"

export GIT_ASKPASS="$ROOT_DIR/.git-askpass.sh"
export GIT_TERMINAL_PROMPT=0
export GITHUB_USER GITHUB_TOKEN

cat > "$GIT_ASKPASS" <<'EOF'
#!/bin/bash
case "$1" in
  *Username*) echo "$GITHUB_USER" ;;
  *Password*) echo "$GITHUB_TOKEN" ;;
esac
EOF
chmod 700 "$GIT_ASKPASS"

echo "凭据已从 .env 加载（用户: $GITHUB_USER）"
echo "推送示例:"
echo "  GIT_ASKPASS=$GIT_ASKPASS GIT_TERMINAL_PROMPT=0 git push origin master"
echo "或直接运行:"
echo "  ./git-push.sh"
