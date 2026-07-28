#!/usr/bin/env bash
# Quarterly review — report only; never upgrades components or edits Wiki.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
QUARTER="$(date +%Y)-Q$(( ($(date +%-m)-1)/3+1 ))"
OUT="docs/audits/quarterly-review-${QUARTER}.md"
LEDGER_JSON="$(mktemp)"
trap 'rm -f "$LEDGER_JSON"' EXIT
{
  echo "# 季度复查报告 ${QUARTER}（$(date +%Y-%m-%d) 生成）"
  echo
  echo "> 自动生成草稿；**不**自动升级组件、**不**修改 Wiki。"
  echo
  echo "## 维护台账（scripts/check-maintenance-ledger.sh）"
  echo
  if bash scripts/check-maintenance-ledger.sh --json > "$LEDGER_JSON" 2>/dev/null; then
    echo "- 台账检查：**通过**"
  else
    echo "- 台账检查：**需人工处理**（见下方 JSON）"
  fi
  echo
  echo '```json'
  cat "$LEDGER_JSON"
  echo '```'
  echo
  echo "## 静态检查"
  echo '```'
  bash scripts/run-static-checks.sh || true
  echo '```'
  echo
  echo "## EOL / 维护台账提醒"
  echo "- 人工核对 docs/MAINTENANCE.md 复查日期与 EOL 组件"
  echo "- CVE：请在现网漏洞源查询（本脚本不拉取外部 CVE API，避免伪造结果）"
  echo
  echo "## 镜像可用性"
  echo "- 抽查 pull.sh / 清单中的仓库域名是否仍可解析（人工）"
  echo
  echo "## 链接"
  echo "- 运行 scripts/check-markdown-links.sh 与 Wiki 链接抽查"
  echo
  echo "## 未关闭高风险事项"
  echo "- 见 docs/audits/final-acceptance-*.md 遗留风险与 GitHub Issues"
  echo "- 台账 JSON 中 \`high_risk_untracked\` > 0 时请开/关联 Issue"
} > "$OUT"
echo "wrote $OUT"
