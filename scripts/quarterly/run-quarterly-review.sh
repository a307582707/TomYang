#!/usr/bin/env bash
# Quarterly review — report only; never upgrades components or edits Wiki.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
OUT="docs/audits/quarterly-review-$(date +%Y%m%d).md"
{
  echo "# 季度复查报告 $(date +%Y-%m-%d)"
  echo
  echo "> 自动生成草稿；**不**自动升级组件、**不**修改 Wiki。"
  echo
  echo "## 静态检查"
  echo '```'
  bash scripts/run-static-checks.sh || true
  echo '```'
  echo
  echo "## EOL / 维护台账提醒"
  echo "- 请人工核对 docs/MAINTENANCE.md 复查日期与 EOL 组件"
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
} > "$OUT"
echo "wrote $OUT"
