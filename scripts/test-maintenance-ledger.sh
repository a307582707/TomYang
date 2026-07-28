#!/usr/bin/env bash
# Smoke tests for check-maintenance-ledger.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

chmod +x scripts/check-maintenance-ledger.sh

echo "== real ledger (expect ok) =="
bash scripts/check-maintenance-ledger.sh

echo "== json mode =="
bash scripts/check-maintenance-ledger.sh --json | python3 -c "import json,sys; d=json.load(sys.stdin); assert 'summary' in d; print('json ok')"

echo "== overdue fixture =="
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
cat > "$TMP/MAINTENANCE.md" <<'EOF'
# test
**下次统一复查:** 2020-01-01

## 2. 组件台账

| 组件 | 当前版本（仓内） | 目标版本 | 适用 K8s | 风险 | 负责人 | 最近复查 | 下次复查 | 待迁移事项 | 验证方法 | 回滚方案 |
|------|------------------|----------|----------|------|--------|----------|----------|------------|----------|----------|
| bad | `k8s/archived/efk/` | x | 旧 | 高 | m | 2020-01-01 | 2020-01-01 | deploy | x | x |
EOF
if MAINTENANCE_LEDGER_FILE="$TMP/MAINTENANCE.md" TODAY=2026-07-28 bash scripts/check-maintenance-ledger.sh; then
  echo "expected failure for bad fixture" >&2
  exit 1
fi
echo "overdue fixture failed as expected"

echo "maintenance ledger tests ok"
