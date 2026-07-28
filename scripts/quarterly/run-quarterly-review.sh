#!/usr/bin/env bash
# Quarterly review — report only; never upgrades components or edits Wiki.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

# YYYY-QN output (calendar quarter)
YEAR="$(date +%Y)"
MONTH="$(date +%-m)"
case "$MONTH" in
  1|2|3) QUARTER="Q1" ;;
  4|5|6) QUARTER="Q2" ;;
  7|8|9) QUARTER="Q3" ;;
  *)     QUARTER="Q4" ;;
esac
PERIOD="${YEAR}-${QUARTER}"
REVIEW_DATE="$(date +%Y-%m-%d)"
NEXT_QUARTER_END="2026-10-25"  # aligned with docs/MAINTENANCE.md cadence

OUT="docs/audits/quarterly-review-${PERIOD}.md"
STATIC_LOG="$(mktemp)"
trap 'rm -f "$STATIC_LOG"' EXIT

set +e
bash scripts/run-static-checks.sh >"$STATIC_LOG" 2>&1
STATIC_RC=$?
set -e

DOC_QUALITY=$(grep -E '^doc_quality_findings=' "$STATIC_LOG" | tail -1 | cut -d= -f2 || echo "?")
MODERN_WARNS=$(grep -E '^modern_examples_warns=' "$STATIC_LOG" | tail -1 | cut -d= -f2 || echo "?")
MODERN_ERRS=$(grep -E '^modern_examples_errors=' "$STATIC_LOG" | tail -1 | cut -d= -f2 || echo "?")
WIKI_LINKS=$(grep -E '^wiki_links_checked=' "$STATIC_LOG" | tail -1 | cut -d= -f2 || echo "?")
MD_LINKS=$(grep -E '^local_md_links_checked=' "$STATIC_LOG" | tail -1 | cut -d= -f2 || echo "?")

