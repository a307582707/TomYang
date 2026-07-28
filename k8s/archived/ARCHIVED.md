# 高风险历史清单归档区

**状态: 禁止直接部署到生产或共享集群。**

本目录仅保留教学 / 反例 / 迁移对照价值。路径自 `k8s/ExtraAddons/*` 与 `k8s/addons/metrics-server` 迁入，清单正文未删改。

## 归档内容

| 目录 | 原因 |
|------|------|
| `WeaveScope/` | privileged、hostPID/hostNetwork、Docker socket；项目停更 |
| `dashboard/` | Dashboard v1.8.3 EOL；曾含匿名代理 + `cluster-admin`（该 RBAC 文件已删除，见下） |
| `metrics-server/` | 旧版本；含 `--deprecated-kubelet-completely-insecure` 等不安全抓取 | 替代：[`examples/current/observability/metrics-server-skeleton.yml`](../../examples/current/observability/metrics-server-skeleton.yml) |
| `kube-dns/` | kube-dns EOL；由 CoreDNS 取代 |
| `efk/` | ES/Kibana 6.2 EOL；默认 emptyDir、特权容器等历史假设 |

## 已删除（不可恢复为推荐项）

- `anonymous-proxy-rbac.yml`（原 `ExtraAddons/dashboard/`）：曾绑定 `system:anonymous` 与 Dashboard 代理，并将 SA 绑 `cluster-admin`。安全审计中删除；**禁止恢复**。

## 使用规则

1. 学习时请只读；对照 `docs/audits/k8s-security-report.md` 与兼容性矩阵。
2. 新环境请使用 `examples/current/`（现代基线）或现网发行版清单。
3. 不得把本目录写入「推荐安装」入口、一键安装脚本或 INFRA 默认步骤。
4. 旧路径留下的 README 仅为跳转说明。

## 回滚

`git revert` 本归档迁移提交，或从 git 历史取回原路径。
