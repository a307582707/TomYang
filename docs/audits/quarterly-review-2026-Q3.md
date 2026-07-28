# 季度复查报告 2026-Q3

**复查日期:** 2026-07-28  
**下次统一复查:** 2026-10-25  
**生成脚本:** `scripts/quarterly/run-quarterly-review.sh`

> 自动生成草稿；**不**自动升级组件、**不**修改 Wiki、**不**变更 `docs/MAINTENANCE.md` 台账版本列。

## 摘要

- 静态检查：**失败**（exit 1）— 见下文日志
- `examples/current` 现代基线：errors=?, warns=?
- 文档质量启发式：findings=?（warn-only）
- 本地 Markdown 链接：?；Wiki 链接：?

## EOL / 维护台账

权威来源：[`docs/MAINTENANCE.md`](../MAINTENANCE.md)。本报告**不**修改台账中的「当前版本」列。

| 组件类别 | 仓内版本量级 | 风险 | 备注 |
|----------|--------------|------|------|
| kube-apiserver / 控制面 | v1.11.x | 高 | EOL；仅教材，现网须重建集群 |
| etcd | v3.3.9 | 高 | 快照演练后迁移；见 runbook |
| Calico / Flannel | v3.1 / v0.10 | 高 | 与现网 CNI 二选一对齐 |
| CoreDNS | 1.2.0 | 高 | 随集群重建 |
| metrics-server（归档） | v0.2/v0.3 | 高 | **禁止** apply 归档 insecure 清单 |
| Prometheus Operator / Grafana | v0.22 / 5.1 | 高 | 全量重建监控栈 |
| HAProxy / Keepalived | 1.7 / 1.3.9 | 中 | backend 占位符已文档化 |

**CVE：** 请在现网漏洞源与发行版公告人工核对（本脚本不拉取外部 CVE API）。

## 静态检查

```text
checked=139
yaml/json ok
shellcheck not installed; bash -n only
shell ok (23 files)
scripts/quarterly/run-quarterly-review.sh:88:  echo "- \`scripts/check-secrets.sh\` + 回归测试：禁止 \`admin:admin\` 等默认凭据回灌"
Potential secrets found
```

完整日志可在本地重跑：`bash scripts/run-static-checks.sh`

## 链接

- 本地 Markdown：`scripts/check-markdown-links.sh`（? 条）
- Wiki：`scripts/check-wiki-links.sh`（? 条，需 `gh`/网络）
- 参考：[`docs/audits/wiki-link-check.md`](./wiki-link-check.md)

## 危险模式 / 密钥

- `scripts/check-dangerous-patterns.sh`：工作区扫描（见 [`docs/audits/dangerous-patterns.md`](./dangerous-patterns.md)）
- `scripts/check-secrets.sh` + 回归测试：禁止 `admin:admin` 等默认凭据回灌
- Grafana / HAProxy stats 已改为占位符；Git 历史仍可能含旧样例 — 见 [`remaining-security-remediation.md`](./remaining-security-remediation.md)

## 镜像可用性（人工）

- 抽查 `pull.sh` 与清单中的仓库域名是否仍可解析
- 个人/转储镜像（`kairen/`、`zhangguanzhang/`）见 [`image-supply-chain.md`](./image-supply-chain.md)

## 未关闭高风险事项（GitHub Issues）

维护者在本次复查中创建/关联的跟踪 Issue（去重后）：

- LICENSE: https://github.com/a307582707/TomYang/issues/71
- METRICS: https://github.com/a307582707/TomYang/issues/72
- HAPROXY_STATS: https://github.com/a307582707/TomYang/issues/73

历史验收遗留：[`final-acceptance-2026-07-27.md`](./final-acceptance-2026-07-27.md)、[`hygiene-acceptance-2026-07-27.md`](./hygiene-acceptance-2026-07-27.md)

## 本季度建议动作（不自动执行）

1. 选定根目录 LICENSE（见 [`license-and-provenance.md`](./license-and-provenance.md)）
2. 现网 metrics-server：禁用 insecure 抓取路径（勿 apply `k8s/archived/metrics-server/`）
3. HAProxy stats `:8006` 收敛至管理网
4. HA 控制面隔离实验室实测（[`ha-control-plane-test-plan.md`](./ha-control-plane-test-plan.md)）
5. etcd 备份恢复桌面演练（[`docs/runbooks/etcd-backup-restore.md`](../runbooks/etcd-backup-restore.md)）

## 回滚

删除本报告文件；revert 脚本变更即可。不影响集群或台账版本列。