{
  echo "# 季度复查报告 ${PERIOD}"
  echo
  echo "**复查日期:** ${REVIEW_DATE}  "
  echo "**下次统一复查:** ${NEXT_QUARTER_END}  "
  echo "**生成脚本:** \`scripts/quarterly/run-quarterly-review.sh\`"
  echo
  echo "> 自动生成草稿；**不**自动升级组件、**不**修改 Wiki、**不**变更 \`docs/MAINTENANCE.md\` 台账版本列。"
  echo
  echo "## 摘要"
  echo
  if [[ "$STATIC_RC" -eq 0 ]]; then
    echo "- 静态检查：**通过**（exit 0）"
  else
    echo "- 静态检查：**失败**（exit ${STATIC_RC}）— 见下文日志"
  fi
  echo "- \`examples/current\` 现代基线：errors=${MODERN_ERRS}, warns=${MODERN_WARNS}"
  echo "- 文档质量启发式：findings=${DOC_QUALITY}（warn-only）"
  echo "- 本地 Markdown 链接：${MD_LINKS}；Wiki 链接：${WIKI_LINKS}"
  echo
  echo "## EOL / 维护台账"
  echo
  echo "权威来源：[\`docs/MAINTENANCE.md\`](../MAINTENANCE.md)。本报告**不**修改台账中的「当前版本」列。"
  echo
  echo "| 组件类别 | 仓内版本量级 | 风险 | 备注 |"
  echo "|----------|--------------|------|------|"
  echo "| kube-apiserver / 控制面 | v1.11.x | 高 | EOL；仅教材，现网须重建集群 |"
  echo "| etcd | v3.3.9 | 高 | 快照演练后迁移；见 runbook |"
  echo "| Calico / Flannel | v3.1 / v0.10 | 高 | 与现网 CNI 二选一对齐 |"
  echo "| CoreDNS | 1.2.0 | 高 | 随集群重建 |"
  echo "| metrics-server（归档） | v0.2/v0.3 | 高 | **禁止** apply 归档 insecure 清单 |"
  echo "| Prometheus Operator / Grafana | v0.22 / 5.1 | 高 | 全量重建监控栈 |"
  echo "| HAProxy / Keepalived | 1.7 / 1.3.9 | 中 | backend 占位符已文档化 |"
  echo
  echo "**CVE：** 请在现网漏洞源与发行版公告人工核对（本脚本不拉取外部 CVE API）。"
  echo
  echo "## 静态检查"
  echo
  echo '```text'
  tail -n 40 "$STATIC_LOG"
  echo '```'
  echo
  echo "完整日志可在本地重跑：\`bash scripts/run-static-checks.sh\`"
  echo
  echo "## 链接"
  echo
  echo "- 本地 Markdown：\`scripts/check-markdown-links.sh\`（${MD_LINKS} 条）"
  echo "- Wiki：\`scripts/check-wiki-links.sh\`（${WIKI_LINKS} 条，需 \`gh\`/网络）"
  echo "- 参考：[\`docs/audits/wiki-link-check.md\`](./wiki-link-check.md)"
  echo
  echo "## 危险模式 / 密钥"
  echo
  echo "- \`scripts/check-dangerous-patterns.sh\`：工作区扫描（见 [\`docs/audits/dangerous-patterns.md\`](./dangerous-patterns.md)）"
  echo "- \`scripts/check-secrets.sh\` + 回归测试：禁止 \`admin:admin\` 等默认凭据回灌"
  echo "- Grafana / HAProxy stats 已改为占位符；Git 历史仍可能含旧样例 — 见 [\`remaining-security-remediation.md\`](./remaining-security-remediation.md)"
  echo
  echo "## 镜像可用性（人工）"
  echo
  echo "- 抽查 \`pull.sh\` 与清单中的仓库域名是否仍可解析"
  echo "- 个人/转储镜像（\`kairen/\`、\`zhangguanzhang/\`）见 [\`image-supply-chain.md\`](./image-supply-chain.md)"
  echo
  echo "## 未关闭高风险事项（GitHub Issues）"
  echo
  echo "维护者在本次复查中创建/关联的跟踪 Issue（去重后）："
  echo
  # Placeholders filled by maintainer after gh issue create (or via QUARTERLY_ISSUE_* env)
  for key in LICENSE METRICS HAPROXY_STATS; do
    var="QUARTERLY_ISSUE_${key}"
    url="${!var:-}"
    if [[ -n "$url" ]]; then
      echo "- ${key}: ${url}"
    fi
  done
  if [[ -z "${QUARTERLY_ISSUE_LICENSE:-}" && -z "${QUARTERLY_ISSUE_METRICS:-}" && -z "${QUARTERLY_ISSUE_HAPROXY_STATS:-}" ]]; then
    echo "- _（运行 \`gh issue create\` 后，以 \`QUARTERLY_ISSUE_*=URL\` 重跑脚本或手工补链）_"
  fi
  echo
  echo "历史验收遗留：[\`final-acceptance-2026-07-27.md\`](./final-acceptance-2026-07-27.md)、[\`hygiene-acceptance-2026-07-27.md\`](./hygiene-acceptance-2026-07-27.md)"
  echo
  echo "## 本季度建议动作（不自动执行）"
  echo
  echo "1. 选定根目录 LICENSE（见 [\`license-and-provenance.md\`](./license-and-provenance.md)）"
  echo "2. 现网 metrics-server：禁用 insecure 抓取路径（勿 apply \`k8s/archived/metrics-server/\`）"
  echo "3. HAProxy stats \`:8006\` 收敛至管理网"
  echo "4. HA 控制面隔离实验室实测（[\`ha-control-plane-test-plan.md\`](./ha-control-plane-test-plan.md)）"
  echo "5. etcd 备份恢复桌面演练（[\`docs/runbooks/etcd-backup-restore.md\`](../runbooks/etcd-backup-restore.md)）"
  echo
  echo "## 回滚"
  echo
  echo "删除本报告文件；revert 脚本变更即可。不影响集群或台账版本列。"
} > "$OUT"

echo "wrote $OUT"
